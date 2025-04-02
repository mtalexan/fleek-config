{ pkgs, misc, lib, config, options, inputs, system, ... }: {
  # WARNING: Only include one of homeage.nix and agenix.nix

  # The Home Manager module for agenix is undocumented, see https://github.com/ryantm/agenix/issues/50#issuecomment-1633579069

  home.packages = [
    inputs.agenix.packages.${system}.default
  ];

  imports = [
    inputs.agenix.homeManagerModules.default
  ];

  # Undocumented module, options need to be read from source here: https://github.com/ryantm/agenix/blob/main/modules/age-home.nixL157
  age = {
    # default is age
    #package = pkgs.age;

    # Folder the decrypted secrets are symlinked/copied into.
    # Default is '/run/user/$UID/agenix'.
    secretsDir = "${config.home.homeDirectory}/.secrets/agenix";

    # Folder secrets are decrypted into before they're symlinked/copied to the secretsDir.
    # Default is /run/user/$UID/agenix.d
    #secretsMountPoint = "";

    # To use:
    # 1. Add an (r)agenix secret to the secrets/ folder (see secrets/secrets.nix for details).
    # 2. Add to hosts/*.nix a path to an out-of-band-transferred private SSH key that can decrypt the secret
    #    # Str or list of Strs for paths to the SSH private keys to use for decrypting the secrets
    #    age.identityPaths = [ "absolute path to secret key" ];
    # 3. Add the secret(s) to a *.nix module
    #    age.secrets."secretname" = {
    #      # path to encrypted file in git repo
    #      file = ./relative/path/to/file.age;
    #      # (optional) Str. Basename of the decrypted secrets file. By default it's the "secretname" part from the key.
    #      # name = "";
    #      # (optional) Str. Override for the pathed name the decrypted secret is located. By default it's the 'name' under the age.secretsDir folder.
    #      #path = "";
    #      # (optional)Str. Mode of decrypted file. Default is 0400.
    #      #mode = "";
    #      # (optional) Bool. Should the decrypted secret be linked to the location or copied? Default=true
    #      #symlink = true
    #    };
    # 4. Reference the decrypted file as part of a program config. E.g.
    #    vpn.wgConf = config.age.secrets."secretname".path;
  };

}
# vim: ts=2:sw=2:expandtab