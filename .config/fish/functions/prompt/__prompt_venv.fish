function __prompt_venv
    if test -n "$VIRTUAL_ENV"
        set -l venv_name
        set -l venv_folder (basename "$VIRTUAL_ENV")
        set -l VENV_DIR_NAMES env .env venv .venv
        set -l ROOT_VENV "$XDG_DATA_HOME/venv"

        if test "$VIRTUAL_ENV" = "$ROOT_VENV"
            set venv_name /venv
        else if contains $venv_folder $VENV_DIR_NAMES
            set -l parent (dirname "$VIRTUAL_ENV")
            if test $parent = (pwd) || string match -q "$parent/*" (pwd)
                set venv_name "$venv_folder"
            else
                set venv_name (basename "$parent")/"$venv_folder"
            end
        else
            set venv_name "venv:"(basename "$VIRTUAL_ENV")
        end
        echo -n "("(set_color blue)$venv_name(set_color normal)")"
    end
end
