{ pkgs, misc, lib, config, ... }: {
  home.packages = [
    #
    # Multiple
    #
    
    # Cargo.toml, go.mod, package.json, pyproject.toml
    pkgs.deputy
    # Autotools, configure.ac, Makefile.am, Makefile
    pkgs.autotools-language-server
    # Javascript + typescript
    pkgs.javascript-typescript-langserver
    # Pandoc, Quarto, R Markdown
    pkgs.panache
    
    #
    # Specific language
    #
    
    # Ansible
    pkgs.ansible-language-server
    # Autotools
    #See multi
    # Awk
    pkgs.awk-language-server
    # Bash
    #pkgs.bashd
    pkgs.bash-language-server
    # Bitbake
    pkgs.bitbake-language-server
    # C/C++ (clangd)
    pkgs.ccls
    # CMake
    pkgs.cmake-language-server
    # CSS
    pkgs.vscode-css-languageserver
    # Device Tree
    pkgs.ginko
    #pkgs.dts-lsp
    # Dockerfile
    pkgs.docker-language-server
    #pkgs.dockerfile-language-server
    # Docker compose
    pkgs.docker-compose-language-service
    # Earthly
    pkgs.earthlyls
    # GitLab CI
    pkgs.gitlab-ci-ls
    # Golang
    pkgs.gopls
    # Golangci-lint
    pkgs.golangci-lint-langserver
    # Golang go.mod
    #see multi
    # Groovy
    pkgs.groovy-language-server
    # Guile
    pkgs.docker-compose-language-service
    # Helm (charts)
    pkgs.helm-ls
    # HTML
    pkgs.superhtml
    #pkgs.vscode-html-languageserver
    # Hyperland Config
    pkgs.hyprls
    # Java
    pkgs.java-language-server
    #pkgs.jdt-language-server
    # Javascript
    #see multi
    # Jinja2
    pkgs.jinja-lsp
    # JSON
    pkgs.vscode-json-languageserver
    # Jsonnet
    pkgs.jsonnet-language-server
    # jq
    pkgs.jq-lsp 
    # Julia
    pkgs.fatou
    # Just
    pkgs.just-lsp
    # LaTeX
    pkgs.texlab
    #pkgs.badness
    # Lua
    pkgs.lua-language-server
    #pkgs.luaPackages.lua-lsp
    #pkgs.vscode-extensions.sumneko.lua
    #pkgs.luajitPackages.lua-lsp
    # Lua Check
    pkgs.luaPackages.llscheck
    #pkgs.luajitPackages.llscheck
    # Makefile
    #see multi
    # Markdown
    pkgs.marksman
    #pkgs.md-lsp
    # Markdown preview
    pkgs.mpls
    # Nginx
    pkgs.nginx-language-server
    # Nim
    pkgs.nimlangserver
    #pkgs.nimlsp
    # Nix
    pkgs.nil
    #pkgs.nixd
    # NPM package.json
    #See multi
    #pkgs.package-version-server
    # Pandoc
    #see multi
    # Perl
    pkgs.perlnavigator
    #pkgs.perlPackages.PLS
    # PHP
    pkgs.phpantom-lsp
    # Python
    pkgs.ty
    #pkgs.vscode-extensions.ms-python.vscode-pylance
    #pkgs.pylyzer
    #pkgs.vscode-extensions.pylyzer.pylyzer
    # Rune
    pkgs.rune-languageserver
    # Rust
    pkgs.rust-analyzer
    #pkgs.vscode-extensions.rust-lang.rust-analyzer
    # Cargo.toml (Rust)
    #see multi
    #pkgs.crates-lsp
    # SQL/SQLite
    pkgs.syntaqlite
    # Systemd
    pkgs.systemd-lsp
    #pkgs.systemd-language-server
    # TOML
    pkgs.tombi
    #pkgs.vscode-extensions.tombi-toml.tombi
    # Typescript
    #See javascript
    #pkgs.typescript-language-server
    # WASM
    pkgs.wasm-language-tools
    # XML
    pkgs.lemminx
    # YAML
    pkgs.yaml-language-server
    # Zig
    pkgs.zls
  ];
}