param (
[parameter(Mandatory=$true)]
[string]
$appPoolName, 
[parameter(Mandatory=$false)]
[string]
$sqlDatabaseName, 
[parameter(Mandatory=$false)]
[string]
$sqlInstance,
#[parameter(Mandatory=$true)]
[string]
$sqlUsername,
[parameter(Mandatory=$false)]
[string]
$sqlPassword,
[parameter(Mandatory=$false)]
[string]
$defaultWorkingDirectory,
[parameter(Mandatory=$false)]
[string]
$releaseEnvironmentName)

#import for .NET password generation
Add-Type -AssemblyName System.Web

$dbRole = 'db_owner'
$releaseEnvironmentName = $releaseEnvironmentName.ToLower()

$connectionString = "server=$sqlInstance;database=master;user id=$sqlUsername;password=$sqlPassword;"

if([string]::IsNullOrEmpty($sqlInstance) -or [string]::IsNullOrEmpty($sqlDatabaseName)) 
{
    Write-Host "Database name not provided, OR SQL Instance not provided. Skipping database creation task. Exiting"
    return
}
#make sure the first char is a capital, took off the toLower preserve Client.Umbraco
$sqlDatabaseName = $sqlDatabaseName.substring(0,1).toupper() + $sqlDatabaseName.substring(1)
Write-Host "Checking for database exists ($sqlDatabaseName) at $releaseEnvironmentName..."
if (($releaseEnvironmentName -eq "dev") -or ($releaseEnvironmentName -eq "uat")) { 
	$databaseExists = invoke-sqlcmd -server $sqlInstance "select name from master.sys.databases where name = '$sqlDatabaseName';"
}
elseif ($releaseEnvironmentName -eq "prod staging") {
	
	$databaseExists = invoke-sqlcmd -ConnectionString $connectionString "select name from master.sys.databases where name = '$sqlDatabaseName';"
}
else {
	Write-Host "Unknown release enviornment. Expected debug, uat or prod staging. You sent $releaseEnvironmentName Exiting"
	return
}

Write-Output "Creating database: $sqlDatabaseName on $sqlInstance"
	
if (($releaseEnvironmentName -eq "dev") -or ($releaseEnvironmentName -eq "uat")) { 

    if ($databaseExists){
	    Write-Host $databaseExists.name 'SQL Database Already exists on target $sqlInstance Skipping'
    }		
    else
    {
        invoke-sqlcmd -ServerInstance $sqlInstance "CREATE DATABASE [$sqlDatabaseName];"
		Write-Output "Created database: $sqlDatabaseName on $($sqlInstance)"
	}

    $loginName = "IIS APPPOOL\{0}" -f $appPoolName;
	Write-Output "User account to be created: $loginName"
	$login = invoke-sqlcmd -ServerInstance $sqlInstance "select loginname from master.dbo.syslogins where name = '$loginName'"
	if ($login) {
		Write-Output "Login $login.loginname Already exists"
	} 
	else {
		invoke-sqlcmd -ServerInstance $sqlInstance "CREATE LOGIN [$loginName] FROM WINDOWS WITH DEFAULT_DATABASE=[master]"
		invoke-sqlcmd -ServerInstance $sqlInstance -Database $sqlDatabaseName "CREATE USER [$loginName] FOR LOGIN [$loginName]"
		Write-Output "Created User: $loginName on $sqlDatabaseName"
		invoke-sqlcmd -ServerInstance $sqlInstance -Database $sqlDatabaseName "ALTER ROLE [$dbRole] ADD MEMBER [$loginName]"
		Write-Output "Granted Role $dbRole to $loginName on $sqlDatabaseName"
	}	
}
#prod staging has a separate SQL machine
elseif ($releaseEnvironmentName -eq "prod staging") {
        if ($databaseExists){
	    Write-Host "$databaseExists.name - SQL Database Already exists on target $sqlInstance Skipping"
    }		
    else
    {
        invoke-sqlcmd -ConnectionString $connectionString "CREATE DATABASE [$sqlDatabaseName];"
		Write-Output "Created database: $sqlDatabaseName on $($sqlInstance)"
    }
    $connectionString = "server=$sqlInstance;database=$sqlDatabaseName;user id=$sqlUsername;password=$sqlPassword;"
    $loginName = "{0}User" -f $sqlDatabaseName;
    $login = invoke-sqlcmd -ConnectionString $connectionString "select loginname from master.dbo.syslogins where name = '$loginName'"

	if ($login) {
		Write-Output "Login $login.loginname Already exists"
	} 
	else {
        $loginPassword = [System.Web.Security.Membership]::GeneratePassword(24,5)
		invoke-sqlcmd -ConnectionString $connectionString "CREATE LOGIN [$loginName] WITH PASSWORD = '`$loginPassword', DEFAULT_DATABASE = [$sqlDatabaseName], CHECK_POLICY = OFF,CHECK_EXPIRATION = OFF;"					
		invoke-sqlcmd -ConnectionString $connectionString "CREATE USER [$loginName] FOR LOGIN [$loginName]"
		Write-Output "Created User: $loginName on $sqlDatabaseName"
		invoke-sqlcmd -ConnectionString $connectionString "ALTER ROLE [$dbRole] ADD MEMBER [$loginName]"
		Write-Output "Granted Role $dbRole to $loginName on $sqlDatabaseName"

        #Write-Output "Setting Connection String"
        #$projectConnectionString = "server=$sqlInstance;database=$sqlDatabaseName;user id=$loginName;password='$loginPassword';"

        #New-Item $defaultWorkingDirectory\connectionstring.txt
        #Add-Content -Path $defaultWorkingDirectory\connectionstring.txt -Value $projectConnectionString -Force 
        #Write-Host "Release: Uploading file from $defaultWorkingDirectory"
        #Write-Host "##vso[artifact.associate]$defaultWorkingDirectory"
        #Write-Host "##vso[artifact.upload containerfolder=drop;artifactname=connectionstring.txt;]$defaultWorkingDirectory\connectionstring.txt"
        #Write-Host ##vso[task.uploadfile]$defaultWorkingDirectory\connectionstring.txt
	}	
}
