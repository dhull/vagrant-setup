#! /bin/bash

# Vagrant runs this script inside the newly-created VM to customize it.

. /vagrant-setup/config

set -x

echo "Provisioning from bootstrap.sh"
if ! egrep "^$USERNAME:" /etc/passwd; then
    useradd "${USERADD_EXTRA[@]}" $USERNAME
    (su $USERNAME -c 'cd $HOME && tar xzf /vagrant-setup/userhome.tar.gz')
fi

if ! test -e /home/$USERNAME/setenv-fw; then
    ln -s /vagrant-setup/setenv-fw /home/$USERNAME
fi

# Let $USER use sudo without a password
USERNAME_DOTLESS=$(echo $USERNAME | tr -d '.~')
echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/user-$USERNAME_DOTLESS
chmod 0440 /etc/sudoers.d/user-$USERNAME_DOTLESS

# basic delivery dev setup
yum install -y \
  zsh \
  erlang-R15B-03.1 \
  framewerk \
  fw-template-cxx \
  fw-template-erlang-rebar \
  fw-template-opt-maven-rpm \
  fw-template-java-mvn \
  fw-template-c \
  fw-template-erlang \
  git \
  gitflow \
  rpm-build \
  ox-map-hosts \
  openx-codex-repo-testing

