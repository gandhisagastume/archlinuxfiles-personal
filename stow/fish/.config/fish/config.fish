set -g fish_greeting

if status is-interactive
    starship init fish | source
end

# List Directory
alias l='eza -lh  --icons=auto' # long list
alias ls='eza -1   --icons=auto' # short list
alias ll='eza -lha --icons=auto --sort=name --group-directories-first' # long list all
alias ld='eza -lhD --icons=auto' # long list dirs
alias lt='eza --icons=auto --tree' # list folder as tree

# Handy change dir shortcuts
abbr .. 'cd ..'
abbr ... 'cd ../..'
abbr .3 'cd ../../..'
abbr .4 'cd ../../../..'
abbr .5 'cd ../../../../..'

# Always mkdir a path (this doesn't inhibit functionality to make a single dir)
abbr mkdir 'mkdir -p'

# ---- Claude Code ----
fish_add_path /home/sagas/.local/bin

# Secrets locales (NO versionados). Copia secrets.fish.example -> secrets.fish
# y pon ahí tus claves. Ver secrets.fish.example
test -f ~/.config/fish/secrets.fish && source ~/.config/fish/secrets.fish

# ---- Node.js ----
fish_add_path /home/sagas/.local/nodejs/bin
