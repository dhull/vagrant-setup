#! /bin/bash

# Vagrant runs this script inside the newly-created VM to customize it.

HOSTNAME=$(perl -e '$hn = lc(shift); $hn =~ s/[^a-z0-9]+/-/g; print $hn;' "$1")

. /vagrant-setup/config

echo "Provisioning from bootstrap.sh"

# Set hostname.
if egrep '^HOSTNAME=' /etc/sysconfig/network; then
    perl -i -p \
         -e 'BEGIN { $hn = shift; }' \
         -e 's/^HOSTNAME=\K.*/$hn/;' \
         "$HOSTNAME" /etc/sysconfig/network
fi
if test -f /etc/hostname; then
    echo "$HOSTNAME" >/etc/hostname
fi
hostname "$HOSTNAME"

# Create the user if he doesn't already exist.
if ! egrep "^$USERNAME:" /etc/passwd >/dev/null; then
    echo "Creating user $USERNAME"
    useradd "${USERADD_EXTRA[@]}" $USERNAME
    (su $USERNAME -c 'cd $HOME && tar xzf /vagrant-setup/userhome.tar.gz')
fi

# Link the framewerk setup script if it doesn't already exist.
if ! test -e /home/$USERNAME/setenv-fw; then
    ln -s /vagrant-setup/setenv-fw /home/$USERNAME
fi

# Set up sudo for user.
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

