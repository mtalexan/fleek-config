{ pkgs, misc, lib, ... }: {
  # This is actually called the Cloudflare Zero Trust Agent now.

  # This provides services that must be manually enabled
  #   system service: warp-svc.service
  #   user service: warp-taskbar.service
  home.packages = [
    pkgs.cloudflare-warp
  ];

}