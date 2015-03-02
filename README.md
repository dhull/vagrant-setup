This project contains scripts to configure CentOS instances under
Vagrant for demand team development.  The goal is to capture as much
of the per-user customization as possible so that that a new throwaway
VM instance can be easily created to do some development, and then
destroyed when the developement is done.

Old VirtualBox versions will not work with these Vagrantfile.  I know
that VirtualBox 4.3.20-96996 and later works.

1. Edit `setup/config`.  This will control the user setup in the new instance.
2. Run `./mk-setup`.  This creates a personalized tar file that will be used to populate your account in the new instance.
3. cd into the directory for the OS version you want to create an instance for and run `vagrant up`.

