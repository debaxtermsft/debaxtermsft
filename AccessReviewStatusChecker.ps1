<#
Created 8/11/22 by Derrick Baxter
Powershell script written to export all Azure access review w status information

If not running as a global administrator - A Global Administrator will need to run the below script to consent to the user(s) being able to access graph for the below script

$sp = get-mgserviceprincipal | ?{$_.displayname -eq "Microsoft Graph"}
$resource = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"
$principalid = "user object id"
$scope1 ="AccessReview.Read.All"
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
connect-mggraph -Scopes "AccessReview.Read.All"
Select-MgProfile "beta"

$definitionURI = "https://graph.microsoft.com/beta/identityGovernance/accessReviews/definitions?$"
$defURI2 = "top=100&$"
$defURI3 = "skip=0"
$ARs = invoke-mggraphrequest -uri $definitionURI+$defURI2+$defURI3 -method GET
$ARIDs = $ars.value.id

$ARDefIDProperties =@()
foreach ($ARIDfounditem in $ARIDs)
{

    $filter = $definitionURI +"/"+"$ARIDfounditem"
    $ARInfo = invoke-mggraphrequest -uri $filter -method GET

    foreach ($ARDefitem in $ARInfo)
        {
            $createdbyupn = $ARDefitem.createdby.userprincipalname
            $createdbydisplayname = $ARDefitem.createdby.displayname
            $resourcescopequery = $ARDefitem.scope.resourcescopes.query
            $rsqhold =@()
            $rsqthold =@()
            if ($resourcescopequery.count -gt 1)
            {
                foreach ($rsq in $resourcescopequery) { [string]$rsqhold += $rsq +" - "}
            }
            else 
            {
                foreach ($rsq in $resourcescopequery) { [string]$rsqhold += $rsq }<# Action when all if and elseif conditions are false #>
            }
            $resourcescopequerytype = $ARDefitem.scope.resourcescopes.querytype
            if ($resourcescopequerytype.count -gt 1)
            {
                foreach ($rsqt in $resourcescopequerytype) { [string]$rsqthold += $rsqt +" - " }
            }
            else 
            {
                foreach ($rsqt in $resourcescopequerytype) { [string]$rsqthold += $rsqt }
            }

            $ARDefIDProperties += New-Object Object |
            Add-Member -NotePropertyName displayName -NotePropertyValue $ARDefitem.displayname -PassThru |
            Add-Member -NotePropertyName id -NotePropertyValue $ARDefitem.id -PassThru |
            Add-Member -NotePropertyName DescriptionForAdmins -NotePropertyValue $ARDefitem.DescriptionForAdmins -PassThru |
            Add-Member -NotePropertyName Status -NotePropertyValue $ARDefitem.status -PassThru |
            Add-Member -NotePropertyName createdDateTime -NotePropertyValue $ARDefitem.createdDateTime -PassThru |
            Add-Member -NotePropertyName LastModifiedDateTime -NotePropertyValue $ARDefitem.LastModifiedDateTime -PassThru |
            Add-Member -NotePropertyName createdbyUPN -NotePropertyValue $createdbyupn -PassThru |
            Add-Member -NotePropertyName createdbydisplayName -NotePropertyValue $createdbydisplayname -PassThru |
            Add-Member -NotePropertyName resourcescopequery -NotePropertyValue $rsqhold -PassThru |
            Add-Member -NotePropertyName resourcescopequerytype -NotePropertyValue $rsqthold -PassThru 


        }
}

$ARDefIDProperties | sort-object -Property status, displayname | export-csv -Path "./accessreviewstatus.csv" -NoTypeInformation

