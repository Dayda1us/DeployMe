<!-- Project Name and Description-->
# Windows Auto Deployment (AutoDeploy) Script
<!-- Brief Description -->
An automated script that deploys Windows PCs written in PowerShell.

<!-- About this Project -->
## About this Project
This script was developed for the purpose of automating deployments for refurbished PCs by updating the PC to the latest patches and retrieving drivers from Microsoft Update. The script has the ability to add a Windows product key for refurbished PCs by launching an application called Key Deploy.

Prior to the creation of this script, PC deployments were done manually by having an ITAD technician interact with each computer. With the creation of this script, this reduces the workload of interacting with the PCs which allows the ITAD technicians to perform other duties while the deployed PCs are automated.

<!-- Features -->
## Features
- Uses PSWindowsUpdate which allows the script to retrieve Windows updates and drivers from PowerShell.
- The script has the ability to automatically sync the date and time when the computer's current time/date is out of sync.
- The script can deploy Windows product keys on refurbished PCs which runs an application called Key Deploy.
<!-- How the script works -->
## How does the script work?

Launching the script will perform a prerequisite check which is checking for Internet connectivity.
