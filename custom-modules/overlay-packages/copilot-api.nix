# This is an importable file for use in the flake.nix overlay definitions.
#
# This is the build wrapper for the copilot-api-rust project so it can be injected as a copilot-api package in an overlay.
# Args:
#   copilotApiInput: The flake input that has the source code for the project.
# Example usage:
#   ((import custom-modules/overlay-packages/copilot-api.nix) copilot-api-src)
copilotApiInput: final: prev: {
  # Build the copilot-api Rust package from source, as pkgs.copilot-api
  copilot-api = final.rustPlatform.buildRustPackage {
    pname   = "copilot-api";
    version = copilotApiInput.shortRev or "unknown";

    src = copilotApiInput;  # the flake input IS the source

    cargoLock.lockFile = "${copilotApiInput}/Cargo.lock";

    # WARNING: copilot-api v1.14.0 has a bug in the test implementation that cause cross-contamination
    #          between some of the tests. As a result, the 'cargo test' always fails on `claude_malformed_usage_never_coerces_to_success`
    #          unless tests just so happen to run in just the right order and the cross-contamination causes a false
    #          success.
    #          Disable the tests for now.
    doCheck = false;

    meta = {
      description = "OpenAI/Anthropic-compatible gateway for GitHub Copilot (Rust port)";
      homepage    = "https://github.com/Arthur742Ramos/copilot-api-rust";
      license     = final.lib.licenses.mit;
      mainProgram = "copilot-api";
    };
  };
}