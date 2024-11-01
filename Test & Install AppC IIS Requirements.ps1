Import-Module ServerManager; 

#The list of Windows Features required by AppC
$features = @('Web-Server','Web-Static-Content','Web-Default-Doc','Web-Http-Errors','Web-Http-Redirect','Web-Asp-Net45','Web-Net-Ext45','Web-CGI','Web-ISAPI-Ext','Web-ISAPI-Filter','Web-Http-Logging','Web-Log-Libraries','Web-Request-Monitor','Web-Http-Tracing','Web-Windows-Auth','Web-Filtering','Web-IP-Security','Web-Mgmt-Console','Web-Scripting-Tools','Web-Mgmt-Service')

#The check and install each feature.
ForEach($feature in $features){
    $Object = Get-WindowsFeature $feature
    if ($object.Installed -eq $true){
        Write-Host $feature " already installed."
        }
        else {
            Add-WindowsFeature $feature
            Write-Host $feature " installed."
        }
}

#The check the status and start the Web Management Service.
#There could be edge cases where $svc is null if WMSVC was not succesfully installed above.
$svc = Get-Service WMSvc
Write-Host "WMSVC is" $svc.Status
if ($svc.Status -eq 'Stopped'){
    Write-Host "Starting..."
    Start-Service WMSVC
    $svc = Get-Service WMSvc
    Write-Host "WMSVC is" $svc.Status
}
