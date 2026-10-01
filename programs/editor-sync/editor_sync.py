#!/usr/bin/env python3
"""Sync VS Code and Cursor settings, keybindings, snippets, and extensions.

Source of truth is chezmoi/.editor-config (shared layers plus per-host overlays).
Age-encrypted secrets are files under chezmoi/.chezmoisecrets/editor-sync.
Git-ignored local secrets live in ~/.config/editor-sync/local.
"""

from __future__ import annotations

import argparse
import difflib
import json
import os
import shutil
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

EDITORS = ("vscode", "cursor")
KINDS = ("settings", "keybindings", "snippets", "extensions")
MISSING = object()


class JsoncError(Exception):
    pass


class Quit(Exception):
    pass


class Widen(Exception):
    pass


@dataclass
class Node:
    kind: str  # object, array, atom
    start: int
    end: int
    value: Any = None
    items: list = field(default_factory=list)


@dataclass
class Item:
    start: int
    end: int
    value: Node
    key: str | None = None


class Parser:
    def __init__(self, text: str):
        self.text = text
        self.n = len(text)
        self.i = 0

    def peek(self) -> str:
        return self.text[self.i] if self.i < self.n else ""

    def skip(self) -> None:
        while self.i < self.n:
            c = self.text[self.i]
            if c in " \t\r\n":
                self.i += 1
            elif c == "/" and self.text.startswith("//", self.i):
                self.i += 2
                while self.i < self.n and self.text[self.i] != "\n":
                    self.i += 1
            elif c == "/" and self.text.startswith("/*", self.i):
                self.i += 2
                while self.i + 1 < self.n and not self.text.startswith("*/", self.i):
                    self.i += 1
                if self.text.startswith("*/", self.i):
                    self.i += 2
                else:
                    raise JsoncError("unterminated block comment")
            else:
                return

    def parse(self) -> Node:
        self.skip()
        if self.i >= self.n:
            raise JsoncError("empty document")
        node = self.parse_value()
        self.skip()
        if self.i < self.n:
            raise JsoncError(f"trailing data at {self.i}")
        return node

    def parse_value(self) -> Node:
        self.skip()
        start = self.i
        c = self.peek()
        if c == "{":
            return self.parse_object(start)
        if c == "[":
            return self.parse_array(start)
        if c == '"':
            self.parse_string()
            return Node("atom", start, self.i, decode_json_string(self.text[start:self.i]))
        if c == "-" or c.isdigit():
            self.scan_number()
            return Node("atom", start, self.i, json.loads(self.text[start:self.i]))
        for lit, val in (("true", True), ("false", False), ("null", None)):
            if self.text.startswith(lit, self.i):
                self.i += len(lit)
                return Node("atom", start, self.i, val)
        raise JsoncError(f"unexpected {c!r} at {self.i}")

    def parse_object(self, start: int) -> Node:
        self.i += 1
        items: list[Item] = []
        while True:
            self.skip()
            if self.peek() == "}":
                self.i += 1
                break
            key_start = self.i
            key = self.parse_string_value()
            self.skip()
            if self.peek() != ":":
                raise JsoncError(f"expected ':' at {self.i}")
            self.i += 1
            val = self.parse_value()
            items.append(Item(key_start, val.end, val, key))
            self.skip()
            if self.peek() == ",":
                self.i += 1
                self.skip()
                if self.peek() == "}":
                    self.i += 1
                    break
                continue
            if self.peek() == "}":
                self.i += 1
                break
            raise JsoncError(f"expected ',' or '}}' at {self.i}")
        return Node("object", start, self.i, items=items)

    def parse_array(self, start: int) -> Node:
        self.i += 1
        items: list[Item] = []
        while True:
            self.skip()
            if self.peek() == "]":
                self.i += 1
                break
            elem_start = self.i
            val = self.parse_value()
            items.append(Item(elem_start, val.end, val))
            self.skip()
            if self.peek() == ",":
                self.i += 1
                self.skip()
                if self.peek() == "]":
                    self.i += 1
                    break
                continue
            if self.peek() == "]":
                self.i += 1
                break
            raise JsoncError(f"expected ',' or ']' at {self.i}")
        return Node("array", start, self.i, items=items)

    def parse_string(self) -> None:
        if self.peek() != '"':
            raise JsoncError(f"expected string at {self.i}")
        self.i += 1
        while self.i < self.n:
            c = self.text[self.i]
            if c == "\\":
                self.i += 2
                continue
            if c == '"':
                self.i += 1
                return
            self.i += 1
        raise JsoncError("unterminated string")

    def parse_string_value(self) -> str:
        start = self.i
        self.parse_string()
        return decode_json_string(self.text[start:self.i])

    def scan_number(self) -> None:
        if self.peek() == "-":
            self.i += 1
        while self.peek().isdigit():
            self.i += 1
        if self.peek() == ".":
            self.i += 1
            while self.peek().isdigit():
                self.i += 1
        if self.peek() in "eE":
            self.i += 1
            if self.peek() in "+-":
                self.i += 1
            while self.peek().isdigit():
                self.i += 1


def decode_json_string(token: str) -> str:
    """Decode a JSON string token, including the surrounding quotes.

    VS Code snippet files contain raw tabs inside strings. json.loads rejects
    those, so fall back to a decoder that keeps the control character.
    """
    try:
        return json.loads(token)
    except json.JSONDecodeError:
        return decode_lenient_string(token)


def decode_lenient_string(token: str) -> str:
    if len(token) < 2 or token[0] != '"' or token[-1] != '"':
        raise JsoncError("unterminated string")
    out: list[str] = []
    i = 1
    end = len(token) - 1
    escapes = {
        '"': '"',
        "\\": "\\",
        "/": "/",
        "b": "\b",
        "f": "\f",
        "n": "\n",
        "r": "\r",
        "t": "\t",
    }
    while i < end:
        char = token[i]
        if char != "\\":
            out.append(char)
            i += 1
            continue
        if i + 1 >= end:
            raise JsoncError("bad escape")
        esc = token[i + 1]
        if esc in escapes:
            out.append(escapes[esc])
            i += 2
            continue
        if esc == "u" and i + 6 <= end:
            out.append(chr(int(token[i + 2 : i + 6], 16)))
            i += 6
            continue
        raise JsoncError(f"bad escape {esc!r}")
    return "".join(out)


def parse_jsonc(text: str) -> Node:
    return Parser(text).parse()


def to_py(node: Node) -> Any:
    if node.kind == "atom":
        return node.value
    if node.kind == "array":
        return [to_py(item.value) for item in node.items]
    obj: dict[str, Any] = {}
    for item in node.items:
        obj[item.key] = to_py(item.value)
    return obj


def loads_jsonc(text: str) -> Any:
    return to_py(parse_jsonc(text))


def dump(value: Any) -> str:
    return json.dumps(value, indent=4, ensure_ascii=False)


def path_str(path: list) -> str:
    parts = []
    for seg in path:
        if isinstance(seg, str):
            parts.append("[" + json.dumps(seg, ensure_ascii=False) + "]")
        elif isinstance(seg, dict) and "index" in seg:
            parts.append(f"[{seg['index']}]")
        elif isinstance(seg, dict) and seg.get("append"):
            parts.append("[append]")
        elif isinstance(seg, dict) and "where" in seg:
            parts.append("[where " + json.dumps(seg["where"], ensure_ascii=False) + "]")
        else:
            parts.append("[" + json.dumps(seg, ensure_ascii=False) + "]")
    return "".join(parts) or "(root)"


def path_key(path: list) -> str:
    return json.dumps(path, ensure_ascii=False, sort_keys=True)


def paths_equal(a: list, b: list) -> bool:
    return path_key(a) == path_key(b)


def nest(path: list, value: Any) -> Any:
    if not path:
        return value
    seg = path[0]
    inner = nest(path[1:], value)
    if isinstance(seg, str):
        return {seg: inner}
    if isinstance(seg, dict) and "index" in seg:
        idx = int(seg["index"])
        return [None] * idx + [inner]
    if isinstance(seg, dict) and seg.get("append"):
        return [inner]
    if isinstance(seg, dict) and "where" in seg:
        if path[1:] and isinstance(inner, dict):
            return [{**seg["where"], **inner}]
        return [inner]
    raise JsoncError(f"bad path segment {seg!r}")


def _find_item(node: Node, seg: Any) -> Item | None:
    if isinstance(seg, str):
        if node.kind != "object":
            return None
        found = None
        for item in node.items:
            if item.key == seg:
                found = item
        return found
    if isinstance(seg, dict) and "index" in seg:
        if node.kind != "array":
            return None
        idx = int(seg["index"])
        if 0 <= idx < len(node.items):
            return node.items[idx]
        return None
    if isinstance(seg, dict) and "where" in seg:
        if node.kind != "array":
            return None
        for item in node.items:
            if isinstance(to_py(item.value), dict) and _where_match(to_py(item.value), seg["where"]):
                return item
        return None
    return None


def _where_match(elem: dict, where: dict) -> bool:
    return all(elem.get(k) == v for k, v in where.items())


def _child(node: Node, seg: Any) -> Node | None:
    if isinstance(seg, dict) and seg.get("append"):
        return None
    item = _find_item(node, seg)
    return item.value if item else None


def locate(root: Node, path: list) -> tuple[Node | None, Node | None, Any, list]:
    """Return (node, parent, missing_seg, remaining_from_missing)."""
    current = root
    parent = None
    for i, seg in enumerate(path):
        parent = current
        child = _child(current, seg)
        if child is None:
            return None, parent, seg, path[i:]
        current = child
    return current, parent, None, []


def _indent_at(text: str, pos: int) -> str:
    line = text.rfind("\n", 0, pos) + 1
    i = line
    while i < len(text) and text[i] in " \t":
        i += 1
    return text[line:i] or "    "


def _has_comma_after(text: str, end: int, limit: int) -> bool:
    i = end
    while i < limit and text[i] in " \t\r\n":
        i += 1
    return i < limit and text[i] == ","


def _after_trailing_comma(text: str, end: int, limit: int) -> int:
    """Insertion point after the last item: past its trailing comma if it has one."""
    i = end
    while i < limit and text[i] in " \t\r\n":
        i += 1
    if i < limit and text[i] == ",":
        return i + 1
    return end


def _insert_into_object(text: str, node: Node, key: str, value: Any) -> str:
    blob = dump(value)
    close = node.end - 1
    rendered = json.dumps(key, ensure_ascii=False) + ": " + blob
    if not node.items:
        indent = "    "
        return text[:close] + "\n" + indent + rendered + "\n" + text[close:]
    last = node.items[-1]
    indent = _indent_at(text, last.start)
    comma = "" if _has_comma_after(text, last.end, close) else ","
    at = _after_trailing_comma(text, last.end, close)
    return text[:at] + comma + "\n" + indent + rendered + text[at:]


def _append_to_array(text: str, node: Node, values: list) -> str:
    close = node.end - 1
    if not node.items:
        indent = "    "
        body = ",\n".join(indent + dump(v) for v in values)
        return text[:close] + "\n" + body + "\n" + text[close:]
    last = node.items[-1]
    indent = _indent_at(text, last.start)
    comma = "" if _has_comma_after(text, last.end, close) else ","
    at = _after_trailing_comma(text, last.end, close)
    extra = ",\n".join(indent + dump(v) for v in values)
    if comma == "":
        extra += ","
    return text[:at] + comma + "\n" + extra + text[at:]


def _set_index(text: str, node: Node, idx: int, value: Any) -> str:
    if idx < len(node.items):
        item = node.items[idx]
        return text[: item.value.start] + dump(value) + text[item.value.end :]
    gaps = idx - len(node.items)
    return _append_to_array(text, node, [None] * gaps + [value])


def _delete_item(text: str, container: Node, item: Item) -> str:
    start = item.start
    end = item.end
    before = start - 1
    while before > container.start and text[before] in " \t\r\n":
        before -= 1
    if text[before] == ",":
        return text[:before] + text[end:]
    after = end
    while after < container.end and text[after] in " \t\r\n":
        after += 1
    if after < container.end and text[after] == ",":
        return text[:start] + text[after + 1 :]
    return text[:start] + text[end:]


def set_path(text: str, path: list, value: Any) -> str:
    root = parse_jsonc(text)
    if not path:
        return dump(value) + ("\n" if text.endswith("\n") else "")
    node, parent, seg, remaining = locate(root, path)
    if node is not None:
        return text[: node.start] + dump(value) + text[node.end :]
    if parent is None:
        raise JsoncError("cannot set a path on an empty parent")
    blob = nest(remaining[1:], value)
    if isinstance(seg, str):
        if parent.kind != "object":
            raise JsoncError(f"expected object setting {path_str(path)}")
        return _insert_into_object(text, parent, seg, blob)
    if isinstance(seg, dict) and "index" in seg:
        if parent.kind != "array":
            raise JsoncError(f"expected array setting {path_str(path)}")
        return _set_index(text, parent, int(seg["index"]), blob)
    if isinstance(seg, dict) and (seg.get("append") or "where" in seg):
        if parent.kind != "array":
            raise JsoncError(f"expected array setting {path_str(path)}")
        if isinstance(seg, dict) and "where" in seg and remaining[1:] and isinstance(blob, dict):
            blob = {**seg["where"], **blob}
        elif isinstance(seg, dict) and "where" in seg and not remaining[1:]:
            pass
        return _append_to_array(text, parent, [blob])
    raise JsoncError(f"cannot set {path_str(path)}")


def unset_path(text: str, path: list) -> str:
    if not path:
        raise JsoncError("cannot unset the document root")
    root = parse_jsonc(text)
    parent = root
    if len(path) > 1:
        parent_node, _, seg, _ = locate(root, path[:-1])
        if parent_node is None:
            return text
        parent = parent_node
    item = _find_item(parent, path[-1])
    if item is None:
        return text
    return _delete_item(text, parent, item)


def get_path(value: Any, path: list) -> Any:
    cur = value
    for seg in path:
        if isinstance(seg, str):
            if not isinstance(cur, dict) or seg not in cur:
                return MISSING
            cur = cur[seg]
        elif isinstance(seg, dict) and "index" in seg:
            idx = int(seg["index"])
            if not isinstance(cur, list) or idx < 0 or idx >= len(cur):
                return MISSING
            cur = cur[idx]
        elif isinstance(seg, dict) and "where" in seg:
            if not isinstance(cur, list):
                return MISSING
            found = MISSING
            for elem in cur:
                if isinstance(elem, dict) and _where_match(elem, seg["where"]):
                    found = elem
                    break
            if found is MISSING:
                return MISSING
            cur = found
        else:
            return MISSING
    return cur


def py_set(value: Any, path: list, new: Any) -> Any:
    if not path:
        return new
    seg = path[0]
    if isinstance(seg, str):
        obj = dict(value) if isinstance(value, dict) else {}
        if path[1:]:
            child = obj[seg] if isinstance(obj.get(seg), (dict, list)) else {}
            obj[seg] = py_set(child, path[1:], new)
        else:
            obj[seg] = new
        return obj
    if isinstance(seg, dict) and "index" in seg:
        idx = int(seg["index"])
        arr = list(value) if isinstance(value, list) else []
        while len(arr) < idx:
            arr.append(None)
        if path[1:]:
            base = arr[idx] if idx < len(arr) and arr[idx] is not None else {}
            child = py_set(base, path[1:], new)
        else:
            child = new
        if idx == len(arr):
            arr.append(child)
        else:
            arr[idx] = child
        return arr
    if isinstance(seg, dict) and seg.get("append"):
        arr = list(value) if isinstance(value, list) else []
        arr.append(py_set({}, path[1:], new) if path[1:] else new)
        return arr
    if isinstance(seg, dict) and "where" in seg:
        arr = list(value) if isinstance(value, list) else []
        idx = None
        for i, elem in enumerate(arr):
            if isinstance(elem, dict) and _where_match(elem, seg["where"]):
                idx = i
                break
        if idx is None:
            if path[1:]:
                elem = py_set(dict(seg["where"]), path[1:], new)
            else:
                elem = new
            arr.append(elem)
        else:
            arr[idx] = py_set(arr[idx], path[1:], new) if path[1:] else new
        return arr
    raise JsoncError(f"bad path segment {seg!r}")


def py_unset(value: Any, path: list) -> Any:
    if not path or value is MISSING:
        return value
    seg = path[0]
    if isinstance(seg, str):
        if not isinstance(value, dict) or seg not in value:
            return value
        obj = dict(value)
        if path[1:]:
            obj[seg] = py_unset(obj[seg], path[1:])
        else:
            del obj[seg]
        return obj
    if isinstance(seg, dict) and "index" in seg:
        idx = int(seg["index"])
        if not isinstance(value, list) or idx < 0 or idx >= len(value):
            return value
        arr = list(value)
        if path[1:]:
            arr[idx] = py_unset(arr[idx], path[1:])
        else:
            del arr[idx]
        return arr
    if isinstance(seg, dict) and "where" in seg:
        if not isinstance(value, list):
            return value
        arr = list(value)
        for i, elem in enumerate(arr):
            if isinstance(elem, dict) and _where_match(elem, seg["where"]):
                if path[1:]:
                    arr[i] = py_unset(elem, path[1:])
                else:
                    del arr[i]
                break
        return arr
    return value


def is_age(value: Any) -> bool:
    return isinstance(value, dict) and value.get("$editorSync") == "age" and "file" in value and "identity" in value


def chezmoi_root(source: Path) -> Path:
    return source.parent


def default_fleek_root() -> Path:
    """Find the writable fleek checkout used by direct invocations."""
    configured = os.environ.get("FLEEK_CONFIG_DIR")
    if configured:
        return Path(configured).expanduser()
    cwd = Path.cwd()
    if (cwd / "chezmoi" / ".editor-config").is_dir():
        return cwd
    return Path.home() / ".local/share/fleek"


def default_source() -> Path:
    return default_fleek_root() / "chezmoi" / ".editor-config"


def default_host() -> str:
    """Lowercased user@host, matching the home-manager configuration name."""
    import getpass

    user = getpass.getuser()
    host = os.uname().nodename.split(".")[0]
    return f"{user}@{host}".lower()


def fleek_bin(name: str) -> Path:
    return default_fleek_root() / "bin" / name


def expand_identity(identity: str) -> str:
    return os.path.expanduser(identity)


def age_file(source: Path, ref: dict) -> Path:
    return chezmoi_root(source) / ref["file"]


def decrypt_age(source: Path, ref: dict) -> Any:
    path = age_file(source, ref)
    identity = expand_identity(ref["identity"])
    if not path.is_file():
        raise SystemExit(f"editor-sync: encrypted secret not found: {path}")
    proc = subprocess.run(
        ["age", "--decrypt", "-i", identity, str(path)],
        check=False,
        capture_output=True,
    )
    if proc.returncode != 0:
        sys.stderr.write(proc.stderr.decode(errors="replace"))
        raise SystemExit(f"editor-sync: failed to decrypt {path}")
    try:
        return json.loads(proc.stdout.decode())
    except json.JSONDecodeError as exc:
        raise SystemExit(f"editor-sync: decrypted secret is not JSON: {path}") from exc


def reveal(source: Path, value: Any) -> Any:
    if is_age(value):
        return decrypt_age(source, value)
    return value


def encrypt_with_helper(key_path: Path, value: Any) -> str:
    script = "chezmoi-age-encrypt-ssh" if key_path.name.endswith(".pub") else "chezmoi-age-encrypt-age"
    helper = fleek_bin(script)
    if not helper.is_file():
        raise SystemExit(f"editor-sync: helper not found: {helper}")
    payload = json.dumps(value, ensure_ascii=False)
    proc = subprocess.run(
        [str(helper), str(key_path)],
        input=payload.encode(),
        check=False,
        capture_output=True,
    )
    if proc.returncode != 0:
        sys.stderr.write(proc.stderr.decode(errors="replace"))
        raise SystemExit(f"editor-sync: {script} failed")
    return proc.stdout.decode()


def list_age_keys() -> list[Path]:
    folder = Path.home() / ".age"
    if not folder.is_dir():
        return []
    keys = []
    for path in sorted(folder.iterdir()):
        if path.is_file() and not path.name.endswith(".pub") and not path.name.startswith("."):
            keys.append(path)
    return keys


def identity_for(key_path: Path) -> str:
    try:
        home = key_path.resolve().relative_to(Path.home().resolve())
        return "~/" + home.as_posix()
    except ValueError:
        return str(key_path)


def slug(path: list) -> str:
    parts = []
    for seg in path:
        if isinstance(seg, str):
            parts.append(seg.replace("/", "_"))
        elif isinstance(seg, dict) and "index" in seg:
            parts.append(f"idx{seg['index']}")
        elif isinstance(seg, dict) and seg.get("append"):
            parts.append("append")
        else:
            parts.append(json.dumps(seg, sort_keys=True, ensure_ascii=False))
    raw = "__".join(parts) or "root"
    return "".join(ch if ch.isalnum() or ch in "._-" else "_" for ch in raw)


@dataclass(frozen=True)
class Layer:
    scope: str  # shared, host, local
    editor: str  # common, vscode, cursor
    host: str = ""

    def label(self) -> str:
        who = "all hosts" if self.scope == "shared" else (self.host if self.scope == "host" else "this machine")
        ed = "common" if self.editor == "common" else ("VSCode" if self.editor == "vscode" else "Cursor")
        if self.scope == "local":
            return f"{ed}, local"
        return f"{ed}, {who}"

    def name(self) -> str:
        if self.scope == "local":
            return f"local/{self.editor}"
        if self.scope == "host":
            return f"host/{self.host}/{self.editor}"
        return self.editor

    def secret_dir(self) -> str:
        if self.scope == "host":
            return f"hosts/{self.host}/{self.editor}"
        if self.scope == "local":
            return f"local/{self.editor}"
        return self.editor


def parse_layer(text: str, host: str) -> Layer:
    parts = text.split("/")
    if parts[0] == "local" and len(parts) == 2 and parts[1] in ("common", "vscode", "cursor"):
        return Layer("local", parts[1])
    if parts[0] == "host" and len(parts) == 3 and parts[2] in ("common", "vscode", "cursor"):
        return Layer("host", parts[2], parts[1].lower())
    if len(parts) == 1 and parts[0] in ("common", "vscode", "cursor"):
        return Layer("shared", parts[0], host)
    raise SystemExit(
        "editor-sync: layer must be common, vscode, cursor, "
        "host/<user@host>/{common,vscode,cursor}, or local/{common,vscode,cursor}"
    )


def placement_layer(choice: str, editor: str, host: str) -> Layer:
    if choice == "a":
        return Layer("shared", "common", host)
    if choice == "e":
        return Layer("shared", editor, host)
    if choice == "A":
        return Layer("host", "common", host)
    if choice == "E":
        return Layer("host", editor, host)
    raise SystemExit(f"editor-sync: bad placement {choice}")


class Store:
    def __init__(self, source: Path, host: str):
        self.source = source
        self.host = host
        self.texts: dict[Path, str] = {}
        self.raw: dict[Path, bytes] = {}
        self.deletes: list[Path] = []

    def read(self, path: Path) -> str | None:
        if path in self.texts:
            return self.texts[path]
        if path.is_file():
            return path.read_text()
        return None

    def write(self, path: Path, text: str) -> None:
        if path.is_relative_to(self.source) or str(path).startswith(str(chezmoi_root(self.source) / ".chezmoisecrets")):
            if '"$editorSync"' not in text and "$editorSync" in text:
                pass
        self.texts[path] = text if text.endswith("\n") or text == "" else text + "\n"

    def write_bytes(self, path: Path, data: bytes) -> None:
        self.raw[path] = data

    def delete(self, path: Path) -> None:
        self.deletes.append(path)
        self.raw.pop(path, None)
        self.texts.pop(path, None)

    def commit(self) -> None:
        for path, text in self.texts.items():
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text)
        for path, data in self.raw.items():
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
        for path in self.deletes:
            if path.is_file() and path not in self.raw and path not in self.texts:
                path.unlink()


def doc_path(source: Path, kind: str, layer: Layer, snippet: str | None) -> Path:
    if layer.scope == "local":
        base = Path.home() / ".config" / "editor-sync" / "local"
        if kind == "settings":
            return base / f"{layer.editor}.jsonc"
        if kind == "snippets":
            return base / "snippets" / layer.editor / f"{snippet}.jsonc"
        return base / kind / f"{layer.editor}.jsonc"
    if layer.scope == "host":
        base = source / "hosts" / layer.host
    else:
        base = source
    if kind == "snippets":
        folder = base / "snippets" / layer.editor
        return folder / f"{snippet}.jsonc"
    if kind == "extensions":
        return base / "extensions" / f"{layer.editor}.json"
    return base / kind / f"{layer.editor}.jsonc"


def empty_overlay() -> str:
    return '{\n    "set": [],\n    "unset": []\n}\n'


def empty_extensions() -> str:
    return '{\n    "add": [],\n    "remove": []\n}\n'


def load_overlay(store: Store, path: Path) -> dict:
    text = store.read(path)
    if text is None or not text.strip():
        return {"set": [], "unset": []}
    data = loads_jsonc(text)
    data.setdefault("set", [])
    data.setdefault("unset", [])
    return data


def save_overlay(store: Store, path: Path, data: dict) -> None:
    store.write(path, dump({"set": data.get("set", []), "unset": data.get("unset", [])}) + "\n")


def load_ext(store: Store, path: Path) -> dict:
    text = store.read(path)
    if text is None or not text.strip():
        return {"add": [], "remove": []}
    data = loads_jsonc(text)
    if isinstance(data, list):
        return {"add": data, "remove": []}
    data.setdefault("add", [])
    data.setdefault("remove", [])
    return data


def save_ext(store: Store, path: Path, data: dict) -> None:
    add = sorted(set(data.get("add", [])))
    remove = sorted(set(data.get("remove", [])) - set(add))
    store.write(path, dump({"add": add, "remove": remove}) + "\n")


def common_text(store: Store, kind: str, snippet: str | None) -> str:
    path = doc_path(store.source, kind, Layer("shared", "common"), snippet)
    text = store.read(path)
    if text is None:
        raise SystemExit(f"editor-sync: missing {path}")
    return text


def overlay_layers(editor: str, host: str) -> list[Layer]:
    return [
        Layer("shared", editor, host),
        Layer("host", "common", host),
        Layer("host", editor, host),
        Layer("local", "common"),
        Layer("local", editor),
    ]


def shared_clear_layers(editor: str, host: str) -> list[Layer]:
    """Layers cleared when a value is written to shared common."""
    return [
        Layer("shared", "vscode", host),
        Layer("shared", "cursor", host),
        Layer("host", "common", host),
        Layer("host", "vscode", host),
        Layer("host", "cursor", host),
    ]


def apply_overlay_text(source: Path, text: str, overlay: dict) -> str:
    for path in overlay.get("unset", []):
        try:
            parse_jsonc(text)
        except JsoncError:
            break
        text = unset_path(text, path)
    for op in overlay.get("set", []):
        value = op["value"]
        if is_age(value):
            value = decrypt_age(source, value)
        text = set_path(text, op["path"], value)
    return text


def decrypt_markers(source: Path, text: str) -> str:
    try:
        root = parse_jsonc(text)
    except JsoncError:
        return text
    spans = []

    def walk(node: Node) -> None:
        if node.kind == "object":
            py = to_py(node)
            if is_age(py):
                spans.append((node.start, node.end, decrypt_age(source, py)))
                return
            for item in node.items:
                walk(item.value)
        elif node.kind == "array":
            for item in node.items:
                walk(item.value)

    walk(root)
    for start, end, value in reversed(spans):
        text = text[:start] + dump(value) + text[end:]
    return text


def render_text(store: Store, editor: str, kind: str, snippet: str | None) -> str:
    text = common_text(store, kind, snippet)
    for layer in overlay_layers(editor, store.host):
        path = doc_path(store.source, kind, layer, snippet)
        if layer.scope != "local" and store.read(path) is None and not path.is_file():
            continue
        if layer.scope == "local" and store.read(path) is None:
            continue
        if kind == "extensions":
            continue
        overlay = load_overlay(store, path)
        text = apply_overlay_text(store.source, text, overlay)
    text = decrypt_markers(store.source, text)
    return text


def py_from_text(text: str) -> Any:
    return loads_jsonc(text)


def _inherit_common(store: Store, kind: str, layer: Layer, snippet: str | None, path: list) -> tuple[Any, str]:
    if layer.scope != "shared":
        return MISSING, "(absent)"
    inherited, _note = layer_contribution(
        store, kind, Layer("shared", "common", layer.host), snippet, path
    )
    if inherited is MISSING:
        return MISSING, "(absent)"
    return inherited, "from common"


def layer_contribution(store: Store, kind: str, layer: Layer, snippet: str | None, path: list) -> tuple[Any, str]:
    """Value this layer itself stores at path, and a short note."""
    if kind == "extensions":
        return MISSING, "(absent)"
    if layer.editor == "common" and layer.scope == "shared":
        text = common_text(store, kind, snippet)
        value = get_path(py_from_text(text), path)
        if value is MISSING:
            return MISSING, "(absent)"
        if is_age(value):
            value = decrypt_age(store.source, value)
        return value, ""
    file = doc_path(store.source, kind, layer, snippet)
    if store.read(file) is None and not file.is_file():
        return _inherit_common(store, kind, layer, snippet, path)
    data = load_overlay(store, file)
    for unset in data.get("unset", []):
        if paths_equal(unset, path):
            return MISSING, "(absent — unset)"
    for op in data.get("set", []):
        if paths_equal(op["path"], path):
            value = op["value"]
            if is_age(value):
                value = decrypt_age(store.source, value)
            return value, f"{layer.editor} override"
    return _inherit_common(store, kind, layer, snippet, path)


def ext_membership(store: Store, layer: Layer) -> dict:
    path = doc_path(store.source, "extensions", layer, None)
    if store.read(path) is None and not path.is_file():
        return {"add": [], "remove": []}
    return load_ext(store, path)


def desired_extensions(store: Store, editor: str) -> set[str]:
    ids: set[str] = set()
    layers = [
        Layer("shared", "common", store.host),
        Layer("shared", editor, store.host),
        Layer("host", "common", store.host),
        Layer("host", editor, store.host),
    ]
    for layer in layers:
        data = ext_membership(store, layer)
        ids.update(data.get("add", []))
        ids.difference_update(data.get("remove", []))
    return ids


def extensions_json(editor: str) -> Path:
    return {
        "vscode": Path.home() / ".vscode" / "extensions" / "extensions.json",
        "cursor": Path.home() / ".cursor" / "extensions" / "extensions.json",
    }[editor]


def installed_extensions(editor: str) -> set[str] | None:
    path = extensions_json(editor)
    if not path.is_file():
        return None
    try:
        data = json.loads(path.read_text())
    except (OSError, json.JSONDecodeError):
        return None
    ids = set()
    if not isinstance(data, list):
        return None
    for item in data:
        ident = item.get("identifier") if isinstance(item, dict) else None
        if isinstance(ident, dict) and ident.get("id"):
            ids.add(ident["id"])
    return ids


def live_file(editor: str, kind: str, snippet: str | None = None) -> Path:
    if editor == "vscode":
        root = Path.home() / ".config" / "Code" / "User"
    else:
        root = Path.home() / ".config" / "Cursor" / "User"
    if kind == "settings":
        return root / "settings.json"
    if kind == "keybindings":
        return root / "keybindings.json"
    if kind == "snippets":
        return root / "snippets" / f"{snippet}.json"
    raise SystemExit(f"editor-sync: no live file for {kind}")


def snippet_names(store: Store, editor: str) -> set[str]:
    names = set()
    for layer in [Layer("shared", "common")] + overlay_layers(editor, store.host):
        folder = doc_path(store.source, "snippets", layer, "x").parent
        if folder.is_dir():
            for path in folder.glob("*.jsonc"):
                names.add(path.stem)
    live = live_file(editor, "snippets", "x").parent
    if live.is_dir():
        for path in live.glob("*.json"):
            names.add(path.stem)
    return names


def require_tty() -> None:
    if not sys.stdin.isatty() or not sys.stdout.isatty():
        raise SystemExit("editor-sync: import and move must be run in an interactive terminal")


def prompt(question: str, allowed: str) -> str:
    allowed_set = set(allowed)
    while True:
        try:
            answer = input(question).strip()
        except EOFError:
            raise Quit() from None
        if not answer:
            continue
        choice = answer[0]
        if choice in allowed_set:
            return choice
        print(f"  choose one of: {' '.join(allowed)}")


def format_value(value: Any, live: Any) -> list[str]:
    if value is MISSING:
        return []
    text = dump(value)
    if len(text) <= 80 and "\n" not in text.strip():
        return [text]
    live_text = dump(live) if live is not MISSING else ""
    diff = difflib.unified_diff(
        text.splitlines(),
        live_text.splitlines(),
        fromfile="layer",
        tofile="live",
        lineterm="",
    )
    lines = list(diff)
    return lines or text.splitlines()


def print_layers(store: Store, kind: str, editor: str, snippet: str | None, path: list, live: Any) -> None:
    layers = [
        Layer("shared", "common", store.host),
        Layer("shared", "vscode", store.host),
        Layer("shared", "cursor", store.host),
        Layer("host", "common", store.host),
        Layer("host", "vscode", store.host),
        Layer("host", "cursor", store.host),
        Layer("local", "common"),
        Layer("local", editor),
    ]
    for layer in layers:
        if layer.scope == "local":
            value, note = layer_contribution(store, kind, layer, snippet, path)
            if value is MISSING and note == "(absent)":
                continue
        else:
            value, note = layer_contribution(store, kind, layer, snippet, path)
        label = f"{layer.label():<28}"
        if value is MISSING:
            print(f"  {label}: {note}")
            continue
        rendered = format_value(value, live)
        if len(rendered) == 1:
            suffix = f"    ({note})" if note else ""
            print(f"  {label}: {rendered[0]}{suffix}")
        else:
            print(f"  {label}:")
            for line in rendered:
                print(f"    {line}")


def creation_notes(base: Any, path: list) -> list[str]:
    notes = []
    cur = base
    built = []
    for seg in path:
        built.append(seg)
        if isinstance(seg, str):
            if not isinstance(cur, dict) or seg not in cur:
                notes.append(f"Writing this creates {path_str(built)}.")
                return notes
            cur = cur[seg]
        elif isinstance(seg, dict) and "index" in seg:
            idx = int(seg["index"])
            if not isinstance(cur, list):
                notes.append(f"Writing this creates {path_str(built)}.")
                return notes
            if idx >= len(cur):
                missing = ", ".join(str(i) for i in range(len(cur), idx))
                if missing:
                    notes.append(
                        f"array length is {len(cur)}; setting index {idx} inserts null at indexes {missing}."
                    )
                return notes
            cur = cur[idx]
        elif isinstance(seg, dict) and (seg.get("append") or "where" in seg):
            if isinstance(seg, dict) and seg.get("append"):
                notes.append("this appends one element; it does not use an index.")
            elif isinstance(seg, dict) and "where" in seg:
                if not isinstance(cur, list) or not any(
                    isinstance(e, dict) and _where_match(e, seg["where"]) for e in cur
                ):
                    notes.append("no matching element; this appends one.")
            return notes
        else:
            return notes
    return notes


def clear_overlay_path(store: Store, kind: str, layer: Layer, snippet: str | None, path: list) -> None:
    file = doc_path(store.source, kind, layer, snippet)
    if store.read(file) is None and not file.is_file():
        return
    if kind == "extensions":
        return
    data = load_overlay(store, file)
    data["set"] = [op for op in data["set"] if not paths_equal(op["path"], path)]
    data["unset"] = [item for item in data["unset"] if not paths_equal(item, path)]
    if data["set"] or data["unset"]:
        save_overlay(store, file, data)
    elif file.is_file() or file in store.texts:
        save_overlay(store, file, data)


def write_common_value(store: Store, kind: str, snippet: str | None, path: list, value: Any, remove: bool) -> None:
    file = doc_path(store.source, kind, Layer("shared", "common"), snippet)
    text = store.read(file)
    if text is None:
        raise SystemExit(f"editor-sync: missing {file}")
    if remove:
        text = unset_path(text, path)
    else:
        text = set_path(text, path, value)
    store.write(file, text)


def write_overlay_value(store: Store, kind: str, layer: Layer, snippet: str | None, path: list, value: Any, remove: bool) -> None:
    file = doc_path(store.source, kind, layer, snippet)
    data = load_overlay(store, file) if (store.read(file) or file.is_file()) else {"set": [], "unset": []}
    data["set"] = [op for op in data["set"] if not paths_equal(op["path"], path)]
    data["unset"] = [item for item in data["unset"] if not paths_equal(item, path)]
    if remove:
        data["unset"].append(path)
    else:
        data["set"].append({"path": path, "value": value})
    save_overlay(store, file, data)


def drop_noop(store: Store, kind: str, layer: Layer, snippet: str | None, editor: str, path: list) -> None:
    """Drop a set/unset that does not change the result of the layers below it."""
    if layer.scope == "local" or kind == "extensions":
        return
    file = doc_path(store.source, kind, layer, snippet)
    if layer.editor == "common" and layer.scope == "shared":
        return
    data = load_overlay(store, file)
    below = _value_below(store, kind, layer, snippet, editor, path)
    new_sets = []
    for op in data["set"]:
        if not paths_equal(op["path"], path):
            new_sets.append(op)
            continue
        revealed = reveal(store.source, op["value"])
        if revealed == below:
            continue
        new_sets.append(op)
    new_unsets = []
    for item in data["unset"]:
        if paths_equal(item, path) and below is MISSING:
            continue
        new_unsets.append(item)
    data["set"] = new_sets
    data["unset"] = new_unsets
    save_overlay(store, file, data)


def _value_below(store: Store, kind: str, layer: Layer, snippet: str | None, editor: str, path: list) -> Any:
    text = common_text(store, kind, snippet)
    order = []
    if layer.scope == "shared" and layer.editor != "common":
        order = []
    elif layer.scope == "host" and layer.editor == "common":
        order = [Layer("shared", editor)]
    elif layer.scope == "host" and layer.editor != "common":
        order = [Layer("shared", editor), Layer("host", "common", layer.host)]
    for item in order:
        file = doc_path(store.source, kind, item, snippet)
        if store.read(file) is None and not file.is_file():
            continue
        text = apply_overlay_text(store.source, text, load_overlay(store, file))
    text = decrypt_markers(store.source, text)
    return get_path(py_from_text(text), path)


def place_value(
    store: Store,
    kind: str,
    editor: str,
    snippet: str | None,
    path: list,
    value: Any,
    choice: str,
    remove: bool,
) -> str:
    layer = placement_layer(choice, editor, store.host)
    if choice == "a":
        if is_age(value):
            raise SystemExit("editor-sync: refusing to write a secret marker check")
        write_common_value(store, kind, snippet, path, value, remove)
        for item in shared_clear_layers(editor, store.host):
            clear_overlay_path(store, kind, item, snippet, path)
        return f"{'remove' if remove else 'set'} {path_str(path)} on common, all hosts"
    if layer.scope == "shared" and layer.editor != "common":
        write_overlay_value(store, kind, layer, snippet, path, value, remove)
        clear_overlay_path(store, kind, Layer("host", editor, store.host), snippet, path)
        drop_noop(store, kind, layer, snippet, editor, path)
        ed = "VSCode" if editor == "vscode" else "Cursor"
        return f"{'remove' if remove else 'set'} {path_str(path)} on {ed}, all hosts"
    if choice == "A":
        write_overlay_value(store, kind, layer, snippet, path, value, remove)
        for ed in ("vscode", "cursor"):
            clear_overlay_path(store, kind, Layer("host", ed, store.host), snippet, path)
        drop_noop(store, kind, layer, snippet, editor, path)
        return f"{'remove' if remove else 'set'} {path_str(path)} on common, {store.host}"
    write_overlay_value(store, kind, layer, snippet, path, value, remove)
    drop_noop(store, kind, layer, snippet, editor, path)
    ed = "VSCode" if editor == "vscode" else "Cursor"
    return f"{'remove' if remove else 'set'} {path_str(path)} on {ed}, {store.host}"


def place_local(store: Store, kind: str, editor: str, snippet: str | None, path: list, value: Any, which: str) -> str:
    layer = Layer("local", "common" if which == "c" else editor)
    write_overlay_value(store, kind, layer, snippet, path, value, False)
    who = "both editors" if which == "c" else editor
    return f"store {path_str(path)} locally for {who}"


def age_ref(layer: Layer, path: list, identity: str) -> dict:
    rel = f".chezmoisecrets/editor-sync/{layer.secret_dir()}/{slug(path)}.age"
    return {"$editorSync": "age", "file": rel, "identity": identity}


def choose_age_key() -> Path:
    keys = list_age_keys()
    if not keys:
        raise SystemExit("editor-sync: no age keys in ~/.age/; only the local store is available")
    print("  age keys in ~/.age/:")
    for i, key in enumerate(keys, 1):
        print(f"    [{i}] {key.name}")
    while True:
        answer = input("  key number: ").strip()
        if answer.isdigit() and 1 <= int(answer) <= len(keys):
            return keys[int(answer) - 1]
        print("  enter a number from the list")


def secret_flow(
    store: Store,
    editor: str,
    snippet: str | None,
    path: list,
    value: Any,
    actions: list[str],
) -> None:
    print("  [g] age-encrypt into a chezmoi layer    [l] store only on this machine    [q] quit")
    mode = prompt("  secret store: ", "glq")
    if mode == "q":
        raise Quit()
    if mode == "l":
        which = prompt("  [c] local common (both editors)   [e] this editor only   [q] quit\n  local: ", "ceq")
        if which == "q":
            raise Quit()
        actions.append(place_local(store, "settings", editor, snippet, path, value, which))
        return
    key = choose_age_key()
    print("  [a] all editors, all hosts   [e] this editor, all hosts")
    print("  [A] all editors, this host   [E] this editor, this host   [q] quit")
    choice = prompt("  chezmoi layer: ", "aeAEq")
    if choice == "q":
        raise Quit()
    layer = placement_layer(choice, editor, store.host)
    ciphertext = encrypt_with_helper(key, value)
    ref = age_ref(layer, path, identity_for(key))
    dest = chezmoi_root(store.source) / ref["file"]
    store.write_bytes(dest, ciphertext.encode())
    # place_value would reveal-check; write the reference directly.
    if choice == "a":
        write_common_value(store, "settings", snippet, path, ref, False)
        for item in shared_clear_layers(editor, store.host):
            clear_overlay_path(store, "settings", item, snippet, path)
    elif choice == "e":
        write_overlay_value(store, "settings", layer, snippet, path, ref, False)
        clear_overlay_path(store, "settings", Layer("host", editor, store.host), snippet, path)
    elif choice == "A":
        write_overlay_value(store, "settings", layer, snippet, path, ref, False)
        for ed in ("vscode", "cursor"):
            clear_overlay_path(store, "settings", Layer("host", ed, store.host), snippet, path)
    else:
        write_overlay_value(store, "settings", layer, snippet, path, ref, False)
    actions.append(f"age-encrypt {path_str(path)} with {key.name} into {layer.name()} ({ref['file']})")


def diff_units(src: Any, live: Any, path: list, units: list) -> None:
    if isinstance(src, dict) and isinstance(live, dict):
        keys = list(src.keys())
        for key in live.keys():
            if key not in src:
                keys.append(key)
        for key in keys:
            child = path + [key]
            if key not in src or key not in live:
                units.append(child)
            else:
                diff_units(src[key], live[key], child, units)
        return
    if isinstance(src, list) or isinstance(live, list):
        units.append(path)
        return
    if src != live:
        units.append(path)


def ask_placement(kind: str, editor: str, remove: bool) -> str:
    ed = "VSCode" if editor == "vscode" else "Cursor"
    print("  [s] do not merge")
    print(f"  [a] all editors, all hosts    [e] {ed} only, all hosts")
    print(f"  [A] all editors, this host    [E] {ed} only, this host")
    extra = "k" if kind == "settings" and not remove else ""
    if extra:
        print("  [k] this value is a secret")
    print("  [p] decide on the parent value instead   [q] quit")
    return prompt("  choice: ", "saeAE" + extra + "pq")


def decide_unit(
    store: Store,
    kind: str,
    editor: str,
    snippet: str | None,
    path: list,
    src: Any,
    live: Any,
    actions: list[str],
    base_for_notes: Any,
) -> None:
    removed = live is MISSING and src is not MISSING
    added = src is MISSING and live is not MISSING
    state = "removed" if removed else ("added" if added else "changed")
    ed = "Cursor" if editor == "cursor" else "VSCode"
    print(f"\npath {path_str(path)}: {state} in {ed} on {store.host}")
    print_layers(store, kind, editor, snippet, path, live if live is not MISSING else src)
    if live is not MISSING:
        shown = format_value(live, src if src is not MISSING else live)
        if len(shown) == 1:
            print(f"  {'live':<28}: {shown[0]}")
        else:
            print("  live:")
            for line in shown:
                print(f"    {line}")
    else:
        print(f"  {'live':<28}: (absent)")
    for note in creation_notes(base_for_notes, path):
        print(f"  {note}")
    choice = ask_placement(kind, editor, removed or (live is MISSING))
    if choice == "q":
        raise Quit()
    if choice == "p":
        raise Widen()
    if choice == "s":
        actions.append(f"skip {path_str(path)}")
        return
    if choice == "k":
        if live is MISSING:
            print("  nothing live to store as a secret; skipping")
            actions.append(f"skip {path_str(path)}")
            return
        secret_flow(store, editor, snippet, path, live, actions)
        return
    value = live if live is not MISSING else None
    remove = live is MISSING
    actions.append(place_value(store, kind, editor, snippet, path, value, choice, remove))


def align_array(
    store: Store,
    kind: str,
    editor: str,
    snippet: str | None,
    path: list,
    src: Any,
    live: Any,
    actions: list[str],
) -> None:
    print(f"\npath {path_str(path)}: array differs in {'Cursor' if editor == 'cursor' else 'VSCode'}")
    print_layers(store, kind, editor, snippet, path, live if isinstance(live, list) else MISSING)
    print("  How should this array be compared?")
    print("  [w] whole array, one decision")
    print("  [i] by index (order matters)")
    print("  [c] by element content (order does not matter)")
    print("  [s] do not merge   [q] quit")
    choice = prompt("  array: ", "wicsq")
    if choice == "q":
        raise Quit()
    if choice == "s":
        actions.append(f"skip {path_str(path)}")
        return
    if choice == "w":
        decide_unit(store, kind, editor, snippet, path, src, live, actions, src if src is not MISSING else {})
        return
    src_list = src if isinstance(src, list) else []
    live_list = live if isinstance(live, list) else []
    if choice == "i":
        n = max(len(src_list), len(live_list))
        for i in range(n):
            s_item = src_list[i] if i < len(src_list) else MISSING
            l_item = live_list[i] if i < len(live_list) else MISSING
            child = path + [{"index": i}]
            if s_item == l_item:
                continue
            if isinstance(s_item, dict) and isinstance(l_item, dict):
                walk(store, kind, editor, snippet, child, s_item, l_item, actions)
            else:
                try:
                    decide_unit(store, kind, editor, snippet, child, s_item, l_item, actions, src_list)
                except Widen:
                    decide_unit(store, kind, editor, snippet, path, src, live, actions, {})
                    return
        return
    fields = suggest_fields(src_list, live_list)
    if fields is not None:
        entered = input(f"  identity fields [{','.join(fields)}] (empty keeps this, or comma-separated): ").strip()
        if entered:
            fields = [part.strip() for part in entered.split(",") if part.strip()]
    else:
        fields = []
    pairs, src_left, live_left = match_elements(src_list, live_list, fields)
    for s_item, l_item in pairs:
        if s_item == l_item:
            continue
        where = {key: s_item[key] for key in fields} if fields else {"where-value": s_item}
        seg = {"where": where} if fields else {"index": src_list.index(s_item)}
        child = path + [seg]
        if isinstance(s_item, dict) and isinstance(l_item, dict):
            walk(store, kind, editor, snippet, child, s_item, l_item, actions)
        else:
            decide_unit(store, kind, editor, snippet, child, s_item, l_item, actions, src_list)
    for item in live_left:
        child = path + [{"append": True}]
        decide_unit(store, kind, editor, snippet, child, MISSING, item, actions, src_list)
    for item in src_left:
        where = {key: item[key] for key in fields} if fields and isinstance(item, dict) else None
        child = path + ([{"where": where}] if where else [{"index": src_list.index(item)}])
        decide_unit(store, kind, editor, snippet, child, item, MISSING, actions, src_list)


def suggest_fields(src: list, live: list) -> list[str] | None:
    elems = [e for e in list(src) + list(live) if isinstance(e, dict)]
    if elems and all(all(k in e for k in ("key", "command", "when")) for e in elems):
        return ["key", "command", "when"]
    return [] if elems else None


def match_elements(src: list, live: list, fields: list[str]) -> tuple[list, list, list]:
    used = set()
    pairs = []
    src_left = []
    for s_item in src:
        found = None
        for i, l_item in enumerate(live):
            if i in used:
                continue
            if fields and isinstance(s_item, dict) and isinstance(l_item, dict):
                if all(s_item.get(f) == l_item.get(f) for f in fields):
                    found = i
                    break
            elif not fields and s_item == l_item:
                found = i
                break
        if found is None:
            src_left.append(s_item)
        else:
            used.add(found)
            pairs.append((s_item, live[found]))
    live_left = [item for i, item in enumerate(live) if i not in used]
    return pairs, src_left, live_left


def walk(store: Store, kind: str, editor: str, snippet: str | None, path: list, src: Any, live: Any, actions: list[str]) -> None:
    if isinstance(src, list) or isinstance(live, list):
        if src == live:
            return
        align_array(store, kind, editor, snippet, path, src, live, actions)
        return
    if isinstance(src, dict) and isinstance(live, dict):
        keys = list(dict.fromkeys(list(src.keys()) + [k for k in live.keys() if k not in src]))
        for key in keys:
            child = path + [key]
            s_item = src[key] if key in src else MISSING
            l_item = live[key] if key in live else MISSING
            if s_item == l_item:
                continue
            try:
                if isinstance(s_item, dict) and isinstance(l_item, dict):
                    walk(store, kind, editor, snippet, child, s_item, l_item, actions)
                elif isinstance(s_item, list) or isinstance(l_item, list):
                    align_array(store, kind, editor, snippet, child, s_item, l_item, actions)
                else:
                    decide_unit(store, kind, editor, snippet, child, s_item, l_item, actions, src)
            except Widen:
                decide_unit(store, kind, editor, snippet, path, src, live, actions, {})
                return
        return
    if src != live:
        decide_unit(store, kind, editor, snippet, path, src, live, actions, src if isinstance(src, (dict, list)) else {})


def import_document(store: Store, editor: str, kind: str, snippet: str | None, actions: list[str]) -> None:
    rendered = render_text(store, editor, kind, snippet)
    live_path = live_file(editor, kind, snippet)
    if not live_path.is_file():
        if kind == "snippets":
            return
        print(f"no live file {live_path}")
        return
    live = loads_jsonc(live_path.read_text())
    src = loads_jsonc(rendered)
    if src == live:
        print(f"{kind}{'' if not snippet else ' ' + snippet}: no changes")
        return
    walk(store, kind, editor, snippet, [], src, live, actions)
    if kind == "snippets" and snippet:
        ensure_snippet_templates(store, snippet)


def ensure_snippet_templates(store: Store, snippet: str) -> None:
    root = chezmoi_root(store.source)
    for editor, folder in (("vscode", "Code"), ("cursor", "Cursor")):
        dest = root / "dot_config" / folder / "User" / "snippets" / f"{snippet}.json.tmpl"
        if dest.is_file():
            continue
        body = (
            "{{ output (joinPath .chezmoi.sourceDir \"..\" \"programs\" \"editor-sync\" \"editor_sync.py\") \"render\" \"--source\" "
            "(joinPath .chezmoi.sourceDir \".editor-config\") \"--host\" (includeTemplate \"editor-sync-host\" .) "
            f"\"{editor}\" \"snippets\" \"{snippet}\" -}}\n"
        )
        store.write(dest, body)


def ext_lists_mention(store: Store, editor: str, ext_id: str) -> list[str]:
    lines = []
    layers = [
        Layer("shared", "common", store.host),
        Layer("shared", "vscode", store.host),
        Layer("shared", "cursor", store.host),
        Layer("host", "common", store.host),
        Layer("host", "vscode", store.host),
        Layer("host", "cursor", store.host),
    ]
    for layer in layers:
        data = ext_membership(store, layer)
        if ext_id in data.get("add", []):
            lines.append(f"  {layer.label()}: add")
        elif ext_id in data.get("remove", []):
            lines.append(f"  {layer.label()}: remove")
        else:
            lines.append(f"  {layer.label()}: (absent)")
    return lines


def mutate_ext(store: Store, layer: Layer, ext_id: str, action: str) -> None:
    file = doc_path(store.source, "extensions", layer, None)
    data = load_ext(store, file) if (store.read(file) or file.is_file()) else {"add": [], "remove": []}
    data["add"] = [item for item in data.get("add", []) if item != ext_id]
    data["remove"] = [item for item in data.get("remove", []) if item != ext_id]
    if action == "add":
        data["add"].append(ext_id)
    elif action == "remove":
        data["remove"].append(ext_id)
    save_ext(store, file, data)


def clear_ext(store: Store, layer: Layer, ext_id: str) -> None:
    file = doc_path(store.source, "extensions", layer, None)
    if store.read(file) is None and not file.is_file():
        return
    data = load_ext(store, file)
    before = (list(data["add"]), list(data["remove"]))
    data["add"] = [item for item in data["add"] if item != ext_id]
    data["remove"] = [item for item in data["remove"] if item != ext_id]
    if (data["add"], data["remove"]) != before:
        save_ext(store, file, data)


def place_extension(store: Store, editor: str, ext_id: str, choice: str, present: bool) -> str:
    layer = placement_layer(choice, editor, store.host)
    action = "add" if present else "remove"
    if choice == "a":
        for item in (
            Layer("shared", "vscode"),
            Layer("shared", "cursor"),
            Layer("host", "common", store.host),
            Layer("host", "vscode", store.host),
            Layer("host", "cursor", store.host),
        ):
            clear_ext(store, item, ext_id)
        if present:
            mutate_ext(store, Layer("shared", "common"), ext_id, "add")
        else:
            clear_ext(store, Layer("shared", "common"), ext_id)
        return f"{action} {ext_id} on common, all hosts"
    if choice == "e":
        mutate_ext(store, Layer("shared", editor), ext_id, action)
        clear_ext(store, Layer("host", editor, store.host), ext_id)
        return f"{action} {ext_id} on {editor}, all hosts"
    if choice == "A":
        mutate_ext(store, Layer("host", "common", store.host), ext_id, action)
        for ed in ("vscode", "cursor"):
            clear_ext(store, Layer("host", ed, store.host), ext_id)
        return f"{action} {ext_id} on common, {store.host}"
    mutate_ext(store, layer, ext_id, action)
    return f"{action} {ext_id} on {editor}, {store.host}"


def import_extensions(store: Store, editor: str, actions: list[str]) -> None:
    desired = desired_extensions(store, editor)
    installed = installed_extensions(editor)
    if installed is None:
        print(f"{editor}: extensions.json missing or unreadable; not treating that as an empty install")
        return
    extra = sorted(installed - desired)
    missing = sorted(desired - installed)
    if not extra and not missing:
        print(f"{editor} extensions: no changes")
        return
    ed = "Cursor" if editor == "cursor" else "VSCode"
    for ext_id in extra:
        print(f"\nextension {ext_id}: installed in {ed}, not in source")
        print("\n".join(ext_lists_mention(store, editor, ext_id)))
        print(f"  {ed} live: installed")
        choice = ask_placement("extensions", editor, False)
        if choice == "q":
            raise Quit()
        if choice == "p":
            print("  extensions are not nested")
            choice = "s"
        if choice == "s":
            actions.append(f"skip {ext_id}")
        else:
            actions.append(place_extension(store, editor, ext_id, choice, True))
    for ext_id in missing:
        print(f"\nextension {ext_id}: in source, not installed in {ed}")
        print("\n".join(ext_lists_mention(store, editor, ext_id)))
        print(f"  {ed} live: not installed")
        choice = ask_placement("extensions", editor, True)
        if choice == "q":
            raise Quit()
        if choice == "p":
            print("  extensions are not nested")
            choice = "s"
        if choice == "s":
            actions.append(f"skip {ext_id}")
        else:
            actions.append(place_extension(store, editor, ext_id, choice, False))


def cmd_render(args: argparse.Namespace) -> None:
    store = Store(Path(args.source), args.host)
    if args.kind == "snippets" and not args.snippet:
        raise SystemExit("editor-sync: render snippets requires the snippet file name")
    if args.editor not in EDITORS or args.kind not in ("settings", "keybindings", "snippets"):
        raise SystemExit("editor-sync: render expects vscode|cursor and settings|keybindings|snippets")
    sys.stdout.write(render_text(store, args.editor, args.kind, args.snippet))


def installed_editors() -> list[str]:
    """Editors whose user config or extensions directory exists on this machine."""
    found = []
    for editor in EDITORS:
        if live_file(editor, "settings").parent.is_dir() or extensions_json(editor).parent.is_dir():
            found.append(editor)
    return found


def split_import_args(words: list[str]) -> tuple[list[str], list[str]]:
    editors: list[str] = []
    kinds: list[str] = []
    for word in words:
        if word in EDITORS and not editors:
            editors.append(word)
        elif word in KINDS and not kinds:
            kinds.append(word)
        else:
            raise SystemExit(
                "editor-sync: usage: editor-sync import [vscode|cursor] "
                "[settings|keybindings|snippets|extensions]"
            )
    return editors or installed_editors(), kinds or list(KINDS)


def cmd_import(args: argparse.Namespace) -> None:
    require_tty()
    editors, kinds = split_import_args(args.words)
    if not editors:
        raise SystemExit("editor-sync: neither VS Code nor Cursor config was found in ~/.config")
    store = Store(Path(args.source), args.host)
    actions: list[str] = []
    try:
        for editor in editors:
            if len(editors) > 1:
                print(f"\n=== {'VSCode' if editor == 'vscode' else 'Cursor'} ===")
            for kind in kinds:
                if kind == "extensions":
                    import_extensions(store, editor, actions)
                elif kind == "snippets":
                    for name in sorted(snippet_names(store, editor)):
                        import_document(store, editor, kind, name, actions)
                else:
                    import_document(store, editor, kind, None, actions)
    except Quit:
        print("quit; nothing written")
        raise SystemExit(1) from None
    if not actions:
        print("nothing to write")
        return
    print("\nPending source edits:")
    for line in actions:
        print(f"  - {line}")
    answer = prompt("Write these changes? [y/N/q] ", "yYnNq")
    if answer.lower() != "y":
        print("nothing written")
        raise SystemExit(1)
    store.commit()
    print("wrote source files")


def find_ext_list(data: dict, ext_id: str) -> str | None:
    if ext_id in data.get("add", []):
        return "add"
    if ext_id in data.get("remove", []):
        return "remove"
    return None


def cmd_move(args: argparse.Namespace) -> None:
    require_tty()
    if args.kind not in KINDS:
        raise SystemExit(f"editor-sync: unknown kind {args.kind}")
    store = Store(Path(args.source), args.host)
    src = parse_layer(args.src_layer, store.host)
    dst = parse_layer(args.dst_layer, store.host)
    if args.kind == "extensions":
        if src.scope == "local" or dst.scope == "local":
            raise SystemExit("editor-sync: extensions are not stored in the local secret layer")
        move_extension(store, src, dst, args.target)
        return
    if args.kind == "snippets" and not args.snippet:
        raise SystemExit("editor-sync: move snippets requires --snippet NAME")
    try:
        path = json.loads(args.target)
    except json.JSONDecodeError as exc:
        raise SystemExit("editor-sync: path must be a JSON list, for example [\"editor.fontSize\"]") from exc
    if not isinstance(path, list):
        raise SystemExit("editor-sync: path must be a JSON list")
    move_value(store, args.kind, args.snippet, src, dst, path)


def move_extension(store: Store, src: Layer, dst: Layer, ext_id: str) -> None:
    data = ext_membership(store, src)
    which = find_ext_list(data, ext_id)
    if which is None:
        raise SystemExit(f"editor-sync: {ext_id} is not in {src.name()}")
    print(f"move extension {ext_id} ({which}) from {src.name()} to {dst.name()}")
    if prompt("Apply this move? [y/N/q] ", "yYnNq").lower() != "y":
        raise SystemExit(1)
    clear_ext(store, src, ext_id)
    mutate_ext(store, dst, ext_id, which)
    store.commit()
    print("moved")


def layer_value(store: Store, kind: str, layer: Layer, snippet: str | None, path: list) -> Any:
    value, _note = layer_contribution(store, kind, layer, snippet, path)
    return value


def move_value(store: Store, kind: str, snippet: str | None, src: Layer, dst: Layer, path: list) -> None:
    value = layer_value(store, kind, src, snippet, path)
    if value is MISSING:
        raise SystemExit(f"editor-sync: {path_str(path)} is not in {src.name()}")
    print(f"move {kind} {path_str(path)} from {src.name()} to {dst.name()}")
    print(f"  value: {dump(value)}")
    ref = _stored_age(store, kind, src, snippet, path)
    if ref and dst.scope != "local" and src.scope != "local":
        new_ref = age_ref(dst, path, ref["identity"])
        print(f"  ciphertext: {ref['file']} -> {new_ref['file']}")
    elif ref and dst.scope == "local":
        print(f"  decrypt {ref['file']} into the local file and delete the ciphertext")
    elif src.scope == "local" and dst.scope != "local":
        print("  plaintext will be age-encrypted; it will not be written into git")
    if prompt("Apply this move? [y/N/q] ", "yYnNq").lower() != "y":
        raise SystemExit(1)
    if src.scope == "local" and dst.scope != "local":
        key = choose_age_key()
        ciphertext = encrypt_with_helper(key, value)
        new_ref = age_ref(dst, path, identity_for(key))
        store.write_bytes(chezmoi_root(store.source) / new_ref["file"], ciphertext.encode())
        _remove_from_layer(store, kind, src, snippet, path)
        _put_on_layer(store, kind, dst, snippet, path, new_ref, False)
    elif ref and dst.scope == "local":
        plain = decrypt_age(store.source, ref)
        _remove_from_layer(store, kind, src, snippet, path)
        store.delete(age_file(store.source, ref))
        _put_on_layer(store, kind, dst, snippet, path, plain, False)
    elif ref and src.scope != "local":
        new_ref = age_ref(dst, path, ref["identity"])
        old = age_file(store.source, ref)
        data = store.raw.get(old)
        if data is None and old.is_file():
            data = old.read_bytes()
        if data is None:
            raise SystemExit(f"editor-sync: missing ciphertext {old}")
        new_path = chezmoi_root(store.source) / new_ref["file"]
        store.write_bytes(new_path, data)
        if new_path != old:
            store.delete(old)
        _remove_from_layer(store, kind, src, snippet, path)
        _put_on_layer(store, kind, dst, snippet, path, new_ref, False)
    else:
        _remove_from_layer(store, kind, src, snippet, path)
        _put_on_layer(store, kind, dst, snippet, path, value, False)
    store.commit()
    print("moved")


def _stored_age(store: Store, kind: str, layer: Layer, snippet: str | None, path: list) -> dict | None:
    if layer.scope == "local":
        return None
    if layer.editor == "common" and layer.scope == "shared":
        text = common_text(store, kind, snippet)
        value = get_path(py_from_text(text), path)
        return value if is_age(value) else None
    file = doc_path(store.source, kind, layer, snippet)
    if store.read(file) is None and not file.is_file():
        return None
    for op in load_overlay(store, file).get("set", []):
        if paths_equal(op["path"], path) and is_age(op["value"]):
            return op["value"]
    return None


def _remove_from_layer(store: Store, kind: str, layer: Layer, snippet: str | None, path: list) -> None:
    if layer.editor == "common" and layer.scope == "shared":
        write_common_value(store, kind, snippet, path, None, True)
        return
    file = doc_path(store.source, kind, layer, snippet)
    data = load_overlay(store, file) if (store.read(file) or file.is_file()) else {"set": [], "unset": []}
    had_unset = any(paths_equal(item, path) for item in data["unset"])
    data["set"] = [op for op in data["set"] if not paths_equal(op["path"], path)]
    data["unset"] = [item for item in data["unset"] if not paths_equal(item, path)]
    if had_unset:
        save_overlay(store, file, data)
        return
    save_overlay(store, file, data)


def _put_on_layer(store: Store, kind: str, layer: Layer, snippet: str | None, path: list, value: Any, remove: bool) -> None:
    if layer.editor == "common" and layer.scope == "shared":
        if is_age(value) or not _plaintext_secret_in_git(value):
            write_common_value(store, kind, snippet, path, value, remove)
            return
        raise SystemExit("editor-sync: refusing to write a plaintext secret into the chezmoi source")
    if layer.scope != "local" and not is_age(value):
        # Ordinary settings are allowed. Plaintext secrets are age refs or local files.
        pass
    write_overlay_value(store, kind, layer, snippet, path, value, remove)


def _plaintext_secret_in_git(value: Any) -> bool:
    return False


EDITOR_CLIS = {"vscode": "code", "cursor": "cursor"}


def sync_editor_extensions(store: Store, editor: str, cli: str) -> bool:
    installed = installed_extensions(editor)
    if installed is None:
        print(f"editor-sync: skipping {editor} extension sync; extensions.json is missing or unreadable", file=sys.stderr)
        return True
    desired = desired_extensions(store, editor)
    ok = True
    for ext_id in sorted(desired - installed):
        print(f"{editor}: install {ext_id}")
        proc = subprocess.run([cli, "--install-extension", ext_id, "--force"], check=False)
        if proc.returncode != 0:
            ok = False
    for ext_id in sorted(installed - desired):
        print(f"{editor}: uninstall {ext_id}")
        proc = subprocess.run([cli, "--uninstall-extension", ext_id], check=False)
        if proc.returncode != 0:
            ok = False
    return ok


def cmd_extensions_sync(args: argparse.Namespace) -> None:
    if args.editor is not None and args.editor not in EDITORS:
        raise SystemExit("editor-sync: editor must be vscode or cursor")
    if args.cli is not None and args.editor is None:
        raise SystemExit("editor-sync: a CLI path needs an editor name before it")
    store = Store(Path(args.source), args.host)
    editors = [args.editor] if args.editor else list(EDITORS)
    ok = True
    for editor in editors:
        cli = args.cli or shutil.which(EDITOR_CLIS[editor])
        if cli is None:
            print(f"editor-sync: skipping {editor} extension sync; {EDITOR_CLIS[editor]} is not on PATH", file=sys.stderr)
            continue
        ok = sync_editor_extensions(store, editor, cli) and ok
    if not ok:
        raise SystemExit(1)


def build_parser() -> argparse.ArgumentParser:
    common = argparse.ArgumentParser(add_help=False)
    common.add_argument("--source", default=str(default_source()))
    common.add_argument(
        "--host",
        default=default_host(),
        type=str.lower,
        help="lowercased user@host (default: current user and short hostname)",
    )
    parser = argparse.ArgumentParser(prog="editor-sync")
    sub = parser.add_subparsers(dest="cmd", required=True)

    render = sub.add_parser("render", parents=[common])
    render.add_argument("editor")
    render.add_argument("kind")
    render.add_argument("snippet", nargs="?")
    render.set_defaults(func=cmd_render)

    imp = sub.add_parser(
        "import",
        parents=[common],
        usage="editor-sync import [--source DIR] [--host USER@HOST] [vscode|cursor] [settings|keybindings|snippets|extensions]",
    )
    imp.add_argument("words", nargs="*", metavar="editor-or-kind")
    imp.set_defaults(func=cmd_import)

    sync = sub.add_parser("extensions-sync", parents=[common])
    sync.add_argument("editor", nargs="?")
    sync.add_argument("cli", nargs="?")
    sync.set_defaults(func=cmd_extensions_sync)

    move = sub.add_parser("move", parents=[common])
    move.add_argument("kind")
    move.add_argument("--from", dest="src_layer", required=True)
    move.add_argument("--to", dest="dst_layer", required=True)
    move.add_argument("--snippet")
    move.add_argument("target")
    move.set_defaults(func=cmd_move)
    return parser


def main(argv: list[str] | None = None) -> None:
    parser = build_parser()
    args = parser.parse_args(argv)
    # Subcommand flags were defined on the top-level parser so --source/--host work
    # before or after the subcommand. argparse only accepts them before the
    # subcommand unless parents are used. Re-parse from sys.argv is already done.
    args.func(args)


if __name__ == "__main__":
    main()
