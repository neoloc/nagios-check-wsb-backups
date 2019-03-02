# Installation

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
