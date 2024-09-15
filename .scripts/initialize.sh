#!/bin/bash

# Stop script if any command fails
set -e

# Update apt repos
sudo apt update

# Git config
sudo apt install -y git
git config --global user.email "adharsh.babu@gmail.com"
git config --global user.name "Adharsh Babu"

# Add $USER to video group so you don't need sudo to run brightnessctl
sudo apt install -y brightnessctl
sudo usermod -aG video $USER

# Linux: https://github.com/alols/xcape
# Windows: https://gist.github.com/tanyuan/55bca522bf50363ae4573d4bdcf06e2e
sudo apt install -y gcc make pkg-config libx11-dev libxtst-dev libxi-dev
git clone https://github.com/alols/xcape.git ~/.xcape
(cd ~/.xcape && make && sudo make install)

# https://github.com/junegunn/fzf#using-git
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf 
yes | ~/.fzf/install

# caffeine, activate on start
sudo apt install -y caffeine
~/dotfiles/.scripts/caffeine-indicator-fix.sh

# Install nvm: package manager for node.js
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
nvm install node
nvm alias default node 
# nvm install 19
# nvm use 19
npm install --global yarn

# Other installs  
# Installing vim-gtk3 so yanks go into clipboard
sudo apt install -y vim vim-gtk3 i3 xdotool xautomation silversearcher-ag maim xclip stow udiskie blueman ripgrep curl arandr tree jq gpick git xpad dunst p7zip-full gnome-sound-recorder pulseaudio pavucontrol zstd xdot

# Install configurations
cd ~/dotfiles
chmod +x ~/dotfiles/bin/*
stow .

# Install anki
wget https://github.com/ankitects/anki/releases/download/24.06.3/anki-24.06.3-linux-qt6.tar.zst
tar --use-compress-program=unzstd -xvf anki-24.06.3-linux-qt6.tar.zst
cd anki-24.06.3-linux-qt6/
read -p "Please check anki-24.06.3-linux-qt6/install.sh script before running with sudo. Once done, hit enter."
sudo ./install.sh
cd ..
rm anki-24.06.3-linux-qt6.tar.zst 
# Leave anki-24.06.3-linux-qt6/uninstall.sh in case it needs to be uninstalled

# Install mdanki
npm install -g mdanki
MDANKI_SQL_PATH="$HOME/.nvm/versions/node/$(node --version)/lib/node_modules/mdanki/node_modules/sql.js/js"
cp $MDANKI_SQL_PATH/sql-memory-growth.js $MDANKI_SQL_PATH/sql.js

# Install timer
sudo add-apt-repository -y ppa:tatokis/alarm-clock-applet
sudo apt update
sudo apt install alarm-clock-applet

# Install copyq clipboard manager
sudo add-apt-repository ppa:hluk/copyq
sudo apt update
sudo apt install -y copyq
# Set show preview

# Installing mamba from miniforge
wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
chmod +x Miniforge3-Linux-x86_64.sh
./Miniforge3-Linux-x86_64.sh -b
conda config --set auto_activate_base false
rm Miniforge3-Linux-x86_64.sh

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
mamba deactivate

## Installing cling: C++ jupyter kernel
mamba create -n cling -y
mamba activate cling
mamba install -y xeus-cling -c conda-forge
mamba install -y jupyterlab
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
yes | pip install aider-chat
mamba deactivate

# Install docker
# Add Docker's official GPG key:
sudo apt update
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
# Install latest
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
# Linux post install
sudo getent group docker || sudo groupadd docker # Create group only if group doesn't exist
sudo usermod -aG docker $USER
newgrp docker
# Installation verification
docker run hello-world | grep -q "Hello from Docker!"
# Start docker (Done automatically default in Ubuntu)
sudo systemctl enable docker.service
sudo systemctl enable containerd.service

echo "Reboot to see changes."
