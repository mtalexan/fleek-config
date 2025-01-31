{ pkgs, misc, lib, ... }: {
  # Doesn't actually install cargo, you should still run the rustup script yourself so you can better pin the version:
  #   https://www.rust-lang.org/tools/install

  ## Add the nix rustup package that includes rustc, rustup, and cargo.
  ## This disables using the 'rustup' command to self-update, but automatically puts
  ## all the tools in your path.
  #home.packages = [
  #  pkgs.rustup
  #];

  # source the cargo install
  programs.zsh.initExtra = lib.concatLines [
    ''
      if [ -e "$HOME/.cargo/env" ] ; then
        source $HOME/.cargo/env
      fi
    ''
  ];

  programs.bash.initExtra = lib.concatLines [
    ''
      if [ -e "$HOME/.cargo/env" ] ; then
        source $HOME/.cargo/env
      fi
    ''
  ];
}

# vim: ts=2:sw=2:expandtab
