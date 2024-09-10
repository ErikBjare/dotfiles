function cd
    # Call the builtin cd function
    builtin cd $argv

    # After changing directory, check and activate venv if necessary
    check_and_activate_venv
end
