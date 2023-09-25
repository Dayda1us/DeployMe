#####################################################################################
#                                                                                   #
#                  WINDOWS AUTO UPDATE SCRIPT (RELEASE CANDIDATE 2)                 #
#                                                                                   #
#       Leverages Microsoft Update provider to install all missing updates          #
#       using the PSWindowsUpdate module. THIS RC RELEASE MAY                       #
#       CONTAIN UNEXPECTED RESULTS. USE AT YOUR OWN RISK!                           #
#                                                                                   #
#                           Developed by Charles Thai                               #
#####################################################################################

<#

RC1 CHANGELOGS:

NEW:


REVISIONS:
1. Split the codes into group of functions for easier maintenance.
2. Minor revisions on output messages.


BUGFIXES:
1. Fixed an issue on Reboot_module function where it displays the Get-Module twice.

#>

# This script must be started with elevated user rights.
#Requires -RunAsAdministrator

$newline = Write-Output "`n"

# This prerequisite check requires Windows PowerShell V5. This function will not work on later versions.
Write-Output "Checking for Internet connectivity...."
Start-sleep 5
while ((Test-Connection 3rtechnology.com -Count 1 -ErrorAction SilentlyContinue).ResponseTime -lt 0) {
    Write-Host "No Internet connection. Please double check your network configuration. Retrying..." -ForegroundColor Red
    start-sleep -seconds 5
}

Write-Host "Internet connection established! Initializing script..." -ForegroundColor Green
Start-sleep -Seconds 5
Clear-Host

##########################
#   MODIFYING SETTINGS   #
##########################

# Setting the process execution policy to Bypass
function exec_policy { 
    Write-Output "Setting the Process Execution Policy to Bypass."
    start-sleep -seconds 2
    $Execution_Policy = Get-ExecutionPolicy -Scope Process
    if ($Execution_Policy -contains "Bypass") {
        Write-Output "Process Execution Policy is already set to Bypass."
        Get-ExecutionPolicy -List
    } else {
        Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
        Write-Output "Process Execution Policy set to Bypass."
        Get-ExecutionPolicy -List
    }
    $newline
}

# Checks if NuGet is installed on the computer.
function nuget_check {
    Write-Output "Checking if NuGet is installed on your computer..."
    $nuget = (Get-PackageProvider |  Where-Object {$_.name -eq "Nuget"}).name -contains "NuGet"
    Start-Sleep -Seconds 3
    if ($nuget -eq $true) {
        Write-Output "NuGet is already installed! Importing NuGet..."
        start-sleep -seconds 3
        Import-PackageProvider -name Nuget
        $newline
        Write-Output "NuGet Imported!"
        start-sleep -Seconds 3
    } else {
        Write-Output "NuGet not installed. Installing NuGet..."
        start-sleep -Seconds 3
        Install-PackageProvider -name NuGet -Force -ForceBootstrap
        $newline
        Write-Output "Installed NuGet. Importing NuGet..."
        start-sleep -Seconds 3
        Import-PackageProvider -name Nuget
        Write-Output "Nuget Imported!"
        start-sleep -Seconds 3
    } 
    Get-PackageProvider -name NuGet
    $newline
}

# Update the PSGallery (Default) repository to trusted to ensure the installed modules work properly.
function psgallery_trust {
    Write-Output "Updating the PSGallery installation policy to Trusted"
    Start-Sleep -Seconds 2
    $Install_Policy = (Get-PSRepository | Where-Object {$_.InstallationPolicy -contains "Trusted"}).InstallationPolicy
    if ($Install_Policy -eq "Trusted") {
        Write-Output "Installation Policy is already set to Trusted."
        Get-PSRepository -Name PSGallery | Format-List Name,SourceLocation,Trusted,Registered,InstallationPolicy
        start-sleep -Seconds 3
    } else {
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        Write-Output "Installation set to Trusted."
        Get-PSRepository -Name PSGallery | Format-List Name,SourceLocation,Trusted,Registered,InstallationPolicy
        start-sleep -Seconds 3
    } 
}

###########################
#  INSTALL REQ'D MODULES  #
###########################

# Check if PSWindowsUpdate module is installed.
function PSWinUpdate {
    Write-Output "Checking if PSWindowsUpdate is already installed..."
    if ((Get-InstalledModule -Name PSWindowsUpdate -ErrorAction SilentlyContinue).name -contains "PSWindowsUpdate" -eq $false) {
        Write-Output "PSWindowsUpdate module not installed. Installing PSWindowsUpdate..."
        Install-Module -name PSWindowsUpdate -Force
        start-sleep -Seconds 2
        Write-Output "PSWindowsUpdate installed. Importing PSWindowsUpdate..."
        start-sleep -Seconds 2
        Import-Module -name PSWindowsUpdate
    } else {
        Write-Output "PSWindowsUpdate module is already installed! Importing PSWindowsUpdate..."
        start-sleep -Seconds 2
        Import-Module -name PSWindowsUpdate
    } 
    Write-Output "Import complete!"
    $newline
    Get-Module
    Start-Sleep -Seconds 5
}

# Check if PendingReboot module is installed.
function reboot_module {
    Write-Output "Checking if PendingReboot is already installed..."
    if ((Get-InstalledModule -Name PendingReboot).name -contains "PendingReboot" -eq $false) {
        Write-Output "PendingReboot module not installed. Installing PendingReboot..."
        Install-Module -name PendingReboot -Force
        start-sleep -Seconds 2
        Write-Output "PendingReboot installed. Importing PendingReboot..."
        start-sleep -Seconds 2
        Import-Module -name PendingReboot
        Get-Module
    } else {
        Write-Output "PendingReboot module is already installed. Importing PendingReboot..."
        start-sleep -Seconds 2
        Import-Module -name PendingReboot
        Write-Output "Import complete!"
        $newline
        Get-Module
        Start-Sleep -Seconds 5
    }
}


###########################
# STAGE 1: DRIVER UPDATES #
###########################
function drivers_update {
    Write-Output "CHECKING FOR DRIVER UPDATES"
    Get-WUList -MicrosoftUpdate -UpdateType Driver -AcceptAll -Download -Install -IgnoreReboot
    Write-Output "Checking for installed updates (if any) that require a reboot..."
    Start-Sleep -Seconds 10
    if ((Test-PendingReboot -SkipConfigurationManagerClientCheck).IsRebootPending -eq $false) {
        Write-Host "Drivers are up to date" -ForegroundColor Green
        start-sleep -Seconds 5
    } else {
        Write-Output "One or more updates requires a reboot. Rebooting..."
        Start-sleep -Seconds 5
        Restart-Computer -Force
        break
    }
    Clear-Host
}

#############################
# STAGE 2: SOFTWARE UPDATES #
#############################
function software_update {
    Write-Output "CHECKING FOR SOFTWARE UPDATES"
    Get-WUList -MicrosoftUpdate -UpdateType Software -AcceptAll -Download -Install -IgnoreReboot
    Write-Output "Checking for installed updates (if any) that require a reboot..."
    Start-Sleep -Seconds 10
    if ((Test-PendingReboot -SkipConfigurationManagerClientCheck).IsRebootPending -eq $false) {
        Write-Host "Software is up to date" -ForegroundColor Green
        start-sleep -Seconds 5
    } else {
        Write-Output "One or more updates requires a reboot. Rebooting..."
        Start-sleep -Seconds 2
        Restart-Computer -Force
        break
    }
    Clear-Host
}

##############################
#  STAGE 3: WINDOWS UPDATES  #
##############################
function windows_update {
    Write-Output "CHECKING FOR WINDOWS UPDATES"
    Get-WUList -WindowsUpdate -AcceptAll -Download -Install -IgnoreReboot
    Write-Output "Checking for installed updates (if any) that require a reboot..."
    Start-Sleep -Seconds 10
    if ((Test-PendingReboot -SkipConfigurationManagerClientCheck).IsRebootPending -eq $false) {
        Write-Host "Windows is up to date" -ForegroundColor Green
        start-sleep -Seconds 5
    } else {
        Write-Output "One or more updates requires a reboot. Rebooting..."
        Start-sleep -Seconds 2
        Restart-Computer -Force
        break
    }
    Clear-Host
}


##############################
#      REVERT SETTINGS       #
##############################

# Removing the installed modules.
function module_remove {
    # PSWindowsUpdate
    Write-Output "Removing the PSWindowsUpdate module..."
    start-sleep -Seconds 2
    "PSWindowsUpdate" | Remove-Module
    Write-Host "Module sucessfully removed" -ForegroundColor Green
    start-sleep -Seconds 1
    Get-Module
    start-sleep -Seconds 2

    $newline

    # PendingReboot
    Write-Output "Removing the PendingReboot module..."
    start-sleep -Seconds 2
    "PendingReboot" | Remove-Module
    Write-Host "Module sucessfully removed" -ForegroundColor Green
    start-sleep -Seconds 1
    Get-Module
    start-sleep -Seconds 2

    $newline
}

# Revert default Installation Policy to Untrusted
function psgallery_revert {
    Write-Output "Reverting PSGallery Installation Policy to Untrusted..."
    start-sleep -Seconds 2
    Set-PSRepository -Name PSGallery -InstallationPolicy Untrusted
    $Install_Policy = (Get-PSRepository | Where-Object {$_.InstallationPolicy -contains "Untrusted"}).InstallationPolicy
    if ($Install_Policy -contains "Untrusted") {
        Write-Output "Installation Policy set to Untrusted."
        Get-PSRepository -Name PSGallery | Format-List Name,SourceLocation,Trusted,Registered,InstallationPolicy
        start-sleep -Seconds 3
    }
}

# Revert Execution Policy to Undefined
function revert_expolicy {
    Write-Output "Setting the execution policy to Undefined..."
    start-sleep -Seconds 2
    Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope Process -Force
    $Execution_Policy = Get-ExecutionPolicy -Scope Process
    if ($Execution_Policy -contains "Undefined") {
        Write-Output "Execution Policy set back to Undefined."
        Get-ExecutionPolicy -List
        start-sleep -Seconds 3
    }
    Clear-Host    
}

# Checks if Sysprep is already opened
function sysprep_check {
    $check_sysprep = "sysprep"
    if ((Get-Process $check_sysprep -ErrorAction SilentlyContinue).ProcessName -contains "sysprep") {
        Write-Output "Terminiating Sysprep..."
        Start-sleep -Seconds 3
        Stop-Process -ProcessName $check_sysprep
    } else {
        Write-Output "Sysprep is not opened."
    }
}

# Deploy Sysprep and delete the script.
function deploy {
    Write-Output "Preparing Sysprep..."
    Start-sleep 5
    Set-Location $env:SystemRoot\System32\Sysprep
    .\sysprep.exe /oobe
    shutdown.exe /s /t 05
}

# Delete the script.
function delete {
    Write-Output "Script complete! This script will self-destruct in 3 seconds."
    3..1 | ForEach-Object {
        If ($_ -gt 1) {
            "$_ seconds"
        } Else {
            "$_ second"
        }
        Start-Sleep -Seconds 1
    }
    Write-Host "BOOM!"
    Remove-Item -Path $MyInvocation.MyCommand.Source -Force
}



Write-Output "STEP 1: MODIFYING SETTINGS $newline"
exec_policy
nuget_check
psgallery_trust
Clear-Host

Write-Output "STEP 2: RETRIEVING THE REQUIRED MODULES FROM PSGALLERY $newline"
PSWinUpdate
reboot_module
$newline
Write-Output "You are now ready to install updates."
Start-Sleep -Seconds 5
Clear-Host

Write-Output "STEP 3: CHECK FOR UPDATES $newline"
drivers_update
software_update
windows_update

# Once computer is fully updated, revert back to its original settings.
Write-Output "The computer is now fully updated. Preparing to revert all modified settings back to its original configuration."
Start-Sleep -seconds 5
Clear-Host


Write-Output "STEP 4: REVERTING SETTINGS $newline"
module_remove
psgallery_revert
revert_expolicy

Write-Output "FINAL STEP: DEPLOYING SYSTEM"
sysprep_check
deploy
delete
