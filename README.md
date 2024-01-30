<!-- Project Name and Description-->
# Windows Auto Deployment (AutoDeploy) Script

<!-- Brief Description -->
A simple automated script that deploys Windows PCs written in PowerShell.

<!-- About this Project -->
## About this Project
This script was developed for the purpose of automating PC deployments for refurbished units. Prior to the development of this script, all PC deployments were done manually by having an ITAD technician interact with each computer. This script helps alleviate the workload of interacting with the PCs which allows technicians to perform other duties while the deployed PCs are being automated.

<!-- Features -->
## Key Features
- Utilizes the PSWindowsUpdate module to retrieve Microsoft Updates using PowerShell.
- Has the ability to automatically sync the date/time of the computer.
- The script automatically launches an application called KeyDeploy which inserts a Windows product key specifically for refurbished PCs.
- Checks for Internet connectivity before launching the script.
