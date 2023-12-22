#!/bin/sh
# install necrosato linux common packages and git setup with ssh keys

set -eux

GITHUB_USER="necrosato"
GITHUB_EMAIL="necrosato@live.com"

install_packages() {
    PRIV_CMD="sudo"
    MINIMAL="
        git
        rsync
        tig
        tmux
        vim
    "
    EXTRAS="
        ansible
        docker
    "
    APT_ONLY="
        ranger
        docker.io
    "
    YUM_ONLY="
    "
    if [ "$(which apt-get)" != "" ]; then
        UPDATE_CMD="apt-get update -y"
        INSTALL_CMD="apt-get install -y"
        ONLY=$APT_ONLY
    elif [ "$(which yum)" != "" ]; then
        UPDATE_CMD="yum -y update"
        INSTALL_CMD="yum -y install"
        ONLY=$YUM_ONLY
    fi

    $PRIV_CMD $UPDATE_CMD
    $PRIV_CMD $INSTALL_CMD $ONLY $MINIMAL
    $PRIV_CMD $INSTALL_CMD $EXTRAS
}

setup_defaults() {
    if [ -e /etc/os-release ]; then
        OSBASE=$(cat /etc/os-release | grep "^ID_LIKE=" | awk -F= '{print $2}')
        if [ "$OSBASE" = "debian" ]; then
            sudo update-alternatives --set editor /usr/bin/vim.basic
            sudo update-alternatives --set vi     /usr/bin/vim.basic
        fi
    fi
}

setup_git() {
    git config --global user.name  "$GITHUB_USER"
    git config --global user.email "$GITHUB_EMAIL"
}

setup_ssh_keys() {
    cd $(mktemp -d)
    git clone https://github.com/$GITHUB_USER/public-keys
    mkdir -p $HOME/.ssh
    cat public-keys/.ssh/authorized_keys >> $HOME/.ssh/authorized_keys
    rm -rf public-keys
}

setup_tailscale() {
    if [ "$(which tailscale)" = "" ]; then
         curl -fsSL https://tailscale.com/install.sh | sh
    fi
}

osname() {
    if [ -e /etc/os-release ]; then
        echo $(cat /etc/os-release | grep "^ID=" | awk -F= '{print $2}')
    fi
}

setup_homedir() {
    cd $(mktemp -d)
    git clone https://github.com/$GITHUB_USER/fsckyourself
    SRC=fsckyourself/home/
    OSDIR="./$SRC/$(osname)"
    HOSTDIR="$SRC/$(hostname | awk '{print tolower($0)}')"
    USERDIR="$SRC/$USER"
    rsync -aAXv $SRC/common/ $HOME/
    if [ -d $OSDIR ]; then
        rsync -aAXv $OSDIR/ $HOME/
    fi
    if [ -d $HOSTDIR ]; then
        rsync -aAXv $HOSTDIR/ $HOME/
    fi
    if [ -d $USERDIR ]; then
        rsync -aAXv $USERDIR/ $HOME/
    fi
}

main() {
    install_packages
    setup_defaults
    setup_git
    setup_ssh_keys
    setup_tailscale
    setup_homedir
}

main
