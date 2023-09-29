#####################################################################################
#                                                                                   #
#                          WINDOWS AUTO DEPLOYMENT (v1.0)                           #
#                                                                                   #
#       Leverages Microsoft Update provider to install all missing updates          #
#       using the PSWindowsUpdate module and deploy keys via Keydeploy.             #
#                                                                                   #
#                                                                                   #
#                           Developed by Charles Thai                               #
#####################################################################################

<#
PRODUCTION v1.0 CHANGELOGS:

NEW:
1. Created company name in ASCII.

REVISIONS:
1. Renamed ps1 file from "Windows-AutoUpdate" to "AutoDeploy".
2. Revised the steps as stages and shortened the stages from 6 to 4.
3. Decreased the sleep time for CheckForReboot from 5 sec. to 3 sec.

BUGFIXES:
1. Added Remove-LocalUser on LocalAccountRemoval function. Now it should automatically remove the local account.
2. Added an ErrorAction parameter on the PendingRebootModule to SilentlyContinue to suppress the error message if module is not installed.


TODO: 
1. Add the DeployKey functionality to the script with a message prompt.
2. Check the CheckForReboot functionality.
3. Combine all updates into one instead of three stages.

#>

# This script must be started with elevated user rights.
#Requires -RunAsAdministrator

$newline = Write-Output "`n"

Start-Sleep -seconds 1
Clear-Host
Write-Host " _____ ____    _____ _____ ____ _   _ _   _  ___  _     ___   ______   __" -ForegroundColor Green
Write-Host "|___ /|  _ \  |_   _| ____/ ___| | | | \ | |/ _ \| |   / _ \ / ___\ \ / /" -ForegroundColor Green
Write-Host "  |_ \| |_) |   | | |  _|| |   | |_| |  \| | | | | |  | | | | |  _ \ V / " -ForegroundColor Green
Write-Host " ___) |  _ <    | | | |__| |___|  _  | |\  | |_| | |__| |_| | |_| | | |  " -ForegroundColor Green
Write-Host "|____/|_| \_\   |_| |_____\____|_| |_|_| \_|\___/|_____\___/ \____| |_|`n  " -ForegroundColor Green
Write-Output "#######################################################################"
Write-Output "#              WINDOWS AUTOMATED DEPLOYMENT SCRIPT v1.0               #"
Write-Output "#                                                                     #"
Write-Output "#                     DEVELOPED BY CHARLES THAI                       #"
Write-Output "#######################################################################`n"
Start-Sleep -seconds 3
Clear-Host



##########################
#   MODIFYING SETTINGS   #
##########################

# Sets the process execution policy to Bypass
function BypassPolicy { 
    Write-Verbose "Sets the execution policy to bypass for the script to run properly"
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
    } #endif
    $newline
} #function

# Checks if NuGet is installed on the computer.
function NuGetCheck {
    Write-Output "Checking if NuGet is installed on your computer..."
    $nuget = (Get-PackageProvider |  Where-Object {$_.name -eq "Nuget"}).name -contains "NuGet"
    Start-Sleep -Seconds 3
    if ($nuget -eq $true) {
        Write-Output "NuGet is already installed! Importing NuGet..."
        start-sleep -seconds 3
        Import-PackageProvider -name Nuget
        $newline
        Write-Output "NuGet Imported!"
        Get-PackageProvider
    } else {
        Write-Output "NuGet not installed. Installing NuGet..."
        start-sleep -Seconds 3
        Install-PackageProvider -name NuGet -Force -ForceBootstrap
        $newline
        Write-Output "Installed NuGet. Importing NuGet..."
        start-sleep -Seconds 3
        Import-PackageProvider -name Nuget
        Write-Output "Nuget Imported!"
        Get-PackageProvider
    } #if
    start-sleep -seconds 3
    $newline
} #function

# Update the PSGallery (Default) repository to trusted to ensure the installed modules work properly.
function TrustPSGallery {
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
} #function

###########################
#  INSTALL REQ'D MODULES  #
###########################

# Check if PSWindowsUpdate module is installed.
function PSWinUpdateModule {
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
    } #if
    Write-Output "Import complete!"
    $newline
    Get-Module
    Start-Sleep -Seconds 5
} #function

# Check if PendingReboot module is installed.
function PendingRebootModule {
    Write-Output "Checking if PendingReboot is already installed..."
    if ((Get-InstalledModule -Name PendingReboot -EA SilentlyContinue).name -contains "PendingReboot" -eq $false) {
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
    } #if
} #function

#TODO: Separate reboot check. Tested and working.
function CheckForReboot {
    Write-Output "Checking for installed updates (if any) that require a reboot..."
    Start-Sleep -Seconds 10
    if ((Test-PendingReboot -SkipConfigurationManagerClientCheck).IsRebootPending -eq $false) {
        Write-Host "You're up to date!" -ForegroundColor Green
        start-sleep -Seconds 3
    } else {
        Write-Output "One or more updates requires a reboot. Rebooting..."
        Start-sleep -Seconds 3
        Restart-Computer -Force
        break
    } #if
} #function

#TODO: Combine all updates into one. Tested on a Lenovo Thinkpad X1 Carbon.
function Updates {
    Write-Output "CHECKING FOR UPDATES"
    $GWU = Get-WUList -MicrosoftUpdate
    $GWU
    Get-WUList -AcceptAll -Install -IgnoreReboot
    CheckForReboot
    Clear-Host
} #function

# REMOVE THREE FUNCTIONS AFTER TESTING Updates. KEEP IT SIMPLE STUPID.

###########################
#     DRIVER UPDATES      #
###########################

function DriverUpdate {
    Write-Output "DRIVER UPDATES"
    Get-WUList -MicrosoftUpdate -UpdateType Driver -AcceptAll -Download -Install -IgnoreReboot
    CheckForReboot
    Clear-Host
} #function

#############################
#     SOFTWARE UPDATES      #
#############################
function SoftwareUpdate {
    Write-Output "SOFTWARE UPDATES AND VIRUS DEFINITIONS"
    Get-WUList -MicrosoftUpdate -UpdateType Software -AcceptAll -Download -Install -IgnoreReboot
    CheckForReboot
    Clear-Host
} #function

# TO BE REMOVED: REDUNDANT.
#######################
#   WINDOWS UPDATES   #
#######################
function WinUpdate {
    Write-Output "WINDOWS UPDATES"
    Get-WUList -WindowsUpdate -AcceptAll -Download -Install -IgnoreReboot
    CheckForReboot
    Clear-Host
} #function


#####################
#  REVERT SETTINGS  #
#####################

# Remove the installed modules (PSWindowsUpdate and PendingReboot).
function RemoveModules {
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
} #function

# Revert default Installation Policy to Untrusted
function UntrustPSGallery {
    Write-Output "Reverting PSGallery Installation Policy to Untrusted..."
    start-sleep -Seconds 2
    Set-PSRepository -Name PSGallery -InstallationPolicy Untrusted
    $Install_Policy = (Get-PSRepository | Where-Object {$_.InstallationPolicy -contains "Untrusted"}).InstallationPolicy
    if ($Install_Policy -contains "Untrusted") {
        Write-Output "Installation Policy set to Untrusted."
        Get-PSRepository -Name PSGallery | Format-List Name,SourceLocation,Trusted,Registered,InstallationPolicy
        start-sleep -Seconds 3
    } #endif
} #function

# Revert Execution Policy to Undefined
function UndefinedPolicy {
    Write-Output "Setting the execution policy to Undefined..."
    start-sleep -Seconds 2
    Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope Process -Force
    $Execution_Policy = Get-ExecutionPolicy -Scope Process
    if ($Execution_Policy -contains "Undefined") {
        Write-Output "Execution Policy set back to Undefined."
        Get-ExecutionPolicy -List
        start-sleep -Seconds 3
    } #endif
    Clear-Host    
} #function

################
#  DEPLOYMENT  #
################

# Remove Refurb account.
function LocalAccountRemoval {
    Write-Verbose "Checks if the previously created account exists and deletes it if found"
    $Account = "Refurb"
    Write-Output "Retrieving previously created account..."
    Start-Sleep -Seconds 2
    if ((Get-LocalUser -Name $Account -EA SilentlyContinue).name -eq $Account) {
        Write-Output "Removing account.."
        Start-Sleep -Seconds 1
        Remove-LocalUser -Name $Account
        Write-Host "$Account account removed! $newline" -ForegroundColor Green
        Get-LocalUser
    } else {
        Write-Host "$Account account doesn't exist! Skipping account removal." -ForegroundColor Red
        Get-LocalUser
    } #endif 
} #function


# Checks if Sysprep is already opened
function CheckSysprep {
    Write-Output "Checking if Sysprep is already opened..."
    $check_sysprep = "sysprep"
    Start-Sleep -Seconds 2
    if ((Get-Process $check_sysprep -ErrorAction SilentlyContinue).ProcessName -contains "sysprep") {
        Write-Output "Terminiating Sysprep..."
        Start-sleep -Seconds 3
        Stop-Process -ProcessName $check_sysprep
        Write-Host "Sysprep terminated." -ForegroundColor Green
    } else {
        Write-Host "Sysprep is not opened. Skipping Sysprep check." -ForegroundColor Red
    } #endif
} #function

#TODO: Get KeyDeploy working
function DeployKey {
    Write-Output "This process will open KeyDeploy. If you're deploying a desktop, please power off the computer and connect it to the KeyDeploy server."
    Write-Output "When you're ready, press ENTER to launch KeyDeploy."
    Pause
    $process = "KeyDeploy"
    Write-Output "Launching $process..."
    Start-sleep -Seconds 5
    Start-Process $process
    do {
        Write-Output "$process is open"
        start-sleep -Seconds 1
    } while ((Get-Process -name $process).name -contains "keydeploy") #dowhile
} #function

#TODO: Check if Windows license is installed. Prompt the user if they would like to launch KeyDeploy.
function CheckWindowsLicense {
    Write-Output "Check for Windows activation status..."
    if (!(Get-CimInstance SoftwareLicensingProduct).LicenseStatus -eq 0) {
        Write-Host "Your Windows activation key is licensed!" -ForegroundColor Green
    } else {
        Write-Host "Your Windows activation key is not licensed! Would you like to run KeyDeploy manually?" -ForegroundColor Red
        start-sleep -Seconds 2
        break
    }
}

# Sysprep and delete the script.
function OOBE {
    Write-Output "Preparing Sysprep..."
    Start-sleep 5
    Set-Location $env:SystemRoot\System32\Sysprep
    .\sysprep.exe /oobe
    shutdown.exe /s /t 10
}

# This prerequisite check requires Windows PowerShell v5. This function will not work on later versions.
Write-Verbose -Message "Checks for an Internet connection before running the script"
Write-Output "Checking for Internet connectivity...."
Start-sleep 5
while ((Test-Connection 3rtechnology.com -Count 1 -ErrorAction SilentlyContinue).ResponseTime -lt 0) {
    Write-Host "No Internet connection. Please double check your network configuration. Retrying..." -ForegroundColor Red
    start-sleep -seconds 5
}

Write-Host "Internet connection established! Initializing script..." -ForegroundColor Green
Start-sleep -Seconds 5
Clear-Host

Write-Output "STAGE 1: MODIFYING SETTINGS AND RETRIEVING THE REQUIRED MODULES $newline"
BypassPolicy
NuGetCheck
TrustPSGallery
PSWinUpdateModule
PendingRebootModule
Clear-Host
Write-Output "You are now ready to install updates."
Start-Sleep -Seconds 5
Clear-Host


Write-Output "STAGE 2: UPDATES $newline"
Updates

# Once computer is fully updated, revert back to its original settings.
Write-Output "The computer is now fully updated. Preparing to revert all modified settings back to its original configuration."
Start-Sleep -seconds 5
Clear-Host

Write-Output "STAGE 3: REVERT SETTINGS $newline"
RemoveModules
UntrustPSGallery
UndefinedPolicy

Write-Output "FINAL STAGE: DEPLOYMENT $newline"
LocalAccountRemoval
#DeployKey
#CheckWindowsLicense
CheckSysprep
#OOBE

# Delete the script once it is done.
Write-Output "Script complete! This script will self-destruct in 3 seconds."
3..1 | ForEach-Object {
    If ($_ -gt 1) {
        "$_ seconds"
    } Else {
        "$_ second"
    }
    Start-Sleep -Seconds 1
}
Write-Output "Script deleted!"
Remove-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat" -Force
Remove-Item -Path $MyInvocation.MyCommand.Source -Force
