{ pkgs, misc, lib, config, ... }: {

  options.custom.atuin = with lib; {
    ai = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable the AI features of atuin.
      '';
    };
  };
  
  config = {
    programs.atuin = {
      enable = true;
      # run a daemon in the background so sync actually works
      daemon.enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      flags = [
        "--disable-up-arrow"
        (lib.mkIf (! config.custom.atuin.ai) "--disable-ai")
      ];
      settings = {
        # do not set daemon.autostart = true, it replaces systemd management
  
        update_check = false;
        dialect = "us";
  
        # fzf-style search syntax.
        # Uses the daemon to do the fuzzy, which is more efficient and allows more tuning.
        search_mode = "daemon-fuzzy";
  
        # look at history of just the one session by default, hitting Ctrl+R again will give host
        filter_mode = "session";
        # when pressing up-key, only look in the session
        filter_mode_shell_up_key_binding = "session";
  
        # other formats take up more space and count towards the inline_height
        style = "compact";
        inline_height = 10;
  
        # don't show an extra help line
        show_help = false;
  
        # show a preview of the full command
        show_preview = true;
  
        # return-original doesn't work, it always wipes it
        exit_mode = "return-query";
  
        # per-git-repo mode
        workspaces = "true";
  
        # Setup for syncing and sync frequency is defined by the identities
  
        # Enable the capturing of all the output from commands too
        pty_proxy.enabled = true;
      } // 
      lib.mkIf (config.custom.atuin.ai) {
        ai = {
          enabled = true;
          opening = {
            send_cwd = true;
            send_last_command = true;
          };
        };
      };
    };
  };
}

# vim: ts=2:sw=2:expandtab
