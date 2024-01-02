# This file should be sourced from your .bashrc file.
#
# Copyright 2014-2020 Simon Edwards <simon@simonzone.com>
#
# This source code is licensed under the MIT license which is detailed in the LICENSE.txt file.
#

# Early-out in case this has been sourced and enabled already
# https://github.com/sedwards2009/extraterm/pull/148

isfunction () {
    type $1 2> /dev/null | head -n1 | grep "$1 is a function" > /dev/null
}

if ( isfunction "postexec"            ); then return 0; fi
if ( isfunction "preexec"             ); then return 0; fi
if ( isfunction "preexec_invoke_exec" ); then return 0; fi

# Early-out if LC_EXTRATERM_COOKIE is not set
if [ -z "$LC_EXTRATERM_COOKIE" ]; then return 0; fi
if [[ "$TERM" =~ 'screen' ]]; then
    unset -v LC_EXTRATERM_COOKIE
    return 0
fi

if [ ! -t 0 ] ; then
    # Not an interactive terminal
    unset -v LC_EXTRATERM_COOKIE
    return 0
fi

echo "Setting up Extraterm support."

# Put our enhanced commands at the start of the PATH.
filedir=`dirname "$BASH_SOURCE"`
if [ ${filedir:0:1} != "/" ]
then
    filedir="$PWD/$filedir"
fi

export PATH="$filedir:$PATH"

export EXTRATERM_PREVIOUS_PROMPT_COMMAND=$PROMPT_COMMAND
extraterm_postexec () {
  echo -n -e "\033&${LC_EXTRATERM_COOKIE};3\007"
  echo -n $1
  echo -n -e "\000"
  if [ "$EXTRATERM_PREVIOUS_PROMPT_COMMAND" != "" ];
  then
      if [ "$EXTRATERM_PREVIOUS_PROMPT_COMMAND" != "extraterm_postexec \$?" ]; then
          $EXTRATERM_PREVIOUS_PROMPT_COMMAND
      fi
  fi
}

export PROMPT_COMMAND="extraterm_postexec \$?"

extraterm_preexec () {
    echo -n -e "\033&${LC_EXTRATERM_COOKIE};2;bash\007"
    echo -n $1
    echo -n -e "\000"
}

extraterm_preexec_invoke_exec () {
    [ -n "$COMP_LINE" ] && return                     # do nothing if completing
    [ "$BASH_COMMAND" = "$PROMPT_COMMAND" ] && return # don't cause a preexec for $PROMPT_COMMAND
    local this_command=`history 1`; # obtain the command from the history
    extraterm_preexec "$this_command"
}
trap 'extraterm_preexec_invoke_exec' DEBUG

# Look for Python 3 support.
if ! which python3 > /dev/null; then
    echo "Unable to find the Python3 executable!"
else
    alias from="exfrom.py"
    alias show="exshow.py"
fi
