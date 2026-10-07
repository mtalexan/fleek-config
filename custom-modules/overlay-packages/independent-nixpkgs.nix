# This is an importable file for use in the flake.nix overlay definitions.
#
# This utility defines packages that use an independent version of nixpkgs to resolve their dependencies.
# That allows their flake to be updated independently and not run into dependency version conflicts.
#
# Args:
#   nixpkgsInput: The flake input that provides the packages and their independent nixpkgs.
#   packagePairs: A list of [sourceName overlayName] pairs. sourceName is the package in the flake input.
#     overlayName is the name assigned in the overlay.
# Example usage:
#   ((import custom-modules/overlay-packages/independent-nixpkgs.nix) inputs.some-flake [
#     [ "some-package" "new-package-name" ]
#     [ "another-package" "another-new-name" ]
#   ])

nixpkgsInput: packagePairs: final: prev:
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
in
builtins.listToAttrs (map (pair: {
  name = builtins.elemAt pair 1;
  value = pkgs.${builtins.elemAt pair 0};
}) packagePairs)
