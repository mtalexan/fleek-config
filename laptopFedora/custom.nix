{ pkgs, misc, ... }: {
  # FEEL FREE TO EDIT: This file is NOT managed by fleek. 

  home.shellAliases = {
    # end all aliases in a space so completion on arguments works for them
    
    # Flatpaks
    "code" = "flatpak run com.visualstudio.code ";
    "meld" = "flatpak run org.gnome.meld ";
    "flameshot" = "flatpak run org.flameshot.Flameshot ";
    "wireshark" = "flatpak run org.wireshark.Wireshark ";
  };

  programs.bash.initExtra = ''
    ######################################################################
    # Fedora default is to source /etc/bashrc, but this includes unconditional
    # overwrites of aliases and other undesirable things, so we reconstruct it
    # manually instead.
    ## Source global definitions
    #if [ -f /etc/bashrc ]; then
    #        . /etc/bashrc
    #fi

    # Nix
    if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
        . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
    fi
    # End Nix

    # Prevent doublesourcing
    if [ -z "$BASHRCSOURCED" ]; then
      BASHRCSOURCED="Y"

      if ! shopt -q login_shell ; then # We're not a login shell
        # Need to redefine pathmunge, it gets undefined at the end of /etc/profile
        pathmunge () {
          case ":$${PATH}:" in
            *:"$1":*)
              ;;
            *)
              if [ "$2" = "after" ] ; then
                PATH=$PATH:$1
              else
                PATH=$1:$PATH
              fi
          esac
        }

        # Set default umask for non-login shell only if it is set to 0
        [ `umask` -eq 0 ] && umask 022

        SHELL=/bin/bash
        # Only display echos from profile.d scripts if we are no login shell
        # and interactive - otherwise just process them to set envvars
        for i in /etc/profile.d/{bash_completion,colorgrep,colorxzgrep,colorzgrep,debuginfod,flatpak,gawk,lang,less,nix,PackageKit,toolbox,vte,which2}.sh; do
            if [ -r "$i" ]; then
                if [ "$PS1" ]; then
                    . "$i"
                else
                    . "$i" >/dev/null
                fi
            fi
        done

        unset i
        unset -f pathmunge
      fi
    fi

    # User specific environment
    if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
    then
        PATH="$HOME/.local/bin:$HOME/bin:$PATH"
    fi
    export PATH

    # Uncomment the following line if you don't like systemctl's auto-paging feature:
    # export SYSTEMD_PAGER=

    unset rc
    ######################################################################
  '';
 
}


# vim:sw=2:expandtab
