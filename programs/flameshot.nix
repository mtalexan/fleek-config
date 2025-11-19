{ pkgs, misc, lib, config, options, ... }: {

  # Service not program
  services.flameshot = {
    enable = true;
    # Use some other version flameshot and setup most of the settings. You can then export that config,
    # or find it in the default ~/.config/flameshot/flameshot.ini file.
    settings = {
      General = {
        # This can't be set. Even when the value is written to the file exactly correctly, Flameshot claims an error with it.
        # Not setting it gives the defaults for the buttons, which is all of them.
        #buttons = ''@Variant(\0\0\0\x7f\0\0\0\vQList<int>\0\0\0\0\x14\0\0\0\0\0\0\0\x1\0\0\0\x2\0\0\0\x3\0\0\0\x4\0\0\0\x5\0\0\0\x6\0\0\0\x12\0\0\0\xf\0\0\0\x13\0\0\0\a\0\0\0\b\0\0\0\t\0\0\0\x10\0\0\0\n\0\0\0\v\0\0\0\f\0\0\0\r\0\0\0\xe\0\0\0\x11)'';
        contrastOpacity = 188;
        filenamePattern = "Screenshot_%F_%H-%M";
        showStartupLaunchMessage = false;
        startupLaunch = true;
      };
    };
  };
}