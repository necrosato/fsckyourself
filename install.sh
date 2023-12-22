#!/bin/sh
# install necrosato linux common packages and git setup with ssh keys

ARG="$1"
if [ "$1" = "" ]; then ARG="-e"; fi

set -eux

install_packages() {
    PRIV_CMD="sudo"
    if [ "$(which yum)" != "" ]; then
        UPDATE_CMD="yum update"
        INSTALL_CMD="yum install"
    elif [ "$(which apt-get)" != "" ]; then
        UPDATE_CMD="apt-get update -y"
        INSTALL_CMD="apt-get install -y"
    fi
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
    OSNAME=common
    if [ -e /etc/os-release ]; then
        OSNAME=$(cat /etc/os-release | grep "^ID=" | awk -F= '{print $2}')
    fi
    cd $(mktemp -d)
    git clone https://github.com/necrosato/fsckyourself
    cd fsckyourself/home/
    rsync -aAXv common/ $HOME/
    if [ -d $OSNAME ]; then
        rsync -aAXv $OSNAME/ $HOME/
    fi
    HOSTNAME_LOWER=$(hostname | awk '{print tolower($0)}')
    if [ -d $HOSTNAME_LOWER ]; then
        rsync -aAXv $HOSTNAME_LOWER/ $HOME/
    fi
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
