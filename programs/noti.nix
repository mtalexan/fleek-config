{ pkgs, misc, lib, ... }: {
  # notifies of completed commands. Can also Ctrl+Z a command and then add noti to it with:
  #   fg; noti
  # Always includes banner notifications, but can include Telegram, Slack, Zulip, whatever
  # if configured.
  programs.noti = {
    enable = true;
    # settings = {
    #  # see   https://github.com/variadico/noti/blob/main/docs/noti.md#configuration
    #};
  };
}

# vim: sw=2:expandtab
