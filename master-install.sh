#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [[ -f /etc/debian_version ]]; then
   export OS=DEB
elif [[ -f /etc/redhat-release ]]; then
   export OS=RHEL
else
   echo "This script must be run on a Debian or RedHat derivative"
   exit 1
fi

echo "#########################################################                         "
echo "#::: EverQuest Emulator Modular Installer                                         "
echo "#::: Installer Author: Akkadius                                                   "
echo "#:::                                                                              "
echo "#::: EQEmulator Server Software is developed and maintained                       "
echo "#:::	by the EQEmulator Developement team                                         "
echo "#:::                                                                              "
echo "#::: Everquest is a registered trademark                                          "
echo "#::: Daybreak Game Company LLC.                                                   "
echo "#:::                                                                              "
echo "#::: EQEmulator is not associated or                                              "
echo "#::: affiliated in any way with Daybreak Game Company LLC.                        "
echo "#########################################################                         "
echo "#:                                                                                "
echo "#########################################################                         "
echo "#::: To be installed:                                                             "
echo "#########################################################                         "
echo "- Server running folder - Will be installed to the folder you ran this script     "
echo "- MariaDB (MySQL) - Database engine                                               "
echo "- Perl 5.X :: Scripting language for quest engines                             "
echo "- LUA Configured :: Scripting language for quest engines                          "
echo "- Latest PEQ Database                                                             "
echo "- Latest PEQ Quests                                                               "
echo "- Latest Plugins repository                                                       "
echo "- Maps (Latest V2) formats are loaded                                             "
echo "- New Path files are loaded                                                       "
echo "- Optimized server binaries                                                       "
echo "#########################################################                         "

# Installation variables (Don't need to change, only for advanced users)

export eqemu_server_directory=/home/eqemu
export apt_options="-y -qq" # Set autoconfirm and silent install

################################################################

read -n1 -r -p "Press any key to continue..." key

#::: Setting up user environment (eqemu)
echo "First, we need to set your passwords..."
echo "Make sure that you remember these and keep them somewhere"
echo ""
echo ""
groupadd eqemu
useradd -g eqemu -d $eqemu_server_directory eqemu
passwd eqemu

#::: Make server directory and go to it
mkdir $eqemu_server_directory
cd $eqemu_server_directory

#::: Setup MySQL root user PW
read -p "Enter MySQL root (Database) password: " eqemu_db_root_password

#::: Write install variables (later use)
echo "mysql_root:$eqemu_db_root_password" > install_variables.txt

#::: Setup MySQL server 
read -p "Enter Database Name (single word, no special characters, lower case):" eqemu_db_name
read -p "Enter (Database) MySQL EQEmu Server username: " eqemu_db_username
read -p "Enter (Database) MySQL EQEmu Server password: " eqemu_db_password

#::: Write install variables (later use)
echo "mysql_eqemu_db_name:$eqemu_db_name" >> install_variables.txt
echo "mysql_eqemu_user:$eqemu_db_username" >> install_variables.txt
echo "mysql_eqemu_password:$eqemu_db_password" >> install_variables.txt

if [[ "$OS" == "DEB" ]]; then
# Install pre-req packages
apt-get $apt_options install bash
apt-get $apt_options install build-essential
apt-get $apt_options install cmake
apt-get $apt_options install cpp
apt-get $apt_options install curl
apt-get $apt_options install debconf-utils
apt-get $apt_options install g++
apt-get $apt_options install gcc
apt-get $apt_options install git
apt-get $apt_options install git-core
apt-get $apt_options install libio-stringy-perl
apt-get $apt_options install liblua5.1
apt-get $apt_options install liblua5.1-dev
apt-get $apt_options install libluabind-dev
apt-get $apt_options install libmysql++
apt-get $apt_options install libperl-dev
apt-get $apt_options install libperl5i-perl
apt-get $apt_options install libwtdbomysql-dev
apt-get $apt_options install lua5.1
apt-get $apt_options install make
apt-get $apt_options install mariadb-client
apt-get $apt_options install open-vm-tools
apt-get $apt_options install unzip
apt-get $apt_options install uuid-dev
apt-get $apt_options install zlib-bin
apt-get $apt_options install zlibc

#::: Install FTP for remote FTP access
echo "proftpd-basic shared/proftpd/inetd_or_standalone select standalone" | debconf-set-selections
apt-get -y -q install proftpd

#::: Install MariaDB Server
export DEBIAN_FRONTEND=noninteractive
debconf-set-selections <<< 'mariadb-server-10.0 mysql-server/root_password password PASS'
debconf-set-selections <<< 'mariadb-server-10.0 mysql-server/root_password_again password PASS'
apt-get install -y mariadb-server
mysql -uroot -pPASS -e "SET PASSWORD = PASSWORD('$eqemu_db_root_password');"

elif [[ "$OS" == "RHEL" ]]; then
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
yum -y install open-vm-tools vim tuned tuned cmake boost-* zlib-devel mariadb-server mariadb-client mariadb-devel mariadb-libs mariadb-compat perl-* lua* p7zip dos2unix php-mysql iptables-services proftpd
yum -y groupinstall "Development Tools" "Basic Web Server" "Compatibility Libraries"
# Set tuned profile
#tuned-adm profile virtual-guest
# Start MariaDB server and set root password
echo "Starting MariaDB server..."
systemctl start mariadb.service
sleep 5
/usr/bin/mysqladmin -u root password '$eqemu_db_root_password'
fi

#::: Configure game server database user
mysql -uroot -p$eqemu_db_root_password -e "CREATE USER '$eqemu_db_username'@'localhost' IDENTIFIED BY '$eqemu_db_password';"
mysql -uroot -p$eqemu_db_root_password -e "GRANT GRANT OPTION ON *.* TO '$eqemu_db_username'@'localhost';"
mysql -uroot -p$eqemu_db_root_password -e "GRANT ALL ON *.* TO '$eqemu_db_username'@'localhost';"

#::: Create source and server directories
mkdir $eqemu_server_directory/source
mkdir $eqemu_server_directory/server
mkdir $eqemu_server_directory/server/export
mkdir $eqemu_server_directory/server/logs
mkdir $eqemu_server_directory/server/shared
mkdir $eqemu_server_directory/server/maps

#::: Pull down needed files for the installer from the Install repo 

cd $eqemu_server_directory/source
git clone https://github.com/EQEmu/Server.git
mkdir $eqemu_server_directory/source/Server/build
cd $eqemu_server_directory/source/Server/build

echo "Generating CMake build files..."
cmake -DEQEMU_BUILD_LOGIN=ON -DEQEMU_BUILD_LUA=ON -G "Unix Makefiles" ..
echo "Building EQEmu Server code. This will take a while."

#::: Grab loginserver dependencies
cd $eqemu_server_directory/source/Server/dependencies
if [[ "$OS" == "DEB" ]]; then
  wget http://eqemu.github.io/downloads/ubuntu_LoginServerCrypto_x64.zip
  unzip ubuntu_LoginServerCrypto_x64.zip
  rm ubuntu_LoginServerCrypto_x64.zip
elif [[ "$OS" == "RHEL" ]]; then
  wget http://eqemu.github.io/downloads/fedora12_LoginServerCrypto_x64.zip
  unzip fedora12_LoginServerCrypto_x64.zip
  rm fedora12_LoginServerCrypto_x64.zip
fi
cd $eqemu_server_directory/source/Server/build

#::: Build
make

#::: Back to server directory
cd $eqemu_server_directory/server
wget https://dl.dropboxusercontent.com/u/50023467/dl/eqemu/eqemu_server.pl

#::: Link build files

cd $eqemu_server_directory/server

#::: Map lowercase to uppercase to avoid issues
ln -s maps Maps

ln -s $eqemu_server_directory/source/Server/build/bin/loginserver loginserver
ln -s $eqemu_server_directory/source/Server/build/bin/eqlaunch eqlaunch 
ln -s $eqemu_server_directory/source/Server/build/bin/export_client_files export_client_files 
ln -s $eqemu_server_directory/source/Server/build/bin/import_client_files import_client_files 
ln -s $eqemu_server_directory/source/Server/build/bin/libcommon.a libcommon.a 
ln -s $eqemu_server_directory/source/Server/build/bin/libluabind.a libluabind.a 
ln -s $eqemu_server_directory/source/Server/build/bin/queryserv queryserv 
ln -s $eqemu_server_directory/source/Server/build/bin/shared_memory shared_memory 
ln -s $eqemu_server_directory/source/Server/build/bin/ucs ucs 
ln -s $eqemu_server_directory/source/Server/build/bin/world world 
ln -s $eqemu_server_directory/source/Server/build/bin/zone zone 

#::: Notes

perl $eqemu_server_directory/server/eqemu_server.pl installer

#::: Chown files
chown eqemu:eqemu $eqemu_server_directory/ -R 
chmod 755 $eqemu_server_directory/server/*.pl
chmod 755 $eqemu_server_directory/server/*.sh
