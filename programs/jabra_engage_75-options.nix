{ lib, ... }: {
  options.custom.jabra-engage-75 = with lib; {
    disablePipewireMuteHandling = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Write ~/.config/wireplumber/wireplumber.conf.d/51-headset-soft-mute.conf for WirePlumber 0.5 or newer.

        The rule sets api.alsa.soft-mixer on alsa_card.usb-GN_Audio_A_S_Jabra_Engage_75_0345AEB5E80F-00.
        PipeWire detects that headset's mute button changing to muted but not back to unmuted, so its mirrored mute state gets stuck.
        Soft-mixer leaves mute handling to the headset.

        Set this to false to omit the file and leave PipeWire mute handling enabled.
      '';
    };
  };
}

# vim: ts=2:sw=2:expandtab
