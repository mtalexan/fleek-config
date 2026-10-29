# This is an importable file for use in the flake.nix overlay definitions.
#
# This utility exposes packages from an independent flake input.
# Their dependencies stay with that input, so updating it does not collide with the shared nixpkgs.
#
# Args:
#   flakeInput: A nixpkgs flake, or a flake that exposes packages.<system>.<name>.
#   packagePairs: A list of [sourceName overlayName] pairs. sourceName is the package in the flake input.
#     overlayName is the name assigned in the overlay.
# Example usage:
#   ((import custom-modules/overlay-packages/independent-package-from-flake.nix) inputs.some-flake [
#     [ "some-package" "new-package-name" ]
#     [ "another-package" "another-new-name" ]
#   ])

flakeInput: packagePairs: final: prev:
let
  system = prev.stdenv.hostPlatform.system;
  # Nixpkgs inputs also expose packages, but importing them applies allowUnfree.
  # Other flakes only expose packages already built against their own nixpkgs.
  pkgs =
    if flakeInput ? packages && !(flakeInput ? legacyPackages) then
      flakeInput.packages.${system}
    else
      import flakeInput {
        inherit system;
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
