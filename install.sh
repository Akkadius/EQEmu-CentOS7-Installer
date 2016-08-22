#!/bin/bash
# Base directory to hold source/server files. Also serves as the eqemu user's home directory
export EMUDIR=/home/eqemu
# Add the eqemu user/group
groupadd -g 1000 eqemu
useradd -g 1000 -u 1000 -d $EMUDIR eqemu
# Set a password for the eqemu user
echo "Please enter a new password for the eqemu user"
passwd eqemu
# Add the MariaDB repository to yum
cat <<EOF > /etc/yum.repos.d/mariadb.repo
# MariaDB 10.1 CentOS repository list - created 2016-08-20 05:42 UTC
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.1/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
enabled=1
gpgcheck=1
EOF
# Remove the extra CentOS options for the cp command
alias cp='cp'
# Disable firewalld service since we will be installing and using iptables
systemctl stop firewalld
systemctl mask firewalld
# Install prereqs
yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum -y install deltarpm
yum -y install open-vm-tools vim tuned tuned cmake boost-* zlib-devel mariadb-server mariadb-client mariadb-devel mariadb-libs mariadb-compat perl-* lua* p7zip dos2unix php-mysql iptables-services
yum -y groupinstall "Development Tools" "Basic Web Server" "Compatibility Libraries"
# Enable iptables service and start firewall
systemctl enable iptables
iptables-restore /home/eqemu/source/Install/iptables.eqemu
service iptables save
service iptables restart
# Set tuned profile
tuned-adm profile virtual-guest
# Start MariaDB server and set root password
echo "Starting MariaDB server..."
systemctl start mariadb.service
sleep 5
/usr/bin/mysqladmin -u root password 'eqemu'
# Create source and server directories
mkdir $EMUDIR/server
mkdir $EMUDIR/source
# Pull down needed files for the installer from the Install repo
cd $EMUDIR/source
git clone https://github.com/N0ctrnl/EQEmu-CentOS7-Install-Script.git Install
# Unpack and source in PEQ database. Currently the 8-19-2016 release
cd $EMUDIR/source/Install
7za e peqdb.7z -aoa
mysql -u root -peqemu < $EMUDIR/source/Install/db_prep.sql
mysql -u eqemu -peqemu peq < $EMUDIR/source/Install/peqbeta.sql
mysql -u eqemu -peqemu peq < $EMUDIR/source/Install/player_tables.sql
# Checkout and build EQEmu Server source
cd $EMUDIR/source
git clone https://github.com/EQEmu/Server.git
cd $EMUDIR/source/Server
mkdir build
cd $EMUDIR/source/Server/build
cmake -G "Unix Makefiles" ..
echo "Building EQEmu Server code. This will take a while."
make
# Create server directories and copy needed files
mkdir $EMUDIR/server/export
cp -a $EMUDIR/source/Server/build/bin/* $EMUDIR/server/
cp -a $EMUDIR/source/Server/utils/scripts/db_dumper.pl $EMUDIR/server
cp -a $EMUDIR/source/Server/utils/scripts/eqemu_update.pl $EMUDIR/server
cp -a $EMUDIR/source/Server/utils/defaults/* $EMUDIR/server
cp -a $EMUDIR/source/Install/_update.pl $EMUDIR/server
cp -a $EMUDIR/source/Install/emuserver $EMUDIR/server
cp -a $EMUDIR/source/Install/eqemu_config.xml $EMUDIR/server
rm -f $EMUDIR/server/plugins/*.pl
touch $EMUDIR/server/plugin.pl
cd $EMUDIR/server
chmod +x $EMUDIR/server/*.pl
chmod +x $EMUDIR/server/emuserver
# Run modified updater and update official one
$EMUDIR/server/_update.pl firstrun ran_from_start
# We're done. Let's change the ownership to the eqemu user
chown -R eqemu.eqemu $EMUDIR
echo "Congratulations! If you saw no errors, your installation is complete."
echo "Please logout of the root user account and login as 'eqemu' with the password you set."
echo "Running the 'emuserver' script from the server directory will give you options on starting/stopping/restarting the server."
echo "Please see www.eqemulator.org for support and other information on running your server."
