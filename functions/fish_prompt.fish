# Default appearance options. Override in config.fish if you want.
if ! set -q dirty_indicator
    set -g dirty_indicator "*"
end

if ! set -q prompt_symbol
    set -g prompt_symbol ">"
end

if ! set -q prompt_symbol_color
    set -g prompt_symbol_color magenta
end

if ! set -q prompt_symbol_error_color
    set -g prompt_symbol_error_color grey
end

if ! set -q cwd_color
    set -g cwd_color brcyan
end

if ! set -q git_color
    set -g git_color green
end

# State used for memoization and async calls.
set -g __cmd_id 0
set -g __git_state_cmd_id -1
set -g __git_static ""
set -g __dirty ""

# Increment a counter each time a prompt is about to be displayed.
# Enables us to distingish between redraw requests and new prompts.
function __increment_cmd_id --on-event fish_prompt
    set __cmd_id (math $__cmd_id + 1)
end

# Abort an in-flight dirty check, if any.
function __abort_check
    if set -q __check_pid
        set -l pid $__check_pid
        functions -e __on_finish_$pid
        command kill $pid >/dev/null 2>&1
        set -e __check_pid
    end
end

function __git_status
    # Reset state if this call is *not* due to a redraw request
    set -l prev_dirty $__dirty
    if test $__cmd_id -ne $__git_state_cmd_id
        __abort_check

        set __git_state_cmd_id $__cmd_id
        set __git_static ""
        set __dirty ""
    end

    # Fetch git position & action synchronously.
    # Memoize results to avoid recomputation on subsequent redraws.
    if test -z $__git_static
        # Determine git working directory
        set -l git_dir (command git --no-optional-locks rev-parse --absolute-git-dir 2>/dev/null)
        if test $status -ne 0
            return 1
        end

        set -l position (command git --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
        if test $status -ne 0
            # Denote detached HEAD state with short commit hash
            set position (command git --no-optional-locks rev-parse --short HEAD 2>/dev/null)
            if test $status -eq 0
                set position "@$position"
            end
        end

        # TODO: add bisect
        set -l action ""
        if test -f "$git_dir/MERGE_HEAD"
            set action "merge"
        else if test -d "$git_dir/rebase-merge"
            set branch "rebase"
        else if test -d "$git_dir/rebase-apply"
            set branch "rebase"
        end

        set -l state $position
        if test -n $action
            set state "$state <$action>"
        end

        set -g __git_static $state
    end

    # Fetch dirty status asynchronously.
    if test -z $__dirty
        if ! set -q __check_pid
            # Compose shell command to run in background
            set -l check_cmd "git --no-optional-locks status -unormal --porcelain --ignore-submodules 2>/dev/null | head -n1 | count"
            set -l cmd "if test ($check_cmd) != "0"; exit 1; else; exit 0; end"

            begin
                # Defer execution of event handlers by fish for the remainder of lexical scope.
                # This is to prevent a race between the child process exiting before we can get set up.
                block -l

                set -g __check_pid 0
                command fish --private --command "$cmd" >/dev/null 2>&1 &
                set -l pid (jobs --last --pid)

                set -g __check_pid $pid

                # Use exit code to convey dirty status to parent process.
                function __on_finish_$pid --inherit-variable pid --on-process-exit $pid
                    functions -e __on_finish_$pid

                    if set -q __check_pid
                        if test $pid -eq $__check_pid
                            switch $argv[3]
                                case 0
                                    set -g __dirty_state 0
                                    if status is-interactive
                                        commandline -f repaint
                                    end
                                case 1
                                    set -g __dirty_state 1
                                    if status is-interactive
                                        commandline -f repaint
                                    end
                                case '*'
                                    set -g __dirty_state 2
                                    if status is-interactive
                                        commandline -f repaint
                                    end
                            end
                        end
                    end
                end
            end
        end

        if set -q __dirty_state
            switch $__dirty_state
                case 1
                    set -g __dirty $dirty_indicator
                case 2
                    set -g __dirty "<err>"
            end

            set -e __check_pid
            set -e __dirty_state
        end
    end

    # Render git status. When in-progress, use previous state to reduce flicker.
    set_color $git_color
    echo -n $__git_static ''

    if ! test -z $__dirty
        echo -n $__dirty
    else if ! test -z $prev_dirty
        set_color --dim $git_color
        echo -n $prev_dirty
        set_color normal
    end

    set_color normal
end

function fish_prompt
    set -l last_pipestatus $pipestatus
    set -l cwd (pwd | string replace "$HOME" '~')
    set -l prompt_symbol_color "$prompt_symbol_color"
    printf \e\[0J

    if not set -e transient_prompt
        echo ''
        set_color $cwd_color
        if test $cwd != '~' -a $cwd != '/'
            set -l udir (dirname (pwd) | string replace "$HOME" '~')
            test $udir != '/'; and set udir $udir'/'
            echo -sn $udir
        end
        set_color -o $cwd_color
        echo -n (basename (prompt_pwd))
        set_color normal

        if test $cwd != '~'; or test -n "$git_status_in_home_directory"
            set -l git_state (__git_status)
            if test $status -eq 0
                echo -sn " on $git_state"
            end
        end

        echo ''

        for status_code in $last_pipestatus
            if test "$status_code" -ne 0
                set prompt_symbol_color "$prompt_symbol_error_color"
                break
            end
        end
    end

    set_color -o "$prompt_symbol_color"
    echo -n "$prompt_symbol "
    set_color normal
end

# Implementation of transient prompt.
function transient
    set -g transient_prompt
    commandline -f repaint
    commandline -f execute
end

bind \r transient
