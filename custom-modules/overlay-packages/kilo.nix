kiloSrc: final: prev:
let
  packageJson = builtins.fromJSON (builtins.readFile (kiloSrc + "/packages/opencode/package.json"));
  generatedBunNix = prev.runCommand "kilo-bun.nix" {
    nativeBuildInputs = [ prev.bun2nix ];
  } ''
    bun2nix \
      --lock-file ${kiloSrc}/bun.lock \
      --copy-prefix ${kiloSrc}/ \
      --output-file $out
  '';
  bunNixHelpers = {
    copyPathToStore = path: builtins.path {
      inherit path;
      name = prev.lib.strings.sanitizeDerivationName (baseNameOf path);
    };
    fetchFromGitHub = _: prev.writeText "bun2nix-package-placeholder" "";
    fetchgit = _: prev.writeText "bun2nix-package-placeholder" "";
    fetchurl = _: prev.writeText "bun2nix-package-placeholder" "";
  };
  # This is how it would normally be done, but kilo's patches don't apply cleanly and require the native
  # bun custom patching logic that fuzzy applies. We use a fork of bun2nix that includes useNativeBunPatches
  # to allow bun to do it for us.
  #generatedPackages = import generatedBunNix bunNixHelpers;
  #patchedDependencies = prev.lib.filterAttrs (name: _: builtins.hasAttr name generatedPackages) (
  #  prev.lib.mapAttrs (_: path: kiloSrc + "/${path}") (
  #    (builtins.fromJSON (builtins.readFile (kiloSrc + "/package.json"))).patchedDependencies
  #  )
  #);
in {
  kilo = prev.bun2nix.mkDerivation {
    pname = "kilo";
    inherit (packageJson) version;
    src = kiloSrc;

    bunDeps = prev.bun2nix.fetchBunDeps {
      bunNix = args: import generatedBunNix (bunNixHelpers // args);
      # If we need the patched bun2nix CLI tool, it can be done this way. We are using the fork for
      # getting useNativeBunPatches, which already includes this as well.
      #overrides = prev.bun2nix.patchedDependenciesToOverrides { inherit patchedDependencies; };
    };

    # WARNING: This option requires the forked version of bun2nix.
    useNativeBunPatches = true;
    dontRunLifecycleScripts = true;
    nativeBuildInputs = with prev; [
      nodejs
      bubblewrap
      installShellFiles
      makeBinaryWrapper
      models-dev
      ripgrep
      versionCheckHook
      writableTmpDirAsHomeHook
    ];

    env = {
      MODELS_DEV_API_JSON = "${prev.models-dev}/dist/_api.json";
      KILO_DISABLE_MODELS_FETCH = true;
      KILO_SKIP_BUNDLED_BWRAP = "1";
      KILO_VERSION = packageJson.version;
      KILO_CHANNEL = "local";
    };

    buildPhase = ''
      cd packages/opencode
      bun --bun ./script/build.ts --single --skip-install
      bun --bun ./script/schema.ts schema.json
    '';

    installPhase = ''
      install -Dm755 dist/@kilocode/cli-*/bin/kilo $out/bin/kilo
      install -Dm644 schema.json $out/share/kilo/schema.json
      wrapProgram $out/bin/kilo \
        --set KILO_BWRAP_PATH ${prev.bubblewrap}/bin/bwrap \
        --prefix PATH : ${prev.lib.makeBinPath [ prev.ripgrep ]}
    '';

    meta = {
      description = "AI-powered development tool";
      homepage = "https://kilo.ai/";
      license = [ prev.lib.licenses.mit prev.lib.licenses.lgpl2Plus ];
      mainProgram = "kilo";
    };
  };
}