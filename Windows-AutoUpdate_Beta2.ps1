#####################################################################################
#                                                                                   #
#                        WINDOWS AUTO UPDATE SCRIPT (BETA 2)                        #
#                                                                                   #
#       Leverages Microsoft Update provider to install all missing updates          #
#       using the PSWindowsUpdate module. THIS IS FOR TESTING PURPOSES ONLY!        #
#       PLEASE DO NOT USE THIS SCRIPT IN A PRODUCTION ENVIRONMENT.                  #
#                           Developed by Charles Thai                               #
#####################################################################################


<#
CHANGELOGS

NEW:
1. Broken the Microsoft Updates into three stages: Drivers, Software, and Windows updates

REVISIONS:
1. Changed sleep seconds from 5 seconds to 2 seconds
2. Added an else statement on line 38-43 to check if the execution policy is set to Bypass.
3. Removed line 76-79 as this code is redundant
4. Removed line 153-156 as updates has been broken apart into three stages. See NEW.

BUGFIXES:
1. Reworded the write output on line 16 to "Execution Policy is set to Bypass."
2. Changed the cmdlet of $nuget variable on line 43 by changing from Select-Object {$_.name -match "nuget"}
to Where-Object {$_.name -eq "Nuget"} to fix the boolean switch 
3. Fixed line 65-73 by adding $Install_Policy variable and moving the Set-Repository inside an if/else statement



#>

# This script must be started with elevated user rights.
#Requires -RunAsAdministrator

# Setting the execution policy
Write-Output "Setting the execution policy to Bypass."
start-sleep -seconds 2
$Execution_Policy = Get-ExecutionPolicy
if ($Execution_Policy -contains "Bypass") {
    Write-Output "Execution Policy is already set to Bypass."
} else {
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
    Write-Output "Execution Policy set to Bypass."
}

# Checks if NuGet is installed on the computer.
Write-Output "Checking if NuGet is installed on your computer."
#$nuget = Get-PackageProvider -name nuget | Select-Object {$_.name -match "nuget"} -ErrorAction SilentlyContinue
$nuget = (Get-PackageProvider |  Where-Object {$_.name -eq "Nuget"}).name -contains "NuGet"
Start-Sleep -Seconds 2
if ($nuget -eq $true) {
    Write-Output "NuGet is already installed! Importing NuGet..."
    start-sleep -seconds 2
    Import-PackageProvider -name Nuget
} else {
    Write-Output "Installing NuGet..."
    start-sleep -Seconds 2
    Install-PackageProvider -name NuGet -Force -ForceBootstrap
    Import-PackageProvider -name Nuget
}

# Updating the PSGallery (Default) repository.
Write-Output "Updating the PSGallery installation policy to Trusted"
Start-Sleep -Seconds 2
#Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
$Install_Policy = (Get-PSRepository | Where-Object {$_.InstallationPolicy -contains "Trusted"}).InstallationPolicy
if ($Install_Policy -contains "Trusted") {
    Write-Output "Installation Policy is already set to Trusted."
    Get-PSRepository -Name PSGallery | Format-List Name,SourceLocation,Trusted,Registered,InstallationPolicy
} else {
    Write-Output "Installation set to Trusted"
    Get-PSRepository -Name PSGallery | Format-List Name,SourceLocation,Trusted,Registered,InstallationPolicy
}

# Check the trust of the PSGallery repository
#Write-Output "PSGallery repository has been set to Trusted."
#Get-PSRepository -Name PSGallery | Format-List Name,SourceLocation,Trusted,Registered,InstallationPolicy
#start-sleep -seconds 2

# Installing the PSWindowsUpdate module.
Write-Output "Checking if PSWindowsUpdate is already installed..."
if ((Get-InstalledModule -Name PSWindowsUpdate).name -contains "PSWindowsUpdate" -eq $false) {
    Write-Output "Looks like you don't have the PSWindowsUpdate module. Installing the module..."
    Install-Module -name PSWindowsUpdate -Force
    start-sleep -Seconds 2
    Write-Output "PSWindowsUpdate installed. Importing the module..."
    start-sleep -Seconds 2
    Import-Module -name PSWindowsUpdate
} else {
    Write-Output "Looks like your computer has the PSWindowsUpdate module installed. Importing the module..."
    start-sleep -Seconds 2
    Import-Module -name PSWindowsUpdate
} Write-Output "Import complete! When you're ready, press the ENTER key to move on to the next step."

Pause

# Checking if the Microsoft Update service is available. If not, we need to add it.

$MicrosoftUpdateServiceId = "7971f918-a847-4430-9279-4a52d1efe18d" #This Service ID should be preinstalled and set as the default. You may check this using Get-WUServiceManager.

Write-Output "Verifying the Microsoft Update Service ID..."
if ((Get-WUServiceManager -ServiceID $MicrosoftUpdateServiceId).ServiceID -eq $MicrosoftUpdateServiceId) {
    Write-Output "Service ID verified."
} else {
    Add-WUServiceManager -ServiceID $MicrosoftUpdateServiceId -Confirm: $true
}
if (!((Get-WUServiceManager -ServiceID $MicrosoftUpdateServiceId).ServiceID -eq $MicrosoftUpdateServiceId)) {
    Throw "Error: Microsoft Update service is not registered."
}
Write-Output "You're now ready to download and install updates. Press the ENTER key to check for updates"
Pause

###########################
# STAGE 1: DRIVER UPDATES #
###########################

Write-Output "STAGE 1: CHECKING FOR DRIVER UPDATES"
Get-WUList -UpdateType Driver
Get-WUInstall -MicrosoftUpdate -UpdateType Driver -AcceptAll -Download -Install -AutoReboot
$Reboot_Status = (Get-WURebootStatus).RebootRequired
if ($Reboot_Status -eq $true) {
    Write-Output "Rebooting..."
} else {Write-Output "Drivers are up to date."}
start-sleep -Seconds 2
clear

#############################
# STAGE 2: SOFTWARE UPDATES #
#############################

Write-Output "STAGE 2: CHECKING FOR SOFTWARE UPDATES"
Get-WUList -UpdateType Software
Get-WUInstall -MicrosoftUpdate -UpdateType Software -AcceptAll -Download -Install -AutoReboot
if ($Reboot_Status -eq $true) {
    Write-Output "Rebooting..."
} else {Write-Output "Software is up to date."}
start-sleep -Seconds 2
clear

##############################
#  STAGE 3: WINDOWS UPDATES  #
##############################

Write-Output "STAGE 3: CHECKING FOR WINDOWS UPDATES"
Get-WUInstall -MicrosoftUpdate -AcceptAll -Download -Install -AutoReboot
if ($Reboot_Status -eq $true) {
    Write-Output "Rebooting..."
} else {Write-Output "Windows is up to date."}
start-sleep -Seconds 2
clear

# Force the installation of updates and reboot the computer (if required)
#Get-WUInstall -MicrosoftUpdate -AcceptAll -AutoReboot
#Get-WUInstall -MicrosoftUpdate -AcceptAll -Download -Install -AutoReboot

# Once computer is fully up to date, revert back to its original settings.

Write-Output "Your computer is now fully updated. We will now revert all modified settings back to its original settings. Press the ENTER key when you're ready"
Pause

# Uninstalling the PSWindowsUpdate module
#Write-Output "Removing the PSWindowsUpdate module..."
#"PSWindowsUpdate" | Remove-Module | Uninstall-Module -Name PSWindowsUpdate
#Write-Output "Module sucessfully removed"
#Get-Module

# Change the default repository back to Untrusted
Write-Output "Setting PSGallery repository to Untrusted..."
start-sleep -Seconds 2
Set-PSRepository -Name PSGallery -InstallationPolicy Untrusted
if ((Get-PSRepository -Name PSGallery).InstallationPolicy -match "Untrusted") {
    Write-Output "Installation Policy set to Untrusted."
    Get-PSRepository -Name PSGallery | Format-List Name,SourceLocation,Trusted,Registered,InstallationPolicy
}


# Revert Execution Policy to RemoteSigned
Write-Output "Setting the execution policy to RemoteSigned..."
start-sleep -Seconds 2
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
$Execution_Policy = Get-ExecutionPolicy
if ($Execution_Policy -contains "RemoteSigned") {
    Write-Output "Execution Policy set back to RemoteSigned."
}

# Finalize System

# Delete the script.
Write-Output "Script complete! This script will self-destruct in 5 seconds."
5..1 | ForEach-Object {
    If ($_ -gt 1) {
        "$_ seconds"
    } Else {
        "$_ second"
    }
    Start-Sleep -Seconds 1
}
Write-Output -InputObject "Goodbye."
Remove-Item -Path $MyInvocation.MyCommand.Source -Force

