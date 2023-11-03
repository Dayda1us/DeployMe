<!-- Project Name and Description-->
# Auto Deployment (AutoDeploy) Script
<!-- Brief Description -->
A script used to automate the deployment of Microsoft Windows PCs. This script was developed for my workplace (3R Technology) to automate the process of how I process PC deployments.

<!-- About this Project -->
## About this Project
The purpose of creating this script was to reduce the workload of manually deploying computers. 3R Technology deploys around 30-50 refurbished computers a day and the process of deployments were all done by having a user interact with each computers. This script automatically grabs the updates from Microsoft and automatically inserts a Windows Refurbish product key via Deploykey, thus significantly reduces the amount of man hours having to deploy if it were to be done by hand.

<!-- Features -->
## Features
Key features of AutoDeploy are:
- Uses the PSWindowsUpdate module to retrieve all the latest updates and stable drivers.
- Has an Internet connectivity test which test whether the PC has Internet connectivity before running the script.
<!-- Prerequisites -->
## Prerequisites
The script requires that you have an Internet connection (For PSWindowsUpdate), and the user has administrative privileges for the script to work. The script will not work if any of these conditions aren't met.

It is generally recommended that you use this script on a reference image as the script is meant to be used for deploying on various PCs.
<!-- Getting Started -->
## Getting Started
To get started, download the following files that are listed in the release repository

- AutoDeploy_vX.X.ps1*
- AutoDeployment.bat

*The 'x' denotes the version number.

There is an optional file called "Install_AutoDeployment.bat" if you wish to not add the two files into an offline reference image.
### Installation Guide (Reference Image)
If you have an offline reference image that is in "Audit" mode, here are the steps of adding these two files. For this example, I will be using Microsoft Hyper-V.
1. Navigate to where you store your .vhd/.vhdx files. (By default, the VM files are stored in C:\ProgramData\Microsoft\Hyper-V"
2. Double click on the virtual disk that holds the reference image. Windows will automatically mount the disk for you. If the virtual disk fails to open, either you can mount it via terminal, or the virtual disk is corrupted
3. Drag "AutoDeploy_vX.X.ps1" into the reference image
4. Navigate to .\ProgramData\Microsoft\Windows\Start Menu\Startup
5. Drag "AutoDeployment.bat" into the startup folder. What this will do is run the script when the computer starts up.
