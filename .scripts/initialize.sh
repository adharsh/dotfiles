#!/bin/bash

# Run from home directory (curl preferred):
# wget -vO initialize.sh https://raw.githubusercontent.com/adharsh/dotfiles/refs/heads/master/.scripts/initialize.sh && bash initialize.sh
# curl -o initialize.sh https://raw.githubusercontent.com/adharsh/dotfiles/refs/heads/master/.scripts/initialize.sh && bash initialize.sh

# Stop script if any command fails
set -ex

# Script must only run from home directory
if [ "$PWD" != "$HOME" ]; then
    echo "Error: Not in home directory. Current directory is $PWD"
    exit 1
fi

# Update & upgrade apt repos
sudo apt update -y
sudo apt upgrade -y

# Install Nvidia Driver
read -rp $'Follow these steps to install correct Nvidia Driver:
1. Get GPU name, if you already have it, can skip to step 2
1.1 Settings -> Additional Drivers
1.2 Install a (recent) driver of the form: Using NVIDIA driver metapackage from nvidia-driver-* (proprietary)
1.3 Run nvidia-smi without rebooting to get GPU name
2. Look up GPU name on https://www.nvidia.com/en-us/drivers/ and get driver info
3. Go to Settings -> Additional Drivers and then install the right driver of the form: Using NVIDIA driver metapackage from nvidia-driver-* (proprietary)
4. Reboot
5. Verify that nvidia-smi works'
if ! command -v nvidia-smi >/dev/null 2>&1; then
    echo "Error: NVIDIA driver not installed or nvidia-smi not found." >&2
    exit 1
fi

# Install bare minimum utilities
sudo apt install -y git xclip vim vim-gtk3 stow curl # Installing vim-gtk3 so yanks go into clipboard

# Install Chrome
if ! command -v google-chrome >/dev/null 2>&1; then
    curl -o google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo apt install -y ./google-chrome.deb
    rm google-chrome.deb
    # Dark Mode for default profile
    read -rp $'1. Sign in and sync. \n2. Set chrome://flags Auto Dark Mode for Web Contents to Enabled.'
    # Light Mode profile / dev-profile, only after signing in to default profile since that will be copied over
    cp -r ~/.config/google-chrome/Default ~/.config/google-chrome/dev-profile
fi

# Install VSCode
if ! command -v /usr/bin/code >/dev/null 2>&1; then
    wget -O vscode.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
    sudo apt install -y ./vscode.deb
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
    read -rp "Activate command in VSCode: Reload Custom CSS and JS"
fi

# Setup ssh keys
git config --global user.email "adharsh.babu@gmail.com"
git config --global user.name "Adharsh Babu"
git config --global core.editor "vim"
git config --global init.defaultBranch master
if [ ! -f ~/.ssh/id_ed25519.pub ]; then
    ssh-keygen -t ed25519 -C "adharsh.babu@gmail.com" -f ~/.ssh/id_ed25519 -N "" < /dev/null
    xclip -selection clipboard < ~/.ssh/id_ed25519.pub
    read -rp "Public ssh key copied to clipboard. Paste into Github ssh keys: https://github.com/settings/keys"
fi

# Install dotfiles
if [ ! -d ~/dotfiles ]; then
    git clone git@github.com:adharsh/dotfiles.git ~/dotfiles
fi

# Create .api_keys file
if [ ! -f ~/dotfiles/.api_keys ]; then
    PROMPT=$(cat <<EOM
export OPENAI_API_KEY=
export ANTHROPIC_API_KEY=
export CLOCKIFY_API_KEY=
EOM
)
    echo "$PROMPT" > ~/dotfiles/.api_keys
    read -rp "Populate .api_keys file: https://platform.openai.com/api-keys https://console.anthropic.com/settings/keys https://app.clockify.me/user/preferences#advanced"
    source ~/dotfiles/.api_keys
fi

# Create .screenshot_save_config
touch ~/dotfiles/.screenshot_save_config

# Install configurations
rm -f ~/.bashrc ~/.profile
chmod +x ~/dotfiles/bin/*
~/dotfiles/bin/dfm link

# Install CUDA (after stowing .bashrc for updated PATH and LD_LIBRARY_PATH)
read -rp $'1. Install CUDA: https://developer.nvidia.com/cuda-downloads \n2. Reboot or Ctrl+c and source ~/.bashrc or open new shell session.'
if ! command -v nvcc >/dev/null 2>&1; then
    echo "Error: Cuda not installed or nvcc not found." >&2
    exit 1
fi
if ! command -v ncu-ui >/dev/null 2>&1; then
    echo "Error: Nsight Compute not found." >&2
    exit 1
fi
if ! command -v nsys-ui >/dev/null 2>&1; then
    echo "Error: Nsight Systems not found." >&2
    exit 1
fi

# Install general packages
packages=(
    gnome-themes-extra gnome-icon-theme
    i3 xdotool xautomation silversearcher-ag maim udiskie blueman ripgrep curl arandr tree jq gpick
    xpad dunst p7zip-full gnome-sound-recorder pulseaudio pavucontrol zstd xdot yad audacity expect
    valgrind kcachegrind heaptrack heaptrack-gui massif-visualizer hotspot
    stress-ng gnome-system-monitor ncdu
    xournalpp libreoffice
    cmake
    obs-studio cheese
    gpg
)
sudo apt install -y "${packages[@]}"

# Add $USER to video group so you don't need sudo to run brightnessctl
sudo apt install -y brightnessctl
sudo usermod -aG video "$USER"

# xcape
# Linux: https://github.com/alols/xcape
# Windows: https://gist.github.com/tanyuan/55bca522bf50363ae4573d4bdcf06e2e
if ! command -v xcape >/dev/null 2>&1; then
    sudo apt install -y gcc make pkg-config libx11-dev libxtst-dev libxi-dev
    git clone https://github.com/alols/xcape.git ~/.xcape
    (cd ~/.xcape && make && sudo make install)
fi

# fzf: https://github.com/junegunn/fzf#using-git
if ! command -v fzf >/dev/null 2>&1; then
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf 
    yes | ~/.fzf/install
fi

# caffeine, activate on start
if ! command -v caffeine >/dev/null 2>&1; then
    sudo apt install -y caffeine
    bash ~/dotfiles/.scripts/caffeine-indicator-fix.sh
fi

# Web Dev fnm (like nvm but faster to handle different versions of node.js), pnpm (npm but faster)
if ! command -v fnm >/dev/null 2>&1; then
    curl -fsSL https://fnm.vercel.app/install | bash
    
    # Equivalent of source ~/.bashrc (update if needed in future since copied from ~/.bashrc)
    FNM_PATH="/home/adharsh/.local/share/fnm"
    if [ -d "$FNM_PATH" ]; then
        export PATH="$FNM_PATH:$PATH"
        eval "`fnm env`"
    fi
    read -rp "New fnm script is appended to .bashrc, merge with existing one. Check if sourcing matches in .bashrc."

    fnm install --lts
    fnm default "$(fnm list | grep lts | tail -n1 | awk '{print $2}' | sed 's/^v//')"
fi
if ! command -v pnpm >/dev/null 2>&1; then
    corepack enable pnpm
    # pnpm global packages 
    ## Markdown to Anki custom plugin
    yes | pnpm add -g markdown-it @iktakahiro/markdown-it-katex highlight.js
fi

# Install timer
if ! command -v alarm-clock-applet >/dev/null 2>&1; then
    sudo add-apt-repository -y ppa:tatokis/alarm-clock-applet
    sudo apt update
    sudo apt install -y alarm-clock-applet
fi

# Install copyq clipboard manager
if ! command -v copyq >/dev/null 2>&1; then
    sudo add-apt-repository -y ppa:hluk/copyq
    sudo apt update
    sudo apt install -y copyq
fi

# Installing mamba from miniforge
if ! command -v mamba >/dev/null 2>&1; then
    wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
    chmod +x Miniforge3-Linux-x86_64.sh
    ./Miniforge3-Linux-x86_64.sh -b

    # Equivalent of source ~/.bashrc (update if needed in future since copied from ~/.bashrc)
    MAMBA_ROOT_PREFIX="$HOME/miniforge3"
    export PATH="$MAMBA_ROOT_PREFIX/bin:$PATH"
    read -rp "Check if sourcing matches in .bashrc for mamba."

    conda config --set auto_activate_base false
    mamba shell init
    rm Miniforge3-Linux-x86_64.sh
fi

## Basic
if [ ! -d "$MAMBA_ROOT_PREFIX/envs/basic" ]; then
    mamba create -n basic python -y
    eval "$(mamba shell hook --shell bash)"
    mamba activate basic
    mamba install -y pip
    yes | pip install jupyterlab matplotlib pandas mypy shortuuid genanki loguru nbdime black isort ipywidgets gdown
    yes | pip install google-auth-oauthlib google-auth-httplib2 google-api-python-client tenacity
    yes | pip install nvitop
    nbdime config-git --enable --global
    mamba deactivate
fi

## Installing cling: C++ jupyter kernel
if [ ! -d "$MAMBA_ROOT_PREFIX/envs/cling" ]; then
    mamba create -n cling -y
    eval "$(mamba shell hook --shell bash)"
    mamba activate cling
    mamba install -y xeus-cling -c conda-forge
    mamba install -y pip
    yes | pip install jupyterlab
    mamba deactivate
fi

## Installing sgpt
if [ ! -d "$MAMBA_ROOT_PREFIX/envs/sgpt" ]; then
    mamba create -n sgpt python -y
    eval "$(mamba shell hook --shell bash)"
    mamba activate sgpt
    mamba install -y pip
    yes | pip install shell-gpt litellm
    sgpt --install-integration
    sgpt --install-functions
    read -rp "sgpt shell integration command run. Merge additions in .bashrc (with custom history lines) before continuing."
    mamba deactivate
fi

## Installing aider
if [ ! -d "$MAMBA_ROOT_PREFIX/envs/aider" ]; then
    mamba create -n aider python -y
    eval "$(mamba shell hook --shell bash)"
    mamba activate aider
    mamba install -y pip
    yes | pip install aider-install
    aider-install
    mamba deactivate
fi

## For VSCode Extension: Latex Sympy Calculator
if [ ! -d "$MAMBA_ROOT_PREFIX/envs/latex_sympy_calculator" ]; then
    mamba create -n latex_sympy_calculator python=3.11 -y
    eval "$(mamba shell hook --shell bash)"
    mamba activate latex_sympy_calculator 
    mamba install -y pip
    yes | pip install latex2sympy2 Flask
    mamba deactivate
fi

## Installing ML libraries: PyTorch
if [ ! -d "$MAMBA_ROOT_PREFIX/envs/ml" ]; then
    sudo apt install -y libcairo2-dev # for pycairo
    mamba create -n ml python=3.12 -y
    eval "$(mamba shell hook --shell bash)"
    mamba activate ml
    mamba install -y pip
    yes | pip install torch torchmetrics torchtext torchvision torchaudio tensorboard torch-tb-profiler jupyterlab pandas tokenizers datasets altair
    if ! python3 -c "import torch; exit(0 if torch.cuda.is_available() else 1)"; then
        read -rp "CUDA is not available."
        exit 1
    fi
    yes | pip install jupyterlab pandas tokenizers datasets altair triton
    yes | pip install jaxtyping pycairo
    git clone https://github.com/Deep-Learning-Profiling-Tools/triton-viz.git ~/.triton-viz
    (cd .triton-viz && pip install -e .)
    mamba deactivate
fi

# Install Bazel
if [ ! -f ~/bin/bazel ]; then
    wget -O ~/bin/bazel https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-amd64
    chmod +x ~/bin/bazel
fi

# Scrcpy, screen capture for Android
if ! command -v scrcpy >/dev/null 2>&1; then
    sudo apt install -y ffmpeg libsdl2-2.0-0 adb wget \
                    gcc git pkg-config meson ninja-build libsdl2-dev \
                    libavcodec-dev libavdevice-dev libavformat-dev libavutil-dev \
                    libswresample-dev libusb-1.0-0 libusb-1.0-0-dev
    git clone https://github.com/Genymobile/scrcpy ~/.scrcpy
    (cd ~/.scrcpy && ./install_release.sh)
fi

# Install anki
if ! command -v anki >/dev/null 2>&1; then
    wget https://github.com/ankitects/anki/releases/download/24.06.3/anki-24.06.3-linux-qt6.tar.zst
    tar --use-compress-program=unzstd -xvf anki-24.06.3-linux-qt6.tar.zst
    cd anki-24.06.3-linux-qt6/
    sudo ./install.sh
    cd ..
    rm anki-24.06.3-linux-qt6.tar.zst 
    read -rp "Leave anki-24.06.3-linux-qt6/uninstall.sh in case it needs to be uninstalled."

    # Make sure to install Anki plugins, descriptions in order below
    read -rp "Install Anki Plugins: 2055492159 874215009 1771074083 613684242 817108664 175794613"
    # Anki Connect: for connecting to Anki via an API
    # Advanced browser: In browse, add Time (Total) and Lapses, sort by either column
    # Review Heatmap: Heatmap similar to contribution activity on Github
    ## Useful when starting fresh: Fine Tuning -> Ignore data before date
    # True Retention: Shift+Click Stats button
    ## Adjust interval so retention is 80-90%: https://youtu.be/A56wVF9Fr0Q?si=ibnpMcC4nsgdksZu&t=564
    # Anki Simulator: Predict how long it will to master a deck
    # Anki Leaderboard: Compete online
    read -rp "Adjust Display Order->New card gather order = Random cards"
    read -rp "Adjust Display Order->New card sort order = Order gathered"
fi

# Install docker
## Add Docker's official GPG key:
if ! command -v docker >/dev/null 2>&1; then
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
    sudo getent group docker || sudo groupadd docker # Create group only if group doesn't exist (prints stuff out)
    sudo usermod -aG docker "$USER" # docker will only work without sudo after logout
    read -rp "Reboot to run docker without sudo."
    exit 1
fi
## Installation verification
if ! docker run hello-world | grep -q "Hello from Docker!"; then
    read -rp "Docker verification failed."
    exit 1
fi

# (Optional) Install slack
if ! command -v /usr/bin/slack >/dev/null 2>&1; then
    read -rp "(optional) Slack isn't installed."
fi

# Install bruno
sudo mkdir -p /etc/apt/keyrings
sudo gpg --list-keys
sudo gpg --no-default-keyring --keyring /etc/apt/keyrings/bruno.gpg --keyserver keyserver.ubuntu.com --recv-keys 9FA6017ECABE0266
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/bruno.gpg] http://debian.usebruno.com/ bruno stable" | sudo tee /etc/apt/sources.list.d/bruno.list
sudo apt update && sudo apt install bruno
# Install fly
curl -L https://fly.io/install.sh | sh

# Check if passwords are being synced in chrome
read -rp "If password sync is not working (check chrome://sync-internals), then run bash ~/dotfiles/.scripts/restart_chrome_password_sync.sh"

read -rp "Reboot to see changes."
