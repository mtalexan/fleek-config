{ lib, config, ... }:
let
  cfg = config.custom.jabra-engage-75;
in {
  # PipeWire only sees this headset mute, not unmute. Soft-mixer leaves mute to the headset.
  config = lib.mkIf cfg.disablePipewireMuteHandling {
    xdg.configFile."wireplumber/wireplumber.conf.d/51-headset-soft-mute.conf".text = ''
      monitor.alsa.rules = [
        {
          matches = [ { device.name = "~alsa_card.usb-GN_Audio_A_S_Jabra_Engage_75_0345AEB5E80F-00*" } ]
          actions = { update-props = { api.alsa.soft-mixer = true } }
        }
      ]
    '';
  };
}

# vim: ts=2:sw=2:expandtab
