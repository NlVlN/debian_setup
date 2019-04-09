#!/bin/bash
# TODO: journalctl
# TODO: fail2ban

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" ;
    exit 1;
fi
ssh_port=22
username='foo'
echo "SSH will run on port $ssh_port
To change it stop script and adjust variable"
sleep 5

# BASICS
echo -e '\n\nUPDATE\n'
apt-get update
apt-get full-upgrade -y
apt-get install tmux htop vim mc neofetch dnsutils git curl -y

# DOCKER
echo -e '\n\nDOCKER\n'
sleep 3

apt-get install apt-transport-https ca-certificates gnupg2 software-properties-common -y
apt-get update
curl -fsSL https://download.docker.com/linux/debian/gpg |  apt-key add -
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"

apt-get update
apt-get install docker-ce docker-ce-cli containerd.io -y

# DOCKER COMPOSE
curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
curl -L https://raw.githubusercontent.com/docker/compose/1.24.0/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose

## DROPBOX
#echo -e '\n\nDROPBOX\n'
#sleep 3
#echo 'deb http://linux.dropbox.com/ubuntu xenial main' >> /etc/apt/source.list
#apt-key adv --keyserver pgp.mit.edu --recv-keys 1C61A2656FB57B7E4DE0F4C1FC918B335044912E
#apt-get install dropbox -y

# SSH SERVER
echo -e '\n\nSSH\n'
sleep 3
sed -i "s/#Port 22/Port ${ssh_port}/g" /etc/ssh/sshd_config
echo -e "KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256\nPubkeyAuthentication yes" >> /etc/ssh/sshd_config

# JOURNALCTL
echo -e '\n\nJOURNALCTL\n'
sed -i 's/#Storage=auto/Storage=persistent/' /etc/systemd/journald.conf

# IPTABLES
# basic iptables configuration from debian wiki
echo -e '\n\nIPTABLES\n'
sleep 3
echo "*filter

-P INPUT DROP
-P FORWARD DROP
-P OUTPUT ACCEPT

# Allows all loopback (lo0) traffic and drop all traffic to 127/8 that doesn't use lo0
-A INPUT -i lo -j ACCEPT
-A INPUT ! -i lo -d 127.0.0.0/8 -j REJECT

# Accepts all established inbound connections
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allows all outbound traffic
# You could modify this to only allow certain traffic
#-A OUTPUT -j ACCEPT

# Allows HTTP and HTTPS connections from anywhere (the normal ports for websites)
#-A INPUT -p tcp --dport 80 -j ACCEPT
#-A INPUT -p tcp --dport 443 -j ACCEPT

# Allows SSH connections
-A INPUT -p tcp -m state --state NEW --dport ${ssh_port} -j ACCEPT

# Allow ping
#  note that blocking other types of icmp packets is considered a bad idea by some
#  remove -m icmp --icmp-type 8 from this line to allow all kinds of icmp:
#  https://security.stackexchange.com/questions/22711
-A INPUT -p icmp -m icmp --icmp-type 0 -j ACCEPT
-A INPUT -p icmp -m icmp --icmp-type 3 -j ACCEPT
-A INPUT -p icmp -m icmp --icmp-type 5 -j ACCEPT
-A INPUT -p icmp -m icmp --icmp-type 8 -j ACCEPT
-A INPUT -p icmp -m icmp --icmp-type 11 -j ACCEPT

# log iptables denied calls (access via 'dmesg' command)
-A INPUT -m limit --limit 5/min -j LOG --log-prefix \"iptables denied: \" --log-level 7

# Reject all other inbound - default deny unless explicitly allowed policy:
#-A INPUT -j REJECT
#-A FORWARD -j REJECT

COMMIT" > /etc/iptables.test.rules
iptables-restore < /etc/iptables.test.rules
iptables-save > /etc/iptables.up.rules
echo -e '#!/bin/sh\n/sbin/iptables-restore < /etc/iptables.up.rules' > /etc/network/if-pre-up.d/iptables
chmod +x /etc/network/if-pre-up.d/iptables

# SUDO
read -p "Add user $username to sudo?[y/N] " -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
    adduser $username sudo
fi


# .BASHRC
echo -e '\n\n.BASHRC AND .TMUX\n'
sleep 3
echo "
#######################

alias ls='ls --color=auto'
alias l='ls -lA --color=auto'
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


secs=$((5))
while [ $secs -gt 0 ]; do
   echo -ne "rebooting in $secs\033[0K\r"
   sleep 1
   : $((secs--))
done
reboot
