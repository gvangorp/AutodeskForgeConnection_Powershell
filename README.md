# Autodesk Forge Connection Powershell
This PowerShell script is meant to automate an Autodesk BIM 360 / Construction Cloud connection workflow from the Windows task scheduler on your desktop.  In this case it recurrently runs a file download to get the updated Revit file.
The script contains the 

#First setup
Follow these steps:
1. Create a new App on https://forge.autodesk.com/myapps/
2. Fill in the required variables in the PS1 file:
   - **AppFolder** writable folder to run the script in 'C:\TEMP\AutoRun\' 
   - **RedirectUrl** as defined in https://forge.autodesk.com/myapps/ e.g. http://localhost:8000/
   - **ClientID** from https://forge.autodesk.com/myapps/
   - **ClientSecret** from https://forge.autodesk.com/myapps/
   - **AutodeskFileGuid** if you would like to download a file. Steps to find the GUID: https://forge.autodesk.com/en/docs/data/v2/tutorials/download-file/
3. Run the script.
4. Click on the URL starting with	https://developer.api.autodesk.com/authentication/v1/authorize
   - Login with your Autodesk Account.
   - Click *Allow*
   - In the return URL path copy, the string behind the code and paste it in the command line.
   - Let the script run.
   - Make sure the LoginCredentials.log file is created in the **AppFolder**. If not the ps1 script does not have write access to the folder.
5. Add te ps1 to your Windows tasks scheduler. See https://www.windowscentral.com/how-create-automated-task-using-task-scheduler-windows-10
6. Make sure your desktop is turned on when the scheduled task is run.
