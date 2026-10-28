#!/usr/bin/env python3
"""Initialize packaged stdio servers and exercise advertised completion."""

import argparse
import json
import os
import select
import subprocess
import sys
import tempfile
import time
from pathlib import Path

FIXTURES = {
    "python": ("python", "main.py", "import os\nos.pa"),
    "clangd": ("cpp", "main.cpp", "#include <string>\nint main() { std::str"),
    "rust": ("rust", "src/main.rs", "fn main() { let mut x = String::new(); x.pu| }\n"),
    "go": ("go", "main.go", "package main\nimport \"fmt\"\nfunc main() { fmt.Pr| }\n"),
    "typescript": ("typescript", "main.ts", "const value = 'test';\nvalue."),
    "nix": ("nix", "default.nix", "{ pkgs }: pkgs."),
    "json": ("json", "example.json", '{"key": '),
    "yaml": ("yaml", "example.yaml", "key: value\n"),
    "toml": ("toml", "example.toml", "[example]\nkey = "),
    "bitbake": ("bitbake", "example.bb", 'SUMMARY = "Example"\n'),
    "bash": ("shellscript", "main.sh", "#!/bin/sh\nprintf "),
    "css": ("css", "main.css", "body { col"),
    "html": ("html", "index.html", "<html><bo"),
    "markdown": ("markdown", "README.md", "# Example\n"),
    "java": ("java", "Main.java", "class Main { String value; }\n"),
    "xml": ("xml", "example.xml", "<example></example>\n"),
    "tex": ("latex", "example.tex", "\\documentclass{article}\n"),
    "cmake": ("cmake", "CMakeLists.txt", "cmake_minimum_required(VERSION 3.20)\nproject(example)\n"),
    "autotools": ("makefile", "Makefile", "all:\n\techo hello\n"),
    "dts": ("dts", "example.dts", "/dts-v1/;\n/ { model = \"example\"; };\n"),
    "docker": ("dockerfile", "Dockerfile", "FROM alpine\n"),
    "just": ("just", "justfile", "hello:\n    echo hello\n"),
    "systemd": ("systemd", "example.service", "[Unit]\nDescription=Example\n"),
    "jq": ("jq", "example.jq", ".example\n"),
    "ruby": ("ruby", "main.rb", '"hello".'),
    "php": ("php", "main.php", "<?php\n$value = 'hello';\n"),
    "perl": ("perl", "main.pl", "use strict;\nmy $value = 1;\n"),
    "lua": ("lua", "main.lua", "local value = 'hello'\nvalue."),
    "clojure": ("clojure", "src/main.clj", "(ns main)\n(str "),
    "kotlin": ("kotlin", "main.kt", 'fun main() { val value = "hello"; value.sub| }\n'),
    "groovy": ("groovy", "main.groovy", "println 'hello'\n"),
    "csharp": ("csharp", "Main.cs", "class Main { static void Run() {} }\n"),
    "fsharp": ("fsharp", "Main.fsx", 'printfn "hello"\n'),
    "dart": ("dart", "main.dart", 'void main() { print("hello"); }\n'),
    "swift": ("swift", "Sources/Fleek/main.swift", 'let value = "hello"\nval'),
    "r": ("r", "main.R", 'value <- "hello"\n'),
    "julia": ("julia", "main.jl", 'value = "hello"\nvalue.'),
    "powershell": ("powershell", "main.ps1", "Get-Chil"),
    "sql": ("sql", "example.sql", "SEL"),
    "jinja": ("jinja", "templates/example.jinja", "{% for item in items %}{{ item }}{% endfor %}\n"),
    "wat": ("wat", "example.wat", "(module (func (result i32) i32.co|))"),
}


class Client:
    def __init__(self, process):
        self.process = process
        self.pending = b""
        self.diagnostics = set()

    def send(self, message):
        payload = json.dumps({"jsonrpc": "2.0", **message}).encode()
        self.process.stdin.write(f"Content-Length: {len(payload)}\r\n\r\n".encode() + payload)
        self.process.stdin.flush()

    def receive(self, deadline):
        while time.monotonic() < deadline:
            if b"\r\n\r\n" in self.pending:
                header, body = self.pending.split(b"\r\n\r\n", 1)
                length = next((int(line.split(b":", 1)[1]) for line in header.split(b"\r\n")
                               if line.lower().startswith(b"content-length:")), None)
                if length is None:
                    raise ValueError(f"non-LSP stdout: {header[:200]!r}")
                if len(body) >= length:
                    self.pending = body[length:]
                    return json.loads(body[:length])
            readable, _, _ = select.select([self.process.stdout], [], [], min(0.1, max(0, deadline - time.monotonic())))
            if readable:
                chunk = os.read(self.process.stdout.fileno(), 65536)
                if not chunk:
                    raise RuntimeError(f"server closed stdout (exit {self.process.poll()})")
                self.pending += chunk
        raise TimeoutError("server response timed out")

    def response(self, request_id, timeout):
        deadline = time.monotonic() + timeout
        while True:
            message = self.receive(deadline)
            if "method" in message:
                self.handle(message)
            elif message.get("id") == request_id:
                if "error" in message:
                    raise ValueError(message["error"])
                return message.get("result")

    def handle(self, message):
        if message.get("method") == "textDocument/publishDiagnostics":
            self.diagnostics.add(message["params"]["uri"])
        if "id" in message:
            result = [None] * len(message.get("params", {}).get("items", [])) if message["method"] == "workspace/configuration" else None
            self.send({"id": message["id"], "result": result})

    def indexed(self, uri, timeout):
        deadline = time.monotonic() + timeout
        try:
            while uri not in self.diagnostics:
                self.handle(self.receive(deadline))
        except TimeoutError:
            return False
        return True


def check(name, command, timeout):
    result = {"profile": name, "command": command}
    try:
        with tempfile.TemporaryDirectory(prefix="fleek-lsp-") as directory:
            root = Path(directory)
            (root / "go.mod").write_text("module example.com/fleek\n\ngo 1.24\n")
            (root / "Cargo.toml").write_text('[package]\nname="fleek-test"\nversion="0.1.0"\nedition="2021"\n')
            (root / "pyproject.toml").write_text('[project]\nname="fleek-test"\nversion="0.1.0"\n')
            (root / "package.json").write_text('{"name":"fleek-test","version":"1.0.0"}')
            (root / "deps.edn").write_text('{:paths ["src"]}')
            (root / "test.csproj").write_text('<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup><TargetFramework>net10.0</TargetFramework></PropertyGroup></Project>')
            if name == "swift":
                (root / "Package.swift").write_text('// swift-tools-version: 6.0\nimport PackageDescription\nlet package = Package(name: "Fleek", targets: [.executableTarget(name: "Fleek")])\n')
            language, filename, text = FIXTURES[name]
            prefix = text.split("|", 1)[0]
            text = text.replace("|", "")
            file = root / filename
            file.parent.mkdir(parents=True, exist_ok=True)
            file.write_text(text)
            with tempfile.TemporaryFile() as stderr:
                launch = command + ["-data", str(root / ".jdtls")] if name == "java" else command
                process = subprocess.Popen(launch, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                           stderr=stderr, cwd=root)
                try:
                    client = Client(process)
                    start = time.monotonic()
                    client.send({"id": 1, "method": "initialize", "params": {
                        "processId": os.getpid(), "rootUri": root.as_uri(),
                        "capabilities": {"workspace": {"configuration": True},
                                         "textDocument": {"completion": {"completionItem": {"snippetSupport": False}}}},
                        "workspaceFolders": [{"uri": root.as_uri(), "name": "fleek-test"}],
                        "clientInfo": {"name": "Emacs", "version": "31.1"},
                    }})
                    response = client.response(1, timeout)
                    if not isinstance(response, dict) or "capabilities" not in response:
                        raise ValueError(f"invalid initialize result: {response!r}")
                    result["initializeMs"] = round((time.monotonic() - start) * 1000, 1)
                    client.send({"method": "initialized", "params": {}})
                    client.send({"method": "textDocument/didOpen", "params": {
                        "textDocument": {"uri": file.as_uri(), "languageId": language, "version": 1, "text": text},
                    }})
                    if name in ("rust", "kotlin"):
                        result["diagnosticsReceived"] = client.indexed(file.as_uri(), 10)
                    provider = response["capabilities"].get("completionProvider")
                    if provider is not None and provider is not False:
                        lines = prefix.split("\n")
                        completion_start = time.monotonic()
                        client.send({"id": 2, "method": "textDocument/completion", "params": {
                            "textDocument": {"uri": file.as_uri()},
                            "position": {"line": len(lines) - 1, "character": len(lines[-1])},
                            "context": {"triggerKind": 1},
                        }})
                        completion = client.response(2, timeout)
                        result["completionMs"] = round((time.monotonic() - completion_start) * 1000, 1)
                        items = completion.get("items", []) if isinstance(completion, dict) else completion
                        if items is not None and not isinstance(items, list):
                            raise ValueError("invalid completion response")
                        result["completionCandidates"] = len(items or [])
                    result["status"] = "ok"
                except (OSError, ValueError, RuntimeError, TimeoutError) as error:
                    stderr.seek(0)
                    result.update(status="failed", error=str(error),
                                  stderr=stderr.read().decode(errors="replace")[-2000:])
                finally:
                    process.terminate()
                    try:
                        process.wait(timeout=3)
                    except subprocess.TimeoutExpired:
                        process.kill()
                        process.wait()
                    process.stdin.close()
                    process.stdout.close()
    except OSError as error:
        result.update(status="failed", error=str(error))
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("commands", type=Path)
    parser.add_argument("--only", help="comma-separated profile IDs")
    parser.add_argument("--timeout", type=float, default=20)
    args = parser.parse_args()
    commands = json.loads(args.commands.read_text())
    if args.only:
        selected = args.only.split(",")
    else:
        selected = sorted(commands.keys() - {"swift"})
        inactive = sorted(commands.keys() - set(selected))
        if inactive:
            print("Inactive profiles not tested: " + ", ".join(inactive), file=sys.stderr)
    missing = set(selected) - FIXTURES.keys()
    if missing:
        parser.error("missing test fixtures for profiles: " + ", ".join(sorted(missing)))
    results = [check(name, commands[name], args.timeout) for name in selected if commands[name]]
    print(json.dumps(results, indent=2), flush=True)
    raise SystemExit(any(result["status"] != "ok" for result in results))


if __name__ == "__main__":
    main()
