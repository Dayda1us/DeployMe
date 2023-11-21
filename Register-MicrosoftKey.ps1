function Register-MicrosoftKey {
    [CmdletBinding()]
    Param()
    BEGIN {
        $Title       = 'KeyDeploy'
        $Description = 'You are about to launch KeyDeploy. If this PC is not connected to the deployment station, please move the PC to the deployment station.'
        $Yes         = New-Object System.Management.Automation.Host.ChoiceDescription "&Y", "Launch KeyDeploy"
        $No          = New-Object System.Management.Automation.Host.ChoiceDescription "&N", "Skip this step. This option will open a window the KeyDeploy directory if available."
        $Shutdown    = New-Object System.Management.Automation.Host.ChoiceDescription "&Shutdown", "Shutdown your PC. Use this option if you're deploying a desktop."
        $Options     = [System.Management.Automation.Host.ChoiceDescription[]]($Yes, $No, $Shutdown)
        $Default     = 1    # 0 = Yes, 1 = No

        do {
            $KDResponse = $Host.UI.PromptForChoice($Title, $Description, $Options, $Default)
            if ($KDResponse -eq 0) {
                return 0 | Out-Null
            }
            elseif ($KDResponse -eq 2) {
                return 2 | Out-Null
            }
        } until ($KDResponse -eq 1)
    } #BEGIN
    PROCESS {
        switch ($KDResponse) {
            {$KDResponse -eq 0} {
                Write-Output "Opening KeyDeploy..."
                <# TEST ONLY #> Invoke-Item -Path "$env:WINDIR\notepad.exe"
                if ((Test-Path -Path "$env:WINDIR\MARFO_SCRIPTS\Startup\DTStartup.exe") -eq $true) {
                    #Invoke-Item -Path "$env:WINDIR\MARFO_SCRIPTS\Startup\DTStartup.exe"
                }
                $Process = 'notepad'
                do {
                    start-sleep -Seconds 1
                } while ((Get-Process -name $Process -EA SilentlyContinue).name -contains $Process) #dowhile
            } #{$KDResponse -eq 0}
            {$KDResponse -eq 2} {
                Write-Warning 'PC is shutting down'
                start-sleep -Seconds 2
                Stop-Computer -Force -WhatIf
                return 2 | Out-Null
            } #{$KDResponse -eq 2}
            default {
                return 1 | Out-Null
            } #default
        } #switch ($KDResponse)
    }# PROCESS
    END {
        if ($KDResponse -eq 1) {
            Write-Output 'OK! Skipping product key deployment'
            # This if statement will work if the KeyDeploy files are available.
            if ((Test-Path -Path "$env:WINDIR\MARFO_SCRIPTS\Startup\") -eq $true) {
                Invoke-Item -Path "$env:WINDIR\MARFO_SCRIPTS\Startup\"
            } #if ((Test-Path -Path "$env:WINDIR\MARFO_SCRIPTS\Startup\") -eq $true)
        }
        elseif ($KDResponse -eq 2) {
            Write-Output 'PC currently shutting down.'
            break
        } else {
            Write-Host 'The operation was successful.' -ForegroundColor Green
            Write-Output "`nMake sure to leave a put a square holographic Microsoft Authorized Refurbisher sticker on the bottom of the unit, or as close to the original Windows sticker as possible."
            Write-Output "If this is a citzenship PC, only put a Microsoft Office for Citizenship key sticker. Citizenship PCs does not get a holographic sticker.`n"
            Write-Warning "If you are deploying a non-citzenship PC, please make sure to report this to the MDOS Smart Client."
            Start-Sleep -Seconds 10
        }#if/elseif/else ($KDResponse -eq 1)
    }# END
} #function Register-MicrosoftKey