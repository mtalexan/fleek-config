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

    # Overlays
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Technically has support for a home-manager module, but it only uses systemd to mount secrets.
    # That's only functional/possible on NixOS systems, not on non-NixOS systems using home-manager.
    # homeage (below) supports "activation" mode, which does decryption on home-manager switch rather than requiring a systemd mount.
    agenix = {
      # Use ragenix instead of agenix.
      #url = "github:ryantm/agenix";
      url = "github:yaxitech/ragenix";
      inputs.nixpkgs.follows = "nixpkgs";
      # don't download download darwin deps (saves some resources on Linux)
      inputs.darwin.follows = "";
    };

    homeage = {
      url = "github:jordanisaacs/homeage";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = { self, nixpkgs, home-manager, agenix, homeage, ... }@inputs: let
    myOverlaysSet = [
      # extra overlays need to be added here
      inputs.emacs-overlay.overlay
      inputs.nixgl.overlay
      # Make all Golang applications build with CGO=1.
      # Golang tried to re-invent the world but got lazy when it came to libc, having only a half-assed
      # libc replacement.  Anything low-level, like querying a username from a UID, is implemented how you
      # explicitly shouldn't, and DOES NOT WORK (especially with LDAP users).
      # This sets CGO=1 as part of all golang tool builds so it actually uses the real libc implementation
      # that works properly.
      (self: super: {
        buildGoModule = args: super.buildGoModule (args // {
          buildInputs = (args.buildInputs or []) ++ [ super.gcc ]; # Add GCC for CGO
          goFlags = (args.goFlags or "") + " CGO_ENABLED=1"; # Set CGO_ENABLED=1
        });
      })
    ];

    # Define a function to create `pkgs` with overlays added.
    # Takes a system double (e.g. x86_64-linux) to use
    pkgsForSystem = system: import nixpkgs {
      inherit system;
      overlays = myOverlaysSet;
    };

    # Function to construct the hostFile path from the config name
    hostFileFromName = configName: let
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
      extraSpecialArgs = { inherit inputs; }; # Pass flake inputs to our config
      modules = [
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
      { name = "mtalexander@goln-5cl17g3"; configFunction = linuxConfig; }
      { name = "mtalexander@goln-422q533c"; }
      { name = "mtalexander@golw-12t4k74"; }
      { name = "mike@kubic-730xd"; }
      { name = "mike@cloud-t610"; }
      { name = "dev@vm-gol-422Q533"; }
      { name = "aaravchen2@laptopFedora"; }
      { name = "aaravchen@WINDOWS-GAMING"; }
      { name = "aaravchen@bazzite"; }
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
