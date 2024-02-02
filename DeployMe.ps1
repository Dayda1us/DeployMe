#####################################################################################
#                                                                                   #
#                                DEPLOY ME (v4.0)                                   #
#                                                                                   #
#       Leverages PSWindowsUpdate to install drivers and updates                    #
#       and deploy Microsoft Windows product key for refurbish PCs                  #
#       via Keydeploy.                                                              #
#                                                                                   #
#                           Developed by Charles Thai                               #
#####################################################################################

<#

    .DESCRIPTION
        An automated script used to deploy Windows PCs with little to no user intervention.
    
    .NOTES
        This script requires elevated privileges as well as running the latest Windows operating system.

#>

# This script must be started with elevated user rights.
#Requires -RunAsAdministrator

Clear-Host
Write-Host " _____ ____    _____ _____ ____ _   _ _   _  ___  _     ___   ______   __" -ForegroundColor Green
Write-Host "|___ /|  _ \  |_   _| ____/ ___| | | | \ | |/ _ \| |   / _ \ / ___\ \ / /" -ForegroundColor Green
Write-Host "  |_ \| |_) |   | | |  _|| |   | |_| |  \| | | | | |  | | | | |  _ \ V / " -ForegroundColor Green
Write-Host " ___) |  _ <    | | | |__| |___|  _  | |\  | |_| | |__| |_| | |_| | | |  " -ForegroundColor Green
Write-Host "|____/|_| \_\   |_| |_____\____|_| |_|_| \_|\___/|_____\___/ \____| |_|`n  " -ForegroundColor Green
Write-Output "#######################################################################"
Write-Output "#                            DEPLOY ME v4.0                           #"
Write-Output "#                           WORK IN PROGRESS                          #"
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

# Enter an IP or website to ping.
$TestWebsite = '3rtechnology.com'

<# Limit the script to run on a certain Windows operating system based on the build number.
    Example:
    - Windows 7 = 7601
    - Windows 8 = 9002
    - Windows 10 (1507) = 10240
    - Windows 11 = 22000 or later

#>
$PreferredOSBuild = 22000

#############################
#   RUN MICROSOFT UPDATES   #
#############################

# Update Categories
$UpdateCatalog = @(
    'Critical Updates',                 # <-- [0] 20XX-XX Update for Windows XX Version 2XXX for [ANY ARCHITECTURE]-based Systems. Includes Microsoft Office updates.
    'Definition Updates',               # <-- [1] AKA Security Intelligence Updates.
    'Drivers',                          # <-- [2] Self-explantory.
    'Feature Packs',                    # <-- [3] New product functionality that is first distributed outside the context of a product release and that is typically included in the next full product release.
    'Security Updates',                 # <-- [4] Cumulative Updates also counts as "Security Updates".

    'Service Packs',                    # <-- [5] A tested, cumulative set of all hotfixes, security updates, critical updates, and updates. Additionally, service packs
                                                # may contain additional fixes for problems that are found internally since the release of the product. Service packs may
                                                # also contain a limited number of customer-requested design changes or features.
                                                
    'Tools',                            # <-- [6] A utility or feature that helps complete a task or set of tasks.
    'Update Rollups',                   # <-- [7] Windows Malicious Software Removal Tool.
    'Updates',                          # <-- [8] Combination of security, definition, and critical updates.
    'Upgrades'
)


# List the updates you want the PC to download and install by the Update Categories above.
$Category = $UpdateCatalog[2,7,8]

# Exclude any updates that causes Microsoft Update to fail based by their Knowledge Base (KB) ID.
$ExcludeKB = @(

)

<# Exclude Preview Updates.
- Removing the hashtag (#) before the dollar sign ($) will include preview updates. (This is the default option)
- Adding the hashtag(#) before the dollar sign ($) will exclude preview updates.
#> 
$NoPreview = 'Preview'

#############################
#        DEPLOYMENT         #
#############################

# Specify the previous username.
$Username = 'Refurb'

###############################################
#          Editable Variables End             #
###############################################

######################################################################################
# No edits should take place beyond this comment unless you know what you're doing!  #
# All changes should be made in the Variables section.                               #
######################################################################################

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
            # If failed 5 times, display a warning message and open up the directory to the batch file and abort script.
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


function Request-OSBuild {
    [CmdletBinding()]
    Param()

    BEGIN {
        Write-Output 'Checking the host operating system.'
        # Retrieve current host operating system
        $CurrentOS = (Get-CimInstance -ClassName Win32_OperatingSystem).BuildNumber

        # Preferred operating system
        $RequiredOS = $PreferredOSBuild

        start-sleep -Seconds 3
    } #END BEGIN

    PROCESS {
        if ($CurrentOS -lt $RequiredOS) {
            Write-Warning "This operating system does not meet the requirements. Please "
            start-sleep -Seconds 3
            exit 
        } #End if 
        else {
            continue
        } #end else
    } #END PROCESS

    END {
        if ($CurrentOS -ge $RequiredOS) {
            Write-Output ''
        }
    } #END
}# End function Request-OSBuild


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
                
                # Restart the script if this cmdlet fails.
                Write-Warning 'Restarting script'
                start-sleep 5
                Invoke-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat"
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
    END {} #END
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
                Write-Warning "An error has occurred that could not be resolved. Restarting script..."
                Start-Sleep -Seconds 3
                if ((Test-Path -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat") -eq $true) {
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
                        Write-Warning "An error has occurred that could not be resolved. Restarting script..."
                        Start-Sleep -Seconds 3
                        if ((Test-Path -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat") -eq $true) {
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
            Write-Warning "PSWindowsUpdate was not imported properly! Restarting script..."
            Start-Sleep -Seconds 3
            if ((Test-Path -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat") -eq $true) {
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
            Write-Warning 'PSWindowsUpdate is not imported! Restarting script...'
            Start-Sleep -Seconds 3
            if ((Test-Path -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat") -eq $true) {
                Invoke-Item -Path "$env:ProgramData/Microsoft/Windows/Start Menu/Programs/StartUp/AutoDeployment.bat"
            } #End if
            exit
        } #end if
    } #END BEGIN
    PROCESS {
        try {
            # Download and install drivers. Exclude preview updates.
            while ((Get-WUList -Category $Category -NotTitle $NoPreview).Size -gt 0) {
                Get-WUList -Category $Category -NotTitle $NoPreview -AcceptAll -Install -AutoReboot | Format-List Title, KB, Size, Status, RebootRequired
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
                Write-Warning "An error has occurred that could not be resolved. Please remove the account manually."
                Start-Process "ms-settings:otherusers"
            }#End Catch
        } #End Else
    }#END PROCESS
    END {}#END
} #End function Remove-RefurbAccount







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
