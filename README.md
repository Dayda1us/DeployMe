# Windows-AutoUpdate

BETA 3 CHANGELOGS:

NEW:
1. Added clear commands on line 110, 125, and 139 for easier reading
2. Added ECHO commands on line 101 and 104 to auto prompt the Windows Update Service Manager verfication
3. Add Get-WUList cmdlet on Stage 3 of Microsoft Updates
4. Added a break command when an update requires a reboot to prevent the script from running.

REVISIONS:
1. Revised line 180-187 from "RemoteSigned" to "Restricted" as the default ExecutionPolicy
2. Revised line 146 by changing the switch parameter from "-MicrosoftUpdate" to "-WindowsUpdate", so the WU client can grab the security updates. 
3. Changed the alias from clear to Clear-Host

BUGFIXES:
1. Fixed a bug on line 165 where 
2. Changed the operator switch from -contains to -eq on line 62
3. Added Set-PSRepository -Name PSGallery -InstallationPolicy Trusted on line 68 in the else statement
4. Added $Install_Policy variable on line 187 to fix the if statement.
5. Fixed wording on line 207 that said "RemoteSigning" when it supposed to switch to "Restricted."
6. Fixed output message for Updates: "Write-Output "Checking for any updates that requires a reboot..."
