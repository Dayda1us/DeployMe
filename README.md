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
<!-- How the script works -->
## How does the script work?
When you first start the script on a reference image, it displays the 
