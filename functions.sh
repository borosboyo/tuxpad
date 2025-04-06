__compal__complete_alias () 
{ 
    local cmd="${COMP_WORDS[0]}";
    if (( __compal__refcnt == 0 )); then
        local i=0 j=0;
        for ((1; i <= $COMP_CWORD; i++ ))
        do
            for ((1; j <= ${#COMP_LINE}; j++ ))
            do
                [[ "${COMP_LINE:j}" == "${COMP_WORDS[i]}"* ]] && break;
            done;
            (( i == $COMP_CWORD )) && break;
            (( j += ${#COMP_WORDS[i]} ));
        done;
        if (( j <= $COMP_POINT )) && (( $COMP_POINT <= j + ${#COMP_WORDS[$COMP_CWORD]} )); then
            local ignore="$COMP_CWORD";
        else
            local ignore="";
        fi;
        __compal__expand_alias 0 "${#COMP_WORDS[@]}" "$ignore" 0;
    fi;
    (( __compal__refcnt++ ));
    __compal__delegate_in_context "$cmd";
    (( __compal__refcnt-- ))
}
__compal__complete_non_alias () 
{ 
    local cmd="${COMP_WORDS[0]}";
    local compcmd="${cmd##*/}";
    if alias "$compcmd" &> /dev/null; then
        __compal__delegate_in_context "$compcmd";
    else
        __compal__error "command is not an alias: $cmd";
    fi
}
__compal__debug () 
{ 
    echo;
    echo "#COMP_WORDS=${#COMP_WORDS[@]}";
    echo "COMP_WORDS=(";
    for x in "${COMP_WORDS[@]}";
    do
        echo "'$x'";
    done;
    echo ")";
    echo "COMP_CWORD=${COMP_CWORD}";
    echo "COMP_LINE='${COMP_LINE}'";
    echo "COMP_POINT=${COMP_POINT}";
    echo
}
__compal__debug_raw_vanilla_cspecs () 
{ 
    for x in "${!__compal__raw_vanilla_cspecs[@]}";
    do
        echo "$x";
    done
}
__compal__debug_split_cmd_line () 
{ 
    local str="$1";
    __compal__split_cmd_line "$str";
    for x in "${__compal__retval[@]}";
    do
        echo "'$x'";
    done
}
__compal__debug_vanilla_cspecs () 
{ 
    if [[ "$1" == "key" ]]; then
        for x in "${!__compal__vanilla_cspecs[@]}";
        do
            echo "$x";
        done;
    else
        for x in "${__compal__vanilla_cspecs[@]}";
        do
            echo "$x";
        done;
    fi
}
__compal__delegate () 
{ 
    _command_offset 0
}
__compal__delegate_in_context () 
{ 
    local cmd="$1";
    __compal__unmask_alias "$cmd";
    __compal__delegate;
    __compal__remask_alias "$cmd"
}
__compal__error () 
{ 
    printf "error: %s\n" "$1" 1>&2
}
__compal__expand_alias () 
{ 
    local beg="$1" end="$2" ignore="$3" n_used="$4";
    shift 4;
    local used=("${@:1:$n_used}");
    shift "$n_used";
    if (( $beg == $end )); then
        __compal__retval=0;
    else
        if [[ -n "$ignore" ]] && (( $beg == $ignore )); then
            __compal__expand_alias "$(( $beg + 1 ))" "$end" "$ignore" "${#used[@]}" "${used[@]}";
        else
            if ! alias "${COMP_WORDS[$beg]}" &> /dev/null; then
                __compal__retval=0;
            else
                if ( __compal__inarr "${COMP_WORDS[$beg]}" "${used[@]}" ); then
                    __compal__retval=0;
                else
                    local cmd="${COMP_WORDS[$beg]}";
                    local str0;
                    str0="$(__compal__get_alias_body "$cmd")";
                    __compal__split_cmd_line "$str0";
                    local words0=("${__compal__retval[@]}");
                    local nstr0="${words0[*]}";
                    local i=0 j=0;
                    for ((i = 0; i <= $beg; i++ ))
                    do
                        for ((1; j <= ${#COMP_LINE}; j++ ))
                        do
                            [[ "${COMP_LINE:j}" == "${COMP_WORDS[i]}"* ]] && break;
                        done;
                        (( i == $beg )) && break;
                        (( j += ${#COMP_WORDS[i]} ));
                    done;
                    COMP_LINE="${COMP_LINE:0:j}${nstr0}${COMP_LINE:j+${#cmd}}";
                    if (( $COMP_POINT < j )); then
                        :;
                    else
                        if (( $COMP_POINT < j + ${#cmd} )); then
                            (( COMP_POINT = j + ${#nstr0} ));
                        else
                            (( COMP_POINT += ${#nstr0} - ${#cmd} ));
                        fi;
                    fi;
                    COMP_WORDS=("${COMP_WORDS[@]:0:beg}" "${words0[@]}" "${COMP_WORDS[@]:beg+1}");
                    if (( $COMP_CWORD < $beg )); then
                        :;
                    else
                        if (( $COMP_CWORD < $beg + 1 )); then
                            (( COMP_CWORD = $beg + ${#words0[@]} - 1 ));
                        else
                            (( COMP_CWORD += ${#words0[@]} - 1 ));
                        fi;
                    fi;
                    if [[ -n "$ignore" ]]; then
                        local ignore_gt_beg=0;
                        if (( $ignore > $beg )); then
                            ignore_gt_beg=1;
                            (( ignore += ${#words0[@]} - 1 ));
                        fi;
                    fi;
                    local used0=("${used[@]}" "$cmd");
                    __compal__expand_alias "$beg" "$(( $beg + ${#words0[@]} ))" "$ignore" "${#used0[@]}" "${used0[@]}";
                    local diff0="$__compal__retval";
                    if [[ -n "$ignore" ]] && (( $ignore_gt_beg == 1 )); then
                        (( ignore += $diff0 ));
                    fi;
                    if [[ -n "$str0" ]] && [[ "${str0: -1}" == ' ' ]]; then
                        local used1=("${used[@]}");
                        __compal__expand_alias "$(( $beg + ${#words0[@]} + $diff0 ))" "$(( $end + ${#words0[@]} - 1 + $diff0 ))" "$ignore" "${#used1[@]}" "${used1[@]}";
                        local diff1="$__compal__retval";
                    else
                        local diff1=0;
                    fi;
                    __compal__retval=$(( ${#words0[@]} - 1 + diff0 + diff1 ));
                fi;
            fi;
        fi;
    fi
}
__compal__get_alias_body () 
{ 
    local cmd;
    cmd="$1";
    local body;
    body="$(alias "$cmd")";
    echo "${body#*=}" | command xargs
}
__compal__inarr () 
{ 
    for e in "${@:2}";
    do
        [[ "$e" == "$1" ]] && return 0;
    done;
    return 1
}
__compal__main () 
{ 
    if (( "$COMPAL_AUTO_UNMASK" == 1 )); then
        __compal__save_vanilla_cspecs;
    fi
}
__compal__remask_alias () 
{ 
    local cmd="$1";
    complete -F _complete_alias "$cmd"
}
__compal__run_cspec_args () 
{ 
    local cspec_args=("$@");
    if [[ "${cspec_args[0]}" == "complete" ]]; then
        "${cspec_args[@]}";
    else
        __compal__error "not a complete command: ${cspec_args[*]}";
    fi
}
__compal__save_vanilla_cspecs () 
{ 
    local def_cspec;
    def_cspec="$(complete -p -D 2>/dev/null)";
    while IFS= read -r cspec; do
        [[ "$cspec" != "$def_cspec" ]] || continue;
        [[ "$cspec" != *"-F _complete_alias"* ]] || continue;
        __compal__raw_vanilla_cspecs["$cspec"]="";
    done < <(complete -p 2>/dev/null)
}
__compal__split_cmd_line () 
{ 
    local str="$1";
    local words=();
    local sta=();
    local check_redass=1;
    local found_redass=0;
    local i=0 j=0;
    for ((1; j < ${#str}; j++ ))
    do
        if (( ${#sta[@]} == 0 )); then
            if [[ "${str:j:1}" =~ [_a-zA-Z0-9] ]]; then
                :;
            else
                if [[ ' 	
' == *"${str:j:1}"* ]]; then
                    if (( i < j )); then
                        if (( $found_redass == 1 )); then
                            if (( $check_redass == 0 )); then
                                words+=("${str:i:j-i}");
                            fi;
                            found_redass=0;
                        else
                            check_redass=0;
                            words+=("${str:i:j-i}");
                        fi;
                    fi;
                    (( i = j + 1 ));
                else
                    if [[ ":" == *"${str:j:1}"* ]]; then
                        if (( i < j )); then
                            if (( $found_redass == 1 )); then
                                if (( $check_redass == 0 )); then
                                    words+=("${str:i:j-i}");
                                fi;
                                found_redass=0;
                            else
                                check_redass=0;
                                words+=("${str:i:j-i}");
                            fi;
                        fi;
                        words+=("${str:j:1}");
                        (( i = j + 1 ));
                    else
                        if [[ '$(' == "${str:j:2}" ]]; then
                            sta+=(')');
                            (( j++ ));
                        else
                            if [[ '`' == "${str:j:1}" ]]; then
                                sta+=('`');
                            else
                                if [[ '(' == "${str:j:1}" ]]; then
                                    sta+=(')');
                                else
                                    if [[ '{' == "${str:j:1}" ]]; then
                                        sta+=('}');
                                    else
                                        if [[ '"' == "${str:j:1}" ]]; then
                                            sta+=('"');
                                        else
                                            if [[ "'" == "${str:j:1}" ]]; then
                                                sta+=("'");
                                            else
                                                if [[ '\' == "${str:j:1}" ]]; then
                                                    (( j++ ));
                                                else
                                                    if [[ '&>' == "${str:j:2}" ]]; then
                                                        found_redass=1;
                                                        (( j++ ));
                                                    else
                                                        if [[ '>&' == "${str:j:2}" ]]; then
                                                            found_redass=1;
                                                            (( j++ ));
                                                        else
                                                            if [[ "><=" == *"${str:j:1}"* ]]; then
                                                                found_redass=1;
                                                            else
                                                                if [[ '&&' == "${str:j:2}" ]]; then
                                                                    words=();
                                                                    check_redass=1;
                                                                    (( i = j + 2 ));
                                                                else
                                                                    if [[ '||' == "${str:j:2}" ]]; then
                                                                        words=();
                                                                        check_redass=1;
                                                                        (( i = j + 2 ));
                                                                    else
                                                                        if [[ '&' == "${str:j:1}" ]]; then
                                                                            words=();
                                                                            check_redass=1;
                                                                            (( i = j + 1 ));
                                                                        else
                                                                            if [[ '|' == "${str:j:1}" ]]; then
                                                                                words=();
                                                                                check_redass=1;
                                                                                (( i = j + 1 ));
                                                                            else
                                                                                if [[ ';' == "${str:j:1}" ]]; then
                                                                                    words=();
                                                                                    check_redass=1;
                                                                                    (( i = j + 1 ));
                                                                                fi;
                                                                            fi;
                                                                        fi;
                                                                    fi;
                                                                fi;
                                                            fi;
                                                        fi;
                                                    fi;
                                                fi;
                                            fi;
                                        fi;
                                    fi;
                                fi;
                            fi;
                        fi;
                    fi;
                fi;
            fi;
        else
            if [[ "${sta[-1]}" == ')' ]]; then
                if [[ ')' == "${str:j:1}" ]]; then
                    unset sta[-1];
                else
                    if [[ '$(' == "${str:j:2}" ]]; then
                        sta+=(')');
                        (( j++ ));
                    else
                        if [[ '`' == "${str:j:1}" ]]; then
                            sta+=('`');
                        else
                            if [[ '(' == "${str:j:1}" ]]; then
                                sta+=(')');
                            else
                                if [[ '{' == "${str:j:1}" ]]; then
                                    sta+=('}');
                                else
                                    if [[ '"' == "${str:j:1}" ]]; then
                                        sta+=('"');
                                    else
                                        if [[ "'" == "${str:j:1}" ]]; then
                                            sta+=("'");
                                        else
                                            if [[ '\' == "${str:j:1}" ]]; then
                                                (( j++ ));
                                            fi;
                                        fi;
                                    fi;
                                fi;
                            fi;
                        fi;
                    fi;
                fi;
            else
                if [[ "${sta[-1]}" == '}' ]]; then
                    if [[ '}' == "${str:j:1}" ]]; then
                        unset sta[-1];
                    else
                        if [[ '$(' == "${str:j:2}" ]]; then
                            sta+=(')');
                            (( j++ ));
                        else
                            if [[ '`' == "${str:j:1}" ]]; then
                                sta+=('`');
                            else
                                if [[ '(' == "${str:j:1}" ]]; then
                                    sta+=(')');
                                else
                                    if [[ '{' == "${str:j:1}" ]]; then
                                        sta+=('}');
                                    else
                                        if [[ '"' == "${str:j:1}" ]]; then
                                            sta+=('"');
                                        else
                                            if [[ "'" == "${str:j:1}" ]]; then
                                                sta+=("'");
                                            else
                                                if [[ '\' == "${str:j:1}" ]]; then
                                                    (( j++ ));
                                                fi;
                                            fi;
                                        fi;
                                    fi;
                                fi;
                            fi;
                        fi;
                    fi;
                else
                    if [[ "${sta[-1]}" == '`' ]]; then
                        if [[ '`' == "${str:j:1}" ]]; then
                            unset sta[-1];
                        else
                            if [[ '$(' == "${str:j:2}" ]]; then
                                sta+=(')');
                                (( j++ ));
                            else
                                if [[ '(' == "${str:j:1}" ]]; then
                                    sta+=(')');
                                else
                                    if [[ '{' == "${str:j:1}" ]]; then
                                        sta+=('}');
                                    else
                                        if [[ '"' == "${str:j:1}" ]]; then
                                            sta+=('"');
                                        else
                                            if [[ "'" == "${str:j:1}" ]]; then
                                                sta+=("'");
                                            else
                                                if [[ '\' == "${str:j:1}" ]]; then
                                                    (( j++ ));
                                                fi;
                                            fi;
                                        fi;
                                    fi;
                                fi;
                            fi;
                        fi;
                    else
                        if [[ "${sta[-1]}" == "'" ]]; then
                            if [[ "'" == "${str:j:1}" ]]; then
                                unset sta[-1];
                            fi;
                        else
                            if [[ "${sta[-1]}" == '"' ]]; then
                                if [[ '"' == "${str:j:1}" ]]; then
                                    unset sta[-1];
                                else
                                    if [[ '$(' == "${str:j:2}" ]]; then
                                        sta+=(')');
                                        (( j++ ));
                                    else
                                        if [[ '`' == "${str:j:1}" ]]; then
                                            sta+=('`');
                                        else
                                            if [[ '\$' == "${str:j:2}" ]]; then
                                                (( j++ ));
                                            else
                                                if [[ '\`' == "${str:j:2}" ]]; then
                                                    (( j++ ));
                                                else
                                                    if [[ '\"' == "${str:j:2}" ]]; then
                                                        (( j++ ));
                                                    else
                                                        if [[ '\\' == "${str:j:2}" ]]; then
                                                            (( j++ ));
                                                        fi;
                                                    fi;
                                                fi;
                                            fi;
                                        fi;
                                    fi;
                                fi;
                            fi;
                        fi;
                    fi;
                fi;
            fi;
        fi;
    done;
    if (( i < j )); then
        if (( $found_redass == 1 )); then
            if (( $check_redass == 0 )); then
                words+=("${str:i:j-i}");
            fi;
            found_redass=0;
        else
            check_redass=0;
            words+=("${str:i:j-i}");
        fi;
    fi;
    unset sta;
    __compal__retval=("${words[@]}")
}
__compal__unmask_alias () 
{ 
    local cmd="$1";
    if [[ "$(complete -p "$cmd")" != *"-F _complete_alias"* ]]; then
        __compal__error "cannot unmask alias command: $cmd";
        return;
    fi;
    if (( "$COMPAL_AUTO_UNMASK" == 1 )); then
        __compal__unmask_alias_auto "$@";
    else
        __compal__unmask_alias_manual "$@";
    fi
}
__compal__unmask_alias_auto () 
{ 
    local cmd="$1";
    local cspec="${__compal__vanilla_cspecs[$cmd]}";
    if [[ -n "$cspec" ]]; then
        __compal__split_cmd_line "$cspec";
        local cspec_args=("${__compal__retval[@]}");
        __compal__run_cspec_args "${cspec_args[@]}";
    else
        for _cspec in "${!__compal__raw_vanilla_cspecs[@]}";
        do
            if [[ "$_cspec" == *" $cmd" ]]; then
                __compal__split_cmd_line "$_cspec";
                local _cspec_args=("${__compal__retval[@]}");
                local _cspec_cmd="${_cspec_args[-1]}";
                if [[ "$_cspec_cmd" == "$cmd" ]]; then
                    __compal__vanilla_cspecs["$_cspec_cmd"]="$_cspec";
                    unset __compal__raw_vanilla_cspecs["$_cspec"];
                    __compal__run_cspec_args "${_cspec_args[@]}";
                    return;
                fi;
            fi;
        done;
        complete -r "$cmd";
    fi
}
__compal__unmask_alias_manual () 
{ 
    local cmd="$1";
    case "$cmd" in 
        bind)
            complete -A binding "$cmd"
        ;;
        help)
            complete -A helptopic "$cmd"
        ;;
        set)
            complete -A setopt "$cmd"
        ;;
        shopt)
            complete -A shopt "$cmd"
        ;;
        bg)
            complete -A stopped -P '"%' -S '"' "$cmd"
        ;;
        service)
            complete -F _service "$cmd"
        ;;
        unalias)
            complete -a "$cmd"
        ;;
        builtin)
            complete -b "$cmd"
        ;;
        command | type | which)
            complete -c "$cmd"
        ;;
        fg | jobs | disown)
            complete -j -P '"%' -S '"' "$cmd"
        ;;
        groups | slay | w | sux)
            complete -u "$cmd"
        ;;
        readonly | unset)
            complete -v "$cmd"
        ;;
        traceroute | traceroute6 | tracepath | tracepath6 | fping | fping6 | telnet | rsh | rlogin | ftp | dig | mtr | ssh-installkeys | showmount)
            complete -F _known_hosts "$cmd"
        ;;
        aoss | command | do | else | eval | exec | ltrace | nice | nohup | padsp | then | time | tsocks | vsound | xargs)
            complete -F _command "$cmd"
        ;;
        fakeroot | gksu | gksudo | kdesudo | really)
            complete -F _root_command "$cmd"
        ;;
        a2ps | awk | base64 | bash | bc | bison | cat | chroot | colordiff | cp | csplit | cut | date | df | diff | dir | du | enscript | env | expand | fmt | fold | gperf | grep | grub | head | irb | ld | ldd | less | ln | ls | m4 | md5sum | mkdir | mkfifo | mknod | mv | netstat | nl | nm | objcopy | objdump | od | paste | pr | ptx | readelf | rm | rmdir | sed | seq | sha{,1,224,256,384,512}sum | shar | sort | split | strip | sum | tac | tail | tee | texindex | touch | tr | uname | unexpand | uniq | units | vdir | wc | who)
            complete -F _longopt "$cmd"
        ;;
        *)
            _completion_loader "$cmd"
        ;;
    esac
}
__expand_tilde_by_ref () 
{ 
    if [[ ${!1} == \~* ]]; then
        eval $1=$(printf ~%q "${!1#\~}");
    fi
}
__get_cword_at_cursor_by_ref () 
{ 
    local cword words=();
    __reassemble_comp_words_by_ref "$1" words cword;
    local i cur index=$COMP_POINT lead=${COMP_LINE:0:$COMP_POINT};
    if [[ $index -gt 0 && ( -n $lead && -n ${lead//[[:space:]]} ) ]]; then
        cur=$COMP_LINE;
        for ((i = 0; i <= cword; ++i ))
        do
            while [[ ${#cur} -ge ${#words[i]} && "${cur:0:${#words[i]}}" != "${words[i]}" ]]; do
                cur="${cur:1}";
                [[ $index -gt 0 ]] && ((index--));
            done;
            if [[ $i -lt $cword ]]; then
                local old_size=${#cur};
                cur="${cur#"${words[i]}"}";
                local new_size=${#cur};
                (( index -= old_size - new_size ));
            fi;
        done;
        [[ -n $cur && ! -n ${cur//[[:space:]]} ]] && cur=;
        [[ $index -lt 0 ]] && index=0;
    fi;
    local "$2" "$3" "$4" && _upvars -a${#words[@]} $2 "${words[@]}" -v $3 "$cword" -v $4 "${cur:0:$index}"
}
__git_eread () 
{ 
    test -r "$1" && IFS='
' read "$2" < "$1"
}
__git_ps1 () 
{ 
    local exit=$?;
    local pcmode=no;
    local detached=no;
    local ps1pc_start='\u@\h:\w ';
    local ps1pc_end='\$ ';
    local printf_format=' (%s)';
    case "$#" in 
        2 | 3)
            pcmode=yes;
            ps1pc_start="$1";
            ps1pc_end="$2";
            printf_format="${3:-$printf_format}";
            PS1="$ps1pc_start$ps1pc_end"
        ;;
        0 | 1)
            printf_format="${1:-$printf_format}"
        ;;
        *)
            return $exit
        ;;
    esac;
    local ps1_expanded=yes;
    [ -z "${ZSH_VERSION-}" ] || [[ -o PROMPT_SUBST ]] || ps1_expanded=no;
    [ -z "${BASH_VERSION-}" ] || shopt -q promptvars || ps1_expanded=no;
    local repo_info rev_parse_exit_code;
    repo_info="$(git rev-parse --git-dir --is-inside-git-dir 		--is-bare-repository --is-inside-work-tree 		--short HEAD 2>/dev/null)";
    rev_parse_exit_code="$?";
    if [ -z "$repo_info" ]; then
        return $exit;
    fi;
    local short_sha="";
    if [ "$rev_parse_exit_code" = "0" ]; then
        short_sha="${repo_info##*
}";
        repo_info="${repo_info%
*}";
    fi;
    local inside_worktree="${repo_info##*
}";
    repo_info="${repo_info%
*}";
    local bare_repo="${repo_info##*
}";
    repo_info="${repo_info%
*}";
    local inside_gitdir="${repo_info##*
}";
    local g="${repo_info%
*}";
    if [ "true" = "$inside_worktree" ] && [ -n "${GIT_PS1_HIDE_IF_PWD_IGNORED-}" ] && [ "$(git config --bool bash.hideIfPwdIgnored)" != "false" ] && git check-ignore -q .; then
        return $exit;
    fi;
    local r="";
    local b="";
    local step="";
    local total="";
    if [ -d "$g/rebase-merge" ]; then
        __git_eread "$g/rebase-merge/head-name" b;
        __git_eread "$g/rebase-merge/msgnum" step;
        __git_eread "$g/rebase-merge/end" total;
        if [ -f "$g/rebase-merge/interactive" ]; then
            r="|REBASE-i";
        else
            r="|REBASE-m";
        fi;
    else
        if [ -d "$g/rebase-apply" ]; then
            __git_eread "$g/rebase-apply/next" step;
            __git_eread "$g/rebase-apply/last" total;
            if [ -f "$g/rebase-apply/rebasing" ]; then
                __git_eread "$g/rebase-apply/head-name" b;
                r="|REBASE";
            else
                if [ -f "$g/rebase-apply/applying" ]; then
                    r="|AM";
                else
                    r="|AM/REBASE";
                fi;
            fi;
        else
            if [ -f "$g/MERGE_HEAD" ]; then
                r="|MERGING";
            else
                if __git_sequencer_status; then
                    :;
                else
                    if [ -f "$g/BISECT_LOG" ]; then
                        r="|BISECTING";
                    fi;
                fi;
            fi;
        fi;
        if [ -n "$b" ]; then
            :;
        else
            if [ -h "$g/HEAD" ]; then
                b="$(git symbolic-ref HEAD 2>/dev/null)";
            else
                local head="";
                if ! __git_eread "$g/HEAD" head; then
                    return $exit;
                fi;
                b="${head#ref: }";
                if [ "$head" = "$b" ]; then
                    detached=yes;
                    b="$(
				case "${GIT_PS1_DESCRIBE_STYLE-}" in
				(contains)
					git describe --contains HEAD ;;
				(branch)
					git describe --contains --all HEAD ;;
				(tag)
					git describe --tags HEAD ;;
				(describe)
					git describe HEAD ;;
				(* | default)
					git describe --tags --exact-match HEAD ;;
				esac 2>/dev/null)" || b="$short_sha...";
                    b="($b)";
                fi;
            fi;
        fi;
    fi;
    if [ -n "$step" ] && [ -n "$total" ]; then
        r="$r $step/$total";
    fi;
    local w="";
    local i="";
    local s="";
    local u="";
    local c="";
    local p="";
    if [ "true" = "$inside_gitdir" ]; then
        if [ "true" = "$bare_repo" ]; then
            c="BARE:";
        else
            b="GIT_DIR!";
        fi;
    else
        if [ "true" = "$inside_worktree" ]; then
            if [ -n "${GIT_PS1_SHOWDIRTYSTATE-}" ] && [ "$(git config --bool bash.showDirtyState)" != "false" ]; then
                git diff --no-ext-diff --quiet || w="*";
                git diff --no-ext-diff --cached --quiet || i="+";
                if [ -z "$short_sha" ] && [ -z "$i" ]; then
                    i="#";
                fi;
            fi;
            if [ -n "${GIT_PS1_SHOWSTASHSTATE-}" ] && git rev-parse --verify --quiet refs/stash > /dev/null; then
                s="$";
            fi;
            if [ -n "${GIT_PS1_SHOWUNTRACKEDFILES-}" ] && [ "$(git config --bool bash.showUntrackedFiles)" != "false" ] && git ls-files --others --exclude-standard --directory --no-empty-directory --error-unmatch -- ':/*' > /dev/null 2> /dev/null; then
                u="%${ZSH_VERSION+%}";
            fi;
            if [ -n "${GIT_PS1_SHOWUPSTREAM-}" ]; then
                __git_ps1_show_upstream;
            fi;
        fi;
    fi;
    local z="${GIT_PS1_STATESEPARATOR-" "}";
    if [ $pcmode = yes ] && [ -n "${GIT_PS1_SHOWCOLORHINTS-}" ]; then
        __git_ps1_colorize_gitstring;
    fi;
    b=${b##refs/heads/};
    if [ $pcmode = yes ] && [ $ps1_expanded = yes ]; then
        __git_ps1_branch_name=$b;
        b="\${__git_ps1_branch_name}";
    fi;
    local f="$w$i$s$u";
    local gitstring="$c$b${f:+$z$f}$r$p";
    if [ $pcmode = yes ]; then
        if [ "${__git_printf_supports_v-}" != yes ]; then
            gitstring=$(printf -- "$printf_format" "$gitstring");
        else
            printf -v gitstring -- "$printf_format" "$gitstring";
        fi;
        PS1="$ps1pc_start$gitstring$ps1pc_end";
    else
        printf -- "$printf_format" "$gitstring";
    fi;
    return $exit
}
__git_ps1_colorize_gitstring () 
{ 
    if [[ -n ${ZSH_VERSION-} ]]; then
        local c_red='%F{red}';
        local c_green='%F{green}';
        local c_lblue='%F{blue}';
        local c_clear='%f';
    else
        local c_red='\[\e[31m\]';
        local c_green='\[\e[32m\]';
        local c_lblue='\[\e[1;34m\]';
        local c_clear='\[\e[0m\]';
    fi;
    local bad_color=$c_red;
    local ok_color=$c_green;
    local flags_color="$c_lblue";
    local branch_color="";
    if [ $detached = no ]; then
        branch_color="$ok_color";
    else
        branch_color="$bad_color";
    fi;
    c="$branch_color$c";
    z="$c_clear$z";
    if [ "$w" = "*" ]; then
        w="$bad_color$w";
    fi;
    if [ -n "$i" ]; then
        i="$ok_color$i";
    fi;
    if [ -n "$s" ]; then
        s="$flags_color$s";
    fi;
    if [ -n "$u" ]; then
        u="$bad_color$u";
    fi;
    r="$c_clear$r"
}
__git_ps1_show_upstream () 
{ 
    local key value;
    local svn_remote svn_url_pattern count n;
    local upstream=git legacy="" verbose="" name="";
    svn_remote=();
    local output="$(git config -z --get-regexp '^(svn-remote\..*\.url|bash\.showupstream)$' 2>/dev/null | tr '\0\n' '\n ')";
    while read -r key value; do
        case "$key" in 
            bash.showupstream)
                GIT_PS1_SHOWUPSTREAM="$value";
                if [[ -z "${GIT_PS1_SHOWUPSTREAM}" ]]; then
                    p="";
                    return;
                fi
            ;;
            svn-remote.*.url)
                svn_remote[$((${#svn_remote[@]} + 1))]="$value";
                svn_url_pattern="$svn_url_pattern\\|$value";
                upstream=svn+git
            ;;
        esac;
    done <<< "$output";
    for option in ${GIT_PS1_SHOWUPSTREAM};
    do
        case "$option" in 
            git | svn)
                upstream="$option"
            ;;
            verbose)
                verbose=1
            ;;
            legacy)
                legacy=1
            ;;
            name)
                name=1
            ;;
        esac;
    done;
    case "$upstream" in 
        git)
            upstream="@{upstream}"
        ;;
        svn*)
            local -a svn_upstream;
            svn_upstream=($(git log --first-parent -1 					--grep="^git-svn-id: \(${svn_url_pattern#??}\)" 2>/dev/null));
            if [[ 0 -ne ${#svn_upstream[@]} ]]; then
                svn_upstream=${svn_upstream[${#svn_upstream[@]} - 2]};
                svn_upstream=${svn_upstream%@*};
                local n_stop="${#svn_remote[@]}";
                for ((n=1; n <= n_stop; n++))
                do
                    svn_upstream=${svn_upstream#${svn_remote[$n]}};
                done;
                if [[ -z "$svn_upstream" ]]; then
                    upstream=${GIT_SVN_ID:-git-svn};
                else
                    upstream=${svn_upstream#/};
                fi;
            else
                if [[ "svn+git" = "$upstream" ]]; then
                    upstream="@{upstream}";
                fi;
            fi
        ;;
    esac;
    if [[ -z "$legacy" ]]; then
        count="$(git rev-list --count --left-right 				"$upstream"...HEAD 2>/dev/null)";
    else
        local commits;
        if commits="$(git rev-list --left-right "$upstream"...HEAD 2>/dev/null)"; then
            local commit behind=0 ahead=0;
            for commit in $commits;
            do
                case "$commit" in 
                    "<"*)
                        ((behind++))
                    ;;
                    *)
                        ((ahead++))
                    ;;
                esac;
            done;
            count="$behind	$ahead";
        else
            count="";
        fi;
    fi;
    if [[ -z "$verbose" ]]; then
        case "$count" in 
            "")
                p=""
            ;;
            "0	0")
                p="="
            ;;
            "0	"*)
                p=">"
            ;;
            *"	0")
                p="<"
            ;;
            *)
                p="<>"
            ;;
        esac;
    else
        case "$count" in 
            "")
                p=""
            ;;
            "0	0")
                p=" u="
            ;;
            "0	"*)
                p=" u+${count#0	}"
            ;;
            *"	0")
                p=" u-${count%	0}"
            ;;
            *)
                p=" u+${count#*	}-${count%	*}"
            ;;
        esac;
        if [[ -n "$count" && -n "$name" ]]; then
            __git_ps1_upstream_name=$(git rev-parse 				--abbrev-ref "$upstream" 2>/dev/null);
            if [ $pcmode = yes ] && [ $ps1_expanded = yes ]; then
                p="$p \${__git_ps1_upstream_name}";
            else
                p="$p ${__git_ps1_upstream_name}";
                unset __git_ps1_upstream_name;
            fi;
        fi;
    fi
}
__git_sequencer_status () 
{ 
    local todo;
    if test -f "$g/CHERRY_PICK_HEAD"; then
        r="|CHERRY-PICKING";
        return 0;
    else
        if test -f "$g/REVERT_HEAD"; then
            r="|REVERTING";
            return 0;
        else
            if __git_eread "$g/sequencer/todo" todo; then
                case "$todo" in 
                    p[\ \	] | pick[\ \	]*)
                        r="|CHERRY-PICKING";
                        return 0
                    ;;
                    revert[\ \	]*)
                        r="|REVERTING";
                        return 0
                    ;;
                esac;
            fi;
        fi;
    fi;
    return 1
}
__helm_debug () 
{ 
    if [[ -n ${BASH_COMP_DEBUG_FILE:-} ]]; then
        echo "$*" >> "${BASH_COMP_DEBUG_FILE}";
    fi
}
__helm_extract_activeHelp () 
{ 
    local activeHelpMarker="_activeHelp_ ";
    local endIndex=${#activeHelpMarker};
    while IFS='' read -r comp; do
        if [ "${comp:0:endIndex}" = "$activeHelpMarker" ]; then
            comp=${comp:endIndex};
            __helm_debug "ActiveHelp found: $comp";
            if [ -n "$comp" ]; then
                activeHelp+=("$comp");
            fi;
        else
            completions+=("$comp");
        fi;
    done < <(printf "%s\n" "${out}")
}
__helm_format_comp_descriptions () 
{ 
    local tab='	';
    local comp desc maxdesclength;
    local longest=$1;
    local i ci;
    for ci in ${!COMPREPLY[*]};
    do
        comp=${COMPREPLY[ci]};
        if [[ "$comp" == *$tab* ]]; then
            __helm_debug "Original comp: $comp";
            desc=${comp#*$tab};
            comp=${comp%%$tab*};
            maxdesclength=$(( COLUMNS - longest - 4 ));
            if [[ $maxdesclength -gt 8 ]]; then
                for ((i = ${#comp} ; i < longest ; i++))
                do
                    comp+=" ";
                done;
            else
                maxdesclength=$(( COLUMNS - ${#comp} - 4 ));
            fi;
            if [ $maxdesclength -gt 0 ]; then
                if [ ${#desc} -gt $maxdesclength ]; then
                    desc=${desc:0:$(( maxdesclength - 1 ))};
                    desc+="…";
                fi;
                comp+="  ($desc)";
            fi;
            COMPREPLY[ci]=$comp;
            __helm_debug "Final comp: $comp";
        fi;
    done
}
__helm_get_completion_results () 
{ 
    local requestComp lastParam lastChar args;
    args=("${words[@]:1}");
    requestComp="${words[0]} __complete ${args[*]}";
    lastParam=${words[$((${#words[@]}-1))]};
    lastChar=${lastParam:$((${#lastParam}-1)):1};
    __helm_debug "lastParam ${lastParam}, lastChar ${lastChar}";
    if [ -z "${cur}" ] && [ "${lastChar}" != "=" ]; then
        __helm_debug "Adding extra empty parameter";
        requestComp="${requestComp} ''";
    fi;
    if [[ "${cur}" == -*=* ]]; then
        cur="${cur#*=}";
    fi;
    __helm_debug "Calling ${requestComp}";
    out=$(eval "${requestComp}" 2>/dev/null);
    directive=${out##*:};
    out=${out%:*};
    if [ "${directive}" = "${out}" ]; then
        directive=0;
    fi;
    __helm_debug "The completion directive is: ${directive}";
    __helm_debug "The completions are: ${out}"
}
__helm_handle_completion_types () 
{ 
    __helm_debug "__helm_handle_completion_types: COMP_TYPE is $COMP_TYPE";
    case $COMP_TYPE in 
        37 | 42)
            local tab='	' comp;
            while IFS='' read -r comp; do
                [[ -z $comp ]] && continue;
                comp=${comp%%$tab*};
                if [[ $comp == "$cur"* ]]; then
                    COMPREPLY+=("$comp");
                fi;
            done < <(printf "%s\n" "${completions[@]}")
        ;;
        *)
            __helm_handle_standard_completion_case
        ;;
    esac
}
__helm_handle_special_char () 
{ 
    local comp="$1";
    local char=$2;
    if [[ "$comp" == *${char}* && "$COMP_WORDBREAKS" == *${char}* ]]; then
        local word=${comp%"${comp##*${char}}"};
        local idx=${#COMPREPLY[*]};
        while [[ $((--idx)) -ge 0 ]]; do
            COMPREPLY[$idx]=${COMPREPLY[$idx]#"$word"};
        done;
    fi
}
__helm_handle_standard_completion_case () 
{ 
    local tab='	' comp;
    if [[ "${completions[*]}" != *$tab* ]]; then
        IFS='
' read -ra COMPREPLY -d '' < <(compgen -W "${completions[*]}" -- "$cur");
        return 0;
    fi;
    local longest=0;
    local compline;
    while IFS='' read -r compline; do
        [[ -z $compline ]] && continue;
        comp=${compline%%$tab*};
        [[ $comp == "$cur"* ]] || continue;
        COMPREPLY+=("$compline");
        if ((${#comp}>longest)); then
            longest=${#comp};
        fi;
    done < <(printf "%s\n" "${completions[@]}");
    if [ ${#COMPREPLY[*]} -eq 1 ]; then
        __helm_debug "COMPREPLY[0]: ${COMPREPLY[0]}";
        comp="${COMPREPLY[0]%%$tab*}";
        __helm_debug "Removed description from single completion, which is now: ${comp}";
        COMPREPLY[0]=$comp;
    else
        __helm_format_comp_descriptions $longest;
    fi
}
__helm_init_completion () 
{ 
    COMPREPLY=();
    _get_comp_words_by_ref "$@" cur prev words cword
}
__helm_process_completion_results () 
{ 
    local shellCompDirectiveError=1;
    local shellCompDirectiveNoSpace=2;
    local shellCompDirectiveNoFileComp=4;
    local shellCompDirectiveFilterFileExt=8;
    local shellCompDirectiveFilterDirs=16;
    if [ $((directive & shellCompDirectiveError)) -ne 0 ]; then
        __helm_debug "Received error from custom completion go code";
        return;
    else
        if [ $((directive & shellCompDirectiveNoSpace)) -ne 0 ]; then
            if [[ $(type -t compopt) = "builtin" ]]; then
                __helm_debug "Activating no space";
                compopt -o nospace;
            else
                __helm_debug "No space directive not supported in this version of bash";
            fi;
        fi;
        if [ $((directive & shellCompDirectiveNoFileComp)) -ne 0 ]; then
            if [[ $(type -t compopt) = "builtin" ]]; then
                __helm_debug "Activating no file completion";
                compopt +o default;
            else
                __helm_debug "No file completion directive not supported in this version of bash";
            fi;
        fi;
    fi;
    local completions=();
    local activeHelp=();
    __helm_extract_activeHelp;
    if [ $((directive & shellCompDirectiveFilterFileExt)) -ne 0 ]; then
        local fullFilter filter filteringCmd;
        for filter in ${completions[*]};
        do
            fullFilter+="$filter|";
        done;
        filteringCmd="_filedir $fullFilter";
        __helm_debug "File filtering command: $filteringCmd";
        $filteringCmd;
    else
        if [ $((directive & shellCompDirectiveFilterDirs)) -ne 0 ]; then
            local subdir;
            subdir=$(printf "%s" "${completions[0]}");
            if [ -n "$subdir" ]; then
                __helm_debug "Listing directories in $subdir";
                pushd "$subdir" > /dev/null 2>&1 && _filedir -d && popd > /dev/null 2>&1 || return;
            else
                __helm_debug "Listing directories in .";
                _filedir -d;
            fi;
        else
            __helm_handle_completion_types;
        fi;
    fi;
    __helm_handle_special_char "$cur" :;
    __helm_handle_special_char "$cur" =;
    if [ ${#activeHelp} -ne 0 ]; then
        printf "\n";
        printf "%s\n" "${activeHelp[@]}";
        printf "\n";
        if ( x=${PS1@P} ) 2> /dev/null; then
            printf "%s" "${PS1@P}${COMP_LINE[@]}";
        else
            printf "%s" "${COMP_LINE[@]}";
        fi;
    fi
}
__kubectl_debug () 
{ 
    if [[ -n ${BASH_COMP_DEBUG_FILE-} ]]; then
        echo "$*" >> "${BASH_COMP_DEBUG_FILE}";
    fi
}
__kubectl_extract_activeHelp () 
{ 
    local activeHelpMarker="_activeHelp_ ";
    local endIndex=${#activeHelpMarker};
    while IFS='' read -r comp; do
        if [[ ${comp:0:endIndex} == $activeHelpMarker ]]; then
            comp=${comp:endIndex};
            __kubectl_debug "ActiveHelp found: $comp";
            if [[ -n $comp ]]; then
                activeHelp+=("$comp");
            fi;
        else
            completions+=("$comp");
        fi;
    done <<< "${out}"
}
__kubectl_format_comp_descriptions () 
{ 
    local tab='	';
    local comp desc maxdesclength;
    local longest=$1;
    local i ci;
    for ci in ${!COMPREPLY[*]};
    do
        comp=${COMPREPLY[ci]};
        if [[ "$comp" == *$tab* ]]; then
            __kubectl_debug "Original comp: $comp";
            desc=${comp#*$tab};
            comp=${comp%%$tab*};
            maxdesclength=$(( COLUMNS - longest - 4 ));
            if ((maxdesclength > 8)); then
                for ((i = ${#comp} ; i < longest ; i++))
                do
                    comp+=" ";
                done;
            else
                maxdesclength=$(( COLUMNS - ${#comp} - 4 ));
            fi;
            if ((maxdesclength > 0)); then
                if ((${#desc} > maxdesclength)); then
                    desc=${desc:0:$(( maxdesclength - 1 ))};
                    desc+="…";
                fi;
                comp+="  ($desc)";
            fi;
            COMPREPLY[ci]=$comp;
            __kubectl_debug "Final comp: $comp";
        fi;
    done
}
__kubectl_get_completion_results () 
{ 
    local requestComp lastParam lastChar args;
    args=("${words[@]:1}");
    requestComp="${words[0]} __complete ${args[*]}";
    lastParam=${words[$((${#words[@]}-1))]};
    lastChar=${lastParam:$((${#lastParam}-1)):1};
    __kubectl_debug "lastParam ${lastParam}, lastChar ${lastChar}";
    if [[ -z ${cur} && ${lastChar} != = ]]; then
        __kubectl_debug "Adding extra empty parameter";
        requestComp="${requestComp} ''";
    fi;
    if [[ ${cur} == -*=* ]]; then
        cur="${cur#*=}";
    fi;
    __kubectl_debug "Calling ${requestComp}";
    out=$(eval "${requestComp}" 2>/dev/null);
    directive=${out##*:};
    out=${out%:*};
    if [[ ${directive} == "${out}" ]]; then
        directive=0;
    fi;
    __kubectl_debug "The completion directive is: ${directive}";
    __kubectl_debug "The completions are: ${out}"
}
__kubectl_handle_completion_types () 
{ 
    __kubectl_debug "__kubectl_handle_completion_types: COMP_TYPE is $COMP_TYPE";
    case $COMP_TYPE in 
        37 | 42)
            local tab='	' comp;
            while IFS='' read -r comp; do
                [[ -z $comp ]] && continue;
                comp=${comp%%$tab*};
                if [[ $comp == "$cur"* ]]; then
                    COMPREPLY+=("$comp");
                fi;
            done < <(printf "%s\n" "${completions[@]}")
        ;;
        *)
            __kubectl_handle_standard_completion_case
        ;;
    esac
}
__kubectl_handle_special_char () 
{ 
    local comp="$1";
    local char=$2;
    if [[ "$comp" == *${char}* && "$COMP_WORDBREAKS" == *${char}* ]]; then
        local word=${comp%"${comp##*${char}}"};
        local idx=${#COMPREPLY[*]};
        while ((--idx >= 0)); do
            COMPREPLY[idx]=${COMPREPLY[idx]#"$word"};
        done;
    fi
}
__kubectl_handle_standard_completion_case () 
{ 
    local tab='	' comp;
    if [[ "${completions[*]}" != *$tab* ]]; then
        IFS='
' read -ra COMPREPLY -d '' < <(compgen -W "${completions[*]}" -- "$cur");
        return 0;
    fi;
    local longest=0;
    local compline;
    while IFS='' read -r compline; do
        [[ -z $compline ]] && continue;
        comp=${compline%%$tab*};
        [[ $comp == "$cur"* ]] || continue;
        COMPREPLY+=("$compline");
        if ((${#comp}>longest)); then
            longest=${#comp};
        fi;
    done < <(printf "%s\n" "${completions[@]}");
    if ((${#COMPREPLY[*]} == 1)); then
        __kubectl_debug "COMPREPLY[0]: ${COMPREPLY[0]}";
        comp="${COMPREPLY[0]%%$tab*}";
        __kubectl_debug "Removed description from single completion, which is now: ${comp}";
        COMPREPLY[0]=$comp;
    else
        __kubectl_format_comp_descriptions $longest;
    fi
}
__kubectl_init_completion () 
{ 
    COMPREPLY=();
    _get_comp_words_by_ref "$@" cur prev words cword
}
__kubectl_process_completion_results () 
{ 
    local shellCompDirectiveError=1;
    local shellCompDirectiveNoSpace=2;
    local shellCompDirectiveNoFileComp=4;
    local shellCompDirectiveFilterFileExt=8;
    local shellCompDirectiveFilterDirs=16;
    local shellCompDirectiveKeepOrder=32;
    if (((directive & shellCompDirectiveError) != 0)); then
        __kubectl_debug "Received error from custom completion go code";
        return;
    else
        if (((directive & shellCompDirectiveNoSpace) != 0)); then
            if [[ $(type -t compopt) == builtin ]]; then
                __kubectl_debug "Activating no space";
                compopt -o nospace;
            else
                __kubectl_debug "No space directive not supported in this version of bash";
            fi;
        fi;
        if (((directive & shellCompDirectiveKeepOrder) != 0)); then
            if [[ $(type -t compopt) == builtin ]]; then
                if [[ ${BASH_VERSINFO[0]} -lt 4 || ( ${BASH_VERSINFO[0]} -eq 4 && ${BASH_VERSINFO[1]} -lt 4 ) ]]; then
                    __kubectl_debug "No sort directive not supported in this version of bash";
                else
                    __kubectl_debug "Activating keep order";
                    compopt -o nosort;
                fi;
            else
                __kubectl_debug "No sort directive not supported in this version of bash";
            fi;
        fi;
        if (((directive & shellCompDirectiveNoFileComp) != 0)); then
            if [[ $(type -t compopt) == builtin ]]; then
                __kubectl_debug "Activating no file completion";
                compopt +o default;
            else
                __kubectl_debug "No file completion directive not supported in this version of bash";
            fi;
        fi;
    fi;
    local completions=();
    local activeHelp=();
    __kubectl_extract_activeHelp;
    if (((directive & shellCompDirectiveFilterFileExt) != 0)); then
        local fullFilter filter filteringCmd;
        for filter in ${completions[*]};
        do
            fullFilter+="$filter|";
        done;
        filteringCmd="_filedir $fullFilter";
        __kubectl_debug "File filtering command: $filteringCmd";
        $filteringCmd;
    else
        if (((directive & shellCompDirectiveFilterDirs) != 0)); then
            local subdir;
            subdir=${completions[0]};
            if [[ -n $subdir ]]; then
                __kubectl_debug "Listing directories in $subdir";
                pushd "$subdir" > /dev/null 2>&1 && _filedir -d && popd > /dev/null 2>&1 || return;
            else
                __kubectl_debug "Listing directories in .";
                _filedir -d;
            fi;
        else
            __kubectl_handle_completion_types;
        fi;
    fi;
    __kubectl_handle_special_char "$cur" :;
    __kubectl_handle_special_char "$cur" =;
    if ((${#activeHelp[*]} != 0)); then
        printf "\n";
        printf "%s\n" "${activeHelp[@]}";
        printf "\n";
        if ( x=${PS1@P} ) 2> /dev/null; then
            printf "%s" "${PS1@P}${COMP_LINE[@]}";
        else
            printf "%s" "${COMP_LINE[@]}";
        fi;
    fi
}
__load_completion () 
{ 
    local -a dirs=(${BASH_COMPLETION_USER_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion}/completions);
    local OIFS=$IFS IFS=: dir cmd="${1##*/}" compfile;
    [[ -n $cmd ]] || return 1;
    for dir in ${XDG_DATA_DIRS:-/usr/local/share:/usr/share};
    do
        dirs+=($dir/bash-completion/completions);
    done;
    IFS=$OIFS;
    if [[ $BASH_SOURCE == */* ]]; then
        dirs+=("${BASH_SOURCE%/*}/completions");
    else
        dirs+=(./completions);
    fi;
    for dir in "${dirs[@]}";
    do
        [[ -d "$dir" ]] || continue;
        for compfile in "$cmd" "$cmd.bash" "_$cmd";
        do
            compfile="$dir/$compfile";
            [[ -f "$compfile" ]] && . "$compfile" &> /dev/null && return 0;
        done;
    done;
    [[ -n "${_xspecs[$cmd]}" ]] && complete -F _filedir_xspec "$cmd" && return 0;
    return 1
}
__ltrim_colon_completions () 
{ 
    if [[ "$1" == *:* && "$COMP_WORDBREAKS" == *:* ]]; then
        local colon_word=${1%"${1##*:}"};
        local i=${#COMPREPLY[*]};
        while [[ $((--i)) -ge 0 ]]; do
            COMPREPLY[$i]=${COMPREPLY[$i]#"$colon_word"};
        done;
    fi
}
__parse_options () 
{ 
    local option option2 i IFS=' 	
,/|';
    option=;
    local -a array=($1);
    for i in "${array[@]}";
    do
        case "$i" in 
            ---*)
                break
            ;;
            --?*)
                option=$i;
                break
            ;;
            -?*)
                [[ -n $option ]] || option=$i
            ;;
            *)
                break
            ;;
        esac;
    done;
    [[ -n $option ]] || return 0;
    IFS=' 	
';
    if [[ $option =~ (\[((no|dont)-?)\]). ]]; then
        option2=${option/"${BASH_REMATCH[1]}"/};
        option2=${option2%%[<{().[]*};
        printf '%s\n' "${option2/=*/=}";
        option=${option/"${BASH_REMATCH[1]}"/"${BASH_REMATCH[2]}"};
    fi;
    option=${option%%[<{().[]*};
    printf '%s\n' "${option/=*/=}"
}
__promptline () 
{ 
    local last_exit_code="${PROMPTLINE_LAST_EXIT_CODE:-$?}";
    local esc='[' end_esc=m;
    if [[ -n ${ZSH_VERSION-} ]]; then
        local noprint='%{' end_noprint='%}';
    else
        if [[ -n ${FISH_VERSION-} ]]; then
            local noprint='' end_noprint='';
        else
            local noprint='\[' end_noprint='\]';
        fi;
    fi;
    local wrap="$noprint$esc" end_wrap="$end_esc$end_noprint";
    local space=" ";
    local sep="";
    local rsep="";
    local alt_sep="|";
    local alt_rsep="|";
    local reset="${wrap}0${end_wrap}";
    local reset_bg="${wrap}49${end_wrap}";
    local a_fg="${wrap}38;5;220${end_wrap}";
    local a_bg="${wrap}48;5;166${end_wrap}";
    local a_sep_fg="${wrap}38;5;166${end_wrap}";
    local b_fg="${wrap}38;5;231${end_wrap}";
    local b_bg="${wrap}48;5;31${end_wrap}";
    local b_sep_fg="${wrap}38;5;31${end_wrap}";
    local c_fg="${wrap}38;5;250${end_wrap}";
    local c_bg="${wrap}48;5;240${end_wrap}";
    local c_sep_fg="${wrap}38;5;240${end_wrap}";
    local warn_fg="${wrap}38;5;231${end_wrap}";
    local warn_bg="${wrap}48;5;52${end_wrap}";
    local warn_sep_fg="${wrap}38;5;52${end_wrap}";
    local y_fg="${wrap}38;5;250${end_wrap}";
    local y_bg="${wrap}48;5;236${end_wrap}";
    local y_sep_fg="${wrap}38;5;236${end_wrap}";
    if [[ -n ${ZSH_VERSION-} ]]; then
        PROMPT="$(__promptline_left_prompt)";
        RPROMPT="$(__promptline_right_prompt)";
    else
        if [[ -n ${FISH_VERSION-} ]]; then
            if [[ -n "$1" ]]; then
                [[ "$1" = "left" ]] && __promptline_left_prompt || __promptline_right_prompt;
            else
                __promptline_ps1;
            fi;
        else
            PS1="$(__promptline_ps1)";
        fi;
    fi
}
__promptline_cwd () 
{ 
    local dir_limit="${dir_limit:-3}";
    local truncation="${truncation:-...}";
    local first_char;
    local part_count=0;
    local formatted_cwd="";
    local dir_sep=${dir_sep:-" / "};
    local tilde="~";
    local cwd="${PWD/#$HOME/$tilde}";
    [[ -n ${ZSH_VERSION-} ]] && first_char=$cwd[1,1] || first_char=${cwd::1};
    cwd="${cwd#\~}";
    while [[ "$cwd" == */* && "$cwd" != "/" ]]; do
        local part="${cwd##*/}";
        cwd="${cwd%/*}";
        formatted_cwd="$dir_sep$part$formatted_cwd";
        part_count=$((part_count+1));
        [[ $part_count -eq $dir_limit ]] && first_char="$truncation" && break;
    done;
    printf "%s" "$first_char$formatted_cwd"
}
__promptline_host () 
{ 
    local only_if_ssh="0";
    if [ $only_if_ssh -eq 0 -o -n "${SSH_CLIENT}" ]; then
        if [[ -n ${ZSH_VERSION-} ]]; then
            print %m;
        else
            if [[ -n ${FISH_VERSION-} ]]; then
                hostname -s;
            else
                printf "%s" \\h;
            fi;
        fi;
    fi
}
__promptline_last_exit_code () 
{ 
    [[ $last_exit_code -gt 0 ]] || return 1;
    printf "%s" "$last_exit_code"
}
__promptline_left_prompt () 
{ 
    local slice_prefix slice_empty_prefix slice_joiner slice_suffix is_prompt_empty=1;
    slice_prefix="${a_bg}${sep}${a_fg}${a_bg}${space}" slice_suffix="$space${a_sep_fg}" slice_joiner="${a_fg}${a_bg}${alt_sep}${space}" slice_empty_prefix="${a_fg}${a_bg}${space}";
    [ $is_prompt_empty -eq 1 ] && slice_prefix="$slice_empty_prefix";
    __promptline_wrapper "$(__promptline_host)" "$slice_prefix" "$slice_suffix" && { 
        slice_prefix="$slice_joiner";
        is_prompt_empty=0
    };
    slice_prefix="${b_bg}${sep}${b_fg}${b_bg}${space}" slice_suffix="$space${b_sep_fg}" slice_joiner="${b_fg}${b_bg}${alt_sep}${space}" slice_empty_prefix="${b_fg}${b_bg}${space}";
    [ $is_prompt_empty -eq 1 ] && slice_prefix="$slice_empty_prefix";
    __promptline_wrapper "$USER" "$slice_prefix" "$slice_suffix" && { 
        slice_prefix="$slice_joiner";
        is_prompt_empty=0
    };
    slice_prefix="${c_bg}${sep}${c_fg}${c_bg}${space}" slice_suffix="$space${c_sep_fg}" slice_joiner="${c_fg}${c_bg}${alt_sep}${space}" slice_empty_prefix="${c_fg}${c_bg}${space}";
    [ $is_prompt_empty -eq 1 ] && slice_prefix="$slice_empty_prefix";
    __promptline_wrapper "$(__promptline_cwd)" "$slice_prefix" "$slice_suffix" && { 
        slice_prefix="$slice_joiner";
        is_prompt_empty=0
    };
    printf "%s" "${reset_bg}${sep}$reset$space"
}
__promptline_ps1 () 
{ 
    local slice_prefix slice_empty_prefix slice_joiner slice_suffix is_prompt_empty=1;
    slice_prefix="${a_bg}${sep}${a_fg}${a_bg}${space}" slice_suffix="$space${a_sep_fg}" slice_joiner="${a_fg}${a_bg}${alt_sep}${space}" slice_empty_prefix="${a_fg}${a_bg}${space}";
    [ $is_prompt_empty -eq 1 ] && slice_prefix="$slice_empty_prefix";
    __promptline_wrapper "${shortprompt-$(__promptline_host)}" "$slice_prefix" "$slice_suffix" && { 
        slice_prefix="$slice_joiner";
        is_prompt_empty=0
    };
    slice_prefix="${b_bg}${sep}${b_fg}${b_bg}${space}" slice_suffix="$space${b_sep_fg}" slice_joiner="${b_fg}${b_bg}${alt_sep}${space}" slice_empty_prefix="${b_fg}${b_bg}${space}";
    [ $is_prompt_empty -eq 1 ] && slice_prefix="$slice_empty_prefix";
    __promptline_wrapper "${shortprompt-$USER}" "$slice_prefix" "$slice_suffix" && { 
        slice_prefix="$slice_joiner";
        is_prompt_empty=0
    };
    slice_prefix="${c_bg}${sep}${c_fg}${c_bg}${space}" slice_suffix="$space${c_sep_fg}" slice_joiner="${c_fg}${c_bg}${alt_sep}${space}" slice_empty_prefix="${c_fg}${c_bg}${space}";
    [ $is_prompt_empty -eq 1 ] && slice_prefix="$slice_empty_prefix";
    __promptline_wrapper "$(__promptline_cwd)" "$slice_prefix" "$slice_suffix" && { 
        slice_prefix="$slice_joiner";
        is_prompt_empty=0
    };
    slice_prefix="${y_bg}${sep}${y_fg}${y_bg}${space}" slice_suffix="$space${y_sep_fg}" slice_joiner="${y_fg}${y_bg}${alt_sep}${space}" slice_empty_prefix="${y_fg}${y_bg}${space}";
    [ $is_prompt_empty -eq 1 ] && slice_prefix="$slice_empty_prefix";
    __promptline_wrapper "$(__promptline_vcs_branch)" "$slice_prefix" "$slice_suffix" && { 
        slice_prefix="$slice_joiner";
        is_prompt_empty=0
    };
    slice_prefix="${warn_bg}${sep}${warn_fg}${warn_bg}${space}" slice_suffix="$space${warn_sep_fg}" slice_joiner="${warn_fg}${warn_bg}${alt_sep}${space}" slice_empty_prefix="${warn_fg}${warn_bg}${space}";
    [ $is_prompt_empty -eq 1 ] && slice_prefix="$slice_empty_prefix";
    __promptline_wrapper "$(__promptline_last_exit_code)" "$slice_prefix" "$slice_suffix" && { 
        slice_prefix="$slice_joiner";
        is_prompt_empty=0
    };
    printf "%s" "${reset_bg}${sep}$reset$space"
}
__promptline_right_prompt () 
{ 
    local slice_prefix slice_empty_prefix slice_joiner slice_suffix;
    slice_prefix="${warn_sep_fg}${rsep}${warn_fg}${warn_bg}${space}" slice_suffix="$space${warn_sep_fg}" slice_joiner="${warn_fg}${warn_bg}${alt_rsep}${space}" slice_empty_prefix="";
    __promptline_wrapper "$(__promptline_last_exit_code)" "$slice_prefix" "$slice_suffix" && { 
        slice_prefix="$slice_joiner"
    };
    slice_prefix="${y_sep_fg}${rsep}${y_fg}${y_bg}${space}" slice_suffix="$space${y_sep_fg}" slice_joiner="${y_fg}${y_bg}${alt_rsep}${space}" slice_empty_prefix="";
    __promptline_wrapper "$(__promptline_vcs_branch)" "$slice_prefix" "$slice_suffix" && { 
        slice_prefix="$slice_joiner"
    };
    printf "%s" "$reset"
}
__promptline_vcs_branch () 
{ 
    local branch;
    local branch_symbol="";
    if [[ -n "$K8S_PROMPT" ]]; then
        ns=$(kubectl config view --minify -o jsonpath='{.contexts[0].name}/{.contexts[0].context.namespace}');
        printf "$ns";
        return;
    fi;
    if hash git 2> /dev/null; then
        if branch=$( { git symbolic-ref --quiet HEAD || git rev-parse --short HEAD; } 2>/dev/null ); then
            branch=${branch##*/};
            printf "%s" "${branch_symbol}${branch:-unknown}";
            return;
        fi;
    fi;
    return 1
}
__promptline_wrapper () 
{ 
    [[ -n "$1" ]] || return 1;
    printf "%s" "${2}${1}${3}"
}
__reassemble_comp_words_by_ref () 
{ 
    local exclude i j line ref;
    if [[ -n $1 ]]; then
        exclude="${1//[^$COMP_WORDBREAKS]}";
    fi;
    printf -v "$3" %s "$COMP_CWORD";
    if [[ -n $exclude ]]; then
        line=$COMP_LINE;
        for ((i=0, j=0; i < ${#COMP_WORDS[@]}; i++, j++))
        do
            while [[ $i -gt 0 && ${COMP_WORDS[$i]} == +([$exclude]) ]]; do
                [[ $line != [[:blank:]]* ]] && (( j >= 2 )) && ((j--));
                ref="$2[$j]";
                printf -v "$ref" %s "${!ref}${COMP_WORDS[i]}";
                [[ $i == $COMP_CWORD ]] && printf -v "$3" %s "$j";
                line=${line#*"${COMP_WORDS[$i]}"};
                [[ $line == [[:blank:]]* ]] && ((j++));
                (( $i < ${#COMP_WORDS[@]} - 1)) && ((i++)) || break 2;
            done;
            ref="$2[$j]";
            printf -v "$ref" %s "${!ref}${COMP_WORDS[i]}";
            line=${line#*"${COMP_WORDS[i]}"};
            [[ $i == $COMP_CWORD ]] && printf -v "$3" %s "$j";
        done;
        [[ $i == $COMP_CWORD ]] && printf -v "$3" %s "$j";
    else
        for i in "${!COMP_WORDS[@]}";
        do
            printf -v "$2[i]" %s "${COMP_WORDS[i]}";
        done;
    fi
}
__start_helm () 
{ 
    local cur prev words cword split;
    COMPREPLY=();
    if declare -F _init_completion > /dev/null 2>&1; then
        _init_completion -n "=:" || return;
    else
        __helm_init_completion -n "=:" || return;
    fi;
    __helm_debug;
    __helm_debug "========= starting completion logic ==========";
    __helm_debug "cur is ${cur}, words[*] is ${words[*]}, #words[@] is ${#words[@]}, cword is $cword";
    words=("${words[@]:0:$cword+1}");
    __helm_debug "Truncated words[*]: ${words[*]},";
    local out directive;
    __helm_get_completion_results;
    __helm_process_completion_results
}
__start_kubectl () 
{ 
    local cur prev words cword split;
    COMPREPLY=();
    if declare -F _init_completion > /dev/null 2>&1; then
        _init_completion -n =: || return;
    else
        __kubectl_init_completion -n =: || return;
    fi;
    __kubectl_debug;
    __kubectl_debug "========= starting completion logic ==========";
    __kubectl_debug "cur is ${cur}, words[*] is ${words[*]}, #words[@] is ${#words[@]}, cword is $cword";
    words=("${words[@]:0:$cword+1}");
    __kubectl_debug "Truncated words[*]: ${words[*]},";
    local out directive;
    __kubectl_get_completion_results;
    __kubectl_process_completion_results
}
_allowed_groups () 
{ 
    if _complete_as_root; then
        local IFS='
';
        COMPREPLY=($(compgen -g -- "$1"));
    else
        local IFS='
 ';
        COMPREPLY=($(compgen -W             "$(id -Gn 2>/dev/null || groups 2>/dev/null)" -- "$1"));
    fi
}
_allowed_users () 
{ 
    if _complete_as_root; then
        local IFS='
';
        COMPREPLY=($(compgen -u -- "${1:-$cur}"));
    else
        local IFS='
 ';
        COMPREPLY=($(compgen -W             "$(id -un 2>/dev/null || whoami 2>/dev/null)" -- "${1:-$cur}"));
    fi
}
_available_interfaces () 
{ 
    local PATH=$PATH:/sbin;
    COMPREPLY=($({
        if [[ ${1:-} == -w ]]; then
            iwconfig
        elif [[ ${1:-} == -a ]]; then
            ifconfig || ip link show up
        else
            ifconfig -a || ip link show
        fi
    } 2>/dev/null | awk         '/^[^ \t]/ { if ($1 ~ /^[0-9]+:/) { print $2 } else { print $1 } }'));
    COMPREPLY=($(compgen -W '${COMPREPLY[@]/%[[:punct:]]/}' -- "$cur"))
}
_cd () 
{ 
    local cur prev words cword;
    _init_completion || return;
    local IFS='
' i j k;
    compopt -o filenames;
    if [[ -z "${CDPATH:-}" || "$cur" == ?(.)?(.)/* ]]; then
        _filedir -d;
        return;
    fi;
    local -r mark_dirs=$(_rl_enabled mark-directories && echo y);
    local -r mark_symdirs=$(_rl_enabled mark-symlinked-directories && echo y);
    for i in ${CDPATH//:/'
'};
    do
        k="${#COMPREPLY[@]}";
        for j in $(compgen -d -- $i/$cur);
        do
            if [[ ( -n $mark_symdirs && -h $j || -n $mark_dirs && ! -h $j ) && ! -d ${j#$i/} ]]; then
                j+="/";
            fi;
            COMPREPLY[k++]=${j#$i/};
        done;
    done;
    _filedir -d;
    if [[ ${#COMPREPLY[@]} -eq 1 ]]; then
        i=${COMPREPLY[0]};
        if [[ "$i" == "$cur" && $i != "*/" ]]; then
            COMPREPLY[0]="${i}/";
        fi;
    fi;
    return
}
_cd_devices () 
{ 
    COMPREPLY+=($(compgen -f -d -X "!*/?([amrs])cd*" -- "${cur:-/dev/}"))
}
_command () 
{ 
    local offset i;
    offset=1;
    for ((i=1; i <= COMP_CWORD; i++ ))
    do
        if [[ "${COMP_WORDS[i]}" != -* ]]; then
            offset=$i;
            break;
        fi;
    done;
    _command_offset $offset
}
_command_offset () 
{ 
    local word_offset=$1 i j;
    for ((i=0; i < $word_offset; i++ ))
    do
        for ((j=0; j <= ${#COMP_LINE}; j++ ))
        do
            [[ "$COMP_LINE" == "${COMP_WORDS[i]}"* ]] && break;
            COMP_LINE=${COMP_LINE:1};
            ((COMP_POINT--));
        done;
        COMP_LINE=${COMP_LINE#"${COMP_WORDS[i]}"};
        ((COMP_POINT-=${#COMP_WORDS[i]}));
    done;
    for ((i=0; i <= COMP_CWORD - $word_offset; i++ ))
    do
        COMP_WORDS[i]=${COMP_WORDS[i+$word_offset]};
    done;
    for ((i; i <= COMP_CWORD; i++ ))
    do
        unset 'COMP_WORDS[i]';
    done;
    ((COMP_CWORD -= $word_offset));
    COMPREPLY=();
    local cur;
    _get_comp_words_by_ref cur;
    if [[ $COMP_CWORD -eq 0 ]]; then
        local IFS='
';
        compopt -o filenames;
        COMPREPLY=($(compgen -d -c -- "$cur"));
    else
        local cmd=${COMP_WORDS[0]} compcmd=${COMP_WORDS[0]};
        local cspec=$(complete -p $cmd 2>/dev/null);
        if [[ ! -n $cspec && $cmd == */* ]]; then
            cspec=$(complete -p ${cmd##*/} 2>/dev/null);
            [[ -n $cspec ]] && compcmd=${cmd##*/};
        fi;
        if [[ ! -n $cspec ]]; then
            compcmd=${cmd##*/};
            _completion_loader $compcmd;
            cspec=$(complete -p $compcmd 2>/dev/null);
        fi;
        if [[ -n $cspec ]]; then
            if [[ ${cspec#* -F } != $cspec ]]; then
                local func=${cspec#*-F };
                func=${func%% *};
                if [[ ${#COMP_WORDS[@]} -ge 2 ]]; then
                    $func $cmd "${COMP_WORDS[${#COMP_WORDS[@]}-1]}" "${COMP_WORDS[${#COMP_WORDS[@]}-2]}";
                else
                    $func $cmd "${COMP_WORDS[${#COMP_WORDS[@]}-1]}";
                fi;
                local opt;
                while [[ $cspec == *" -o "* ]]; do
                    cspec=${cspec#*-o };
                    opt=${cspec%% *};
                    compopt -o $opt;
                    cspec=${cspec#$opt};
                done;
            else
                cspec=${cspec#complete};
                cspec=${cspec%%$compcmd};
                COMPREPLY=($(eval compgen "$cspec" -- '$cur'));
            fi;
        else
            if [[ ${#COMPREPLY[@]} -eq 0 ]]; then
                _minimal;
            fi;
        fi;
    fi
}
_complete_alias () 
{ 
    local cmd="${COMP_WORDS[0]}";
    if ! alias "$cmd" &> /dev/null; then
        __compal__complete_non_alias "$@";
    else
        __compal__complete_alias "$@";
    fi
}
_complete_as_root () 
{ 
    [[ $EUID -eq 0 || -n ${root_command:-} ]]
}
_completion_loader () 
{ 
    local cmd="${1:-_EmptycmD_}";
    __load_completion "$cmd" && return 124;
    complete -F _minimal -- "$cmd" && return 124
}
_configured_interfaces () 
{ 
    if [[ -f /etc/debian_version ]]; then
        COMPREPLY=($(compgen -W "$(command sed -ne 's|^iface \([^ ]\{1,\}\).*$|\1|p'            /etc/network/interfaces /etc/network/interfaces.d/* 2>/dev/null)"             -- "$cur"));
    else
        if [[ -f /etc/SuSE-release ]]; then
            COMPREPLY=($(compgen -W "$(printf '%s\n'             /etc/sysconfig/network/ifcfg-* |             command sed -ne 's|.*ifcfg-\([^*].*\)$|\1|p')" -- "$cur"));
        else
            if [[ -f /etc/pld-release ]]; then
                COMPREPLY=($(compgen -W "$(command ls -B             /etc/sysconfig/interfaces |             command sed -ne 's|.*ifcfg-\([^*].*\)$|\1|p')" -- "$cur"));
            else
                COMPREPLY=($(compgen -W "$(printf '%s\n'             /etc/sysconfig/network-scripts/ifcfg-* |             command sed -ne 's|.*ifcfg-\([^*].*\)$|\1|p')" -- "$cur"));
            fi;
        fi;
    fi
}
_count_args () 
{ 
    local i cword words;
    __reassemble_comp_words_by_ref "$1" words cword;
    args=1;
    for ((i=1; i < cword; i++ ))
    do
        if [[ ${words[i]} != -* && ${words[i-1]} != $2 || ${words[i]} == $3 ]]; then
            (( args++ ));
        fi;
    done
}
_curl () 
{ 
    local cur prev words cword;
    _init_completion || return;
    case $prev in 
        --ciphers | --connect-timeout | --continue-at | --form | --form-string | --ftp-account | --ftp-alternative-to-user | --ftp-port | --header | --help | --hostpubmd5 | --keepalive-time | --krb | --limit-rate | --local-port | --mail-from | --mail-rcpt | --max-filesize | --max-redirs | --max-time | --pass | --proto | --proto-redir | --proxy-user | --proxy1.0 | --quote | --range | --request | --retry | --retry-delay | --retry-max-time | --socks5-gssapi-service | --telnet-option | --tftp-blksize | --time-cond | --url | --user | --user-agent | --version | --write-out | --resolve | --tlsuser | --tlspassword | -!(-*)[CFPHhmQrXtzuAVw])
            return
        ;;
        --config | --cookie | --cookie-jar | --dump-header | --egd-file | --key | --libcurl | --output | --random-file | --upload-file | --trace | --trace-ascii | --netrc-file | -!(-*)[KbcDoT])
            _filedir;
            return
        ;;
        --cacert | --cert | -!(-*)E)
            _filedir '@(c?(e)rt|cer|pem|der)';
            return
        ;;
        --capath)
            _filedir -d;
            return
        ;;
        --cert-type | --key-type)
            COMPREPLY=($(compgen -W 'DER PEM ENG' -- "$cur"));
            return
        ;;
        --crlfile)
            _filedir crl;
            return
        ;;
        --data | --data-ascii | --data-binary | --data-urlencode | -!(-*)d)
            if [[ $cur == \@* ]]; then
                cur=${cur:1};
                _filedir;
                if [[ ${#COMPREPLY[@]} -eq 1 && -d "${COMPREPLY[0]}" ]]; then
                    COMPREPLY[0]+=/;
                    compopt -o nospace;
                fi;
                COMPREPLY=("${COMPREPLY[@]/#/@}");
            fi;
            return
        ;;
        --delegation)
            COMPREPLY=($(compgen -W 'none policy always' -- "$cur"));
            return
        ;;
        --engine)
            COMPREPLY=($(compgen -W 'list' -- "$cur"));
            return
        ;;
        --ftp-method)
            COMPREPLY=($(compgen -W 'multicwd nocwd singlecwd' -- "$cur"));
            return
        ;;
        --ftp-ssl-ccc-mode)
            COMPREPLY=($(compgen -W 'active passive' -- "$cur"));
            return
        ;;
        --interface)
            _available_interfaces -a;
            return
        ;;
        --proxy | --socks4 | --socks4a | --socks5 | --socks5-hostname | -!(-*)x)
            _known_hosts_real -- "$cur";
            return
        ;;
        --pubkey)
            _xfunc ssh _ssh_identityfile pub;
            return
        ;;
        --stderr)
            COMPREPLY=($(compgen -W '-' -- "$cur"));
            _filedir;
            return
        ;;
        --tlsauthtype)
            COMPREPLY=($(compgen -W 'SRP' -- "$cur"));
            return
        ;;
    esac;
    if [[ $cur == -* ]]; then
        COMPREPLY=($(compgen -W '$(_parse_help "$1")' -- "$cur"));
    fi
}
_dvd_devices () 
{ 
    COMPREPLY+=($(compgen -f -d -X "!*/?(r)dvd*" -- "${cur:-/dev/}"))
}
_expand () 
{ 
    if [[ "$cur" == \~*/* ]]; then
        __expand_tilde_by_ref cur;
    else
        if [[ "$cur" == \~* ]]; then
            _tilde "$cur" || eval COMPREPLY[0]=$(printf ~%q "${COMPREPLY[0]#\~}");
            return ${#COMPREPLY[@]};
        fi;
    fi
}
_filedir () 
{ 
    local IFS='
';
    _tilde "$cur" || return;
    local -a toks;
    local reset;
    if [[ "$1" == -d ]]; then
        reset=$(shopt -po noglob);
        set -o noglob;
        toks=($(compgen -d -- "$cur"));
        IFS=' ';
        $reset;
        IFS='
';
    else
        local quoted;
        _quote_readline_by_ref "$cur" quoted;
        local xspec=${1:+"!*.@($1|${1^^})"} plusdirs=();
        local opts=(-f -X "$xspec");
        [[ -n $xspec ]] && plusdirs=(-o plusdirs);
        [[ -n ${COMP_FILEDIR_FALLBACK-} ]] || opts+=("${plusdirs[@]}");
        reset=$(shopt -po noglob);
        set -o noglob;
        toks+=($(compgen "${opts[@]}" -- $quoted));
        IFS=' ';
        $reset;
        IFS='
';
        [[ -n ${COMP_FILEDIR_FALLBACK:-} && -n "$1" && ${#toks[@]} -lt 1 ]] && { 
            reset=$(shopt -po noglob);
            set -o noglob;
            toks+=($(compgen -f "${plusdirs[@]}" -- $quoted));
            IFS=' ';
            $reset;
            IFS='
'
        };
    fi;
    if [[ ${#toks[@]} -ne 0 ]]; then
        compopt -o filenames 2> /dev/null;
        COMPREPLY+=("${toks[@]}");
    fi
}
_filedir_xspec () 
{ 
    local cur prev words cword;
    _init_completion || return;
    _tilde "$cur" || return;
    local IFS='
' xspec=${_xspecs[${1##*/}]} tmp;
    local -a toks;
    toks=($(
        compgen -d -- "$(quote_readline "$cur")" | {
        while read -r tmp; do
            printf '%s\n' $tmp
        done
        }
        ));
    eval xspec="${xspec}";
    local matchop=!;
    if [[ $xspec == !* ]]; then
        xspec=${xspec#!};
        matchop=@;
    fi;
    xspec="$matchop($xspec|${xspec^^})";
    toks+=($(
        eval compgen -f -X "'!$xspec'" -- "\$(quote_readline "\$cur")" | {
        while read -r tmp; do
            [[ -n $tmp ]] && printf '%s\n' $tmp
        done
        }
        ));
    [[ -n ${COMP_FILEDIR_FALLBACK:-} && ${#toks[@]} -lt 1 ]] && { 
        local reset=$(shopt -po noglob);
        set -o noglob;
        toks+=($(compgen -f -- "$(quote_readline "$cur")"));
        IFS=' ';
        $reset;
        IFS='
'
    };
    if [[ ${#toks[@]} -ne 0 ]]; then
        compopt -o filenames;
        COMPREPLY=("${toks[@]}");
    fi
}
_fstypes () 
{ 
    local fss;
    if [[ -e /proc/filesystems ]]; then
        fss="$(cut -d'	' -f2 /proc/filesystems)
             $(awk '! /\*/ { print $NF }' /etc/filesystems 2>/dev/null)";
    else
        fss="$(awk '/^[ \t]*[^#]/ { print $3 }' /etc/fstab 2>/dev/null)
             $(awk '/^[ \t]*[^#]/ { print $3 }' /etc/mnttab 2>/dev/null)
             $(awk '/^[ \t]*[^#]/ { print $4 }' /etc/vfstab 2>/dev/null)
             $(awk '{ print $1 }' /etc/dfs/fstypes 2>/dev/null)
             $([[ -d /etc/fs ]] && command ls /etc/fs)";
    fi;
    [[ -n $fss ]] && COMPREPLY+=($(compgen -W "$fss" -- "$cur"))
}
_get_comp_words_by_ref () 
{ 
    local exclude flag i OPTIND=1;
    local cur cword words=();
    local upargs=() upvars=() vcur vcword vprev vwords;
    while getopts "c:i:n:p:w:" flag "$@"; do
        case $flag in 
            c)
                vcur=$OPTARG
            ;;
            i)
                vcword=$OPTARG
            ;;
            n)
                exclude=$OPTARG
            ;;
            p)
                vprev=$OPTARG
            ;;
            w)
                vwords=$OPTARG
            ;;
        esac;
    done;
    while [[ $# -ge $OPTIND ]]; do
        case ${!OPTIND} in 
            cur)
                vcur=cur
            ;;
            prev)
                vprev=prev
            ;;
            cword)
                vcword=cword
            ;;
            words)
                vwords=words
            ;;
            *)
                echo "bash_completion: $FUNCNAME: \`${!OPTIND}':" "unknown argument" 1>&2;
                return 1
            ;;
        esac;
        (( OPTIND += 1 ));
    done;
    __get_cword_at_cursor_by_ref "$exclude" words cword cur;
    [[ -n $vcur ]] && { 
        upvars+=("$vcur");
        upargs+=(-v $vcur "$cur")
    };
    [[ -n $vcword ]] && { 
        upvars+=("$vcword");
        upargs+=(-v $vcword "$cword")
    };
    [[ -n $vprev && $cword -ge 1 ]] && { 
        upvars+=("$vprev");
        upargs+=(-v $vprev "${words[cword - 1]}")
    };
    [[ -n $vwords ]] && { 
        upvars+=("$vwords");
        upargs+=(-a${#words[@]} $vwords "${words[@]}")
    };
    (( ${#upvars[@]} )) && local "${upvars[@]}" && _upvars "${upargs[@]}"
}
_get_cword () 
{ 
    local LC_CTYPE=C;
    local cword words;
    __reassemble_comp_words_by_ref "$1" words cword;
    if [[ -n ${2//[^0-9]/} ]]; then
        printf "%s" "${words[cword-$2]}";
    else
        if [[ "${#words[cword]}" -eq 0 || "$COMP_POINT" == "${#COMP_LINE}" ]]; then
            printf "%s" "${words[cword]}";
        else
            local i;
            local cur="$COMP_LINE";
            local index="$COMP_POINT";
            for ((i = 0; i <= cword; ++i ))
            do
                while [[ "${#cur}" -ge ${#words[i]} && "${cur:0:${#words[i]}}" != "${words[i]}" ]]; do
                    cur="${cur:1}";
                    [[ $index -gt 0 ]] && ((index--));
                done;
                if [[ "$i" -lt "$cword" ]]; then
                    local old_size="${#cur}";
                    cur="${cur#${words[i]}}";
                    local new_size="${#cur}";
                    (( index -= old_size - new_size ));
                fi;
            done;
            if [[ "${words[cword]:0:${#cur}}" != "$cur" ]]; then
                printf "%s" "${words[cword]}";
            else
                printf "%s" "${cur:0:$index}";
            fi;
        fi;
    fi
}
_get_first_arg () 
{ 
    local i;
    arg=;
    for ((i=1; i < COMP_CWORD; i++ ))
    do
        if [[ "${COMP_WORDS[i]}" != -* ]]; then
            arg=${COMP_WORDS[i]};
            break;
        fi;
    done
}
_get_pword () 
{ 
    if [[ $COMP_CWORD -ge 1 ]]; then
        _get_cword "${@:-}" 1;
    fi
}
_gids () 
{ 
    if type getent &> /dev/null; then
        COMPREPLY=($(compgen -W '$(getent group | cut -d: -f3)' -- "$cur"));
    else
        if type perl &> /dev/null; then
            COMPREPLY=($(compgen -W '$(perl -e '"'"'while (($gid) = (getgrent)[2]) { print $gid . "\n" }'"'"')' -- "$cur"));
        else
            COMPREPLY=($(compgen -W '$(cut -d: -f3 /etc/group)' -- "$cur"));
        fi;
    fi
}
_have () 
{ 
    PATH=$PATH:/usr/sbin:/sbin:/usr/local/sbin type $1 &> /dev/null
}
_included_ssh_config_files () 
{ 
    [[ $# -lt 1 ]] && echo "bash_completion: $FUNCNAME: missing mandatory argument CONFIG" 1>&2;
    local configfile i f;
    configfile=$1;
    local included=($(command sed -ne 's/^[[:blank:]]*[Ii][Nn][Cc][Ll][Uu][Dd][Ee][[:blank:]]\{1,\}\([^#%]*\)\(#.*\)\{0,1\}$/\1/p' "${configfile}"));
    for i in "${included[@]}";
    do
        if ! [[ "$i" =~ ^\~.*|^\/.* ]]; then
            if [[ "$configfile" =~ ^\/etc\/ssh.* ]]; then
                i="/etc/ssh/$i";
            else
                i="$HOME/.ssh/$i";
            fi;
        fi;
        __expand_tilde_by_ref i;
        for f in ${i};
        do
            if [ -r $f ]; then
                config+=("$f");
                _included_ssh_config_files $f;
            fi;
        done;
    done
}
_init_completion () 
{ 
    local exclude="" flag outx errx inx OPTIND=1;
    while getopts "n:e:o:i:s" flag "$@"; do
        case $flag in 
            n)
                exclude+=$OPTARG
            ;;
            e)
                errx=$OPTARG
            ;;
            o)
                outx=$OPTARG
            ;;
            i)
                inx=$OPTARG
            ;;
            s)
                split=false;
                exclude+==
            ;;
        esac;
    done;
    COMPREPLY=();
    local redir="@(?([0-9])<|?([0-9&])>?(>)|>&)";
    _get_comp_words_by_ref -n "$exclude<>&" cur prev words cword;
    _variables && return 1;
    if [[ $cur == $redir* || $prev == $redir ]]; then
        local xspec;
        case $cur in 
            2'>'*)
                xspec=$errx
            ;;
            *'>'*)
                xspec=$outx
            ;;
            *'<'*)
                xspec=$inx
            ;;
            *)
                case $prev in 
                    2'>'*)
                        xspec=$errx
                    ;;
                    *'>'*)
                        xspec=$outx
                    ;;
                    *'<'*)
                        xspec=$inx
                    ;;
                esac
            ;;
        esac;
        cur="${cur##$redir}";
        _filedir $xspec;
        return 1;
    fi;
    local i skip;
    for ((i=1; i < ${#words[@]}; 1))
    do
        if [[ ${words[i]} == $redir* ]]; then
            [[ ${words[i]} == $redir ]] && skip=2 || skip=1;
            words=("${words[@]:0:i}" "${words[@]:i+skip}");
            [[ $i -le $cword ]] && (( cword -= skip ));
        else
            (( i++ ));
        fi;
    done;
    [[ $cword -le 0 ]] && return 1;
    prev=${words[cword-1]};
    [[ -n ${split-} ]] && _split_longopt && split=true;
    return 0
}
_installed_modules () 
{ 
    COMPREPLY=($(compgen -W "$(PATH="$PATH:/sbin" lsmod |         awk '{if (NR != 1) print $1}')" -- "$1"))
}
_ip_addresses () 
{ 
    local n;
    case $1 in 
        -a)
            n='6\?'
        ;;
        -6)
            n='6'
        ;;
    esac;
    local PATH=$PATH:/sbin;
    local addrs=$({ LC_ALL=C ifconfig -a || ip addr show; } 2>/dev/null |
        command sed -e 's/[[:space:]]addr:/ /' -ne             "s|.*inet${n}[[:space:]]\{1,\}\([^[:space:]/]*\).*|\1|p");
    COMPREPLY+=($(compgen -W "$addrs" -- "$cur"))
}
_kernel_versions () 
{ 
    COMPREPLY=($(compgen -W '$(command ls /lib/modules)' -- "$cur"))
}
_known_hosts () 
{ 
    local cur prev words cword;
    _init_completion -n : || return;
    local options;
    [[ "$1" == -a || "$2" == -a ]] && options=-a;
    [[ "$1" == -c || "$2" == -c ]] && options+=" -c";
    _known_hosts_real $options -- "$cur"
}
_known_hosts_real () 
{ 
    local configfile flag prefix OIFS=$IFS;
    local cur user suffix aliases i host ipv4 ipv6;
    local -a kh tmpkh khd config;
    local OPTIND=1;
    while getopts "ac46F:p:" flag "$@"; do
        case $flag in 
            a)
                aliases='yes'
            ;;
            c)
                suffix=':'
            ;;
            F)
                configfile=$OPTARG
            ;;
            p)
                prefix=$OPTARG
            ;;
            4)
                ipv4=1
            ;;
            6)
                ipv6=1
            ;;
        esac;
    done;
    [[ $# -lt $OPTIND ]] && echo "bash_completion: $FUNCNAME: missing mandatory argument CWORD" 1>&2;
    cur=${!OPTIND};
    (( OPTIND += 1 ));
    [[ $# -ge $OPTIND ]] && echo "bash_completion: $FUNCNAME($*): unprocessed arguments:" $(while [[ $# -ge $OPTIND ]]; do printf '%s\n' ${!OPTIND}; shift; done) 1>&2;
    [[ $cur == *@* ]] && user=${cur%@*}@ && cur=${cur#*@};
    kh=();
    if [[ -n $configfile ]]; then
        [[ -r $configfile ]] && config+=("$configfile");
    else
        for i in /etc/ssh/ssh_config ~/.ssh/config ~/.ssh2/config;
        do
            [[ -r $i ]] && config+=("$i");
        done;
    fi;
    for i in "${config[@]}";
    do
        _included_ssh_config_files "$i";
    done;
    if [[ ${#config[@]} -gt 0 ]]; then
        local IFS='
' j;
        tmpkh=($(awk 'sub("^[ \t]*([Gg][Ll][Oo][Bb][Aa][Ll]|[Uu][Ss][Ee][Rr])[Kk][Nn][Oo][Ww][Nn][Hh][Oo][Ss][Tt][Ss][Ff][Ii][Ll][Ee][ \t]+", "") { print $0 }' "${config[@]}" | sort -u));
        IFS=$OIFS;
        for i in "${tmpkh[@]}";
        do
            while [[ $i =~ ^([^\"]*)\"([^\"]*)\"(.*)$ ]]; do
                i=${BASH_REMATCH[1]}${BASH_REMATCH[3]};
                j=${BASH_REMATCH[2]};
                __expand_tilde_by_ref j;
                [[ -r $j ]] && kh+=("$j");
            done;
            for j in $i;
            do
                __expand_tilde_by_ref j;
                [[ -r $j ]] && kh+=("$j");
            done;
        done;
    fi;
    if [[ -z $configfile ]]; then
        for i in /etc/ssh/ssh_known_hosts /etc/ssh/ssh_known_hosts2 /etc/known_hosts /etc/known_hosts2 ~/.ssh/known_hosts ~/.ssh/known_hosts2;
        do
            [[ -r $i ]] && kh+=("$i");
        done;
        for i in /etc/ssh2/knownhosts ~/.ssh2/hostkeys;
        do
            [[ -d $i ]] && khd+=("$i"/*pub);
        done;
    fi;
    if [[ ${#kh[@]} -gt 0 || ${#khd[@]} -gt 0 ]]; then
        if [[ ${#kh[@]} -gt 0 ]]; then
            for i in "${kh[@]}";
            do
                while read -ra tmpkh; do
                    set -- "${tmpkh[@]}";
                    [[ $1 == [\|\#]* ]] && continue;
                    [[ $1 == @* ]] && shift;
                    local IFS=,;
                    for host in $1;
                    do
                        [[ $host == *[*?]* ]] && continue;
                        host="${host#[}";
                        host="${host%]?(:+([0-9]))}";
                        COMPREPLY+=($host);
                    done;
                    IFS=$OIFS;
                done < "$i";
            done;
            COMPREPLY=($(compgen -W '${COMPREPLY[@]}' -- "$cur"));
        fi;
        if [[ ${#khd[@]} -gt 0 ]]; then
            for i in "${khd[@]}";
            do
                if [[ "$i" == *key_22_$cur*.pub && -r "$i" ]]; then
                    host=${i/#*key_22_/};
                    host=${host/%.pub/};
                    COMPREPLY+=($host);
                fi;
            done;
        fi;
        for ((i=0; i < ${#COMPREPLY[@]}; i++ ))
        do
            COMPREPLY[i]=$prefix$user${COMPREPLY[i]}$suffix;
        done;
    fi;
    if [[ ${#config[@]} -gt 0 && -n "$aliases" ]]; then
        local hosts=$(command sed -ne 's/^[[:blank:]]*[Hh][Oo][Ss][Tt][[:blank:]]\{1,\}\([^#*?%]*\)\(#.*\)\{0,1\}$/\1/p' "${config[@]}");
        COMPREPLY+=($(compgen -P "$prefix$user"             -S "$suffix" -W "$hosts" -- "$cur"));
    fi;
    if [[ -n ${COMP_KNOWN_HOSTS_WITH_AVAHI:-} ]] && type avahi-browse &> /dev/null; then
        COMPREPLY+=($(compgen -P "$prefix$user" -S "$suffix" -W             "$(avahi-browse -cpr _workstation._tcp 2>/dev/null |                awk -F';' '/^=/ { print $7 }' | sort -u)" -- "$cur"));
    fi;
    COMPREPLY+=($(compgen -W         "$(ruptime 2>/dev/null | awk '!/^ruptime:/ { print $1 }')"         -- "$cur"));
    if [[ -n ${COMP_KNOWN_HOSTS_WITH_HOSTFILE-1} ]]; then
        COMPREPLY+=($(compgen -A hostname -P "$prefix$user" -S "$suffix" -- "$cur"));
    fi;
    if [[ -n $ipv4 ]]; then
        COMPREPLY=("${COMPREPLY[@]/*:*$suffix/}");
    fi;
    if [[ -n $ipv6 ]]; then
        COMPREPLY=("${COMPREPLY[@]/+([0-9]).+([0-9]).+([0-9]).+([0-9])$suffix/}");
    fi;
    if [[ -n $ipv4 || -n $ipv6 ]]; then
        for i in "${!COMPREPLY[@]}";
        do
            [[ -n ${COMPREPLY[i]} ]] || unset -v COMPREPLY[i];
        done;
    fi;
    __ltrim_colon_completions "$prefix$user$cur"
}
_longopt () 
{ 
    local cur prev words cword split;
    _init_completion -s || return;
    case "${prev,,}" in 
        --help | --usage | --version)
            return
        ;;
        --!(no-*)dir*)
            _filedir -d;
            return
        ;;
        --!(no-*)@(file|path)*)
            _filedir;
            return
        ;;
        --+([-a-z0-9_]))
            local argtype=$(LC_ALL=C $1 --help 2>&1 | command sed -ne                 "s|.*$prev\[\{0,1\}=[<[]\{0,1\}\([-A-Za-z0-9_]\{1,\}\).*|\1|p");
            case ${argtype,,} in 
                *dir*)
                    _filedir -d;
                    return
                ;;
                *file* | *path*)
                    _filedir;
                    return
                ;;
            esac
        ;;
    esac;
    $split && return;
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "$(LC_ALL=C $1 --help 2>&1 |             while read -r line; do                 [[ $line =~ --[-A-Za-z0-9]+=? ]] &&                     printf '%s\n' ${BASH_REMATCH[0]}
            done)" -- "$cur"));
        [[ $COMPREPLY == *= ]] && compopt -o nospace;
    else
        if [[ "$1" == *@(rmdir|chroot) ]]; then
            _filedir -d;
        else
            [[ "$1" == *mkdir ]] && compopt -o nospace;
            _filedir;
        fi;
    fi
}
_mac_addresses () 
{ 
    local re='\([A-Fa-f0-9]\{2\}:\)\{5\}[A-Fa-f0-9]\{2\}';
    local PATH="$PATH:/sbin:/usr/sbin";
    COMPREPLY+=($(        { LC_ALL=C ifconfig -a || ip link show; } 2>/dev/null | command sed -ne         "s/.*[[:space:]]HWaddr[[:space:]]\{1,\}\($re\)[[:space:]].*/\1/p" -ne         "s/.*[[:space:]]HWaddr[[:space:]]\{1,\}\($re\)[[:space:]]*$/\1/p" -ne         "s|.*[[:space:]]\(link/\)\{0,1\}ether[[:space:]]\{1,\}\($re\)[[:space:]].*|\2|p" -ne         "s|.*[[:space:]]\(link/\)\{0,1\}ether[[:space:]]\{1,\}\($re\)[[:space:]]*$|\2|p"
        ));
    COMPREPLY+=($({ arp -an || ip neigh show; } 2>/dev/null | command sed -ne         "s/.*[[:space:]]\($re\)[[:space:]].*/\1/p" -ne         "s/.*[[:space:]]\($re\)[[:space:]]*$/\1/p"));
    COMPREPLY+=($(command sed -ne         "s/^[[:space:]]*\($re\)[[:space:]].*/\1/p" /etc/ethers 2>/dev/null));
    COMPREPLY=($(compgen -W '${COMPREPLY[@]}' -- "$cur"));
    __ltrim_colon_completions "$cur"
}
_minimal () 
{ 
    local cur prev words cword split;
    _init_completion -s || return;
    $split && return;
    _filedir
}
_modules () 
{ 
    local modpath;
    modpath=/lib/modules/$1;
    COMPREPLY=($(compgen -W "$(command ls -RL $modpath 2>/dev/null |         command sed -ne 's/^\(.*\)\.k\{0,1\}o\(\.[gx]z\)\{0,1\}$/\1/p')" -- "$cur"))
}
_ncpus () 
{ 
    local var=NPROCESSORS_ONLN;
    [[ $OSTYPE == *linux* ]] && var=_$var;
    local n=$(getconf $var 2>/dev/null);
    printf %s ${n:-1}
}
_parse_help () 
{ 
    eval local cmd=$(quote "$1");
    local line;
    { 
        case $cmd in 
            -)
                cat
            ;;
            *)
                LC_ALL=C "$(dequote "$cmd")" ${2:---help} 2>&1
            ;;
        esac
    } | while read -r line; do
        [[ $line == *([[:blank:]])-* ]] || continue;
        while [[ $line =~ ((^|[^-])-[A-Za-z0-9?][[:space:]]+)\[?[A-Z0-9]+([,_-]+[A-Z0-9]+)?(\.\.+)?\]? ]]; do
            line=${line/"${BASH_REMATCH[0]}"/"${BASH_REMATCH[1]}"};
        done;
        __parse_options "${line// or /, }";
    done
}
_parse_usage () 
{ 
    eval local cmd=$(quote "$1");
    local line match option i char;
    { 
        case $cmd in 
            -)
                cat
            ;;
            *)
                LC_ALL=C "$(dequote "$cmd")" ${2:---usage} 2>&1
            ;;
        esac
    } | while read -r line; do
        while [[ $line =~ \[[[:space:]]*(-[^]]+)[[:space:]]*\] ]]; do
            match=${BASH_REMATCH[0]};
            option=${BASH_REMATCH[1]};
            case $option in 
                -?(\[)+([a-zA-Z0-9?]))
                    for ((i=1; i < ${#option}; i++ ))
                    do
                        char=${option:i:1};
                        [[ $char != '[' ]] && printf '%s\n' -$char;
                    done
                ;;
                *)
                    __parse_options "$option"
                ;;
            esac;
            line=${line#*"$match"};
        done;
    done
}
_pci_ids () 
{ 
    COMPREPLY+=($(compgen -W         "$(PATH="$PATH:/sbin" lspci -n | awk '{print $3}')" -- "$cur"))
}
_pgids () 
{ 
    COMPREPLY=($(compgen -W '$(command ps axo pgid=)' -- "$cur"))
}
_pids () 
{ 
    COMPREPLY=($(compgen -W '$(command ps axo pid=)' -- "$cur"))
}
_pnames () 
{ 
    local -a procs;
    if [[ "$1" == -s ]]; then
        procs=($(command ps axo comm | command sed -e 1d));
    else
        local line i=-1 OIFS=$IFS;
        IFS='
';
        local -a psout=($(command ps axo command=));
        IFS=$OIFS;
        for line in "${psout[@]}";
        do
            if [[ $i -eq -1 ]]; then
                if [[ $line =~ ^(.*[[:space:]])COMMAND([[:space:]]|$) ]]; then
                    i=${#BASH_REMATCH[1]};
                else
                    break;
                fi;
            else
                line=${line:$i};
                line=${line%% *};
                procs+=($line);
            fi;
        done;
        if [[ $i -eq -1 ]]; then
            for line in "${psout[@]}";
            do
                if [[ $line =~ ^[[(](.+)[])]$ ]]; then
                    procs+=(${BASH_REMATCH[1]});
                else
                    line=${line%% *};
                    line=${line##@(*/|-)};
                    procs+=($line);
                fi;
            done;
        fi;
    fi;
    COMPREPLY=($(compgen -X "<defunct>" -W '${procs[@]}' -- "$cur" ))
}
_quote_readline_by_ref () 
{ 
    if [ -z "$1" ]; then
        printf -v $2 %s "$1";
    else
        if [[ $1 == \'* ]]; then
            printf -v $2 %s "${1:1}";
        else
            if [[ $1 == \~* ]]; then
                printf -v $2 \~%q "${1:1}";
            else
                printf -v $2 %q "$1";
            fi;
        fi;
    fi;
    [[ ${!2} == \$* ]] && eval $2=${!2}
}
_realcommand () 
{ 
    type -P "$1" > /dev/null && { 
        if type -p realpath > /dev/null; then
            realpath "$(type -P "$1")";
        else
            if type -p greadlink > /dev/null; then
                greadlink -f "$(type -P "$1")";
            else
                if type -p readlink > /dev/null; then
                    readlink -f "$(type -P "$1")";
                else
                    type -P "$1";
                fi;
            fi;
        fi
    }
}
_rl_enabled () 
{ 
    [[ "$(bind -v)" == *$1+([[:space:]])on* ]]
}
_root_command () 
{ 
    local PATH=$PATH:/sbin:/usr/sbin:/usr/local/sbin;
    local root_command=$1;
    _command
}
_service () 
{ 
    local cur prev words cword;
    _init_completion || return;
    [[ $cword -gt 2 ]] && return;
    if [[ $cword -eq 1 && $prev == ?(*/)service ]]; then
        _services;
        [[ -e /etc/mandrake-release ]] && _xinetd_services;
    else
        local sysvdirs;
        _sysvdirs;
        COMPREPLY=($(compgen -W '`command sed -e "y/|/ /" \
            -ne "s/^.*\(U\|msg_u\)sage.*{\(.*\)}.*$/\2/p" \
            ${sysvdirs[0]}/${prev##*/} 2>/dev/null` start stop' -- "$cur"));
    fi
}
_services () 
{ 
    local sysvdirs;
    _sysvdirs;
    local IFS=' 	
' reset=$(shopt -p nullglob);
    shopt -s nullglob;
    COMPREPLY=($(printf '%s\n' ${sysvdirs[0]}/!($_backup_glob|functions|README)));
    $reset;
    COMPREPLY+=($({ systemctl list-units --full --all ||                      systemctl list-unit-files; } 2>/dev/null |         awk '$1 ~ /\.service$/ { sub("\\.service$", "", $1); print $1 }'));
    if [[ -x /sbin/upstart-udev-bridge ]]; then
        COMPREPLY+=($(initctl list 2>/dev/null | cut -d' ' -f1));
    fi;
    COMPREPLY=($(compgen -W '${COMPREPLY[@]#${sysvdirs[0]}/}' -- "$cur"))
}
_shells () 
{ 
    local shell rest;
    while read -r shell rest; do
        [[ $shell == /* && $shell == "$cur"* ]] && COMPREPLY+=($shell);
    done 2> /dev/null < /etc/shells
}
_signals () 
{ 
    local -a sigs=($(compgen -P "$1" -A signal "SIG${cur#$1}"));
    COMPREPLY+=("${sigs[@]/#${1}SIG/${1}}")
}
_split_longopt () 
{ 
    if [[ "$cur" == --?*=* ]]; then
        prev="${cur%%?(\\)=*}";
        cur="${cur#*=}";
        return 0;
    fi;
    return 1
}
_sysvdirs () 
{ 
    sysvdirs=();
    [[ -d /etc/rc.d/init.d ]] && sysvdirs+=(/etc/rc.d/init.d);
    [[ -d /etc/init.d ]] && sysvdirs+=(/etc/init.d);
    [[ -f /etc/slackware-version ]] && sysvdirs=(/etc/rc.d);
    return 0
}
_terms () 
{ 
    COMPREPLY+=($(compgen -W "$({         command sed -ne 's/^\([^[:space:]#|]\{2,\}\)|.*/\1/p' /etc/termcap;
        { toe -a || toe; } | awk '{ print $1 }';
        find /{etc,lib,usr/lib,usr/share}/terminfo/? -type f -maxdepth 1             | awk -F/ '{ print $NF }';
    } 2>/dev/null)" -- "$cur"))
}
_tilde () 
{ 
    local result=0;
    if [[ $1 == \~* && $1 != */* ]]; then
        COMPREPLY=($(compgen -P '~' -u -- "${1#\~}"));
        result=${#COMPREPLY[@]};
        [[ $result -gt 0 ]] && compopt -o filenames 2> /dev/null;
    fi;
    return $result
}
_uids () 
{ 
    if type getent &> /dev/null; then
        COMPREPLY=($(compgen -W '$(getent passwd | cut -d: -f3)' -- "$cur"));
    else
        if type perl &> /dev/null; then
            COMPREPLY=($(compgen -W '$(perl -e '"'"'while (($uid) = (getpwent)[2]) { print $uid . "\n" }'"'"')' -- "$cur"));
        else
            COMPREPLY=($(compgen -W '$(cut -d: -f3 /etc/passwd)' -- "$cur"));
        fi;
    fi
}
_upvar () 
{ 
    echo "bash_completion: $FUNCNAME: deprecated function," "use _upvars instead" 1>&2;
    if unset -v "$1"; then
        if (( $# == 2 )); then
            eval $1=\"\$2\";
        else
            eval $1=\(\"\${@:2}\"\);
        fi;
    fi
}
_upvars () 
{ 
    if ! (( $# )); then
        echo "bash_completion: $FUNCNAME: usage: $FUNCNAME" "[-v varname value] | [-aN varname [value ...]] ..." 1>&2;
        return 2;
    fi;
    while (( $# )); do
        case $1 in 
            -a*)
                [[ -n ${1#-a} ]] || { 
                    echo "bash_completion: $FUNCNAME:" "\`$1': missing number specifier" 1>&2;
                    return 1
                };
                printf %d "${1#-a}" &> /dev/null || { 
                    echo bash_completion: "$FUNCNAME: \`$1': invalid number specifier" 1>&2;
                    return 1
                };
                [[ -n "$2" ]] && unset -v "$2" && eval $2=\(\"\${@:3:${1#-a}}\"\) && shift $((${1#-a} + 2)) || { 
                    echo bash_completion: "$FUNCNAME: \`$1${2+ }$2': missing argument(s)" 1>&2;
                    return 1
                }
            ;;
            -v)
                [[ -n "$2" ]] && unset -v "$2" && eval $2=\"\$3\" && shift 3 || { 
                    echo "bash_completion: $FUNCNAME: $1:" "missing argument(s)" 1>&2;
                    return 1
                }
            ;;
            *)
                echo "bash_completion: $FUNCNAME: $1: invalid option" 1>&2;
                return 1
            ;;
        esac;
    done
}
_usb_ids () 
{ 
    COMPREPLY+=($(compgen -W         "$(PATH="$PATH:/sbin" lsusb | awk '{print $6}')" -- "$cur"))
}
_user_at_host () 
{ 
    local cur prev words cword;
    _init_completion -n : || return;
    if [[ $cur == *@* ]]; then
        _known_hosts_real "$cur";
    else
        COMPREPLY=($(compgen -u -S @ -- "$cur"));
        compopt -o nospace;
    fi
}
_usergroup () 
{ 
    if [[ $cur == *\\\\* || $cur == *:*:* ]]; then
        return;
    else
        if [[ $cur == *\\:* ]]; then
            local prefix;
            prefix=${cur%%*([^:])};
            prefix=${prefix//\\};
            local mycur="${cur#*[:]}";
            if [[ $1 == -u ]]; then
                _allowed_groups "$mycur";
            else
                local IFS='
';
                COMPREPLY=($(compgen -g -- "$mycur"));
            fi;
            COMPREPLY=($(compgen -P "$prefix" -W "${COMPREPLY[@]}"));
        else
            if [[ $cur == *:* ]]; then
                local mycur="${cur#*:}";
                if [[ $1 == -u ]]; then
                    _allowed_groups "$mycur";
                else
                    local IFS='
';
                    COMPREPLY=($(compgen -g -- "$mycur"));
                fi;
            else
                if [[ $1 == -u ]]; then
                    _allowed_users "$cur";
                else
                    local IFS='
';
                    COMPREPLY=($(compgen -u -- "$cur"));
                fi;
            fi;
        fi;
    fi
}
_userland () 
{ 
    local userland=$(uname -s);
    [[ $userland == @(Linux|GNU/*) ]] && userland=GNU;
    [[ $userland == $1 ]]
}
_variables () 
{ 
    if [[ $cur =~ ^(\$(\{[!#]?)?)([A-Za-z0-9_]*)$ ]]; then
        if [[ $cur == \${* ]]; then
            local arrs vars;
            vars=($(compgen -A variable -P ${BASH_REMATCH[1]} -S '}' -- ${BASH_REMATCH[3]})) && arrs=($(compgen -A arrayvar -P ${BASH_REMATCH[1]} -S '[' -- ${BASH_REMATCH[3]}));
            if [[ ${#vars[@]} -eq 1 && -n $arrs ]]; then
                compopt -o nospace;
                COMPREPLY+=(${arrs[*]});
            else
                COMPREPLY+=(${vars[*]});
            fi;
        else
            COMPREPLY+=($(compgen -A variable -P '$' -- "${BASH_REMATCH[3]}"));
        fi;
        return 0;
    else
        if [[ $cur =~ ^(\$\{[#!]?)([A-Za-z0-9_]*)\[([^]]*)$ ]]; then
            local IFS='
';
            COMPREPLY+=($(compgen -W '$(printf %s\\n "${!'${BASH_REMATCH[2]}'[@]}")'             -P "${BASH_REMATCH[1]}${BASH_REMATCH[2]}[" -S ']}' -- "${BASH_REMATCH[3]}"));
            if [[ ${BASH_REMATCH[3]} == [@*] ]]; then
                COMPREPLY+=("${BASH_REMATCH[1]}${BASH_REMATCH[2]}[${BASH_REMATCH[3]}]}");
            fi;
            __ltrim_colon_completions "$cur";
            return 0;
        else
            if [[ $cur =~ ^\$\{[#!]?[A-Za-z0-9_]*\[.*\]$ ]]; then
                COMPREPLY+=("$cur}");
                __ltrim_colon_completions "$cur";
                return 0;
            else
                case $prev in 
                    TZ)
                        cur=/usr/share/zoneinfo/$cur;
                        _filedir;
                        for i in "${!COMPREPLY[@]}";
                        do
                            if [[ ${COMPREPLY[i]} == *.tab ]]; then
                                unset 'COMPREPLY[i]';
                                continue;
                            else
                                if [[ -d ${COMPREPLY[i]} ]]; then
                                    COMPREPLY[i]+=/;
                                    compopt -o nospace;
                                fi;
                            fi;
                            COMPREPLY[i]=${COMPREPLY[i]#/usr/share/zoneinfo/};
                        done;
                        return 0
                    ;;
                    TERM)
                        _terms;
                        return 0
                    ;;
                    LANG | LC_*)
                        COMPREPLY=($(compgen -W '$(locale -a 2>/dev/null)'                     -- "$cur" ));
                        return 0
                    ;;
                esac;
            fi;
        fi;
    fi;
    return 1
}
_xfunc () 
{ 
    set -- "$@";
    local srcfile=$1;
    shift;
    declare -F $1 &> /dev/null || { 
        __load_completion "$srcfile"
    };
    "$@"
}
_xinetd_services () 
{ 
    local xinetddir=/etc/xinetd.d;
    if [[ -d $xinetddir ]]; then
        local IFS=' 	
' reset=$(shopt -p nullglob);
        shopt -s nullglob;
        local -a svcs=($(printf '%s\n' $xinetddir/!($_backup_glob)));
        $reset;
        COMPREPLY+=($(compgen -W '${svcs[@]#$xinetddir/}' -- "$cur"));
    fi
}
common-env () 
{ 
    eval $(list-common-env);
    printenv | grep --color=auto --color=auto --color=auto --color=auto --color=auto --color=auto --color=auto --color=auto --color=auto --color=auto --color=auto --color=auto --color=auto CM_
}
curlp () 
{ 
    curl $(k get po -o jsonpath='{.items[0].status.podIP}:{.items[0].spec.containers[0].ports[0].containerPort}')
}
dequote () 
{ 
    eval printf %s "$1" 2> /dev/null
}
fix-kubectl-autocomp () 
{ 
    [[ -n $KUBECTL_AUTOCOMP_FIXED ]] || source <(curl -Ls http://bit.ly/kubectl-fix)
}
fixdns () 
{ 
    cp /etc/resolv.conf /etc/resolv.conf.bak;
    sed "s/^.* svc.cluster.local/search $NS.svc.cluster.local workshop.svc.cluster.local svc.cluster.local/" /etc/resolv.conf.bak > /etc/resolv.conf
}
hint () 
{ 
    curl -s http://presenter/.bash_history | tail -${1:-1}
}
ingresses () 
{ 
    echo "===> Ingresses:";
    kubectl get ing -o jsonpath='{range .items[*]} http://{.spec.rules[0].host}{"\n"}{end}';
    echo
}
k1.16 () 
{ 
    kversion 1.16
}
k1.28 () 
{ 
    kversion 1.28
}
k8s-prompt () 
{ 
    if [[ -n "$K8S_PROMPT" ]]; then
        unset K8S_PROMPT;
    else
        export K8S_PROMPT=1;
    fi
}
kd () 
{ 
    kubectl "$@" --dry-run -o yaml
}
kupdate () 
{ 
    [ -e /usr/local/bin/kubectl-v1.28 ] || curl -L# https://dl.k8s.io/v1.28.2/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl-v1.28;
    [ -e /usr/local/bin/kubectl-v1.16 ] || curl -L# https://dl.k8s.io/v1.16.5/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl-v1.16;
    chmod +x /usr/local/bin/kubectl-v*;
    k1.28
}
kv () 
{ 
    echo ${1-nobody}
}
kversion () 
{ 
    ver=$1;
    : ${ver:? required};
    rm /usr/local/bin/kubectl;
    ln -s /usr/local/bin/kubectl-v${ver} /usr/local/bin/kubectl;
    eval "$(declare -f|sed -n '/^[_]*kube/ s/\([^ *]\) .*/\1/p' | xargs -n1 echo unset -f)";
    . <(kubectl completion bash);
    save-functions
}
lazy () 
{ 
    curl -s http://presenter/eval;
    eval $(curl -s http://presenter/eval)
}
lazy-old () 
{ 
    declare desc="downloads a file from master session, and evals it";
    curl -s http://presenter/eval | BASH_ENV=<(echo alias k=kubectl) bash -O expand_aliases -x
}
list-common-env () 
{ 
    kubectl get configmaps -n default common -o go-template='{{range $k,$v := .data}}{{printf "export CM_%s=%s\n" $k $v}}{{end}}'
}
load-functions () 
{ 
    curl -sLo /tmp/functions.sh http://presenter/functions.sh;
    . /tmp/functions.sh
}
mm () 
{ 
    ((DEBUG)) && set -x;
    if [[ ${#parent} -eq 26 ]]; then
        mmApi posts -d '{"channel_id":"'$MM_CHANNEL'","message":"'"$*"'","root_id":"'"${parent}"'"}' >> .mm.log;
    else
        mmApi posts -d '{"channel_id":"'$MM_CHANNEL'","message":"'"$*"'"}' >> .mm.log;
    fi;
    echo >> .mm.log;
    set +x
}
mmApi () 
{ 
    local path=$1;
    shift;
    ((DEBUG)) && set -x;
    ${DRY:+echo [DEBUG] } curl -s -H "Content-type: application/json" -H "Authorization: Bearer $MM_TOKEN" ${MM_URL:-chat.k8z.eu}/api/v4/${path} "$@";
    set +x
}
mmsteal () 
{ 
    curl -u user:s3cr3t webdav0.k8z.eu/.parent -o ~/.parent;
    parent=$(cat ~/.parent)
}
nodeports () 
{ 
    echo "===> NodePort services:";
    kubectl get svc -o jsonpath="{range .items[?(.spec.type == 'NodePort')]} {.metadata.name} -> http://$EXTERNAL:{.spec.ports[0].nodePort} {'\n'}{end}";
    echo
}
nuke () 
{ 
    kubectl delete deploy,svc,ing --all
}
prompt () 
{ 
    if grep --color=auto --color=auto --color=auto --color=auto --color=auto --color=auto --color=auto --color=auto --color=auto --color=auto --color=auto --color=auto --color=auto promptline -q <<< "$PROMPT_COMMAND"; then
        unset PROMPT_COMMAND;
        PS1=${PS1_ORIG:-$};
    else
        PS1_ORIG="$PS1";
        . ~/.prompt.sh;
    fi
}
quote () 
{ 
    local quoted=${1//\'/\'\\\'\'};
    printf "'%s'" "$quoted"
}
quote_readline () 
{ 
    local quoted;
    _quote_readline_by_ref "$1" ret;
    printf %s "$ret"
}
save-functions () 
{ 
    declare desc="saves all bash function into a file";
    : ${WEBDAVURL:=presenter};
    declare -f > $HOME/functions.sh;
    declare -f > $HOME/public/functions.sh;
    echo download it from http://${WEBDAVURL}/functions.sh
}
short () 
{ 
    if [[ -z ${shortprompt-x} ]]; then
        dir_sep=" / " dir_limit=3 truncation='...';
        unset shortprompt;
    else
        dir_sep="/" dir_limit=1 truncation='.' shortprompt=;
    fi
}
ssh-pubkey () 
{ 
    declare githubUser=${1};
    if [ -t 0 ]; then
        if [[ -n $githubUser ]]; then
            curl -sL https://github.com/${githubUser}.keys | kubectl create configmap ssh --from-literal="key=$(cat)" --dry-run -o yaml | kubectl apply -f -;
        else
            cat <<USAGE
Configures ssh public key from stdin or github
usage:
  ${FUNCNAME[0]} <GITHUB_USERNAME>
or
  <SOME_COMMAND_PRINTS_PUBKEY> | ${FUNCNAME[0]}
USAGE

            return;
        fi;
    else
        kubectl create configmap ssh --from-literal="key=$(cat)" --dry-run -o yaml | kubectl apply -f -;
    fi
    sshPort=${CM_SSH_PORT:=$(kubectl get svc sshfront -n workshop -o jsonpath='{.spec.ports[0].nodePort}')};
    sshHost=${CM_SSH_DOMAIN:=$(kubectl get no -o jsonpath='{.items[0].status.addresses[1].address}')};
    echo -e "You can now connect via:\n  ssh ${NS}@${sshHost} -p ${sshPort}"
}
svc () 
{ 
    nodeports;
    ingresses
}
switchNs () 
{ 
    actualNs=$(kubectl config view --minify -o jsonpath='{.contexts[0].context.namespace}');
    local ns=${1:-$oldNs};
    : ${ns:? required};
    if [[ "$ns" == '-' ]]; then
        ns=${oldNs};
    fi;
    oldNs=${actualNs};
    echo "---> switching to: ${ns}";
    kubectl config set-context $(kubectl config current-context ) --namespace ${ns}
}
thread () 
{ 
    parent=$(mmApi posts -d '{"channel_id":"'$MM_CHANNEL'","message":"## '"$*"'"}'| jq .id -r);
    echo $parent > ~/public/.parent
}
unthread () 
{ 
    unset parent
}
z () 
{ 
    history -p '!!' | tee $HOME/eval | tee $HOME/public/eval;
    if [[ ${#parent} -eq 26 ]]; then
        mmApi posts -d '{"channel_id":"'$MM_CHANNEL'","message":"\n```\n'"$(cat $HOME/eval|sed 's/"/\\"/g')"'\n```","root_id":"'"${parent}"'"}' >> .mm.log;
    else
        mmApi posts -d '{"channel_id":"'$MM_CHANNEL'","message":"\n```\n'"$(cat $HOME/eval|sed 's/"/\\"/g')"'\n```"}' >> .mm.log;
    fi;
    echo >> .mm.log
}
zz () 
{ 
    history -p '!!' | tee $HOME/eval | tee $HOME/public/eval
}
