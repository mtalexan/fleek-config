{ pkgs, lib, config }:
# Routes Plannotator reviews and editor requests to the herdr client that is viewing the session.
# Returns the bridge tool. The janitor timer runs on the server. Attach through `herdr-bridge wrap`
# (aliased as herdr) on the viewing machine.
let
  cfg = config.custom.herdr.bridge;
  herdrBin = lib.getExe config.programs.herdr.package;

  substitutions = {
    "@herdr@" = herdrBin;
    "@ssh@" = lib.getExe pkgs.openssh;
    "@xdgOpen@" = lib.getExe' pkgs.xdg-utils "xdg-open";
    "@claimTimeout@" = toString cfg.claimTimeout;
    "@pendingMaxAge@" = toString cfg.janitor.pendingMaxAge;
    "@claimStaleAfter@" = toString cfg.janitor.claimStaleAfter;
    "@defaultEditor@" = cfg.editor.default;
    "@altEditor@" = cfg.editor.alt;
  };

  substitute = file: subs: builtins.replaceStrings (builtins.attrNames subs) (builtins.attrValues subs) (builtins.readFile file);

  tool = pkgs.writers.writePython3Bin "herdr-bridge" {
    flakeIgnore = [ "E501" "E731" ];
  } (substitute ./herdr-bridge/herdr-bridge.py substitutions);
in
{
  inherit tool;
}
