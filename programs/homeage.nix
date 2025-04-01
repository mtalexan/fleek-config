{ pkgs, misc, lib, config, options, inputs, ... }: {
  # WARNING: because we need an 'options.' key here, we have to use the verbose format with a 'config.home.' for home-manager things

  # Not configurable in home-manager itself, add the package generically and setup config.home.file's for what we need
  home.packages = [
    pkgs.ragenix
  ];

  # provides its own home-manager module. Has to be imported before we can configure the homeage settings.
  imports = [
    inputs.homeage.homeManagerModules.homeage
  ];

  homeage = {
    # this is the (r)agenix package, not a homeage package. Make sure it's listed above as a package to install.
    # Note that ragenix also provides the tool name agenix.
    pkg = pkgs.ragenix;
    # Where the decrypted secrets are mounted. Defaults to /run/user/$UID/secrets/
    # Unless a systemd mount is installed (not possible with home-manager directly), this must be
    # a non-volatile storage location.
    mount = "/home/${config.home.username}/.secrets/homeage/";
    # Not on NixOS so can't use systemd, this update secrets on home-manager switch.
    # Requires 'mount' to be non-volatile since it will only update the secrets on switch and not on reboot.
    installationType = "activation";

    # To use:
    # 1. Add an (r)agenix secret to the secrets/ folder (see secrets/secrets.nix for details).
    # 2. Add to hosts/*.nix a path to an out-of-band-transferred private SSH key that can decrypt the secret
    #    # Str or list of Strs for paths to the SSH private keys to use for decrypting the secrets
    #    homeage.identityPaths = [ "absolute path to secret key" ];
    # 3. Add the secret(s) to a *.nix module
    #    homeage.file."secretname" = {
    #      # path to encrypted file in git repo
    #      source = ./relative/path/to/file.age;
    #      # (optional) Str. Override for where the decrypted file is mounted. By default it's teh source name wihtout .age extension in the 'mount' folder.
    #      #path = "";
    #      # (optional)Str. Mode of decrypted file. Default is 0400.
    #      #mode = "";
    #      # (optional) Str. User owner of decrypted file. Default is the current user, $UID.
    #      #owner = "";
    #      # (optional) Str. Group owner of decrypted file. Default is the current user's default group, $(id -g).
    #      #group = "";
    #      # (optional) list of Str. Extra Locations of symlinks to the decrypted files. Absolute paths.
    #      #symlinks = [];
    #      # (optinoal) list of Str. Extra Locations of copies of the decrypted files. Absolute paths.
    #      #copies = [];;
    #    };
    # 4. Reference the decrypted file as part of a program config. E.g.
    #    vpn.wgConf = config.homeage.file."secretname".path;
  };

}
# vim: ts=2:sw=2:expandtab