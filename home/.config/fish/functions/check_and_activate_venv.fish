function check_and_activate_venv --description 'Check for venv or Poetry env and activate if found' --on-variable PWD
    # Guard against multiple executions
    if set -q __VENV_ACTIVATION_IN_PROGRESS
        return
    end
    set -g __VENV_ACTIVATION_IN_PROGRESS 1

    set -l venv_dir
    set -l poetry_env
    set -l current_venv $VIRTUAL_ENV
    set -l current_dir $PWD

    # Check current directory and its parents for venv or pyproject.toml
    set -l check_dir $current_dir
    while test "$check_dir" != "/"
        if test -d "$check_dir/venv"
            set venv_dir "$check_dir/venv"
            break
        else if test -f "$check_dir/pyproject.toml"
            set poetry_env (cd "$check_dir" && poetry env info --path 2>/dev/null)
            break
        end
        set check_dir (dirname "$check_dir")
    end
    cd $current_dir

    # Determine the new environment
    set -l new_env
    if test -n "$venv_dir"
        set new_env "$venv_dir"
    else if test -n "$poetry_env"
        set new_env "$poetry_env"
    end

    # Check if we need to change the environment
    if test -n "$new_env" -a "$new_env" != "$current_venv"
        if test -n "$current_venv"
            echo "Deactivating current environment: $current_venv"
            deactivate
        end
        echo "Activating environment: $new_env"
        source "$new_env/bin/activate.fish"
    else if test -z "$new_env" -a -n "$current_venv"
        echo "Deactivating environment: $current_venv"
        deactivate
    end

    # Clean up
    set -e __VENV_ACTIVATION_IN_PROGRESS
end
