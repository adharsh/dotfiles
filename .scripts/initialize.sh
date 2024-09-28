#!/bin/bash

# Stop script if any command fails
set -e

# Update apt repos
sudo apt update

# Assume's Chrome is installed
read -p "Assumes chrome is already installed. Set chrome://flags Auto Dark Mode for Web Contents to Enabled."

# Install configurations
cd ~/dotfiles
chmod +x ~/dotfiles/bin/*
stow .

# Installing vim-gtk3 so yanks go into clipboard
sudo apt install -y git xpad dunst p7zip-full gnome-sound-recorder pulseaudio pavucontrol zstd xdot
sudo apt install -y vim vim-gtk3 i3 xdotool xautomation silversearcher-ag maim xclip stow udiskie blueman ripgrep curl arandr tree jq gpick
sudo apt install -y valgrind kcachegrind heaptrack heaptrack-gui massif-visualizer hotspot
sudo apt install -y stress-ng gnome-system-monitor

# Git config
git config --global user.email "adharsh.babu@gmail.com"
git config --global user.name "Adharsh Babu"

# Add $USER to video group so you don't need sudo to run brightnessctl
sudo apt install -y brightnessctl
sudo usermod -aG video $USER

# xcape
# Linux: https://github.com/alols/xcape
# Windows: https://gist.github.com/tanyuan/55bca522bf50363ae4573d4bdcf06e2e
sudo apt install -y gcc make pkg-config libx11-dev libxtst-dev libxi-dev
git clone https://github.com/alols/xcape.git ~/.xcape
(cd ~/.xcape && make && sudo make install)

# fzf
# https://github.com/junegunn/fzf#using-git
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf 
yes | ~/.fzf/install

# caffeine, activate on start
sudo apt install -y caffeine
bash ~/dotfiles/.scripts/caffeine-indicator-fix.sh

# Web Dev - fnm, node, pnpm
curl -fsSL https://fnm.vercel.app/install | bash
read -p "New fnm script is appended to .bashrc, merge with existing one, be sure to add in --use-on-cd flag"
fnm install --lts
fnm default $(fnm list | grep lts | tail -n1)
corepack enable pnpm
command -v fnm >/dev/null 2>&1 || { echo "Error: fnm is NOT installed"; exit 1; }
command -v node >/dev/null 2>&1 || { echo "Error: Node.js is NOT installed"; exit 1; }
command -v pnpm >/dev/null 2>&1 || { echo "Error: pnpm is NOT installed"; exit 1; }
pnpm setup

# pnpm global packages 
## Anki
pnpm add -g markdown-it @iktakahiro/markdown-it-katex highlight.js

# Install anki
pushd .
cd ~/Downloads
wget https://github.com/ankitects/anki/releases/download/24.06.3/anki-24.06.3-linux-qt6.tar.zst
tar --use-compress-program=unzstd -xvf anki-24.06.3-linux-qt6.tar.zst
cd anki-24.06.3-linux-qt6/
read -p "Please check anki-24.06.3-linux-qt6/install.sh script before running with sudo. Once done, hit enter."
sudo ./install.sh
cd ..
rm anki-24.06.3-linux-qt6.tar.zst 
popd 
read -p "Leave anki-24.06.3-linux-qt6/uninstall.sh in case it needs to be uninstalled."

# Make sure to install AnkiConnect 
read -p "Make sure to install addon AnkiConnect in Anki: https://foosoft.net/projects/anki-connect/"

# Install timer
sudo add-apt-repository -y ppa:tatokis/alarm-clock-applet
sudo apt update
sudo apt install alarm-clock-applet

# Install copyq clipboard manager
sudo add-apt-repository ppa:hluk/copyq
sudo apt update
sudo apt install -y copyq

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
read -p "Activate command in VSCode: Reload Custom CSS and JS"

# Installing mamba from miniforge
wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
chmod +x Miniforge3-Linux-x86_64.sh
./Miniforge3-Linux-x86_64.sh -b
conda config --set auto_activate_base false
rm Miniforge3-Linux-x86_64.sh

## Basic
mamba create -n basic python -y
mamba activate basic
mamba install -y pip
yes | pip install jupyterlab matplotlib pandas mypy shortuuid genanki loguru nbdime
nbdime config-git --enable --global
mamba deactivate

## Installing cling: C++ jupyter kernel
mamba create -n cling -y
mamba activate cling
mamba install -y xeus-cling -c conda-forge
mamba install -y pip
yes | pip install jupyterlab
mamba deactivate

## Installing sgpt
## https://www.youtube.com/watch?v=Vxsx7Il-KMA&ab_channel=AICodeKing
mamba create -n sgpt python -y
mamba activate sgpt
mamba install -y pip
yes | pip install shell-gpt litellm matplotlib pandas
mamba deactivate

## Installing aider
mamba create -n aider python -y
mamba activate aider
mamba install -y pip
yes | pip install aider-chat
mamba deactivate

# Install docker
## Add Docker's official GPG key:
sudo apt update
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
## Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
## Install latest
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
## Linux post install
sudo getent group docker || sudo groupadd docker # Create group only if group doesn't exist
sudo usermod -aG docker $USER
newgrp docker
## Installation verification
docker run hello-world | grep -q "Hello from Docker!"
## Start docker (Done automatically default in Ubuntu)
sudo systemctl enable docker.service
sudo systemctl enable containerd.service

# Install Bazel
wget -O ~/bin/bazel https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-amd64
chmod +x ~/bin/bazel

read -p "Reboot to see changes."
