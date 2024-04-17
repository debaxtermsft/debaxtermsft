<# 
Written by Derrick Baxter
4/17/2024
Retrieves by graphapi users createdDateTime between dates
pick the signin activity below (unrem) and run
Update the $outputfile location from c:\temp\name as wanted - date and .csv are automatically added to avoid overwritting  

IMPORTANT!!!

TenantID is not required but recommended
.\Search_Users_CreatedDateTime.ps1 
-tenantID "tenantID" 
-startDate "01/01/2024" 
-endDate "03/31/2024" 
-Outputdirectory "c:\temp\"

Running without TenantID 
.\Search_Users_CreatedDateTime.ps1 
-startDate "01/01/2024" 
-endDate "03/31/2024" 
-Outputdirectory "c:\temp\"

Just a startDate
.\Search_Users_CreatedDateTime.ps1 
-tenantID "tenantID" 
-startDate "01/01/2024" 
-Outputdirectory "c:\temp\"

Just an endDate
.\Search_Users_CreatedDateTime.ps1 
-tenantID "tenantID" 
-endDate "01/01/2024" 
-Outputdirectory "c:\temp\"

To consent for users to run this script a global admin will need to run the following
-------------------------------------------------------------------------------------------

$sp = get-mgserviceprincipal | ?{$_.displayname -eq "Microsoft Graph"}
$resource = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"
$principalid = "users object id"
$scope1 ="directory.read.all"
$scope3 ="user.read.all"
$today = Get-Date -Format "yyyy-MM-dd"
$expiredate1 = get-date
$expiredate2 = $expiredate1.AddDays(365).ToString("yyyy-MM-dd")
$params = @{
    ClientId = $SP.Id
    ConsentType = "Principal"
    ResourceId = $resource.id
    principalId = $principalid
    Scope = "$scope1" + " " + "$scope2"+ " " + "$scope3"
    startTime = "$today"
    expiryTime = "$expiredate2"
    
}

$InitialConsented = New-MgOauth2PermissionGrant -BodyParameter $params
-------------------------------------------------------------------------------------------
You may need to update the connect-mggraph to have the -environment USGov or as needed -tenantid <tenantid> can be added as needed.



#>

param([parameter(mandatory=$false)][string]$tenantID,
            [parameter (mandatory)][string]$startDate,
            [parameter (mandatory)][string]$endDate,
            [parameter(mandatory)] [string]$Outputdirectory)

If(!$tenantID)
{           
    connect-mggraph -scopes "directory.read.all, user.read.all" #-TenantId <tenantid>
}
else
{
    connect-mggraph -scopes "directory.read.all, user.read.all" -TenantId $tenantID
}

if(!$startDate)
{
	$users = get-mguser -all -Property displayname, createdDateTime, userprincipalname | select displayname, userprincipalname, createdDateTime  |  where-object { $_.createdDateTime -le (Get-Date($endDate)) }
}
elseif(!$endDate)
{
	$users = get-mguser -all -Property displayname, createdDateTime, userprincipalname | select displayname, userprincipalname, createdDateTime  |  where-object { $_.createdDateTime -gt (Get-Date($startDate))}
}
else
{
	$users = get-mguser -all -Property displayname, createdDateTime, userprincipalname | select displayname, userprincipalname, createdDateTime  |  where-object { $_.createdDateTime -gt (Get-Date($startDate)) -and $_.createdDateTime -le (Get-Date($endDate)) }
}

$CreatedDateTimeProperties =@()

foreach($item in $users)
{
     $CreatedDateTimeProperties += New-Object Object |
                                Add-Member -NotePropertyName DisplayName -NotePropertyValue $item.displayname -PassThru |
                                Add-Member -NotePropertyName UserprincipalName -NotePropertyValue $item.userprincipalname-PassThru |
                                Add-Member -NotePropertyName CreatedDateTime -NotePropertyValue $item.createdDateTime -PassThru 
}

$tdy = get-date -Format "MM-dd-yyyy_hh.mm.ss"
$outputfile = $outputdirectory+"exportuserscreatedDateTime_"+$tdy+".csv"
$CreatedDateTimeProperties | export-csv -Path $outputfile -NoTypeInformation -Encoding UTF8

