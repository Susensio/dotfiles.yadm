# Completions for cidm v2

# Print an optspec for argparse to handle cidm's options
# that are independent of any subcommand. Borrowed from git completion file.
function __fish_cidm_global_optspecs
    string join \n v-version h/help C= c=+ 'e-exec-path=?' H-html-path M-man-path I-info-path p/paginate \
        P/no-pager o-no-replace-objects b-bare G-git-dir= W-work-tree= N-namespace= S-super-prefix= \
        l-literal-pathspecs g-glob-pathspecs O-noglob-pathspecs i-icase-pathspecs \
        Y/cidm-dir= R-cidm-repo= n-cidm-config= E-cidm-encrypt= a-cidm-archive= B-cidm-bootstrap=
end

# Config values accepted by `cidm config`
# See `cidm gitconfig` for setting git config values
function __fish_cidm_config_keys
    cidm introspect configs
end

set -l __fish_cidm_subcommands (cidm introspect commands)

# Borrowed from git completion file
function __fish_cidm_needs_command
    # Figure out if the current invocation already has a command.
    set -l cmd (commandline -opc)
    set -e cmd[1]
    argparse -s (__fish_cidm_global_optspecs) -- $cmd 2>/dev/null
    or return 0
    # These flags function as commands, effectively.
    set -q _flag_version; and return 1
    set -q _flag_html_path; and return 1
    set -q _flag_man_path; and return 1
    set -q _flag_info_path; and return 1
    if set -q argv[1]
        # Also print the command, so this can be used to figure out what it is.
        echo $argv[1]
        return 1
    end
    return 0
end

# Borrowed from git completion file
function __fish_cidm_using_command
    set -l cmd (__fish_cidm_needs_command)
    test -z "$cmd"
    and return 1
    contains -- $cmd $argv
    and return 0
    return 1
end

# Manual wrapping (instead of `complete -w`) is necessary here because we
# don't want to inherit all completions from git
function __fish_complete_cidm_like_git
    # Remove the first word from the commandline because that is "cidm"
    set -l cmdline (commandline -opc; commandline -ct)[2..-1]

    # `cidm gitconfig` is same as `git config`
    if __fish_seen_subcommand_from gitconfig
        set cmdline (string replace 'gitconfig' 'config' "$cmdline")
    end

    set -l cidm_work_tree (cidm gitconfig --get core.worktree)
    set -l cidm_repo (cidm introspect repo)

    argparse -i 'R-cidm-repo=' -- $cmdline 2>/dev/null
    if set -q _flag_cidm_repo
        set cidm_repo $_flag_cidm_repo
        # argparse *always* sets $argv to remaining arguments after consuming specified options
        set cmdline $argv
    end

    set -l git_wrapper_cmd "git --work-tree $cidm_work_tree --git-dir $cidm_repo $cmdline"

    # `complete -a` expects each completion to be separated by space, not newline
    complete -C "$git_wrapper_cmd"
end

# General git wrapping
complete -f -c cidm -n "not __fish_seen_subcommand_from $__fish_cidm_subcommands" -a '(__fish_complete_cidm_like_git)'

# Global options
complete -F -r -c cidm -l cidm-dir -s Y -a '(__fish_complete_directories)' -d 'Override the cidm directory'
complete -F -r -c cidm -l cidm-repo -d 'Override location of cidm repository'
complete -F -r -c cidm -l cidm-config -d 'Override location of cidm configuration file'
complete -F -r -c cidm -l cidm-encrypt -d 'Override location of cidm encryption configuration'
complete -F -r -c cidm -l cidm-archive -d 'Override location of cidm encrypted files archive'
complete -F -r -c cidm -l cidm-bootstrap -d 'Override location of cidm bootstrap program'

# Subcommands
complete -f -c cidm -n __fish_cidm_needs_command -a version -d 'Print cidm version'
complete -f -c cidm -n __fish_cidm_needs_command -a init -d 'Initialize new repository for tracking dotfiles'
complete -f -c cidm -n __fish_cidm_needs_command -a config -d 'Manage configuration for cidm'
complete -f -c cidm -n __fish_cidm_needs_command -a list -d 'Print list of files managed by cidm'
complete -f -c cidm -n __fish_cidm_needs_command -a bootstrap -d 'Execute bootstrap script'
complete -f -c cidm -n __fish_cidm_needs_command -a encrypt -d 'Encrypt files matched by encrypt spec file'
complete -f -c cidm -n __fish_cidm_needs_command -a decrypt -d 'Decrypt files matched by encrypt spec file'
complete -f -c cidm -n __fish_cidm_needs_command -a alt -d 'Setup and process alternate files'
complete -f -c cidm -n __fish_cidm_needs_command -a perms -d 'Update permissions'
complete -f -c cidm -n __fish_cidm_needs_command -a enter -d 'Run sub-shell with all git variables set'
complete -f -c cidm -n __fish_cidm_needs_command -a git-crypt -d 'Pass options to git-crypt if installed'
complete -f -c cidm -n __fish_cidm_needs_command -a gitconfig -d 'Pass options to the git config command'
complete -f -c cidm -n __fish_cidm_needs_command -a upgrade -d 'Migrate from v1 to v2'
complete -f -c cidm -n __fish_cidm_needs_command -a introspect -d 'Report internal cidm data'
complete -f -c cidm -n __fish_cidm_needs_command -a clone -d 'Clone remote repository for tracking dotfiles'

# Options for subcommands
complete -f -c cidm -n "__fish_cidm_using_command init" -s f -d 'Overwrite existing repository'
complete -f -c cidm -n "__fish_cidm_using_command init" -s w -r -a '(__fish_complete_directories)' -d 'Override work-tree'
complete -f -c cidm -n "__fish_cidm_using_command clone" -s f -d 'Overwrite existing repository'
complete -f -c cidm -n "__fish_cidm_using_command clone" -s w -r -a '(__fish_complete_directories)' -d 'Override work-tree'
complete -f -c cidm -n "__fish_cidm_using_command clone" -s b -d 'Use another branch'
complete -f -c cidm -n "__fish_cidm_using_command clone" -l bootstrap -d 'Force run the bootstrap script'
complete -f -c cidm -n "__fish_cidm_using_command clone" -l no-bootstrap -d 'Do not execute bootstrap script'
complete -f -c cidm -n "__fish_cidm_using_command list" -s a -d 'List all files'
complete -f -c cidm -n "__fish_cidm_using_command decrypt" -s l -d 'List files without extracting'
complete -f -c cidm -n "__fish_cidm_using_command introspect" -x -a 'commands configs repo switches'

# These inherit some options from git
complete -f -c cidm -n "__fish_cidm_using_command gitconfig" -a '(__fish_complete_cidm_like_git)'

# Some options for `cidm config` takes configuration keys as arguments, and these should have
# cidm's config keys instead of git's. Inherit all other options.
complete -f -c cidm -n "__fish_cidm_using_command config; and not __fish_seen_argument -l get -l get-all -l replace-all -l unset -l unset-all" -a '(__fish_complete_cidm_like_git)'

complete -f -c cidm -n "__fish_cidm_using_command config" -l get -r -a '(__fish_cidm_config_keys)' -d 'Get config with name'
complete -f -c cidm -n "__fish_cidm_using_command config" -l get-all -a '(__fish_cidm_config_keys)' -d 'Get all values matching key'
complete -f -c cidm -n "__fish_cidm_using_command config" -l replace-all -r -a '(__fish_cidm_config_keys)' -d 'Replace all matching variables'
complete -f -c cidm -n "__fish_cidm_using_command config" -l unset -a '(__fish_cidm_config_keys)' -d 'Remove a variable'
complete -f -c cidm -n "__fish_cidm_using_command config" -l unset-all -a '(__fish_cidm_config_keys)' -d 'Remove matching variables'

# If no argument is specified for `config`, it's as if --get was used
complete -f -c cidm -n "__fish_cidm_using_command config; and __fish_is_nth_token 3" -a '(__fish_cidm_config_keys)'
