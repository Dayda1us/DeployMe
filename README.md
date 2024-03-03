<!-- Project Name and Description-->
# Windows Auto Deployment (AutoDeploy) Script

<!-- Brief Description -->
A simple automated script that deploys Windows PCs written in PowerShell.

<!-- About this Project -->
## About this Project
This script was developed for the purpose of automating deployments for refurbished PCs. Prior to the development of this script, all deployments were done manually by having an ITAD technician interact with each computer. This script helps alleviate the workload of interacting with the PCs which allows technicians to perform other duties while the deployments are being automated.

<!-- Features -->
## Key Features
- Utilizes the PSWindowsUpdate module to retrieve Microsoft Updates using PowerShell.
- Contains editable variables to modify the behavior of the script.
- Has the ability to automatically sync the date/time of the computer.
- Utilizes Sysprep to "seal" the PC for an Out-of-Box-Experience (OOBE).
- Checks for Internet connectivity before launching the script.
