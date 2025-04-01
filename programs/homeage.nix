{ pkgs, misc, lib, config, options, inputs, ... }: {
  # WARNING: because we need an 'options.' key here, we have to use the verbose format with a 'config.home.' for home-manager things

  # Not configurable in home-manager itself, add the package generically and setup config.home.file's for what we need
  home.packages = [
    pkgs.ragenix
  ];

  imports = [
    inputs.homeage.homeManagerModules.homeage
  ];

  homeage = {
    # this is the (r)agenix package, not a homeage package. Make sure it's listed above
    pkg = pkgs.ragenix;
    # Where the decrypted secrets are mounted. Defaults to /run/user/$UID/secrets/
    # Unless a systemd mount is installed (not possible with home-manager directly), this must be
    # a non-volatile storage location.
    mount = "/home/${config.home.username}/.secrets/homeage/";
    # Not on NixOS so can't use systemd, this update secrets on home-manager switch.
    # Requires 'mount' to be non-volatile since it will only update the secrets on switch and not on reboot.
    installationType = "activation";

    # Required for any config using this.
    # Str or list of Strs for paths to the SSH private keys to use for decrypting the secrets
    #identityPaths = [];

    # Required for any config using this.
    ## Access like 'vpn.wgConf = config.age.secrets."pathnameoffile".path';
    #file."pathnameoffile" = {
    #  # Str. Override for where the decrypted file is mounted. By default it's teh source name wihtout .age extension in the 'mount' folder.
    #  path = "";
    #  # path to encrypted file in git repo
    #  source = ./path/to/age/file;
    #  # Str. Mode of decrypted file. Default is 0400.
    #  mode = "";
    #  # Str. User owner of decrypted file. Default is the current user, $UID.
    #  owner = "";
    #  # Str. Group owner of decrypted file. Default is the current user's default group, $(id -g).
    #  group = "";
    #  # list of Str. Locations of symlinks to the decrypted files. Absolute paths.
    #  symlinks = [];
    #  # list of Str. Locations of copies of the decrypted files. Absolute paths.
    #  copies = [];;
    #};
  };

}
# vim: ts=2:sw=2:expandtab