<#
Written By Derrick Baxter debaxter@microsoft.com
The below script uses the Azure Graph powershell module pulling all deleted objects (users/groups/spns/apps/devices)

.\AzureDeletedObjectsReport-msgraphv1.ps1
You will need to update the directory $outputdirectory = "C:\Temp\"

written: 7/18/23


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
$outputdirectory = "C:\Temp\"
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
$apps = invoke-MgGraphrequest -Uri "https://graph.microsoft.com/beta/directory/deletedItems/microsoft.graph.application?&'$count=true&'$orderBy=deletedDateTime+desc&'$select=id,displayName,deletedDateTime/organization" -Method GET -Headers @{ConsistencyLevel='eventual'}
$spns = invoke-MgGraphrequest -Uri "https://graph.microsoft.com/beta/directory/deletedItems/microsoft.graph.serviceprincipal?&'$count=true&'$orderBy=deletedDateTime+desc&'$'select=id,displayName,deletedDateTime/organization" -Method GET -Headers @{ConsistencyLevel='eventual'}
$users = invoke-MgGraphrequest -Uri "https://graph.microsoft.com/beta/directory/deletedItems/microsoft.graph.user?&'$count=true&$'orderBy=deletedDateTime+desc&$'select=id,displayName,deletedDateTime/organization" -Method GET -Headers @{ConsistencyLevel='eventual'}
$groups = invoke-MgGraphrequest -Uri "https://graph.microsoft.com/beta/directory/deletedItems/microsoft.graph.group?&'$count=true&$'orderBy=deletedDateTime+desc&$'select=id,displayName,deletedDateTime/organization" -Method GET -Headers @{ConsistencyLevel='eventual'}
$devices = invoke-MgGraphrequest -Uri "https://graph.microsoft.com/beta/directory/deletedItems/microsoft.graph.device?&'$count=true&$'orderBy=deletedDateTime+desc&$'select=id,displayName,deletedDateTime/organization" -Method GET -Headers @{ConsistencyLevel='eventual'}


$value = $apps.value
foreach ($item in $value){
$Deletedapps += New-Object Object |
                    Add-Member -NotePropertyName DisplayName -NotePropertyValue $item.displayname -PassThru |
                    Add-Member -NotePropertyName ID -NotePropertyValue $item.id -PassThru 
}
$value = $spns.value
foreach ($item in $value){
$Deletedspns += New-Object Object |
                    Add-Member -NotePropertyName DisplayName -NotePropertyValue $item.displayname -PassThru |
                    Add-Member -NotePropertyName ID -NotePropertyValue $item.id -PassThru 
}
$value = $users.value
foreach ($item in $value){
$Deletedusers += New-Object Object |
                    Add-Member -NotePropertyName DisplayName -NotePropertyValue $item.displayname -PassThru |
                    Add-Member -NotePropertyName ID -NotePropertyValue $item.id -PassThru 
}
$value = $groups.value
foreach ($item in $value){
$Deletedgroups += New-Object Object |
                    Add-Member -NotePropertyName DisplayName -NotePropertyValue $item.displayname -PassThru |
                    Add-Member -NotePropertyName ID -NotePropertyValue $item.id -PassThru 
}
$value = $devices.value
foreach ($item in $value){
$Deleteddevices += New-Object Object |
                    Add-Member -NotePropertyName DisplayName -NotePropertyValue $item.displayname -PassThru |
                    Add-Member -NotePropertyName ID -NotePropertyValue $item.id -PassThru 
}
$tdy = get-date -Format "MM-dd-yyyy_hh.mm.ss"
$outputfile = $outputdirectory + "deletedapps_"+$tdy+".csv"
if($deletedapps -ne $null){$deletedapps | export-csv -path $outputfile -notypeinformation}
$outputfile = $outputdirectory + "deletedspns_"+$tdy+".csv"
if($deletedspns -ne $null){$deletedspns | export-csv -path $outputfile -notypeinformation}
$outputfile = $outputdirectory + "deletedusers_"+$tdy+".csv"
if($deletedusers -ne $null){$deletedusers | export-csv -path $outputfile -notypeinformation}
$outputfile = $outputdirectory + "deletedgroups_"+$tdy+".csv"
if($deletedgroups -ne $null){$deletedgroups | export-csv -path $outputfile -notypeinformation}
$outputfile = $outputdirectory + "deleteddevices_"+$tdy+".csv"
if($deleteddevices -ne $null){$deleteddevices | export-csv -path $outputfile -notypeinformation}