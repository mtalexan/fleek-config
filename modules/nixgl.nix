{ pkgs, misc, lib, config, options, inputs, ... }: {
  # WARNING: because we need an 'options.' key here, we have to use the verbose format with a 'config.home.' for home-manager things

  # Reference: https://nix-community.github.io/home-manager/index.xhtml#sec-usage-gpu-non-nixos

  # This sets up the config.lib.nixGL.wrappers.* functions so they can be used, and the options configure
  # the config.lib.nixGL.wrap and config.lib.nixGL.wrapOffload aliases.
  # Usage in other files looks like one of the following:
  #    programs.mpv = {
  #      enable = true;
  #      package = config.lib.nixGL.wrap pkgs.mpv;
  #    };
  #    
  #    home.packages = [
  #      (config.lib.nixGL.wrapOffload pkgs.freecad)
  #      (config.lib.nixGL.wrappers.nvidiaPrime pkgs.xonotic)
  #    ];

  # Every per-system custom.nix file should include a block that looks like:
  #   config.custom.nixGL.gpu = true; # or false

  # Integrate nixGL into the home-manager. This requires the nixGL overlay to be enabled in Fleek.
  # Fleek maps each overlay as an input flake, but then passes the input flakes weirdly to the config
  # files without giving them a nicer name. So we have to reference them directly from 'inputs'
  config.nixGL.packages = inputs.nixgl.packages;

  # Supports some basic nixGL wrapper customizations.
  #   gpu : bool : Does the system have a dGPU that should be used for GPU-capable programs?
  options.custom.nixGL = with lib; {
    gpu = mkEnableOption(mdDoc "Is there a dGPU in the system that should be used for GPU-capable programs?");
  };

  config.nixGL = {
    # Can be "mesa", "mesaPrime", "nvidia", or "nvidiaPrime".
    # Poorly documented but "mesa" should be used for non-NVIDIA graphics,
    # the non-*Prime refers to the primary GPU (dGPU takes precendece over iGPU when both are present),
    # and the *Prime only if there's two GPUs and it should explicitly be the non-default dGPU.
    default.wrapper = if config.custom.nixGL.gpu then "nvidia" else "mesa";
    offloadWrapper = if config.custom.nixGL.gpu then "nvidiaPrime" else "mesa";
    # Install callable commands 'nixGL{name}' for manual running.
    installScripts = [
      "mesa"
    ] ++
    ( if config.custom.nixGL.gpu then [
        "nvidia"
        "nvidiaPrime"
      ]
      else []
    );
  };
}
# vim: sw=2:expandtab