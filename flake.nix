{
  # DO NOT EDIT: This file is managed by fleek. Manual changes will be overwritten.
  description = "Fleek Configuration";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home manager
    home-manager = {
      url = "https://flakehub.com/f/nix-community/home-manager/0.1.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Fleek
    fleek.url = "https://flakehub.com/f/ublue-os/fleek/*.tar.gz";

    # Overlays
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = { self, nixpkgs, home-manager, fleek, ... }@inputs: {

     packages.x86_64-linux.fleek = fleek.packages.x86_64-linux.default;

    # Available through 'home-manager --flake .#your-username@your-hostname'
    homeConfigurations = {

      "aaravchen@fedora" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = { inherit inputs; }; # Pass flake inputs to our config
        modules = [
          ./home.nix
          ./path.nix
          ./shell.nix
          ./user.nix
          ./aliases.nix
          ./programs.nix
          # Host Specific configs
          ./fedora/aaravchen.nix
          ./fedora/custom.nix
          # self-manage fleek
          {
            home.packages = [
              fleek.packages.x86_64-linux.default
            ];
          }
          ({
           nixpkgs.overlays = [inputs.emacs-overlay.overlay inputs.nixgl.overlay ];
          })

        ];
      };

      "mtalexander@goln-5cl17g3" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = { inherit inputs; }; # Pass flake inputs to our config
        modules = [
          ./home.nix 
          ./path.nix
          ./shell.nix
          ./user.nix
          ./aliases.nix
          ./programs.nix
          # Host Specific configs
          ./goln-5cl17g3/mtalexander.nix
          ./goln-5cl17g3/custom.nix
          # self-manage fleek
          {
            home.packages = [
              fleek.packages.x86_64-linux.default
            ];
          }
          ({
           nixpkgs.overlays = [inputs.emacs-overlay.overlay inputs.nixgl.overlay ];
          })

        ];
      };

      "aaravchen@laptop" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = { inherit inputs; }; # Pass flake inputs to our config
        modules = [
          ./home.nix 
          ./path.nix
          ./shell.nix
          ./user.nix
          ./aliases.nix
          ./programs.nix
          # Host Specific configs
          ./laptop/aaravchen.nix
          ./laptop/custom.nix
          # self-manage fleek
          {
            home.packages = [
              fleek.packages.x86_64-linux.default
            ];
          }
          ({
           nixpkgs.overlays = [inputs.emacs-overlay.overlay inputs.nixgl.overlay ];
          })

        ];
      };
      
      "aaravchen@laptopFedora" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = { inherit inputs; }; # Pass flake inputs to our config
        modules = [
          ./home.nix 
          ./path.nix
          ./shell.nix
          ./user.nix
          ./aliases.nix
          ./programs.nix
          # Host Specific configs
          ./laptopFedora/aaravchen.nix
          ./laptopFedora/custom.nix
          # self-manage fleek
          {
            home.packages = [
              fleek.packages.x86_64-linux.default
            ];
          }
          ({
           nixpkgs.overlays = [inputs.emacs-overlay.overlay inputs.nixgl.overlay ];
          })

        ];
      };
      
      "mtalexander@goln-422q533" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = { inherit inputs; }; # Pass flake inputs to our config
        modules = [
          ./home.nix 
          ./path.nix
          ./shell.nix
          ./user.nix
          ./aliases.nix
          ./programs.nix
          # Host Specific configs
          ./goln-422q533/mtalexander.nix
          ./goln-422q533/custom.nix
          # self-manage fleek
          {
            home.packages = [
              fleek.packages.x86_64-linux.default
            ];
          }
          ({
           nixpkgs.overlays = [inputs.emacs-overlay.overlay inputs.nixgl.overlay ];
          })

        ];
      };
      
      "mike@kubic-730xd" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = { inherit inputs; }; # Pass flake inputs to our config
        modules = [
          ./home.nix 
          ./path.nix
          ./shell.nix
          ./user.nix
          ./aliases.nix
          ./programs.nix
          # Host Specific configs
          ./kubic-730xd/mike.nix
          ./kubic-730xd/custom.nix
          # self-manage fleek
          {
            home.packages = [
              fleek.packages.x86_64-linux.default
            ];
          }
          ({
           nixpkgs.overlays = [inputs.emacs-overlay.overlay inputs.nixgl.overlay ];
          })

        ];
      };
      
      "mike@cloud-t610" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = { inherit inputs; }; # Pass flake inputs to our config
        modules = [
          ./home.nix 
          ./path.nix
          ./shell.nix
          ./user.nix
          ./aliases.nix
          ./programs.nix
          # Host Specific configs
          ./cloud-t610/mike.nix
          ./cloud-t610/custom.nix
          # self-manage fleek
          {
            home.packages = [
              fleek.packages.x86_64-linux.default
            ];
          }
          ({
           nixpkgs.overlays = [inputs.emacs-overlay.overlay inputs.nixgl.overlay ];
          })

        ];
      };
      
      "dev@vm-gol-422Q533" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = { inherit inputs; }; # Pass flake inputs to our config
        modules = [
          ./home.nix 
          ./path.nix
          ./shell.nix
          ./user.nix
          ./aliases.nix
          ./programs.nix
          # Host Specific configs
          ./vm-gol-422Q533/dev.nix
          ./vm-gol-422Q533/custom.nix
          # self-manage fleek
          {
            home.packages = [
              fleek.packages.x86_64-linux.default
            ];
          }
          ({
           nixpkgs.overlays = [inputs.emacs-overlay.overlay inputs.nixgl.overlay ];
          })

        ];
      };
      
      "aaravchen2@laptopFedora" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = { inherit inputs; }; # Pass flake inputs to our config
        modules = [
          ./home.nix 
          ./path.nix
          ./shell.nix
          ./user.nix
          ./aliases.nix
          ./programs.nix
          # Host Specific configs
          ./laptopFedora/aaravchen2.nix
          ./laptopFedora/custom.nix
          # self-manage fleek
          {
            home.packages = [
              fleek.packages.x86_64-linux.default
            ];
          }
          ({
           nixpkgs.overlays = [inputs.emacs-overlay.overlay inputs.nixgl.overlay ];
          })

        ];
      };
      
      "aaravchen@WINDOWS-GAMING" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = { inherit inputs; }; # Pass flake inputs to our config
        modules = [
          ./home.nix 
          ./path.nix
          ./shell.nix
          ./user.nix
          ./aliases.nix
          ./programs.nix
          # Host Specific configs
          ./WINDOWS-GAMING/aaravchen.nix
          ./WINDOWS-GAMING/custom.nix
          # self-manage fleek
          {
            home.packages = [
              fleek.packages.x86_64-linux.default
            ];
          }
          ({
           nixpkgs.overlays = [inputs.emacs-overlay.overlay inputs.nixgl.overlay ];
          })

        ];
      };
      
      "aaravchen@bazzite" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = { inherit inputs; }; # Pass flake inputs to our config
        modules = [
          ./home.nix 
          ./path.nix
          ./shell.nix
          ./user.nix
          ./aliases.nix
          ./programs.nix
          # Host Specific configs
          ./bazzite/aaravchen.nix
          ./bazzite/custom.nix
          # self-manage fleek
          {
            home.packages = [
              fleek.packages.x86_64-linux.default
            ];
          }
          ({
           nixpkgs.overlays = [inputs.emacs-overlay.overlay inputs.nixgl.overlay ];
          })

        ];
      };
      
    };
  };
}
