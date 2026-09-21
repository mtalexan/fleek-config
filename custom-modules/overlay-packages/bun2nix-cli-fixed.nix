# This applies a patch to the bun2nix so that when bun.lock specifies a tarball and includes the
# content hash (which is standard now), the bun2nix CLI tool that converts a bun.lock into a bun.nix
# no longer ignores the hash and does a prefetch to calculate it, but reuses the defined hash without prefetch.
#
# This theoretically eliminates prefetching for modern bun.lock files, which allows the bun.lock -> bun.nix
# to be executed as part of a sandboxed nix build fully deterministically and without any network lookups.
#
# This patch is unnecessary once this PR is merged: https://github.com/nix-community/bun2nix/pull/108
bun2nixSrc: final: prev: {
  bun2nix = bun2nixSrc.packages.${prev.stdenv.hostPlatform.system}.default.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [
      ./patches/bun2nix-explicit-tarball-integrity.patch
    ];
    patchFlags = (oldAttrs.patchFlags or [ ]) ++ [ "-p3" ];
  });
}