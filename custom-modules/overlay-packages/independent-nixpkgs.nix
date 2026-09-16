# This is an importable file for use in the flake.nix overlay definitions.
#
# This is a utility for defining a package the uses an independent version of nixpkgs in order to resolve its dependencies.
# That allows its flake to be updated independently and not run into dependency version conflicts.
#
# Args:
#   nixpkgsInput: The flake input we're getting the package from that needs independent nixpkgs.
#   packageName: The name of the package in the flake input.
#   newPackageName: The name to assign to the package in the overlay.
# Example usage:
#   ((import custom-modules/overlay-packages/independent-nixpkgs.nix) inputs.some-flake "some-package" "new-package-name")

nixpkgsInput: packageName: newPackageName: final: prev:
let
  pkgs = import nixpkgsInput {
    inherit (prev.stdenv.hostPlatform) system;
    # Because we're using a separate nixpkgs from the shared input, we have to explicitly set these
    # on the independent copy as well.
    config = {
      allowUnfree = true;
      allowunfreePredicate = (_: true);
    };
  };
in {
  "${newPackageName}" = pkgs.${packageName};
}