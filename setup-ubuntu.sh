#!/bin/bash

# local timezone
__timezone="America/Los_Angeles"


# ask the user a question
function ask_user(){
  local __msg=$1
  zenity --question --text "$__msg"
}

# notify and wait for user confirmation before continuing
function ask_to_proceed(){
  local __msg=$1
  ask_user "$__msg"

  if [ "0" -ne "$?" ]; then
    ask_to_proceed "$__msg"
  fi
}


###################################################################################
## BEGIN DESKTOP DRIVER MODS 
###################################################################################

# install nvidia driver
sudo add-apt-repository ppa:graphics-drivers/ppa
sudo apt-get update
sudo apt-get install --assume-yes nvidia358


# update wifi driver options
echo "options iwlwifi 11n_disable=1" | sudo tee /etc/modprobe.d/iwlwifi.conf
echo "options rtl8723be fwlps=N ips=N" | sudo tee /etc/modprobe.d/rtl8723be.conf
sudo modprobe -rfv iwldvm
sudo modprobe -rfv iwlwifi
sudo modprobe -v iwlwifi


# set wireless region
sudo iw reg set US
sudo sed -i 's/^REG.*=$/&US/' /etc/default/crda


# update grub use of nvidia and pci power management
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash i915.modeset=1 pcie_aspm=off"/g' /etc/default/grub
sudo grub-mkconfig
sudo update-grub2

###################################################################################
## END DESKTOP DRIVER MODS 
###################################################################################


# setup system
sudo add-apt-repository -y ppa:nemh/systemback
sudo apt-get update
sudo apt-get install --assume-yes git \
                                  vim \
                                  realpath \
                                  file \
                                  zenity \
                                  htop \
                                  mysql-client \
                                  xauth


## configure timezone
sudo sh -c "echo '$__timezome' > /etc/timezone"
sudo dpkg-reconfigure --frontend noninteractive tzdata
sudo service cron restart


# setup ssh access
rm $HOME/.ssh/id_rsa $HOME/.ssh/id_rsa.pub
ssh-keygen -t rsa -N "" -f $HOME/.ssh/id_rsa
__pubkey=$(cat $HOME/.ssh/id_rsa.pub)


# copy public key to bitbucket account
ask_to_proceed "Have you copied your public key to bitbucket?\n$__pubkey"


# install host
mkdir --parents $HOME/dev
cd $HOME/dev
git clone git@bitbucket.org:kfoss/setup-ubuntu.git
pushd setup-ubuntu
    source install_variables_possible_desktop.sh
    sudo --preserve-env ./install_noprompt.sh
popd


# finalize environment
source ~/.bashrc


# cleanup
sudo apt-get install -f
sudo apt-get autoremove
sudo apt-get autoclean
