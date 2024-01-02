{ pkgs, misc, lib, ... }: {
  # A terminal multiplexer with lots of features, but also high speed.
  # WARNING: The nix version doesn't work since it's hermatically sealed against system graphics capabilities detection.
  #          Kitty must be manually installed instead, following the directions here: https://sw.kovidgoyal.net/kitty/binary/#binary-install
  #          The current config below relies on the kitty.app being in home_files, and will link the application.

  options.custom.kitty.config = with lib; {
    fromNix = mkEnableOption(mdDoc "Use kitty from nix instead of the one included in the repo directly (OpenGL issues?)")
  };

  # Add manually installed tools to the PATH (~/.local/bin)
  config.home.file = {
    ".local/bin/kitty" = {
      enable = !config.custom.kitty.config.fromNix;
      executable = true;
      source = ../home_files/kitty.app/bin/kitty;
    };
    ".local/bin/kitten" = {
      enable = !config.custom.kitty.config.fromNix;
      executable = true;
      source = ../home_files/kitty.app/bin/kitten;
    };
    # install the icon
    ".local/share/icons/kitty.png" = {
      enable = !config.custom.kitty.config.fromNix;
      executable = false;
      source = ../home_files/kitty.app/share/icons/hicolor/256x256/apps/kitty.png;
    };
    # add the .desktop files
    ".local/share/applications/kitty.desktop" = {
      enable = !config.custom.kitty.config.fromNix;
      executable = false;
      # There's a desktop file shipped with kitty.app, but it needs the Icon and Exec path fixed.
      # The file is so simple anyway, just generate it instead.
      text = ''
        [Desktop Entry]
        Version=1.0
        Type=Application
        Name=kitty
        GenericName=Terminal emulator
        Comment=Fast, feature-rich, GPU based terminal
        TryExec=kitty
        Exec=$HOME/.local/bin/kitty
        Icon=$HOME/.local/share/icons/kitty.png
        Categories=System;TerminalEmulator;
      '';
    };
    ".local/share/applications/kitty-open.desktop" = {
      enable = !config.custom.kitty.config.fromNix;
      executable = false;
      # There's a desktop file shipped with kitty.app, but it needs the Icon and Exec path fixed.
      # The file is so simple anyway, just generate it instead.
      text = ''
        [Desktop Entry]
        Version=1.0
        Type=Application
        Name=kitty URL Launcher
        GenericName=Terminal emulator
        Comment=Open URLs with kitty
        TryExec=kitty
        Exec=$HOME/.local/bin/kitty +open %U
        Icon=$HOME/.local/share/icons/kitty.png
        Categories=System;TerminalEmulator;
        NoDisplay=true
        MimeType=image/*;application/x-sh;application/x-shellscript;inode/directory;text/*;x-scheme-handler/kitty;x-scheme-handler/ssh;
      '';
    };
  };

  # manual kitty integration into the shell is required since automatic injection doesn't work for subshells, multiplexers, etc
  # See https://sw.kovidgoyal.net/kitty/shell-integration/#manual-shell-integration
  config.programs.zsh.initExtra = ''
    if test -n "$KITTY_INSTALLATION_DIR"; then
        export KITTY_SHELL_INTEGRATION="enabled"
        autoload -Uz -- "$KITTY_INSTALLATION_DIR"/shell-integration/zsh/kitty-integration
        kitty-integration
        unfunction kitty-integration
    fi
  '';
  config.programs.bash.initExtra = ''
    if test -n "$KITTY_INSTALLATION_DIR"; then
        export KITTY_SHELL_INTEGRATION="enabled"
        source "$KITTY_INSTALLATION_DIR/shell-integration/bash/kitty.bash"
    fi
  '';

  config.programs.kitty = {
    enable = config.custom.kitty.config.fromNix;
    shellIntegration = {
      # Since automatic shell integration doesn't work in subshells, multiplexers, etc, we have to manually detect and load the code ourselves
      # as part of the rc file
      mode = "disabled";
    };
    #environment = {
      # variables set on every child process.  Equivalent of 'env' in the settings.
    #  "LS_COLORS" = "1";
    #};

    #font = {
    #  # package to install in the nix profile to ensure the font is available.  Set to 'null' (default) if it's guaranteed to be there already.
    #  package = pkgs.nerdfonts;
    #  name = ???;
    #  size = ???;
    #};

    keybindings = {
      #: Keys are identified simply by their lowercase unicode characters.
      #: For example: ``a`` for the A key, ``[`` for the left square bracket
      #: key, etc. For functional keys, such as ``Enter or Escape`` the
      #: names are present at https://sw.kovidgoyal.net/kitty/keyboard-
      #: protocol.html#functional-key-definitions. For a list of modifier
      #: names, see: GLFW mods
      #: <https://www.glfw.org/docs/latest/group__mods.html>

      #: On Linux you can also use XKB key names to bind keys that are not
      #: supported by GLFW. See XKB keys
      #: <https://github.com/xkbcommon/libxkbcommon/blob/master/xkbcommon/xkbcommon-
      #: keysyms.h> for a list of key names. The name to use is the part
      #: after the XKB_KEY_ prefix. Note that you can only use an XKB key
      #: name for keys that are not known as GLFW keys.

      #: Finally, you can use raw system key codes to map keys, again only
      #: for keys that are not known as GLFW keys. To see the system key
      #: code for a key, start kitty with the kitty --debug-input option.
      #: Then kitty will output some debug text for every key event. In that
      #: text look for ``native_code`` the value of that becomes the key
      #: name in the shortcut. For example:

      #: .. code-block:: none

      #:     on_key_input: glfw key: 65 native_code: 0x61 action: PRESS mods: 0x0 text: 'a'

      #: Here, the key name for the A key is 0x61 and you can use it with::

      #:     map ctrl+0x61 something

      #: to map ctrl+a to something.

      #: You can use the special action no_op to unmap a keyboard shortcut
      #: that is assigned in the default configuration::

      #:     map kitty_mod+space no_op

      #: You can combine multiple actions to be triggered by a single
      #: shortcut, using the syntax below::

      #:     map key combine <separator> action1 <separator> action2 <separator> action3 ...

      #: For example::

      #:     map kitty_mod+e combine : new_window : next_layout

      #: this will create a new window and switch to the next available
      #: layout

      #: You can use multi-key shortcuts using the syntax shown below::

      #:     map key1>key2>key3 action

      #: For example::

      #:     map ctrl+f>2 set_font_size 20

      # kitty_mod ctrl+shift

      #: The value of kitty_mod is used as the modifier for all default
      #: shortcuts, you can change it in your kitty.conf to change the
      #: modifiers for all the default shortcuts.

      # clear_all_shortcuts no

      #: You can have kitty remove all shortcut definition seen up to this
      #: point. Useful, for instance, to remove the default shortcuts.

      # kitten_alias hints hints --hints-offset=0

      #: You can create aliases for kitten names, this allows overriding the
      #: defaults for kitten options and can also be used to shorten
      #: repeated mappings of the same kitten with a specific group of
      #: options. For example, the above alias changes the default value of
      #: kitty +kitten hints --hints-offset to zero for all mappings,
      #: including the builtin ones.

      # CLIPBOARD
      #-------------------------------------------------
      # "kitty_mod+c" = "copy_to_clipboard";

      #: There is also a copy_or_interrupt action that can be optionally
      #: mapped to Ctrl+c. It will copy only if there is a selection and
      #: send an interrupt otherwise. Similarly, copy_and_clear_or_interrupt
      #: will copy and clear the selection or send an interrupt if there is
      #: no selection.

      # "kitty_mod+v" = "paste_from_clipboard";
      # "kitty_mod+s" = "paste_from_selection";
      # "kitty_mod+o" = "pass_selection_to_program";

      #: You can also pass the contents of the current selection to any
      #: program using pass_selection_to_program. By default, the system's
      #: open program is used, but you can specify your own, the selection
      #: will be passed as a command line argument to the program, for
      #: example::

      #:     map kitty_mod+o pass_selection_to_program firefox

      #: You can pass the current selection to a terminal program running in
      #: a new kitty window, by using the @selection placeholder::

      #:     map kitty_mod+y new_window less @selection

      # SCROLLING
      #-------------------------------------------------
      # "kitty_mod+up"        = "scroll_line_up";
      # "kitty_mod+down"      = "scroll_line_down";
      # "kitty_mod+page_up"   = "scroll_page_up";
      # "kitty_mod+page_down" = "scroll_page_down";
      # "kitty_mod+home"      = "scroll_home";
      # "kitty_mod+end"       = "scroll_end";
      # "kitty_mod+h"         = "show_scrollback";

      #: You can pipe the contents of the current screen + history buffer as
      #: STDIN to an arbitrary program using the ``launch`` function. For
      #: example, the following opens the scrollback buffer in less in an
      #: overlay window::

      #:     map f1 launch --stdin-source=@screen_scrollback --stdin-add-formatting --type=overlay less +G -R

      #: For more details on piping screen and buffer contents to external
      #: programs, see launch.

      # WINDOW MGMT
      #-------------------------------------------------
      # "kitty_mod+enter" = "new_window";

      #: You can open a new window running an arbitrary program, for
      #: example::

      #:     map kitty_mod+y      launch mutt

      #: You can open a new window with the current working directory set to
      #: the working directory of the current window using::

      #:     map ctrl+alt+enter    launch --cwd=current

      #: You can open a new window that is allowed to control kitty via the
      #: kitty remote control facility by prefixing the command line with @.
      #: Any programs running in that window will be allowed to control
      #: kitty. For example::

      #:     map ctrl+enter launch --allow-remote-control some_program

      #: You can open a new window next to the currently active window or as
      #: the first window, with::

      #:     map ctrl+n launch --location=neighbor some_program
      #:     map ctrl+f launch --location=first some_program

      #: For more details, see launch.

      # "kitty_mod+n" = "new_os_window";

      #: Works like new_window above, except that it opens a top level OS
      #: kitty window. In particular you can use new_os_window_with_cwd to
      #: open a window with the current working directory.

      # "kitty_mod+w" = "close_window";
      # "kitty_mod+]" = "next_window";
      # "kitty_mod+[" = "previous_window";
      # "kitty_mod+f" = "move_window_forward";
      # "kitty_mod+b" = "move_window_backward";
      # "kitty_mod+`" = "move_window_to_top";
      # "kitty_mod+r" = "start_resizing_window";
      # "kitty_mod+1" = "first_window";
      # "kitty_mod+2" = "second_window";
      # "kitty_mod+3" = "third_window";
      # "kitty_mod+4" = "fourth_window";
      # "kitty_mod+5" = "fifth_window";
      # "kitty_mod+6" = "sixth_window";
      # "kitty_mod+7" = "seventh_window";
      # "kitty_mod+8" = "eighth_window";
      # "kitty_mod+9" = "ninth_window";
      # "kitty_mod+0" = "tenth_window";

      # TAB MGMT
      #-------------------------------------------------
      # "kitty_mod+right" = "next_tab";
      # "kitty_mod+left"  = "previous_tab";
      # "kitty_mod+t"     = "new_tab";
      # "kitty_mod+q"     = "close_tab";
      # "shift+cmd+w"     = "close_os_window";
      # "kitty_mod+."     = "move_tab_forward";
      # "kitty_mod+,"     = "move_tab_backward";
      # "kitty_mod+alt+t" = "set_tab_title";

      #: You can also create shortcuts to go to specific tabs, with 1 being
      #: the first tab, 2 the second tab and -1 being the previously active
      #: tab, and any number larger than the last tab being the last tab::

      #:     map ctrl+alt+1 goto_tab 1
      #:     map ctrl+alt+2 goto_tab 2

      #: Just as with new_window above, you can also pass the name of
      #: arbitrary commands to run when using new_tab and use
      #: new_tab_with_cwd. Finally, if you want the new tab to open next to
      #: the current tab rather than at the end of the tabs list, use::

      #:     map ctrl+t new_tab !neighbor [optional cmd to run]

      # LAYOUT MGMT
      #-------------------------------------------------
      # "kitty_mod+l" = "next_layout";

      #: You can also create shortcuts to switch to specific layouts::

      #:     map ctrl+alt+t goto_layout tall
      #:     map ctrl+alt+s goto_layout stack

      #: Similarly, to switch back to the previous layout::

      #:    map ctrl+alt+p last_used_layout

      # FONT SIZES
      #-------------------------------------------------
      #: You can change the font size for all top-level kitty OS windows at
      #: a time or only the current one.

      # "kitty_mod+equal"     = "change_font_size all +2.0";
      # "kitty_mod+minus"     = "change_font_size all -2.0";
      # "kitty_mod+backspace" = "change_font_size all 0";

      #: To setup shortcuts for specific font sizes::

      #:     map kitty_mod+f6 change_font_size all 10.0

      #: To setup shortcuts to change only the current OS window's font
      #: size::

      #:     map kitty_mod+f6 change_font_size current 10.0

      # SELECT AND ACT ON VISIBLE TEXT
      #-------------------------------------------------
      #: Use the hints kitten to select text and either pass it to an
      #: external program or insert it into the terminal or copy it to the
      #: clipboard.

      # "kitty_mod+e" = "kitten hints";

      #: Open a currently visible URL using the keyboard. The program used
      #: to open the URL is specified in open_url_with.

      # "kitty_mod+p>f" = "kitten hints --type path --program -";

      #: Select a path/filename and insert it into the terminal. Useful, for
      #: instance to run git commands on a filename output from a previous
      #: git command.

      # "kitty_mod+p>shift+f" = "kitten hints --type path";

      #: Select a path/filename and open it with the default open program.

      # "kitty_mod+p>l" "kitten hints --type line --program -";

      #: Select a line of text and insert it into the terminal. Use for the
      #: output of things like: ls -1

      # "kitty_mod+p>w" = "kitten hints --type word --program -";

      #: Select words and insert into terminal.

      # "kitty_mod+p>h" = "kitten hints --type hash --program -";

      #: Select something that looks like a hash and insert it into the
      #: terminal. Useful with git, which uses sha1 hashes to identify
      #: commits

      # "kitty_mod+p>n" = "kitten hints --type linenum";

      #: Select something that looks like filename:linenum and open it in
      #: vim at the specified line number.

      # "kitty_mod+p>y" = "kitten hints --type hyperlink";

      #: Select a hyperlink (i.e. a URL that has been marked as such by the
      #: terminal program, for example, by ls --hyperlink=auto).


      #: The hints kitten has many more modes of operation that you can map
      #: to different shortcuts. For a full description see kittens/hints.

      # MISC
      #-------------------------------------------------
      # "kitty_mod+f11"    = "toggle_fullscreen";
      # "kitty_mod+f10"    = "toggle_maximized";
      # "kitty_mod+u"      = "kitten unicode_input";
      # "kitty_mod+f2"     = "edit_config_file";
      # "kitty_mod+escape" = "kitty_shell window";

      #: Open the kitty shell in a new window/tab/overlay/os_window to
      #: control kitty using commands.

      # "kitty_mod+a>m"    = "set_background_opacity +0.1";
      # "kitty_mod+a>l"    = "set_background_opacity -0.1";
      # "kitty_mod+a>1"    = "set_background_opacity 1";
      # "kitty_mod+a>d"    = "set_background_opacity default";
      # "kitty_mod+delete" = "clear_terminal reset active";

      #: You can create shortcuts to clear/reset the terminal. For example::

      #:     # Reset the terminal
      #:     map kitty_mod+f9 clear_terminal reset active
      #:     # Clear the terminal screen by erasing all contents
      #:     map kitty_mod+f10 clear_terminal clear active
      #:     # Clear the terminal scrollback by erasing it
      #:     map kitty_mod+f11 clear_terminal scrollback active
      #:     # Scroll the contents of the screen into the scrollback
      #:     map kitty_mod+f12 clear_terminal scroll active

      #: If you want to operate on all windows instead of just the current
      #: one, use all instead of active.

      #: It is also possible to remap Ctrl+L to both scroll the current
      #: screen contents into the scrollback buffer and clear the screen,
      #: instead of just clearing the screen, for example, for ZSH add the
      #: following to ~/.zshrc:

      #: .. code-block:: sh

      #:     scroll-and-clear-screen() {
      #:         printf '\n%.0s' {1..$LINES}
      #:         zle clear-screen
      #:     }
      #:     zle -N scroll-and-clear-screen
      #:     bindkey '^l' scroll-and-clear-screen

      # "kitty_mod+f5" = "load_config_file";

      #: Reload kitty.conf, applying any changes since the last time it was
      #: loaded. Note that a handful of settings cannot be dynamically
      #: changed and require a full restart of kitty.  You can also map a
      #: keybinding to load a different config file, for example::

      #:     map f5 load_config /path/to/alternative/kitty.conf

      #: Note that all setting from the original kitty.conf are discarded,
      #: in other words the new conf settings *replace* the old ones.

      # "kitty_mod+f6" = "debug_config"

      #: Show details about exactly what configuration kitty is running with
      #: and its host environment. Useful for debugging issues.


      #: You can tell kitty to send arbitrary (UTF-8) encoded text to the
      #: client program when pressing specified shortcut keys. For example::

      #:     map ctrl+alt+a send_text all Special text

      #: This will send "Special text" when you press the ctrl+alt+a key
      #: combination.  The text to be sent is a python string literal so you
      #: can use escapes like \x1b to send control codes or \u21fb to send
      #: unicode characters (or you can just input the unicode characters
      #: directly as UTF-8 text). The first argument to send_text is the
      #: keyboard modes in which to activate the shortcut. The possible
      #: values are normal or application or kitty or a comma separated
      #: combination of them.  The special keyword all means all modes. The
      #: modes normal and application refer to the DECCKM cursor key mode
      #: for terminals, and kitty refers to the special kitty extended
      #: keyboard protocol.

      #: Another example, that outputs a word and then moves the cursor to
      #: the start of the line (same as pressing the Home key)::

      #:     map ctrl+alt+a send_text normal Word\x1b[H
      #:     map ctrl+alt+a send_text application Word\x1bOH
    };

    # note that the 'extraConfig' can be used to directly set the native format directly instead
    settings = {
      # Ctrl+Shift+F2 in kitty opens a well commented settings file

      # FONTS
      #-------------------------------------------------
      # See the font category above for just setting the font

      #: kitty does not support BIDI (bidirectional text), however, for RTL
      #: scripts, words are automatically displayed in RTL. That is to say,
      #: in an RTL script, the words "HELLO WORLD" display in kitty as
      #: "WORLD HELLO", and if you try to select a substring of an RTL-
      #: shaped string, you will get the character that would be there had
      #: the the string been LTR. For example, assuming the Hebrew word
      #: ירושלים, selecting the character that on the screen appears to be ם
      #: actually writes into the selection buffer the character י.  kitty's
      #: default behavior is useful in conjunction with a filter to reverse
      #: the word order, however, if you wish to manipulate RTL glyphs, it
      #: can be very challenging to work with, so this option is provided to
      #: turn it off. Furthermore, this option can be used with the command
      #: line program GNU FriBidi
      #: <https://github.com/fribidi/fribidi#executable> to get BIDI
      #: support, because it will force kitty to always treat the text as
      #: LTR, which FriBidi expects for terminals.

      # adjust_line_height = 0;
      # adjust_column_width = 0;

      #: Change the size of each character cell kitty renders. You can use
      #: either numbers, which are interpreted as pixels or percentages
      #: (number followed by %), which are interpreted as percentages of the
      #: unmodified values. You can use negative pixels or percentages less
      #: than 100% to reduce sizes (but this might cause rendering
      #: artifacts).

      # adjust_baseline = 0;

      #: Adjust the vertical alignment of text (the height in the cell at
      #: which text is positioned). You can use either numbers, which are
      #: interpreted as pixels or a percentages (number followed by %),
      #: which are interpreted as the percentage of the line height. A
      #: positive value moves the baseline up, and a negative value moves
      #: them down. The underline and strikethrough positions are adjusted
      #: accordingly.

      # symbol_map = "U+E0A0-U+E0A3,U+E0C0-U+E0C7 PowerlineSymbols";

      #: Map the specified unicode codepoints to a particular font. Useful
      #: if you need special rendering for some symbols, such as for
      #: Powerline. Avoids the need for patched fonts. Each unicode code
      #: point is specified in the form U+<code point in hexadecimal>. You
      #: can specify multiple code points, separated by commas and ranges
      #: separated by hyphens. symbol_map itself can be specified multiple
      #: times. Syntax is::

      #:     symbol_map codepoints Font Family Name

      # disable_ligatures = "never";

      #: Choose how you want to handle multi-character ligatures. The
      #: default is to always render them.  You can tell kitty to not render
      #: them when the cursor is over them by using cursor to make editing
      #: easier, or have kitty never render them at all by using always, if
      #: you don't like them. The ligature strategy can be set per-window
      #: either using the kitty remote control facility or by defining
      #: shortcuts for it in kitty.conf, for example::

      #:     map alt+1 disable_ligatures_in active always
      #:     map alt+2 disable_ligatures_in all never
      #:     map alt+3 disable_ligatures_in tab cursor

      #: Note that this refers to programming ligatures, typically
      #: implemented using the calt OpenType feature. For disabling general
      #: ligatures, use the font_features setting.

      # font_features = "none";

      #: Choose exactly which OpenType features to enable or disable. This
      #: is useful as some fonts might have features worthwhile in a
      #: terminal. For example, Fira Code Retina includes a discretionary
      #: feature, zero, which in that font changes the appearance of the
      #: zero (0), to make it more easily distinguishable from Ø. Fira Code
      #: Retina also includes other discretionary features known as
      #: Stylistic Sets which have the tags ss01 through ss20.

      #: For the exact syntax to use for individual features, see the
      #: Harfbuzz documentation <https://harfbuzz.github.io/harfbuzz-hb-
      #: common.html#hb-feature-from-string>.

      #: Note that this code is indexed by PostScript name, and not the font
      #: family. This allows you to define very precise feature settings;
      #: e.g. you can disable a feature in the italic font but not in the
      #: regular font.

      #: On Linux, these are read from the FontConfig database first and
      #: then this, setting is applied, so they can be configured in a
      #: single, central place.

      #: To get the PostScript name for a font, use kitty + list-fonts
      #: --psnames:

      #: .. code-block:: sh

      #:     $ kitty + list-fonts --psnames | grep Fira
      #:     Fira Code
      #:     Fira Code Bold (FiraCode-Bold)
      #:     Fira Code Light (FiraCode-Light)
      #:     Fira Code Medium (FiraCode-Medium)
      #:     Fira Code Regular (FiraCode-Regular)
      #:     Fira Code Retina (FiraCode-Retina)

      #: The part in brackets is the PostScript name.

      #: Enable alternate zero and oldstyle numerals::

      #:     font_features FiraCode-Retina +zero +onum

      #: Enable only alternate zero::

      #:     font_features FiraCode-Retina +zero

      #: Disable the normal ligatures, but keep the calt feature which (in
      #: this font) breaks up monotony::

      #:     font_features TT2020StyleB-Regular -liga +calt

      #: In conjunction with force_ltr, you may want to disable Arabic
      #: shaping entirely, and only look at their isolated forms if they
      #: show up in a document. You can do this with e.g.::

      #:     font_features UnifontMedium +isol -medi -fina -init

      # box_drawing_scale 0.001, 1, 1.5, 2

      #: Change the sizes of the lines used for the box drawing unicode
      #: characters These values are in pts. They will be scaled by the
      #: monitor DPI to arrive at a pixel value. There must be four values
      #: corresponding to thin, normal, thick, and very thick lines.

      # CURSOR
      #-------------------------------------------------
      # cursor = "#cccccc";

      #: Default cursor color

      # cursor_text_color = "#111111";

      #: Choose the color of text under the cursor. If you want it rendered
      #: with the background color of the cell underneath instead, use the
      #: special keyword: background

      # cursor_shape = "block";

      #: The cursor shape can be one of (block, beam, underline). Note that
      #: when reloading the config this will be changed only if the cursor
      #: shape has not been set by the program running in the terminal.

      # cursor_beam_thickness = 1.5;

      #: Defines the thickness of the beam cursor (in pts)

      # cursor_underline_thickness = 2.0;

      #: Defines the thickness of the underline cursor (in pts)

      # cursor_blink_interval = -1;
      cursor_blink_interval = 0;

      #: The interval (in seconds) at which to blink the cursor. Set to zero
      #: to disable blinking. Negative values mean use system default. Note
      #: that numbers smaller than repaint_delay will be limited to
      #: repaint_delay.

      # cursor_stop_blinking_after = 15.0;

      #: Stop blinking cursor after the specified number of seconds of
      #: keyboard inactivity.  Set to zero to never stop blinking.

      # SCROLLBACK
      #-------------------------------------------------

      # use scrollback_pager_history_size instead for long scrollback
      scrollback_lines = 100000;

      #: Number of lines of history to keep in memory for scrolling back.
      #: Memory is allocated on demand. Negative numbers are (effectively)
      #: infinite scrollback. Note that using very large scrollback is not
      #: recommended as it can slow down performance of the terminal and
      #: also use large amounts of RAM. Instead, consider using
      #: scrollback_pager_history_size. Note that on config reload if this
      #: is changed it will only affect newly created windows, not existing
      #: ones.

      # scrollback_pager = "less --chop-long-lines --RAW-CONTROL-CHARS +INPUT_LINE_NUMBER"

      #: Program with which to view scrollback in a new window. The
      #: scrollback buffer is passed as STDIN to this program. If you change
      #: it, make sure the program you use can handle ANSI escape sequences
      #: for colors and text formatting. INPUT_LINE_NUMBER in the command
      #: line above will be replaced by an integer representing which line
      #: should be at the top of the screen. Similarly CURSOR_LINE and
      #: CURSOR_COLUMN will be replaced by the current cursor position.

      # scrollback_pager_history_size = 0;
      scrollback_pager_history_size = 4000;

      #: Separate scrollback history size, used only for browsing the
      #: scrollback buffer (in MB). This separate buffer is not available
      #: for interactive scrolling but will be piped to the pager program
      #: when viewing scrollback buffer in a separate window. The current
      #: implementation stores the data in UTF-8, so approximatively 10000
      #: lines per megabyte at 100 chars per line, for pure ASCII text,
      #: unformatted text. A value of zero or less disables this feature.
      #: The maximum allowed size is 4GB. Note that on config reload if this
      #: is changed it will only affect newly created windows, not existing
      #: ones.

      # scrollback_fill_enlarged_window = false;
      scrollback_fill_enlarged_window = true;

      #: Fill new space with lines from the scrollback buffer after
      #: enlarging a window.

      # wheel_scroll_multiplier = 5.0;

      #: Modify the amount scrolled by the mouse wheel. Note this is only
      #: used for low precision scrolling devices, not for high precision
      #: scrolling on platforms such as macOS and Wayland. Use negative
      #: numbers to change scroll direction.

      # touch_scroll_multiplier = 1.0;

      #: Modify the amount scrolled by a touchpad. Note this is only used
      #: for high precision scrolling devices on platforms such as macOS and
      #: Wayland. Use negative numbers to change scroll direction.

      # MOUSE
      #-------------------------------------------------
      # mouse_hide_wait = 3.0;
      mouse_hide_wait = -1;

      #: Hide mouse cursor after the specified number of seconds of the
      #: mouse not being used. Set to zero to disable mouse cursor hiding.
      #: Set to a negative value to hide the mouse cursor immediately when
      #: typing text. Disabled by default on macOS as getting it to work
      #: robustly with the ever-changing sea of bugs that is Cocoa is too
      #: much effort.

      # url_color = "#0087bd";
      # url_style = "curly";

      #: The color and style for highlighting URLs on mouse-over. url_style
      #: can be one of: none, single, double, curly

      # open_url_with = "default"

      #: The program with which to open URLs that are clicked on. The
      #: special value default means to use the operating system's default
      #: URL handler.

      # url_prefixes = "http https file ftp gemini irc gopher mailto news git";

      #: The set of URL prefixes to look for when detecting a URL under the
      #: mouse cursor.

      # detect_urls = true;

      #: Detect URLs under the mouse. Detected URLs are highlighted with an
      #: underline and the mouse cursor becomes a hand over them. Even if
      #: this option is disabled, URLs are still clickable.

      # url_excluded_characters = "";

      #: Additional characters to be disallowed from URLs, when detecting
      #: URLs under the mouse cursor. By default, all characters legal in
      #: URLs are allowed.

      # copy_on_select = false;
      copy_on_select = true;

      #: Copy to clipboard or a private buffer on select. With this set to
      #: clipboard, simply selecting text with the mouse will cause the text
      #: to be copied to clipboard. Useful on platforms such as macOS that
      #: do not have the concept of primary selections. You can instead
      #: specify a name such as a1 to copy to a private kitty buffer
      #: instead. Map a shortcut with the paste_from_buffer action to paste
      #: from this private buffer. For example::

      #:     map cmd+shift+v paste_from_buffer a1

      #: Note that copying to the clipboard is a security risk, as all
      #: programs, including websites open in your browser can read the
      #: contents of the system clipboard.

      # strip_trailing_spaces = "never";
      strip_trailing_spaces = "smart";

      #: Remove spaces at the end of lines when copying to clipboard. A
      #: value of smart will do it when using normal selections, but not
      #: rectangle selections. always will always do it.

      # select_by_word_characters = "@-./_~?&=%+#";

      #: Characters considered part of a word when double clicking. In
      #: addition to these characters any character that is marked as an
      #: alphanumeric character in the unicode database will be matched.

      # click_interval = -1.0;

      #: The interval between successive clicks to detect double/triple
      #: clicks (in seconds). Negative numbers will use the system default
      #: instead, if available, or fallback to 0.5.

      # focus_follows_mouse = false;

      #: Set the active window to the window under the mouse when moving the
      #: mouse around

      # pointer_shape_when_grabbed = "arrow";

      #: The shape of the mouse pointer when the program running in the
      #: terminal grabs the mouse. Valid values are: arrow, beam and hand

      # default_pointer_shape = "beam";

      #: The default shape of the mouse pointer. Valid values are: arrow,
      #: beam and hand

      # pointer_shape_when_dragging = "beam";

      #: The default shape of the mouse pointer when dragging across text.
      #: Valid values are: arrow, beam and hand

      # MOUSE ACTIONS
      #-------------------------------------------------
      #: Mouse buttons can be remapped to perform arbitrary actions. The
      #: syntax for doing so is:

      #: .. code-block:: none

      #:     mouse_map button-name event-type modes action

      #: Where ``button-name`` is one of ``left``, ``middle``, ``right`` or
      #: ``b1 ... b8`` with added keyboard modifiers, for example:
      #: ``ctrl+shift+left`` refers to holding the ctrl+shift keys while
      #: clicking with the left mouse button. The number ``b1 ... b8`` can
      #: be used to refer to upto eight buttons on a mouse.

      #: ``event-type`` is one ``press``, ``release``, ``doublepress``,
      #: ``triplepress``, ``click`` and ``doubleclick``.  ``modes``
      #: indicates whether the action is performed when the mouse is grabbed
      #: by the program running in the terminal, or not. It can have one or
      #: more or the values, ``grabbed,ungrabbed``. ``grabbed`` refers to
      #: when the program running in the terminal has requested mouse
      #: events. Note that the click and double click events have a delay of
      #: click_interval to disambiguate from double and triple presses.

      #: You can run kitty with the kitty --debug-input command line option
      #: to see mouse events. See the builtin actions below to get a sense
      #: of what is possible.

      #: If you want to unmap an action map it to ``no-op``. For example, to
      #: disable opening of URLs with a plain click::

      #:     mouse_map left click ungrabbed no-op

      #: .. note::
      #:     Once a selection is started, releasing the button that started it will
      #:     automatically end it and no release event will be dispatched.

      # mouse_map left            click ungrabbed mouse_click_url_or_select
      # mouse_map shift+left      click grabbed,ungrabbed mouse_click_url_or_select
      # mouse_map ctrl+shift+left release grabbed,ungrabbed mouse_click_url

      #: Variant with ctrl+shift is present because the simple click based
      #: version has an unavoidable delay of click_interval, to disambiguate
      #: clicks from double clicks.

      # mouse_map ctrl+shift+left press grabbed discard_event

      #: Prevent this press event from being sent to the program that has
      #: grabbed the mouse, as the corresponding release event is used to
      #: open a URL.

      # mouse_map middle        release ungrabbed paste_from_selection
      # mouse_map left          press ungrabbed mouse_selection normal
      # mouse_map ctrl+alt+left press ungrabbed mouse_selection rectangle
      # mouse_map left          doublepress ungrabbed mouse_selection word
      # mouse_map left          triplepress ungrabbed mouse_selection line

      #: Select the entire line

      # mouse_map ctrl+alt+left triplepress ungrabbed mouse_selection line_from_point

      #: Select from the clicked point to the end of the line

      # mouse_map right               press ungrabbed mouse_selection extend
      # mouse_map shift+middle        release ungrabbed,grabbed paste_selection
      # mouse_map shift+left          press ungrabbed,grabbed mouse_selection normal
      # mouse_map shift+ctrl+alt+left press ungrabbed,grabbed mouse_selection rectangle
      # mouse_map shift+left          doublepress ungrabbed,grabbed mouse_selection word
      # mouse_map shift+left          triplepress ungrabbed,grabbed mouse_selection line

      #: Select the entire line

      # mouse_map shift+ctrl+alt+left triplepress ungrabbed,grabbed mouse_selection line_from_point

      #: Select from the clicked point to the end of the line

      # mouse_map shift+right press ungrabbed,grabbed mouse_selection extend

      # PERFORMANCE TUNING
      #----------------------------------------------
      # repaint_delay = 10;

      #: Delay (in milliseconds) between screen updates. Decreasing it,
      #: increases frames-per-second (FPS) at the cost of more CPU usage.
      #: The default value yields ~100 FPS which is more than sufficient for
      #: most uses. Note that to actually achieve 100 FPS you have to either
      #: set sync_to_monitor to no or use a monitor with a high refresh
      #: rate. Also, to minimize latency when there is pending input to be
      #: processed, repaint_delay is ignored.

      # input_delay = 3;

      #: Delay (in milliseconds) before input from the program running in
      #: the terminal is processed. Note that decreasing it will increase
      #: responsiveness, but also increase CPU usage and might cause flicker
      #: in full screen programs that redraw the entire screen on each loop,
      #: because kitty is so fast that partial screen updates will be drawn.

      # sync_to_monitor = true;

      #: Sync screen updates to the refresh rate of the monitor. This
      #: prevents tearing (https://en.wikipedia.org/wiki/Screen_tearing)
      #: when scrolling. However, it limits the rendering speed to the
      #: refresh rate of your monitor. With a very high speed mouse/high
      #: keyboard repeat rate, you may notice some slight input latency. If
      #: so, set this to no.

      # TERMINAL BELL
      #-------------------------------------------------
      # enable_audio_bell = true;
      enable_audio_bell = false;

      #: Enable/disable the audio bell. Useful in environments that require
      #: silence.

      # visual_bell_duration = 0.0;

      #: Visual bell duration. Flash the screen when a bell occurs for the
      #: specified number of seconds. Set to zero to disable.

      # window_alert_on_bell = true;

      #: Request window attention on bell. Makes the dock icon bounce on
      #: macOS or the taskbar flash on linux.

      # bell_on_tab = true;

      #: Show a bell symbol on the tab if a bell occurs in one of the
      #: windows in the tab and the window is not the currently focused
      #: window

      # command_on_bell = "none";

      #: Program to run when a bell occurs.

      # WINDOW LAYOUT
      #-------------------------------------------------
      # remember_window_size = true;
      # initial_window_width = 640;
      # initial_window_height = 400;

      #: If enabled, the window size will be remembered so that new
      #: instances of kitty will have the same size as the previous
      #: instance. If disabled, the window will initially have size
      #: configured by initial_window_width/height, in pixels. You can use a
      #: suffix of "c" on the width/height values to have them interpreted
      #: as number of cells instead of pixels.

      # enabled_layouts = "*";

      #: The enabled window layouts. A comma separated list of layout names.
      #: The special value all means all layouts. The first listed layout
      #: will be used as the startup layout. Default configuration is all
      #: layouts in alphabetical order. For a list of available layouts, see
      #: the https://sw.kovidgoyal.net/kitty/index.html#layouts.

      # window_resize_step_cells = 2;
      # window_resize_step_lines = 2;

      #: The step size (in units of cell width/cell height) to use when
      #: resizing windows. The cells value is used for horizontal resizing
      #: and the lines value for vertical resizing.

      # window_border_width = "0.5pt";

      #: The width of window borders. Can be either in pixels (px) or pts
      #: (pt). Values in pts will be rounded to the nearest number of pixels
      #: based on screen resolution. If not specified the unit is assumed to
      #: be pts. Note that borders are displayed only when more than one
      #: window is visible. They are meant to separate multiple windows.

      # draw_minimal_borders = true;

      #: Draw only the minimum borders needed. This means that only the
      #: minimum needed borders for inactive windows are drawn. That is only
      #: the borders that separate the inactive window from a neighbor. Note
      #: that setting a non-zero window margin overrides this and causes all
      #: borders to be drawn.

      # window_margin_width = "0";

      #: The window margin (in pts) (blank area outside the border). A
      #: single value sets all four sides. Two values set the vertical and
      #: horizontal sides. Three values set top, horizontal and bottom. Four
      #: values set top, right, bottom and left.

      # single_window_margin_width = "-1";

      #: The window margin (in pts) to use when only a single window is
      #: visible. Negative values will cause the value of
      #: window_margin_width to be used instead. A single value sets all
      #: four sides. Two values set the vertical and horizontal sides. Three
      #: values set top, horizontal and bottom. Four values set top, right,
      #: bottom and left.

      # window_padding_width = "0";

      #: The window padding (in pts) (blank area between the text and the
      #: window border). A single value sets all four sides. Two values set
      #: the vertical and horizontal sides. Three values set top, horizontal
      #: and bottom. Four values set top, right, bottom and left.

      # placement_strategy = "center"

      #: When the window size is not an exact multiple of the cell size, the
      #: cell area of the terminal window will have some extra padding on
      #: the sides. You can control how that padding is distributed with
      #: this option. Using a value of center means the cell area will be
      #: placed centrally. A value of top-left means the padding will be on
      #: only the bottom and right edges.

      # active_border_color = "#00ff00";

      #: The color for the border of the active window. Set this to none to
      #: not draw borders around the active window.

      # inactive_border_color = "#cccccc";

      #: The color for the border of inactive windows

      # bell_border_color = "#ff5a00";

      #: The color for the border of inactive windows in which a bell has
      #: occurred

      # inactive_text_alpha = 1.0;

      #: Fade the text in inactive windows by the specified amount (a number
      #: between zero and one, with zero being fully faded).

      # hide_window_decorations = false;

      #: Hide the window decorations (title-bar and window borders) with
      #: yes. On macOS, titlebar-only can be used to only hide the titlebar.
      #: Whether this works and exactly what effect it has depends on the
      #: window manager/operating system. Note that the effects of changing
      #: this setting when reloading config are undefined.

      # resize_debounce_time = 0.1;

      #: The time (in seconds) to wait before redrawing the screen when a
      #: resize event is received. On platforms such as macOS, where the
      #: operating system sends events corresponding to the start and end of
      #: a resize, this number is ignored.

      # resize_draw_strategy = "static";

      #: Choose how kitty draws a window while a resize is in progress. A
      #: value of static means draw the current window contents, mostly
      #: unchanged. A value of scale means draw the current window contents
      #: scaled. A value of blank means draw a blank window. A value of size
      #: means show the window size in cells.

      # resize_in_steps = false;

      #: Resize the OS window in steps as large as the cells, instead of
      #: with the usual pixel accuracy. Combined with an
      #: initial_window_width and initial_window_height in number of cells,
      #: this option can be used to keep the margins as small as possible
      #: when resizing the OS window. Note that this does not currently work
      #: on Wayland.

      # confirm_os_window_close = 0;

      #: Ask for confirmation when closing an OS window or a tab that has at
      #: least this number of kitty windows in it. A value of zero disables
      #: confirmation. This confirmation also applies to requests to quit
      #: the entire application (all OS windows, via the quit action).

      # TAB BAR
      #-------------------------------------------------
      # tab_bar_edge = "bottom";

      #: Which edge to show the tab bar on, top or bottom

      # tab_bar_margin_width = 0.0;

      #: The margin to the left and right of the tab bar (in pts)

      # tab_bar_margin_height = "0.0 0.0";

      #: The margin above and below the tab bar (in pts). The first number
      #: is the margin between the edge of the OS Window and the tab bar and
      #: the second number is the margin between the tab bar and the
      #: contents of the current tab.

      # tab_bar_style = "fade";

      #: The tab bar style, can be one of: fade, separator, powerline, or
      #: hidden. In the fade style, each tab's edges fade into the
      #: background color, in the separator style, tabs are separated by a
      #: configurable separator, and the powerline shows the tabs as a
      #: continuous line. If you use the hidden style, you might want to
      #: create a mapping for the select_tab action which presents you with
      #: a list of tabs and allows for easy switching to a tab.

      # tab_bar_min_tabs = 2;

      #: The minimum number of tabs that must exist before the tab bar is
      #: shown

      # tab_switch_strategy = "previous";

      #: The algorithm to use when switching to a tab when the current tab
      #: is closed. The default of previous will switch to the last used
      #: tab. A value of left will switch to the tab to the left of the
      #: closed tab. A value of right will switch to the tab to the right of
      #: the closed tab. A value of last will switch to the right-most tab.

      # tab_fade = "0.25 0.5 0.75 1";

      #: Control how each tab fades into the background when using fade for
      #: the tab_bar_style. Each number is an alpha (between zero and one)
      #: that controls how much the corresponding cell fades into the
      #: background, with zero being no fade and one being full fade. You
      #: can change the number of cells used by adding/removing entries to
      #: this list.

      # tab_separator = " ┇";

      #: The separator between tabs in the tab bar when using separator as
      #: the tab_bar_style.

      # tab_powerline_style = "angled";

      #: The powerline separator style between tabs in the tab bar when
      #: using powerline as the tab_bar_style, can be one of: angled,
      #: slanted, or round.

      # tab_activity_symbol = "none";

      #: Some text or a unicode symbol to show on the tab if a window in the
      #: tab that does not have focus has some activity.

      # tab_title_template = "{title}";
      tab_title_template = "{sup.index}: {title}";

      #: A template to render the tab title. The default just renders the
      #: title. If you wish to include the tab-index as well, use something
      #: like: {index}: {title}. Useful if you have shortcuts mapped for
      #: goto_tab N. If you prefer to see the index as a superscript, use
      #: {sup.index}. In addition you can use {layout_name} for the current
      #: layout name and {num_windows} for the number of windows in the tab.
      #: Note that formatting is done by Python's string formatting
      #: machinery, so you can use, for instance, {layout_name[:2].upper()}
      #: to show only the first two letters of the layout name, upper-cased.
      #: If you want to style the text, you can use styling directives, for
      #: example: {fmt.fg.red}red{fmt.fg.default}normal{fmt.bg._00FF00}green
      #: bg{fmt.bg.normal}. Similarly, for bold and italic:
      #: {fmt.bold}bold{fmt.nobold}normal{fmt.italic}italic{fmt.noitalic}.

      # active_tab_title_template = "none";

      #: Template to use for active tabs, if not specified falls back to
      #: tab_title_template.

      # active_tab_foreground   = "#000";
      # active_tab_background   = "#eee";
      # active_tab_font_style   = "bold-italic";
      # inactive_tab_foreground = "#444";
      # inactive_tab_background = "#999";
      # inactive_tab_font_style = "normal";

      #: Tab bar colors and styles

      # tab_bar_background = "none";

      #: Background color for the tab bar. Defaults to using the terminal
      #: background color.

      # COLORS
      #-------------------------------------------------
      # WARNING: See theme option for most of these

      # foreground = "#dddddd";
      # background = "#000000";

      #: The foreground and background colors

      # background_opacity = 1.0;

      #: The opacity of the background. A number between 0 and 1, where 1 is
      #: opaque and 0 is fully transparent.  This will only work if
      #: supported by the OS (for instance, when using a compositor under
      #: X11). Note that it only sets the background color's opacity in
      #: cells that have the same background color as the default terminal
      #: background. This is so that things like the status bar in vim,
      #: powerline prompts, etc. still look good.  But it means that if you
      #: use a color theme with a background color in your editor, it will
      #: not be rendered as transparent.  Instead you should change the
      #: default background color in your kitty config and not use a
      #: background color in the editor color scheme. Or use the escape
      #: codes to set the terminals default colors in a shell script to
      #: launch your editor.  Be aware that using a value less than 1.0 is a
      #: (possibly significant) performance hit.  If you want to dynamically
      #: change transparency of windows set dynamic_background_opacity to
      #: yes (this is off by default as it has a performance cost). Changing
      #: this setting when reloading the config will only work if
      #: dynamic_background_opacity was enabled in the original config.

      # background_image = "none";

      #: Path to a background image. Must be in PNG format.

      # background_image_layout = "tiled";

      #: Whether to tile or scale the background image.

      # background_image_linear = false;

      #: When background image is scaled, whether linear interpolation
      #: should be used.

      # dynamic_background_opacity = false;

      #: Allow changing of the background_opacity dynamically, using either
      #: keyboard shortcuts (increase_background_opacity and
      #: decrease_background_opacity) or the remote control facility.
      #: Changing this setting by reloading the config is not supported.

      # background_tint = 0.0;

      #: How much to tint the background image by the background color. The
      #: tint is applied only under the text area, not margin/borders. Makes
      #: it easier to read the text. Tinting is done using the current
      #: background color for each window. This setting applies only if
      #: background_opacity is set and transparent windows are supported or
      #: background_image is set.

      # dim_opacity = 0.75;

      #: How much to dim text that has the DIM/FAINT attribute set. One
      #: means no dimming and zero means fully dimmed (i.e. invisible).

      # selection_foreground = "#000000";

      #: The foreground for text selected with the mouse. A value of none
      #: means to leave the color unchanged.

      # selection_background = "#fffacd";

      #: The background for text selected with the mouse.

        # COLOR TABLE
        #-------------------------------------------------
        #: The 256 terminal colors. There are 8 basic colors, each color has a
        #: dull and bright version, for the first 16 colors. You can set the
        #: remaining 240 colors as color16 to color255.

        # color0 = "#000000";
        # color8 = "#767676";

        #: black

        # color1 = "#cc0403";
        # color9 = "#f2201f";

        #: red

        # color2  = "#19cb00";
        # color10 = "#23fd00";

        #: green

        # color3  = "#cecb00";
        # color11 = "#fffd00";

        #: yellow

        # color4  = "#0d73cc";
        # color12 = "#1a8fff";

        #: blue

        # color5  = "#cb1ed1";
        # color13 = "#fd28ff";

        #: magenta

        # color6  = "#0dcdcd";
        # color14 = "#14ffff";

        #: cyan

        # color7  = "#dddddd";
        # color15 = "#ffffff";

        #: white

        # mark1_foreground = "black";

        #: Color for marks of type 1

        # mark1_background = "#98d3cb";

        #: Color for marks of type 1 (light steel blue)

        # mark2_foreground = "black";

        #: Color for marks of type 2

        # mark2_background = "#f2dcd3";

        #: Color for marks of type 1 (beige)

        # mark3_foreground = "black";

        #: Color for marks of type 3

        # mark3_background = "#f274bc";

        #: Color for marks of type 3 (violet)

      # ADVANCED
      #-------------------------------------------------
      # shell = ".";

      #: The shell program to execute. The default value of . means to use
      #: whatever shell is set as the default shell for the current user.
      #: Note that on macOS if you change this, you might need to add
      #: --login to ensure that the shell starts in interactive mode and
      #: reads its startup rc files.

      # editor = ".";

      #: The console editor to use when editing the kitty config file or
      #: similar tasks. A value of . means to use the environment variables
      #: VISUAL and EDITOR in that order. Note that this environment
      #: variable has to be set not just in your shell startup scripts but
      #: system-wide, otherwise kitty will not see it.

      # close_on_child_death = false;

      #: Close the window when the child process (shell) exits. If no (the
      #: default), the terminal will remain open when the child exits as
      #: long as there are still processes outputting to the terminal (for
      #: example disowned or backgrounded processes). If yes, the window
      #: will close as soon as the child process exits. Note that setting it
      #: to yes means that any background processes still using the terminal
      #: can fail silently because their stdout/stderr/stdin no longer work.

      # allow_remote_control = "no";

      #: Allow other programs to control kitty. If you turn this on other
      #: programs can control all aspects of kitty, including sending text
      #: to kitty windows, opening new windows, closing windows, reading the
      #: content of windows, etc.  Note that this even works over ssh
      #: connections. You can chose to either allow any program running
      #: within kitty to control it, with yes or only programs that connect
      #: to the socket specified with the kitty --listen-on command line
      #: option, if you use the value socket-only. The latter is useful if
      #: you want to prevent programs running on a remote computer over ssh
      #: from controlling kitty. Changing this option by reloading the
      #: config will only affect newly created windows.

      # listen_on = "none";

      #: Tell kitty to listen to the specified unix/tcp socket for remote
      #: control connections. Note that this will apply to all kitty
      #: instances. It can be overridden by the kitty --listen-on command
      #: line flag. This option accepts only UNIX sockets, such as
      #: unix:${TEMP}/mykitty or (on Linux) unix:@mykitty. Environment
      #: variables are expanded. If {kitty_pid} is present then it is
      #: replaced by the PID of the kitty process, otherwise the PID of the
      #: kitty process is appended to the value, with a hyphen. This option
      #: is ignored unless you also set allow_remote_control to enable
      #: remote control. See the help for kitty --listen-on for more
      #: details. Changing this option by reloading the config is not
      #: supported.

      # See environment = {} instead;
      ## env = "";
      #
      ##: Specify environment variables to set in all child processes. Note
      ##: that environment variables are expanded recursively, so if you
      ##: use::
      #
      ##:     env MYVAR1=a
      ##:     env MYVAR2=${MYVAR1}/${HOME}/b
      #
      ##: The value of MYVAR2 will be a/<path to home directory>/b.

      # update_check_interval = 24;

      #: Periodically check if an update to kitty is available. If an update
      #: is found a system notification is displayed informing you of the
      #: available update. The default is to check every 24 hrs, set to zero
      #: to disable. Changing this option by reloading the config is not
      #: supported.

      # startup_session = "none";

      #: Path to a session file to use for all kitty instances. Can be
      #: overridden by using the kitty --session command line option for
      #: individual instances. See
      #: https://sw.kovidgoyal.net/kitty/index.html#sessions in the kitty
      #: documentation for details. Note that relative paths are interpreted
      #: with respect to the kitty config directory. Environment variables
      #: in the path are expanded. Changing this option by reloading the
      #: config is not supported.

      # clipboard_control = "write-clipboard write-primary";

      #: Allow programs running in kitty to read and write from the
      #: clipboard. You can control exactly which actions are allowed. The
      #: set of possible actions is: write-clipboard read-clipboard write-
      #: primary read-primary. You can additionally specify no-append to
      #: disable kitty's protocol extension for clipboard concatenation. The
      #: default is to allow writing to the clipboard and primary selection
      #: with concatenation enabled. Note that enabling the read
      #: functionality is a security risk as it means that any program, even
      #: one running on a remote server via SSH can read your clipboard.

      # allow_hyperlinks = true;

      #: Process hyperlink (OSC 8) escape sequences. If disabled OSC 8
      #: escape sequences are ignored. Otherwise they become clickable
      #: links, that you can click by holding down ctrl+shift and clicking
      #: with the mouse. The special value of ``ask`` means that kitty will
      #: ask before opening the link.

      # term = "xterm-kitty";

      #: The value of the TERM environment variable to set. Changing this
      #: can break many terminal programs, only change it if you know what
      #: you are doing, not because you read some advice on Stack Overflow
      #: to change it. The TERM variable is used by various programs to get
      #: information about the capabilities and behavior of the terminal. If
      #: you change it, depending on what programs you run, and how
      #: different the terminal you are changing it to is, various things
      #: from key-presses, to colors, to various advanced features may not
      #: work. Changing this option by reloading the config will only affect
      #: newly created windows.

      # OS SPECIFIC TWEAKS
      #-------------------------------------------------
      # wayland_titlebar_color = "system";

      #: Change the color of the kitty window's titlebar on Wayland systems
      #: with client side window decorations such as GNOME. A value of
      #: system means to use the default system color, a value of background
      #: means to use the background color of the currently active window
      #: and finally you can use an arbitrary color, such as #12af59 or red.

      # macos_titlebar_color = "system";

      #: Change the color of the kitty window's titlebar on macOS. A value
      #: of system means to use the default system color, a value of
      #: background means to use the background color of the currently
      #: active window and finally you can use an arbitrary color, such as
      #: #12af59 or red. WARNING: This option works by using a hack, as
      #: there is no proper Cocoa API for it. It sets the background color
      #: of the entire window and makes the titlebar transparent. As such it
      #: is incompatible with background_opacity. If you want to use both,
      #: you are probably better off just hiding the titlebar with
      #: hide_window_decorations.

      # macos_option_as_alt = false;

      #: Use the option key as an alt key. With this set to no, kitty will
      #: use the macOS native Option+Key = unicode character behavior. This
      #: will break any Alt+key keyboard shortcuts in your terminal
      #: programs, but you can use the macOS unicode input technique. You
      #: can use the values: left, right, or both to use only the left,
      #: right or both Option keys as Alt, instead. Changing this setting by
      #: reloading the config is not supported.

      # macos_hide_from_tasks = false;

      #: Hide the kitty window from running tasks (⌘+Tab) on macOS. Changing
      #: this setting by reloading the config is not supported.

      # macos_quit_when_last_window_closed = false;

      #: Have kitty quit when all the top-level windows are closed. By
      #: default, kitty will stay running, even with no open windows, as is
      #: the expected behavior on macOS.

      # macos_window_resizable = true;

      #: Disable this if you want kitty top-level (OS) windows to not be
      #: resizable on macOS. Changing this setting by reloading the config
      #: will only affect newly created windows.

      # macos_thicken_font = 0;

      #: Draw an extra border around the font with the given width, to
      #: increase legibility at small font sizes. For example, a value of
      #: 0.75 will result in rendering that looks similar to sub-pixel
      #: antialiasing at common font sizes.

      # macos_traditional_fullscreen = false;

      #: Use the traditional full-screen transition, that is faster, but
      #: less pretty.

      # macos_show_window_title_in = "all";

      #: Show or hide the window title in the macOS window or menu-bar. A
      #: value of window will show the title of the currently active window
      #: at the top of the macOS window. A value of menubar will show the
      #: title of the currently active window in the macOS menu-bar, making
      #: use of otherwise wasted space. all will show the title everywhere
      #: and none hides the title in the window and the menu-bar.

      # macos_custom_beam_cursor = false;

      #: Enable/disable custom mouse cursor for macOS that is easier to see
      #: on both light and dark backgrounds. WARNING: this might make your
      #: mouse cursor invisible on dual GPU machines. Changing this setting
      #: by reloading the config is not supported.

      # linux_display_server = "auto";

      #: Choose between Wayland and X11 backends. By default, an appropriate
      #: backend based on the system state is chosen automatically. Set it
      #: to x11 or wayland to force the choice. Changing this setting by
      #: reloading the config is not supported.
    };

    # See theme options with 'kitty +kitten themes'
    #theme = ;
  };
}

# vim: sw=2:expandtab