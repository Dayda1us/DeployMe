<!-- Project Name and Description-->
# Auto Deployment (AutoDeploy) Script
<!-- Brief Description -->
An automated script that is used to update Windows PCs and deploy WIndows Refurbish Product Keys.

<!-- About this Project -->
## About this Project
The script was developed for my workplace that primarily deals with IT Asset Disposal (ITAD). The purpose of this script is to automate the deployment of refurbished PCs by updating to the latest patches from Microsoft and retrieve a new Microsoft Windows product key as the company is an Authorized Microsoft Refurbisher (MAR). 

The company that I work for deploys around 30 to 50 refurbished computers a day. Prior to the creation of this script, all deployments were done manually by having the technician interact with each computers. With this script, this significantly reduces the workload.

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
