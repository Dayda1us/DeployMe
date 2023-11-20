<!-- Project Name and Description-->
# Auto Deployment (AutoDeploy) Script
<!-- Brief Description -->
A script used to automate the deployment of Microsoft Windows PCs. This script was developed for my workplace (3R Technology) to automate the process of how I process PC deployments.

<!-- About this Project -->
## About this Project
This script was created for the purpose to reduce the workload of having to manually deploy refurbished computers. 3R Technology deploys around 30 to 50 refurbished computers a day and the process of deployments were all done by having a user interact with each computers. The script automatically retrieves the updates from Microsoft, and stable hardware drivers automatically inserts a Windows Refurbish product key via Deploykey, thus significantly reduces the amount of man hours having to deploy if it were to be done by hand.

<!-- Features -->
## Features
- Uses PSWindowsUpdate to automatically grabs software updates and stable drivers from Microsoft.
- Has the ability to automatically sync the timezone when a deployed PC has an out-of-sync clock.
<!-- Prerequisites -->
## Prerequisites
You must have an Internet connection for this script to work due to PSWindowsUpdate pulling updates from Microsoft. The script also be run with administrative privileges.
<!-- Getting Started -->
## Getting Started
To get started, download the following files listed in the release repository:

- AutoDeploy.ps1
- AutoDeployment.bat
- 
<!-- Installation Guide -->
### Installation Guide
If you have an offline reference image that is setup in "Audit" mode, here are the steps of adding these two files. For this example, I will be using Microsoft Hyper-V.
1. Navigate to where you store your .vhd/.vhdx files. (By default, the VM files are stored in C:\ProgramData\Microsoft\Hyper-V"
2. Double click on the virtual disk that holds the reference image. Windows will automatically mount the disk for you. If the virtual disk fails to open, either you can mount it via terminal, or the virtual disk is corrupted
3. Drag "AutoDeploy_vX.X.ps1" into the reference image
4. Navigate to ".\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup". You may need to enable "Show Hidden Files" for 
5. Drag "AutoDeployment.bat" into the startup folder. What this will do is run the script when the computer starts up.
