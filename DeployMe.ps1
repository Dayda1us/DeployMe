<#

    .DESCRIPTION
        An automated script used to deploy Windows PCs with little to no user intervention.
    
    .NOTES
        This script requires the following: `
        - Windows PowerShell v5.1 or later`
        - Windows 11 or later `
        - Elevated prilveges `
        - Execution policy set to "Bypass"

#>
#Requires -RunAsAdministrator
#Requires -Version 5.1


# Check if the operating system is running on Windows 11. Terminate the script and delete its files if the OS is older than Windows 11.
Write-Output "Checking if this PC is running Windows 11 or later..."
Start-Sleep -Seconds 5
if (([System.Environment]::OSVersion.Version).Build -lt 21999) {
    Write-Warning "This operating system is unsupported. This script will only run on Windows 11 or later."
    Start-Sleep -Seconds 5
    if ((Test-Path -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat") -eq $true) {
        Write-Warning "Removing script..."
        Start-Sleep -Seconds 2
        Remove-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat" -Force
        Remove-Item -Path "$env:HOMEDRIVE/DeployMe.ps1" -Force
    } #end if
    exit
} #end if 
else {
    Write-Host "This PC is running Windows 11." -ForegroundColor Green
    Write-OUtput "Starting script..."
    Start-Sleep -seconds 3
    Clear-Host
}

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

#Skip prerequisite check (Default is 0 for enabled).
$skipPreReqCheck = 0


## The two variables below are part of the prerequisite check. ##
## If you intend to skip the prerequisite check, then these variables will have no effect to the script. ##

# Enable the Internet connectivity check. Enter an IP or website to ping. (Default is 1 for enabled).
$enablePingTest = 1
$TestWebsite = '3rtechnology.com'

# Enable this script to set the date/time. Set the timezone of the location and automatically sync the date/time. (Default is 1 for enabled).
$enableTimeSync = 0
$Timezone = 'Pacific Standard Time'

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
$skipOOBE = 0

###############################################
#          Editable Variables End             #
###############################################

######################################################################################
# No edits should take place beyond this comment unless you know what you're doing!  #
# All changes should be made in the Variables section.                               #
######################################################################################


function Sync-DateTime {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        $Timezone
    )

    BEGIN {
        Write-Verbose -Message "[BEGIN] Setting the timezone on $env:COMPUTERNAME"
        if ((Get-TimeZone -ListAvailable).Id -contains $Timezone) {
            try {
                Set-TimeZone -Id $Timezone
            } #end try
            catch {
                Write-Warning "Unable to set the timezone. An error occurred that could not be resolved."
            } #end catch

            if ((Get-TimeZone).Id -eq $Timezone) {
                Write-Host "Timezone set to `"$Timezone`"" -ForegroundColor Green
                $Sync = 1
            } #end if
        } #end if
        else {
            Write-Warning "Invalid Timezone!"
        } #end else
    } #end BEGIN

    PROCESS {
        if ($Sync -eq 1) {
            # Start Windows Time if service status is anything other than "Started."
            if ((-not(Get-Service -Name W32Time).Status -eq 'Running')) {
                Write-Output "Starting service: Windows Time..."
                Start-Sleep -Seconds 5
                try {
                    Start-Service -Name W32Time
                    if ((Get-Service -Name W32Time).Status -eq 'Running') {
                        Write-Warning "Service started!"
                        Start-Sleep -Seconds 3
                    } #end if
                } #end try
                catch {
                    Write-Warning "Failed to start Windows Time service. An unknown error has occurred."
                    Write-Host $_ -ForegroundColor Red
                    $Sync = 0
                    Start-Sleep -Seconds 5
                } #end catch
            } #end if

            # Invoke the command from w32tm.exe to sync the date/time.
            if (((Get-Service -Name W32Time).Status -eq 'Running')) {
                Write-Output "Syncing the date and time..."
                Start-Sleep -Seconds 3
                try {
                    Invoke-Command -ScriptBlock { w32tm.exe /resync }
                } # end try
                catch {
                    Write-Host $_ -ForegroundColor Red
                    Write-Warning "Failed to sync the date and time. An unknown error has occurred!"
                    Start-Sleep -Seconds 5
                    $Sync = 0
                } #end catch
            } #end if
        } #end if
    } #end PROCESS

    END {
        if (-not($Sync -eq 1)) {
            Write-Warning "Operation aborted!"
        } #end if
        else {
            Write-Output "The operation was successful."
        } #end else
    } #end END
} #end function Sync-DateTime

########################
#  PREREQUISITE CHECK  #
########################

function Test-InternetConnection {
    [CmdletBinding()]
    Param()

    BEGIN {
        Write-Verbose -Message "[BEGIN] Running an Internet connectivity check for $env:COMPUTERNAME"
        Write-Output "Checking for Internet connectivity..."
        Start-Sleep -Seconds 3
    } #BEGIN
    PROCESS {
        # If there is no Internet connection, display an error and retry 5 five times.
        Write-Verbose -Message "[PROCESS] Checking if $env:COMPUTERNAME can ping to $TestWebsite"
        while ((-not((Test-Connection $TestWebsite -Quiet -Count 1) -eq $true)) -and $Retries -lt 5) {
            Write-Warning "No Internet connection found. Retrying..."
            Start-Sleep -Seconds 10
            $Retries++
        } #end while
    }#PROCESS
    END {
        if (((Test-Connection $TestWebsite -Quiet -Count 1) -eq $true)) {
            Write-Verbose -Message "[END] $env:COMPUTERNAME successfully pings $TestWebsite"
            Write-Host "Internet connection established!" -ForegroundColor Green
            Start-sleep -Seconds 3
            Clear-Host
        } # End if
        else {
            Write-Verbose -Message "[END] $env:COMPUTERNAME could not establish an Internet connection."
            Write-Warning "Could not establish an Internet connection. Please check your network configuration and try again."
            if ((Test-Path -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/") -eq $true) {
                Invoke-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/"
            } # end if
            Start-Sleep -Seconds 5
            exit
        } # End else
    } #END 
}#function Test-InternetConnection

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


#############################
#  INSTALL PSWINDOWSUPDATE  #
#############################
function Install-NuGet {
    [CmdletBinding()]
    Param()

    BEGIN {
        Write-Verbose -Message "[BEGIN} Checking if NuGet is installed on $env:COMPUTERNAME"
        Write-Output "Checking for NuGet..."
        start-sleep -Seconds 3
        
        if ((Get-PackageProvider).Name -contains "NuGet") {
            Write-Output "NuGet is already installed!"
        } #end if
    } #END BEGIN

    PROCESS {
        if (-not((Get-PackageProvider).Name -contains "NuGet")) {
            Write-Warning "Installing NuGet..."
            try {
                Write-Verbose -Message "[PROCESS] Installing NuGet on $env:COMPUTERNAME"
                Install-PackageProvider -name NuGet -Force -ForceBootstrap -EA Stop
            } #end try
            catch {
                Write-Warning 'Failed to install NuGet!'
                Write-Host $_.Exception.Message -ForegroundColor Red
                Start-Sleep -Seconds 2
                # Restart the script if this cmdlet fails.
                if ((Test-Path -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat") -eq $true) {
                    Write-Warning 'Restarting script'
                    Start-Sleep -seconds 3
                    Invoke-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat"
                } #end else
                exit
            } #end catch
        } #end if
    } #END PROCESS

    END {
        if ((Get-PackageProvider).Name -contains "NuGet") {
            Write-Warning "Importing NuGet..."
            Start-Sleep -Seconds 2
            try {
                Import-PackageProvider -Name NuGet
                Write-Host "NuGet imported! `n" -ForegroundColor Green
            } #end try
            catch {
                Write-Warning 'Failed to import NuGet!'
                Write-Host $_.Exception.Message -ForegroundColor Red
                Start-Sleep -Seconds 2
                # Restart the script if this cmdlet fails.
                if ((Test-Path -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat") -eq $true) {
                    Write-Warning 'Restarting script'
                    Start-Sleep -seconds 3
                    Invoke-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat"
                } #end else
                exit
            } #end catch
        } #end if
    } #END
} # end function Install-NuGet

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
        Write-Verbose "[BEGIN] Check if this PC has PSWindowsUpdate installed."
        Write-Output "Checking for PSWindowsUpdate..."
        Start-Sleep -Seconds 5
        if (Get-InstalledModule -Name PSWindowsUpdate) {
            Write-Warning "PSWindowsUpdate installed!"
        } #end if
    } #END BEGIN

    PROCESS {
        # Install PSWindowsUpdate if it is not installed.
        if (-not(Get-InstalledModule -Name PSWindowsUpdate -EA SilentlyContinue)) {
            Write-Verbose "[PROCESS] Install PSWindowsUpdate"
            Write-Warning "Installing PSWindowsUpdate..."
            try {
                Install-Module -Name PSWindowsUpdate -Force
            } #end try
            catch {
                Write-Host $_ -ForegroundColor Red
                Write-Warning "Failed to install PSWindowsUpdate!"
                Start-Sleep -Seconds 3
                if ((Test-Path -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat") -eq $true) {
                    Write-Warning "Restarting script..."
                    Start-Sleep -Seconds 3
                    Invoke-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat"
                } #End if
                exit
            } #end catch
        } #end if
    } #END PROCESS

    END {
        if (Get-InstalledModule -Name PSWindowsUpdate) {
            Write-Verbose "[END] Import PSWindowsUpdate"
            # Import PSWindowsUpdate.
            if (-not(Get-Module -Name PSWindowsUpdate)) {
                Write-Warning "Importing PSWindowsUpdate..."
                Start-Sleep -Seconds 3
                Import-Module -Name PSWindowsUpdate -Force
                if (Get-Module -Name PSWindowsUpdate) {
                    Write-Host "PSWindowsUpdate Imported!" -ForegroundColor Green
                    Write-Output "This PC is now ready to install updates."
                    Start-Sleep -Seconds 3
                } #end if
            } #end if
            elseif (Get-Module -Name PSWindowsUpdate) {
                Write-Warning "PSWindowsUpdate is already imported!"
                Write-Output "This PC is now ready to install updates."
                Start-Sleep -Seconds 3
            } #end elseif
        } #end if
        else {
            Write-Warning "PSWindowsUpdate is not installed on $env:COMPUTERNAME. Restarting script..."
            if ((Test-Path -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat") -eq $true) {
                Write-Warning "Restarting script..."
                Start-Sleep -Seconds 3
                Invoke-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat"
            } #End if
            exit
        } #end else
        Clear-Host
    } #END
} #End function Get-PSWindowsUpdate


#############################
#   RUN MICROSOFT UPDATES   #
#############################

function Request-MicrosoftUpdate {
    [CmdletBinding()]
    Param()

    BEGIN {
        if ((Get-Module -name PSWindowsUpdate)) {
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
                Get-WUList -Category $Category -NotTitle $NoPreview -AcceptAll -Install -AutoReboot | Format-Table Status, KB, Size, @{l = "Reboot?"; e = { $_.RebootRequired } }, Title -Wrap
            } #End while
        } #End try
        catch {
            Write-Host $_ -ForegroundColor Red
            Write-Warning "A fatal error has occurred that could not be resolved."
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
            Write-Host "`nYour PC is up to date" -ForegroundColor Green
            Write-Output "Preparing for deployment..."
            Start-Sleep -Seconds 3
            Clear-Host
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
                Write-Warning "Account removal unsuccessful. Please remove the account and sysprep the machine manually."
                Start-Process "ms-settings:otherusers"
                Start-Sleep -Seconds 2
            }#End Catch
        } #End Else
    }#END PROCESS
} #End function Remove-ReferenceAccount

# Start the script by setting the correct date and time. Then install the PSWindowsUpdate to begin retrieving updates via PowerShell.
function Start-Script {
    Clear-Host
    Write-Output "STAGE 1: INSTALL PSWINDOWSUPDATE`n"

    # Verify the date and time. Change the timezone according to your location.
    #Sync-Time -Timezone $Time
    Write-Output "`n"
    # Install PSWindowsUpdate
    Install-NuGet
    Set-PSGallery -InstallationPolicy 'Trusted'
    Get-PSWindowsUpdate
} #End function Start-Script

# Accept, Download, Install, and Reboot updates using PSWindowsUpdate.
function Get-Update {
    Write-Output "STAGE 2: UPDATING WINDOWS`n"
    Request-MicrosoftUpdate
} #End function Get-Update

function Deploy-Computer {
    # If PSGallery is set to "Untrusted", proceed to account removal. [If variable is set to 0 (Enabled)].
    if (((Get-PSRepository -Name PSGallery).InstallationPolicy -eq "Untrusted")) {
        Write-Output "FINAL STAGE: DEPLOYMENT`n"
        if ($skipAccountRemoval -eq 0) {
            Remove-ReferenceAccount
        } #end if
    } #end if
    else {
        Write-Output "FINAL STAGE: DEPLOYMENT`n"
        if ((Get-PSRepository -Name PSGallery).InstallationPolicy -eq 'Trusted') {
            Set-PSGallery -InstallationPolicy 'Untrusted'
        } #end if

        # Remove reference account if variable is set to 0 (Enabled).
        if ($skipAccountRemoval -eq 0) {
            Remove-ReferenceAccount
        } #end if
    } #end else
} #End function Deploy-Computer
function Start-DeployMe {
    [CmdletBinding()]
    Param()

    BEGIN {
        if ($skipPreReqCheck -eq 0) {
            Write-Verbose "[BEGIN] Performing prerequisite check(s) on $ENV:COMPUTERNAME"

            if ($enablePingTest) {
                # Test for internet connectivity
                Test-InternetConnection
            } #end if

            if ($enableTimeSync) {
                # Sync the date/time
                Sync-Time
            } #end if
        } #end if
        Clear-Host
    } #end BEGIN

    PROCESS {
        Write-Verbose -Message "[PROCESS] Checking if this script was previously ran on $ENV:COMPUTERNAME"
        Write-Output "Initializing script...`n"
        Start-Sleep -Seconds 5

        if (Get-InstalledModule -Name "PSWindowsUpdate" -EA SilentlyContinue) {
            Write-Output "DeployMe has detected that PSWindowsUpdate is installed on $ENV:COMPUTERNAME. Importing script..."
            try {
                Import-Module "PSWindowsUpdate" -Force
                if (Get-Module -name "PSWindowsUpdate") {
                    Write-Host "PSWindowsUpdate imported!" -ForegroundColor Green
                    Get-Module
                    Start-Sleep -Seconds 2
                } #end if
            } #end try
            catch {
                Write-Warning "Failed to import PSWindowsUpdate!"
                Write-Host $_ -ForegroundColor Red
                Start-Sleep -Seconds 5
                if (Test-Path -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat" -eq $true) {
                    Write-Warning 'Restarting script...'
                    Start-Sleep -Seconds 3
                    Invoke-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat"
                } #end if
                exit
            } #end catch

            Write-Verbose -Message "[PROCESS] $env:COMPUTERNAME is checking for updates."
            Write-Output "`nChecking for updates..."

            if (-not(Get-WUList -Category $Category -NotTitle $NoPreview -NotKBArticleID $ExcludeKB).Size -gt 0) {
                Write-Host "Your PC is up to date!" -ForegroundColor Green
                Write-Output "Preparing to deploy PC..."
                Deploy-Computer
            } #end if
            else {
                Write-Warning "Your PC has updates to install."
                Start-Sleep -Seconds 5
                Get-Update
                Deploy-Computer
            } #end else
        } #end if

        # Install PSWindowsUpdate only if NuGet is installed and PSGallery's installation policy is set to 'Trusted'.
        elseif (((Get-PackageProvider).Name -contains "NuGet") -and (Get-PSRepository -Name PSGallery).InstallationPolicy -eq 'Trusted') {
            Write-Warning "Installing PSWindowsUpdate..."
            if (-not(Get-InstalledModule -Name "PSWindowsUpdate")) {
                Get-PSWindowsUpdate
                if (Get-Module -Name "PSWindowsUpdate") {
                    Get-Update
                    Deploy-Computer
                } #end if
                else {
                    Write-Warning "Could not find PSWindowsUpdate in the module. This module is required for this script to work!"
                } #end if
            } #end if
        } #end elseif

        # Start the script for the first time.
        else {
            Write-Verbose -Message "[PROCESS] Initializing DeployMe for the first time on $env:COMPUTERNAME"
            Start-Script
            Get-Update
            Deploy-Computer
        } #end else
    } #end PROCESS

    END {
        if (($skipAccountRemoval -eq 0) -and (Get-LocalUser) -match $Username) {
            Write-Verbose -Message "[END] Warn the user that this reference account exists and abort Sysprep."
            Write-Warning "This reference account wasn't removed. Please remove the account manually then sysprep the machine."
            $skipOOBE = 1
        } #end if

        # Sysprep the PC. Give it 20 seconds for the success tag to be created in the sysprep folder.
        if ($skipOOBE -eq 0) {
            Write-Verbose -Message "[END] Sysprep the PC using Out of Box Experience (OOBE) and quit the application."
            Write-Output "Preparing Sysprep using Out of Box Experience (OOBE)"
            start-sleep -Seconds 5
            if ((Get-Process).ProcessName -contains 'sysprep') {
                Stop-Process -Name sysprep
                if ((Test-Path $env:WINDIR\system32\sysprep) -eq $true) {
                    Set-Location $env:WINDIR\system32\sysprep
                    Invoke-Command -ScriptBlock { .\sysprep.exe /oobe /quit }
                    Start-Sleep -Seconds 15
                } #end if
            } #end if
            else {
                if ((Test-Path $env:WINDIR\system32\sysprep) -eq $true) {
                    Set-Location $env:WINDIR\system32\sysprep
                    Invoke-Command -ScriptBlock { .\sysprep.exe /oobe /quit }
                    Start-Sleep -Seconds 15
                } #end if
            } #end else
        } #end if
    } #end END
} #end function

Start-DeployMe

# Check the Sysprep folder and verify if the success tag exists. If the tag exists, Uninstall PSWindowsUpdate, delete the script, and shut down the PC.
if ((Test-Path -Path $env:WINDIR\System32\Sysprep\Sysprep_succeeded.tag) -eq $true) {
    Write-Output "Script complete! Preparing to shutdown PC in 30 seconds."
    Invoke-Expression 'cmd /c start powershell -Command {Write-Output "Uninstalling PSWindowsUpdate" ; Uninstall-Module -Name PSWindowsUpdate -Force}'
    Remove-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat" -Force
    Remove-Item -Path $MyInvocation.MyCommand.Source -Force
    Start-Sleep -Seconds 30
    Stop-Computer
} #end if
else {
    Write-Output "Script complete! Preparing to uninstall PSWindowsUpdate. Please sysprep the PC when you are finished."
    if ((Get-Process).ProcessName -contains 'sysprep') {
        Write-Output "Sysprep is already opened!"
        Start-Sleep -Seconds 5
    } #end if
    elseif ((Test-Path -Path $env:WINDIR\System32\Sysprep\sysprep.exe) -eq $true) {
        Invoke-Item -Path $env:WINDIR\System32\Sysprep\sysprep.exe
    } #end elseif
    Invoke-Expression 'cmd /c start powershell -Command {Write-Output "Uninstalling PSWindowsUpdate..." ; Uninstall-Module -Name PSWindowsUpdate -Force}'
    Remove-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat" -Force
    Remove-Item -Path $MyInvocation.MyCommand.Source -Force
} #end else
