{ pkgs, misc, lib, config, options, inputs, ... }: {
  # WARNING: because we need an 'options.' key here, we have to use the verbose format with a 'config.home.' for home-manager things

  # Every per-system custom.nix file should include a block that looks like:
  #   config.custom.nixGL.gpu = true; # or false
  # This indicates whether the system has an NVIDIA dGPU or not.
  # Programs/tools that support HW rendering should use the wrappers:
  #   config.nixGL.wrap = for ligh-use HW rendering.
  #   config.nixGL.wrapOffload = for heavy-use HW rendering that uses the best available but can fallback to weaker GPUs.
  #   confuig.nixGL.wrappers.nvidia = for heavy-use HW rendering that always requires an NVIDIA dGPU.

  # Supports some basic nixGL wrapper customizations.
  #   gpu : bool : Does the system have an NVIDIA dGPU that should be used for GPU-capable programs?
  options.custom.nixGL = with lib; {
    # TODO: Don't assume there's always a 
    gpu = mkEnableOption("Is there an NVIDIA dGPU that we should use for heavy-duty HW rendering? If not, we fallback to the iGPU as well.");
  };

  config.nixGL = {
    # Reference: https://nix-community.github.io/home-manager/index.xhtml#sec-usage-gpu-non-nixos
    # Incredibly poor and misleading documention.
    # WARNING: The home-manager implementation forces impure evaluation to set defaults for values that only
    #          affect functions we don't make use of.
    #
    # Home-manager adds a 'wrapper' field to the config.lib.nixGL brought in by the normal nixGL overlay
    # and defines 4 pre-defined wrappers: "mesa", "nvidia", "mesaPrime", "nvidiaPrime",
    # and 2 configurable wrappers: "wrap" and "wrapOffload"
    # The 2 configurable wrappers can be configured to each point to one of the 4 pre-defined wrappers
    # by setting "defaultWrapper" and "offlineWrapper".
    #
    # The wrappers can be used to wrap the pkg for a home.packages pkg, or a programs.<name>.pkg like so:
    #
    #    programs.mpv = {
    #      enable = true;
    #      # uses the defaultWrapper
    #      package = config.lib.nixGL.wrap pkgs.mpv;
    #    };
    #    
    #    home.packages = [
    #      (config.lib.nixGL.wrapOffload pkgs.freecad)
    #      (config.lib.nixGL.wrappers.nvidiaPrime pkgs.xonotic)
    #    ];
    #
    # The wrappers ensure the wrapped pkg binaries and desktop file calls to the binaries will use the wrapped command
    # instead, and ensure the wrapping command is available to be used.
    #
    # "mesa" wraps with 'nixGLIntel', and "nvidia" wraps with 'nixGLNvidia' (both hardcoded).
    # The non-"Prime" wrappers always use the default GPU that supports the selected drivers and the default GPU settings.
    # This means a iGPU+dGPU system where the iGPU is Intel/AMD and the dGPU is NVIDIA can pick which of the two GPUs to use
    # simply by using "mesa" (the only non-NVIDIA GPU is the iGPU) and "nvidia" (the only NVIDIA GPU is the dGPU).
    #
    # The "Prime" set of wrappers share a single set of home-manager nixGL options and override the run-time system default selection
    # of the GPU to use.  The configurable options are:
    #  - The exact PCIe bus index of the GPU to use
    #  - (optional) The exact NVIDIA diver type (e.g. "NVIDIA-G0")
    #  - Whether to force Vulkan use or not.
    # This allows the "Prime" options to be configured to point to a second dGPU, or any non-default GPU configuration,
    # but using the "Prime" wrappers will always require the home-manager switch to use '--impure'.

    # Tell it where to find the nixgl from the overlay.
    packages = inputs.nixgl.packages;

    # We can technically set and use these however we want. We've chosen to make "wrap" (defaultWrapper) point to the light-use GPU, and
    # "wrapOffload" (offloadWrapper) point to the heavy-use GPU.
    # We expect tools that can do HW rendering but don't need a lot of power to use "wrap", and those that need a lot of power to use "wrapOffload".
    defaultWrapper = "mesa";
    offloadWrapper = if config.custom.nixGL.gpu then "nvidia" else "mesa";
    # Install callable commands 'nixGL{Name}' for manual running things from a terminal
    installScripts = [
      "mesa" # nixGLMesa
    ] ++
    ( if config.custom.nixGL.gpu then
        [
          "nvidia" # nixGLNvidia
        ]
      else
        []
    );
  };
}

# vim: ts=2:sw=2:expandtab
