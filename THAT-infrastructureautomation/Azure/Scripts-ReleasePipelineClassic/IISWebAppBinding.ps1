param ($websiteName, $bindingIpAddress,$hostHeader,$project);
Import-Module WebAdministration;
Write-Host "Input Paramaters: "
Write-Host "WebsiteName = $websiteName"
Write-Host "Binding IP = $bindingIpAddress"
Write-Host "Host Header for binding  = $hostHeader"
Write-Host "Project  = $project"
#cover 90% of the cases where we don't want the extra ".com" as part of the binding; this will also cause issues with the wildcard SSL
[regex]$pattern = "\.us|\.com|\.org|\.biz|\.cc|\.net"
$cleanProjectName = $pattern.replace($project, "", 1)
Write-Host "Sanitizing project name = $cleanProjectName"
$fullHostHeader = "{0}.{1}" -f $cleanProjectName, $hostHeader
Write-Host "Binding Host Header = $fullHostHeader"
$HttpBinding = $null
try{
    #some verisons of powershell do not deal with get call with nulls; 
    $HttpBinding = (Get-WebBinding -Name $websiteName -HostHeader $fullHostHeader -Protocol "http")
    }
catch{
}

if($null -eq $HttpBinding)
{
    Write-Host "Adding Binding for $fullHostHeader..."
    New-WebBinding -Name "$websiteName" -IPAddress "$bindingIpAddress" -Port 80 -Protocol "http" -HostHeader "$fullHostHeader"
}
else {
    Write-Host "Http binding already exists! Skipping binding"
}

Write-Host "Finished"
