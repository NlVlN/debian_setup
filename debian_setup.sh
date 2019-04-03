#!/bin/bash
ssh_port=5739

# BASICS
apt-get update
apt-get full-upgrade -y
apt-get install tmux htop vim mc neofetch dnsutils git curl -y

# DOCKER
curl -fsSL https://download.docker.com/linux/debian/gpg |  apt-key add -
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"

apt-get update
apt-get install apt-transport-https ca-certificates gnupg2 software-properties-common -y
apt-get install docker-ce docker-ce-cli containerd.io 

## DROPBOX
#echo 'deb http://linux.dropbox.com/ubuntu xenial main' >> /etc/apt/source.list
#apt-key adv --keyserver pgp.mit.edu --recv-keys 1C61A2656FB57B7E4DE0F4C1FC918B335044912E
#apt-get install dropbox -y

# SSH
sed -i "s/#Port 22/Port ${ssh_port}/g" /etc/ssh/sshd_config
echo -e "KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256\nPubkeyAuthentication yes" >> /etc/ssh/sshd_config

# .BASHRC
echo "#######################


export LS_OPTIONS='--color=auto'
alias ls='ls $LS_OPTIONS'
alias l='ls $LS_OPTIONS -lA'
alias mc='mc -b'
alias grep='grep --color=auto'
if [ -f /usr/share/bash-completion/bash_completion ]; then
       	. /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
       	. /etc/bash_completion
fi


#######################" >> /etc/bash.bashrc

# .TMUX
echo "bind a set synchronize-panes off
bind s set synchronize-panes on" >> ~/.tmux.conf


echo "Rebooting in: 3"
sleep 1
echo "2"
sleep 1
echo "1"
sleep 1
reboot
