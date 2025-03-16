<#

    .DESCRIPTION
        An automated script used to deploy Windows PCs.
    
    .NOTES
        This script requires the following: `
        - Windows PowerShell v5.1 or later`
        - Windows 10 or later `
        - Elevated prilveges `
        - Execution policy set to "Bypass"

#>
#Requires -RunAsAdministrator
#Requires -Version 5.1

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
Write-Output "#                             Deploy IT                               #"
Write-Output "#                            Version 5.0                              #"
Write-Output "#                        Developed by Charles                         #"
Write-Output "#######################################################################"
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
$TestWebsite = 'google.com'

# Enable this script to set the date/time. Set the timezone of the location and automatically sync the date/time. (Default is 1 for enabled).
$enableTimeSync = 1
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
Enable this option if a local administrator account was previously created. (1 = Skip, 0 = Remove account)
It is important to specify the account name correctly, otherwise the account removal will fail.
#>
$skipAccountRemoval = 0 
$Username = 'Refurb'

# Apply a new Windows product key using Key Deploy (1 = Enable, 0 = Disable). 
# Specify both the removable media's volume name and the network drive for saving files.
$installProductKey = 1
$USBVolumeName = "MARXPRESS"
$outputDrive = "\\10.0.0.91\Keys"

# Skip Sysprep OOBE. (1 = Skip Sysprep, 0 = Sysprep PC)
$skipOOBE = 0

###############################################
#          Editable Variables End             #
###############################################

######################################################################################
# No edits should take place beyond this comment unless you know what you're doing!  #
# All changes should be made in the Variables section.                               #
######################################################################################

$switchON = 1
$switchOFF = 0

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
        # If there is no Internet connection, display an error and retry 6 (six) times.
        Write-Verbose -Message "[PROCESS] Checking if $env:COMPUTERNAME can ping to $TestWebsite"
        while ((-not((Test-Connection $TestWebsite -Quiet -Count 1) -eq $true)) -and $Retries -lt 6) {
            Write-Warning "Could not connect to the Internet. Retrying..."
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

function Sync-DateTime {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        $TimeZone
    )

    BEGIN {
        Write-Verbose -Message "[BEGIN] Setting the timezone on $env:COMPUTERNAME"
        if ((Get-TimeZone -ListAvailable).Id -contains $TimeZone) {
            try {
                Set-TimeZone -Id $TimeZone
                if ((Get-TimeZone).Id -eq $TimeZone) {
                    Write-Host "Timezone set to `"$TimeZone`"" -ForegroundColor Green
                    $Sync = 1
                } #end if
            } #end try
            catch {
                Write-Warning "Unable to set the timezone."
            } #end catch
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
                    $Sync = 0
                    Start-Sleep -Seconds 5
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
            # Disable this check once time/date is in sync.
            if (Test-Path -Path $env:HOMEDRIVE\DeployIT.ps1) {
                (Get-Content -Path $env:HOMEDrive\DeployIT.ps1 -Raw).Replace("enableTimeSync = 1", "enableTimeSync = $switchOFF") | Set-Content -Path $env:HOMEDRIVE\DeployIT.ps1
            } #end if
        } #end else
    } #end END
} #end function Sync-DateTime

#############################
#  INSTALL PSWINDOWSUPDATE  #
#############################
function Install-NuGet {
    [CmdletBinding()]
    Param()

    BEGIN {
        Write-Verbose -Message "[BEGIN} Checking if NuGet is installed on $env:COMPUTERNAME"
        Write-Output "Checking if NuGet is installed on this PC..."
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
            Write-Warning "$Account doesn't exist!`n"
            Start-Process "ms-settings:otherusers"
            Start-Sleep -Seconds 2
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

function Approve-Computer {
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
} #End function Approve-Computer
function Start-DeployMe {
    [CmdletBinding()]
    Param()

    BEGIN {
        if ($skipPreReqCheck -eq 0) {
            Write-Verbose "[BEGIN] Performing prerequisite check(s) on $ENV:COMPUTERNAME"

            # Test Internet connectivity
            if ($enablePingTest -eq 1) {
                Test-InternetConnection
            } #end if

            # Sync the date/time. This variable will be set to 0 (false) once the correct date/time has been set to prevent looping.
            if ($enableTimeSync -eq 1) {
                Sync-DateTime -Timezone $Timezone
            } #end if
        } #end if
        Clear-Host
    } #end BEGIN

    PROCESS {
        Write-Verbose -Message "[PROCESS] Check if the script was previously ran on $ENV:COMPUTERNAME"
        Write-Output "Initializing script...`n"
        Start-Sleep -Seconds 5

        if (Get-InstalledModule -Name "PSWindowsUpdate" -EA SilentlyContinue) {
            Write-Output "Deploy IT has detected that PSWindowsUpdate is installed on $ENV:COMPUTERNAME."
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
                Approve-Computer
            } #end if
            else {
                Write-Warning "Your PC has updates to install."
                Start-Sleep -Seconds 5
                Clear-Host
                Get-Update
                Approve-Computer
            } #end else
        } #end if

        # Install PSWindowsUpdate only if NuGet is installed and PSGallery's installation policy is set to 'Trusted'.
        elseif (((Get-PackageProvider).Name -contains "NuGet") -and (Get-PSRepository -Name PSGallery).InstallationPolicy -eq 'Trusted') {
            Write-Warning "Installing PSWindowsUpdate..."
            if (-not(Get-InstalledModule -Name "PSWindowsUpdate")) {
                Get-PSWindowsUpdate
                if (Get-Module -Name "PSWindowsUpdate") {
                    Get-Update
                    Approve-Computer
                } #end if
                else {
                    Write-Warning "Could not find PSWindowsUpdate in the module. This module is required for this script to work!"
                    if (Test-Path -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat" -eq $true) {
                        Write-Warning 'Restarting script...'
                        Start-Sleep -Seconds 3
                        Invoke-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat"
                    } #end if
                } #end if
            } #end if
        } #end elseif

        # Start the script for the first time.
        else {
            Write-Verbose -Message "[PROCESS] Initializing DeployMe for the first time on $env:COMPUTERNAME"
            Start-Script
            Get-Update
            Approve-Computer
        } #end else
    } #end PROCESS

    END {

        # Warn the user that the local administrator account still exists and prevent the system being Sysprep
        if (($skipAccountRemoval -eq 0) -and (Get-LocalUser) -match $Username) {
            Write-Verbose -Message "[END] Warn the user that this reference account exists and abort Sysprep."
            Write-Warning "The local administrator account wasn't removed. Please remove the account manually then sysprep the machine when ready."
            Start-Process "ms-settings:otherusers"
            $skipOOBE = 1
        } #end if

        # Apply a new Windows product key and activate refurbished PCs.
        if ($installProductKey -eq 1) {
            # Check for removable media. 
            if ($null -eq $USBVolumeName) {
                Write-Warning "Volume name not found! This process will be skipped!"
                $skipOOBE = 1
            } #end if
            else {
                Read-Host -Prompt "This next step will install a Windows product key for refurbished PCs. Please plug in the removable media named $USBVolumeName then press the ENTER key to continue." | Out-Null
                Write-Output "Checking for $USBVolumeName USB drive..."
                Start-Sleep -Seconds 5
                
                #Warn the user if the removable media is not found.
                while ((Get-CimInstance -ClassName Win32_LogicalDisk).VolumeName -notcontains $USBVolumeName) {
                    Write-Warning "$USBVolumeName drive not found! Check if the removable media is plugged in properly."
                    Start-Sleep -Seconds 5
                } #end while
            } #end else

            if ((Get-CimInstance -ClassName Win32_LogicalDisk).VolumeName -contains $USBVolumeName) {
                $DriveLetter = (Get-CimInstance -ClassName Win32_Volume -Filter 'Label LIKE "MARXPRESS"').DriveLetter
                $FilePath = "$DriveLetter\Script"
                $OutputPath = "$DriveLetter\Output"
                if ((Test-Path $FilePath)) {
                    try {
                        Set-Location $FilePath
                        .\run.ps1

                        #Activate Windows
                        if ((Get-WmiObject -query ‘select * from SoftwareLicensingService’).OA3xOriginalProductKey -notcontains "") {
                            Write-Output "Activating Windows..."
                            Start-Sleep -Seconds 2
                            slmgr.vbs /ato

                            if ((Get-CimInstance -ClassName SoftwareLicensingProduct | Where-Object { $_.Name -match "Windows" }).LicenseStatus -contains 1) {
                                Write-Host -ForegroundColor Green "Windows is activated!"
                                Start-Sleep -Seconds 5
                            } #end if
                            else {
                                Write-Warning "Windows is not activated. Please activate Windows manually"
                                Start-Sleep -Seconds 2
                            } #end else
                        } #end if
                    } #end try
                    catch [System.Exception] {
                        $Message = $Error[0].Exception;
                        $Message;
                        $Message | Out-File -FilePath ($DriveLetter + "\DeployIT-log.log") -Append;
                        Write-Host -Object "Error(s) occurred when trying to run the script. Error log has been written in the $USBVolumeName drive."
                        Read-Host -Prompt "Press the ENTER key to exit..." | Out-Null
                        exit
                    } #end catch

                    #Only retrieve today's output files. Ignore old output files.
                    $latestOutputFiles = Get-ChildItem $OutputPath | Where-Object { $_.LastWriteTime -ge $(Get-Date).ToShortDateString() }

                    # Copy files to a file share.
                    if ($latestOutputFiles = Get-ChildItem $OutputPath | Where-Object { $_.LastWriteTime -ge $(Get-Date).ToShortDateString() }) {
                        $networkDrive = @{ 
                            Name        = "MAREXPRESS"
                            PSProvider  = "FileSystem"
                            Root        = $outputDrive
                            Description = "MAREXPRESS output keys."
                        }

                        # Mapped network credentials.
                        $Username = "deploy"
                        $PWord = "password"
                        $networkCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, $PWord

                        try {
                            New-PSDrive @networkDrive -Credential $networkCredentials
                        } #end try
                        catch {
                            $Message = $Error[0].Exception;
                            $Message;
                            $Message | Out-File -FilePath ($DriveLetter + "\AutoDeploy-log.log") -Append;
                            Write-Warning "Failed to map the network drive! Please move the output files manually."
                            Start-Sleep -Seconds 5
                        } #end catch
                                    
                        if ((Get-PSDrive).Name -contains "MAREXPRESS") {
                            try {
                                $latestOutputFiles = Get-ChildItem $OutputPath | Where-Object { $_.LastWriteTime -ge $(Get-Date).ToShortDateString() }
                                Set-Location -Path MAREXPRESS:
                                Copy-Item -Path $latestOutputFiles -Destination MAREXPRESS:

                                if (Get-ChildItem -Path MAREXPRESS: | Where-Object { $_.LastWriteTime -ge $(Get-Date).ToShortDateString() }) {
                                    Write-Host -ForegroundColor Green "Copy successful!"
                                    Get-ChildItem -Path MAREXPRESS:
                                } #end if
                            } #end try
                            catch [System.Exception] {
                                $Message = $Error[0].Exception;
                                $Message;
                                $Message | Out-File -FilePath ($DriveLetter + "\AutoDeploy-log.log") -Append;
                                Write-Warning "Failed to copy the output files. Please move the files manually."
                                Start-Sleep -Seconds 5
                            } #end catch
                        } #end if
                    } #end if
                    else {
                        Write-Warning "The latest output files not found!"
                        Start-Sleep -Seconds 5
                    } #end else
                } #end if
                else {
                    $Message = $Error[0].Exception;
                    $Message;
                    $Message | Out-File -FilePath ($DriveLetter + "\DeployIT-log.log") -Append;
                    Write-Host -ForegroundColor Red -Object "This media does not have the required files. Please check the $USBVolumeName media and try again."
                    Read-Host -Prompt "Press the ENTER key to exit..." | Out-Null
                    exit
                } #end else
            } #end if        
        } #end if
        

        # Sysprep the PC. Give it 15 seconds for the success tag to be created in the sysprep folder.
        if ($skipOOBE -eq 0) {
            Write-Verbose -Message "[END] Sysprep the PC using Out of Box Experience (OOBE) and quit the application."
            Write-Output "Preparing to sysprep the PC..."
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
    Write-Output "Script complete! The PC will restart in 30 seconds. If you wish to cancel the restart, press CTRL + C."
    Invoke-Expression 'cmd /c start powershell -Command {Write-Output "Uninstalling PSWindowsUpdate" ; Uninstall-Module -Name PSWindowsUpdate -Force}'
    Remove-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat" -Force
    Remove-Item -Path $MyInvocation.MyCommand.Source -Force
    Start-Sleep -Seconds 30
    Restart-Computer -Force # Restart the PC.
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