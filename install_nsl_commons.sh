#!/bin/sh
# install necrosato linux common packages and git setup with ssh keys

OSNAME=ubuntu #TODO: dont be dumb
ARG="$1"
if [ "$1" = "" ]; then ARG="-e"; fi

set -eux

install_packages() {
    PRIV_CMD="sudo"
    UPDATE_CMD="apt update -y"
    INSTALL_CMD="apt install -y"
    MINIMAL="
        git
        ranger
        rsync
        tig
        tmux
        vim
    "
    EXTRAS="
        ansible
        ansible-playbook
        docker.io
        docker
    "
    $PRIV_CMD $UPDATE_CMD
    $PRIV_CMD $INSTALL_CMD $MINIMAL
    if [ "$ARG" = "-e" ]; then
        $PRIV_CMD $INSTALL_CMD $EXTRAS
    fi
}

setup_defaults() {
    if [ "$(which update-alternatives)" != "" ]; then
        sudo update-alternatives --set editor /usr/bin/vim.basic
        sudo update-alternatives --set vi     /usr/bin/vim.basic
    fi
}

setup_git() {
    git config --global user.name  "necrosato"
    git config --global user.email "necrosato@live.com"
}

setup_ssh_keys() {
    cd $(mktemp -d)
    git clone https://github.com/necrosato/public-keys
    mkdir -p $HOME/.ssh
    cat public-keys/.ssh/authorized_keys >> $HOME/.ssh/authorized_keys
    rm -rf public-keys
}

setup_tailscale() {
    if [ "$(which tailscale)" = "" ]; then
         curl -fsSL https://tailscale.com/install.sh | sh
    fi
}

setup_nsl() {
    cd $(mktemp -d)
    git clone https://github.com/necrosato/nsl-setup
    cd nsl-setup
    rsync -aAXv common/ $HOME/
    rsync -aAXv $OSNAME/ $HOME/
}

main() {
    install_packages
    setup_defaults
    setup_git
    setup_ssh_keys
    setup_tailscale
    setup_nsl
}

main
