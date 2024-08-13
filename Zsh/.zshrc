# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-autosuggestions zsh-syntax-highlighting fzf)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Default
export EDITOR=micro

# $PATH
export PATH=$PATH:/snap/bin
export PATH="$HOME/.cargo/bin:$PATH"

# Imports
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
source ~/fzf-git.sh/fzf-git.sh
eval "$(starship init zsh)"
source <(fzf --zsh)
eval "$(zoxide init zsh)"
eval $(thefuck --alias)
eval $(thefuck --alias fk)

# Aliases
alias d="cd /mnt/d"
alias c="cd /mnt/c"
alias dot="cd /mnt/d/Dotfiles"
alias conf="cd /home/whosowsee/.config"
alias bin="cd /bin"

alias cc="cd .."
alias cls="clear"
alias sau="sudo apt update"
alias sai="sudo apt install"
alias sagi="sudo apt-get install"

alias la='ls -alF'
alias ll='ls -A'
alias l='ls -CF'

alias g="git"
alias y="yazi"
alias m="micro"
alias bat="batcat"
alias fd="fdfind"
alias trl="trash-list"
alias trp="trash-put"
alias tre="trash-empty"
alias trr="trash-restore"

bindkey '^[' kill-whole-line

if [ -x "$(command -v exa)" ]; then
	alias ls="exa"
	alias ll="exa -a"
	alias la="exa --long --all --group"
fi

alias close='wsl.exe --terminate Ubuntu'

# Powershell

function New-DirectoryAndEnter() {
    if [ -z "$1" ]; then
        echo "Usage: mc <directory_name>"
        return 1
    fi
    if [ -d "$1" ]; then
        echo "Directory '$1' already exists"
    else
        mkdir -p "$1"
    fi
    cd "$1"
}
alias mc="New-DirectoryAndEnter"

function Remove-CurrentDirectoryToRecycleBin() {
    currentPath=$(pwd)
    parentPath=$(dirname "$currentPath")
    if [ "$parentPath" = "/" ]; then
        echo "Невозможно удалить корневую директорию"
        return 1
    fi
    cd "$parentPath"
    if [ -d "$currentPath" ]; then
        trash-put "$currentPath"
        if [ $? -eq 0 ]; then
        else
            echo "Ошибка при перемещении директории в корзину"
            cd "$currentPath"
            return 1
        fi
    else
        echo "Директория не найдена"
        cd "$currentPath"
    fi
}
alias rw="Remove-CurrentDirectoryToRecycleBin"

copy_recursively() {
    local source="$1"
    local destination_or_new_name="$2"
    local new_name="$3"
    if [[ ! -e "$source" ]]; then
        echo "Исходный путь '$source' не существует" >&2
        return 1
    fi
    local source_name=$(basename "$source")
    local is_directory=false
    [[ -d "$source" ]] && is_directory=true
    local current_location="$PWD"
    if [[ -n "$destination_or_new_name" && -z "$new_name" ]]; then
        if [[ "$destination_or_new_name" == */* ]]; then
            local destination="$destination_or_new_name"
            new_name=""
        else
            local destination="$current_location"
            new_name="$destination_or_new_name"
        fi
    elif [[ -n "$destination_or_new_name" && -n "$new_name" ]]; then
        local destination="$destination_or_new_name"
    else
        local destination="$current_location"
    fi
    if $is_directory && [[ -n "$new_name" && "$new_name" == *.* ]]; then
        echo "Ошибка: Нельзя скопировать директорию '$source' и назвать её как файл '$new_name'" >&2
        return 1
    fi
    if [[ -f "$destination" ]]; then
        echo "Ошибка: Указанный путь назначения '$destination' является файлом, а не директорией" >&2
        return 1
    fi
    if [[ -n "$new_name" ]]; then
        local final_destination="$destination/$new_name"
    else
        local final_destination="$destination/$source_name"
    fi
    if ! $is_directory && [[ -d "$destination" && -z "$new_name" ]]; then
        final_destination="$destination/$source_name"
    fi
    if $is_directory; then
        mkdir -p "$final_destination"
        cp -R "$source/." "$final_destination"
    else
        mkdir -p "$(dirname "$final_destination")"
        cp "$source" "$final_destination"
    fi
    if [[ $? -ne 0 ]]; then
        echo "Ошибка при копировании" >&2
        return 1
    fi
}
alias cpc='copy_recursively'

function move_items_to_parent {
    local f=0 d=0 h=0
    while getopts "fdh" opt; do
        case $opt in
            f) f=1 ;;
            d) d=1 ;;
            h) h=1 ;;
            *) return 1 ;;
        esac
    done
    shift $((OPTIND - 1))
    local destination=$(realpath ..)
    local items=()
    local find_command="find . -maxdepth 1"
    if [[ $h -eq 1 ]]; then
        find_command+=" -not -path '*/\.*'"
    fi
    if [[ $f -eq 1 ]]; then
        find_command+=" -type f"
    elif [[ $d -eq 1 ]]; then
        find_command+=" -type d"
    fi
    items=($(eval "$find_command -printf '%P\n'"))
    local item_count=0
    local moved_count=0
    for item in "${items[@]}"; do
        local source_path="$PWD/$item"
        local dest_path="$destination/$item"
        if [[ "$source_path" != "$PWD" && "$source_path" != "$destination" ]]; then
            mv -f "$source_path" "$destination" && ((moved_count++)) && ((item_count++))
        fi
    done
    if [[ $moved_count -lt $item_count ]]; then
        echo "Перемещено элементов: $moved_count из $item_count"
    fi
}
alias mvp='move_items_to_parent'

function yy() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}


# One-liners
alias uzsh="source /home/whosowsee/.zshrc"
alias czsh="code /home/whosowsee/.zshrc"

alias mf="touch"

alias tt="eza --tree --level=3 --icons=always --no-time --no-user --no-permissions -s type"
alias ls="eza -a --icons=always --no-time --no-user --no-permissions -s type"
alias lls="eza --icons=always --no-time --no-user --no-permissions -s type"
alias ld="eza -a --icons=always --no-time --no-user --no-permissions -D"
alias lld="eza --icons=always --no-time --no-user --no-permissions -D"
alias lf="eza -a --icons=always --no-time --no-user --no-permissions -f"
alias llf="eza --icons=always --no-time --no-user --no-permissions -f"
alias ll="eza -a --tree --level=1 --icons=always --no-time --no-user --no-permissions -s type"
alias lq="eza --tree --level=1 --icons=always --no-time --no-user --no-permissions -s type"
alias lv="eza -a --long --icons=always --no-time --no-user --no-permissions --no-filesize -s type"
alias llv="eza --long --icons=always --no-time --no-user --no-permissions --no-filesize -s type"
alias lg="eza -a --long --icons=always --no-time --no-user --no-permissions --no-filesize -s type --git"
alias la="eza -a --long --icons=always -s type"
alias lla="eza --long --icons=always -s type"


function htt() {
    httpyac $1 --json -а | jq -г ".requests[0].response.body" | jq | bat --language=json
}

export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
  --color=fg:#8f93a2,fg+:#d9d9d9,bg:-1,bg+:-1
  --color=hl:#9db5cc,hl+:#c5e1eb,info:#a3be8c,marker:#a3be8c
  --color=prompt:#81A1C1,spinner:#bb9af7,pointer:#e0af68,header:#87afaf
  --color=gutter:-1,border:#262626,label:#aeaeae,query:#d9d9d9
  --border="rounded" --border-label="" --preview-window="border-rounded" --prompt="> "
  --marker=">" --pointer="◆" --separator="─" --scrollbar="│" --info="right"'

export FZF_DEFAULT_COMMAND="fdfind --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fdfind --type=d --hidden --strip-cwd-prefix --exclude .git"

_fzf_compgen_path() {
    fdfind --hidden --exclude .git . "$1"
}

_fzf_compgen_dir() {
    fdfind --type=d --hidden --exclude .git . "$1"
}

show_file_or_dir_preview="if [ -d {} ]; then eza --tree --color=always --icons=always {} | head -200; else batcat -n --color=always --line-range :500 {}; fi"
export FZF_CTRL_T_OPTS="--preview '$show_file_or_dir_preview'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always --icons=always {} | head -200'"

# Advanced customization of fzf options via _fzf_comprun function
# - The first argument to the function is the name of the command.
# - You should make sure to pass the rest of the arguments to fzf.
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview 'eza --tree --color=always --icons=always {} | head -200' "$@" ;;
    export|unset) fzf --preview "eval 'echo \${}'"         "$@" ;;
    ssh)          fzf --preview 'dig {}'                   "$@" ;;
    *)            fzf --preview "$show_file_or_dir_preview" "$@" ;;
  esac
}
