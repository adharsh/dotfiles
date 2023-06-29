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
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
# nvm install 19
# nvm use 19
# npm install --global yarn

# Installing mamba
wget https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-Linux-x86_64.sh
bash Mambaforge-Linux-x86_64.sh
rm Mambaforge-Linux-x86_64.sh

# Installing cling: C++ jupyter kernel
mamba create -n cling
mamba activate cling
mamba install xeus-cling -c conda-forge
mamba install jupyterlab matplotlib pandas

# Other installs
sudo apt install -y i3 silversearcher-ag maim xclip stow udiskie blueman ripgrep curl arandr tree

echo "Reboot to see changes."
