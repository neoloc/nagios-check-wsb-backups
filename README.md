# Installation

## Client Side

1) Download the script

2) Edit the nsclient.ini file and add:

    [/settings/external scripts/scripts]
    check_shadowprotect_backup=cmd /c echo C:\Manage\Scripts\nagios-check-wsb-backups\check_wsb_backup.ps1; exit $LastExitCode | PowerShell.exe -Command -

3) Set your Powershell ExecutionPolicy to Remotesigned. Also note that there are two versions of powershell on a 64bit OS! Depending on the architecture of your NSClient++ version you have to choose the right one:

    64bit NSClient++ (installed under C:\Program Files ):
    %SystemRoot%\SysWOW64\WindowsPowerShell\v1.0\powershell.exe "Set-ExecutionPolicy RemoteSigned"

    32bit NSClient++ (installed under C:\Program Files (x86) ):
    %SystemRoot%\syswow64\WindowsPowerShell\v1.0\powershell.exe "Set-ExecutionPolicy RemoteSigned"

4) Restart the nsclient++ service

## Nagios Side

1) Connect to the monitor1 host internally. Refer to TeamPass for credentials.

2) Edit the '/etc/nagios3/clients/common-hostgroups.cfg' file.

    nano /etc/nagios3/clients/common-hostgroups.cfg

3) Search for 'parent-check-wsb-backups'

    inside nano, press CTRL+W and then paste the 'parent-check-wsb-backups' search string

4) Add the hosts/hostgroups that represent the servers you want to check to the 'parent-check-wsb-backups' hostgroup.

5) Save and exit the file.

    inside nano, CTRL+X to save and exit

6) Check the configuration syntax is OK.

    verifynagios

7) Restart nagios

    service nagios3 restart
