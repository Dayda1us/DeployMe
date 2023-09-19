#####################################################################################
#                                                                                   #
#                        WINDOWS AUTO UPDATE SCRIPT (BETA 4)                        #
#                                                                                   #
#       Leverages Microsoft Update provider to install all missing updates          #
#       using the PSWindowsUpdate module. THIS SCRIPT IS IN BETA AND MAY            #
#       CONTAIN UNEXPECTED RESULTS. USE AT YOUR OWN RISK!                           #
#                                                                                   #
#                           Developed by Charles Thai                               #
#####################################################################################

<#

BETA 4 CHANGELOGS:

NEW:
1. Added the Pending Reboot module to replace the Get-WURebootStatus cmdlet. This new module will now verify if the computer requires a restart, and breaks the script if pending restart is set to TRUE.
2. Added "STEP X: " output messages for each code of the script.

REVISIONS:
1. Removed Microsoft/Windows Update verification service as it is unnecessary.
2. Revised the message for updates that requires a restart on Step 3 of the script: "One of the updates requires a reboot. Aborting script!"
3. Changed the execution policy on Step 4 of the script from "Restricted" to "Undefined", since it is the original setting for the built-in Administrator account.
4. Made minor revisions on output messages.
5. Added Get-ExecutionPolicy -List on the beginning of the execution policy script.

BUGFIXES:
1. Fixed a bug on the beginning of execution policy if statement. $Execution_Policy will now focus on the "Process" profile rather than the "CurrentUser."


#>

# This script must be started with elevated user rights.
#Requires -RunAsAdministrator

Write-Output "STEP 1: MODIFYING SETTINGS"

# Setting the execution policy
Write-Output "Setting the execution policy to Bypass."
start-sleep -seconds 2
$Execution_Policy = Get-ExecutionPolicy -Scope Process
if ($Execution_Policy -contains "Bypass") {
    Write-Output "Execution Policy is already set to Bypass."
    Get-ExecutionPolicy -List
    Start-Sleep -seconds 3
    Clear-Host
} else {
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
    Write-Output "Execution Policy set to Bypass."
    Get-ExecutionPolicy -List
    Start-Sleep -seconds 3
    Clear-Host
}

Write-Output "STEP 1: MODIFYING SETTINGS"

# Checks if NuGet is installed on the computer.
Write-Output "Checking if NuGet is installed on your computer."
$nuget = (Get-PackageProvider |  Where-Object {$_.name -eq "Nuget"}).name -contains "NuGet"
Start-Sleep -Seconds 3
if ($nuget -eq $true) {
    Write-Output "NuGet is already installed! Importing NuGet..."
    start-sleep -seconds 3
    Import-PackageProvider -name Nuget
    Write-Output "Nuget Imported!"
    start-sleep -Seconds 3
    Clear-Host
} else {
    Write-Output "Installing NuGet..."
    start-sleep -Seconds 3
    Install-PackageProvider -name NuGet -Force -ForceBootstrap
    Write-Output "Installed NuGet. Importing NuGet..."
    start-sleep -Seconds 3
    Import-PackageProvider -name Nuget
    Write-Output "Nuget Imported!"
    start-sleep -Seconds 3
    Clear-Host
}

Write-Output "STEP 1: MODIFYING SETTINGS"

# Updating the PSGallery (Default) repository.
Write-Output "Updating the PSGallery installation policy to Trusted"
Start-Sleep -Seconds 2
$Install_Policy = (Get-PSRepository | Where-Object {$_.InstallationPolicy -contains "Trusted"}).InstallationPolicy
if ($Install_Policy -eq "Trusted") {
    Write-Output "Installation Policy is already set to Trusted."
    Get-PSRepository -Name PSGallery | Format-List Name,SourceLocation,Trusted,Registered,InstallationPolicy
    start-sleep -Seconds 3
    Clear-Host
} else {
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    Write-Output "Installation set to Trusted."
    Get-PSRepository -Name PSGallery | Format-List Name,SourceLocation,Trusted,Registered,InstallationPolicy
    start-sleep -Seconds 3
    Clear-Host
}

Write-Output "STEP 2: RETRIEVING THE MODULES FROM PSGALLERY"

# Installing the PSWindowsUpdate module.
Write-Output "Checking if PSWindowsUpdate is already installed..."
if ((Get-InstalledModule -Name PSWindowsUpdate).name -contains "PSWindowsUpdate" -eq $false) {
    Write-Output "Looks like you don't have the PSWindowsUpdate module. Installing the module..."
    Install-Module -name PSWindowsUpdate -Force
    start-sleep -Seconds 2
    Write-Output "PSWindowsUpdate installed. Importing the module..."
    start-sleep -Seconds 2
    Import-Module -name PSWindowsUpdate
    Get-Module
} else {
    Write-Output "Looks like your computer has the PSWindowsUpdate module installed. Importing the module..."
    start-sleep -Seconds 2
    Import-Module -name PSWindowsUpdate
    Get-Module
} Write-Output "Import complete!"

Start-Sleep -Seconds 5
Clear-Host

Write-Output "STEP 2: RETRIEVING THE MODULES FROM PSGALLERY"

# Installing the PendingReboot module.
Write-Output "Checking if PendingReboot is already installed..."
if ((Get-InstalledModule -Name PendingReboot).name -contains "PendingReboot" -eq $false) {
    Write-Output "Looks like you don't have the PendingReboot module. Installing the module..."
    Install-Module -name PendingReboot -Force
    start-sleep -Seconds 2
    Write-Output "PendingReboot installed. Importing the module..."
    start-sleep -Seconds 2
    Import-Module -name PendingReboot
    Get-Module
} else {
    Write-Output "Looks like your computer has the PendingReboot module installed. Importing the module..."
    start-sleep -Seconds 2
    Import-Module -name PendingReboot
    Get-Module
} Write-Output "Import complete! You are now ready to install updates."

Start-Sleep -Seconds 5
Clear-Host


<#

# Checking if the Microsoft Update and Windows Update service is available. If not, we need to add it.

$MicrosoftUpdateServiceId = "7971f918-a847-4430-9279-4a52d1efe18d"
$WindowsUpdateServiceId = "9482f4b4-e343-43b6-b170-9a65bc822c77"

Write-Output "Verifying the Microsoft Update Service ID..."
start-sleep -seconds 3
Write-Output 'A' | Out-Null
if ((Get-WUServiceManager -ServiceID $MicrosoftUpdateServiceId).ServiceID -eq $MicrosoftUpdateServiceId) {
    Write-Output "Microsoft Update Service ID verified."
    start-sleep -seconds 3
} else {
    Add-WUServiceManager -ServiceID $MicrosoftUpdateServiceId -Confirm: $true
}
if (!((Get-WUServiceManager -ServiceID $MicrosoftUpdateServiceId).ServiceID -eq $MicrosoftUpdateServiceId)) {
    Throw "Error: Microsoft Update service is not registered."
}

Write-Output "Verifying the Windows Update Service ID..."
start-sleep -seconds 3
if ((Get-WUServiceManager -ServiceID $WindowsUpdateServiceId).ServiceID -eq $WindowsUpdateServiceId) {
    Write-Output "Windows Update Service ID verified."

} else {
    Add-WUServiceManager -ServiceID $WindowsUpdateServiceId -Confirm: $true
}
if (!((Get-WUServiceManager -ServiceID $WindowsUpdateServiceId).ServiceID -eq $WindowsUpdateServiceId)) {
    Throw "Error: Microsoft Update service is not registered."
}

#>

Write-Output "STEP 3: UPDATES"

###########################
# STAGE 1: DRIVER UPDATES #
###########################

Write-Output "STAGE 1: CHECKING FOR DRIVER UPDATES"
Get-WUList -UpdateType Driver
Get-WUInstall -MicrosoftUpdate -UpdateType Driver -AcceptAll -Download -Install -AutoReboot
$Reboot_Status = (Test-PendingReboot -SkipConfigurationManagerClientCheck).IsRebootPending
if ($Reboot_Status -eq $true) {
    Write-Output "One of the updates requires a reboot. Aborting script!"
    Start-sleep -Seconds 1
    break
} else {
    Write-Host "Drivers are up to date" -ForegroundColor Green
    start-sleep -Seconds 5
    Clear-Host
}

Write-Output "STEP 3: UPDATES"

#############################
# STAGE 2: SOFTWARE UPDATES #
#############################

Write-Output "STAGE 2: CHECKING FOR SOFTWARE UPDATES"
Get-WUList -UpdateType Software
Get-WUInstall -MicrosoftUpdate -UpdateType Software -AcceptAll -Download -Install -AutoReboot
if ($Reboot_Status -eq $true) {
    return "One of the updates requires a reboot. Aborting script!"
    Start-sleep -Seconds 1
    break
} else {
    Write-Host "Software is up to date." -ForegroundColor Green
    start-sleep -Seconds 5
    Clear-Host
}

Write-Output "STEP 3: UPDATES"

##############################
#  STAGE 3: WINDOWS UPDATES  #
##############################

Write-Output "STAGE 3: CHECKING FOR WINDOWS UPDATES"
Get-WUList
Get-WUInstall -WindowsUpdate -AcceptAll -Download -Install -AutoReboot
if ($Reboot_Status -eq $true) {
    Write-Output "One of the updates requires a reboot. Aborting script!"
    Start-sleep -Seconds 1
    break
} else {
    Write-Host "Windows is up to date." -ForegroundColor Green
    start-sleep -Seconds 5
    Clear-Host
}

# Once computer is fully up to date, revert back to its original settings.

Write-Output "Your computer is now fully updated. We will now revert all modified settings back to its original settings."
Start-Sleep -seconds 5
Clear-Host
Write-Output "STEP 4: SETTINGS CLEANUP"

##############################
#      SETTINGS CLEANUP      #
##############################

# Uninstalling the PSWindowsUpdate module
Write-Output "Removing the PSWindowsUpdate module..."
start-sleep -Seconds 2
"PSWindowsUpdate" | Remove-Module
Write-Host "Module sucessfully removed" -ForegroundColor Green
start-sleep -Seconds 1
Get-Module
start-sleep -Seconds 2
Clear-Host

Write-Output "STEP 4: SETTINGS CLEANUP"

# Uninstalling the PendingReboot module
Write-Output "Removing the PendingReboot module..."
start-sleep -Seconds 2
"PendingReboot" | Remove-Module
Write-Host "Module sucessfully removed" -ForegroundColor Green
start-sleep -Seconds 1
Get-Module
start-sleep -Seconds 2
Clear-Host

Write-Output "STEP 4: SETTINGS CLEANUP"

# Change the default repository back to Untrusted
Write-Output "Setting PSGallery repository to Untrusted..."
start-sleep -Seconds 2
Set-PSRepository -Name PSGallery -InstallationPolicy Untrusted
$Install_Policy = (Get-PSRepository | Where-Object {$_.InstallationPolicy -contains "Untrusted"}).InstallationPolicy
if ($Install_Policy -contains "Untrusted") {
    Write-Output "Installation Policy set to Untrusted."
    Get-PSRepository -Name PSGallery | Format-List Name,SourceLocation,Trusted,Registered,InstallationPolicy
    start-sleep -Seconds 3
    Clear-Host
}

Write-Output "STEP 4: SETTINGS CLEANUP"

# Revert Execution Policy to Undefined
Write-Output "Setting the execution policy to Undefined..."
start-sleep -Seconds 2
Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope Process -Force
$Execution_Policy = Get-ExecutionPolicy
if ($Execution_Policy -contains "Undefined") {
    Write-Output "Execution Policy set back to Undefined."
    Get-ExecutionPolicy -List
    start-sleep -Seconds 3
    Clear-Host
}

Write-Output "STEP 5: FINALIZING SYSTEM"

# Sysprep the PC
Write-Output "Preparing Sysprep..."
Start-sleep 5
Set-Location $env:SystemRoot\System32\Sysprep
.\sysprep.exe /oobe /shutdown

# Delete the script.
Write-Output "Script complete! This script will self-destruct in 3 seconds."
3..1 | ForEach-Object {
    If ($_ -gt 1) {
        "$_ seconds"
    } Else {
        "$_ second"
    }
    Start-Sleep -Seconds 1
}
Write-Output -InputObject "Goodbye."
Remove-Item -Path $MyInvocation.MyCommand.Source -Force

