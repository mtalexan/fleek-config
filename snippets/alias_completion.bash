# Sets up so aliases can be tab completed.
#
# Must come after all aliases are defined.
# No arguments required.


# Automatically add completion for all aliases to commands having completion functions
# Must be done after all alias and completion setup!
function alias_completion {
    local namespace="alias_completion"

    # parse function based completion definitions, where capture group 2 => function and 3 => trigger
    local compl_regex='complete( +[^ ]+)* -F ([^ ]+) ("[^"]+"|[^ ]+)'
    # parse alias definitions, where capture group 1 => trigger, 2 => command, 3 => command arguments
    local alias_regex="alias ([^=]+)='(\"[^\"]+\"|[^ ]+)(( +[^ ]+)*)'"

    # create array of function completion triggers, keeping multi-word triggers together
    eval "local completions=($(complete -p | sed -Ene "/${compl_regex}/s//'\3'/p"))"
    (( ${#completions[@]} == 0 )) && return 0

    # create temporary file for wrapper functions and completions
    rm -f "/tmp/${namespace}-*.tmp" # preliminary cleanup
    local tmp_file
    tmp_file="$(mktemp "/tmp/tmp-${namespace}-${RANDOM}.XXXXXXXXXX")" || return 1

    # read in "<alias> '<aliased command>' '<command args>'" lines from defined aliases
    local line
    while read line; do
        eval "local alias_tokens; alias_tokens=(${line})" 2>/dev/null || continue # some alias arg patterns cause an eval parse error
        local alias_name="${alias_tokens[0]}"
        local alias_cmd="${alias_tokens[1]}"
        local alias_args="${alias_tokens[2]# }"

        # skip aliases to pipes, boolan control structures and other command lists
        # (leveraging that eval errs out if $alias_args contains unquoted shell metacharacters)
        eval "local alias_arg_words; alias_arg_words=(${alias_args})" 2>/dev/null || continue

        # skip alias if there is no completion function triggered by the aliased command
        [[ " ${completions[*]} " =~ " ${alias_cmd} " ]] || continue
        local new_completion="$(complete -p "${alias_cmd}")"

        # create a wrapper inserting the alias arguments if any
        if [[ -n ${alias_args} ]]; then
            local compl_func="${new_completion/#* -F /}"
            compl_func="${compl_func%% *}"
            # avoid recursive call loops by ignoring our own functions
            if [[ "${compl_func#_${namespace}::}" == ${compl_func} ]]; then
                local compl_wrapper="_${namespace}::${alias_name}"
                    echo "function ${compl_wrapper} {
                        (( COMP_CWORD += ${#alias_arg_words[@]} ))
                        COMP_WORDS=(${alias_cmd} ${alias_args} \${COMP_WORDS[@]:1})
                        (( COMP_POINT -= \${#COMP_LINE} ))
                        COMP_LINE=\${COMP_LINE/${alias_name}/${alias_cmd} ${alias_args}}
                        (( COMP_POINT += \${#COMP_LINE} ))
                        ${compl_func}
                    }" >> "${tmp_file}"
                    new_completion="${new_completion/ -F ${compl_func} / -F ${compl_wrapper} }"
            fi
        fi

        # replace completion trigger by alias
        new_completion="${new_completion% *} ${alias_name}"
        echo "${new_completion}" >> "${tmp_file}"
    done < <(alias -p | sed -Ene "s/${alias_regex}/\1 '\2' '\3'/p")
    source "${tmp_file}" && rm -f "${tmp_file}"
};
alias_completion
