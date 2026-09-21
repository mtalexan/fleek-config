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

    # TUI vscode/zeditor tool
    ttt = {
      url = "github:eugenioenko/ttt";
    };
    
    # Non-flake source input for copilot-api
    copilot-api-src = {
      url   = "github:Arthur742Ramos/copilot-api-rust";
      flake = false;  # repo has no flake.nix; treat as raw source path
    };

    # Add Cursor (IDE) as independent input, by pinning a second copy of nixpkgs
    code-cursor-nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
      #inputs.nixpkgs.follows = "nixpkgs"; # Independence from the nixpkgs flake is the whole point
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

    # Kilo from nixpkgs is broken, so use Kilo's upstream flake instead.
    kilo = {
      url = "github:Kilo-Org/kilocode";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    bun2nix = {
      # We need a patch to the bun2nix CLI tool that properly handles content hashed tarballs so it works with kilo.
      #   Implemented in overlay-packages/bun2nix-cli-fixed.nix as well.
      # Bun allows providing patches for dependencies directly, but uses a custom written patching that is fuzzy. Bun2nix
      # normally extracts this into into a Nix variable and strips it from the source code so that the patches get applied 
      # with GNU patch (which doesn't support the same fuzzy apply). If the patches don't apply cleanly this is a problem.
      #   Implemented as a branch in the forked copy, adding userNativePatching argument to the nix.
      # The forked branch includes both changes directly.
      #url = "github:nix-community/bun2nix/2.1.2";
      url = "github:mtalexan/bun2nix/allow-bun-patching-compatibilty";
      inputs.nixpkgs.follows = "nixpkgs";
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
        ttt,
        code-cursor-nixpkgs,
        vscode-nixpkgs,
        zed-nixpkgs,
        copilot-api-src,
        bun2nix,
        kilo,
        ...
      }@inputs:
    let
      # not packaged as an overlay on its own
      language-servers-overlay = final: prev: {
        language-servers = inputs.language-servers.packages.${prev.stdenv.hostPlatform.system}.default;
      };

      # Not packaged as an overlay on its own
      ttt-overlay = final: prev: {
        ttt = inputs.ttt.packages.${prev.stdenv.hostPlatform.system}.default;
      };

      # We're using a fork of bun2nix instead since we also need the useNativeBunPatches feature.
      ## TODO: Remove this when bun2nix adopts https://github.com/nix-community/bun2nix/pull/108
      #bun2nix-overlay = (import custom-modules/overlay-packages/bun2nix-cli-fixed.nix) bun2nix;

      kilo-overlay = (import custom-modules/overlay-packages/kilo.nix) kilo;

      # extra overlays need to be added here
      myOverlaysSet = [
        emacs-overlay.overlay
        git-agecrypt.overlay
        language-servers-overlay
        ttt-overlay
        bun2nix.overlays.default

        kilo-overlay

        # The input is raw source and not a flake.nix, so we have a custom definition we use to create the package as an overlay and we just have
        # to define which input the source is in.
        ((import custom-modules/overlay-packages/copilot-api.nix) copilot-api-src)

        # These are set to be packages that get their dependencies from an independently pinned nixpkgs, so we don't have
        # dependency version mismatch issues if we update just these input flakes.
        # These packages can be referred to as pkgs.*-independent in modules.
        ((import custom-modules/overlay-packages/independent-nixpkgs.nix) code-cursor-nixpkgs "code-cursor" "code-cursor-independent")
        ((import custom-modules/overlay-packages/independent-nixpkgs.nix) vscode-nixpkgs "vscode" "vscode-independent")
        ((import custom-modules/overlay-packages/independent-nixpkgs.nix) zed-nixpkgs "zed-editor" "zed-independent")

        # must be last in this list. Forces all golang to be CGO=1 so it actually functions.
        (import custom-modules/overlay-packages/golang-cgo.nix)
      ];

      # Define a function to create `pkgs` with overlays added.
      # Takes a stdenv.hostPlatform.system double (e.g. x86_64-linux) as argument 'system'to use
      pkgsForSystem = system: import nixpkgs {
        inherit system;
        overlays = myOverlaysSet;
        # Make sure the nixpkgs set allows unfree packages.
        # NOTE: Any independent nixpkgs need to set this as well (see independent-nixpkgs.nix)
        config = {
          allowUnfree = true;
          allowunfreePredicate = (_: true);
        };
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
          (self + "/hosts/${host}_${user}.nix"); # Construct the file path

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
          (self + "/home.nix")
          (self + "/user.nix")
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
        { name = "aaravchen2@laptopfedora"; }
        { name = "aaravchen@helios3000"; }
        { name = "aaravchen@bazzite"; } # linked to helios3000
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

      # the installed home-manager needs to be the one from the flake
      packages = nixpkgs.lib.genAttrs
        [ "x86_64-linux" ]
        (system: {
          hm = home-manager.packages.${system}.default;
        });
    };
}

# vim: ts=2:sw=2:expandtab
