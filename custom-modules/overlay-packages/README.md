The files in here are expected to be imported into an overlay like:


```nix
outputs = { self, nixpkgs, home-manager, ... }@inputs:
let
    # ...
    overlays = [
        #...
        (import custom-modules/overlay-packages/filename.nix )
        #...
    ];
    pkgs = import nixpkgs { inherit system overlays; }
in {
    # ...
};
```

These are non-trivial overlays that either insert packages, or affect the set of exposed packages under the `pkgs` variable for the rest of the home-manager config.