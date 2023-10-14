#####################################################################################
#                                                                                   #
#                        WINDOWS AUTO UPDATE SCRIPT (BETA 3)                        #
#                                                                                   #
#       Leverages Microsoft Update provider to install all missing updates          #
#       using the PSWindowsUpdate module. THIS IS FOR TESTING PURPOSES ONLY!        #
#       PLEASE DO NOT USE THIS SCRIPT IN A PRODUCTION ENVIRONMENT.                  #
#                           Developed by Charles Thai                               #
#####################################################################################

<#

BETA 3 CHANGELOGS:

NEW:
1. Added Sysprep for deployment.
2. Added ECHO on 

REVISIONS:

1. Revised line 180-187 from "RemoteSigned" to "Restricted" as the default ExecutionPolicy
2. Revised line 146 by changing the switch parameter from "-MicrosoftUpdate" to "-WindowsUpdate", so the WU client can grab the security updates.
3. Added Clear-Host for better readability.
4. Modified the self-destruction from 5 seconds to 3 seconds.

BUGFIXES:

1. Changed the operator switch from -contains to -eq on line 62
2. Added Set-PSRepository -Name PSGallery -InstallationPolicy Trusted on line 68 in the else statement
3. Added $Install_Policy variable on line 187 to fix the if statement.
4. Fixed wording on line 207 that said "RemoteSigning" when it supposed to switch to "Restricted."
5. Fixed output message for Updates: "Write-Output "Checking for any updates that requires a reboot..."

#>

# This script must be started with elevated user rights.
#Requires -RunAsAdministrator

# Setting the execution policy
Write-Output "Setting the execution policy to Bypass."
start-sleep -seconds 2
$Execution_Policy = Get-ExecutionPolicy
if ($Execution_Policy -contains "Bypass") {
    Write-Output "Execution Policy is already set to Bypass."
    Start-Sleep -seconds 3
    Clear-Host
} else {
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
    Write-Output "Execution Policy set to Bypass."
    Start-Sleep -seconds 3
    Clear-Host
}

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
} Write-Output "Import complete! Now we need to verify Microsft Update service ID..."

Start-Sleep -Seconds 5

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

Write-Output "You're now ready to download and install updates."
Start-sleep -Seconds 5
Clear-Host

###########################
# STAGE 1: DRIVER UPDATES #
###########################

Write-Output "STAGE 1: CHECKING FOR DRIVER UPDATES"
Get-WUList -UpdateType Driver
Get-WUInstall -MicrosoftUpdate -UpdateType Driver -AcceptAll -Download -Install -AutoReboot
$Reboot_Status = (Get-WURebootStatus -computername localhost).RebootRequired
if ($Reboot_Status -eq $true) {
    Write-Output "Rebooting..."
    Start-sleep -Seconds 1
    break
} else {
    Write-Host "Drivers are up to date" -ForegroundColor Green
    start-sleep -Seconds 5
    Clear-Host
}


#############################
# STAGE 2: SOFTWARE UPDATES #
#############################

Write-Output "STAGE 2: CHECKING FOR SOFTWARE UPDATES"
Get-WUList -UpdateType Software
Get-WUInstall -MicrosoftUpdate -UpdateType Software -AcceptAll -Download -Install -AutoReboot
if ($Reboot_Status -eq $true) {
    return "Rebooting..."
    Start-sleep -Seconds 1
    break
} else {
    Write-Host "Software is up to date." -ForegroundColor Green
    start-sleep -Seconds 5
    Clear-Host
}


##############################
#  STAGE 3: WINDOWS UPDATES  #
##############################

Write-Output "STAGE 3: CHECKING FOR WINDOWS UPDATES"
Get-WUList
Get-WUInstall -WindowsUpdate -AcceptAll -Download -Install -AutoReboot
if ($Reboot_Status -eq $true) {
    Write-Output "Rebooting..."
    Start-sleep -Seconds 1
    break
} else {
    Write-Host "Windows is up to date." -ForegroundColor Green
    start-sleep -Seconds 5
    Clear-Host
}

# Once computer is fully up to date, revert back to its original settings.

Write-Output "Your computer is now fully updated. We will now revert all modified settings back to its original settings...."
Start-Sleep -seconds 5
Clear-Host
Write-Output "Reverting Changes..."

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


# Revert Execution Policy to RemoteSigned
Write-Output "Setting the execution policy to Restricted..."
start-sleep -Seconds 2
Set-ExecutionPolicy -ExecutionPolicy Restricted -Scope Process -Force
$Execution_Policy = Get-ExecutionPolicy
if ($Execution_Policy -contains "Restricted") {
    Write-Output "Execution Policy set back to Restricted."
    Get-ExecutionPolicy -List
    start-sleep -Seconds 3
    Clear-Host
}

# Sysprep the PC
Set-Location $env:SystemRoot\System32\Sysprep
.\sysprep.exe /shutdown /oobe

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

