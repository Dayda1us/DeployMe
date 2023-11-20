function Register-MicrosoftKey {
    [CmdletBinding()]
    Param()
    BEGIN {
        $Title       = 'KeyDeploy'
        $Description = 'You are about to launch KeyDeploy. If this PC is not connected to the deployment station, please power off the PC and move it to the deployment station.'
        $Yes         = New-Object System.Management.Automation.Host.ChoiceDescription "&Y", "Launch KeyDeploy"
        $No          = New-Object System.Management.Automation.Host.ChoiceDescription "&N", "Don't launch KeyDeploy. You will be prompt if you would like to shutdown your PC."
        $Options     = [System.Management.Automation.Host.ChoiceDescription[]]($Yes,$No)
        $Default     = 1    # 0 = Yes, 1 = No

        do {
            $KDResponse = $Host.UI.PromptForChoice($Title, $Description, $Options, $Default)
            if ($KDResponse -eq 0) {break}
        } until ($KDResponse -eq 1)
    } #BEGIN
    PROCESS {
        if ($KDResponse -eq 0) {
            Write-Output "Opening KeyDeploy..."
            <# TEST ONLY #> Invoke-Item -Path "$env:WINDIR\notepad.exe"
            #Invoke-Item -Path "$env:WINDIR\MARFO_SCRIPTS\Startup\DTStartup.exe"
            $Process = 'DTStartup'
            do {
                Write-Output "$Process is open"
                start-sleep -Seconds 2
            } while ((Get-Process -name $Process -EA SilentlyContinue).name -contains $Process) #dowhile
        }
        else {
            $Description = "Would you like to turn off your PC?"
            $Yes         = New-Object System.Management.Automation.Host.ChoiceDescription "&Y", "Shut down the PC."
            $No          = New-Object System.Management.Automation.Host.ChoiceDescription "&N", "Do not shut down the PC."
            $Options     = [System.Management.Automation.Host.ChoiceDescription[]]($Yes,$No)
            $Default     = 1    # 0 = Yes, 1 = No
            do {
                $ShutdownResponse = $Host.UI.PromptForChoice($Title, $Description, $Options, $Default)
                if ($ShutdownResponse -eq 0) {
                    Write-Warning 'PC is shutting down'
                    start-sleep -Seconds 2
                    #Stop-Computer -Force
                    break
                }
            } until ($ShutdownResponse -eq 1)
        } #if ($KDResponse -eq 0)
    }# PROCESS
    END {
        if ($KDResponse -ne 0 -and $ShutdownResponse -ne 0) {
            Write-Output 'OK! Skipping product key deployment'
        } elseif ($KDResponse -ne 0 -and $ShutdownResponse -ne 1) {
            Write-Output 'PC currently shutting down.'
            break
        } else {
            Write-Host 'The operation was successful.' -ForegroundColor Green
            Write-Output "`nMake sure to leave a put a square holographic Microsoft Authorized Refurbisher sticker on the bottom of the unit, or as close to the original Windows sticker as possible."
            Write-Output "If this is a citzenship PC, only put a Microsoft Office for Citizenship key sticker. Citizenship PCs does not get a holographic sticker.`n"
            Write-Warning "If you are deploying a non-citzenship PC, please make sure to report this to the MDOS Smart Client."
            start-sleep 10
        }#if/elseif/else ($KeyDeployPrompt -ne 0 -and $ShutdownResponse -ne 0)
    }# END
}
