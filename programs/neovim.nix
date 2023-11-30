{ pkgs, misc, lib, ... }:
# Programs that aren't the shell or the prompt are in here
let
  # for fake hash, use "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
  vimPluginFromGitHub = owner: repo: rev: hash: pkgs.vimUtils.buildVimPlugin {
    pname = "${lib.strings.sanitizeDerivationName "${owner}/${repo}"}";
    version = "${rev}";
    src = pkgs.fetchFromGitHub {
      owner = "${owner}";
      repo = "${repo}";
      rev = "${rev}";
      hash = "${hash}";
    };
  };
in
{

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = false;

    # bug in some versions of home-manager requires this to be set to something for plugins to get parsed
    extraConfig = ''

    '';

    extraLuaConfig = lib.concatLines [
      "vim.opt.backup = false"
      "vim.opt.relativenumber = true"
      "vim.opt.syntax = on"
    ];

    # plugins can be from nixpkgs vimPlugins.*
    # or can be from gitHub by using the custom function define in the let at the top of
    # this file, vimPluginFromGitHub
    plugins = with pkgs.vimPlugins; [
      # needed by barbar-nvim and lualine-nvim for icons
      nvim-web-devicons

      # tabs for buffers
      barbar-nvim

      # nicer mode line
      {
        plugin = lualine-nvim;
        config = ''
          lua require('lualine').setup({options={theme='vscode'}})
        '';
      }

      # use nix precompiled grammars
      nvim-treesitter.withAllGrammars

      {
        # latest rev as of 2023-08-01
        plugin = (vimPluginFromGitHub "Mofiqul" "vscode.nvim" "05973862f95f85dd0564338a03baf61b56e1823f" "sha256-iY3S3NnFH80sMLXgPKNG895kcWpl/IjqHtFNOFNTMKg=");
        config = ''
          :colorscheme vscode
        '';
      }
    ];
  };
}

# vim: sw=2:expandtab
