#!/bin/bash
export EMUDIR=/home/eqemu
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
yum -y install open-vm-tools vim tuned tuned cmake boost-* zlib-devel mariadb-server mariadb-client mariadb-devel mariadb-libs mariadb-compat perl-* lua* p7zip dos2unix php-mysql
yum -y groupinstall "Development Tools" "Basic Web Server" "Compatibility Libraries"
tuned-adm profile virtual-guest
echo "Starting MariaDB server..."
systemctl start mariadb.service
/usr/bin/mysqladmin -u root password 'eqemu'
mkdir $EMUDIR/server
mkdir $EMUDIR/source
cd $EMUDIR/source
git clone https://github.com/N0ctrnl/EQEmu-CentOS7-Install-Script.git Install
cd $EMUDIR/source/Install
7za e peqdb.7z -aoa
mysql -u root -peqemu < $EMUDIR/source/Install/db_prep.sql
mysql -u eqemu -peqemu peq < $EMUDIR/source/Install/peqbeta.sql
mysql -u eqemu -peqemu peq < $EMUDIR/source/Install/player_tables.sql
cd $EMUDIR/source
git clone https://github.com/EQEmu/Server.git
cd $EMUDIR/source/Server
mkdir build
cd $EMUDIR/source/Server/build
cmake -G "Unix Makefiles" ..
echo "Building EQEmu Server code. This will take a while."
make
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
$EMUDIR/server/_update.pl firstrun ran_from_start
$EMUDIR/server/eqemu_update.pl update
chown -R eqemu.eqemu $EMUDIR
