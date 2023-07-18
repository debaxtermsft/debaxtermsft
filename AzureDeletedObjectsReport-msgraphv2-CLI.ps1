<#
Written By Derrick Baxter debaxter@microsoft.com
The below script uses the Azure Graph powershell module pulling all deleted objects (users/groups/spns/apps/devices)

written: 7/18/23
Users
.\AzureDeletedObjectsReport-msgraphv1_CLI.ps1 -deletedobjectquestion Users -Outputdirectory "c:\temp\"
Groups
.\AzureDeletedObjectsReport-msgraphv1_CLI.ps1 -deletedobjectquestion Groups -Outputdirectory "c:\temp\"
ServicePrincipals
.\AzureDeletedObjectsReport-msgraphv1_CLI.ps1 -deletedobjectquestion ServicePrincipals -Outputdirectory "c:\temp\"
Applications
.\AzureDeletedObjectsReport-msgraphv1_CLI.ps1 -deletedobjectquestion Applications -Outputdirectory "c:\temp\"
Devices
.\AzureDeletedObjectsReport-msgraphv1_CLI.ps1 -deletedobjectquestion Devices -Outputdirectory "c:\temp\"
All
.\AzureDeletedObjectsReport-msgraphv1_CLI.ps1 -deletedobjectquestion All -Outputdirectory "c:\temp\"
You may need to have a global admin run the below rem'ed script to consent to the user to run this script

$sp = get-mgserviceprincipal | ?{$_.displayname -eq "Microsoft Graph"}
$resource = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"
$principalid = "user object id"
$scope1 ="application.read.all"
$scope2 ="directory.read.all"
$today = Get-Date -Format "yyyy-MM-dd"
$expiredate1 = get-date
$expiredate2 = $expiredate1.AddDays(365).ToString("yyyy-MM-dd")
$params = @{
    ClientId = $SP.Id
    ConsentType = "Principal"
    ResourceId = $resource.id
    principalId = $principalid
    Scope = "$scope1" + " " + "$scope2"+ " "
    startTime = "$today"
    expiryTime = "$expiredate2"
}
$InitialConsented = New-MgOauth2PermissionGrant -BodyParameter $params


You may need to update the connect-mggraph to have the -environment USGov or as needed -tenantid <tenantid> can be added as needed.

#>
param([parameter(mandatory=$false)][string] $tenantID,
            [parameter (mandatory)][validateset("All", "Users","Groups","Applications","ServicePrincipals","Devices")] [string]$deletedobjectquestion,
            [parameter(mandatory)] [string]$Outputdirectory)

try
    {
    Get-MGDomain -ErrorAction Stop > $null
    }
catch
    {
    Connect-MgGraph -Scopes "directory.read.all, Application.Read.All"
    Select-MgProfile -Name "beta"
    }

$deletedapps =@()
$deletedspns = @()
$deletedusers =@()
$deletedgroups =@()
$deleteddevices =@()
$WarningPreference = "SilentlyContinue"  


switch -exact ($deletedobjectquestion) 
            {
                "Cancel" {exit}
                "Users"
                {
                    write-host "Reporting Deleted Users"
                }
                "Groups"
                {
                    write-host "Reporting Deleted Groups"
                }
                "Applications"
                {
                    write-host "Reporting Deleted Applications"
                }
                "ServicePrincipals"
                {
                    write-host "Reporting Deleted ServicePrincipals"
                }
                "Devices"
                {
                    write-host "Reporting Deleted Devices"
                }
                "All"
                {
                    write-host "Reporting All Deleted Objects"
                }
            }
   
  
try
    {
    Get-MGDomain -ErrorAction Stop > $null
    }
catch
    {
    Connect-MgGraph -Scopes "directory.read.all, Application.Read.All"
    Select-MgProfile -Name "beta"
    }

$deletedapps =@()
$deletedspns = @()
$deletedusers =@()
$deletedgroups =@()
$deleteddevices =@()

switch -exact ($deletedobjectquestion) 
            {
                "Cancel" {exit}
                "Users"
                {
                    $users = invoke-MgGraphrequest -Uri "https://graph.microsoft.com/beta/directory/deletedItems/microsoft.graph.user?&$count=true&$'orderBy=deletedDateTime+desc&$'select=id,displayName,deletedDateTime/organization" -Method GET -Headers @{ConsistencyLevel='eventual'}

                }
                "Groups"
                {
                    $groups = invoke-MgGraphrequest -Uri "https://graph.microsoft.com/beta/directory/deletedItems/microsoft.graph.group?&$count=true&$'orderBy=deletedDateTime+desc&$'select=id,displayName,deletedDateTime/organization" -Method GET -Headers @{ConsistencyLevel='eventual'}
                }
                "Applications"
                {
                    $apps = invoke-MgGraphrequest -Uri "https://graph.microsoft.com/beta/directory/deletedItems/microsoft.graph.application?&$count=true&$orderBy=deletedDateTime+desc&$select=id,displayName,deletedDateTime/organization" -Method GET -Headers @{ConsistencyLevel='eventual'}
                }
                "ServicePrincipals"
                {
                    $spns = invoke-MgGraphrequest -Uri "https://graph.microsoft.com/beta/directory/deletedItems/microsoft.graph.serviceprincipal?&$count=true&$orderBy=deletedDateTime+desc&$'select=id,displayName,deletedDateTime/organization" -Method GET -Headers @{ConsistencyLevel='eventual'}
                }
                "Devices"
                {
                    $devices = invoke-MgGraphrequest -Uri "https://graph.microsoft.com/beta/directory/deletedItems/microsoft.graph.device?&$count=true&$'orderBy=deletedDateTime+desc&$'select=id,displayName,deletedDateTime/organization" -Method GET -Headers @{ConsistencyLevel='eventual'}
                }
                "All"
                {
                    $apps = invoke-MgGraphrequest -Uri "https://graph.microsoft.com/beta/directory/deletedItems/microsoft.graph.application?&$count=true&$orderBy=deletedDateTime+desc&$select=id,displayName,deletedDateTime/organization" -Method GET -Headers @{ConsistencyLevel='eventual'}
                    $spns = invoke-MgGraphrequest -Uri "https://graph.microsoft.com/beta/directory/deletedItems/microsoft.graph.serviceprincipal?&$count=true&$orderBy=deletedDateTime+desc&$'select=id,displayName,deletedDateTime/organization" -Method GET -Headers @{ConsistencyLevel='eventual'}
                    $users = invoke-MgGraphrequest -Uri "https://graph.microsoft.com/beta/directory/deletedItems/microsoft.graph.user?&$count=true&$'orderBy=deletedDateTime+desc&$'select=id,displayName,deletedDateTime/organization" -Method GET -Headers @{ConsistencyLevel='eventual'}
                    $groups = invoke-MgGraphrequest -Uri "https://graph.microsoft.com/beta/directory/deletedItems/microsoft.graph.group?&$count=true&$'orderBy=deletedDateTime+desc&$'select=id,displayName,deletedDateTime/organization" -Method GET -Headers @{ConsistencyLevel='eventual'}
                    $devices = invoke-MgGraphrequest -Uri "https://graph.microsoft.com/beta/directory/deletedItems/microsoft.graph.device?&$count=true&$'orderBy=deletedDateTime+desc&$'select=id,displayName,deletedDateTime/organization" -Method GET -Headers @{ConsistencyLevel='eventual'}

                }
            }


If($deletedobjectquestion -eq "All" -or $deletedobjectquestion -eq "Applications")
    {
        $value = $apps.value
        foreach ($item in $value){
        $Deletedapps += New-Object Object |
                            Add-Member -NotePropertyName DisplayName -NotePropertyValue $item.displayname -PassThru |
                            Add-Member -NotePropertyName ID -NotePropertyValue $item.id -PassThru 
        }
    }
If($deletedobjectquestion -eq "All" -or $deletedobjectquestion -eq "ServicePrincipals")
    {
        $value = $spns.value
        foreach ($item in $value){
        $Deletedspns += New-Object Object |
                            Add-Member -NotePropertyName DisplayName -NotePropertyValue $item.displayname -PassThru |
                            Add-Member -NotePropertyName ID -NotePropertyValue $item.id -PassThru 
        }
    }
If($deletedobjectquestion -eq "All" -or $deletedobjectquestion -eq "Users")
    {
        $value = $users.value
        foreach ($item in $value){
        $Deletedusers += New-Object Object |
                            Add-Member -NotePropertyName DisplayName -NotePropertyValue $item.displayname -PassThru |
                            Add-Member -NotePropertyName ID -NotePropertyValue $item.id -PassThru 
        }
    }
If($deletedobjectquestion -eq "All" -or $deletedobjectquestion -eq "Groups")
    {
        $value = $groups.value
        foreach ($item in $value){
        $Deletedgroups += New-Object Object |
                            Add-Member -NotePropertyName DisplayName -NotePropertyValue $item.displayname -PassThru |
                            Add-Member -NotePropertyName ID -NotePropertyValue $item.id -PassThru 
        }
    }
If($deletedobjectquestion -eq "All" -or $deletedobjectquestion -eq "Devices")
    {
        $value = $devices.value
        foreach ($item in $value){
        $Deleteddevices += New-Object Object |
                            Add-Member -NotePropertyName DisplayName -NotePropertyValue $item.displayname -PassThru |
                            Add-Member -NotePropertyName ID -NotePropertyValue $item.id -PassThru 
        }
    }
#>

$tdy = get-date -Format "MM-dd-yyyy_hh.mm.ss"
$outputfile = "c:\temp\deletedapps_"+$tdy+".csv"
if($deletedapps -ne $null){$deletedapps | export-csv -path $outputfile -notypeinformation}
$outputfile = "c:\temp\deletedspns_"+$tdy+".csv"
if($deletedspns -ne $null){$deletedspns | export-csv -path $outputfile -notypeinformation}
$outputfile = "c:\temp\deletedusers_"+$tdy+".csv"
if($deletedusers -ne $null){$deletedusers | export-csv -path $outputfile -notypeinformation}
$outputfile = "c:\temp\deletedgroups_"+$tdy+".csv"
if($deletedgroups -ne $null){$deletedgroups | export-csv -path $outputfile -notypeinformation}
$outputfile = "c:\temp\deleteddevices_"+$tdy+".csv"
if($deleteddevices -ne $null){$deleteddevices | export-csv -path $outputfile -notypeinformation}

