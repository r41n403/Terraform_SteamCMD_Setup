#!/bin/bash
dnf update -y
#create steam user, replace example password with desired password
useradd -p $(openssl passwd -1 examplepassword) steam
#install steam cmd dependencies
yum install glibc.i686 libstdc++.i686 -y
#switch to steam user, make steam dir, get files, and extract to steam dir
sudo -iu steam bash << EOF
mkdir ~/Steam
cd ~/Steam
wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz -P ~/Steam
tar -xzvf ~/Steam/steamcmd_linux.tar.gz
EOF


