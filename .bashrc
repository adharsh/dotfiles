# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything

case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# >>> mamba initialize >>>
# !! Contents within this block are managed by 'mamba shell init' !!
export MAMBA_EXE='/home/adharsh/miniforge3/bin/mamba';
export MAMBA_ROOT_PREFIX='/home/adharsh/miniforge3';
__mamba_setup="$("$MAMBA_EXE" shell hook --shell bash --root-prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__mamba_setup"
else
    alias mamba="$MAMBA_EXE"  # Fallback on help from mamba activate
fi
unset __mamba_setup
# <<< mamba initialize <<<

# fzf
[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# fnm
FNM_PATH="/home/adharsh/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "$(fnm env --use-on-cd)"
fi

# pnpm
export PNPM_HOME="/home/adharsh/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# NODE_PATH
export NODE_PATH=$(pnpm root -g)

# uv
export PATH="/home/adharsh/.local/bin:$PATH"

# CUDA
export PATH=/usr/local/cuda/bin${PATH:+:${PATH}}
export LD_LIBRARY_PATH=/usr/local/cuda/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
# export CUDADIR=/usr/local/cuda
# export CUDA_HOME=/usr/local/cuda

# Others
alias md="m deactivate"
alias ma="md && m activate"
alias m=mamba
alias t=tree
export PATH="$HOME/bin:$PATH" # Check local binaries first

# Restart copyq
rcopyq() {
    pkill copyq
    nohup copyq >/dev/null 2>&1 &
}

# Git exclude without tracking
gex() {
    if [[ ! -f .git/info/exclude ]]; then
        echo "Not a Git repository, missing .git/info/exclude file" >&2
        return 1
    fi

    for f in "$@"; do
        # Trim trailing slashes and whitespace
        f_clean=$(echo "$f" | sed 's:/*$::' | xargs)
        
        # Re-add trailing slash if it's a directory
        if [[ -d "$f_clean" ]]; then
            f_clean="$f_clean/"
        fi
        
        # Escape special characters for Git pattern matching
        # Escape: [ ] * ? \
        f_git_escaped=$(printf '%s\n' "$f_clean" | sed -e 's/[][*?\\]/\\&/g')
        
        # Only add if not already present (exact match)
        if ! grep -Fxq -- "$f_git_escaped" .git/info/exclude; then
            echo "$f_git_escaped" >> .git/info/exclude
            echo "Excluded (without tracking): $f_clean"
        else
            echo "Already excluded: $f_clean"
        fi
    done
}


# Load api keys
[ -f "$HOME/.api_keys" ] && source "$HOME/.api_keys"

# Disable ctrl+s (which freezes output) to allow Shell-GPT integration
stty -ixon
# To revert: stty ixon

# Shell-GPT integration BASH v0.2
_sgpt_bash() {
if [[ -n "$READLINE_LINE" ]]; then
    history -s "$READLINE_LINE" # Custom: Add prompt to shell history
    READLINE_LINE=$(sgpt --shell <<< "$READLINE_LINE" --no-interaction)
    history -s "$READLINE_LINE" # Custom: Add generated command to shell history
    READLINE_POINT=${#READLINE_LINE}
fi
}
bind -x '"\C-s": _sgpt_bash'
# Shell-GPT integration BASH v0.2

# Clipboard
## Usage: c                 - Copies the last run command to clipboard
## Usage: echo "text" | c   - Copies piped input to clipboard
c() {
    if [ -t 0 ] && [ $# -eq 0 ]; then
        # If nothing is piped in and no arguments are provided
        fc -ln -1 | sed 's/^\s*//' | tee >(xclip -selection clipboard)
    else
        # Copy piped input to clipboard
        tee >(xclip -selection clipboard)
    fi
}

# Shell-GPT quick chat
## Usage: s your prompt here
## Usage: <command> | s
## Usage: <command> | s your prompt here
s() {
  sgpt "$*"
}

# Shell-GPT chat
## Usage: srt
## Usage: srt < my_file.txt
## Usage: <command> | srt
srt() {
  sgpt --repl temp "$@"
}
# srt() {
# #   # Read piped input or stdin (if any)
# #   if [ ! -t 0 ]; then
# #     input="$(cat -)"
# #     echo $input
# #   fi

#   # Append function arguments on a new line, if any
#   if [ $# -ne 0 ]; then
#     # input="${input}"$'\n'"$*"
#     input="$*"
#   fi

#   # Escape backslashes and double quotes for Expect
#   input_escaped=$(printf '%s' "$input" | sed 's/\\/\\\\/g; s/"/\\"/g')

#   expect -c "
#     spawn -noecho sgpt --repl temp
#     expect \"> \"
#     send \"${input_escaped}\r\"
#     interact
#   "
# }
