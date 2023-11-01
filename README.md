<!-- Project Name and Description-->
# Auto Deployment (AutoDeploy) Script
<!-- Brief Description -->
A script used to automate the deployment of Microsoft Windows PCs. This script was developed for my workplace (3R Technology) to automate the process of how I process PC deployments.
<!-- Features -->
## Features
Key features of AutoDeploy are:
- Uses the PSWindowsUpdate module to retrieve all the latest updates and stable drivers.
- Has an Internet connectivity test which test whether the PC has Internet connectivity before running the script.
<!-- Prerequisites -->
## Prerequisites
The script requires that you have an Internet connection (For PSWindowsUpdate), and the user has administrative privileges for the script to work. The script will not work if any of these conditions aren't met.

It is generally recommended that you use this script on a reference image as the script is meant to be used for deploying on various PCs.

## Installation Guide
The repository release comes with three files that are bundled into this script:
- InstallAutoDeploy.bat
- AutoDeployment.bat
- AutoDeploy_vX.X.ps1 (X represents the version number)

