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
          ./fedora_aaravchen.nix
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
          ./hosts/goln-5cl17g3_mtalexander.nix
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
          ./hosts/laptop_aaravchen.nix
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
          ./hosts/laptopFedora_aaravchen.nix
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
          ./hosts/goln-422q533_mtalexander.nix
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
          ./hosts/kubic-730xd_mike.nix
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
          ./hosts/cloud-t610_mike.nix
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
          ./hosts/vm-gol-422Q533_dev.nix
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
          ./hosts/laptopFedora_aaravchen2.nix
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
          ./hosts/WINDOWS-GAMING_aaravchen.nix
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
          ./hosts/bazzite_aaravchen.nix
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
      
      "aaravchen@helios300" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = { inherit inputs; }; # Pass flake inputs to our config
        modules = [
          ./home.nix 
          ./path.nix
          ./shell.nix
          ./user.nix
          ./hosts/helios300_aaravchen.nix
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
