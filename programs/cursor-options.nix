{ pkgs, lib, ... }:
let
  inherit (lib) mkOption types;

  # Cursor hooks.json event names (user-level ~/.cursor/hooks.json).
  cursorHookTypes = [
    # Agent
    "sessionStart"
    "sessionEnd"
    "preToolUse"
    "postToolUse"
    "postToolUseFailure"
    "subagentStart"
    "subagentStop"
    "beforeShellExecution"
    "afterShellExecution"
    "beforeMCPExecution"
    "afterMCPExecution"
    "beforeReadFile"
    "afterFileEdit"
    "beforeSubmitPrompt"
    "preCompact"
    "stop"
    "afterAgentResponse"
    "afterAgentThought"
    # Tab
    "beforeTabFileRead"
    "afterTabFileEdit"
    # App
    "workspaceOpen"
  ];

  hookTypeOption = hookType: mkOption {
    type = types.listOf (types.attrsOf (pkgs.formats.json { }).type);
    default = [ ];
    description = ''
      Hook script entries for Cursor's "${hookType}" event in ~/.cursor/hooks.json.

      Each list item is a JSON object using normal Nix→JSON field names, e.g.:
        { command = "./hooks/example.sh"; timeout = 10; matcher = "Shell"; failClosed = true; }

      List merge order is the JSON array order Cursor runs. Wrap assignments with
      lib.mkOrder / lib.mkBefore (500) / lib.mkAfter (1500), not objects inside the list:

        custom.cursor.hooks.${hookType} = lib.mkOrder 500 [{ command = "./hooks/first.sh"; }];
    '';
    example = [
      {
        command = "./hooks/example.sh";
        timeout = 10;
      }
    ];
  };
in {
  options.custom.cursor.hooks = lib.genAttrs cursorHookTypes hookTypeOption;
}

# vim: ts=2:sw=2:expandtab
