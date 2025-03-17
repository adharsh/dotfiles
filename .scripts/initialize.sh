#!/bin/bash

# Stop script if any command fails
set -e

# Update apt repos
sudo apt update

# Install Chrome (specific version to avoid breaking changes to viewport)
read -p  "Install Google Chrome 130.0.6723.58: https://drive.google.com/file/d/1Sp1NCEoQFFh8H8cE2O5BY8jRJ4bLSaBG/view" -r
pushd .
cd ~/Downloads/
# Verify version with: 
version=$(dpkg-deb -f google-chrome-stable_current_amd64.deb Version)
if [ "$version" != "130.0.6723.58-1" ]; then
    echo "Version mismatch" >&2
    exit 1
fi
sudo apt install ./google-chrome-stable_current_amd64.deb
popd
read -p "Assumes chrome is already installed. Set chrome://flags Auto Dark Mode for Web Contents to Enabled." -r

# Install configurations
cd ~/dotfiles
chmod +x ~/dotfiles/bin/*
stow .

# Installing vim-gtk3 so yanks go into clipboard
sudo apt install -y git xpad dunst p7zip-full gnome-sound-recorder pulseaudio pavucontrol zstd xdot yad
sudo apt install -y vim vim-gtk3 i3 xdotool xautomation silversearcher-ag maim xclip stow udiskie blueman ripgrep curl arandr tree jq gpick
sudo apt install -y valgrind kcachegrind heaptrack heaptrack-gui massif-visualizer hotspot
sudo apt install -y stress-ng gnome-system-monitor ncdu
# sudo apt install -y pandoc texlive-latex-recommended wkhtmltopdf

# Git config
git config --global user.email "adharsh.babu@gmail.com"
git config --global user.name "Adharsh Babu"

# Add $USER to video group so you don't need sudo to run brightnessctl
sudo apt install -y brightnessctl
sudo usermod -aG video "$USER"

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
bash .scripts/caffeine-indicator-fix.sh

# Web Dev - fnm, node, pnpm
curl -fsSL https://fnm.vercel.app/install | bash
read -p "New fnm script is appended to .bashrc, merge with existing one, be sure to add in --use-on-cd flag" -r
fnm install --lts
fnm default "$(fnm list | grep lts | tail -n1)"
corepack enable pnpm
command -v fnm >/dev/null 2>&1 || { echo "Error: fnm is NOT installed"; exit 1; }
command -v node >/dev/null 2>&1 || { echo "Error: Node.js is NOT installed"; exit 1; }
command -v pnpm >/dev/null 2>&1 || { echo "Error: pnpm is NOT installed"; exit 1; }
pnpm setup
read -p "New pnpm script is appended to .bashrc, merge with existing one." -r

# pnpm global packages 
## Anki
pnpm add -g markdown-it @iktakahiro/markdown-it-katex highlight.js

# Install anki
pushd .
cd ~/Downloads
wget https://github.com/ankitects/anki/releases/download/24.06.3/anki-24.06.3-linux-qt6.tar.zst
tar --use-compress-program=unzstd -xvf anki-24.06.3-linux-qt6.tar.zst
cd anki-24.06.3-linux-qt6/
read -p "Please check anki-24.06.3-linux-qt6/install.sh script before running with sudo. Once done, hit enter." -r
sudo ./install.sh
cd ..
rm anki-24.06.3-linux-qt6.tar.zst 
popd 
read -p "Leave anki-24.06.3-linux-qt6/uninstall.sh in case it needs to be uninstalled." -r

# Make sure to install Anki plugins, descriptions in order below
read -p "Install Anki Plugins: 2055492159 874215009 1771074083 613684242 817108664 175794613" -r
# Anki Connect: for connecting to Anki via an API
# Advanced browser: In browse, add Time (Total) and Lapses, sort by either column
# Review Heatmap: Heatmap similar to contribution activity on Github
## Useful when starting fresh: Fine Tuning -> Ignore data before date
# True Retention: Shift+Click Stats button
## Adjust interval so retention is 80-90%: https://youtu.be/A56wVF9Fr0Q?si=ibnpMcC4nsgdksZu&t=564
# Anki Simulator: Predict how long it will to master a deck
# Anki Leaderboard: Compete online
read -p "Adjust Display Order->New card gather order = Random cards" -r
read -p "Adjust Display Order->New card sort order = Order gathered" -r

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
sudo chown -R "$(whoami)" "$(which code)"
sudo chown -R "$(whoami)" /usr/share/code
read -p "Activate command in VSCode: Reload Custom CSS and JS" -r

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
yes | pip install jupyterlab matplotlib pandas mypy shortuuid genanki loguru nbdime black isort ipywidgets gdown
yes | pip install google-auth-oauthlib google-auth-httplib2 google-api-python-client tenacity
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
yes | pip install shell-gpt litellm
sgpt --install-integration
read -p "sgpt shell integration command run. Merge additions in .bashrc (with custom history line) before continuing." -r
mamba deactivate

## Installing aider
mamba create -n aider python -y
mamba activate aider
mamba install -y pip
yes | pip install aider-chat
mamba deactivate

## For VSCode Extension: Latex Sympy Calculator
mamba create -n latex_sympy_calculator python=3.11 -y
mamba activate latex_sympy_calculator 
mamba install -y pip
yes | pip install latex2sympy2 Flask 
mamba deactivate

## Installing ML libraries: PyTorch
read -p "Install CUDA first." -r
mamba create -n ml python=3.12 -y
mamba activate ml
mamba install -y pip
yes | pip install torch torchmetrics torchtext torchvision torchaudio tensorboard torch-tb-profiler jupyterlab pandas tokenizers datasets nvitop altair
python3 -c "import torch; exit(0 if not torch.cuda.is_available() else 1)" && read -p "CUDA is not available" -r
yes | pip install jupyterlab pandas tokenizers datasets nvitop altair triton
yes | pip install jaxtyping pycairo
git clone https://github.com/Deep-Learning-Profiling-Tools/triton-viz.git ~/.triton-viz
(cd .triton-viz && pip install -e .)
mamba deactivate

# Install docker
## Add Docker's official GPG key:
sudo apt update
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
## Add the repository to Apt sources:
# shellcheck disable=SC1091
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
## Install latest
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
## Linux post install
sudo getent group docker || sudo groupadd docker # Create group only if group doesn't exist
sudo usermod -aG docker "$USER"
newgrp docker
## Installation verification
docker run hello-world | grep -q "Hello from Docker!"
## Start docker (Done automatically default in Ubuntu)
sudo systemctl enable docker.service
sudo systemctl enable containerd.service

# Install Bazel
wget -O ~/bin/bazel https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-amd64
chmod +x ~/bin/bazel

# Scrcpy, screen capture for Android
sudo apt install ffmpeg libsdl2-2.0-0 adb wget \
                 gcc git pkg-config meson ninja-build libsdl2-dev \
                 libavcodec-dev libavdevice-dev libavformat-dev libavutil-dev \
                 libswresample-dev libusb-1.0-0 libusb-1.0-0-dev
git clone https://github.com/Genymobile/scrcpy ~/.scrcpy
(cd ~/.scrcpy && ./install_release.sh)



read -p "Reboot to see changes." -r
