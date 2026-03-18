#!/bin/bash

# Run from home directory (curl preferred):
# wget -vO initialize.sh https://raw.githubusercontent.com/adharsh/dotfiles/refs/heads/master/.scripts/initialize.sh && bash initialize.sh
# curl -o initialize.sh https://raw.githubusercontent.com/adharsh/dotfiles/refs/heads/master/.scripts/initialize.sh && bash initialize.sh

# Stop script if any command fails
set -ex
trap 'echo "Error on line $LINENO (exit code $?)"' ERR

# Script must only run from home directory
if [ "$PWD" != "$HOME" ]; then
    echo "Error: Not in home directory. Current directory is $PWD"
    exit 1
fi

# Update & upgrade apt repos
sudo apt update -y
sudo apt upgrade -y

# Install Nvidia Driver
if ! command -v nvidia-smi >/dev/null 2>&1; then
    read -rp $'Error: NVIDIA driver not installed or nvidia-smi not found.
    Follow these steps to install correct Nvidia Driver:
    1. Get GPU name, if you already have it, can skip to step 2
    1.1 Settings -> Additional Drivers
    1.2 Install a (recent) driver of the form: Using NVIDIA driver metapackage from nvidia-driver-* (proprietary)
    1.3 Run nvidia-smi without rebooting to get GPU name
    2. Look up GPU name on https://www.nvidia.com/en-us/drivers/ and get driver info
    3. Go to Settings -> Additional Drivers and then install the right driver of the form: Using NVIDIA driver metapackage from nvidia-driver-* (proprietary)
    4. Reboot
    5. Verify that nvidia-smi works'
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
    cp -r "$HOME/.config/google-chrome/Default" "$HOME/.config/google-chrome/dev-profile"
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
if [ ! -f "$HOME/.ssh/id_ed25519.pub" ]; then
    ssh-keygen -t ed25519 -C "adharsh.babu@gmail.com" -f "$HOME/.ssh/id_ed25519" -N "" < /dev/null
    xclip -selection clipboard < "$HOME/.ssh/id_ed25519.pub"
    read -rp "Public ssh key copied to clipboard. Paste into Github ssh keys: https://github.com/settings/keys"
fi

# Install dotfiles
if [ ! -d "$HOME/dotfiles" ]; then
    git clone git@github.com:adharsh/dotfiles.git "$HOME/dotfiles"
fi

# Create .api_keys file
if [ ! -f "$HOME/dotfiles/.api_keys" ]; then
    PROMPT=$(cat <<EOM
export OPENAI_API_KEY=
export CLOCKIFY_API_KEY=
EOM
)
    echo "$PROMPT" > "$HOME/dotfiles/.api_keys"
    read -rp "Populate .api_keys file: https://platform.openai.com/api-keys https://console.anthropic.com/settings/keys https://app.clockify.me/user/preferences#advanced"
    source "$HOME/dotfiles/.api_keys"
fi

# Create .screenshot_save_config
touch "$HOME/dotfiles/.screenshot_save_config"

# Install configurations
rm -f "$HOME/.bashrc" "$HOME/.profile"
chmod +x "$HOME/dotfiles/bin/"*
"$HOME/dotfiles/bin/dfm" link

# Install CUDA (after stowing .bashrc for updated PATH and LD_LIBRARY_PATH)
if ! command -v nvcc >/dev/null 2>&1; then
    read -rp $'Error: Cuda not installed or nvcc not found.
    1. Install CUDA: https://developer.nvidia.com/cuda-downloads 
    2. Reboot or Ctrl+c and source ~/.bashrc or open new shell session.'
    exit 1
fi
if ! command -v ncu-ui >/dev/null 2>&1; then
    read -rp $'Error: Nsight Compute not found.
    1. Install CUDA: https://developer.nvidia.com/cuda-downloads 
    2. Reboot or Ctrl+c and source ~/.bashrc or open new shell session.'
    exit 1
fi
if ! command -v nsys-ui >/dev/null 2>&1; then
    read -rp $'Error: Nsight Systems not found.
    1. Install CUDA: https://developer.nvidia.com/cuda-downloads 
    2. Reboot or Ctrl+c and source ~/.bashrc or open new shell session.'
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
    obs-studio cheese
    gpg
    build-essential autoconf libssl-dev libyaml-dev zlib1g-dev libffi-dev libgmp-dev rustc # For rbenv
    ca-certificates wget
    shellcheck
    tmux
    gh
)
sudo apt install -y "${packages[@]}"

# Authenticate GitHub CLI
if ! gh auth status >/dev/null 2>&1; then
    gh auth login --web
fi

# Install latest version of CMake for CUDA compatibility
sudo apt remove -y --purge --auto-remove cmake
test -f /usr/share/doc/kitware-archive-keyring/copyright ||
wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | sudo tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null
echo 'deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ jammy main' | sudo tee /etc/apt/sources.list.d/kitware.list >/dev/null
sudo apt update -y
test -f /usr/share/doc/kitware-archive-keyring/copyright ||
sudo rm /usr/share/keyrings/kitware-archive-keyring.gpg
sudo apt install -y kitware-archive-keyring
sudo apt update -y
sudo apt install -y cmake

# Add $USER to video group so you don't need sudo to run brightnessctl
sudo apt install -y brightnessctl
sudo usermod -aG video "$USER"

# xcape
# Linux: https://github.com/alols/xcape
# Windows: https://gist.github.com/tanyuan/55bca522bf50363ae4573d4bdcf06e2e
if ! command -v xcape >/dev/null 2>&1; then
    sudo apt install -y gcc make pkg-config libx11-dev libxtst-dev libxi-dev
    git clone https://github.com/alols/xcape.git "$HOME/.xcape"
    (cd "$HOME/.xcape" && make && sudo make install)
fi

# fzf: https://github.com/junegunn/fzf#using-git
if ! command -v fzf >/dev/null 2>&1; then
    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
    yes | "$HOME/.fzf/install"
fi

# caffeine, activate on start
if ! command -v caffeine >/dev/null 2>&1; then
    sudo apt install -y caffeine
    bash "$HOME/dotfiles/.scripts/caffeine-indicator-fix.sh"
fi

# Web Dev fnm (like nvm but faster to handle different versions of node.js), pnpm (npm but faster)
if ! command -v fnm >/dev/null 2>&1; then
    curl -fsSL https://fnm.vercel.app/install | bash
    read -rp "source ~/.bashrc then rerun initialize.sh to proceed with installation."
    exit 0
fi
fnm install --lts
fnm default "$(fnm list | grep lts | tail -n1 | awk '{print $2}' | sed 's/^v//')"

if ! command -v pnpm >/dev/null 2>&1; then
    npm install -g corepack@latest 
    corepack enable pnpm
    pnpm setup

    read -rp "source ~/.bashrc then rerun initialize.sh to proceed with installation."
    exit 0
fi
# pnpm global packages 
## Markdown to Anki custom plugin
yes | pnpm add -g markdown-it @iktakahiro/markdown-it-katex highlight.js

# Enable pnpm maintenance timers (daily global update, weekly store prune)
systemctl --user daemon-reload
systemctl --user enable --now pnpm-update.timer pnpm-store-prune.timer

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

# Install uv
if ! command -v uv >/dev/null 2>&1; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi


# Installing conda via Miniforge
CONDA_BIN="$HOME/miniforge3/bin/conda"
if [ ! -x "$CONDA_BIN" ]; then
    curl -L -O https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
    read -rp "Proceed with initialization? [yes|no] -> type yes."
    bash Miniforge3-Linux-x86_64.sh
    rm Miniforge3-Linux-x86_64.sh
    read -rp "source ~/.bashrc then rerun initialize.sh to proceed with installation."
    exit 0
fi
"$CONDA_BIN" config --set auto_activate_base false

# Initialize conda for this script (lazy-loaded in .bashrc, so we do it explicitly here)
eval "$("$CONDA_BIN" shell.bash hook)"

## Basic
if [ ! -d "$("$CONDA_BIN" info --base)/envs/basic" ]; then
    conda create -n basic python -y
    conda activate basic
    pip_packages=(
        jupyterlab matplotlib pandas mypy shortuuid genanki loguru nbdime black isort ipywidgets gdown
        google-auth-oauthlib google-auth-httplib2 google-api-python-client tenacity
        nvitop
    )
    uv pip install "${pip_packages[@]}"
    nbdime config-git --enable --global
    conda deactivate
fi

## Installing cling: C++ jupyter kernel
if [ ! -d "$("$CONDA_BIN" info --base)/envs/cling" ]; then
    conda create -n cling python -y
    conda activate cling
    conda install -y xeus-cling -c conda-forge
    uv pip install jupyterlab
    conda deactivate
fi

## Installing sgpt
if [ ! -d "$("$CONDA_BIN" info --base)/envs/sgpt" ]; then
    conda create -n sgpt python -y
    conda activate sgpt
    uv pip install shell-gpt litellm
    sgpt --install-integration
    sgpt --install-functions
    read -rp "sgpt shell integration command run. Merge additions in .bashrc (with custom history lines) before continuing."
    conda deactivate
    exit 0
fi

## For VSCode Extension: Latex Sympy Calculator
if [ ! -d "$("$CONDA_BIN" info --base)/envs/latex_sympy_calculator" ]; then
    conda create -n latex_sympy_calculator python=3.11 -y
    conda activate latex_sympy_calculator
    uv pip install latex2sympy2 Flask
    conda deactivate
fi

## Installing ML libraries: PyTorch
if [ ! -d "$("$CONDA_BIN" info --base)/envs/ml" ]; then
    sudo apt install -y libcairo2-dev # for pycairo
    conda create -n ml python=3.12 -y
    conda activate ml
    uv pip install torch
    if ! python3 -c "import torch; exit(0 if torch.cuda.is_available() else 1)"; then
        read -rp "CUDA is not available."
        exit 1
    fi
    pip_packages=(
        torchmetrics torchtext torchvision torchaudio tensorboard torch-tb-profiler
        triton "kernel_tuner[cuda]"
        jupyterlab pandas tokenizers datasets altair
        jaxtyping pycairo
    )
    uv pip install "${pip_packages[@]}"

    [ -d "$HOME/.triton-viz" ] && rm -rf "$HOME/.triton-viz"
    git clone https://github.com/Deep-Learning-Profiling-Tools/triton-viz.git "$HOME/.triton-viz"
    (cd .triton-viz && uv pip install -e .)
    conda deactivate
fi

# Install Bazel
if [ ! -f "$HOME/bin/bazel" ]; then
    wget -O "$HOME/bin/bazel" https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-amd64
    chmod +x "$HOME/bin/bazel"
fi
# Install buildifier
if ! command -v buildifier >/dev/null 2>&1; then
    curl -L https://github.com/bazelbuild/buildtools/releases/latest/download/buildifier-linux-amd64 -o buildifier
    chmod +x buildifier
    sudo mv buildifier /usr/local/bin/
fi

# Scrcpy, screen capture for Android
if ! command -v scrcpy >/dev/null 2>&1; then
    sudo apt install -y ffmpeg libsdl2-2.0-0 adb wget \
                    gcc git pkg-config meson ninja-build libsdl2-dev \
                    libavcodec-dev libavdevice-dev libavformat-dev libavutil-dev \
                    libswresample-dev libusb-1.0-0 libusb-1.0-0-dev
    git clone https://github.com/Genymobile/scrcpy "$HOME/.scrcpy"
    (cd "$HOME/.scrcpy" && ./install_release.sh)
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
if ! command -v bruno >/dev/null 2>&1; then
    sudo mkdir -p /etc/apt/keyrings
    sudo gpg --list-keys
    sudo gpg --no-default-keyring --keyring /etc/apt/keyrings/bruno.gpg --keyserver keyserver.ubuntu.com --recv-keys 9FA6017ECABE0266
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/bruno.gpg] http://debian.usebruno.com/ bruno stable" | sudo tee /etc/apt/sources.list.d/bruno.list
    sudo apt update && sudo apt install bruno
fi

# Install fly
if ! command -v flyctl >/dev/null 2>&1; then
    curl -L https://fly.io/install.sh | sh
fi

# Install rbenv
if ! command -v rbenv >/dev/null 2>&1; then
    git clone https://github.com/rbenv/rbenv.git "$HOME/.rbenv"
    "$HOME/.rbenv/bin/rbenv" init
    git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
    latest_version=$(rbenv install -l | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | tail -1)
    rbenv install "$latest_version"
    rbenv global "$latest_version"
    gem install bundler
fi

# Install latest LLVM
read -rp "Read https://apt.llvm.org/ to check latest LLVM version specifically for Ubuntu 22.04 Jammy and update LLVM_VERSION below."
LLVM_VERSION=21
echo "LLVM version: $LLVM_VERSION"
if ! command -v "clang-tidy-$LLVM_VERSION" >/dev/null 2>&1; then
    curl -fsSL https://apt.llvm.org/llvm.sh -o /tmp/llvm.sh
    chmod +x /tmp/llvm.sh
    sudo /tmp/llvm.sh "$LLVM_VERSION" all
    rm -f /tmp/llvm.sh
    ## Fix known LLVM packaging issue where files move between sub-packages across versions
    sudo dpkg --configure -a
    sudo apt install -y --fix-broken -o Dpkg::Options::="--force-overwrite"
    ## Register as defaults
    sudo update-alternatives --install /usr/bin/clangd       clangd       "/usr/bin/clangd-$LLVM_VERSION"       100
    sudo update-alternatives --install /usr/bin/clang-tidy   clang-tidy   "/usr/bin/clang-tidy-$LLVM_VERSION"   100
    sudo update-alternatives --install /usr/bin/clang-format clang-format "/usr/bin/clang-format-$LLVM_VERSION" 100
    sudo update-alternatives --install /usr/bin/clang   clang   "/usr/bin/clang-$LLVM_VERSION"   100
    sudo update-alternatives --install /usr/bin/clang++ clang++ "/usr/bin/clang++-$LLVM_VERSION" 100
fi

# Install brave browser (to block youtube ads)
if ! command -v brave-browser-stable >/dev/null 2>&1; then
    curl -fsS https://dl.brave.com/install.sh | sh
fi

# Install codex
if ! command -v codex >/dev/null 2>&1; then
    yes | pnpm i -g @openai/codex
fi

# Install claude-code
if ! command -v claude >/dev/null 2>&1; then
    curl -fsSL https://claude.ai/install.sh | bash

    # ruflo
    yes | pnpm add -g ruflo@latest

    # task master ai
    yes | pnpm add -g task-master-ai@latest
    claude mcp add task-master-ai --scope user --env TASK_MASTER_TOOLS="core" -- task-master-ai

    # gitnexus (better than deepwiki)
    ## gcc-13 needed to build @ladybugdb/core from source (prebuilt requires GLIBC 2.38, Ubuntu 22.04 has 2.35)
    if ! command -v g++-13 >/dev/null 2>&1; then
        sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test
        sudo apt update
        sudo apt install -y gcc-13 g++-13
    fi
    ## Allow @ladybugdb/core install script (pnpm v10 blocks lifecycle scripts by default)
    PNPM_GLOBAL_DIR="$(dirname "$(pnpm root -g)")"
    if ! grep -q '@ladybugdb/core' "$PNPM_GLOBAL_DIR/pnpm-workspace.yaml" 2>/dev/null; then
        if [ -f "$PNPM_GLOBAL_DIR/pnpm-workspace.yaml" ]; then
            sed -i "/^onlyBuiltDependencies:/a\\  - '@ladybugdb/core'" "$PNPM_GLOBAL_DIR/pnpm-workspace.yaml"
        else
            printf "onlyBuiltDependencies:\n  - '@ladybugdb/core'\n" > "$PNPM_GLOBAL_DIR/pnpm-workspace.yaml"
        fi
    fi
    yes | pnpm add -g gitnexus@latest
    "$DOTFILES_DIR/.scripts/fix-gitnexus.sh"
    ## Register MCP using pnpm global binary (not npx, which has its own broken copy)
    claude mcp add gitnexus --scope user -- gitnexus mcp
fi

# Install whisper.cpp (speech-to-text)
if [ ! -x "$HOME/whisper.cpp/build/bin/whisper-cli" ]; then
    sudo apt install -y libsdl2-dev xdotool xterm wmctrl cmake build-essential
    git clone https://github.com/ggml-org/whisper.cpp.git "$HOME/whisper.cpp"
    (cd "$HOME/whisper.cpp" && sh ./models/download-ggml-model.sh base.en)
    (cd "$HOME/whisper.cpp" && cmake -B build -DGGML_CUDA=1 -DWHISPER_SDL2=ON)
    (cd "$HOME/whisper.cpp" && cmake --build build -j"$(nproc)" --config Release)
    LD_LIBRARY_PATH="$HOME/whisper.cpp/build/src:$HOME/whisper.cpp/build/ggml/src:$HOME/whisper.cpp/build/ggml/src/ggml-cuda" \
        "$HOME/whisper.cpp/build/bin/whisper-quantize" \
        "$HOME/whisper.cpp/models/ggml-base.en.bin" \
        "$HOME/whisper.cpp/models/ggml-base.en-q5_0.bin" q5_0
fi

# Check if passwords are being synced in chrome
read -rp "If password sync is not working (check chrome://sync-internals), then run bash \$HOME/dotfiles/.scripts/restart_chrome_password_sync.sh"

read -rp "Reboot to see changes."

# How to uninstall CUDA and Nvidia Driver
# https://askubuntu.com/a/206289
# sudo apt remove --purge 'libnvidia-*' 'cuda-*' 'nsight-*' 'nvidia-*'
# sudo apt autoremove
# sudo rm -rf /var/cuda-repo-ubuntu2204-12-9-local/
# sudo rm /etc/apt/sources.list.d/cuda-ubuntu2204-12-9-local.list
# sudo apt update
