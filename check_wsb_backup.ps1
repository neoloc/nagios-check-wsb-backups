# Check eventlog for windows server backup errors or warnings
#
# This script will look at the application log for eventid 1121 and 1122, if any
# are found then the appropriate warn/crit message is returned to NAGIOS for
# further investigation.
#
# If no backups failures or aborts are found, and no successes are found then
# a warning or critical message will also be sent.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# Originally created by Ben Vincent (ben.vincent@oneitservices.com.au)
#
# Resources
#   Countless windows servers with backups. scouring eventlogs for what I need.
#   May be missing many event id's so add them if/when you find them.
#
# eventlog_id's
#  success
#   4 - The backup operation has finished successfully.
#
#  warnings
#   7 - The backup operation that started at 'datetime' has completed with errors. Please review the event details for a solution, and then rerun the backup operation once the issue is resolved.
#   51 - The backup storage location is running low on free space. Future backup operations that store backups on this location may fail because of not enough space.
#   146 - A volume included for backup is missing. This could be because the volume is dismounted, reformatted or disk is detached.
#
#  errors
#   5 - The backup operation that started at 'datetime' has failed with following error code '2147942455'. Please review the event details for a solution, and then rerun the backup operation once the issue is resolved.
#   9 - The backup operation that started at 'datetime' has failed because the Volume Shadow Copy Service operation to create a shadow copy of the volumes being backed up failed.
#   19 - The backup operation attempted at 'datetime' has failed to start, error code '2155348061'. Please review the event details for a solution, and then rerun the backup operation once the issue is resolved.
#   49 - The backup operation has failed because no backup storage location could be found. Please confirm that the backup storage location is attached and online, and then rerun the backup operation.


# nagios specific stuff
$NagiosStatus = "0"
$NagiosDescription = ""
$NagiosWarn_Hours = "48"
$NagiosCrit_Hours = "24"

# check if the host is Windows 2008r2/7 (Windows 6.1) or newer
If ([Environment]::OSVersion.Version -ge (new-object 'Version' 6,1))
{
  # get the event data for the local machine
  $FailEvents_General = Get-WinEvent -FilterHashtable @{logname="Microsoft-Windows-Backup"; id=5; providername='Microsoft-Windows-Backup'} -MaxEvents 10 -ErrorAction SilentlyContinue
  $FailEvents_VSSFailure = Get-WinEvent -FilterHashtable @{logname="Microsoft-Windows-Backup"; id=9; providername='Microsoft-Windows-Backup'} -MaxEvents 10 -ErrorAction SilentlyContinue
  $FailEvents_DidNotStart = Get-WinEvent -FilterHashtable @{logname="Microsoft-Windows-Backup"; id=19; providername='Microsoft-Windows-Backup'} -MaxEvents 10 -ErrorAction SilentlyContinue
  $FailEvents_NoBackupDest = Get-WinEvent -FilterHashtable @{logname="Microsoft-Windows-Backup"; id=49; providername='Microsoft-Windows-Backup'} -MaxEvents 10 -ErrorAction SilentlyContinue

  $WarnEvents_General = Get-WinEvent -FilterHashtable @{logname="Microsoft-Windows-Backup"; id=7; providername='Microsoft-Windows-Backup'} -MaxEvents 10 -ErrorAction SilentlyContinue
  $WarnEvents_LowSpace = Get-WinEvent -FilterHashtable @{logname="Microsoft-Windows-Backup"; id=51; providername='Microsoft-Windows-Backup'} -MaxEvents 10 -ErrorAction SilentlyContinue
  $WarnEvents_MissingVol = Get-WinEvent -FilterHashtable @{logname="Microsoft-Windows-Backup"; id=146; providername='Microsoft-Windows-Backup'} -MaxEvents 10 -ErrorAction SilentlyContinue

  $SuccessEvents = Get-WinEvent -FilterHashtable @{logname="Microsoft-Windows-Backup"; id=4; providername='Microsoft-Windows-Backup'} -MaxEvents 10 -ErrorAction SilentlyContinue
}
else
{
  # get the event data for the local machine. This is a slower method so change the maxevents to suit your environment.
  $FailEvents_General = Get-WinEvent -LogName Microsoft-Windows-Backup -MaxEvents 2000 | Where-Object{($_.ID -eq "5") -and ($_.ProviderName -eq "Microsoft-Windows-Backup")}
  $FailEvents_VSSFailure = Get-WinEvent -LogName Microsoft-Windows-Backup -MaxEvents 2000 | Where-Object{($_.ID -eq "9") -and ($_.ProviderName -eq "Microsoft-Windows-Backup")}
  $FailEvents_DidNotStart = Get-WinEvent -LogName Microsoft-Windows-Backup -MaxEvents 2000 | Where-Object{($_.ID -eq "19") -and ($_.ProviderName -eq "Microsoft-Windows-Backup")}
  $FailEvents_NoBackupDest = Get-WinEvent -LogName Microsoft-Windows-Backup -MaxEvents 2000 | Where-Object{($_.ID -eq "49") -and ($_.ProviderName -eq "Microsoft-Windows-Backup")}

  $WarnEvents_General = Get-WinEvent -LogName Microsoft-Windows-Backup -MaxEvents 2000 | Where-Object{($_.ID -eq "7") -and ($_.ProviderName -eq "Microsoft-Windows-Backup")}
  $WarnEvents_LowSpace = Get-WinEvent -LogName Microsoft-Windows-Backup -MaxEvents 2000 | Where-Object{($_.ID -eq "51") -and ($_.ProviderName -eq "Microsoft-Windows-Backup")}
  $WarnEvents_MissingVol = Get-WinEvent -LogName Microsoft-Windows-Backup -MaxEvents 2000 | Where-Object{($_.ID -eq "146") -and ($_.ProviderName -eq "Microsoft-Windows-Backup")}

  $SuccessEvents = Get-WinEvent -LogName Microsoft-Windows-Backup -MaxEvents 2000 | Where-Object{($_.ID -eq "4") -and ($_.ProviderName -eq "Microsoft-Windows-Backup")}
}

# check for critical alerts (failed within last $NagiosCrit_Hours hours)
Foreach ($event in $FailEvents_General)
{
  If ($((get-date).AddHours(-$NagiosCrit_Hours)) -lt $event.TimeCreated)
  {

    # check for more specific failure events (VSS Failure)
    Foreach ($event in $FailEvents_VSSFailure)
    {
      If ($((get-date).AddHours(-$NagiosCrit_Hours)) -lt $event.TimeCreated)
      {
        # Set the nagios alert description
        $NagiosDescription = "Backup failed in last " + $NagiosCrit_Hours + " hours. WSB failed to take a VSS snapshot."

        # Set the status to critical.
        $NagiosStatus = "2"

        # Output the nagios error text and then exit
        Write-Host "CRITICAL: " $NagiosDescription
        exit $NagiosStatus
      }
    }

    # check for more specific failure events (Backup did not start)
    Foreach ($event in $FailEvents_DidNotStart)
    {
      If ($((get-date).AddHours(-$NagiosCrit_Hours)) -lt $event.TimeCreated)
      {
        # Set the nagios alert description
        $NagiosDescription = "Backup failed in last " + $NagiosCrit_Hours + " hours. WSB failed to start backup job."

        # Set the status to critical.
        $NagiosStatus = "2"

        # Output the nagios error text and then exit
        Write-Host "CRITICAL: " $NagiosDescription
        exit $NagiosStatus
      }
    }

    # check for more specific failure events (No backup destination found)
    Foreach ($event in $FailEvents_NoBackupDest)
    {
      If ($((get-date).AddHours(-$NagiosCrit_Hours)) -lt $event.TimeCreated)
      {
        # Set the nagios alert description
        $NagiosDescription = "Backup failed in last " + $NagiosCrit_Hours + " hours. WSB failed to find backup destination device."

        # Set the status to critical.
        $NagiosStatus = "2"

        # Output the nagios error text and then exit
        Write-Host "CRITICAL: " $NagiosDescription
        exit $NagiosStatus
      }
    }

    # Set the nagios alert description, no specific error id found.
    $NagiosDescription = "Backup failed in last " + $NagiosCrit_Hours + " hours."

    # Set the status to critical.
    $NagiosStatus = "2"

    # Output the nagios error text and then exit
    Write-Host "CRITICAL: " $NagiosDescription
    exit $NagiosStatus
  }
}

# check for warnings alerts (warnings within last $NagiosCrit_Hours hours)
Foreach ($event in $WarnEvents_General)
{
  If ($((get-date).AddHours(-$NagiosCrit_Hours)) -lt $event.TimeCreated)
  {

    # check for more specific warning events (Low space on destination drive)
    Foreach ($event in $WarnEvents_LowSpace)
    {
      If ($((get-date).AddHours(-$NagiosCrit_Hours)) -lt $event.TimeCreated)
      {
        # Set the nagios alert description
        $NagiosDescription = "Backup warning in last " + $NagiosCrit_Hours + " hours. WSB reports low space on destination device."

        # Set the status to warning.
        $NagiosStatus = "1"

        # Output the nagios error text and then exit
        Write-Host "WARNING: " $NagiosDescription
        exit $NagiosStatus
      }
    }

    # check for more specific failure events (Missing source volume)
    Foreach ($event in $WarnEvents_MissingVol)
    {
      If ($((get-date).AddHours(-$NagiosCrit_Hours)) -lt $event.TimeCreated)
      {
        # Set the nagios alert description
        $NagiosDescription = "Backup warning in last " + $NagiosCrit_Hours + " hours. WSB reports missing source volume."

        # Set the status to warning.
        $NagiosStatus = "1"

        # Output the nagios error text and then exit
        Write-Host "WARNING: " $NagiosDescription
        exit $NagiosStatus
      }
    }

    # Set the nagios alert description, no specific error id found.
    $NagiosDescription = "Backup warning in last " + $NagiosCrit_Hours + " hours. Completed with errors."

    # Set the status to warning.
    $NagiosStatus = "1"

    # Output the nagios error text and then exit
    Write-Host "WARNING: " $NagiosDescription
    exit $NagiosStatus
  }
}

# check for warnings alerts (failures within last $NagiosWarn_Hours hours)
Foreach ($event in $FailEvents_General)
{
  If ($((get-date).AddHours(-$NagiosWarn_Hours)) -lt $event.TimeCreated)
  {

    # check for more specific failure events (VSS Failure)
    Foreach ($event in $FailEvents_VSSFailure)
    {
      If ($((get-date).AddHours(-$NagiosWarn_Hours)) -lt $event.TimeCreated)
      {
        # Set the nagios alert description
        $NagiosDescription = "Backup failed in last " + $NagiosWarn_Hours + " hours. WSB failed to take a VSS snapshot."

        # Set the status to warning.
        $NagiosStatus = "1"

        # Output the nagios error text and then exit
        Write-Host "WARNING: " $NagiosDescription
        exit $NagiosStatus
      }
    }

    # check for more specific failure events (Backup did not start)
    Foreach ($event in $FailEvents_DidNotStart)
    {
      If ($((get-date).AddHours(-$NagiosWarn_Hours)) -lt $event.TimeCreated)
      {
        # Set the nagios alert description
        $NagiosDescription = "Backup failed in last " + $NagiosWarn_Hours + " hours. WSB failed to start backup job."

        # Set the status to warning.
        $NagiosStatus = "1"

        # Output the nagios error text and then exit
        Write-Host "WARNING: " $NagiosDescription
        exit $NagiosStatus
      }
    }

    # check for more specific failure events (No backup destination found)
    Foreach ($event in $FailEvents_NoBackupDest)
    {
      If ($((get-date).AddHours(-$NagiosWarn_Hours)) -lt $event.TimeCreated)
      {
        # Set the nagios alert description
        $NagiosDescription = "Backup failed in last " + $NagiosWarn_Hours + " hours. WSB failed to find backup destination device."

        # Set the status to warning.
        $NagiosStatus = "1"

        # Output the nagios error text and then exit
        Write-Host "WARNING: " $NagiosDescription
        exit $NagiosStatus
      }
    }

    # Set the nagios alert description, no specific error id found.
    $NagiosDescription = "Backup failed in last " + $NagiosWarn_Hours + " hours."

    # Set the status to warning.
    $NagiosStatus = "1"

    # Output the nagios error text and then exit
    Write-Host "WARNING: " $NagiosDescription
    exit $NagiosStatus
  }
}


# check for successful backups within the last $NagiosCrit_Hours hours, report OK
Foreach ($event in $SuccessEvents)
{
  If ($((get-date).AddHours(-$NagiosCrit_Hours)) -lt $event.TimeCreated)
  {
    # Set the nagios alert description
    $NagiosDescription = "Backup success in last " + $NagiosWarn_Hours + " hours."

    # Set the status to successful.
    $NagiosStatus = "0"

    # Output the nagios error text and then exit
    Write-Host "OK: " $NagiosDescription
    exit $NagiosStatus

  }
}

# check for successful backups within the last $NagiosWARN_Hours hours, report WARN
Foreach ($event in $SuccessEvents)
{
  If ($((get-date).AddHours(-$NagiosWarn_Hours)) -lt $event.TimeCreated)
  {
    # Set the nagios alert description
    $NagiosDescription = "Backup success in last " + $NagiosWarn_Hours + " hours but not " + $NagiosCrit_Hours + " hours."

    # Set the status to warning.
    $NagiosStatus = "1"

    # Output the nagios error text and then exit
    Write-Host "WARNING: " $NagiosDescription
    exit $NagiosStatus

  }
}

# else if no failures, aborts or successes. Are backups even running?
If ($NagiosStatus -eq "0")
{
  # Set the nagios alert description
  $NagiosDescription = "WSB has no backup alerts in last " + $NagiosWarn_Hours + " hours."

  # Set the status to critical.
  $NagiosStatus = "2"

  # Output the nagios error text and then exit
  Write-Host "CRITICAL: " $NagiosDescription
  exit $NagiosStatus
}


# if you get to here, something went wrong. Report to nagios so we can debug.
Write-Host "UNKNOWN: Failed to check backup status"
exit 3
