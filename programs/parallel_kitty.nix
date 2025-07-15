{ pkgs, misc, lib, config, ... }: {

  home.packages = [
    # Full GNU parallel package including docs
    pkgs.parallel-full
  ];

  home.file.".local/bin/parallel_kitty" = {
    executable = true;
    # Read the contents of the script from snippets/parallel_kitty, and replace the
    # KITTY_CMD_DEFAULT variable value with the path to the home manager installed
    # kitty.
    text = let
      snippetContent = builtins.readFile ./../snippets/parallel_kitty;
      # builtins.match regex is required to match ALL of the string, and it will return
      # the match group(s) as a list of strings. If it doesn't match everything,
      # it returns null.
      oldValue = builtins.match ".*(KITTY_CMD_DEFAULT=[^\n]+).*" snippetContent;
      newValue = "KITTY_CMD_DEFAULT=${pkgs.kitty}/bin/kitty";
    in 
      # If we try to replace an empty string, it will cause issues, so only do replacement
      # if we found matches.
      if oldValue != null then
        builtins.replaceStrings oldValue [newValue] snippetContent
      else
        snippetContent;
  };
  
}

# vim: ts=2:sw=2:expandtab:syntax=nix
