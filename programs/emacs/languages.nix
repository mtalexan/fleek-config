{ pkgs, lib, pythonServer ? "basedpyright" }:
let
  profile = package: executable: arguments: {
    inherit package;
    command = [ "${package}/bin/${executable}" ] ++ arguments;
  };
  withRuntime = package: executable: runtime: flags: pkgs.symlinkJoin {
    name = "${package.pname}-emacs";
    paths = [ package ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/${executable}" --suffix PATH : ${lib.makeBinPath runtime} ${lib.escapeShellArgs flags}
    '';
  };
  # BitBake 0.0.16 calls pygls 1 APIs that pygls 2 removes. The compatibility
  # patch translates logging and diagnostic notifications to typed parameters.
  # get_text_document replaces the removed workspace.get_document method.
  # pygls migration reference:
  # https://pygls.readthedocs.io/en/latest/pygls/howto/migrate-to-v2.html
  #
  # Completion at EOF after a newline is a valid LSP position. splitlines()
  # discards that final empty line, so indexing position.line raises IndexError.
  # split("\n") preserves it without changing LSP line numbering.
  # No matching upstream issue or fix was found in the repository's issue list:
  # https://github.com/Freed-Wu/bitbake-language-server/issues
  # Remove these overrides when the pinned release uses pygls 2 APIs and accepts
  # trailing-line completion. check-servers.py exercises that exact EOF case.
  bitbakeServer = pkgs.bitbake-language-server.overridePythonAttrs (old: {
    patches = (old.patches or []) ++ [ ./bitbake-pygls.patch ];
    postPatch = (old.postPatch or "") + ''
      substituteInPlace src/bitbake_language_server/server.py \
        --replace-fail 'self.workspace.get_document(' 'self.workspace.get_text_document(' \
        --replace-fail 'document.source.splitlines()[position.line]' 'document.source.split("\n")[position.line]'
    '';
  });
  # Autotools 0.0.23 has the same EOF completion bug in make_language_server.
  # Preserve the final empty line so a valid cursor position cannot index past
  # the source lines. This does not patch unrelated pygls compatibility issues.
  # No matching trailing-line issue or upstream fix was found in:
  # https://github.com/Freed-Wu/autotools-language-server/issues
  # Remove this override once the pinned server passes the trailing-newline
  # Makefile completion fixture in check-servers.py without the substitution.
  autotoolsServer = pkgs.autotools-language-server.overridePythonAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace src/make_language_server/server.py \
        --replace-fail 'document.source.splitlines()[position.line]' 'document.source.split("\n")[position.line]'
    '';
  });
in {
  python = if pythonServer == "ty"
    then profile pkgs.ty "ty" [ "server" ]
    else profile pkgs.basedpyright "basedpyright-langserver" [ "--stdio" ];
  clangd = profile pkgs.clang-tools "clangd" [ "--background-index" ];
  rust = profile (withRuntime pkgs.rust-analyzer "rust-analyzer" [ pkgs.cargo pkgs.rustc ] [
    "--set-default" "RUST_SRC_PATH" (toString pkgs.rustPlatform.rustLibSrc)
  ]) "rust-analyzer" [];
  go = profile (withRuntime pkgs.gopls "gopls" [ pkgs.go ] []) "gopls" [];
  typescript = profile pkgs.typescript-language-server "typescript-language-server" [ "--stdio" ];
  java = profile pkgs.jdt-language-server "jdtls" [];
  csharp = profile pkgs.csharp-ls "csharp-ls" [];
  fsharp = profile pkgs.fsautocomplete "fsautocomplete" [ "--adaptive-lsp-server-enabled" ];
  clojure = profile pkgs.clojure-lsp "clojure-lsp" [];
  kotlin = profile pkgs.kotlin-language-server "kotlin-language-server" [];
  lua = profile pkgs.lua-language-server "lua-language-server" [];
  julia = profile pkgs.fatou "fatou" [ "lsp" ];
  ruby = profile pkgs.solargraph "solargraph" [ "stdio" ];
  php = profile pkgs.phpantom-lsp "phpantom_lsp" [];
  perl = profile pkgs.perlnavigator "perlnavigator" [ "--stdio" ];
  powershell = profile pkgs.powershell "pwsh" [
    "-NoLogo" "-NoProfile" "-File"
    "${pkgs.powershell-editor-services}/lib/powershell-editor-services/PowerShellEditorServices/Start-EditorServices.ps1"
    "-Stdio" "-LanguageServiceOnly" "-HostName" "Emacs"
    "-HostProfileId" "Emacs" "-HostVersion" "31.1" "-LogLevel" "Warning"
  ];
  r = profile (pkgs.rWrapper.override { packages = [ pkgs.rPackages.languageserver ]; }) "R" [
    "--slave" "-e" "languageserver::run()"
  ];
  dart = profile pkgs.dart "dart" [ "language-server" "--protocol=lsp" ];
  swift = profile (withRuntime pkgs.sourcekit-lsp "sourcekit-lsp" [ pkgs.swift ] []) "sourcekit-lsp" [];
  bash = profile pkgs.bash-language-server "bash-language-server" [ "start" ];
  nix = profile pkgs.nil "nil" [];
  json = profile pkgs.vscode-langservers-extracted "vscode-json-language-server" [ "--stdio" ];
  yaml = profile pkgs.yaml-language-server "yaml-language-server" [ "--stdio" ];
  toml = profile pkgs.tombi "tombi" [ "lsp" ];
  html = profile pkgs.vscode-langservers-extracted "vscode-html-language-server" [ "--stdio" ];
  css = profile pkgs.vscode-langservers-extracted "vscode-css-language-server" [ "--stdio" ];
  xml = profile pkgs.lemminx "lemminx" [];
  jq = profile pkgs.jq-lsp "jq-lsp" [];
  sql = profile pkgs.sqls "sqls" [];
  jinja = profile pkgs.jinja-lsp "jinja-lsp" [];
  wat = profile pkgs.wasm-language-tools "wat_server" [];
  cmake = profile pkgs.cmake-language-server "cmake-language-server" [];
  autotools = profile autotoolsServer "autotools-language-server" [];
  bitbake = profile bitbakeServer "bitbake-language-server" [];
  dts = profile pkgs.ginko "ginko_ls" [];
  groovy = profile pkgs.groovy-language-server "groovy-language-server" [];
  docker = profile pkgs.docker-language-server "docker-language-server" [ "start" "--stdio" ];
  just = profile pkgs.just-lsp "just-lsp" [];
  systemd = profile pkgs.systemd-lsp "systemd-lsp" [];
  markdown = profile pkgs.marksman "marksman" [ "server" ];
  tex = profile pkgs.texlab "texlab" [];
}
