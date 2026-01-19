{ pkgs, misc, lib, config, ... }: {
  programs.parallel = {
    enable = true;
    # normally the parallel command needs to be run with a special option so it doesn't interrupt on every attempt to use it,
    # this does that automatically.
    will-cite = true;
  };
}