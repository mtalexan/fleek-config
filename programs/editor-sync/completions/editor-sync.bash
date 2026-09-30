# bash completion for editor-sync
_editor_sync() {
  local cur prev words cword
  COMPREPLY=()
  # '@' and ':' are in COMP_WORDBREAKS, which splits user@host in COMP_WORDS.
  # Re-split the line on whitespace instead; no editor-sync argument contains a space.
  local line="${COMP_LINE:0:COMP_POINT}"
  read -r -a words <<< "${line}"
  if [[ "${line}" == *[[:space:]] ]]; then
    words+=( "" )
  fi
  cword=$(( ${#words[@]} - 1 ))
  cur="${words[cword]}"
  prev="${words[cword-1]}"

  local cmds="render import extensions-sync move"
  local editors="vscode cursor"
  local kinds="settings keybindings snippets extensions"
  local hostdir="${FLEEK_CONFIG_DIR:-$HOME/.local/share/fleek}/chezmoi/.editor-config/hosts"
  local default_host
  default_host="$(uname -n)"
  default_host="$(id -un)@${default_host%%.*}"
  default_host="${default_host,,}"
  local hosts="${default_host}"
  local layers="common vscode cursor local/common local/vscode local/cursor"
  local host
  if [[ -d "${hostdir}" ]]; then
    for host in "${hostdir}"/*; do
      [[ -d "${host}" ]] || continue
      host="${host##*/}"
      [[ " ${hosts} " == *" ${host} "* ]] || hosts+=" ${host}"
    done
  fi
  for host in ${hosts}; do
    layers+=" host/${host}/common host/${host}/vscode host/${host}/cursor"
  done

  _editor_sync_reply() {
    COMPREPLY=( $(compgen -W "$1" -- "${cur}") )
    # Strip the part of cur that readline treats as a separate word.
    if [[ "${cur}" == *[@:=]* && "${COMP_WORDBREAKS}" == *[@:=]* ]]; then
      local prefix="${cur%"${cur##*[@:=]}"}"
      COMPREPLY=( "${COMPREPLY[@]#"${prefix}"}" )
    fi
  }

  if [[ ${cword} -eq 1 ]]; then
    _editor_sync_reply "${cmds}"
    return 0
  fi

  case "${prev}" in
    --host)
      _editor_sync_reply "${hosts}"
      return 0
      ;;
    --source)
      COMPREPLY=( $(compgen -d -- "${cur}") )
      return 0
      ;;
    --from|--to)
      _editor_sync_reply "${layers}"
      return 0
      ;;
    --snippet)
      return 0
      ;;
  esac

  local cmd="${words[1]}"
  local opts="--host --source"
  [[ "${cmd}" == "move" ]] && opts+=" --from --to --snippet"
  if [[ "${cur}" == -* ]]; then
    _editor_sync_reply "${opts}"
    return 0
  fi

  # Positional words already typed after the subcommand, skipping options and their values.
  local -a pos=()
  local i
  for (( i = 2; i < cword; i++ )); do
    case "${words[i]}" in
      --host|--source|--from|--to|--snippet) (( i++ )) ;;
      -*) ;;
      *) pos+=( "${words[i]}" ) ;;
    esac
  done

  case "${cmd}" in
    render)
      case ${#pos[@]} in
        0) _editor_sync_reply "${editors}" ;;
        1) _editor_sync_reply "settings keybindings snippets" ;;
      esac
      ;;
    import)
      local left="" have_editor=0 have_kind=0 word
      for word in "${pos[@]}"; do
        [[ " ${editors} " == *" ${word} "* ]] && have_editor=1
        [[ " ${kinds} " == *" ${word} "* ]] && have_kind=1
      done
      (( have_editor )) || left+=" ${editors}"
      (( have_kind )) || left+=" ${kinds}"
      _editor_sync_reply "${left}"
      ;;
    extensions-sync)
      case ${#pos[@]} in
        0) _editor_sync_reply "${editors}" ;;
        1) COMPREPLY=( $(compgen -c -- "${cur}") ) ;;
      esac
      ;;
    move)
      [[ ${#pos[@]} -eq 0 ]] && _editor_sync_reply "${kinds}"
      ;;
  esac
}
complete -F _editor_sync editor-sync
