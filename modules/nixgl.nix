{ pkgs, misc, lib, config, options, inputs, ... }: {
  # WARNING: because we need an 'options.' key here, we have to use the verbose format with a 'config.home.' for home-manager things

  # Example per-host configuration for GPUs:
  # custom.nixGL = {
  #   has_dgpu = true; # or false, an NVIDIA dGPU
  #   primary_gpu = "iGPU"; # or "dGPU". iGPU also includes non-AMD dGPUs
  #   use_vulkan = true; # if needed
  # };
  # 
  # Programs/tools that support HW rendering should use the wrappers:
  #   config.nixGL.wrap = for light-use HW rendering or when the primary renderer is required.
  #   config.nixGL.wrapOffload = the non-primary renderer if there are multiple GPUs. May or may not be able to handle heavier load, see wrappers.nvidia if a specific one is needed.
  #   confuig.nixGL.wrappers.nvidia = for heavy-use HW rendering that always requires an NVIDIA dGPU specifically. But only valid on systems with an NVIDIA dGPU

  # Supports some basic nixGL wrapper customizations.
  #   gpu : bool : Does the system have an NVIDIA dGPU that should be used for GPU-capable programs?
  options.custom.nixGL = with lib; {
    has_dgpu = mkEnableOption ''
      Is there an NVIDIA dGPU in the system? The primary_gpu option determines whether this is actually the primary display renderer or not.
      Only NVIDIA dGPUs should set this, non-AMD dGPUs are treated the same as iGPUs!
    '';
    has_only_dgpu = mkEnableOption ''
      Is there only an NVIDIA dGPU in the system? The normal assumption is that there's only a non-NVIDIA dGPU or an iGPU in the system, and 
      there may be an NVIDIA dGPU but it's an optional addition.  Setting this will only have an effect if has_dgpu is also set, otherwise
      this is ignored since there must be at least one GPU in the system.
      AMD dGPUs are treated the same as iGPUs!
    '';
    primary_gpu = mkOption {
      type = types.enum ["iGPU" "dGPU"];
      default = "iGPU";
      description = ''
        Which GPU should be used as the primary? The defaultWrapper is set to match the primary GPU since most tools with HW accelerated rendering need
        to use the primary display rendering GPU or they won't work. 
        iGPU indicates either an iGPU or a non-NVIDIA dGPU.
      '';
    };
    use_vulkan = mkEnableOption ''
      Include Vulkan support? This is required for some things like Zed, but the underlying module's features have a warning about symbol conflicts when enabled.
    '';
  };

  config.nixGL = {
    # Reference: https://nix-community.github.io/home-manager/index.xhtml#sec-usage-gpu-non-nixos
    # Incredibly poor and misleading documentation.
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
    # Simply because these "Prime" wrappers are an option, home-manager requires --impure evaluation, even when they're not used.

    # Tell it where to find the nixgl from the overlay.
    packages = inputs.nixgl.packages;

    # We can technically set and use these however we want. We've chosen to make "wrap" (defaultWrapper) point to the primary/light-use GPU, and
    # "wrapOffload" (offloadWrapper) point to the heavy-use GPU if there is one.
    # Many tools, especially tools using Vulkan, will only use the primary renderer though, so on systems that have both and are configured to use the
    # dGPU as the primary screen renderer, we want to be sure the defaultWrapper is the dGPU instead of the iGPU.
    # We expect tools that can do HW rendering but don't need a lot of power to use "wrap", and those that need a lot of power to use "wrapOffload".
    defaultWrapper = if (config.custom.nixGL.has_dgpu && (config.custom.nixGL.primary_gpu == "dGPU" || config.custom.nixGL.has_only_dgpu)) then "nvidia" else "mesa";
    # If there are multiple GPUs, the non-primary one. If there's only 1 GPU though, this matches the defaultWrapper.
    # mesa should be used for everything except NVIDIA dGPUs, so we still fall back to it if there is no dGPU.
    offloadWrapper = if (config.custom.nixGL.has_dgpu && (config.custom.nixGL.primary_gpu == "iGPU" || config.custom.nixGL.has_only_dgpu)) then "nvidia" else "mesa";
    # Install callable commands 'nixGL{Name}' for manual running things from a terminal
    installScripts = 
    ( if (!config.custom.nixGL.has_dgpu || !config.custom.nixGL.has_only_dgpu)
      then
        [
          "mesa" # nixGLMesa
        ]
      else
        []
    ) ++
    ( if config.custom.nixGL.has_dgpu
      then
        [
          "nvidia" # nixGLNvidia
        ]
      else
        []
    );
    
    # only enable if requested. There's a warning about it potentially causing sybmol conflicts.
    vulkan.enable = config.custom.nixGL.use_vulkan;
  };
}

# vim: ts=2:sw=2:expandtab
