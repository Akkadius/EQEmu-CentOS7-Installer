# EQEmu-CentOS7-Install-Script
This will install a new EQEmu installation on a minimal CentOS 7 installation. You can download an OVA (virtual machine image) of the CentOS install at https://mega.nz/#!soISAKRR!Xm6Zkm1ngOVas4U-le6G_K3Mv2PYuzpBMFVN9RKjlSk

## Things to note
- The $EMUDIR variable will be the home directory for the eqemu user
- All passwords except the one specified for the eqemu user are set to 'eqemu' (This will be changed later)<br />
- The compiled server will not have bots and would need to be recompiled.<br />
- Likewise, the loginserver is not built.
- The emuserver script must be called from the $EMUDIR/server directory, and must be run as the eqemu user.

