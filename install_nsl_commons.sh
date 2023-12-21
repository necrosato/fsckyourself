#!/bin/sh
# install necrosato linux common packages and git setup with ssh keys

ARG="$1"
if [ "$1" -e "" ]; then ARG="-e"; fi

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
    if [ "$ARG" -e "-e" ]; then
        $PRIV_CMD $INSTALL_CMD $EXTRAS
    fi
}

setup_defaults() {
    if [ "$(which update-alternatives)" -ne "" ]; then
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

main() {
    install_packages
    setup_defaults
    setup_git
    setup_ssh_keys
}

main
