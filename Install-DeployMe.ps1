<#

    .DESCRIPTION
        The Install-DeployMe cmdlet installs the script and startup batch file on the computer.
    
    .NOTES
        For the script to work, the three required files are needed for this script to run properly:
        - AutoDeploy.ps1
        - DeployMe.ps1
        - AutoDeployment.bat

#>



#Requires -RunAsAdministrator
#Requires -Version 5.1

#Retrieve the build number of the operating system.
$OSBuildNumber = [System.Environment]::OSVersion.Version.Build
$deployScript = @("AutoDeploy.ps1", "DeployMe.ps1","AutoDeployment.bat")

#Grab the drive where the script is running from.
$currentDrive = $PSCommandPath[0..2] -join ""

# Install DeployMe.ps1 if the computer is running Windows 11 or later.
if ($OSBuildNumber -ge 22000) {
    if ((Test-Path -Path "$($currentDrive)\$($deployScript[1])") -and (Test-Path -Path "$($currentDrive)\$($deployScript[2])")) {
        Write-Warning "Copying $($deployScript[1]) and the startup batch file..."
        Start-Sleep -Seconds 2
        try {
            Copy-Item -Path "$($currentDrive)\$($deployScript[1])" -Destination "$($env:HOMEDRIVE)\"
            Copy-Item -Path "$($currentDrive)\$($deployScript[2])" -Destination "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\"

            # Start the batch file to start the script.
            if (Test-Path -Path "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\$($deployScript[2])") {
                Write-Output "Launching $deployScript[1]"
                Invoke-Item -Path "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\$($deployScript[2])"
            } #end if
        } #end try
        catch {
            Write-Warning "An error has occurred!"
            Write-Host $_ -ForegroundColor Red
            start-sleep -Seconds 5
            exit
        } #end catch
    } #end if
    else {
        Write-Warning "Could not locate $($deployScript[1]) and $($deployScript[2])."
        Write-Host $_ -ForegroundColor Red
        Start-Sleep -Seconds 5
        exit
    } #end else
} #end if

# Install AutoDeploy.ps1 if the computer is running Windows 10.
elseif (-not($OSBuildNumber -ge 22000)) {
    if ((Test-Path -Path "$($currentDrive)\$($deployScript[0])") -and (Test-Path -Path "$($currentDrive)\$($deployScript[2])")) {
        Write-Warning "Copying $($deployScript[0]) and the startup batch file..."
        Start-Sleep -Seconds 2
        try {
            Copy-Item -Path "$($currentDrive)\$($deployScript[0])" -Destination "$($env:HOMEDRIVE)\"
            Copy-Item -Path "$($currentDrive)\$($deployScript[2])" -Destination "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\"

            # Start the batch file to start the script.
            if (Test-Path -Path "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\$($deployScript[2])") {
                Write-Output "Launching $deployScript[0]"
                Invoke-Item -Path "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\$($deployScript[2])"
            } #end if
        } #end try
        catch {
            Write-Warning "An error has occurred!"
            Write-Host $_ -ForegroundColor Red
            start-sleep -Seconds 5
            exit
        } #end catch
    } #end if
    else {
        Write-Warning "Could not locate $($deployScript[0]) and $($deployScript[2])."
        Write-Host $_ -ForegroundColor Red
        Start-Sleep -Seconds 5
        exit
    } #end else
} #end elseif

# Warn the user that this script only runs on Microsoft Windows 10 or later
else {
    Write-Warning "This script only works on Windows 10/11."
    Start-Sleep -Seconds 2
    exit
} #end else