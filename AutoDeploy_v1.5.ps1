#####################################################################################
#                                                                                   #
#                          WINDOWS AUTO DEPLOYMENT (v1.5)                           #
#                                                                                   #
#       Leverages Microsoft Update provider to install all missing updates          #
#       using the PSWindowsUpdate module and deploy keys via Keydeploy.             #
#       READY FOR USE IN PRODUCTION PCs.                                            #
#                                                                                   #
#                           Developed by Charles Thai                               #
#####################################################################################


# This script must be started with elevated user rights.
#Requires -RunAsAdministrator

$newline = Write-Output "`n"

Clear-Host
Write-Host " _____ ____    _____ _____ ____ _   _ _   _  ___  _     ___   ______   __" -ForegroundColor Green
Write-Host "|___ /|  _ \  |_   _| ____/ ___| | | | \ | |/ _ \| |   / _ \ / ___\ \ / /" -ForegroundColor Green
Write-Host "  |_ \| |_) |   | | |  _|| |   | |_| |  \| | | | | |  | | | | |  _ \ V / " -ForegroundColor Green
Write-Host " ___) |  _ <    | | | |__| |___|  _  | |\  | |_| | |__| |_| | |_| | | |  " -ForegroundColor Green
Write-Host "|____/|_| \_\   |_| |_____\____|_| |_|_| \_|\___/|_____\___/ \____| |_|`n  " -ForegroundColor Green
Write-Output "#######################################################################"
Write-Output "#                  WINDOWS AUTOMATED DEPLOYMENT v1.5                  #"
Write-Output "#                         WORK IN PROGRESS                            #"
Write-Output "#                     DEVELOPED BY CHARLES THAI                       #"
Write-Output "#######################################################################`n"
Start-Sleep -seconds 3
Clear-Host


###########################
#  INSTALL REQ'D MODULES  #
###########################

# Checks if NuGet is installed on the computer.
function NuGetCheck {
    $nuget = (Get-PackageProvider |  Where-Object {$_.name -eq "Nuget"}).name -contains "NuGet"
    Write-Output "Checking if NuGet is installed on your computer..."
    Start-Sleep -Seconds 5

    if ($nuget -eq $true) {
        Write-Output "NuGet is already installed!`n"
        Get-PackageProvider
        start-sleep -seconds 2
    } else {
        Write-Output "NuGet not installed. Installing NuGet..."
        Install-PackageProvider -name NuGet -Force -ForceBootstrap

        Write-Output "`nInstalled NuGet. Importing NuGet..."
        Import-PackageProvider -name Nuget

        Write-Output "NuGet Imported!`n"
    } #if

    $newline
} #function

# Update the PSGallery (Default) repository to trusted to ensure the installed modules work properly.
function TrustPSGallery {
    Write-Output "Updating the PSGallery installation policy to Trusted"

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

# Check if PSWindowsUpdate module is installed.
function PSWinUpdateModule {
    Write-Output "Checking for PSWindowsUpdate module..."

    if ((Get-InstalledModule -Name PSWindowsUpdate).name -contains "PSWindowsUpdate" -eq $false) {
        Write-Output "PSWindowsUpdate module not installed. Installing PSWindowsUpdate..."
        Install-Module -name PSWindowsUpdate -Force
        Write-Output "PSWindowsUpdate installed. Importing PSWindowsUpdate..."
        Import-Module -name PSWindowsUpdate
    } else {
        Write-Output "PSWindowsUpdate module is already installed! Importing PSWindowsUpdate..."
        Import-Module -name PSWindowsUpdate
    } #if
    Write-Host "Import Complete!" -ForegroundColor Green
    Start-Sleep -Seconds 2
} #function

function Updates {
    Write-Output "CHECKING FOR UPDATES"
    Get-WUList -AcceptAll -Install -AutoReboot | Format-List Title,KB,Size,Status,RebootRequired

    $WUReboot = Get-WURebootStatus -Silent
    if (($WUReboot -eq $true)) {
        Write-Output "One or more updates require a reboot."
        Start-sleep -Seconds 1
        exit
    } else {
        RevertSettingMessage
        start-sleep -Seconds 3
    } #if
} #function

#####################
#  REVERT SETTINGS  #
#####################

# Remove the installed modules (PSWindowsUpdate).
function RemoveModules {
    Write-Output "Removing the installed module..."

    $UpdateModule = (("PSWindowsUpdate" | Get-Module).Name) -eq "PSWindowsUpdate"

    Start-sleep -Seconds 3
    if ($UpdateModule -eq $True) {
        "PSWindowsUpdate" | Remove-Module
        Write-Host "Installed modules removed!`n" -f Green
        Get-Module
        start-sleep -Seconds 2
    } else {
        Write-Output "The module were already removed."
        Get-Module
        Start-sleep -Seconds 2
    } #if
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

# Revert any Execution Policy to Undefined
function UndefinedPolicy {
    Write-Output "Setting any scope execution policy to Undefined..."
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
#  DEPLOYMENT  #
################

# Remove Refurb account.
# TO BE DEPRECATED.
function LocalAccountRemoval_DEPRECATED {
    $Account = "Refurb"
    Write-Output "Retrieving previously created account: $Account..."
    Start-Sleep -Seconds 2
    if ((Get-LocalUser -Name $Account).name -eq $Account) {
        Write-Output "Removing account..."
        Start-Sleep -Seconds 1
        Remove-LocalUser -Name $Account
        Write-Host "$Account account removed!`n" -ForegroundColor Green
        Get-LocalUser
    } else {
        Write-Warning "$Account account doesn't exist!"
        Write-Output "Skipping account removal"
    } #endif 
} #function

#TODO: Test this new function.
#RESULT: Tested this function on a VM, and confirm that this robust function is working.
function LocalAccountRemoval {
    $Account = "Refurb"
    Write-Output "Retrieving previously created local account: $account"
    Start-Sleep -Seconds 2
    try {
    Remove-LocalUser -Name $Account -EA Stop
    Write-Host "$Account account removed!`n" -ForegroundColor Green
    Get-LocalUser
    Start-sleep -Seconds 2
    } 
    catch {
        Write-Warning "$account account doesn't exist!"
        "Skipping local account removal"
    } #try/catch
} #function



# Checks if Sysprep is already opened
# TO BE DEPRECATED.
function CheckSysprep_DEPRECATED {
    Write-Output "`nChecking if Sysprep is already opened..."
    $CheckForSysprep = "sysprep"
    Start-Sleep -Seconds 3
    if ((Get-Process $CheckForSysprep).ProcessName -contains "sysprep") {
        Write-Output "Terminating Sysprep...`n"
        Start-sleep -Seconds 2
        Stop-Process -ProcessName $CheckForSysprep
        Write-Host "Sysprep terminated." -ForegroundColor Green
    } else {
        Write-Host "Sysprep is not opened. Skipping Sysprep check.`n" -ForegroundColor Red
    } #endif
} #function

#TODO: This this new function on a VM.
#RESULT: Tested this function on a VM, and confirm that this robust function is working.
function CheckSysprep {
    $process = "Sysprep"
    Write-Output "`nChecking for $process..."
    Start-Sleep -Seconds 3
    try {
        if ((Get-Process $process -EA Stop).ProcessName -contains $process) {
            Write-Output "Terminating $process...`n"
            Start-sleep -Seconds 3
            Stop-Process -ProcessName $process
            Write-Host "$process terminated." -ForegroundColor Green
        }
    }
    catch {
        Write-Warning "$process is not opened."
        Write-Output "Skipping $process check"
    } #try/catch
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
    Write-Output "STAGE 1: RETRIEVING THE REQUIRED MODULES`n"
    NuGetCheck
    TrustPSGallery
    PSWinUpdateModule
    ReadyMessage
} #function

function Stage2 {
    Write-Output "STAGE 2: UPDATES`n"
    Updates
} #function

function Stage3 {
    Write-Output "STAGE 3: REVERT SETTINGS`n"
    RemoveModules
    UntrustPSGallery
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
    Write-Output "You are now ready to install updates"
    Start-Sleep -Seconds 5
    Clear-Host

}

function RevertSettingMessage {
    Write-Host "`nYour PC is up to date" -ForegroundColor Green
    Write-Output "Preparing to revert all settings back to its original configuration"
    Start-Sleep -seconds 5
    Clear-Host
}

# TODO: This prerequisite check requires Windows PowerShell v5. This function will not work on later versions.
function Deploy {
    [CmdletBinding()]
    Param()

    Write-Verbose -Message "Checks for an Internet connectivity before running the script"
    Write-Output "Checking for Internet connectivity...."
    Start-sleep 5

    while ((Test-Connection 3rtechnology.com -Count 1).ResponseTime -lt 0) {
        Write-Warning -Message "No Internet connection. Please double check your network configuration. Retrying..."
        start-sleep -seconds 5
    } #while

    Write-Host "Internet connection established!" -ForegroundColor Green
    Start-sleep -Seconds 5
    Clear-Host

    $NuGet = (Get-PackageProvider |  Where-Object {$_.name -eq "Nuget"}).name -contains "NuGet"
    $PSGallery = (Get-PSRepository -name PSGallery).name -eq "PSGallery"
    $InstallPolicy = (Get-PSRepository -Name PSGallery | Where-Object {$_.InstallationPolicy -contains "Trusted"}).InstallationPolicy

    Write-Verbose -Message "Checking if the script has already been started"
    Write-Output "Initializing script...`n"
    Start-sleep -Seconds 3
    if ($NuGet -eq $true -and $PSGallery -eq $true -and $InstallPolicy -eq "Trusted") {
        Write-Output "The script has detected that the settings were already modified. Importing the required module..."
        Start-Sleep -Seconds 2
        Import-Module -Name PSWindowsUpdate

        Write-Output "Module imported.`n"

        Get-Module -Name PSWindowsUpdate

        Write-Verbose -Message "Checks if the PC has updates to install by size that is greater than 0 MB."
        Write-Output "`nChecking for updates..."
        $GWU = (Get-WUList).Size
        
        switch($GWU) {
            { $GWU -gt 0 } {
                Write-Output "`nYour PC has updates to install."
                Start-sleep -Seconds 2
                Clear-Host
                Stage2
                Stage3
                Stage4
            }
            default {
                RevertSettingMessage
                Stage3
                Stage4
            }
        }
    } else {
        Write-Verbose -Message "Initializing script for the first time"
        Clear-Host
        Stage1
        #Stage2
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
#Remove-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat" -Force
#Remove-Item -Path $MyInvocation.MyCommand.Source -Force
