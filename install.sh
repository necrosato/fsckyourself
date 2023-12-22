#!/bin/sh
# install necrosato linux common packages and git setup with ssh keys

ARG="$1"
if [ "$1" = "" ]; then ARG="-e"; fi

set -eux

install_packages() {
    PRIV_CMD="sudo"
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
    APT_ONLY="
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
    if [ "$ARG" = "-e" ]; then
        $PRIV_CMD $INSTALL_CMD $EXTRAS
    fi
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

osname() {
    OSNAME=common
    if [ -e /etc/os-release ]; then
        OSNAME=$(cat /etc/os-release | grep "^ID=" | awk -F= '{print $2}')
    fi
}

setup_nsl() {
    OSNAME=$(osname)
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
