#Encrypt web.config appSettings and ConnectionStrings
param ($physicalPath)
Write-Host "Input Paramaters: "
Write-Host "Path = $physicalPath"
$cleanPath = "$physicalPath".TrimEnd('\')
Write-Host  "Encrypting the appSettings and connectionStrings section at web.config >> $cleanPath"
& "$env:windir\Microsoft.NET\Framework\v4.0.30319\aspnet_regiis.exe" -pef appSettings $cleanPath
& "$env:windir\Microsoft.NET\Framework\v4.0.30319\aspnet_regiis.exe" -pef connectionStrings $cleanPath