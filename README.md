<!-- Project Name and Description-->
# Auto Deployment (AutoDeploy) Script
<!-- Brief Description -->
A script used to automate the deployment of Microsoft Windows PCs. This script was developed for my workplace (3R Technology) to automate the process of how I process PC deployments.

<!-- About this Project -->
## About this Project
This script was created for the purpose to reduce the workload of manually deploying refurbished computers. 3R Technology deploys around 30 to 50 refurbished computers a day and the process of deployments were all done by having a user interact with each computers. The script automatically retrieves the updates from Microsoft, and stable hardware drivers automatically inserts a Windows Refurbish product key via Deploykey, thus significantly reduces the amount of man hours having to deploy if it were to be done by hand.

<!-- Features -->
## Features
- Leverages the PSWindowsUpdate module to retrieve all the latest updates and stable drivers.
- Has an Internet connectivity test which test whether the PC has Internet connectivity before running the script.
- Can automatically select the timezone and sync the clock if the PC clock is out of sync.
- 
<!-- Prerequisites -->
## Prerequisites
You must have an Internet connection for this script to work due to PSWindowsUpdate pulling updates from Microsoft. The script also be run with administrative privileges.

This script was designed to be installed into an offline reference image.
<!-- Getting Started -->
## Getting Started
To get started, download the following files listed in the release repository:

- AutoDeploy_vX.X.ps1*
- AutoDeployment.bat

*The 'x' denotes the version number.

### Installation Guide
If you have an offline reference image that is setup in "Audit" mode, here are the steps of adding these two files. For this example, I will be using Microsoft Hyper-V.
1. Navigate to where you store your .vhd/.vhdx files. (By default, the VM files are stored in C:\ProgramData\Microsoft\Hyper-V"
2. Double click on the virtual disk that holds the reference image. Windows will automatically mount the disk for you. If the virtual disk fails to open, either you can mount it via terminal, or the virtual disk is corrupted
3. Drag "AutoDeploy_vX.X.ps1" into the reference image
4. Navigate to ".\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup". You may need to enable "Show Hidden Files" for 
5. Drag "AutoDeployment.bat" into the startup folder. What this will do is run the script when the computer starts up.
