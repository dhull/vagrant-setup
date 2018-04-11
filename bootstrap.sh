#! /bin/bash

# Vagrant runs this script inside the newly-created VM to customize it.

OSVER=$(perl -n -e 'm/release\s+(\d+)/ and print $1' /etc/redhat-release)

. /vagrant-setup/config

echo "Provisioning $1 from bootstrap.sh for $USERNAME"

# Create the user's account if it doesn't already exist.
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

# https://maven.openx.org/artifactory/releng/certs/megabundle.crt
(cd /etc/pki/tls/certs/; curl -k -O https://maven.openx.org/artifactory/releng/certs/megabundle.crt)
(cd /etc/pki/ca-trust/source/anchors; ln -s  ../../../tls/certs/megabundle.crt .)
/usr/bin/update-ca-trust

# https://maven.openx.org/artifactory/libs-release-local/openx-artifactory-repo-devtools-1.2.0-1.noarch.rpm
# https://maven.openx.org/artifactory/centos-7-local/release/x86_64/openx-artifactory-repo-released-1.5-1.x86_64.rpm
# https://maven.openx.org/artifactory/centos-7-local/release/x86_64/com/openx/releng/repos/openx-artifactory-released-centos-1.0-1.x86_64.rpm
yum install -y \
  /vagrant-setup/openx-artifactory-repo-devtools-1.2.0-1.noarch.rpm \
  /vagrant-setup/openx-artifactory-repo-released-1.5-1.x86_64.rpm

# # Install openx-codex-testing yum repo as first step so that the
# # second "yum install" will see it.
# yum install -y \
#   openx-codex-repo-testing

# Install core RPMs for demand development.
yum install -y --nogpgcheck \
  rpm-build \
  openx-devtools

# I don't want openx-devtools to turn requires of "perl(Module)" into "openx-perl(Module)".
rm -f /usr/bin/ox-perl-provide /usr/bin/ox-perl-require /etc/rpm/macros.ox-perl

case "$OSVER" in
    6) ERLANG_VERSION=18.3.4.7-4.4.7.1 ;;
    *) ERLANG_VERSION=18.3.4.7-4.8.5.1 ;;
esac
ox-install-dev -y -e $ERLANG_VERSION

# Install docker
if test "$OSVER" -ge 7; then
    yum install -y https://download.docker.com/linux/centos/7/x86_64/stable/Packages/docker-ce-17.12.1.ce-1.el7.centos.x86_64.rpm
    systemctl enable docker.service
    usermod -a -G docker $USERNAME
    systemctl start docker.service
fi

# Install google-cloud-sdk.
# https://cloud.google.com/sdk/downloads#yum
if test "$OSVER" -ge 7; then
    cp /vagrant-setup/google-cloud-sdk.repo /etc/yum.repos.d/
    yum install -y google-cloud-sdk
fi


# Create a dummy mondemand config.
mkdir -p /etc/mondemand
cat >/etc/mondemand/mondemand.conf <<EOF
MONDEMAND_ADDR="127.0.0.1"
MONDEMAND_PORT="20402"
EOF

# Create ox-simple-config (oxcon) directories.
mkdir -p /etc/ox/oxcon/{defaults,overrides,local}


# Construct the hostname for the VM.  It is derived from the "box"
# name (passed as the first command-line argument to this script) and
# the username we are constructing the VM for.
HOSTNAME=$(perl -e 'my @hn = map { my $s = lc($_); $s =~ s,^.*/,,; $s =~ s/[^a-z0-9]+//g; $s } @ARGV; print join("-", @hn);' "$1" "$USERNAME")

# Set hostname.
if egrep '^HOSTNAME=' /etc/sysconfig/network >/dev/null; then
    perl -i -p \
         -e 'BEGIN { $hn = shift; }' \
         -e 's/^HOSTNAME=\K.*/$hn/;' \
         "$HOSTNAME" /etc/sysconfig/network
fi
if test -f /etc/hostname; then
    echo "$HOSTNAME$DOMAINNAME" >/etc/hostname
fi
hostname "$HOSTNAME$DOMAINNAME"

# Symlink jq (https://stedolan.github.io/jq/) into $HOME/bin.  This is
# a statically linked Linux x86-64 executable.
mkdir -p /home/$USERNAME/bin
if ! test -e /home/$USERNAME/bin/jq; then
    ln -s /vagrant-setup/jq-linux /home/$USERNAME/bin/jq
fi

# Any files in /vagrant-setup/dotfiles (without the leading '.') will
# be symlinked into the user's home directory.
(
    cd /home/$USERNAME
    for F in /vagrant-setup/dotfiles/*; do
        L=.$(basename $F)
        rm -f $L
        ln -s $F $L
    done
)

# Run personal bootstrap if it exists.
if test -f /vagrant-setup/bootstrap-local.sh; then
    /vagrant-setup/bootstrap-local.sh "$USERNAME"
fi
