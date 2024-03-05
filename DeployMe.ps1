<#

    .DESCRIPTION
        An automated script used to deploy Windows PCs with little to no user intervention.
    
    .NOTES
        This script requires elevated privileges and execution policy set to 'Bypass'

#>

# This script must be started with elevated user rights.
#Requires -RunAsAdministrator

Write-Host " 
                   ***      ***************                      
                 ***    *********           **                   
                ***   *******                                    
              ****  ******       ******************              
             ***********     +**+@%%%@****************#          
             *********                       *************       
            *********                            *+*********     
            ********                               #**********   
            *******                                  **********  
            ******                                    #********* 
            +*****                                     ***** ****
            *****                                       ****#  **
            *****                                    +#  ****   *
            +*****                                   **  ****   #
             *****                                   *+  #****   
              ****                                  ***   ****   
              *****                                 ***   ****   
                ****                               ***#   **+    
            *    ****                             ****   #***    
             +    ****                           *****   ***     
             *+     ***                         ****+    **      
              ***     *+                      ******    **       
                ***                         #******    **        
                *****#                  *********   **          
                   #********#       #************  @#            
                      *************************                  
                           *****++++*********                    
                                  *********                      
                           #************                         `n" -ForegroundColor Green                
Write-Output "#######################################################################"
Write-Output "#                            DEPLOY ME v4.0                           #"
Write-Output "#                                 BETA                                #"
Write-Output "#          THIS SCRIPT MAY CONTAIN BUGS. USE AT YOUR OWN RISK!        #"
Write-Output "#                                                                     #"
Write-Output "#                      DEVELOPED BY CHARLES THAI                      #"
Write-Output "#######################################################################`n"
Start-Sleep -seconds 3
Clear-Host

#################################################
#           Editable Variables Begin            #
#################################################
# You only have to edit this part of the script #
#################################################

########################
#  PREREQUISITE CHECK  #
########################

#Skip prerequisite check (Default is 0).
$SkipPreReqCheck = 0

# Enter an IP or website to ping.
$TestWebsite = '3rtechnology.com'

# Set the timezone of your location and automatically sync the date/time.
$Time = 'Pacific Standard Time'

#############################
#   RUN MICROSOFT UPDATES   #
#############################

# Update Categories
$UpdateCatalog = @(
    'Critical Updates', # <-- [0] 20XX-XX Update for Windows XX Version 2XXX for [ANY ARCHITECTURE]-based Systems. Includes Microsoft Office updates.
    'Definition Updates', # <-- [1] AKA Security Intelligence Updates.
    'Drivers', # <-- [2] Self-explantory.
    'Feature Packs', # <-- [3] New product functionality that is first distributed outside the context of a product release and that is typically included in the next full product release.
    'Security Updates', # <-- [4] Cumulative Updates also counts as "Security Updates".

    'Service Packs', <# <-- [5] A tested, cumulative set of all hotfixes, security updates, critical updates, and updates. Additionally, service packs
                                                  may contain additional fixes for problems that are found internally since the release of the product. Service packs may
                                                  also contain a limited number of customer-requested design changes or features. #>
                                                
    'Tools', # <-- [6] A utility or feature that helps complete a task or set of tasks.
    'Update Rollups', # <-- [7] Windows Malicious Software Removal Tool.
    'Updates', # <-- [8] Combination of security, definition, and critical updates.
    'Upgrades'
)


# List the updates you want the PC to download and install by the Update Categories above. (Default settings are: 2, 7, 8).
$Category = $UpdateCatalog[2, 7, 8]

<# 
Exclude any updates from Microsoft Update based by their Knowledge Base (KB) ID.
Use quotes to add a KB in the exclusion list followed by a comma to add another. (e.g. 'KB12345', 'KB67890',...)
#>
$ExcludeKB = @(

)

<# Exclude Preview updates.
- Removing the hashtag (#) before the dollar sign ($) will exclude preview updates. (This is the default option)
- Adding the hashtag(#) before the dollar sign ($) will include preview updates.
#> 
$NoPreview = 'Preview'

#############################
#        DEPLOYMENT         #
#############################

<#
If you previously created a local administrator account, you may choose the option to remove the account. (1 = Skip, 0 = Remove account)
You must specify the local administrator account name if you enable this option.
#>
$skipAccountRemoval = 0 
$Username = 'Refurb'

# Skip Sysprep OOBE. (1 = Skip Sysprep, 0 = Sysprep PC)
$skipOOBE = 1

###############################################
#          Editable Variables End             #
###############################################

######################################################################################
# No edits should take place beyond this comment unless you know what you're doing!  #
# All changes should be made in the Variables section.                               #
######################################################################################
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
            Write-Output "Your PC is now ready to install updates"
            Start-Sleep -Seconds 3
            Clear-Host
        }
        { $SelectedNumber -eq $numbers[1] } {
            Write-Host "`nYour PC is up to date" -ForegroundColor Green
            Write-Output "Preparing for deployment..."
            Start-Sleep -Seconds 3
            Clear-Host
        }
        { $SelectedNumber -eq $numbers[2] } {
            Write-Output "`nYour PC has updates to install."
            Start-sleep -Seconds 3
            Clear-Host
        }
        { $SelectedNumber -eq $numbers[3] } {
            Write-Output 'Your PC is up to date! Preparing to Sysprep machine...'
            Start-Sleep -Seconds 3
            Clear-Host
        }
        default {
            Write-Warning "Invalid message number. Valid numbers are $numbers"
        }
    } #switch
}#end function Set-Message

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


########################
#  PREREQUISITE CHECK  #
########################

function Test-InternetConnection {
    [CmdletBinding()]
    Param()

    BEGIN {
        Write-Verbose -Message "[BEGIN] Running an Internet connectivity check for $env:COMPUTERNAME"
        Write-Output "Checking for Internet connectivity..."
    } #BEGIN
    PROCESS {
        # If there is no Internet connection, display an error and retry 5 five times.
        Write-Verbose -Message "[PROCESS] Checking if $env:COMPUTERNAME can ping to $TestWebsite"
        while (-not((Test-Connection $TestWebsite -Quiet -Count 1) -eq $true)) {
            5..1 | ForEach-Object {
                Write-Warning "No Internet connection found. Retrying..."
                Start-Sleep -Seconds 5
            }
            break
        }
    }#PROCESS
    END {
        if (((Test-Connection $TestWebsite -Quiet -Count 1) -eq $true)) {
            Write-Verbose -Message "[END] $env:COMPUTERNAME successfully pings $TestWebsite"
            Write-Host "Internet connection established!" -ForegroundColor Green
            Start-sleep -Seconds 3
            Clear-Host
        } # End if
        else {
            # If failed 5 times, display a warning message and open up the directory to the batch file, and abort script.
            Write-Verbose -Message "[END] $env:COMPUTERNAME could not establish an Internet connection."
            Write-Warning "Could not establish an Internet connection. Please check your network configuration and try again."
            if ((Test-Path -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/") -eq $true) {
                Invoke-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/"
            } #if ((Test-Path -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/") -eq $true)
            Start-Sleep -Seconds 5
            exit
        } # End else
    } #END 
}#function Test-InternetConnection


#############################
#  INSTALL PSWINDOWSUPDATE  #
#############################

# Check for NuGet
function Get-Nuget {
    [CmdletBinding()]
    Param()

    BEGIN {
        Write-Verbose -Message "[BEGIN} Checking if NuGet package provider is installed on $env:COMPUTERNAME"
        $NuGet = (Get-PackageProvider |  Where-Object { $_.name -eq "Nuget" }).name -contains "NuGet"
        Write-Output "Checking for NuGet..."
        start-sleep -Seconds 3
    } #END BEGIN

    PROCESS {
        if ($NuGet -eq $false) {
            Write-Warning -Message "NuGet is not installed."
            Write-Output 'Installing NuGet...'
            start-sleep -Seconds 5
            try {
                Write-Verbose -Message "[PROCESS] Installing NuGet on $env:COMPUTERNAME"
                Install-PackageProvider -name NuGet -Force -ForceBootstrap -EA Stop
                Write-Output "`nNuGet Installed. Importing NuGet..."
                start-sleep -Seconds 2
                Import-PackageProvider -name Nuget
            } #End Try
            catch [System.Management.Automation.ActionPreferenceStopException] {
                Write-Warning 'An error has occurred that could not be resolved.'
                Write-Host $_.Exception.Message
                Start-Sleep -Seconds 2
                # Restart the script if this cmdlet fails.
                if ((Test-Path -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat") -eq $true) {
                    Write-Warning 'Restarting script'
                    Start-Sleep -seconds 3
                    Invoke-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat"
                } #end else
                exit
            } #End Catch
        } #End if
        else {
            Write-Output 'NuGet is already installed on this PC. Importing NuGet...'
            Import-PackageProvider -name Nuget
        }#End else
    } #END PROCESS
    END {
        Write-Verbose -Message "Verify if NuGet is installed on $env:COMPUTERNAME"
        $NuGet = (Get-PackageProvider |  Where-Object { $_.name -eq "Nuget" }).name -contains "NuGet"
        if ($NuGet -eq $true) {
            Write-Output "`nNuGet Imported!"
        } #End If
    } #END
} #End function Get-Nuget

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
        }#END Switch
    } #END PROCESS
} #function Set-PSGallery

function Get-PSWindowsUpdate {
    [CmdletBinding()]
    Param()

    BEGIN {
        $PSWU = 'PSWindowsUpdate'
        Write-Output "Checking if $PSWU is installed..."

        # If the module is already installed, import it.
        if ((Get-InstalledModule).Name -contains $PSWU) {
            Write-Output "$PSWU is already installed! Importing the module..."
            try {
                Import-Module $PSWU
            } #End try
            catch {
                Write-Host $_ -ForegroundColor Red
                Write-Warning "An error has occurred that could not be resolved."
                Start-Sleep -Seconds 3
                if ((Test-Path -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat") -eq $true) {
                    Write-Warning "Restarting script..."
                    Start-Sleep -Seconds 3
                    Invoke-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat"
                } #End if
                exit
            } #End catch
        } #end if
    } #END BEGIN

    PROCESS {
        # Install PSWindowsUpdate if it is not installed.
        if ((Get-InstalledModule).Name -notcontains $PSWU) {
            Write-Output "Installing $PSWU..."
            try {
                Install-Module -Name $PSWU -Force
                if ((Get-InstalledModule).Name -contains $PSWU) {
                    Write-Output "$PSWU installed! Importing the module..."
                    try {
                        Import-Module -Name $PSWU -Force
                    } #End try
                    catch {
                        Write-Host $_ -ForegroundColor Red
                        Write-Warning "An error has occurred that could not be resolved."
                        Start-Sleep -Seconds 3
                        if ((Test-Path -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat") -eq $true) {
                            Write-Warning "Restarting script..."
                            Start-Sleep -Seconds 3
                            Invoke-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat"
                        } #End if
                        exit
                    } #End catch
                } #End if
            } #end try
            catch {
                Write-Host $_ -ForegroundColor Red
                Write-Warning "An error has occurred that could not be resolved. Restarting script..."
                Start-Sleep -Seconds 3
                if ((Test-Path -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat") -eq $true) {
                    Write-Warning "Restarting script..."
                    Start-Sleep -Seconds 3
                    Invoke-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat"
                } #End if
                exit
            } #End catch
        } #End if
    } #END PROCESS

    END {
        if ((Get-Module).Name -contains $PSWU) {
            Write-Output 'Module imported!'
            Start-Sleep -Seconds 5
            Clear-Host
        } #end if
        else {
            Write-Warning "PSWindowsUpdate was not imported properly!"
            Start-Sleep -Seconds 3
            if ((Test-Path -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat") -eq $true) {
                Write-Warning "Restarting script..."
                Start-Sleep -Seconds 3
                Invoke-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat"
            } #End if
            exit
        } #end else
    } #END
} #End function Get-PSWindowsUpdate

#############################
#   RUN MICROSOFT UPDATES   #
#############################

function Request-MicrosoftUpdate {
    [CmdletBinding()]
    Param()

    BEGIN {
        if ((Get-Module).Name -contains 'PSWindowsUpdate') {
            Write-Output "CHECKING FOR UPDATES"
        } #end if
        else {
            Write-Warning 'PSWindowsUpdate is not imported! This module is required for the script to work properly.'
            Start-Sleep -Seconds 3
            if ((Test-Path -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat") -eq $true) {
                Write-Warning "Restarting script..."
                Start-Sleep -Seconds 3
                Invoke-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat"
            } #End if
            exit
        } #end if
    } #END BEGIN
    PROCESS {
        try {
            # Download and install updates. Stop when there are no updates left to install.
            while ((Get-WUList -Category $Category -NotTitle $NoPreview).Size -gt 0) {
                Get-WUList -Category $Category -NotTitle $NoPreview -AcceptAll -Install -AutoReboot | Format-Table Title, Status, KB, Size, RebootRequired
            } #End while
        } #End try
        catch {
            Write-Host $_ -ForegroundColor Red
            Write-Warning "A fatal error has occurred. This may be caused by PSWindowsUpdate not being properly imported."
            Write-Output "`nRestarting script..."
            Start-Sleep -Seconds 5
            if ((Test-Path -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat") -eq $true) {
                Invoke-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat"
            } #End if
            exit
        } #End Catch
    } #END PROCESS
    END {
        if ((-not(Get-WUList -Category $Category -NotTitle $NoPreview).Size -gt 0)) {
            Set-Message -Message 2
        } #end if
        elseif ((Get-WURebootStatus -Silent) -eq $true) {
            Write-Output 'One or more updates require a reboot.'
            Start-sleep -Seconds 1
            exit
        } #end elseif
    } #END
} # end function Request-MicrosoftUpdate

#############################
#        DEPLOYMENT         #
#############################
function Remove-ReferenceAccount {
    [CmdletBinding()]
    Param()

    BEGIN {
        $Account = $Username
        Write-Output "Retrieving created local account name: $Account"
    }#END BEGIN
    PROCESS {
        if (-not((Get-LocalUser).name -eq $Account)) {
            Write-Warning "$Account account doesnt exist!`n"
        } #End If
        else {
            try {
                Remove-LocalUser -Name $Account -EA Stop
                Write-Output "`n$Account removed!"
            } #End Try
            catch {
                Write-Host $_ -ForegroundColor Red
                Write-Warning "Could not remove the account. Please remove the account manually."
                Start-Process "ms-settings:otherusers"
                Start-Sleep -Seconds 2
            }#End Catch
        } #End Else
    }#END PROCESS
} #End function Remove-RefurbAccount

# Start the script by setting the correct date and time. Then install the PSWindowsUpdate to begin retrieving updates via PowerShell.
function Start-Script {
    Clear-Host
    Write-Output "STAGE 1: RETRIEVING THE REQUIRED MODULE`n"

    # Verify the date and time. Change the timezone according to your location.
    Sync-Time -Timezone $Time
    Write-Output "`n"
    # Install PSWindowsUpdate
    Get-Nuget
    Set-PSGallery -InstallationPolicy 'Trusted'
    Get-PSWindowsUpdate
} #End function Start-Script

# Accept, Download, Install, and Reboot updates using PSWindowsUpdate.
function Get-Update {
    Write-Output "STAGE 2: UPDATES`n"
    Request-MicrosoftUpdate
} #End function Get-Update

function Deploy-Computer {
    # If PSGallery is set to Untrusted and "Refurb" is already removed, launch KeyDeploy.
    if (((Get-PSRepository -Name PSGallery).InstallationPolicy -eq "Untrusted") -and -not(Get-LocalUser -Name "Refurb").Name) {
        Write-Output "FINAL STAGE: DEPLOYMENT`n"
        Write-Output "The settings were already set back to its original setting."
        Start-Sleep -Seconds 3
    } #end if
    else {
        Write-Output "FINAL STAGE: DEPLOYMENT`n"
        Set-PSGallery -InstallationPolicy 'Untrusted'
        if ($skipAccountRemoval -eq 0) {
            Remove-ReferenceAccount
        } #end if
    } #end else
} #End function Deploy-Computer
function Start-DeployMe {
    [CmdletBinding()]
    Param()
    
    BEGIN {
        if ($SkipPreReqCheck -eq 0) {
            Write-Verbose "[BEGIN] Performing the prerequisite check on $ENV:COMPUTERNAME"
            # Test for internet connectivity before running the script.
            Test-InternetConnection

            # Check if Key Deploy is opened and warn the user to close the application.
            Write-Output "Checking if Key Deploy is opened."
            while ((Get-Process).ProcessName -contains 'DTDesktop') {
                Write-Output "Key Deploy is opened. Please close the application to continue."
                Start-sleep -Seconds 5
            } #end while
            Clear-Host
        } #end if
    } #BEGIN

    PROCESS {
        Write-Verbose -Message "[PROCESS] Checking if this script was previously ran on $ENV:COMPUTERNAME"
        Write-Output "Initializing script...`n"
        $PSWU = (Get-InstalledModule).name -contains 'PSWindowsUpdate'
        Start-Sleep -Seconds 2

        # If PSWindowsUpdate is already installed on the machine, import the module then check for updates.
        if ($PSWU -eq $true) {
            Write-Output "DeployMe has detected that PSWindowsUpdate has already been installed. Importing the PSWindowsUpdate module..."
            Start-Sleep -Seconds 2
            try {
                Import-Module 'PSWindowsUpdate' -EA Stop
                $PSWUModule = (Get-Module).Name -contains 'PSWindowsUpdate'
                if ($PSWUModule -eq $true) {
                    Write-Output 'Module imported'
                    Get-Module
                } #End if
            } #End try
            catch {
                Write-Host $_ -ForegroundColor Red
                Write-Warning 'An error occurred that could not be resolved.'
                Start-sleep 3
                if (Test-Path -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat" -eq $true) {
                    Write-Warning 'Restarting script...'
                    Start-Sleep -Seconds 3
                    Invoke-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat"
                } #End if
                exit
            } #End catch
    
            Write-Verbose -Message "[PROCESS] $env:COMPUTERNAME is checking for updates."
            Write-Output "`nChecking for updates..."
            $InstallPolicy = (Get-PSRepository -Name PSGallery).InstallationPolicy
            $GWU = (Get-WUList -Category $Category -NotTitle $NoPreview -NotKBArticleID $ExcludeKB).Size

            # If the computer is up to date, but the PSGallery is set to "Trusted".
            if (-not($GWU -gt 0) -and $InstallPolicy -eq 'Trusted') {
                Set-Message -Message 2
                Deploy-Computer
            }#End if

            elseif (-not(($GWU -gt 0) -and ($InstallPolicy -eq 'Trusted')) -and ($skipOOBE -eq 0)) {
                Set-Message -Message 4
            } #End elseif

            #If the PC still has updates to install.
            else {
                Set-Message -Message 3
                Get-Update
                Deploy-Computer
            }#End else
        } #End if

        # If PSWindowsUpdate is not installed, but NuGet and PSGallery is already been modified by the script, Install PSWindowsUpdate, import and check for updates.
        elseif ((Get-PackageProvider | Where-Object { $_.name -eq "Nuget" }).name -contains "NuGet" -and (Get-PSRepository -Name PSGallery).InstallationPolicy -eq 'Trusted') {
            Write-Output 'The script has detected that NuGet and PSGallery settings were already modified, Installing PSWindowsUpdate'
            Get-PSWindowsUpdate
            Get-Update
            Deploy-Computer
        } #End elseif

        # Run the script for the first time.
        else {
            Write-Verbose -Message "[PROCESS] Initializing AutoDeploy for the first time on $env:COMPUTERNAME"
            Start-Script
            Get-Update
            Deploy-Computer
        } #End else
    } #PROCESS
    
    END {
        if ($skipOOBE -eq 0) {
            Write-Output "Preparing Sysprep using Out of Box Experience (OOBE)"
            start-sleep -Seconds 5
            if ((Get-Process).ProcessName -contains 'sysprep') {
                Stop-Process -Name sysprep
                if ((Test-Path $env:WINDIR\system32\sysprep) -eq $true) {
                    Set-Location $env:WINDIR\system32\sysprep
                    Invoke-Command -ScriptBlock { .\sysprep.exe /oobe /quit}
                } #end if
            } #end if
        } #end if
    } #END
}#End function Start-DeployMe

Start-DeployMe

# Check the Sysprep folder and verify if the success tag exists. If the tag exists, Uninstall PSWindowsUpdate, delete the script, and shut down the PC.
if ((Test-Path -Path $env:WINDIR\System32\Sysprep\Sysprep_succeeded.tag) -eq $true) {
    Write-Output "Script complete! Preparing to shutdown PC in 30 seconds."
    Invoke-Expression 'cmd /c start powershell -Command {Write-Output "Uninstalling PSWindowsUpdate" ; Uninstall-Module -Name PSWindowsUpdate}'
    Start-Sleep -Seconds 30
    Remove-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat" -Force
    Remove-Item -Path $MyInvocation.MyCommand.Source -Force
    Stop-Computer
} #end if
else {
    Write-Output "Script complete! Preparing to uninstall PSWindowsUpdate. Please sysprep the PC when you are finished."
    Start-Sleep -Seconds 5
    if ((Get-Process).ProcessName -contains 'sysprep') {
        Write-Output "Sysprep is already opened!"
    } #end if
    else {
        if ((Test-Path $env:WINDIR\system32\sysprep) -eq $true) { Invoke-Item $env:WINDIR\system32\sysprep\sysprep.exe }
    }
    Invoke-Expression 'cmd /c start powershell -Command {Write-Output "Uninstalling PSWindowsUpdate..." ; Uninstall-Module -Name PSWindowsUpdate}'
    Remove-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat" -Force
    Remove-Item -Path $MyInvocation.MyCommand.Source -Force
} #end else