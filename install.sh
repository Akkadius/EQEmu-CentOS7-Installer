#!/bin/bash
echo "Please enter a new password for the eqemu user"
passwd eqemu
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
alias cp='cp'
yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum -y install deltarpm
yum -y install open-vm-tools vim tuned tuned cmake boost-* zlib-devel mariadb-server mariadb-client mariadb-devel mariadb-libs mariadb-compat perl-* lua* p7zip dos2unix
yum -y groupinstall "Development Tools"
yum -y groupinstall "Basic Web Server"
yum -y groupinstall "Compatibility Libraries"
yum -y remove *mpich*
tuned profile virtual-guest
echo "Starting MariaDB server..."
systemctl start mariadb.service
/usr/bin/mysqladmin -u root password 'eqemu'
mkdir /home/eqemu/server
mkdir /home/eqemu/source
cd /home/eqemu/source
git clone https://github.com/N0ctrnl/EQEmu-CentOS7-Install-Script.git Install
cd /home/eqemu/source/Install
7za e peqdb.7z -aoa
mysql -u root -peqemu < /home/eqemu/source/Install/db_prep.sql
mysql -u eqemu -peqemu peq < /home/eqemu/source/Install/peqbeta.sql
mysql -u eqemu -peqemu peq < /home/eqemu/player_tables.sql
git clone https://github.com/EQEmu/Server.git
cd /home/eqemu/source/Server
mkdir build
cd /home/eqemu/source/Server/build
cmake -G "Unix Makefiles" ..
echo "Building EQEmu Server code. This will take a while."
make
mkdir /home/eqemu/server/export
cp -a /home/eqemu/source/Server/build/bin/* /home/eqemu/server/
cp -a /home/eqemu/source/Server/utils/scripts/db_dumper.pl /home/eqemu/server
cp -a /home/eqemu/source/Server/utils/scripts/eqemu_update.pl /home/eqemu/server
cp -a /home/eqemu/source/Server/utils/defaults/* /home/eqemu/server
cp -a /home/eqemu/source/Install/_update.pl /home/eqemu/server
cp -a /home/eqemu/source/Install/emuserver /home/eqemu/server
rm -f /home/eqemu/server/plugins/*.pl
touch /home/eqemu/server/plugin.pl
chmod +x /home/eqemu/server/*.pl
chmod +x /home/eqemu/server/emuserver
/home/eqemu/server/_update.pl update
/home/eqemu/server/eqemu_update.pl firstrun ran_from_start
chown -R eqemu.eqemu /home/eqemu
