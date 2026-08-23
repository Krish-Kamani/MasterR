# Add ~/.local/bin to PATH
fish_add_path ~/.local/bin

# Default text editor and Qt platform theme
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx QT_QPA_PLATFORMTHEME gtk3


zoxide init fish | source

abbr -a ff fastfetch
abbr -a v nvim
abbr -a vim nvim

function fish_greeting
    ~/.config/fish/torii-greeting.sh
end


