#####################################################################################
#                                                                                   #
#                          WINDOWS AUTO DEPLOYMENT (v2.5)                           #
#                                                                                   #
#       Leverages PSWindowsUpdate to install drivers and updates                    #
#       and deploy Microsoft Windows product key for refurbish PCs                  #
#       via Keydeploy. READY FOR USE IN PRODUCTION PCs.                             #
#                                                                                   #
#                           Developed by Charles Thai                               #
#####################################################################################


# This script must be started with elevated user rights.
#Requires -RunAsAdministrator

Clear-Host
Write-Host " _____ ____    _____ _____ ____ _   _ _   _  ___  _     ___   ______   __" -ForegroundColor Green
Write-Host "|___ /|  _ \  |_   _| ____/ ___| | | | \ | |/ _ \| |   / _ \ / ___\ \ / /" -ForegroundColor Green
Write-Host "  |_ \| |_) |   | | |  _|| |   | |_| |  \| | | | | |  | | | | |  _ \ V / " -ForegroundColor Green
Write-Host " ___) |  _ <    | | | |__| |___|  _  | |\  | |_| | |__| |_| | |_| | | |  " -ForegroundColor Green
Write-Host "|____/|_| \_\   |_| |_____\____|_| |_|_| \_|\___/|_____\___/ \____| |_|`n  " -ForegroundColor Green
Write-Output "#######################################################################"
Write-Output "#               WINDOWS AUTOMATED DEPLOYMENT SCRIPT v2.5              #"
Write-Output "#                                                                     #"
Write-Output "#                      DEVELOPED BY CHARLES THAI                      #"
Write-Output "#######################################################################`n"
Start-Sleep -seconds 3
Clear-Host

function Set-Message {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [int]$Message
    )

    $SelectedNumber = $Message
    [int[]]$numbers = (1, 2, 3)

    switch ($Number) {
        { $SelectedNumber -eq $numbers[0] } {
            Write-Output "You are now ready to install updates"
            Start-Sleep -Seconds 5
            Clear-Host
        }
        { $SelectedNumber -eq $numbers[1] } {
            Write-Host "`nYour PC is up to date" -ForegroundColor Green
            Write-Output "Preparing for deployment..."
            Start-Sleep -seconds 5
            Clear-Host
        }
        { $SelectedNumber -eq $numbers[2] } {
            Write-Output "`nYour PC has updates to install."
            Start-sleep -Seconds 2
            Clear-Host
        }
        default {
            Write-Warning "Invalid message number. Valid numbers are $numbers"
        }
    } #switch
}#function Set-Message

function Test-InternetConnection {
    [CmdletBinding()]
    Param()

    BEGIN {
        Write-Verbose -Message "[BEGIN] Running an Internet connectivity check for $((Get-CimInstance Win32_ComputerSystem).Name)"
        Write-Output "Checking for Internet connectivity...."
    } #BEGIN
    PROCESS {
        # Company Website
        $TestWebsite = "3RTechnology.com"

        # If there is no Internet connection, display an error until an Internet connection is found.
        Write-Verbose -Message "[PROCESS] Checking if $((Get-CimInstance -ClassName Win32_ComputerSystem).Name) can ping to $TestWebsite"
        while (-not((Test-Connection $TestWebsite -Quiet -Count 1) -eq $true)) {
            Write-Warning "No Internet connection found. Please double check your network configuration. Retrying..."
            Start-Sleep -Seconds 5
        }
    }#PROCESS
    END {
        Write-Verbose -Message "[END] $((Get-CimInstance -ClassName Win32_ComputerSystem).Name) successfully pings $TestWebsite"
        Write-Host "Internet connection established!" -ForegroundColor Green
        Start-sleep -Seconds 5
        Clear-Host
    } #END 
}#function Test-InternetConnection

# Sync the date and timezone if the computer was set incorrectly.
function Sync-Time {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [String]$Timezone
    )

    BEGIN {
        # Grab local computer name.
        $ComputerName = (Get-Ciminstance -ClassName Win32_ComputerSystem).Name

        Write-Verbose "Retrieving the timezone and preferred timezone."
        Write-Output 'Checking the current timezone...'
        # Checks the current timezone of the computer
        $CurrentTimeZone = (Get-TimeZone).Id

        # The preferred timezone.
        $PreferredTimeZone = (Get-TimeZone -ID $Timezone).Id

    } #BEGIN
    PROCESS {
        # Set the preferred Timezone if current timezone is set incorrectly.
        Write-Verbose "[BEGIN] Verifying the timezone for $ComputerName"
        if ($CurrentTimeZone -eq $PreferredTimeZone) {
            Write-Output "Timezone is already set to $PreferredTimeZone`n"
            Get-TimeZone
        }
        else {
            Set-TimeZone -ID $PreferredTimeZone
            Write-Output "Timezone changed to $PreferredTimeZone`n"
            Get-TimeZone
        } #if/else

        # Name of the Windows Time service
        $WindowsTime = 'W32Time'

        Write-Output "Checking if $WindowsTime is running..."
        start-sleep 2
        if ((Get-Service -Name $WindowsTime).Status -eq 'Running') {
            Write-Output "$WindowsTime is already running. Syncing local time..."
            Get-Service -Name W32Time
            try {
                Write-Verbose "[PROCESS] Syncing the local time using 'w32tm /resync' on $ComputerName"
                Write-Output "Syncing local time on $ComputerName"
                start-sleep -Seconds 2
                Invoke-Command -ScriptBlock { w32tm.exe /resync } -EA Stop
                Get-Date
            }
            catch {
                Write-Warning "An error has occurred that could not be resolved."
                Write-Host $_ -ForegroundColor Red

                # Restart the script if an error occurs
                Write-Output 'Restarting script...'
                Start-Sleep -Seconds 5
                Invoke-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat"
                break
            } #try/catch

        }
        else {
            Write-Output "Starting $WindowsTime..."
            Start-Sleep -seconds 2
            try {
                Write-Verbose "[PROCESS] Starting $WindowsTime on $ComputerName"
                Start-Service -Name $WindowsTime -EA Stop
                # If "W32Time" started successfully, run the "w32tm /resync" command.
                if ((Get-Service -Name $WindowsTime).Status -eq 'Running') {
                    Write-Verbose "[PROCESS] Syncing the local time using 'w32tm /resync' on $ComputerName"
                    Write-Output "Syncing local time on $ComputerName"
                    start-sleep -Seconds 2
                    Invoke-Command -ScriptBlock { w32tm.exe /resync } -EA Stop
                } #if (Get-Service -Name $WindowsTime).Status -eq 'Started')
            }
            catch {
                Write-Warning "An error has occurred that could not be resolved."
                Write-Host $_ -ForegroundColor Red

                # Restart the script if an error occurs
                Write-Output 'Restarting script...'
                Start-Sleep -Seconds 5
                Invoke-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat"
                break
            } #try/catch
        } #if/else ((Get-Service -Name $WindowsTime).Status -eq 'Running')
    } #PROCESS
    END {
        Write-Verbose "[END] Verifying that the timezone and today's date is synced."
        $CurrentTimeZone = (Get-TimeZone).Id
        if ($CurrentTimeZone -eq $PreferredTimeZone) {
            Write-Host 'The operation was successful.' -ForegroundColor Green
            start-sleep 2
        } #if ($CurrentTimeZone -eq $PreferredTimeZone)
    } #END
} #function Sync-Time

###########################
# INSTALL PSWINDOWSUPDATE #
###########################

# Checks if NuGet is installed on the computer.
function Get-Nuget {
    [CmdletBinding()]
    Param()

    BEGIN {
        Write-Verbose -Message "Checking if NuGet package provider is installed on $((Get-Ciminstance -ClassName Win32_ComputerSystem).Name)"
        $NuGet = (Get-PackageProvider |  Where-Object { $_.name -eq "Nuget" }).name -contains "NuGet"
        Write-Output "Checking for NuGet..."
    } #BEGIN

    PROCESS {
        if ($NuGet -eq $false) {
            Write-Warning -Message "NuGet is not installed."
            Write-Output 'Installing NuGet...'
            start-sleep -Seconds 5
            try {
                Write-Verbose -Message "Installing NuGet on $((Get-Ciminstance -ClassName Win32_ComputerSystem).Name)"
                Install-PackageProvider -name NuGet -Force -ForceBootstrap -EA Stop
                Write-Output "`nNuGet Installed. Importing NuGet..."
                start-sleep -Seconds 2
                Import-PackageProvider -name Nuget
            }
            catch [System.Management.Automation.ActionPreferenceStopException] {
                Write-Warning 'An error has occurred that could not be resolved.'
                Write-Host $_.Exception.Message
                
                # Restart the script if this cmdlet fails.
                Write-Warning 'Restarting script'
                start-sleep 5
                Invoke-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat"
                break
            } #try/catch
        }
        else {
            Write-Output 'NuGet is already installed on this PC. Importing NuGet...'
            Import-PackageProvider -name Nuget
        }#if/else ($NuGet -eq $false)

    } #PROCESS
    END {
        Write-Verbose -Message "Verify if NuGet is installed on $((Get-Ciminstance -ClassName Win32_ComputerSystem).Name)"
        $NuGet = (Get-PackageProvider |  Where-Object { $_.name -eq "Nuget" }).name -contains "NuGet"
        if ($NuGet -eq $true) {
            Write-Output "`nNuGet Imported!"
        } #if ($NuGet -eq $true)
    } #END
} #function Get-Nuget

# Set PSGallery installation to either trusted or untrusted.
function Set-PSGallery {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true,
            HelpMessage = "Set PSGallery to either 'Trusted' or 'Untrusted'")]
        [ValidateSet('Trusted', 'Untrusted')]
        [String]$InstallationPolicy
    )

    BEGIN {
        $Policy = $InstallationPolicy
        $PSGallery = (Get-PSRepository -Name PSGallery).InstallationPolicy
        $RepositoryTable = @('Name', `
            @{l = "Source Location"; e = { $_.SourceLocation } }, `
                'Trusted', `
                'Registered', `
                'InstallationPolicy')

    } #BEGIN
    PROCESS {
        switch ($InstallPolicy) {
            { $Policy -contains 'Trusted' } {
                if ($PSGallery -contains 'Trusted') {
                    Write-Output "PSGallery Installation Policy is already set to $Policy"
                    Get-PSRepository -Name PSGallery | Format-Table $RepositoryTable
                }
                Else {
                    Write-Output 'PSGallery Installation Policy set to Trusted'
                    Set-PSRepository -Name PSGallery -InstallationPolicy $Policy
                    Get-PSRepository -Name PSGallery | Format-Table $RepositoryTable
                }
            }
            { $Policy -contains 'Untrusted' } {
                if ($PSGallery -contains 'Untrusted') {
                    Write-Output "PSGallery Installation Policy is already set to $Policy"
                    Get-PSRepository -Name PSGallery | Format-Table $RepositoryTable
                }
                else {
                    Write-Output 'PSGallery Installation Policy set to Untrusted'
                    Set-PSRepository -Name PSGallery -InstallationPolicy $Policy
                    Get-PSRepository -Name PSGallery | Format-Table Name, @{l = "Source Location"; e = { $_.SourceLocation } }, Trusted, Registered, InstallationPolicy
                }
            } 
            default {
                Write-Warning "An error has occurred that could not be resolved."
                Write-Host $_.Exception.Message
            }
        }#switch
    } #PROCESS
    END {} #END
} #function Set-PSGallery

# Installs PSWindowsUpdate and imports the module.
function Install-PSWindowsUpdate {
    [CmdletBinding()]
    Param()

    BEGIN {
        $PSWU = 'PSWindowsUpdate'
        Write-Output "Checking for PSWindowsUpdate..."
    }#BEGIN

    PROCESS {
        try {
            $Module = (Get-InstalledModule -Name $PSWU -EA Continue).name -contains 'PSWindowsUpdate'
            if ($Module -eq $True) {
                $Import = (Get-Module -Name PSWindowsUpdate).name -contains "PSWindowsUpdate"
                Write-Output "$PSWU is already installed. Checking if module is imported..."
                if ($Import -eq $true) {
                    Write-Output 'Module is already imported'
                    Get-Module -Name $PSWU
                }
                else {
                    Import-Module -Name $PSWU
                    Write-Host -ForegroundColor Green "`nImport complete!`n"
                    Get-Module -Name $PSWU
                }
            }
            else {
                Write-Warning "$PSWU is not installed. Installing PSWindowsUpdate..."
                Install-Module -Name PSWindowsUpdate -Force
                Write-Output "$PSWU installed. Importing module..."
                Import-Module -Name PSWindowsUpdate
                Write-Host -ForegroundColor Green "`nImport complete!`n"
            }#if PSWindowsUpdate
        }
        catch [System.Management.Automation.ActionPreferenceStopException] {
            Write-Host "$_" -ForegroundColor Red
            Write-Warning 'Restarting script'
            start-sleep 5
            Invoke-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat"
            break
        }
        catch {
            Write-Warning "An error has occurred that could not be resolved"
            Write-Host $_
            Write-Warning 'Restarting script'
            start-sleep 5
            Invoke-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat"
            break
        }#try/catch
    }#PROCESS

    END {} #END
} #function Install-PSWindowsUpdate

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
        try {
            while ((Get-WUList).Size -gt 0) {
                Get-WUList -AcceptAll -Install -AutoReboot | Format-List Title, KB, Size, Status, RebootRequired
            } #while
    
            $PSWUReboot = Get-WURebootStatus -Silent
            if (($PSWUReboot -eq $true)) {
                Write-Output 'One or more updates require a reboot.'
                Start-sleep -Seconds 1
                break
            }#if
        }
        catch [System.Management.Automation.CommandNotFoundException] {
            Write-Warning "A fatal error has occurred. This may be caused by the PSWindowsUpdate module not being properly imported."
            Write-Host $_.Exception.Message
            Write-Output "`nRestarting script..."
            Start-Sleep -Seconds -5
            Invoke-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat"
            break
        } #try/catch
    } #PROCESS
    END {
        Set-Message -Message 2
    } #END
} #function Get-MicrosoftUpdate

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
    }#BEGIN
    PROCESS {
        try {
            Remove-LocalUser -Name $Account -EA Stop
            Get-LocalUser
            Write-Output "`n$Account removed!"
        } 
        catch [Microsoft.PowerShell.Commands.AccessDeniedException] {
            Write-Warning 'This cmdlet requires elevated privileges.'
        } 
        catch {
            Get-LocalUser
            Write-Warning "$Account doesn't exist!"
        }#try/catch
    }#PROCESS
    END {}#END
} #function Remove-RefurbAccount

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
            }
            elseif ($ProcessOpen -eq $true) {
                Write-Output "$Process is already opened!"
            }
            else {
                Set-Location $env:WINDIR/System32/Sysprep
                Start-Process $Process
            }#if/else
        }#try
        catch [System.Management.Automation.ActionPreferenceStopException] {
            if (!((Get-Process -Name $Process -EA SilentlyContinue).name -eq "$Process")) {
                Write-Warning "$Process is not opened"
            }
            elseif ($Terminate) {
                Write-Warning 'This parameter requires an elevated Windows PowerShell console.'           
            }#if/else
        }#catch
    }#PROCESS
    END {} #END
} #function Get-Sysprep

# Sysprep the machine
function Initialize-OOBE {
    Write-Output "`nPreparing Sysprep..."
    Start-sleep 5
    Set-Location $env:SystemRoot\System32\Sysprep
    .\sysprep.exe /oobe
    shutdown.exe /s /t 10
} #function Initialize-OOBE

function Stage1 {
    Write-Output "STAGE 1: RETRIEVING THE REQUIRED MODULE`n"
    Get-Nuget
    Set-PSGallery -InstallationPolicy 'Trusted'
    Install-PSWindowsUpdate
    Set-Message -Message 1
} #function Stage1

function Stage2 {
    Write-Output "STAGE 2: UPDATES`n"
    Get-MicrosoftUpdate
} #function Stage2

function Stage3 {
    Write-Output "FINAL STAGE: DEPLOYMENT`n"
    Set-PSGallery -InstallationPolicy 'Untrusted'
    Remove-RefurbAccount

    # TODO: To be implemented.
    #Register-MicrosoftWindowsProductKey
    #CheckWindowsLicense
} #function Stage3

function Initialize-AutoDeploy {
    [CmdletBinding()]
    Param()
    
    BEGIN {
        # Test for internet connectivity before running the script.
        Test-InternetConnection

        Write-Verbose -Message "[BEGIN] Verifying the timezone and date/time on $((Get-CimInstance Win32_ComputerSystem).Name)"
        # Verify the date and time
        Sync-Time -Timezone 'Pacific Standard Time'
    } #BEGIN

    PROCESS {
        $PSWU = 'PSWindowsUpdate'
        $NuGet = (Get-PackageProvider |  Where-Object { $_.name -eq "Nuget" }).name -contains "NuGet"
        $PSGallery = (Get-PSRepository -name PSGallery).name -eq "PSGallery"
        $InstallPolicy = (Get-PSRepository -Name PSGallery | Where-Object { $_.InstallationPolicy -contains "Trusted" }).InstallationPolicy
    
        Write-Verbose -Message "Checking if this script was previously ran on $((Get-CimInstance Win32_ComputerSystem).Name)"
        Write-Output "Initializing script...`n"
        Start-sleep -Seconds 2
        if ($NuGet -eq $true -and $PSGallery -eq $true -and $InstallPolicy -eq "Trusted") {
            Write-Output "The script has detected that the settings were already modified. Importing the PSWindowsUpdate module..."
            Start-Sleep -Seconds 2
            try {
                $Module = (Get-InstalledModule -Name $PSWU -EA Continue).name -contains $PSWU
                if ($Module -eq $true) {
                    Import-Module -Name $PSWU -EA Stop
                    Write-Output "Module imported.`n"
                    Get-Module -Name $PSWU    
                }
                else {
                    Write-Host -ForegroundColor Red $_.Exception.Message
                    Write-Warning 'PSWindowsUpdate not installed. Installing module...'
                    Install-Module -Name $PSWU -Force
                    Write-Output 'Importing module...'
                    Import-Module -Name $PSWU
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
            }
            else {
                Set-Message -Message 2
                Stage3
            }#if/else
        }
        else {
            Write-Verbose -Message "Initialize the script for the first time"
            Clear-Host
            Stage1
            Stage2
            Stage3
        } #if/else
    } #PROCESS
    
    END {
        if ((Test-Connection google.com -Count 1 -Quiet) -eq $false) {
            Write-Verbose "[END] Internet connection dropped on $((Get-CimInstance Win32_ComputerSystem).Name)"
            Write-Warning "$((Get-CimInstance Win32_ComputerSystem).Name) lost Internet connection."
            $Prompt = Read-Host "Would you like to restart the script? (Y/N) [Default is N]"
            if ($Prompt -match 'Y') {
                try {
                    Write-Output "Restarting script..."
                    Start-sleep -Seconds 1
                    Invoke-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat"
                    break
                }
                catch [System.Management.Automation.ActionPreferenceStopException] {
                    Write-Warning 'An error occurred that could not be resolved.'
                    Write-Host $_ -ForegroundColor Red
                    Write-Output 'Please start the script manually.'
                    Start-sleep 2
                    Invoke-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/"
                    break
                } #try/catch
            }
            else {
                Write-output 'You can restart the script manually by launching AutoDeployment.bat'
                Invoke-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/"
                Write-Warning 'Aborting script...'
                Start-sleep 5
                break
            }#if/else $prompt
        } #if/else Test-Connection
    }
}# function Initialize-AutoDeploy

Initialize-AutoDeploy

# Delete the script once it is done.
Write-Output "`nScript complete! This script will self-destruct in 5 seconds."
5..1 | ForEach-Object {
    If ($_ -gt 1) {
        "$_ seconds"
    }
    Else {
        "$_ second"
    }
    Start-Sleep -Seconds 1
} #5..1 | ForEach-Object
Write-Output "Script deleted!"
Invoke-Expression 'cmd /c start powershell -Command {Write-Output "Uninstalling PSWindowsUpdate..." ; sleep 3 ; Uninstall-Module -Name PSWindowsUpdate}'
Remove-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat" -Force
Remove-Item -Path $MyInvocation.MyCommand.Source -Force

