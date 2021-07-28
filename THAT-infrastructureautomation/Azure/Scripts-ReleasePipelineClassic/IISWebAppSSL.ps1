param ($websiteName, $sslCertName, $bindingIpAddress, $sslCertStore = "WebHosting");
Import-Module WebAdministration;
Write-Host "Input Paramaters: ";
Write-Host "WebsiteName = $websiteName";

Write-Host "SSL Cert Name = $sslCertName";
Write-Host "Binding IP = $bindingIpAddress";
Write-Host "Certificate Store = $sslCertStore";

if([string]::IsNullOrWhiteSpace($sslCertName))
{
    Write-Host "Missing Certificate Name....Skipping SSL";    
}
else {
    $Thumbprint = (Get-ChildItem -Path Cert: -Recurse | Where-Object {$_.FriendlyName -like "*$sslCertName*" -and $_.NotAfter -gt (get-date).AddDays.(30)} | Select-Object -First 1).Thumbprint;
    Write-Host "Assigning Wildcard cert with Thumbprint: $Thumbprint";
    
    $HttpsBinding = $null
    try{
        #some verisons of powershell do not deal with get call with nulls; 
        $HttpsBinding = (Get-WebBinding -Name "$websiteName" -Protocol "https")
        }
    catch{
    }
    if($null -eq $HttpsBinding)
    {
        Write-Host "Getting Http Binding from site name"
        #pull the first http binding...doesn't matter what it is we are going to use it for the first SSL/HTTPS binding
        $HttpBinding = (Get-WebBinding -Name $websiteName -Protocol "http")
        $hostHeader = ($HttpBinding -split ":")[-1]
        Write-Host "Host Header for https: $hostHeader"
        New-WebBinding -Name "$websiteName" -IPAddress "$bindingIpAddress" -Port 443 -Protocol "https" -HostHeader "$hostHeader" -SslFlags 1
        Write-Host "Adding Wildcard Https Binding...";
        (Get-WebBinding -Name "$websiteName" | where-object {$_.protocol -eq "https"}).AddSslCertificate($Thumbprint, $sslCertStore)
    }
    else
    {
    Write-Host "Site already has at least one binding...skipping adding Https binding"
    }        
}
Write-Host "Finished"
