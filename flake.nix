{
  description = "Home Configuration";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home manager
    home-manager = {
      url = "https://flakehub.com/f/nix-community/home-manager/0.1.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # a wrapper for nix-index, which indexes the files provided by the nixpkgs, that
    # includes a pre-generated database.
    nix-index-database ={
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # adds the emacs packages from ELPA/MELPA
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    language-servers = {
      url = "github:Feel-ix-343/language-servers";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # custom forked and patched version of git-agecrypt that fixes a major bug. Needs to be used as an overlay
    git-agecrypt = {
      url = "github:mtalexan/git-agecrypt/fixed";
      #inputs.nixpkgs.follows = "nixpkgs"; # do NOT set this, it causes the one from the nixpkgs store to be used instead of this overlay
    };

    # secrets encryption tool for secrets handled during home-manager switch rather than git commit/checkout (like git-agecrypt)
    agenix = {
      # includes undocumented support for a home-manager module that despite using systemd is able to be used on a non-NixOS system.
      # See https://github.com/ryantm/agenix/issues/50#issuecomment-1633579069
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      # we don't have any darwin targets, so disable it to save a bit of size
      inputs.darwin.follows = "";
    };
    
    # Add VSCode as independent input, by pinning a second copy of nixpkgs
    vscode-nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
      #inputs.nixpkgs.follows = "nixpkgs"; # Independence from the nixpkgs flake is the whole point
    };
    
    # Add Zed as independent input, by pinning a second copy of nixpkgs
    zed-nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
      #inputs.nixpkgs.follows = "nixpkgs"; # Independence from the nixpkgs flake is the whole point
    };
  };

  outputs = {
        self,
        nixpkgs,
        home-manager,
        nix-index-database,
        emacs-overlay,
        language-servers,
        git-agecrypt,
        agenix,
        vscode-nixpkgs,
        zed-nixpkgs,
        ...
      }@inputs:
    let
      myOverlaysSet = [
        # extra overlays need to be added here
        inputs.emacs-overlay.overlay
        inputs.git-agecrypt.overlay
        # vscode from separate vscode-nixpkgs flake input
        (final: prev: {
          vscode-independent = inputs.vscode-nixpkgs.legacyPackages.${prev.stdenv.hostPlatform.system}.vscode;
          })
        # zed-editor-fhs from separate zed-nixpkgs flake input
        (final: prev: {
          zed-independent = inputs.zed-nixpkgs.legacyPackages.${prev.stdenv.hostPlatform.system}.zed-editor-fhs;
          })
        # must be last in this list
        (import custom-modules/overlay-packages/golang-cgo.nix)
      ];

      # Define a function to create `pkgs` with overlays added.
      # Takes a stdenv.hostPlatform.system double (e.g. x86_64-linux) as argument 'system'to use
      pkgsForSystem = system: import nixpkgs {
        inherit system;
        overlays = myOverlaysSet;
      };

      # Function to construct the hostFile path from the config name
      hostFileFromName = configName: 
        let
          # split takes a regex pattern and interleaves unmatched sections with matched sections. So we want to grab the
          # part before and after the split as the capture groups so they end up as indexes 0 and 1
          parts = builtins.match "^(.*)@(.*)$" configName;
          user = builtins.elemAt parts 0; # First capturing group is the user
          host = builtins.elemAt parts 1; # Second capturing group is the host
        in
          ./hosts/${host}_${user}.nix; # Construct the file path

      # default linux template 
      linuxConfig = configName: home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsForSystem "x86_64-linux"; # Use the `pkgsForSystem` function for Linux
        extraSpecialArgs = {
          inherit inputs; # Pass flake inputs to our config
          stdenv.hostPlatform.system = "x86_64-linux"; # Pass the same 'system' variable as we're using for our 'pkgs' to our config
        };
        modules = [
          nix-index-database.homeModules.nix-index # Include the nix-index-database home-manager module
          agenix.homeManagerModules.default # Include agenix home-manager module
          ./home.nix
          ./user.nix
          (hostFileFromName configName) # Dynamically generate the host file path
          ({ nixpkgs.overlays = myOverlaysSet; })
        ];
      };

      # List of configuration names with their respective config functions. The default configFunction is linuxConfig unless specified otherwise.
      # Available through 'home-manager --flake .#your-username@your-hostname'
      # Pulls in the hosts/${host}_${user}.nix file for the per-host config, parsed from the name.
      configurations = [
        # if configFunction isn't set, it defaults to linuxConfig
        { name = "mtalexander@golw-12t4k74"; configFunction = linuxConfig; }
        { name = "mtalexander@goln-5wwdx54"; }
        { name = "mike@kubic-730xd"; }
        { name = "mike@cloud-t610"; }
        { name = "aaravchen2@laptopFedora"; }
        { name = "aaravchen@helios300"; }
      ];
    in {
      # Dynamically generate homeConfigurations using the functions specified as the 'configFunction' for each item in the
      # 'configurations' list. Sets a "${name}" = (${configFunction} "${name}"); for each item.
      # For items where configFunction isn't set, assume linuxConfig.
      # The ${configFunction} calculates the hosts/*.nix file as ${host}_${name}.nix by parsing the ${name} passed to it.
      homeConfigurations = builtins.listToAttrs (map (entry: {
          name = entry.name;
          value = (entry.configFunction or linuxConfig) entry.name; # Default to linuxConfig if not set
        }) configurations);
    };
}

# vim: ts=2:sw=2:expandtab
