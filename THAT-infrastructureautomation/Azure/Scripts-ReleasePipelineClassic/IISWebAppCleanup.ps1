param ($physicalPath)
Write-Host "Cleaning up from transforms....";
Write-Host "Deleting from $physicalPath";
if([string]::IsNullOrWhiteSpace($physicalPath))
{
    Write-Host "Missing Physical Path...Skipping Cleanup";    
}
else {
    Get-ChildItem -Path $physicalPath -File -filter Web.*.config | Remove-Item -Verbose;
    Get-ChildItem -Path $physicalPath -File -filter UmbracoForms.*.config -Recurse | Remove-Item -Verbose;
    Get-ChildItem -Path $physicalPath -File -filter UmbracoSettings.*.config -Recurse | Remove-Item -Verbose;
}
