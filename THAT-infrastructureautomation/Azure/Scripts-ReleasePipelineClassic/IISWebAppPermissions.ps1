param ($websiteName, $appPoolName);
Import-Module WebAdministration;
Write-Host "Input Paramaters: ";
Write-Host "WebsiteName = $websiteName";
Write-Host "Application Pool = $appPoolName";

$sitePath = Get-WebFilePath "IIS:\Sites\$websiteName";
Write-Host "IIS Site path...$sitePath";

$acl_www = Get-Acl -Path $sitePath;
$appPoolSid = (Get-ItemProperty IIS:\AppPools\$appPoolName).applicationPoolSid;
$identifier = New-Object System.Security.Principal.SecurityIdentifier $appPoolSid;
$accessRule_AppPool = New-Object System.Security.AccessControl.FileSystemAccessRule ($identifier,"Modify","ContainerInherit, ObjectInherit", "None", "Allow");
$acl_www.AddAccessRule($accessRule_AppPool);
Write-Host "Setting ACL for IIS AppPool Id {$appPoolSid}";
Set-Acl -Path $sitePath -AclObject $acl_www

Write-Host "Finished"


