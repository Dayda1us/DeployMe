#####################################################################################
#                                                                                   #
#                          WINDOWS AUTO DEPLOYMENT (v1.0)                           #
#                                                                                   #
#       Leverages Microsoft Update provider to install all missing updates          #
#       using the PSWindowsUpdate module and deploy keys via Keydeploy.             #
#                                                                                   #
#                                                                                   #
#                           Developed by Charles Thai                               #
#####################################################################################

<#
PRODUCTION v1.0 CHANGELOGS:

NEW:
1. Created company name in ASCII.

REVISIONS:
1. Renamed ps1 file from "Windows-AutoUpdate" to "AutoDeploy".
2. Revised the steps as stages and shortened the stages from 6 to 4.
3. Decreased the sleep time for CheckForReboot from 5 sec. to 2 sec.
4. Major revamp on the updates by combining all stage updates into one for simplicity.
5. Separated the reboot codes in updates into it's own function: "CheckForReboot".
6. Changed format cmdlet on TrustPSGallery to "format-table".
7. Revamped the UndefinedPolicy with a switch statement.
8. Removed the Import-PackageProvider on NuGetCheck on true statement.

BUGFIXES:
1. Added Remove-LocalUser on LocalAccountRemoval function. Now it should automatically remove the local account.
2. Added an ErrorAction parameter on the PendingRebootModule to SilentlyContinue to suppress the error message if module is not installed.


TODO: 
1. Add the DeployKey functionality to the script with a message prompt. 

#>

# This script must be started with elevated user rights.
#Requires -RunAsAdministrator

$newline = Write-Output "`n"

Start-Sleep -seconds 1
Clear-Host
Write-Host " _____ ____    _____ _____ ____ _   _ _   _  ___  _     ___   ______   __" -ForegroundColor Green
Write-Host "|___ /|  _ \  |_   _| ____/ ___| | | | \ | |/ _ \| |   / _ \ / ___\ \ / /" -ForegroundColor Green
Write-Host "  |_ \| |_) |   | | |  _|| |   | |_| |  \| | | | | |  | | | | |  _ \ V / " -ForegroundColor Green
Write-Host " ___) |  _ <    | | | |__| |___|  _  | |\  | |_| | |__| |_| | |_| | | |  " -ForegroundColor Green
Write-Host "|____/|_| \_\   |_| |_____\____|_| |_|_| \_|\___/|_____\___/ \____| |_|`n  " -ForegroundColor Green
Write-Output "#######################################################################"
Write-Output "#                  WINDOWS AUTOMATED DEPLOYMENT v1.0                  #"
Write-Output "#                                                                     #"
Write-Output "#                     DEVELOPED BY CHARLES THAI                       #"
Write-Output "#######################################################################`n"
Start-Sleep -seconds 3
Clear-Host


##########################
#   MODIFYING SETTINGS   #
##########################

# Sets the process execution policy to Bypass
function BypassPolicy { 
    Write-Output "Setting the Process Execution Policy to Bypass."

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
    $nuget = (Get-PackageProvider |  Where-Object {$_.name -eq "Nuget"}).name -contains "NuGet"
    Write-Output "Checking if NuGet is installed on your computer..."
    Start-Sleep -Seconds 5

    if ($nuget -eq $true) {
        Write-Output "NuGet is already installed!"
        start-sleep -seconds 2
    } else {
        Write-Output "NuGet not installed. Installing NuGet..."
        start-sleep -Seconds 2
        Install-PackageProvider -name NuGet -Force -ForceBootstrap

        Write-Output "`nInstalled NuGet. Importing NuGet..."
        start-sleep -Seconds 2
        Import-PackageProvider -name Nuget

        Write-Output "NuGet Imported!`n"
        Get-PackageProvider
    } #if

    $newline
} #function

# Update the PSGallery (Default) repository to trusted to ensure the installed modules work properly.
function TrustPSGallery {
    Write-Output "Updating the PSGallery installation policy to Trusted"
    Start-Sleep -Seconds 2

    $PSGallery = (Get-PSRepository -Name PSGallery).name -eq "PSGallery"
    $Install_Policy = (Get-PSRepository -Name PSGallery | Where-Object {$_.InstallationPolicy -contains "Trusted"}).InstallationPolicy

    if ($PSGallery -eq $true -and $Install_Policy -eq "Trusted") {
        Write-Output "Installation Policy is already set to Trusted."
        Get-PSRepository -Name PSGallery | Format-Table Name,SourceLocation,Trusted,Registered,InstallationPolicy
        start-sleep -Seconds 3
    } else {
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
        Write-Output "Installation set to Trusted."
        Get-PSRepository -Name PSGallery | Format-Table Name,SourceLocation,Trusted,Registered,InstallationPolicy
        start-sleep -Seconds 3
    } #if
} #function

###########################
#  INSTALL REQ'D MODULES  #
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

    Get-Module -Name PSWindowsUpdate

    Write-Host "Import Complete!" -ForegroundColor Green
    Start-Sleep -Seconds 2
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
    } else {
        Write-Output "PendingReboot module is already installed. Importing PendingReboot..."
        start-sleep -Seconds 2
        Import-Module -name PendingReboot
        $newline
    } #if
    
    Get-Module -Name PendingReboot
    
    Write-Host "Import Complete!" -ForegroundColor Green
    Start-sleep -seconds 2
    Clear-Host
} #function

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

function Updates {
    Write-Output "CHECKING FOR UPDATES"

    $GWU = Get-WUList -MicrosoftUpdate
    $GWU

    Get-WUList -AcceptAll -Install -IgnoreReboot
    CheckForReboot
    Clear-Host
} #function

#####################
#  REVERT SETTINGS  #
#####################

# Remove the installed modules (PSWindowsUpdate and PendingReboot).
function RemoveModules {
    Write-Output "Removing the installed modules..."

    $UpdateModule = (("PSWindowsUpdate" | Get-Module).Name) -eq "PSWindowsUpdate"
    $RebootModule = (("PendingReboot" | Get-Module).Name) -eq "PendingReboot"

    Start-sleep -Seconds 3
    if ($UpdateModule -eq $True -and $RebootModule -eq $True) {
        Write-Output "Removing PSWindowsUpdate and PendingReboot..."
        start-sleep -Seconds 2
        "PSWindowsUpdate" | Remove-Module
        "PendingReboot" | Remove-Module
        Write-Host "Installed modules removed!" -f Green
        Get-Module
        start-sleep -Seconds 2
    } else {
        Write-Output "The modules appear to be removed already at one point."
        Get-Module
        Start-sleep -Seconds 2
    }
    $newline
} #function

# Revert default Installation Policy to Untrusted
function UntrustPSGallery {
    Write-Output "Reverting PSGallery Installation Policy to Untrusted..."
    Start-Sleep -Seconds 2

    $Install_Policy = ((Get-PSRepository PSGallery).InstallationPolicy) -eq "Trusted"

    if ($Install_Policy -contains "Untrusted") {
        Set-PSRepository -Name PSGallery -InstallationPolicy Untrusted
        Write-Output "Installation Policy set to Untrusted."
        Get-PSRepository -Name PSGallery | Format-Table Name,@{l="Source Location";e={$_.SourceLocation}},Trusted,Registered,InstallationPolicy
        start-sleep -Seconds 2
    } else {
        Write-Output "Installation policy is already set to Untrusted."
        Get-PSRepository -Name PSGallery | Format-Table Name,@{l="Source Location";e={$_.SourceLocation}},Trusted,Registered,InstallationPolicy
        start-sleep -Seconds 2
    }#endif
    $newline
} #function

# Revert Execution Policy to Undefined
function UndefinedPolicy {
    Write-Output "Setting the Process execution policy to Undefined..."
    start-sleep -Seconds 2

    $EP = (Get-ExecutionPolicy -List | Where-Object {$_.Scope -contains "Process"}).ExecutionPolicy
    $OtherScope = @("AllSigned", "Restricted", "RemoteSigned", "Unrestricted")

    switch($EP) {
        { $EP -eq "Bypass" } {
            Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope Process -Force
            Write-Output "Process execution policy set back to Undefined."
            Start-Sleep -Seconds 1
            Get-ExecutionPolicy -List

        }
        { $EP -eq "Undefined" } {
            Write-Output "Process execution policy is already set to Undefined"
            Start-Sleep -Seconds 1
            Get-ExecutionPolicy -List
        }
        { $EP -contains $OtherScope} {
            Write-Output "Process execution policy was set other than Bypass. Setting back to Undefined..."
            Start-sleep -Seconds 1
            Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope Process -Force
            Write-Output "Process execution policy set back to Undefined."
            Get-ExecutionPolicy -List
        }
        default {
            Write-Host "Unknown error occurred. Aborting script!" -f Red
            Start-Sleep -Seconds 2
            Break
        }
    } #switch
    Start-Sleep -Seconds 2
    $newline
} #function

################
#  DEPLOYMENT  #
################

# Remove Refurb account. TODO: Let Jake know about creating a new reference image without creating a local admin account.
function LocalAccountRemoval {
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
    Start-Sleep -Seconds 3
    if ((Get-Process $check_sysprep -ErrorAction SilentlyContinue).ProcessName -contains "sysprep") {
        Write-Output "Terminiating Sysprep...`n"
        Start-sleep -Seconds 3
        Stop-Process -ProcessName $check_sysprep
        Write-Host "Sysprep terminated." -ForegroundColor Green
    } else {
        Write-Host "Sysprep is not opened. Skipping Sysprep check.`n" -ForegroundColor Red
    } #endif
} #function

#TODO: Get KeyDeploy working
function DeployKey {
    [CmdletBinding()]
    Param()
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
    [CmdletBinding()]
    Param()
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
    Write-Output "`nPreparing Sysprep..."
    Start-sleep 5
    Set-Location $env:SystemRoot\System32\Sysprep
    .\sysprep.exe /oobe
    shutdown.exe /s /t 10
}
function Stage1 {
    Write-Output "STAGE 1: MODIFYING SETTINGS AND RETRIEVING THE REQUIRED MODULES`n"
    BypassPolicy
    NuGetCheck
    TrustPSGallery
    PSWinUpdateModule
    PendingRebootModule
    ReadyMessage
} #function

function Stage2 {
    Write-Output "STAGE 2: UPDATES`n"
    Updates
    RevertSettingMessage
} #function

function Stage3 {
    Write-Output "STAGE 3: REVERT SETTINGS1n"
    RemoveModules
    UntrustPSGallery
    UndefinedPolicy
}

function Stage4 {
    Write-Output "FINAL STAGE: DEPLOYMENT`n"
    LocalAccountRemoval
    #DeployKey
    #CheckWindowsLicense
    CheckSysprep
    #OOBE
}

function ReadyMessage {
    Write-Output "You are now ready to install updates."
    Start-Sleep -Seconds 5
    Clear-Host

}

function RevertSettingMessage {
    Write-Output "Preparing to revert all modified settings back to its original configuration."
    Start-Sleep -seconds 5
    Clear-Host
}

# TODO: This prerequisite check requires Windows PowerShell v5. This function will not work on later versions.
function Deploy {
    [CmdletBinding()]
    Param()

    $EP = (Get-ExecutionPolicy -Scope Process) -contains "Bypass"
    $NuGet = (Get-PackageProvider |  Where-Object {$_.name -eq "Nuget"}).name -contains "NuGet"
    $PSGallery = (Get-PSRepository -name PSGallery).name -eq "PSGallery"
    $InstallPolicy = (Get-PSRepository -Name PSGallery | Where-Object {$_.InstallationPolicy -contains "Trusted"}).InstallationPolicy

    Write-Verbose -Message "Checks for an Internet connection before running the script"
    Write-Output "Checking for Internet connectivity...."
    Start-sleep 5

    while ((Test-Connection 3rtechnology.com -Count 1 -ErrorAction SilentlyContinue).ResponseTime -lt 0) {
        Write-Warning -Message "No Internet connection. Please double check your network configuration. Retrying..."
        start-sleep -seconds 5
    } #while

    Write-Host "Internet connection established!" -ForegroundColor Green
    Start-sleep -Seconds 5
    Clear-Host

    Write-Verbose -Message "Checks if the script was already launched previously."
    Write-Output "Initializing script...`n"
    Start-sleep -Seconds 3
    if ($EP -eq "Bypass" -and $NuGet -eq $true -and $PSGallery -eq $true -and $InstallPolicy -eq "Trusted") {
        Write-Output "Script detected that the settings were already modified. Importing the required modules..."
        Start-Sleep -Seconds 2
        Import-Module -Name PSWindowsUpdate
        Import-Module -Name PendingReboot
        Write-Output "Modules imported.`n"
        Get-Module -Name PSWindowsUpdate,PendingReboot
        Start-sleep -Seconds 2
        ReadyMessage
        Stage2
        Stage3
        Stage4
    } else {
        Write-Verbose -Message "Initialize the script if it's the first time."
        Stage1
        Stage2
        Stage3
        Stage4
    }
}

Deploy

# Delete the script once it is done.
Write-Output "`nScript complete! This script will self-destruct in 3 seconds."
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

