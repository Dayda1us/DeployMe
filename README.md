<!-- Project Name and Description-->
# Windows Auto Deployment (DeployMe) Script

<!-- Brief Description -->
An automated script written in PowerShell to efficiently retrieve drivers and the latest patches from Microsoft Update.

<!-- About this Project -->
## About this Project
This script has been specifically designed to automate deployments for refurbished Windows PCs. Prior to the development of this script, all deployments were carried out manually. The implementation of this has reduced the workload for ITAD technicians, enabling them to focus on other essential tasks while deployments are automated.

<!-- Features -->
## Key Features
- Implemented PSWindowsUpdate module to retrieve Microsoft Updates via PowerShell
- Editable variables to customize behavior of the script
- Automatically synchronized the date/time of the PC
- Implemented Internet connectivity check prior to script execution
- Seal the refurbished PCs using Sysprep (OOBE)
