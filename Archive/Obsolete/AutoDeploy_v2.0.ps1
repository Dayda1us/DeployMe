#####################################################################################
#                                                                                   #
#                          WINDOWS AUTO DEPLOYMENT (v2.0)                           #
#                                                                                   #
#       Leverages PSWindowsUpdate to install drivers and updates                    #
#       and deploy Microsoft Windows product key for refurbish PCs                  #
#       via Keydeploy. READY FOR USE IN PRODUCTION PCs.                             #
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
Write-Output "#               WINDOWS AUTOMATED DEPLOYMENT SCRIPT v2.0              #"
Write-Output "#                                                                     #"
Write-Output "#                      DEVELOPED BY CHARLES THAI                      #"
Write-Output "#######################################################################`n"
Start-Sleep -seconds 3
Clear-Host

function Set-Message {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [int]$Message
    )

    $SelectedNumber = $Message
    [int[]]$numbers = (1,2,3)

    switch ($Number) {
        {$SelectedNumber -eq $numbers[0]} {
            Write-Output "You are now ready to install updates"
            Start-Sleep -Seconds 5
            Clear-Host
        }
        {$SelectedNumber -eq $numbers[1]} {
            Write-Host "`nYour PC is up to date" -ForegroundColor Green
            Write-Output "Preparing for deployment..."
            Start-Sleep -seconds 5
            Clear-Host
        }
        {$SelectedNumber -eq $numbers[2]} {
            Write-Output "`nYour PC has updates to install."
            Start-sleep -Seconds 2
            Clear-Host
        }
        default {
            Write-Warning "Invalid number. Valid numbers are $numbers"
        }
    } #switch
}#function

###########################
# INSTALL PSWINDOWSUPDATE #
###########################

# Checks if NuGet is installed on the computer.
function Get-Nuget {
    $nuget = (Get-PackageProvider |  Where-Object {$_.name -eq "Nuget"}).name -contains "NuGet"
    Write-Output "Checking for NuGet..."
    Start-Sleep -Seconds 5

    if ($nuget -eq $true) {
        Write-Output "NuGet is already installed!`n"
        Get-PackageProvider
    } else {
        Write-Output "NuGet not installed. Installing NuGet..."
        Install-PackageProvider -name NuGet -Force -ForceBootstrap

        Write-Output "`nNuGet Installed. Importing NuGet..."
        Import-PackageProvider -name Nuget
        Write-Output "NuGet Imported!`n"
    } #if
    $newline
} #function

# Set PSGallery installation to either trusted or untrusted.
function Set-PSGallery {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('Trusted','Untrusted')]
        [String]$InstallationPolicy
    )

    BEGIN {
        $Policy = $InstallationPolicy
        $PSGallery = (Get-PSRepository -Name PSGallery).InstallationPolicy
        $RepositoryTable = @('Name', `
                        @{l="Source Location";e={$_.SourceLocation}}, `
                        'Trusted', `
                        'Registered', `
                        'InstallationPolicy')

    } #BEGIN
    PROCESS {
        switch ($InstallPolicy) {
            {$Policy -contains 'Trusted'} {
                if ($PSGallery -contains 'Trusted') {
                    Write-Output "PSGallery Installation Policy is already set to $Policy"
                    Get-PSRepository -Name PSGallery | Format-Table $RepositoryTable
                } Else {
                    Write-Output 'PSGallery Installation Policy set to Trusted'
                    Set-PSRepository -Name PSGallery -InstallationPolicy $Policy
                    Get-PSRepository -Name PSGallery | Format-Table $RepositoryTable
                }
            }
            {$Policy -contains 'Untrusted'} {
                if ($PSGallery -contains 'Untrusted') {
                    Write-Output "PSGallery Installation Policy is already set to $Policy"
                    Get-PSRepository -Name PSGallery | Format-Table $RepositoryTable
                } else {
                    Write-Output 'PSGallery Installation Policy set to Untrusted'
                    Set-PSRepository -Name PSGallery -InstallationPolicy $Policy
                    Get-PSRepository -Name PSGallery | Format-Table Name,@{l="Source Location";e={$_.SourceLocation}},Trusted,Registered,InstallationPolicy
                }
            } 
            default {
                Write-Host -ForegroundColor Red "An error has occurred:"$_.Exception.Message
            }
        }#switch
    } #PROCESS
    END {} #END
} #function

# Installs PSWindowsUpdate and imports the module.
function Install-PSWindowsUpdate {
    [CmdletBinding()]
    Param()

    BEGIN {
        $WU = 'PSWindowsUpdate'
        Write-Output "Checking for PSWindowsUpdate..."
    }#BEGIN

    PROCESS {
        try {
            $Module = (Get-InstalledModule -Name $WU -EA Continue).name -contains 'PSWindowsUpdate'
            if ($Module -eq $True) {
                $Import = (Get-Module -Name PSWindowsUpdate).name -contains "PSWindowsUpdate"
                Write-Output "$WU is already installed. Checking if module is imported..."
                if ($Import -eq $true) {
                    Write-Output 'Module is already imported'
                    Get-Module -Name PSWindowsUpdate
                } else {
                    Import-Module -Name PSWindowsUpdate
                    Write-Host -ForegroundColor Green "`nImport complete!`n"
                    Get-Module -Name PSWindowsUpdate
                }
            } else {
                Write-Warning "$WU is not installed. Installing PSWindowsUpdate..."
                Install-Module -Name PSWindowsUpdate -Force
                Write-Output "$WU installed. Importing module..."
                Import-Module -Name PSWindowsUpdate
                Write-Host -ForegroundColor Green "`nImport complete!`n"
            }#if PSWindowsUpdate
        } catch [System.Management.Automation.ActionPreferenceStopException] {
            Write-Host "$_" -ForegroundColor Red
        } catch {
            Write-Warning "An error has occurred:"$_.Exception.Message
            break
        }#try/catch
    }#PROCESS

    END {} #END
} #function

###########################
#    CHECK FOR UPDATES    #
###########################
function Get-MicrosoftUpdate {
    [CmdletBinding()]
    Param()

    BEGIN {
        Write-Output "CHECKING FOR UPDATES"
    } #BEGIN
    PROCESS {
        while ((Get-WUList).Size -gt 0) {
            Get-WUList -AcceptAll -Install -AutoReboot | Format-List Title,KB,Size,Status,RebootRequired
        } #while

        $WUReboot = Get-WURebootStatus -Silent
        if (($WUReboot -eq $true)) {
            Write-Output 'One or more updates require a reboot.'
            Start-sleep -Seconds 1
            break
        }#if
    } #PROCESS
    END {
        Set-Message -Message 2
    } #END
} #function

################
#  DEPLOYMENT  #
################

# Removes the Refurb account.
function Remove-RefurbAccount {
    [CmdletBinding()]
    Param()

    BEGIN {
        $Account = 'Refurb'
        Write-Output "Retrieving previously created local account: $account"
        Start-Sleep -Seconds 2
    }#BEGIN
    PROCESS {
        try {
            Remove-LocalUser -Name $Account -EA Stop
            Get-LocalUser
            Write-Output "`n$Account removed!"
        } 
        catch [Microsoft.PowerShell.Commands.AccessDeniedException]  {
            Write-Warning 'This cmdlet requires elevated privileges.'
        } 
        catch {
            Write-Warning "$Account doesn't exist!"
        }#try/catch
    }#PROCESS
    END {}#END
} #Remove-RefurbAccount

# Opens/Terminates Sysprep
function Get-Sysprep {
    [CmdletBinding()]
    Param(
        [switch]$Terminate
    )
    BEGIN {
        $Process = "Sysprep"
        $ProcessOpen = ((Get-Process -Name $Process -EA SilentlyContinue).ProcessName -eq $Process)
    }#BEGIN
    PROCESS {
        try {
            if ($Terminate) {
                Write-Output "Terminating $Process..."
                Start-sleep -Seconds 2
                Stop-Process -ProcessName $Process -EA Stop
                Write-Host "$process terminated." -ForegroundColor Green
            } elseif ($ProcessOpen -eq $true) {
                Write-Output "$Process is already opened!"
            } else {
                Set-Location $env:WINDIR/System32/Sysprep
                Start-Process $Process
            }#if/else
        }#try
        catch [System.Management.Automation.ActionPreferenceStopException] {
            if (!((Get-Process -Name $Process -EA SilentlyContinue).name -eq "$Process")) {
                Write-Warning "$Process is not opened"
            } elseif ($Terminate) {
                Write-Warning 'This parameter requires an elevated Windows PowerShell console.'           
            }#if/else
        }#catch
    }#PROCESS
    END{} #END
} #function

#TODO: Get KeyDeploy working
function Deploy-WindowsRefurbKey {
    [CmdletBinding()]
    Param()

    BEGIN {
        Write-Output "This will launch KeyDeploy. If you are deploying a desktop, please press ENTER once followed by input 'Y' to shutdown the computer.`n"
        $AppPrompt = Read-Host 'Would you like to launch KeyDeploy now? (Y/N) [Default is N if no input]'
    } #BEGIN
    PROCESS {
        if ($AppPrompt -match 'Y') {
            #Set-Location $env:WINDIR/MAFRO_SCRIPTS/ -EA SilentlyContinue
            $Process = "KeyDeploy"
            Write-Output "Launching $process..."
            Start-Process $Process
            do {
                Write-Output "$Process is open"
                start-sleep -Seconds 5
            } while ((Get-Process -name $Process -EA SilentlyContinue).name -contains $Process) #dowhile
        } else {
            $ShutDownPrompt = Read-Host 'Would you like to shut down this PC? (Y/N) [Default is N if no input]'
            if ($ShutDownPrompt -match 'Y') {
                Write-Output 'Shutting down PC...'
                start-sleep -seconds 2
                Stop-Computer -Force
                break
            }
        }
    } #PROCESS
    END{
        if ($ShutDownPrompt -match 'N' -or -not($ShutDownPrompt)) {
            Write-Output 'OK! Skipping product key deployment'
        }
    } #END
} #function

#TODO: Check if Windows license is installed. Prompt the user if they would like to launch KeyDeploy.
function Get-WindowsLicense {
    [CmdletBinding()]
    Param()
    Write-Output "Check for Windows activation status..."
    if (!(Get-CimInstance SoftwareLicensingProduct).LicenseStatus -eq 0) {
        Write-Host "Your Windows activation key is licensed!" -ForegroundColor Green
    } else {
        Write-Host "Your Windows activation key is not licensed!" -ForegroundColor Red
        start-sleep -Seconds 2
        break
    }#if
}#function

# Sysprep the machine
function Initialize-OOBE {
    Write-Output "`nPreparing Sysprep..."
    Start-sleep 5
    Set-Location $env:SystemRoot\System32\Sysprep
    .\sysprep.exe /oobe
    shutdown.exe /s /t 10
}

function Stage1 {
    Write-Output "STAGE 1: RETRIEVING THE REQUIRED MODULE`n"
    Get-Nuget
    Set-PSGallery -InstallationPolicy 'Trusted'
    Install-PSWindowsUpdate
    Set-Message -Message 1
} #function

function Stage2 {
    Write-Output "STAGE 2: UPDATES`n"
    Get-MicrosoftUpdate
} #function

function Stage3 {
    Write-Output "FINAL STAGE: DEPLOYMENT`n"
    Set-PSGallery -InstallationPolicy 'Untrusted'
    Remove-RefurbAccount

    # TODO: To be implemented.
    #Get-Sysprep -Terminate
    #Deploy-WindowsRefurbKey
    #CheckWindowsLicense
    #OOBE
}

function Initialize-AutoDeploy {
    [CmdletBinding()]
    Param()
    
    BEGIN {
        Write-Verbose -Message "Checks for an Internet connectivity before running the script"
        Write-Output "Checking for Internet connectivity...."
        Start-sleep 2

        # THIS TEST WILL ONLY WORK ON WINDOWS POWERSHELL v5.
        while ((Test-Connection 3rtechnology.com -Count 1).ResponseTime -lt 0) {
            Write-Warning -Message "No Internet connection. Please double check your network configuration. Retrying..."
            start-sleep -seconds 5
        } #while

        Write-Host "Internet connection established!" -ForegroundColor Green
        Start-sleep -Seconds 5
        Clear-Host
    } #BEGIN

    PROCESS {
        $WU = 'PSWindowsUpdate'
        $NuGet = (Get-PackageProvider |  Where-Object {$_.name -eq "Nuget"}).name -contains "NuGet"
        $PSGallery = (Get-PSRepository -name PSGallery).name -eq "PSGallery"
        $InstallPolicy = (Get-PSRepository -Name PSGallery | Where-Object {$_.InstallationPolicy -contains "Trusted"}).InstallationPolicy
    
        Write-Verbose -Message "Checking if the script has already been started"
        Write-Output "Initializing script...`n"
        Start-sleep -Seconds 2
        if ($NuGet -eq $true -and $PSGallery -eq $true -and $InstallPolicy -eq "Trusted") {
            Write-Output "The script has detected that the settings were already modified. Importing the PSWindowsUpdate module..."
            Start-Sleep -Seconds 2
            try {
                $Module = (Get-InstalledModule -Name $WU -EA Continue).name -contains $WU
                if ($Module -eq $true) {
                    Import-Module -Name $WU -EA Stop
                    Write-Output "Module imported.`n"
                    Get-Module -Name $WU    
                } else {
                    Write-Host -ForegroundColor Red $_.Exception.Message
                    Write-Warning 'PSWindowsUpdate not installed. Installing module...'
                    Install-Module -Name $WU -Force
                    Write-Output 'Importing module...'
                    Import-Module -Name $WU
                    Write-Host -ForegroundColor Green 'PSWindowsUpdate imported.'
                    Get-Module
                    start-sleep -seconds 2
                }
            }
            catch {
                Write-Output "An error has occurred:" $_.Exception.Message
                Write-Output 'Aborting script...'
                Start-sleep -seconds 2
                break
            } #try/catch
    
            Write-Verbose -Message "Computer checking for updates."
            Write-Output "`nChecking for updates..."
            $GWU = (Get-WUList).Size
            if ($GWU -gt 0) {
                Set-Message -Message 3
                Stage2
                Stage3
            } else {
                Set-Message -Message 2
                Stage3
            } #if/else
        } else {
            Write-Verbose -Message "Initialize the script for the first time"
            Clear-Host
            Stage1
            Stage2
            Stage3
        } #if/else
    } #PROCESS
    
    END {}
}# Initialize-AutoDeploy

Initialize-AutoDeploy

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
Invoke-Expression 'cmd /c start powershell -Command {Write-Output "Uninstalling PSWindowsUpdate..." ; sleep 3 ; Uninstall-Module -Name PSWindowsUpdate}'
Remove-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat" -Force
Remove-Item -Path $MyInvocation.MyCommand.Source -Force

