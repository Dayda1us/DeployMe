#####################################################################################
#                                                                                   #
#                          WINDOWS AUTO DEPLOYMENT (v3.0)                           #
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
Write-Output "#               WINDOWS AUTOMATED DEPLOYMENT SCRIPT v3.0              #"
Write-Output "#                              12-1-2023                              #"
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
    [int[]]$numbers = (1, 2, 3, 4)

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
        { $SelectedNumber -eq $numbers[3] } {
            Write-Output 'The script has detected that the required cmdlets were reverted back to its original settings. Launching KeyDeploy.'
            Start-Sleep -Seconds 2
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
        Write-Verbose -Message "[BEGIN] Running an Internet connectivity check for $ENV:ComputerName"
        Write-Output "Checking for Internet connectivity...."
    } #BEGIN
    PROCESS {
        # Company Website
        $TestWebsite = "3RTechnology.com"

        # If there is no Internet connection, display an error until an Internet connection is found.
        Write-Verbose -Message "[PROCESS] Checking if $ENV:ComputerName can ping to $TestWebsite"
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
        $ComputerName = $env:COMPUTERNAME

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
                exit
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
                exit
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


function Register-MicrosoftKey {
    [CmdletBinding()]
    Param()
    BEGIN {
        if ((Test-Path -Path "$env:WINDIR\MARFO_SCRIPTS\") -eq $True) {
            $Title = 'Key Deploy'
            $Description = "Please make sure you're connected to the Key Deploy server at the deployment station. Would you like to launch KeyDeploy now?"
            $Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Launch Key Deploy."
            $No = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Do not launch Key Deploy at this time. This option will open the KeyDeploy directory."
            $Shutdown = New-Object System.Management.Automation.Host.ChoiceDescription "&Shutdown", "Shutdown the PC. Use this option if you're deploying a desktop."
            $Options = [System.Management.Automation.Host.ChoiceDescription[]]($Yes, $No, $Shutdown)
            $Default = 1    # 0 = Yes, 1 = No, 2 = Shutdown
    
            do {
                $KDResponse = $Host.UI.PromptForChoice($Title, $Description, $Options, $Default)
                if ($KDResponse -eq 0) {
                    #Yes
                    return 0 | Out-Null
                }
                elseif ($KDResponse -eq 2) {
                    #Shutdown PC
                    return 2 | Out-Null
                } #if/elseif ($KDResponse -eq 0)
            } until ($KDResponse -eq 1) #do/while
        } else {
            $KDResponse = -1
        }#if/else ((Test-Path -Path "$env:WINDIR\MARFO_SCRIPTS\") -eq $True)
    } #BEGIN
    PROCESS {
        switch ($KDResponse) {
            { $KDResponse -eq 0 } {
                #Yes
                Write-Output "Opening Key Deploy..."
                if ((Test-Path -Path "$env:WINDIR\MARFO_SCRIPTS\Startup\DTStartup.exe") -eq $true) {
                    try {
                        Invoke-Item -Path "$env:WINDIR\MARFO_SCRIPTS\Startup\DTStartup.exe"
                        $Process = 'DTStartup'
                        Write-Output "Key Deploy opened."
                        do {
                            start-sleep -Seconds 1
                        } while ((Get-Process -name $Process -EA SilentlyContinue).name -contains $Process) #dowhile
                    }
                    catch {
                        Write-Warning 'An error has occurred that could not be resolved. Please open Key Deploy manually.'
                        Write-Host $_ -ForegroundColor Red
                        $KDResponse = 1
                    } #try/catch
                } else {
                    $KDResponse = -1
                }#if ((Test-Path -Path "$env:WINDIR\MARFO_SCRIPTS\Startup\DTStartup.exe") -eq $true)

            } #{$KDResponse -eq 0}
            { $KDResponse -eq 2 } {
                #Shutdown PC
                Write-Warning 'Shutting down using Sysprep audit mode...'
                if ((Test-Path -Path "$ENV:WINDIR\SYSTEM32\SYSPREP\SYSPREP.exe") -eq $true) {
                    Set-Location "$ENV:WINDIR\SYSTEM32\SYSPREP\"
                    if ((Get-Process).ProcessName -contains 'sysprep') {
                        Stop-Process -Name sysprep
                        Start-sleep -Seconds 1
                        Invoke-Command -ScriptBlock { .\sysprep.exe /audit /shutdown }
                    }
                    else {
                        Invoke-Command -ScriptBlock { .\sysprep.exe /audit /shutdown }
                    } #if/else ((Get-Process).ProcessName -contains 'sysprep')

                } #if (Test-Path -Path "$ENV:WINDIR\SYSTEM32\SYSPREP\SYSPREP.exe" -eq $true)
                return 2 | Out-Null
            } #{$KDResponse -eq 2}
            default {
                # if no return answer is given, default answer is "No".
                return 1 | Out-Null
            } #default
        } #switch ($KDResponse)
    }# PROCESS
    END {
        switch ($KDResponse) {
            { $KDResponse -eq 0 } { #Yes
                Write-Host 'The operation was successful.' -ForegroundColor Green
                Write-Output "`nMake sure to leave a square holographic Microsoft Authorized Refurbisher sticker on the bottom of the unit, or as close to the original Windows sticker as possible."
                Write-Output "If this is a citzenship PC, only put a Microsoft Office for Citizenship key sticker. Citizenship PCs does not get a holographic sticker.`n"
                Write-Warning "Please make sure to report the key to the MDOS Smart Client as required under the Microsoft Authorized Refurbisher program."
                Start-Sleep -Seconds 2
            } #{$KDResponse -eq 0}
            { $KDResponse -eq 1 } { #No
                Write-Output 'OK! Skipping product key deployment'
                if ((Test-Path -Path "$env:WINDIR\MARFO_SCRIPTS\Startup\") -eq $true) {
                    Invoke-Item -Path "$env:WINDIR\MARFO_SCRIPTS\Startup\"
                } #if ((Test-Path -Path "$env:WINDIR\MARFO_SCRIPTS\Startup\") -eq $true)
            } #$KDResponse -eq 1
            { $KDResponse -eq 2 } { #Shutdown PC
                Write-Output 'PC currently shutting down.'
                start-sleep -Seconds 1
                exit
            } #{$KDResponse -eq 2}
            default { #If KeyDeploy is not found
                Write-Warning "KeyDeploy directory does not exist! Skipping product key deployment."
                Start-sleep 2
            } #default
        } #switch
    }# END
} #function Register-MicrosoftKey

###########################
# INSTALL PSWINDOWSUPDATE #
###########################

# Checks if NuGet is installed on the computer.
function Get-Nuget {
    [CmdletBinding()]
    Param()

    BEGIN {
        Write-Verbose -Message "Checking if NuGet package provider is installed on $env:COMPUTERNAME"
        $NuGet = (Get-PackageProvider |  Where-Object { $_.name -eq "Nuget" }).name -contains "NuGet"
        Write-Output "Checking for NuGet..."
    } #BEGIN

    PROCESS {
        if ($NuGet -eq $false) {
            Write-Warning -Message "NuGet is not installed."
            Write-Output 'Installing NuGet...'
            start-sleep -Seconds 5
            try {
                Write-Verbose -Message "Installing NuGet on $env:COMPUTERNAME"
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
        Write-Verbose -Message "Verify if NuGet is installed on $env:COMPUTERNAME"
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
            $Module = (Get-InstalledModule -Name $PSWU -EA SilentlyContinue).name -contains 'PSWindowsUpdate'
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
                exit
            }#if
        }
        catch [System.Management.Automation.CommandNotFoundException] {
            Write-Host $_.Exception.Message
            Write-Warning "A fatal error has occurred. This may be caused by the PSWindowsUpdate module not being imported."
            Write-Output "`nRestarting script..."
            Start-Sleep -Seconds -5
            if (Test-Path -Path Invoke-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat" -eq $true) {
                Invoke-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat"
            } #if (Test-Path -Path Invoke-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat" -eq $true)
            exit
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
        Write-Output "Retrieving previously created local account: $Account"
    }#BEGIN
    PROCESS {
        if (-not((Get-LocalUser).name -eq $Account)) {
            Write-Warning "$Account account doesnt exist!`n"
        } else {
            try {
                Remove-LocalUser -Name $Account -EA Stop
                Write-Output "`n$Account removed!"
            } catch {
                Write-Host $_ -ForegroundColor Red
                Write-Warning "An error has occurred that could not be resolved. Please remove the account manually."
                Start-Process "ms-settings:otherusers"
            }#try/catch
        } #if/else (-not((Get-LocalUser).name -eq $Account))
    }#PROCESS
    END {}#END
} #function Remove-RefurbAccount

# Start the script by setting the correct date and time. Then install the PSWindowsUpdate to begin retrieving updates via PowerShell.
function Start-Script {
    Write-Output "STAGE 1: RETRIEVING THE REQUIRED MODULE`n"
    # Verify the date and time
    Sync-Time -Timezone 'Pacific Standard Time'

    # Install PSWindowsUpdate
    Get-Nuget
    Set-PSGallery -InstallationPolicy 'Trusted'
    Install-PSWindowsUpdate
    Set-Message -Message 1
} #function Stage1

# Accept, Download, Install, and Reboot updates using PSWindowsUpdate.
function Get-Update {
    Write-Output "STAGE 2: UPDATES`n"
    Get-MicrosoftUpdate
} #function Stage2

function Deploy-Computer {
    Write-Output "FINAL STAGE: DEPLOYMENT`n"
    Set-PSGallery -InstallationPolicy 'Untrusted'
    Remove-RefurbAccount
    Register-MicrosoftKey
} #function Stage3

function Initialize-AutoDeploy {
    [CmdletBinding()]
    Param()
    
    BEGIN {
        # Test for internet connectivity before running the script.
        Test-InternetConnection
    } #BEGIN

    PROCESS {
        Write-Verbose -Message "Checking if this script was previously ran on $ENV:COMPUTERNAME"
        Write-Output "Initializing script...`n"
        $PSWU = (Get-InstalledModule).name -contains 'PSWindowsUpdate'
        Start-Sleep -Seconds 2
        
        if ($PSWU -eq $true) {
            Write-Output "The script has detected PSWindowsUpdate has already been installed. Importing the PSWindowsUpdate module..."
            Start-Sleep -Seconds 2
            try {
                Import-Module 'PSWindowsUpdate' -EA Stop
                $PSWUModule = (Get-Module).Name -contains 'PSWindowsUpdate'
                if ($PSWUModule -eq $true) {
                    Write-Output 'Module imported'
                    Get-Module
                } #if ($PSWUModule -eq $true)
            }
            catch {
                Write-Warning 'An error occurred that could not be resolved.'
                Write-Host $_ -ForegroundColor Red
                Write-Warning 'Restarting script...'
                Start-sleep 2
                if (Test-Path -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat" -eq $true) {
                    Invoke-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat"
                } #if (Test-Path -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat" -eq $true)
                exit
            } #try/catch
    
            Write-Verbose -Message "$env:COMPUTERNAME is checking for updates."
            Write-Output "`nChecking for updates..."
            #$PSGallery = (Get-PSRepository -name PSGallery).name -eq "PSGallery"
            $InstallPolicy = (Get-PSRepository -Name PSGallery).InstallationPolicy
            $GWU = (Get-WUList).Size

            switch ($GWU) {
                # If the computer is up to date, but the PSGallery is set to "Trusted".
                { -not($GWU -gt 0) -and $InstallPolicy -eq "Trusted" } {
                    Set-Message -Message 2
                    Deploy-Computer
                } #-not($GWU -gt 0) -and $PSGallery -eq $false -and $InstallPolicy -eq "Untrusted"

                # If the computer is up to date, and PSGallery is set to "Untrusted". Move on to KeyDeploy.
                { -not($GWU -gt 0) -and -not($InstallPolicy -eq "Trusted") } {
                    Set-Message -Message 4
                    Register-MicrosoftKey
                } #-not($GWU -gt 0) -and -not($InstallPolicy -eq "Trusted")

                #If you still have updates to install.
                default {  
                    Set-Message -Message 3
                    Get-Update
                    Deploy-Computer
                } #default
            } #switch ($GWU)
        } #if ($NuGet -eq $true -and $PSGallery -eq $true -and $InstallPolicy -eq "Trusted")
        else {
            Write-Verbose -Message "Initialize the script for the first time"
            Clear-Host
            Start-Script
            Get-Update
            Deploy-Computer
        } #if/else if ($PSWU -eq $true)
    } #PROCESS
    
    END {} #END
}# function Initialize-AutoDeploy

Initialize-AutoDeploy

# Delete the script once it is done.
Write-Output "`nScript complete! This script will self-destruct in 3 seconds."
3..1 | ForEach-Object {
    If ($_ -gt 1) {
        "$_ seconds"
    }
    Else {
        "$_ second"
    }
    Start-Sleep -Seconds 1
} #5..1 | ForEach-Object
Write-Output "Script deleted!"
Invoke-Expression 'cmd /c start powershell -Command {Write-Output "Uninstalling PSWindowsUpdate..." ; Uninstall-Module -Name PSWindowsUpdate}'
Remove-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat" -Force
Remove-Item -Path $MyInvocation.MyCommand.Source -Force

