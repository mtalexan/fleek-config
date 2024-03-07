{ pkgs, misc, lib, config, options, ... }: {
  # A terminal multiplexer with lots of features, but also high speed.
  # WARNING: Kitty must be manually installed instead, following the directions here: https://sw.kovidgoyal.net/kitty/binary/#binary-install
  #          An sd command is provided to ease this 'sd install kitty'

  # add the *.desktop files only if explicitly enabled. All new installs require it to be disabled initially, then
  # enabled only after kitty is installed
  options.custom.kitty = with lib; {
    desktop_files = mkEnableOption(mdDoc "kitty terminal emulator *.desktop file installation");
  };

  config = {
    # install the desktop files
    home.file = {
      # The recommended way to do this is to copy the files from the kitty install folder into the desktop folder,
      # then do sed replacements.  We do the equivalent by reading the text of the files from our nix install location,
      # then doing string replacement and specifying it as raw text for a new file.

      ".local/share/applications/kitty.desktop" = {
        enable = config.custom.kitty.desktop_files;
        executable = false;
        # take the file from the nix kitty install and replace the Icon, Exec, and TryExec portions of the lines saying where to find kitty
        text = (builtins.replaceStrings
                  ["Icon=kitty" "Exec=kitty"]
                  ["Icon=${pkgs.kitty}/share/icons/hicolor/256x256/apps/kitty.png" "Exec=${pkgs.kitty}/bin/kitty"]
                  (builtins.readFile "${pkgs.kitty}/share/applications/kitty.desktop"));
      };

      ".local/share/applications/kitty-open.desktop" = {
        enable = config.custom.kitty.desktop_files;
        executable = false;
        # take the file from the nix kitty install and replace the Icon, Exec, and TryExec portions of the lines saying where to find kitty
        text = (builtins.replaceStrings
                  ["Icon=kitty" "Exec=kitty"]
                  ["Icon=${pkgs.kitty}/share/icons/hicolor/256x256/apps/kitty.png" "Exec=${pkgs.kitty}/bin/kitty"]
                  (builtins.readFile "${pkgs.kitty}/share/applications/kitty-open.desktop"));
      };
    };

    # manual kitty integration into the shell is required since automatic injection doesn't work for subshells, multiplexers, etc
    # See https://sw.kovidgoyal.net/kitty/shell-integration/#manual-shell-integration
    programs.zsh = {
      #initExtra = ''
      #  if test -n "$KITTY_INSTALLATION_DIR"; then
      #      export KITTY_SHELL_INTEGRATION="enabled"
      #      autoload -Uz -- "$KITTY_INSTALLATION_DIR"/shell-integration/zsh/kitty-integration
      #      kitty-integration
      #      unfunction kitty-integration
      #  fi
      #'';
      # Assume we will be using kitty as the primary terminal, so alias ssh
      shellAliases = {
        # trailing space to allow for tab completion. Explicitly enable shell integration with the target.
        "sshk" = "kitty +kitten ssh --kitten shell_integration=no-rc ";
      };
    };
    programs.bash = {
      #initExtra = ''
      #  if test -n "$KITTY_INSTALLATION_DIR"; then
      #      export KITTY_SHELL_INTEGRATION="enabled"
      #      source "$KITTY_INSTALLATION_DIR/shell-integration/bash/kitty.bash"
      #  fi
      #'';
      # Assume we will be using kitty as the primary terminal, so alias ssh
      shellAliases = {
        # trailing space to allow for tab completion. Explicitly enable shell integration with the target.
        "sshk" = "kitty +kitten ssh --kitten shell_integration=no-rc ";
      };
    };

    programs.kitty = {
      # we can't use the nix installation, but we also can't use our config without installing it.
      # Luckily the default installation location of ~/.local/bin has higher priority than .nix-profile or the home-manager
      # installation location, so manual installation will work.
      enable = true;
      shellIntegration = {
        # don't set mode=, none of the kitty built-in integration works with subshells and the like, so we have to disable the automatically
        # injected kitty integration (set by mode=).  Instead we use the enable{Bash,Zsh}Integration options that add only the necessary
        # content to the rc files for loading, which only affects when loading on the host.
        enableBashIntegration = true;
        enableZshIntegration = true;
      };

      #font = {
      #  # package to install in the nix profile to ensure the font is available.  Set to 'null' (default) if it's guaranteed to be there already.
      #  package = pkgs.nerdfonts;
      #  name = ???;
      #  size = ???;
      #};

      # See theme options with 'kitty +kitten themes'.
      # These change the color name definitions, so using 'red' or 'bright-green' have different meanings.
      #theme = "Glacier";
      theme = "Gruvbox Material Dark Hard";
      #theme = "Neowave";
      #theme = "Nightfox";
      #theme = "Relaxed Afterglow";
      #theme = "Renault Style";
      #theme = "Space Gray Eighties";
      #theme = "Space Gray Eighties Dull";
      #theme = "Warm Neon";

      # while it's possible to set keybindings, environment, and settings as Nix structures, the translation into the output file
      # can reorder (environment and keybindings), and isn't always a direct 1-to-1 (keybindings, settings).
      # The theme, shellIntegration.mode, and font however have other uses that make them useful still however.
      # So use extraConfig to directly set most of the .conf file to avoid all the translation issues.

      extraConfig = lib.concatLines [
        # from default kitty.conf that includes all keybindings and default settings: https://sw.kovidgoyal.net/kitty/conf/#sample-kitty-conf

        # vim comment moved to bottom since this doesn't appear at the top of the file, and vim requires the special mode settings
        # at either top or bottom of file

        # FONTS
        # mostly should be configured via nix fonts={} above
        ''
          #: Fonts {{{

          #: kitty has very powerful font management. You can configure
          #: individual font faces and even specify special fonts for particular
          #: characters.

          # font_family      monospace
          # bold_font        auto
          # italic_font      auto
          # bold_italic_font auto

          #: You can specify different fonts for the bold/italic/bold-italic
          #: variants. To get a full list of supported fonts use the `kitty
          #: +list-fonts` command. By default they are derived automatically, by
          #: the OSes font system. When bold_font or bold_italic_font is set to
          #: auto on macOS, the priority of bold fonts is semi-bold, bold,
          #: heavy. Setting them manually is useful for font families that have
          #: many weight variants like Book, Medium, Thick, etc. For example::

          #:     font_family      Operator Mono Book
          #:     bold_font        Operator Mono Medium
          #:     italic_font      Operator Mono Book Italic
          #:     bold_italic_font Operator Mono Medium Italic

          # font_size 11.0

          #: Font size (in pts)

          # force_ltr no

          #: kitty does not support BIDI (bidirectional text), however, for RTL
          #: scripts, words are automatically displayed in RTL. That is to say,
          #: order, however, if you wish to manipulate RTL glyphs, it can be
          #: in an RTL script, the words "HELLO WORLD" display in kitty as
          #: "WORLD HELLO", and if you try to select a substring of an RTL-
          #: shaped string, you will get the character that would be there had
          #: the string been LTR. For example, assuming the Hebrew word ירושלים,
          #: selecting the character that on the screen appears to be ם actually
          #: writes into the selection buffer the character י. kitty's default
          #: behavior is useful in conjunction with a filter to reverse the word
          #: very challenging to work with, so this option is provided to turn
          #: it off. Furthermore, this option can be used with the command line
          #: program GNU FriBidi <https://github.com/fribidi/fribidi#executable>
          #: to get BIDI support, because it will force kitty to always treat
          #: the text as LTR, which FriBidi expects for terminals.

          # symbol_map

          #: E.g. symbol_map U+E0A0-U+E0A3,U+E0C0-U+E0C7 PowerlineSymbols

          #: Map the specified Unicode codepoints to a particular font. Useful
          #: if you need special rendering for some symbols, such as for
          #: Powerline. Avoids the need for patched fonts. Each Unicode code
          #: point is specified in the form `U+<code point in hexadecimal>`. You
          #: can specify multiple code points, separated by commas and ranges
          #: separated by hyphens. This option can be specified multiple times.
          #: The syntax is::

          #:     symbol_map codepoints Font Family Name

          # narrow_symbols

          #: E.g. narrow_symbols U+E0A0-U+E0A3,U+E0C0-U+E0C7 1

          #: Usually, for Private Use Unicode characters and some symbol/dingbat
          #: characters, if the character is followed by one or more spaces,
          #: kitty will use those extra cells to render the character larger, if
          #: the character in the font has a wide aspect ratio. Using this
          #: option you can force kitty to restrict the specified code points to
          #: render in the specified number of cells (defaulting to one cell).
          #: This option can be specified multiple times. The syntax is::

          #:     narrow_symbols codepoints [optionally the number of cells]

          # disable_ligatures never

          #: Choose how you want to handle multi-character ligatures. The
          #: default is to always render them. You can tell kitty to not render
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
          #: ligatures, use the font_features option.

          # font_features

          #: E.g. font_features none

          #: Choose exactly which OpenType features to enable or disable. This
          #: is useful as some fonts might have features worthwhile in a
          #: terminal. For example, Fira Code includes a discretionary feature,
          #: zero, which in that font changes the appearance of the zero (0), to
          #: make it more easily distinguishable from Ø. Fira Code also includes
          #: other discretionary features known as Stylistic Sets which have the
          #: tags ss01 through ss20.

          #: For the exact syntax to use for individual features, see the
          #: HarfBuzz documentation <https://harfbuzz.github.io/harfbuzz-hb-
          #: common.html#hb-feature-from-string>.

          #: Note that this code is indexed by PostScript name, and not the font
          #: family. This allows you to define very precise feature settings;
          #: e.g. you can disable a feature in the italic font but not in the
          #: regular font.

          #: On Linux, font features are first read from the FontConfig database
          #: and then this option is applied, so they can be configured in a
          #: single, central place.

          #: To get the PostScript name for a font, use `kitty +list-fonts
          #: --psnames`:

          #: .. code-block:: sh

          #:     $ kitty +list-fonts --psnames | grep Fira
          #:     Fira Code
          #:     Fira Code Bold (FiraCode-Bold)
          #:     Fira Code Light (FiraCode-Light)
          #:     Fira Code Medium (FiraCode-Medium)
          #:     Fira Code Regular (FiraCode-Regular)
          #:     Fira Code Retina (FiraCode-Retina)

          #: The part in brackets is the PostScript name.

          #: Enable alternate zero and oldstyle numerals::

          #:     font_features FiraCode-Retina +zero +onum

          #: Enable only alternate zero in the bold font::

          #:     font_features FiraCode-Bold +zero

          #: Disable the normal ligatures, but keep the calt feature which (in
          #: this font) breaks up monotony::

          #:     font_features TT2020StyleB-Regular -liga +calt

          #: In conjunction with force_ltr, you may want to disable Arabic
          #: shaping entirely, and only look at their isolated forms if they
          #: show up in a document. You can do this with e.g.::

          #:     font_features UnifontMedium +isol -medi -fina -init

          # modify_font

          #: Modify font characteristics such as the position or thickness of
          #: the underline and strikethrough. The modifications can have the
          #: suffix px for pixels or % for percentage of original value. No
          #: suffix means use pts. For example::

          #:     modify_font underline_position -2
          #:     modify_font underline_thickness 150%
          #:     modify_font strikethrough_position 2px

          #: Additionally, you can modify the size of the cell in which each
          #: font glyph is rendered and the baseline at which the glyph is
          #: placed in the cell. For example::

          #:     modify_font cell_width 80%
          #:     modify_font cell_height -2px
          #:     modify_font baseline 3

          #: Note that modifying the baseline will automatically adjust the
          #: underline and strikethrough positions by the same amount.
          #: Increasing the baseline raises glyphs inside the cell and
          #: decreasing it lowers them. Decreasing the cell size might cause
          #: rendering artifacts, so use with care.

          # box_drawing_scale 0.001, 1, 1.5, 2

          #: The sizes of the lines used for the box drawing Unicode characters.
          #: These values are in pts. They will be scaled by the monitor DPI to
          #: arrive at a pixel value. There must be four values corresponding to
          #: thin, normal, thick, and very thick lines.

          # undercurl_style thin-sparse

          #: The style with which undercurls are rendered. This option takes the
          #: form (thin|thick)-(sparse|dense). Thin and thick control the
          #: thickness of the undercurl. Sparse and dense control how often the
          #: curl oscillates. With sparse the curl will peak once per character,
          #: with dense twice.

          # text_composition_strategy platform

          #: Control how kitty composites text glyphs onto the background color.
          #: The default value of platform tries for text rendering as close to
          #: "native" for the platform kitty is running on as possible.

          #: A value of legacy uses the old (pre kitty 0.28) strategy for how
          #: glyphs are composited. This will make dark text on light
          #: backgrounds look thicker and light text on dark backgrounds
          #: thinner. It might also make some text appear like the strokes are
          #: uneven.

          #: You can fine tune the actual contrast curve used for glyph
          #: composition by specifying up to two space-separated numbers for
          #: this setting.

          #: The first number is the gamma adjustment, which controls the
          #: thickness of dark text on light backgrounds. Increasing the value
          #: will make text appear thicker. The default value for this is 1.0 on
          #: Linux and 1.7 on macOS. Valid values are 0.01 and above. The result
          #: is scaled based on the luminance difference between the background
          #: and the foreground. Dark text on light backgrounds receives the
          #: full impact of the curve while light text on dark backgrounds is
          #: affected very little.

          #: The second number is an additional multiplicative contrast. It is
          #: percentage ranging from 0 to 100. The default value is 0 on Linux
          #: and 30 on macOS.

          #: If you wish to achieve similar looking thickness in light and dark
          #: themes, a good way to experiment is start by setting the value to
          #: 1.0 0 and use a dark theme. Then adjust the second parameter until
          #: it looks good. Then switch to a light theme and adjust the first
          #: parameter until the perceived thickness matches the dark theme.

          # text_fg_override_threshold 0

          #: The minimum accepted difference in luminance between the foreground
          #: and background color, below which kitty will override the
          #: foreground color. It is percentage ranging from 0 to 100. If the
          #: difference in luminance of the foreground and background is below
          #: this threshold, the foreground color will be set to white if the
          #: background is dark or black if the background is light. The default
          #: value is 0, which means no overriding is performed. Useful when
          #: working with applications that use colors that do not contrast well
          #: with your preferred color scheme.

          #: WARNING: Some programs use characters (such as block characters)
          #: for graphics display and may expect to be able to set the
          #: foreground and background to the same color (or similar colors).
          #: If you see unexpected stripes, dots, lines, incorrect color, no
          #: color where you expect color, or any kind of graphic display
          #: problem try setting text_fg_override_threshold to 0 to see if this
          #: is the cause of the problem.

          #: }}}
        ''
        # CURSOR customization
        ''
          #: Cursor customization {{{

          # cursor #cccccc

          #: Default cursor color. If set to the special value none the cursor
          #: will be rendered with a "reverse video" effect. It's color will be
          #: the color of the text in the cell it is over and the text will be
          #: rendered with the background color of the cell. Note that if the
          #: program running in the terminal sets a cursor color, this takes
          #: precedence. Also, the cursor colors are modified if the cell
          #: background and foreground colors have very low contrast.

          # cursor_text_color #111111

          #: The color of text under the cursor. If you want it rendered with
          #: the background color of the cell underneath instead, use the
          #: special keyword: background. Note that if cursor is set to none
          #: then this option is ignored.

          # cursor_shape block

          #: The cursor shape can be one of block, beam, underline. Note that
          #: when reloading the config this will be changed only if the cursor
          #: shape has not been set by the program running in the terminal. This
          #: sets the default cursor shape, applications running in the terminal
          #: can override it. In particular, shell integration
          #: <https://sw.kovidgoyal.net/kitty/shell-integration/> in kitty sets
          #: the cursor shape to beam at shell prompts. You can avoid this by
          #: setting shell_integration to no-cursor.

          # cursor_beam_thickness 1.5

          #: The thickness of the beam cursor (in pts).

          # cursor_underline_thickness 2.0

          #: The thickness of the underline cursor (in pts).

          # cursor_blink_interval -1
        ''
        # cursor blink
        ''
          # don't blink the cursor
          cursor_blink_interval 0
        ''
        ''
          #: The interval to blink the cursor (in seconds). Set to zero to
          #: disable blinking. Negative values mean use system default. Note
          #: that the minimum interval will be limited to repaint_delay.

          # cursor_stop_blinking_after 15.0

          #: Stop blinking cursor after the specified number of seconds of
          #: keyboard inactivity. Set to zero to never stop blinking.

          #: }}}
        ''
        # SCROLLBACK
        ''
          #: Scrollback {{{
        ''
        # scrollback size
        ''
          # scrollback_pager_history_size is much larger, and offloads slowdown from keeping it all in memory
          scrollback_lines 100000
        ''
        ''
          # scrollback_lines 2000

          #: Number of lines of history to keep in memory for scrolling back.
          #: Memory is allocated on demand. Negative numbers are (effectively)
          #: infinite scrollback. Note that using very large scrollback is not
          #: recommended as it can slow down performance of the terminal and
          #: also use large amounts of RAM. Instead, consider using
          #: scrollback_pager_history_size. Note that on config reload if this
          #: is changed it will only affect newly created windows, not existing
          #: ones.

          # scrollback_pager less --chop-long-lines --RAW-CONTROL-CHARS +INPUT_LINE_NUMBER

          #: Program with which to view scrollback in a new window. The
          #: scrollback buffer is passed as STDIN to this program. If you change
          #: it, make sure the program you use can handle ANSI escape sequences
          #: for colors and text formatting. INPUT_LINE_NUMBER in the command
          #: line above will be replaced by an integer representing which line
          #: should be at the top of the screen. Similarly CURSOR_LINE and
          #: CURSOR_COLUMN will be replaced by the current cursor position or
          #: set to 0 if there is no cursor, for example, when showing the last
          #: command output.
        ''
        # scrollback pager
        ''
          # max scrollback pager size (4GB), stored on disk and accessed with kitty_mod+h
          scrollback_pager_history_size 4000
        ''
        ''
          # scrollback_pager_history_size 0

          #: Separate scrollback history size (in MB), used only for browsing
          #: the scrollback buffer with pager. This separate buffer is not
          #: available for interactive scrolling but will be piped to the pager
          #: program when viewing scrollback buffer in a separate window. The
          #: current implementation stores the data in UTF-8, so approximately
          #: 10000 lines per megabyte at 100 chars per line, for pure ASCII,
          #: unformatted text. A value of zero or less disables this feature.
          #: The maximum allowed size is 4GB. Note that on config reload if this
          #: is changed it will only affect newly created windows, not existing
          #: ones.
        ''
        # scrollback fill
        ''
          scrollback_fill_enlarged_window yes
        ''
        ''
          # scrollback_fill_enlarged_window no

          #: Fill new space with lines from the scrollback buffer after
          #: enlarging a window.

          # wheel_scroll_multiplier 5.0

          #: Multiplier for the number of lines scrolled by the mouse wheel.
          #: Note that this is only used for low precision scrolling devices,
          #: not for high precision scrolling devices on platforms such as macOS
          #: and Wayland. Use negative numbers to change scroll direction. See
          #: also wheel_scroll_min_lines.

          # wheel_scroll_min_lines 1

          #: The minimum number of lines scrolled by the mouse wheel. The scroll
          #: multiplier wheel_scroll_multiplier only takes effect after it
          #: reaches this number. Note that this is only used for low precision
          #: scrolling devices like wheel mice that scroll by very small amounts
          #: when using the wheel. With a negative number, the minimum number of
          #: lines will always be added.

          # touch_scroll_multiplier 1.0

          #: Multiplier for the number of lines scrolled by a touchpad. Note
          #: that this is only used for high precision scrolling devices on
          #: platforms such as macOS and Wayland. Use negative numbers to change
          #: scroll direction.

          #: }}}
        ''
        # MOUSE
        ''
          #: Mouse {{{
        ''
        # mouse hide wait
        ''
          # hide immediately when typing
          mouse_hide_wait -1
        ''
        ''
          # mouse_hide_wait 3.0

          #: Hide mouse cursor after the specified number of seconds of the
          #: mouse not being used. Set to zero to disable mouse cursor hiding.
          #: Set to a negative value to hide the mouse cursor immediately when
          #: typing text. Disabled by default on macOS as getting it to work
          #: robustly with the ever-changing sea of bugs that is Cocoa is too
          #: much effort.

          # url_color #0087bd
          # url_style curly

          #: The color and style for highlighting URLs on mouse-over. url_style
          #: can be one of: none, straight, double, curly, dotted, dashed.

          # open_url_with default

          #: The program to open clicked URLs. The special value default with
          #: first look for any URL handlers defined via the open_actions
          #: <https://sw.kovidgoyal.net/kitty/open_actions/> facility and if non
          #: are found, it will use the Operating System's default URL handler
          #: (open on macOS and xdg-open on Linux).

          # url_prefixes file ftp ftps gemini git gopher http https irc ircs kitty mailto news sftp ssh

          #: The set of URL prefixes to look for when detecting a URL under the
          #: mouse cursor.

          # detect_urls yes

          #: Detect URLs under the mouse. Detected URLs are highlighted with an
          #: underline and the mouse cursor becomes a hand over them. Even if
          #: this option is disabled, URLs are still clickable. See also the
          #: underline_hyperlinks option to control how hyperlinks (as opposed
          #: to plain text URLs) are displayed.

          # url_excluded_characters

          #: Additional characters to be disallowed from URLs, when detecting
          #: URLs under the mouse cursor. By default, all characters that are
          #: legal in URLs are allowed. Additionally, newlines are allowed (but
          #: stripped). This is to accommodate programs such as mutt that add
          #: hard line breaks even for continued lines. \n can be added to this
          #: option to disable this behavior. Special characters can be
          #: specified using backslash escapes, to specify a backslash use a
          #: double backslash.

          # show_hyperlink_targets no

          #: When the mouse hovers over a terminal hyperlink, show the actual
          #: URL that will be activated when the hyperlink is clicked.

          # underline_hyperlinks hover

          #: Control how hyperlinks are underlined. They can either be
          #: underlined on mouse hover, always (i.e. permanently underlined) or
          #: never which means that kitty will not apply any underline styling
          #: to hyperlinks. Uses the url_style and url_color settings for the
          #: underline style. Note that reloading the config and changing this
          #: value to/from always will only affect text subsequently received by
          #: kitty.
        ''
        # copy on select
        ''
          # WARNING: it doesn't work when in vim, but using it makes it operate more like other terminals
          copy_on_select yes
        ''
        ''
          # copy_on_select no

          #: Copy to clipboard or a private buffer on select. With this set to
          #: clipboard, selecting text with the mouse will cause the text to be
          #: copied to clipboard. Useful on platforms such as macOS that do not
          #: have the concept of primary selection. You can instead specify a
          #: name such as a1 to copy to a private kitty buffer. Map a shortcut
          #: with the paste_from_buffer action to paste from this private
          #: buffer. For example::

          #:     copy_on_select a1
          #:     map shift+cmd+v paste_from_buffer a1

          #: Note that copying to the clipboard is a security risk, as all
          #: programs, including websites open in your browser can read the
          #: contents of the system clipboard.

          # paste_actions quote-urls-at-prompt,confirm

          #: A comma separated list of actions to take when pasting text into
          #: the terminal. The supported paste actions are:

          #: quote-urls-at-prompt:
          #:     If the text being pasted is a URL and the cursor is at a shell prompt,
          #:     automatically quote the URL (needs shell_integration).
          #: replace-dangerous-control-codes
          #:     Replace dangerous control codes from pasted text, without confirmation.
          #: replace-newline
          #:     Replace the newline character from pasted text, without confirmation.
          #: confirm:
          #:     Confirm the paste if the text to be pasted contains any terminal control codes
          #:     as this can be dangerous, leading to code execution if the shell/program running
          #:     in the terminal does not properly handle these.
          #: confirm-if-large
          #:     Confirm the paste if it is very large (larger than 16KB) as pasting
          #:     large amounts of text into shells can be very slow.
          #: filter:
          #:     Run the filter_paste() function from the file paste-actions.py in
          #:     the kitty config directory on the pasted text. The text returned by the
          #:     function will be actually pasted.

          # strip_trailing_spaces never

          #: Remove spaces at the end of lines when copying to clipboard. A
          #: value of smart will do it when using normal selections, but not
          #: rectangle selections. A value of always will always do it.

          # select_by_word_characters @-./_~?&=%+#

          #: Characters considered part of a word when double clicking. In
          #: addition to these characters any character that is marked as an
          #: alphanumeric character in the Unicode database will be matched.

          # select_by_word_characters_forward

          #: Characters considered part of a word when extending the selection
          #: forward on double clicking. In addition to these characters any
          #: character that is marked as an alphanumeric character in the
          #: Unicode database will be matched.

          #: If empty (default) select_by_word_characters will be used for both
          #: directions.

          # click_interval -1.0

          #: The interval between successive clicks to detect double/triple
          #: clicks (in seconds). Negative numbers will use the system default
          #: instead, if available, or fallback to 0.5.

          # focus_follows_mouse no

          #: Set the active window to the window under the mouse when moving the
          #: mouse around. On macOS, this will also cause the OS Window under
          #: the mouse to be focused automatically when the mouse enters it.

          # pointer_shape_when_grabbed arrow

          #: The shape of the mouse pointer when the program running in the
          #: terminal grabs the mouse.

          # default_pointer_shape beam

          #: The default shape of the mouse pointer.

          # pointer_shape_when_dragging beam

          #: The default shape of the mouse pointer when dragging across text.
        ''
        ## MOUSE Actions
        ''
          #: Mouse actions {{{

          #: Mouse buttons can be mapped to perform arbitrary actions. The
          #: syntax is:

          #: .. code-block:: none

          #:     mouse_map button-name event-type modes action

          #: Where button-name is one of left, middle, right, b1 ... b8 with
          #: added keyboard modifiers. For example: ctrl+shift+left refers to
          #: holding the Ctrl+Shift keys while clicking with the left mouse
          #: button. The value b1 ... b8 can be used to refer to up to eight
          #: buttons on a mouse.

          #: event-type is one of press, release, doublepress, triplepress,
          #: click, doubleclick. modes indicates whether the action is performed
          #: when the mouse is grabbed by the program running in the terminal,
          #: or not. The values are grabbed or ungrabbed or a comma separated
          #: combination of them. grabbed refers to when the program running in
          #: the terminal has requested mouse events. Note that the click and
          #: double click events have a delay of click_interval to disambiguate
          #: from double and triple presses.

          #: You can run kitty with the kitty --debug-input command line option
          #: to see mouse events. See the builtin actions below to get a sense
          #: of what is possible.

          #: If you want to unmap an action, map it to no_op. For example, to
          #: disable opening of URLs with a plain click::

          #:     mouse_map left click ungrabbed no_op

          #: See all the mappable actions including mouse actions here
          #: <https://sw.kovidgoyal.net/kitty/actions/>.

          #: .. note::
          #:     Once a selection is started, releasing the button that started it will
          #:     automatically end it and no release event will be dispatched.

          # clear_all_mouse_actions no

          #: Remove all mouse action definitions up to this point. Useful, for
          #: instance, to remove the default mouse actions.

          #: Click the link under the mouse or move the cursor

          # mouse_map left click ungrabbed mouse_handle_click selection link prompt

          #::  First check for a selection and if one exists do nothing. Then
          #::  check for a link under the mouse cursor and if one exists, click
          #::  it. Finally check if the click happened at the current shell
          #::  prompt and if so, move the cursor to the click location. Note
          #::  that this requires shell integration
          #::  <https://sw.kovidgoyal.net/kitty/shell-integration/> to work.

          #: Click the link under the mouse or move the cursor even when grabbed

          # mouse_map shift+left click grabbed,ungrabbed mouse_handle_click selection link prompt

          #::  Same as above, except that the action is performed even when the
          #::  mouse is grabbed by the program running in the terminal.

          #: Click the link under the mouse cursor

          # mouse_map ctrl+shift+left release grabbed,ungrabbed mouse_handle_click link

          #::  Variant with Ctrl+Shift is present because the simple click based
          #::  version has an unavoidable delay of click_interval, to
          #::  disambiguate clicks from double clicks.

          #: Discard press event for link click

          # mouse_map ctrl+shift+left press grabbed discard_event

          #::  Prevent this press event from being sent to the program that has
          #::  grabbed the mouse, as the corresponding release event is used to
          #::  open a URL.

          #: Paste from the primary selection

          # mouse_map middle release ungrabbed paste_from_selection

          #: Start selecting text

          # mouse_map left press ungrabbed mouse_selection normal

          #: Start selecting text in a rectangle

          # mouse_map ctrl+alt+left press ungrabbed mouse_selection rectangle

          #: Select a word

          # mouse_map left doublepress ungrabbed mouse_selection word

          #: Select a line

          # mouse_map left triplepress ungrabbed mouse_selection line

          #: Select line from point

          # mouse_map ctrl+alt+left triplepress ungrabbed mouse_selection line_from_point

          #::  Select from the clicked point to the end of the line. If you
          #::  would like to select the word at the point and then extend to the
          #::  rest of the line, change line_from_point to
          #::  word_and_line_from_point.

          #: Extend the current selection

          # mouse_map right press ungrabbed mouse_selection extend

          #::  If you want only the end of the selection to be moved instead of
          #::  the nearest boundary, use move-end instead of extend.

          #: Paste from the primary selection even when grabbed

          # mouse_map shift+middle release ungrabbed,grabbed paste_selection
          # mouse_map shift+middle press grabbed discard_event

          #: Start selecting text even when grabbed

          # mouse_map shift+left press ungrabbed,grabbed mouse_selection normal

          #: Start selecting text in a rectangle even when grabbed

          # mouse_map ctrl+shift+alt+left press ungrabbed,grabbed mouse_selection rectangle

          #: Select a word even when grabbed

          # mouse_map shift+left doublepress ungrabbed,grabbed mouse_selection word

          #: Select a line even when grabbed

          # mouse_map shift+left triplepress ungrabbed,grabbed mouse_selection line

          #: Select line from point even when grabbed

          # mouse_map ctrl+shift+alt+left triplepress ungrabbed,grabbed mouse_selection line_from_point

          #::  Select from the clicked point to the end of the line even when
          #::  grabbed. If you would like to select the word at the point and
          #::  then extend to the rest of the line, change line_from_point to
          #::  word_and_line_from_point.

          #: Extend the current selection even when grabbed

          # mouse_map shift+right press ungrabbed,grabbed mouse_selection extend

          #: Show clicked command output in pager

          # mouse_map ctrl+shift+right press ungrabbed mouse_show_command_output

          #::  Requires shell integration
          #::  <https://sw.kovidgoyal.net/kitty/shell-integration/> to work.

          #: }}}

          #: }}}
        ''
        # Performance Tuning
        ''
          #: Performance tuning {{{

          # repaint_delay 10

          #: Delay between screen updates (in milliseconds). Decreasing it,
          #: increases frames-per-second (FPS) at the cost of more CPU usage.
          #: The default value yields ~100 FPS which is more than sufficient for
          #: most uses. Note that to actually achieve 100 FPS, you have to
          #: either set sync_to_monitor to no or use a monitor with a high
          #: refresh rate. Also, to minimize latency when there is pending input
          #: to be processed, this option is ignored.

          # input_delay 3

          #: Delay before input from the program running in the terminal is
          #: processed (in milliseconds). Note that decreasing it will increase
          #: responsiveness, but also increase CPU usage and might cause flicker
          #: in full screen programs that redraw the entire screen on each loop,
          #: because kitty is so fast that partial screen updates will be drawn.

          # sync_to_monitor yes

          #: Sync screen updates to the refresh rate of the monitor. This
          #: prevents screen tearing
          #: <https://en.wikipedia.org/wiki/Screen_tearing> when scrolling.
          #: However, it limits the rendering speed to the refresh rate of your
          #: monitor. With a very high speed mouse/high keyboard repeat rate,
          #: you may notice some slight input latency. If so, set this to no.

          #: }}}
        ''
        # Terminal bell
        ''
          #: Terminal bell {{{
        ''
        # audio bell
        ''
          enable_audio_bell no
        ''
        ''
          # enable_audio_bell yes

          #: The audio bell. Useful to disable it in environments that require
          #: silence.

          # visual_bell_duration 0.0

          #: The visual bell duration (in seconds). Flash the screen when a bell
          #: occurs for the specified number of seconds. Set to zero to disable.

          # visual_bell_color none

          #: The color used by visual bell. Set to none will fall back to
          #: selection background color. If you feel that the visual bell is too
          #: bright, you can set it to a darker color.

          # window_alert_on_bell yes

          #: Request window attention on bell. Makes the dock icon bounce on
          #: macOS or the taskbar flash on linux.

          # bell_on_tab "🔔 "

          #: Some text or a Unicode symbol to show on the tab if a window in the
          #: tab that does not have focus has a bell. If you want to use leading
          #: or trailing spaces, surround the text with quotes. See
          #: tab_title_template for how this is rendered.

          #: For backwards compatibility, values of yes, y and true are
          #: converted to the default bell symbol and no, n, false and none are
          #: converted to the empty string.

          # command_on_bell none

          #: Program to run when a bell occurs. The environment variable
          #: KITTY_CHILD_CMDLINE can be used to get the program running in the
          #: window in which the bell occurred.

          # bell_path none

          #: Path to a sound file to play as the bell sound. If set to none, the
          #: system default bell sound is used. Must be in a format supported by
          #: the operating systems sound API, such as WAV or OGA on Linux
          #: (libcanberra) or AIFF, MP3 or WAV on macOS (NSSound)

          # linux_bell_theme __custom

          #: The XDG Sound Theme kitty will use to play the bell sound. Defaults
          #: to the custom theme name used by GNOME and Budgie, falling back to
          #: the default freedesktop theme if it does not exist. This option may
          #: be removed if Linux ever provides desktop-agnostic support for
          #: setting system sound themes.

          #: }}}
        ''
        # WINDOW LAYOUT
        ''
          #: Window layout {{{

          # remember_window_size  yes
          # initial_window_width  640
          # initial_window_height 400

          #: If enabled, the OS Window size will be remembered so that new
          #: instances of kitty will have the same size as the previous
          #: instance. If disabled, the OS Window will initially have size
          #: configured by initial_window_width/height, in pixels. You can use a
          #: suffix of "c" on the width/height values to have them interpreted
          #: as number of cells instead of pixels.

        ''
        # layout reordering
        ''
          # re-order the layouts so Splits is first, making it the default, and eliminating
          # some of the layouts that aren't useful.
          # Splits is the only layout that allows hsplit and vsplit, and directional navigation
          # between splits.
          enabled_layouts Splits,Tall,Horizontal,Grid,Stack
        ''
        ''
          # enabled_layouts *

          #: The enabled window layouts. A comma separated list of layout names.
          #: The special value all means all layouts. The first listed layout
          #: will be used as the startup layout. Default configuration is all
          #: layouts in alphabetical order. For a list of available layouts, see
          #: the layouts <https://sw.kovidgoyal.net/kitty/overview/#layouts>.

          # window_resize_step_cells 2
          # window_resize_step_lines 2

          #: The step size (in units of cell width/cell height) to use when
          #: resizing kitty windows in a layout with the shortcut
          #: start_resizing_window. The cells value is used for horizontal
          #: resizing, and the lines value is used for vertical resizing.

          # window_border_width 0.5pt

          #: The width of window borders. Can be either in pixels (px) or pts
          #: (pt). Values in pts will be rounded to the nearest number of pixels
          #: based on screen resolution. If not specified, the unit is assumed
          #: to be pts. Note that borders are displayed only when more than one
          #: window is visible. They are meant to separate multiple windows.

          # draw_minimal_borders yes

          #: Draw only the minimum borders needed. This means that only the
          #: borders that separate the window from a neighbor are drawn. Note
          #: that setting a non-zero window_margin_width overrides this and
          #: causes all borders to be drawn.

          # window_margin_width 0

          #: The window margin (in pts) (blank area outside the border). A
          #: single value sets all four sides. Two values set the vertical and
          #: horizontal sides. Three values set top, horizontal and bottom. Four
          #: values set top, right, bottom and left.

          # single_window_margin_width -1

          #: The window margin to use when only a single window is visible (in
          #: pts). Negative values will cause the value of window_margin_width
          #: to be used instead. A single value sets all four sides. Two values
          #: set the vertical and horizontal sides. Three values set top,
          #: horizontal and bottom. Four values set top, right, bottom and left.

          # window_padding_width 0

          #: The window padding (in pts) (blank area between the text and the
          #: window border). A single value sets all four sides. Two values set
          #: the vertical and horizontal sides. Three values set top, horizontal
          #: and bottom. Four values set top, right, bottom and left.

          # single_window_padding_width -1

          #: The window padding to use when only a single window is visible (in
          #: pts). Negative values will cause the value of window_padding_width
          #: to be used instead. A single value sets all four sides. Two values
          #: set the vertical and horizontal sides. Three values set top,
          #: horizontal and bottom. Four values set top, right, bottom and left.

          # placement_strategy center

          #: When the window size is not an exact multiple of the cell size, the
          #: cell area of the terminal window will have some extra padding on
          #: the sides. You can control how that padding is distributed with
          #: this option. Using a value of center means the cell area will be
          #: placed centrally. A value of top-left means the padding will be
          #: only at the bottom and right edges.

          # active_border_color #00ff00

          #: The color for the border of the active window. Set this to none to
          #: not draw borders around the active window.

          # inactive_border_color #cccccc

          #: The color for the border of inactive windows.

          # bell_border_color #ff5a00

          #: The color for the border of inactive windows in which a bell has
          #: occurred.

          # inactive_text_alpha 1.0

          #: Fade the text in inactive windows by the specified amount (a number
          #: between zero and one, with zero being fully faded).

          # hide_window_decorations no

          #: Hide the window decorations (title-bar and window borders) with
          #: yes. On macOS, titlebar-only and titlebar-and-corners can be used
          #: to only hide the titlebar and the rounded corners. Whether this
          #: works and exactly what effect it has depends on the window
          #: manager/operating system. Note that the effects of changing this
          #: option when reloading config are undefined. When using titlebar-
          #: only, it is useful to also set window_margin_width and
          #: placement_strategy to prevent the rounded corners from clipping
          #: text. Or use titlebar-and-corners.

          # window_logo_path none

          #: Path to a logo image. Must be in PNG format. Relative paths are
          #: interpreted relative to the kitty config directory. The logo is
          #: displayed in a corner of every kitty window. The position is
          #: controlled by window_logo_position. Individual windows can be
          #: configured to have different logos either using the launch action
          #: or the remote control <https://sw.kovidgoyal.net/kitty/remote-
          #: control/> facility.

          # window_logo_position bottom-right

          #: Where to position the window logo in the window. The value can be
          #: one of: top-left, top, top-right, left, center, right, bottom-left,
          #: bottom, bottom-right.

          # window_logo_alpha 0.5

          #: The amount the logo should be faded into the background. With zero
          #: being fully faded and one being fully opaque.

          # resize_debounce_time 0.1 0.5

          #: The time to wait before redrawing the screen during a live resize
          #: of the OS window, when no new resize events have been received,
          #: i.e. when resizing is either paused or finished. On platforms such
          #: as macOS, where the operating system sends events corresponding to
          #: the start and end of a live resize, the second number is used for
          #: redraw-after-pause since kitty can distinguish between a pause and
          #: end of resizing.  On such systems the first number is ignored and
          #: redraw is immediate after end of resize.  On other systems the
          #: first number is used so that kitty is "ready" quickly after the end
          #: of resizing, while not also continuously redrawing, to save energy.

          # resize_in_steps no

          #: Resize the OS window in steps as large as the cells, instead of
          #: with the usual pixel accuracy. Combined with initial_window_width
          #: and initial_window_height in number of cells, this option can be
          #: used to keep the margins as small as possible when resizing the OS
          #: window. Note that this does not currently work on Wayland.

          # visual_window_select_characters 1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ

          #: The list of characters for visual window selection. For example,
          #: for selecting a window to focus on with focus_visible_window. The
          #: value should be a series of unique numbers or alphabets, case
          #: insensitive, from the set 0-9A-Z\-=[];',./\\`. Specify your
          #: preference as a string of characters.

          # confirm_os_window_close -1

          #: Ask for confirmation when closing an OS window or a tab with at
          #: least this number of kitty windows in it by window manager (e.g.
          #: clicking the window close button or pressing the operating system
          #: shortcut to close windows) or by the close_tab action. A value of
          #: zero disables confirmation. This confirmation also applies to
          #: requests to quit the entire application (all OS windows, via the
          #: quit action). Negative values are converted to positive ones,
          #: however, with shell_integration enabled, using negative values
          #: means windows sitting at a shell prompt are not counted, only
          #: windows where some command is currently running. Note that if you
          #: want confirmation when closing individual windows, you can map the
          #: close_window_with_confirmation action.

          #: }}}
        ''
        # TAB BAR
        ''
          #: Tab bar {{{

          # tab_bar_edge bottom

          #: The edge to show the tab bar on, top or bottom.

          # tab_bar_margin_width 0.0

          #: The margin to the left and right of the tab bar (in pts).

          # tab_bar_margin_height 0.0 0.0

          #: The margin above and below the tab bar (in pts). The first number
          #: is the margin between the edge of the OS Window and the tab bar.
          #: The second number is the margin between the tab bar and the
          #: contents of the current tab.
        ''
        # tab bar style
        ''
          tab_bar_style slant
        ''
        ''
          # tab_bar_style fade

          #: The tab bar style, can be one of:

          #: fade
          #:     Each tab's edges fade into the background color. (See also tab_fade)
          #: slant
          #:     Tabs look like the tabs in a physical file.
          #: separator
          #:     Tabs are separated by a configurable separator. (See also
          #:     tab_separator)
          #: powerline
          #:     Tabs are shown as a continuous line with "fancy" separators.
          #:     (See also tab_powerline_style)
          #: custom
          #:     A user-supplied Python function called draw_tab is loaded from the file
          #:     tab_bar.py in the kitty config directory. For examples of how to
          #:     write such a function, see the functions named draw_tab_with_* in
          #:     kitty's source code: kitty/tab_bar.py. See also
          #:     this discussion <https://github.com/kovidgoyal/kitty/discussions/4447>
          #:     for examples from kitty users.
          #: hidden
          #:     The tab bar is hidden. If you use this, you might want to create
          #:     a mapping for the select_tab action which presents you with a list of
          #:     tabs and allows for easy switching to a tab.

          # tab_bar_align left

          #: The horizontal alignment of the tab bar, can be one of: left,
          #: center, right.

          # tab_bar_min_tabs 2

          #: The minimum number of tabs that must exist before the tab bar is
          #: shown.

          # tab_switch_strategy previous

          #: The algorithm to use when switching to a tab when the current tab
          #: is closed. The default of previous will switch to the last used
          #: tab. A value of left will switch to the tab to the left of the
          #: closed tab. A value of right will switch to the tab to the right of
          #: the closed tab. A value of last will switch to the right-most tab.

          # tab_fade 0.25 0.5 0.75 1

          #: Control how each tab fades into the background when using fade for
          #: the tab_bar_style. Each number is an alpha (between zero and one)
          #: that controls how much the corresponding cell fades into the
          #: background, with zero being no fade and one being full fade. You
          #: can change the number of cells used by adding/removing entries to
          #: this list.

          # tab_separator " ┇"

          #: The separator between tabs in the tab bar when using separator as
          #: the tab_bar_style.

          # tab_powerline_style angled

          #: The powerline separator style between tabs in the tab bar when
          #: using powerline as the tab_bar_style, can be one of: angled,
          #: slanted, round.

          # tab_activity_symbol none

          #: Some text or a Unicode symbol to show on the tab if a window in the
          #: tab that does not have focus has some activity. If you want to use
          #: leading or trailing spaces, surround the text with quotes. See
          #: tab_title_template for how this is rendered.

          # tab_title_max_length 0

          #: The maximum number of cells that can be used to render the text in
          #: a tab. A value of zero means that no limit is applied.
        ''
        # tab title template
        ''
          # add index number to the tab title
          tab_title_template "{fmt.fg.red}{bell_symbol}{activity_symbol}{fmt.fg.tab}{index}:{title}"
        ''
        ''
          # tab_title_template "{fmt.fg.red}{bell_symbol}{activity_symbol}{fmt.fg.tab}{title}"

          #: A template to render the tab title. The default just renders the
          #: title with optional symbols for bell and activity. If you wish to
          #: include the tab-index as well, use something like: {index}:{title}.
          #: Useful if you have shortcuts mapped for goto_tab N. If you prefer
          #: to see the index as a superscript, use {sup.index}. All data
          #: available is:

          #: title
          #:     The current tab title.
          #: index
          #:     The tab index usable with goto_tab N goto_tab shortcuts.
          #: layout_name
          #:     The current layout name.
          #: num_windows
          #:     The number of windows in the tab.
          #: num_window_groups
          #:     The number of window groups (a window group is a window and all of its overlay windows) in the tab.
          #: tab.active_wd
          #:     The working directory of the currently active window in the tab
          #:     (expensive, requires syscall). Use active_oldest_wd to get
          #:     the directory of the oldest foreground process rather than the newest.
          #: tab.active_exe
          #:     The name of the executable running in the foreground of the currently
          #:     active window in the tab (expensive, requires syscall). Use
          #:     active_oldest_exe for the oldest foreground process.
          #: max_title_length
          #:     The maximum title length available.

          #: Note that formatting is done by Python's string formatting
          #: machinery, so you can use, for instance, {layout_name[:2].upper()}
          #: to show only the first two letters of the layout name, upper-cased.
          #: If you want to style the text, you can use styling directives, for
          #: example:
          #: `{fmt.fg.red}red{fmt.fg.tab}normal{fmt.bg._00FF00}greenbg{fmt.bg.tab}`.
          #: Similarly, for bold and italic:
          #: `{fmt.bold}bold{fmt.nobold}normal{fmt.italic}italic{fmt.noitalic}`.
          #: Note that for backward compatibility, if {bell_symbol} or
          #: {activity_symbol} are not present in the template, they are
          #: prepended to it.

          # active_tab_title_template none

          #: Template to use for active tabs. If not specified falls back to
          #: tab_title_template.

          # active_tab_foreground   #000
          # active_tab_background   #eee
          # active_tab_font_style   bold-italic
          # inactive_tab_foreground #444
          # inactive_tab_background #999
          # inactive_tab_font_style normal

          #: Tab bar colors and styles.

          # tab_bar_background none

          #: Background color for the tab bar. Defaults to using the terminal
          #: background color.

          # tab_bar_margin_color none

          #: Color for the tab bar margin area. Defaults to using the terminal
          #: background color for margins above and below the tab bar. For side
          #: margins the default color is chosen to match the background color
          #: of the neighboring tab.

          #: }}}
        ''
        # COLOR SCHEME
        ''
          #: Color scheme {{{

          # foreground #dddddd
          # background #000000

          #: The foreground and background colors.

          # background_opacity 1.0

          #: The opacity of the background. A number between zero and one, where
          #: one is opaque and zero is fully transparent. This will only work if
          #: supported by the OS (for instance, when using a compositor under
          #: X11). Note that it only sets the background color's opacity in
          #: cells that have the same background color as the default terminal
          #: background, so that things like the status bar in vim, powerline
          #: prompts, etc. still look good. But it means that if you use a color
          #: theme with a background color in your editor, it will not be
          #: rendered as transparent. Instead you should change the default
          #: background color in your kitty config and not use a background
          #: color in the editor color scheme. Or use the escape codes to set
          #: the terminals default colors in a shell script to launch your
          #: editor. Be aware that using a value less than 1.0 is a (possibly
          #: significant) performance hit. When using a low value for this
          #: setting, it is desirable that you set the background color to a
          #: color the matches the general color of the desktop background, for
          #: best text rendering.  If you want to dynamically change
          #: transparency of windows, set dynamic_background_opacity to yes
          #: (this is off by default as it has a performance cost). Changing
          #: this option when reloading the config will only work if
          #: dynamic_background_opacity was enabled in the original config.

          # background_blur 0

          #: Set to a positive value to enable background blur (blurring of the
          #: visuals behind a transparent window) on platforms that support it.
          #: Only takes effect when background_opacity is less than one. On
          #: macOS, this will also control the blur radius (amount of blurring).
          #: Setting it to too high a value will cause severe performance issues
          #: and/or rendering artifacts. Usually, values up to 64 work well.
          #: Note that this might cause performance issues, depending on how the
          #: platform implements it, so use with care. Currently supported on
          #: macOS and KDE under X11.

          # background_image none

          #: Path to a background image. Must be in PNG format.

          # background_image_layout tiled

          #: Whether to tile, scale or clamp the background image. The value can
          #: be one of tiled, mirror-tiled, scaled, clamped, centered or
          #: cscaled. The scaled and cscaled values scale the image to the
          #: window size, with cscaled preserving the image aspect ratio.

          # background_image_linear no

          #: When background image is scaled, whether linear interpolation
          #: should be used.

          # dynamic_background_opacity no

          #: Allow changing of the background_opacity dynamically, using either
          #: keyboard shortcuts (increase_background_opacity and
          #: decrease_background_opacity) or the remote control facility.
          #: Changing this option by reloading the config is not supported.

          # background_tint 0.0

          #: How much to tint the background image by the background color. This
          #: option makes it easier to read the text. Tinting is done using the
          #: current background color for each window. This option applies only
          #: if background_opacity is set and transparent windows are supported
          #: or background_image is set.

          # background_tint_gaps 1.0

          #: How much to tint the background image at the window gaps by the
          #: background color, after applying background_tint. Since this is
          #: multiplicative with background_tint, it can be used to lighten the
          #: tint over the window gaps for a *separated* look.

          # dim_opacity 0.4

          #: How much to dim text that has the DIM/FAINT attribute set. One
          #: means no dimming and zero means fully dimmed (i.e. invisible).

          # selection_foreground #000000
          # selection_background #fffacd

          #: The foreground and background colors for text selected with the
          #: mouse. Setting both of these to none will cause a "reverse video"
          #: effect for selections, where the selection will be the cell text
          #: color and the text will become the cell background color. Setting
          #: only selection_foreground to none will cause the foreground color
          #: to be used unchanged. Note that these colors can be overridden by
          #: the program running in the terminal.
        ''
        # COLOR TABLE
        ''
          #: The color table {{{

          #: The 256 terminal colors. There are 8 basic colors, each color has a
          #: dull and bright version, for the first 16 colors. You can set the
          #: remaining 240 colors as color16 to color255.

          # color0 #000000
          # color8 #767676

          #: black

          # color1 #cc0403
          # color9 #f2201f

          #: red

          # color2  #19cb00
          # color10 #23fd00

          #: green

          # color3  #cecb00
          # color11 #fffd00

          #: yellow

          # color4  #0d73cc
          # color12 #1a8fff

          #: blue

          # color5  #cb1ed1
          # color13 #fd28ff

          #: magenta

          # color6  #0dcdcd
          # color14 #14ffff

          #: cyan

          # color7  #dddddd
          # color15 #ffffff

          #: white

          # mark1_foreground black

          #: Color for marks of type 1

          # mark1_background #98d3cb

          #: Color for marks of type 1 (light steel blue)

          # mark2_foreground black

          #: Color for marks of type 2

          # mark2_background #f2dcd3

          #: Color for marks of type 1 (beige)

          # mark3_foreground black

          #: Color for marks of type 3

          # mark3_background #f274bc

          #: Color for marks of type 3 (violet)

          #: }}}

          #: }}}
        ''
        # ADVANCED
        ''
          #: Advanced {{{

          # shell .

          #: The shell program to execute. The default value of . means to use
          #: whatever shell is set as the default shell for the current user.
          #: Note that on macOS if you change this, you might need to add
          #: --login and --interactive to ensure that the shell starts in
          #: interactive mode and reads its startup rc files. Environment
          #: variables are expanded in this setting.

          # editor .

          #: The terminal based text editor (such as vim or nano) to use when
          #: editing the kitty config file or similar tasks.

          #: The default value of . means to use the environment variables
          #: VISUAL and EDITOR in that order. If these variables aren't set,
          #: kitty will run your shell ($SHELL -l -i -c env) to see if your
          #: shell startup rc files set VISUAL or EDITOR. If that doesn't work,
          #: kitty will cycle through various known editors (vim, emacs, etc.)
          #: and take the first one that exists on your system.

          # close_on_child_death no

          #: Close the window when the child process (shell) exits. With the
          #: default value no, the terminal will remain open when the child
          #: exits as long as there are still processes outputting to the
          #: terminal (for example disowned or backgrounded processes). When
          #: enabled with yes, the window will close as soon as the child
          #: process exits. Note that setting it to yes means that any
          #: background processes still using the terminal can fail silently
          #: because their stdout/stderr/stdin no longer work.

          # remote_control_password

          #: Allow other programs to control kitty using passwords. This option
          #: can be specified multiple times to add multiple passwords. If no
          #: passwords are present kitty will ask the user for permission if a
          #: program tries to use remote control with a password. A password can
          #: also *optionally* be associated with a set of allowed remote
          #: control actions. For example::

          #:     remote_control_password "my passphrase" get-colors set-colors focus-window focus-tab

          #: Only the specified actions will be allowed when using this
          #: password. Glob patterns can be used too, for example::

          #:     remote_control_password "my passphrase" set-tab-* resize-*

          #: To get a list of available actions, run::

          #:     kitten @ --help

          #: A set of actions to be allowed when no password is sent can be
          #: specified by using an empty password. For example::

          #:     remote_control_password "" *-colors

          #: Finally, the path to a python module can be specified that provides
          #: a function is_cmd_allowed that is used to check every remote
          #: control command. For example::

          #:     remote_control_password "my passphrase" my_rc_command_checker.py

          #: Relative paths are resolved from the kitty configuration directory.
          #: See rc_custom_auth <https://sw.kovidgoyal.net/kitty/remote-
          #: control/#rc-custom-auth> for details.

          # allow_remote_control no

          #: Allow other programs to control kitty. If you turn this on, other
          #: programs can control all aspects of kitty, including sending text
          #: to kitty windows, opening new windows, closing windows, reading the
          #: content of windows, etc. Note that this even works over SSH
          #: connections. The default setting of no prevents any form of remote
          #: control. The meaning of the various values are:

          #: password
          #:     Remote control requests received over both the TTY device and the socket
          #:     are confirmed based on passwords, see remote_control_password.

          #: socket-only
          #:     Remote control requests received over a socket are accepted
          #:     unconditionally. Requests received over the TTY are denied.
          #:     See listen_on.

          #: socket
          #:     Remote control requests received over a socket are accepted
          #:     unconditionally. Requests received over the TTY are confirmed based on
          #:     password.

          #: no
          #:     Remote control is completely disabled.

          #: yes
          #:     Remote control requests are always accepted.

          # listen_on none

          #: Listen to the specified socket for remote control connections. Note
          #: that this will apply to all kitty instances. It can be overridden
          #: by the kitty --listen-on command line option. For UNIX sockets,
          #: such as unix:$TEMP/mykitty or unix:@mykitty (on Linux).
          #: Environment variables are expanded and relative paths are resolved
          #: with respect to the temporary directory. If {kitty_pid} is present,
          #: then it is replaced by the PID of the kitty process, otherwise the
          #: PID of the kitty process is appended to the value, with a hyphen.
          #: For TCP sockets such as tcp:localhost:0 a random port is always
          #: used even if a non-zero port number is specified.  See the help for
          #: kitty --listen-on for more details. Note that this will be ignored
          #: unless allow_remote_control is set to either: yes, socket or
          #: socket-only. Changing this option by reloading the config is not
          #: supported.

          # env

          #: Specify the environment variables to be set in all child processes.
          #: Using the name with an equal sign (e.g. env VAR=) will set it to
          #: the empty string. Specifying only the name (e.g. env VAR) will
          #: remove the variable from the child process' environment. Note that
          #: environment variables are expanded recursively, for example::

          #:     env VAR1=a
          #:     env VAR2=$HOME/$VAR1/b

          #: The value of VAR2 will be <path to home directory>/a/b.

          # watcher

          #: Path to python file which will be loaded for watchers
          #: <https://sw.kovidgoyal.net/kitty/launch/#watchers>. Can be
          #: specified more than once to load multiple watchers. The watchers
          #: will be added to every kitty window. Relative paths are resolved
          #: relative to the kitty config directory. Note that reloading the
          #: config will only affect windows created after the reload.

          # exe_search_path

          #: Control where kitty finds the programs to run. The default search
          #: order is: First search the system wide PATH, then ~/.local/bin and
          #: ~/bin. If still not found, the PATH defined in the login shell
          #: after sourcing all its startup files is tried. Finally, if present,
          #: the PATH specified by the env option is tried.

          #: This option allows you to prepend, append, or remove paths from
          #: this search order. It can be specified multiple times for multiple
          #: paths. A simple path will be prepended to the search order. A path
          #: that starts with the + sign will be append to the search order,
          #: after ~/bin above. A path that starts with the - sign will be
          #: removed from the entire search order. For example::

          #:     exe_search_path /some/prepended/path
          #:     exe_search_path +/some/appended/path
          #:     exe_search_path -/some/excluded/path
        ''
        # update check
        ''
          # don't check for updates or phone home
          update_check_interval 0
        ''
        ''
          # update_check_interval 24

          #: The interval to periodically check if an update to kitty is
          #: available (in hours). If an update is found, a system notification
          #: is displayed informing you of the available update. The default is
          #: to check every 24 hours, set to zero to disable. Update checking is
          #: only done by the official binary builds. Distro packages or source
          #: builds do not do update checking. Changing this option by reloading
          #: the config is not supported.

          # startup_session none

          #: Path to a session file to use for all kitty instances. Can be
          #: overridden by using the kitty --session =none command line option
          #: for individual instances. See sessions
          #: <https://sw.kovidgoyal.net/kitty/overview/#sessions> in the kitty
          #: documentation for details. Note that relative paths are interpreted
          #: with respect to the kitty config directory. Environment variables
          #: in the path are expanded. Changing this option by reloading the
          #: config is not supported.

          # clipboard_control write-clipboard write-primary read-clipboard-ask read-primary-ask

          #: Allow programs running in kitty to read and write from the
          #: clipboard. You can control exactly which actions are allowed. The
          #: possible actions are: write-clipboard, read-clipboard, write-
          #: primary, read-primary, read-clipboard-ask, read-primary-ask. The
          #: default is to allow writing to the clipboard and primary selection
          #: and to ask for permission when a program tries to read from the
          #: clipboard. Note that disabling the read confirmation is a security
          #: risk as it means that any program, even the ones running on a
          #: remote server via SSH can read your clipboard. See also
          #: clipboard_max_size.

          # clipboard_max_size 512

          #: The maximum size (in MB) of data from programs running in kitty
          #: that will be stored for writing to the system clipboard. A value of
          #: zero means no size limit is applied. See also clipboard_control.

          # file_transfer_confirmation_bypass

          #: The password that can be supplied to the file transfer kitten
          #: <https://sw.kovidgoyal.net/kitty/kittens/transfer/> to skip the
          #: transfer confirmation prompt. This should only be used when
          #: initiating transfers from trusted computers, over trusted networks
          #: or encrypted transports, as it allows any programs running on the
          #: remote machine to read/write to the local filesystem, without
          #: permission.

          # allow_hyperlinks yes

          #: Process hyperlink escape sequences (OSC 8). If disabled OSC 8
          #: escape sequences are ignored. Otherwise they become clickable
          #: links, that you can click with the mouse or by using the hints
          #: kitten <https://sw.kovidgoyal.net/kitty/kittens/hints/>. The
          #: special value of ask means that kitty will ask before opening the
          #: link when clicked.

          # shell_integration enabled

          #: Enable shell integration on supported shells. This enables features
          #: such as jumping to previous prompts, browsing the output of the
          #: previous command in a pager, etc. on supported shells. Set to
          #: disabled to turn off shell integration, completely. It is also
          #: possible to disable individual features, set to a space separated
          #: list of these values: no-rc, no-cursor, no-title, no-cwd, no-
          #: prompt-mark, no-complete, no-sudo. See Shell integration
          #: <https://sw.kovidgoyal.net/kitty/shell-integration/> for details.

          # allow_cloning ask

          #: Control whether programs running in the terminal can request new
          #: windows to be created. The canonical example is clone-in-kitty
          #: <https://sw.kovidgoyal.net/kitty/shell-integration/#clone-shell>.
          #: By default, kitty will ask for permission for each clone request.
          #: Allowing cloning unconditionally gives programs running in the
          #: terminal (including over SSH) permission to execute arbitrary code,
          #: as the user who is running the terminal, on the computer that the
          #: terminal is running on.

          # clone_source_strategies venv,conda,env_var,path

          #: Control what shell code is sourced when running clone-in-kitty in
          #: the newly cloned window. The supported strategies are:

          #: venv
          #:     Source the file $VIRTUAL_ENV/bin/activate. This is used by the
          #:     Python stdlib venv module and allows cloning venvs automatically.
          #: conda
          #:     Run conda activate $CONDA_DEFAULT_ENV. This supports the virtual
          #:     environments created by conda.
          #: env_var
          #:     Execute the contents of the environment variable
          #:     KITTY_CLONE_SOURCE_CODE with eval.
          #: path
          #:     Source the file pointed to by the environment variable
          #:     KITTY_CLONE_SOURCE_PATH.

          #: This option must be a comma separated list of the above values.
          #: Only the first valid match, in the order specified, is sourced.

          # term xterm-kitty

          #: The value of the TERM environment variable to set. Changing this
          #: can break many terminal programs, only change it if you know what
          #: you are doing, not because you read some advice on "Stack Overflow"
          #: to change it. The TERM variable is used by various programs to get
          #: information about the capabilities and behavior of the terminal. If
          #: you change it, depending on what programs you run, and how
          #: different the terminal you are changing it to is, various things
          #: from key-presses, to colors, to various advanced features may not
          #: work. Changing this option by reloading the config will only affect
          #: newly created windows.

          # forward_stdio no

          #: Forward STDOUT and STDERR of the kitty process to child processes
          #: as file descriptors 3 and 4. This is useful for debugging as it
          #: allows child processes to print to kitty's STDOUT directly. For
          #: example, echo hello world >&3 in a shell will print to the parent
          #: kitty's STDOUT. When enabled, this also sets the
          #: KITTY_STDIO_FORWARDED=3 environment variable so child processes
          #: know about the forwarding.

          # menu_map

          #: Specify entries for various menus in kitty. Currently only the
          #: global menubar on macOS is supported. For example::

          #:    menu_map global "Actions::Launch something special" launch --hold --type=os-window sh -c "echo hello world"

          #: This will create a menu entry named "Launch something special" in
          #: an "Actions" menu in the macOS global menubar. Sub-menus can be
          #: created by adding more levels separated by ::.

          #: }}}
        ''
        # OS SPECIFIC
        ''
          #: OS specific tweaks {{{

          # wayland_titlebar_color system

          #: The color of the kitty window's titlebar on Wayland systems with
          #: client side window decorations such as GNOME. A value of system
          #: means to use the default system color, a value of background means
          #: to use the background color of the currently active window and
          #: finally you can use an arbitrary color, such as #12af59 or red.

          # macos_titlebar_color system

          #: The color of the kitty window's titlebar on macOS. A value of
          #: system means to use the default system color, light or dark can
          #: also be used to set it explicitly. A value of background means to
          #: use the background color of the currently active window and finally
          #: you can use an arbitrary color, such as #12af59 or red. WARNING:
          #: This option works by using a hack when arbitrary color (or
          #: background) is configured, as there is no proper Cocoa API for it.
          #: It sets the background color of the entire window and makes the
          #: titlebar transparent. As such it is incompatible with
          #: background_opacity. If you want to use both, you are probably
          #: better off just hiding the titlebar with hide_window_decorations.

          # macos_option_as_alt no

          #: Use the Option key as an Alt key on macOS. With this set to no,
          #: kitty will use the macOS native Option+Key to enter Unicode
          #: character behavior. This will break any Alt+Key keyboard shortcuts
          #: in your terminal programs, but you can use the macOS Unicode input
          #: technique. You can use the values: left, right or both to use only
          #: the left, right or both Option keys as Alt, instead. Note that
          #: kitty itself always treats Option the same as Alt. This means you
          #: cannot use this option to configure different kitty shortcuts for
          #: Option+Key vs. Alt+Key. Also, any kitty shortcuts using
          #: Option/Alt+Key will take priority, so that any such key presses
          #: will not be passed to terminal programs running inside kitty.
          #: Changing this option by reloading the config is not supported.

          # macos_hide_from_tasks no

          #: Hide the kitty window from running tasks on macOS (⌘+Tab and the
          #: Dock). Changing this option by reloading the config is not
          #: supported.

          # macos_quit_when_last_window_closed no

          #: Have kitty quit when all the top-level windows are closed on macOS.
          #: By default, kitty will stay running, even with no open windows, as
          #: is the expected behavior on macOS.

          # macos_window_resizable yes

          #: Disable this if you want kitty top-level OS windows to not be
          #: resizable on macOS.

          # macos_thicken_font 0

          #: Draw an extra border around the font with the given width, to
          #: increase legibility at small font sizes on macOS. For example, a
          #: value of 0.75 will result in rendering that looks similar to sub-
          #: pixel antialiasing at common font sizes. Note that in modern kitty,
          #: this option is obsolete (although still supported). Consider using
          #: text_composition_strategy instead.

          # macos_traditional_fullscreen no

          #: Use the macOS traditional full-screen transition, that is faster,
          #: but less pretty.

          # macos_show_window_title_in all

          #: Control where the window title is displayed on macOS. A value of
          #: window will show the title of the currently active window at the
          #: top of the macOS window. A value of menubar will show the title of
          #: the currently active window in the macOS global menu bar, making
          #: use of otherwise wasted space. A value of all will show the title
          #: in both places, and none hides the title. See
          #: macos_menubar_title_max_length for how to control the length of the
          #: title in the menu bar.

          # macos_menubar_title_max_length 0

          #: The maximum number of characters from the window title to show in
          #: the macOS global menu bar. Values less than one means that there is
          #: no maximum limit.

          # macos_custom_beam_cursor no

          #: Use a custom mouse cursor for macOS that is easier to see on both
          #: light and dark backgrounds. Nowadays, the default macOS cursor
          #: already comes with a white border. WARNING: this might make your
          #: mouse cursor invisible on dual GPU machines. Changing this option
          #: by reloading the config is not supported.

          # macos_colorspace srgb

          #: The colorspace in which to interpret terminal colors. The default
          #: of srgb will cause colors to match those seen in web browsers. The
          #: value of default will use whatever the native colorspace of the
          #: display is. The value of displayp3 will use Apple's special
          #: snowflake display P3 color space, which will result in over
          #: saturated (brighter) colors with some color shift. Reloading
          #: configuration will change this value only for newly created OS
          #: windows.

          # linux_display_server auto

          #: Choose between Wayland and X11 backends. By default, an appropriate
          #: backend based on the system state is chosen automatically. Set it
          #: to x11 or wayland to force the choice. Changing this option by
          #: reloading the config is not supported.

          #: }}}
        ''
        #--------------------------------------------------------
        # KEYBINDINGS
        #--------------------------------------------------------
        ''
          #: Keyboard shortcuts {{{

          #: Keys are identified simply by their lowercase Unicode characters.
          #: For example: a for the A key, [ for the left square bracket key,
          #: etc. For functional keys, such as Enter or Escape, the names are
          #: present at Functional key definitions
          #: <https://sw.kovidgoyal.net/kitty/keyboard-protocol/#functional>.
          #: For modifier keys, the names are ctrl (control, ⌃), shift (⇧), alt
          #: (opt, option, ⌥), super (cmd, command, ⌘). See also: GLFW mods
          #: <https://www.glfw.org/docs/latest/group__mods.html>

          #: On Linux you can also use XKB key names to bind keys that are not
          #: supported by GLFW. See XKB keys
          #: <https://github.com/xkbcommon/libxkbcommon/blob/master/include/xkbcommon/xkbcommon-
          #: keysyms.h> for a list of key names. The name to use is the part
          #: after the XKB_KEY_ prefix. Note that you can only use an XKB key
          #: name for keys that are not known as GLFW keys.

          #: Finally, you can use raw system key codes to map keys, again only
          #: for keys that are not known as GLFW keys. To see the system key
          #: code for a key, start kitty with the kitty --debug-input option,
          #: kitty will output some debug text for every key event. In that text
          #: look for native_code, the value of that becomes the key name in the
          #: shortcut. For example:

          #: .. code-block:: none

          #:     on_key_input: glfw key: 0x61 native_code: 0x61 action: PRESS mods: none text: 'a'

          #: Here, the key name for the A key is 0x61 and you can use it with::

          #:     map ctrl+0x61 something

          #: to map Ctrl+A to something.

          #: You can use the special action no_op to unmap a keyboard shortcut
          #: that is assigned in the default configuration::

          #:     map kitty_mod+space no_op

          #: If you would like kitty to completely ignore a key event, not even
          #: sending it to the program running in the terminal, map it to
          #: discard_event::

          #:     map kitty_mod+f1 discard_event

          #: You can combine multiple actions to be triggered by a single
          #: shortcut with combine action, using the syntax below::

          #:     map key combine <separator> action1 <separator> action2 <separator> action3 ...

          #: For example::

          #:     map kitty_mod+e combine : new_window : next_layout

          #: This will create a new window and switch to the next available
          #: layout.

          #: You can use multi-key shortcuts with the syntax shown below::

          #:     map key1>key2>key3 action

          #: For example::

          #:     map ctrl+f>2 set_font_size 20

          #: The full list of actions that can be mapped to key presses is
          #: available here <https://sw.kovidgoyal.net/kitty/actions/>.

          # kitty_mod ctrl+shift

          #: Special modifier key alias for default shortcuts. You can change
          #: the value of this option to alter all default shortcuts that use
          #: kitty_mod.

          # clear_all_shortcuts no

          #: Remove all shortcut definitions up to this point. Useful, for
          #: instance, to remove the default shortcuts.

          # action_alias

          #: E.g. action_alias launch_tab launch --type=tab --cwd=current

          #: Define action aliases to avoid repeating the same options in
          #: multiple mappings. Aliases can be defined for any action and will
          #: be expanded recursively. For example, the above alias allows you to
          #: create mappings to launch a new tab in the current working
          #: directory without duplication::

          #:     map f1 launch_tab vim
          #:     map f2 launch_tab emacs

          #: Similarly, to alias kitten invocation::

          #:     action_alias hints kitten hints --hints-offset=0

          # kitten_alias

          #: E.g. kitten_alias hints hints --hints-offset=0

          #: Like action_alias above, but specifically for kittens. Generally,
          #: prefer to use action_alias. This option is a legacy version,
          #: present for backwards compatibility. It causes all invocations of
          #: the aliased kitten to be substituted. So the example above will
          #: cause all invocations of the hints kitten to have the --hints-
          #: offset=0 option applied.
        ''
        ## CLIPBOARD
        ''
          #: Clipboard {{{

          #: Copy to clipboard

          # map kitty_mod+c copy_to_clipboard
          # map cmd+c       copy_to_clipboard

          #::  There is also a copy_or_interrupt action that can be optionally
          #::  mapped to Ctrl+C. It will copy only if there is a selection and
          #::  send an interrupt otherwise. Similarly,
          #::  copy_and_clear_or_interrupt will copy and clear the selection or
          #::  send an interrupt if there is no selection.

          #: Paste from clipboard

          # map kitty_mod+v paste_from_clipboard
          # map cmd+v       paste_from_clipboard

          #: Paste from selection

          # map kitty_mod+s  paste_from_selection
          # map shift+insert paste_from_selection

          #: Pass selection to program

          # map kitty_mod+o pass_selection_to_program
        ''
        # Pass selection to selected programs
        ''
          # pass to selected programs with the default binding switched to a chord prefix
          map kitty_mod+o>f pass_selection_to_program firefox
          map kitty_mod+o>c pass_selection_to_program code
          map kitty_mod+o>v new_tab nvim @selection
          # the original mapping, which lets the system decide what to do with it
          map kitty_mod+o>o pass_selection_to_program
        ''
        ''
          #::  You can also pass the contents of the current selection to any
          #::  program with pass_selection_to_program. By default, the system's
          #::  open program is used, but you can specify your own, the selection
          #::  will be passed as a command line argument to the program. For
          #::  example::

          #::      map kitty_mod+o pass_selection_to_program firefox

          #::  You can pass the current selection to a terminal program running
          #::  in a new kitty window, by using the @selection placeholder::

          #::      map kitty_mod+y new_window less @selection

          #: }}}
        ''
        ## SCROLLING
        ''
          #: Scrolling {{{

          #: Scroll line up

          # map kitty_mod+up    scroll_line_up
          # map kitty_mod+k     scroll_line_up
          # map opt+cmd+page_up scroll_line_up
          # map cmd+up          scroll_line_up

          #: Scroll line down

          # map kitty_mod+down    scroll_line_down
          # map kitty_mod+j       scroll_line_down
          # map opt+cmd+page_down scroll_line_down
          # map cmd+down          scroll_line_down

          #: Scroll page up

          # map kitty_mod+page_up scroll_page_up
          # map cmd+page_up       scroll_page_up

          #: Scroll page down

          # map kitty_mod+page_down scroll_page_down
          # map cmd+page_down       scroll_page_down

          #: Scroll to top

          # map kitty_mod+home scroll_home
          # map cmd+home       scroll_home

          #: Scroll to bottom

          # map kitty_mod+end scroll_end
          # map cmd+end       scroll_end

          #: Scroll to previous shell prompt

          # map kitty_mod+z scroll_to_prompt -1

          #::  Use a parameter of 0 for scroll_to_prompt to scroll to the last
          #::  jumped to or the last clicked position. Requires shell
          #::  integration <https://sw.kovidgoyal.net/kitty/shell-integration/>
          #::  to work.

          #: Scroll to next shell prompt

          # map kitty_mod+x scroll_to_prompt 1

          #: Browse scrollback buffer in pager

          # map kitty_mod+h show_scrollback
        ''
        # scrollback history in split
        ''
        map kitty_mod+alt+h launch --stdin-source=@screen_scrollback --stdin-add-formatting --type=window less +G -R +@input-line-number
        ''
        ''
          #::  You can pipe the contents of the current screen and history
          #::  buffer as STDIN to an arbitrary program using launch --stdin-
          #::  source. For example, the following opens the scrollback buffer in
          #::  less in an overlay window::

          #::      map f1 launch --stdin-source=@screen_scrollback --stdin-add-formatting --type=overlay less +G -R

          #::  For more details on piping screen and buffer contents to external
          #::  programs, see launch <https://sw.kovidgoyal.net/kitty/launch/>.

          #: Browse output of the last shell command in pager

          # map kitty_mod+g show_last_command_output
        ''
        # last command output, output in split, last visited command output, output in split
        ''
          # last command output in an overlay (remapped from default)
          map kitty_mod+g>g show_last_command_output
          # last command output in a split
          map kitty_mod+g>s launch --stdin-source=@screen_scrollback --stdin-add-formatting --type=window less +G -R
          # last visited command
          map kitty_mod+g>l>l show_last_visited_command_output
          map kitty_mod+g>l>s launch --stdin-source=@last_visited_cmd_output --stdin-add-formatting --type=window less +G -R
        ''
        ''
          #::  You can also define additional shortcuts to get the command
          #::  output. For example, to get the first command output on screen::

          #::      map f1 show_first_command_output_on_screen

          #::  To get the command output that was last accessed by a keyboard
          #::  action or mouse action::

          #::      map f1 show_last_visited_command_output

          #::  You can pipe the output of the last command run in the shell
          #::  using the launch action. For example, the following opens the
          #::  output in less in an overlay window::

          #::      map f1 launch --stdin-source=@last_cmd_output --stdin-add-formatting --type=overlay less +G -R

          #::  To get the output of the first command on the screen, use
          #::  @first_cmd_output_on_screen. To get the output of the last jumped
          #::  to command, use @last_visited_cmd_output.

          #::  Requires shell integration
          #::  <https://sw.kovidgoyal.net/kitty/shell-integration/> to work.

          #: }}}
        ''
        ## WINDOW MGMT
        ''
          #: Window management {{{

          #: New window

          # map kitty_mod+enter new_window
          # map cmd+enter       new_window
        ''
        # split, w/ and w/o duplicate current
        ''
          # Default to duplicating the current.
          # WARNING: If not in Splits layout, the remap of kitty_mod+enter is ignored and a split is immediately generated that isn't a duplicate
          # WARNING: it's not possible to duplicate env after window creation, so don't bother with --copy-env
          # WARNING: neither --copy-cmdline or --copy-env can work when SSH'd into remote systems, so don't use it.
          # Hsplit and Vsplit are backwards of what feels natural (split along axis)
          map kitty_mod+enter>h launch --type=window --cwd=current --location=vsplit
          map kitty_mod+enter>v launch --type=window --cwd=current --location=hsplit
          # allow clean window opening
          map kitty_mod+alt+enter>h launch --type=window --location=vsplit
          map kitty_mod+alt+enter>v launch --type=window --location=hsplit
        ''
        ''
          #::  You can open a new kitty window running an arbitrary program, for
          #::  example::

          #::      map kitty_mod+y launch mutt

          #::  You can open a new window with the current working directory set
          #::  to the working directory of the current window using::

          #::      map ctrl+alt+enter launch --cwd=current

          #::  You can open a new window that is allowed to control kitty via
          #::  the kitty remote control facility with launch --allow-remote-
          #::  control. Any programs running in that window will be allowed to
          #::  control kitty. For example::

          #::      map ctrl+enter launch --allow-remote-control some_program

          #::  You can open a new window next to the currently active window or
          #::  as the first window, with::

          #::      map ctrl+n launch --location=neighbor
          #::      map ctrl+f launch --location=first

          #::  For more details, see launch
          #::  <https://sw.kovidgoyal.net/kitty/launch/>.

          #: New OS window

          # map kitty_mod+n new_os_window
          # map cmd+n       new_os_window

          #::  Works like new_window above, except that it opens a top-level OS
          #::  window. In particular you can use new_os_window_with_cwd to open
          #::  a window with the current working directory.

          #: Close window

          # map kitty_mod+w close_window
          # map shift+cmd+d close_window

          #: Next window

          # map kitty_mod+] next_window

          #: Previous window

          # map kitty_mod+[ previous_window

          #: Move window forward

          # map kitty_mod+f move_window_forward

          #: Move window backward

          # map kitty_mod+b move_window_backward

          #: Move window to top

          # map kitty_mod+` move_window_to_top

          #: Start resizing window

          # map kitty_mod+r start_resizing_window
          # map cmd+r       start_resizing_window

          #: First window

          # map kitty_mod+1 first_window
          # map cmd+1       first_window

          #: Second window

          # map kitty_mod+2 second_window
          # map cmd+2       second_window

          #: Third window

          # map kitty_mod+3 third_window
          # map cmd+3       third_window

          #: Fourth window

          # map kitty_mod+4 fourth_window
          # map cmd+4       fourth_window

          #: Fifth window

          # map kitty_mod+5 fifth_window
          # map cmd+5       fifth_window

          #: Sixth window

          # map kitty_mod+6 sixth_window
          # map cmd+6       sixth_window

          #: Seventh window

          # map kitty_mod+7 seventh_window
          # map cmd+7       seventh_window

          #: Eighth window

          # map kitty_mod+8 eighth_window
          # map cmd+8       eighth_window

          #: Ninth window

          # map kitty_mod+9 ninth_window
          # map cmd+9       ninth_window

          #: Tenth window

          # map kitty_mod+0 tenth_window
        ''
        # Use Ergo-style Window navigation
        ''
          # Ergo-style navigation among windows in Splits mode.
          # WARNING: only works while in Splits mode.
          map kitty_mod+alt+i neighboring_window up
          map kitty_mod+alt+k neighboring_window down
          map kitty_mod+alt+j neighboring_window left
          map kitty_mod+alt+l neighboring_window right
        ''
        ''
          #: Visually select and focus window

          # map kitty_mod+f7 focus_visible_window

          #::  Display overlay numbers and alphabets on the window, and switch
          #::  the focus to the window when you press the key. When there are
          #::  only two windows, the focus will be switched directly without
          #::  displaying the overlay. You can change the overlay characters and
          #::  their order with option visual_window_select_characters.

          #: Visually swap window with another

          # map kitty_mod+f8 swap_with_window

          #::  Works like focus_visible_window above, but swaps the window.

        ''
        # Window jump from visual number
        ''
          # Puts number overlays on all windows and waits for a key to pick which one to jump to.
          # Automatically jumps to the only other one when only 2 windows are present.
          map kitty_mod+; focus_visible_window

          # jump to last focused window
          map kitty_mod+alt+; nth_window -1

          # swap the window with another
          map kitty_mod+' swap_with_window
        ''
        ''
          #: }}}
        ''
        ## TAB MGMT
        ''
          #: Tab management {{{

          #: Next tab

          # map kitty_mod+right next_tab
          # map shift+cmd+]     next_tab
          # map ctrl+tab        next_tab

          #: Previous tab

          # map kitty_mod+left previous_tab
          # map shift+cmd+[    previous_tab
          # map ctrl+shift+tab previous_tab

          # explicitly unmap these so we can use them in zsh
          map ctrl+shift+right no_op
          map ctrl+shift+left no_op

          #: New tab

          # map kitty_mod+t new_tab
          # map cmd+t       new_tab

          #: Close tab

          # map kitty_mod+q close_tab
          # map cmd+w       close_tab

          #: Close OS window

          # map shift+cmd+w close_os_window

          #: Move tab forward

          # map kitty_mod+. move_tab_forward

          #: Move tab backward

          # map kitty_mod+, move_tab_backward

          #: Set tab title

          # map kitty_mod+alt+t set_tab_title
          # map shift+cmd+i     set_tab_title

          #: You can also create shortcuts to go to specific tabs, with 1 being
          #: the first tab, 2 the second tab and -1 being the previously active
          #: tab, and any number larger than the last tab being the last tab::

          #:     map ctrl+alt+1 goto_tab 1
          #:     map ctrl+alt+2 goto_tab 2

          # remap the ctrl+shift+alt+t to a prefix
          map kitty_mod+alt+t>n set_tab_title
          map kitty_mod+alt+t>k close_tab
          map kitty_mod+alt+t>1 goto_tab 1
          map kitty_mod+alt+t>2 goto_tab 2
          map kitty_mod+alt+t>3 goto_tab 3
          map kitty_mod+alt+t>4 goto_tab 4
          map kitty_mod+alt+t>5 goto_tab 5
          map kitty_mod+alt+t>6 goto_tab 6
          map kitty_mod+alt+t>7 goto_tab 7
          map kitty_mod+alt+t>8 goto_tab 8
          map kitty_mod+alt+t>9 goto_tab 9

          map alt+1 goto_tab 1
          map alt+2 goto_tab 2
          map alt+3 goto_tab 3
          map alt+4 goto_tab 4
          map alt+5 goto_tab 5
          map alt+6 goto_tab 6
          map alt+7 goto_tab 7
          map alt+8 goto_tab 8
          map alt+9 goto_tab 9

          #: Just as with new_window above, you can also pass the name of
          #: arbitrary commands to run when using new_tab and new_tab_with_cwd.
          #: Finally, if you want the new tab to open next to the current tab
          #: rather than at the end of the tabs list, use::

          #:     map ctrl+t new_tab !neighbor [optional cmd to run]
          #: }}}
        ''
        ## LAYOUT MGMT
        ''
          #: Layout management {{{

          #: Next layout

          # map kitty_mod+l next_layout


          #: You can also create shortcuts to switch to specific layouts::

          #:     map ctrl+alt+t goto_layout tall
          #:     map ctrl+alt+s goto_layout stack

          #: Similarly, to switch back to the previous layout::

          #:     map ctrl+alt+p last_used_layout

          #: There is also a toggle_layout action that switches to the named
          #: layout or back to the previous layout if in the named layout.
          #: Useful to temporarily "zoom" the active window by switching to the
          #: stack layout::

          #:     map ctrl+alt+z toggle_layout stack
          #: }}}
        ''
        ## FONT SIZE
        ''
          #: Font sizes {{{

          #: You can change the font size for all top-level kitty OS windows at
          #: a time or only the current one.

          #: Increase font size

          # map kitty_mod+equal  change_font_size all +2.0
          # map kitty_mod+plus   change_font_size all +2.0
          # map kitty_mod+kp_add change_font_size all +2.0
          # map cmd+plus         change_font_size all +2.0
          # map cmd+equal        change_font_size all +2.0
          # map shift+cmd+equal  change_font_size all +2.0

          #: Decrease font size

          # map kitty_mod+minus       change_font_size all -2.0
          # map kitty_mod+kp_subtract change_font_size all -2.0
          # map cmd+minus             change_font_size all -2.0
          # map shift+cmd+minus       change_font_size all -2.0

          #: Reset font size

          # map kitty_mod+backspace change_font_size all 0
          # map cmd+0               change_font_size all 0


          #: To setup shortcuts for specific font sizes::

          #:     map kitty_mod+f6 change_font_size all 10.0

          #: To setup shortcuts to change only the current OS window's font
          #: size::

          #:     map kitty_mod+f6 change_font_size current 10.0
          #: }}}
        ''
        ## SELECT AND ACT ON VISIBLE TEXT
        ''
          #: Select and act on visible text {{{

          #: Use the hints kitten to select text and either pass it to an
          #: external program or insert it into the terminal or copy it to the
          #: clipboard.

          #: Open URL

          # map kitty_mod+e open_url_with_hints

          #::  Open a currently visible URL using the keyboard. The program used
          #::  to open the URL is specified in open_url_with.

          #: Insert selected path

          # map kitty_mod+p>f kitten hints --type path --program -

          #::  Select a path/filename and insert it into the terminal. Useful,
          #::  for instance to run git commands on a filename output from a
          #::  previous git command.

          #: Open selected path

          # map kitty_mod+p>shift+f kitten hints --type path

          #::  Select a path/filename and open it with the default open program.

          #: Insert selected line

          # map kitty_mod+p>l kitten hints --type line --program -

          #::  Select a line of text and insert it into the terminal. Useful for
          #::  the output of things like: `ls -1`.

          #: Insert selected word

          # map kitty_mod+p>w kitten hints --type word --program -

          #::  Select words and insert into terminal.

          #: Insert selected hash

          # map kitty_mod+p>h kitten hints --type hash --program -

          #::  Select something that looks like a hash and insert it into the
          #::  terminal. Useful with git, which uses SHA1 hashes to identify
          #::  commits.

          #: Open the selected file at the selected line

          # map kitty_mod+p>n kitten hints --type linenum

          #::  Select something that looks like filename:linenum and open it in
          #::  vim at the specified line number.

          #: Open the selected hyperlink

          # map kitty_mod+p>y kitten hints --type hyperlink

          #::  Select a hyperlink (i.e. a URL that has been marked as such by
          #::  the terminal program, for example, by `ls --hyperlink=auto`).


          #: The hints kitten has many more modes of operation that you can map
          #: to different shortcuts. For a full description see hints kitten
          #: <https://sw.kovidgoyal.net/kitty/kittens/hints/>.

          #-------
          # copy to clipboard only, so it can be used from the scrollback history buffer too.
          # allow multi-select until escape is hit

          # paths/files, also works for container names with tags
          map kitty_mod+p>f kitten hints --type path --program @ --multiple
          map kitty_mod+p>p kitten hints --type path --program @ --multiple
          # hash/digest
          map kitty_mod+p>h kitten hints --type hash --program @ --multiple
          # url
          map kitty_mod+p>u kitten hints --type url --program @ --multiple
          # ip
          map kitty_mod+p>i kitten hints --type ip --program @ --multiple
          # word
          map kitty_mod+p>w kitten hints --type word --program @ --multiple

          #: }}}
        ''
        ## MISC
        ''
          #: Miscellaneous {{{

          #: Show documentation

          # map kitty_mod+f1 show_kitty_doc overview

          #: Toggle fullscreen

          # map kitty_mod+f11 toggle_fullscreen
          # map ctrl+cmd+f    toggle_fullscreen

          #: Toggle maximized

          # map kitty_mod+f10 toggle_maximized

          #: Toggle macOS secure keyboard entry

          # map opt+cmd+s toggle_macos_secure_keyboard_entry

          #: Unicode input

          # map kitty_mod+u    kitten unicode_input
          # map ctrl+cmd+space kitten unicode_input

          #: Edit config file

          # map kitty_mod+f2 edit_config_file
          # map cmd+,        edit_config_file

          #: Open the kitty command shell

          # map kitty_mod+escape kitty_shell window

          #::  Open the kitty shell in a new window / tab / overlay / os_window
          #::  to control kitty using commands.

          #: Increase background opacity

          # map kitty_mod+a>m set_background_opacity +0.1

          #: Decrease background opacity

          # map kitty_mod+a>l set_background_opacity -0.1

          #: Make background fully opaque

          # map kitty_mod+a>1 set_background_opacity 1

          #: Reset background opacity

          # map kitty_mod+a>d set_background_opacity default

          #: Reset the terminal

          # map kitty_mod+delete clear_terminal reset active
          # map opt+cmd+r        clear_terminal reset active

          #::  You can create shortcuts to clear/reset the terminal. For
          #::  example::

          #::      # Reset the terminal
          #::      map f1 clear_terminal reset active
          #::      # Clear the terminal screen by erasing all contents
          #::      map f1 clear_terminal clear active
          #::      # Clear the terminal scrollback by erasing it
          #::      map f1 clear_terminal scrollback active
          #::      # Scroll the contents of the screen into the scrollback
          #::      map f1 clear_terminal scroll active
          #::      # Clear everything up to the line with the cursor
          #::      map f1 clear_terminal to_cursor active

          #::  If you want to operate on all kitty windows instead of just the
          #::  current one, use all instead of active.

          #::  Some useful functions that can be defined in the shell rc files
          #::  to perform various kinds of clearing of the current window:

          #::  .. code-block:: sh

          #::      clear-only-screen() {
          #::          printf "\e[H\e[2J"
          #::      }

          #::      clear-screen-and-scrollback() {
          #::          printf "\e[H\e[3J"
          #::      }

          #::      clear-screen-saving-contents-in-scrollback() {
          #::          printf "\e[H\e[22J"
          #::      }

          #::  For instance, using these escape codes, it is possible to remap
          #::  Ctrl+L to both scroll the current screen contents into the
          #::  scrollback buffer and clear the screen, instead of just clearing
          #::  the screen. For ZSH, in ~/.zshrc, add:

          #::  .. code-block:: zsh

          #::      ctrl_l() {
          #::          builtin print -rn -- $'\r\e[0J\e[H\e[22J' >"$TTY"
          #::          builtin zle .reset-prompt
          #::          builtin zle -R
          #::      }
          #::      zle -N ctrl_l
          #::      bindkey '^l' ctrl_l

          #: Clear up to cursor line

          # map cmd+k clear_terminal to_cursor active

          #: Reload kitty.conf

          # map kitty_mod+f5 load_config_file
          # map ctrl+cmd+,   load_config_file

          #::  Reload kitty.conf, applying any changes since the last time it
          #::  was loaded. Note that a handful of options cannot be dynamically
          #::  changed and require a full restart of kitty. Particularly, when
          #::  changing shortcuts for actions located on the macOS global menu
          #::  bar, a full restart is needed. You can also map a keybinding to
          #::  load a different config file, for example::

          #::      map f5 load_config /path/to/alternative/kitty.conf

          #::  Note that all options from the original kitty.conf are discarded,
          #::  in other words the new configuration *replace* the old ones.

          #: Debug kitty configuration

          # map kitty_mod+f6 debug_config
          # map opt+cmd+,    debug_config

          #::  Show details about exactly what configuration kitty is running
          #::  with and its host environment. Useful for debugging issues.

          #: Send arbitrary text on key presses

          #::  E.g. map ctrl+shift+alt+h send_text all Hello World

          #::  You can tell kitty to send arbitrary (UTF-8) encoded text to the
          #::  client program when pressing specified shortcut keys. For
          #::  example::

          #::      map ctrl+alt+a send_text all Special text

          #::  This will send "Special text" when you press the Ctrl+Alt+A key
          #::  combination. The text to be sent decodes ANSI C escapes
          #::  <https://www.gnu.org/software/bash/manual/html_node/ANSI_002dC-
          #::  Quoting.html> so you can use escapes like \e to send control
          #::  codes or \u21fb to send Unicode characters (or you can just input
          #::  the Unicode characters directly as UTF-8 text). You can use
          #::  `kitten show_key` to get the key escape codes you want to
          #::  emulate.

          #::  The first argument to send_text is the keyboard modes in which to
          #::  activate the shortcut. The possible values are normal,
          #::  application, kitty or a comma separated combination of them. The
          #::  modes normal and application refer to the DECCKM cursor key mode
          #::  for terminals, and kitty refers to the kitty extended keyboard
          #::  protocol. The special value all means all of them.

          #::  Some more examples::

          #::      # Output a word and move the cursor to the start of the line (like typing and pressing Home)
          #::      map ctrl+alt+a send_text normal Word\e[H
          #::      map ctrl+alt+a send_text application Word\eOH
          #::      # Run a command at a shell prompt (like typing the command and pressing Enter)
          #::      map ctrl+alt+a send_text normal,application some command with arguments\r

          #: Open kitty Website

          # map shift+cmd+/ open_url https://sw.kovidgoyal.net/kitty/

          #: Hide macOS kitty application

          # map cmd+h hide_macos_app

          #: Hide macOS other applications

          # map opt+cmd+h hide_macos_other_apps

          #: Minimize macOS window

          # map cmd+m minimize_macos_window

          #: Quit kitty

          # map cmd+q quit

          #: }}}

          #: }}}
        ''
        # All other Nix options come before this one, and home-manager adds prefix comments.
        # So putting this last will put it last in the file since vim will only pick it up if it's first or last
        ''

          # vim:fileencoding=utf-8:foldmethod=marker
        ''
      ];
    };
  };
}

# vim: ts=2:sw=2:expandtab:syntax=nix
