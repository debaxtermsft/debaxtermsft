<#
Created 8/11/22 by Derrick Baxter
Powershell script written to export all Azure access review w status information
#>
connect-mggraph -Scopes "AccessReview.Read.All"
Select-MgProfile "beta"

$definitionURI = "https://graph.microsoft.com/beta/identityGovernance/accessReviews/definitions"
$ARs = invoke-mggraphrequest -uri $definitionURI -method GET
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

