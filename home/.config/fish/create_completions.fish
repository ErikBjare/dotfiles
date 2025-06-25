#!/bin/env fish

# Check if completions file is available, else symlink it or generate it
set completions_file ~/.config/fish/completions/gptme.fish
set source_completions ~/Programming/gptme/scripts/completions/gptme.fish

if test -f $source_completions
    # Symlink if source completions exist
    mkdir -p (dirname $completions_file)
    ln -sf $source_completions $completions_file
    echo "Symlinked gptme completions from $source_completions"
end
