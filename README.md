# EQEmu-CentOS7-Install-Script
This will install a new EQEmu installation on a minimal CentOS 7 installation. You can download an OVA (virtual machine image) of the CentOS install at https://mega.nz/#!soISAKRR!Xm6Zkm1ngOVas4U-le6G_K3Mv2PYuzpBMFVN9RKjlSk

## Running this script
- If using the OVA from the link above, there is a script called ```download-installer.sh``` in /root. This script will download the ```install.sh``` script which can then be run by doing ```chmod +x install.sh; ./install.sh``` or ```sh install.sh```
- To download the installer an another CentOS 7 installation, issue the followin: ```curl -O https://raw.githubusercontent.com/N0ctrnl/EQEmu-CentOS7-Install-Script/master/install.sh```

## Things to note
- The $EMUDIR variable will be the home directory for the eqemu user
- All passwords except the one specified for the eqemu user are set to 'eqemu' (This will be changed later)<br />
- The compiled server will not have bots and would need to be recompiled.<br />
- Likewise, the loginserver is not built.
- The emuserver script must be called from the $EMUDIR/server directory, and must be run as the eqemu user.

## Feedback
Please do let me know if you have suggestions or issues. This is a very early work in progress. While it works well for me, I haven't yet done extensive testing. I'm also very open to suggestions on trimming down the OS package list. The idea is to make this quick to deploy, so anything that works toward that goal is just fine by me.
