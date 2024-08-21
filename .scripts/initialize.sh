#!/bin/bash

sudo apt update

# Stop script if any command fails
set -e

# Add $USER to video group so you don't need sudo to run brightnessctl
sudo apt install -y brightnessctl
sudo usermod -aG video $USER

# Linux: https://github.com/alols/xcape
# Windows: https://gist.github.com/tanyuan/55bca522bf50363ae4573d4bdcf06e2e
sudo apt install -y git gcc make pkg-config libx11-dev libxtst-dev libxi-dev
git clone https://github.com/alols/xcape.git ~/.xcape
(cd ~/.xcape && make && sudo make install)

# https://github.com/junegunn/fzf#using-git
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf 
~/.fzf/install

# caffeine, activate on start
sudo apt install -y caffeine
~/dotfiles/.scripts/caffeine-indicator-fix.sh

# Install nvm: package manager for node.js
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
# nvm install 19
# nvm use 19
# npm install --global yarn

# Other installs  
# Installing vim-gtk3 so yanks go into clipboard
sudo apt install -y vim vim-gtk3 i3 xdotool xautomation silversearcher-ag maim xclip stow udiskie blueman ripgrep curl arandr tree jq gpick git xpad

# Git config
git config --global user.email "adharsh.babu@gmail.com"
git config --global user.name "Adharsh Babu"

# Install configurations
cd ~/dotfiles
stow .

echo "Reboot to see changes."


# Install timer
sudo add-apt-repository -y ppa:tatokis/alarm-clock-applet
sudo apt update
sudo apt install alarm-clock-applet

# Install copyq clipboard manager
sudo add-apt-repository ppa:hluk/copyq
sudo apt update
sudo apt install -y copyq
# Set show preview

# Post installation steps:
read -p "Make sure to step through install steps correctly. Preferred to Ctrl+C now and run commands one at a time."

## Installing mamba from miniforge
wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
./Miniforge3-Linux-x86_64.sh

# Install VSCode
wget -O vscode.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
sudo apt install ./vscode.deb
rm vscode.deb
# Custom CSS and JS Loader for pretty-ts-errors-hack.css
# Follow more details here: 
# - https://github.com/yoavbls/pretty-ts-errors/blob/HEAD/docs/hide-original-errors.md
# - https://marketplace.visualstudio.com/items?itemName=yoavbls.pretty-ts-errors
# - https://marketplace.visualstudio.com/items?itemName=be5invis.vscode-custom-css
# Custom CSS and JS
# SPECIAL NOTE: If Visual Studio Code complains about that it is corrupted, simply click “Don't show again”.
# NOTE: Every time after Visual Studio Code is updated, please re-enable Custom CSS.
# NOTE: Every time you change the configuration, please re-enable Custom CSS.
sudo chown -R $(whoami) "$(which code)"
sudo chown -R $(whoami) /usr/share/code
# Activate command in VSCode: Reload Custom CSS and JS

## Basic
mamba create -n basic python -y
mamba activate basic
mamba install -y pip
yes | pip install jupyterlab matplotlib pandas mypy
mambda deactivate

## Installing cling: C++ jupyter kernel
mamba create -n cling -y
mamba activate cling
mamba install -y xeus-cling -c conda-forge
mamba install -y jupyterlab
mambda deactivate

## Installing sgpt
## https://www.youtube.com/watch?v=Vxsx7Il-KMA&ab_channel=AICodeKing
mamba create -n sgpt python -y
mamba activate sgpt
mamba install -y pip
yes | pip install shell-gpt litellm matplotlib pandas
mambda deactivate

## Installing aider
mamba create -n aider python -y
mamba activate aider
yes | pip install aider-chat
mambda deactivate
