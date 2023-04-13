<#
Written by Derrick Baxter
PIM RBAC Roles using microsoft.graph and azureadpreview
4/13/23
to run:
-tenantid = tenantid
-resourcequestion : options : ManagementGroup, Subscription, ResourceGroup or All
-NameofIDSelect : options : Name or ObjectID - used to tell the command below which is being used.
-NameorID : Name or Objectid :(of the mgmt group = ID is tenantid, name is name) (subscriptions/resource groups can use Name or ObjectID)
-skipInheritance : options Yes/No - No will show all PIM Roles with inheritance, Yes will show only direct assignments via PIM
-outputdirectory : "c:\temp\" needs the trailing \
filename will be automatically created based on the options selected with data/time of the report generated to avoid overwriting reports.

.\pimrbac-graph.ps1 -tenantid "tenantid" -resourcequestion <ManagementGroup, Subscription, ResourceGroup or All> -NameorIDSelect <Name or ObjectID> -NameorID <DisplayName or ObjectID> -skipInheritance <Yes or No> -outputdirectory <enter the directory and filename.csv>
ManagementGroup
Name
.\pimrbac-graph.ps1  -resourcequestion ManagementGroup -NameorIDSelect Name -NameorID "Tenant Root Group" -skipInheritance Yes -Outputdirectory c:\temp\
ID
.\pimrbac-graph.ps1  -resourcequestion ManagementGroup -NameorIDSelect ObjectID -NameorID "tenantid" -skipInheritance Yes -Outputdirectory c:\temp\

Subscription
By Name
.\pimrbac-graph.ps1  -resourcequestion Subscription -NameorIDSelect Name -NameorID "Name of Subscription" -skipInheritance Yes -Outputdirectory c:\temp\
By ID
.\pimrbac-graph.ps1  -resourcequestion Subscription -NameorIDSelect ObjectID -NameorID "subscriptionid" -skipInheritance Yes -Outputdirectory c:\temp\

ResourceGroup
.\pimrbac-graph.ps1 -tenantid "tenantid"  -resourcequestion ResourceGroup -NameorIDSelect Name -NameorID "Name" -skipInheritance Yes -Outputdirectory c:\temp\
You want all PIM RBAC Roles showing inheritance to all resources below the level selected
.\pimrbac-graph.ps1 -tenantid "tenantid"  -resourcequestion ResourceGroup -NameorIDSelect Name -NameorID "Name" -skipInheritance No -Outputdirectory c:\temp\

All
Will take a long time but not as long as with SkipInheritance set to NO
.\pimrbac-graph.ps1 -tenantid "tenantid"  -resourcequestion All -skipInheritance Yes -Outputdirectory c:\temp\
Show all inheritance - will take a VERY LONG TIME
.\pimrbac-graph.ps1 -tenantid "tenantid"  -resourcequestion All -skipInheritance No -Outputdirectory c:\temp\
#>



param([parameter(mandatory=$false)][string] $tenantID,
            [parameter (mandatory)][validateset("ManagementGroup", "Subscription","ResourceGroup","All")] [string]$resourcequestion,
            [parameter(mandatory=$false)][validateset("Name", "ObjectID")][string]$NameorIDSelect,
            [parameter(mandatory=$false)][string]$NameorID,
            [parameter(mandatory)][validateset("Yes", "No")][string]$skipInheritance,
            [parameter(mandatory)] [string]$Outputdirectory)


$tdy = get-date -Format "MM-dd-yyyy_hh.mm.ss"
if($skipInheritance -eq "Yes"){$SkipAnswer = "SkipInheritanceYES"}else{$SkipAnswer = "SkipInheritanceNo"}
$filename = $Outputdirectory+$resourcequestion+"_"+$NameorIDSelect+"_"+$NameorID+"_"+$skipAnswer+"_"+$tdy+".csv"

$WarningPreference = "SilentlyContinue"    


switch -exact ($resourcequestion) 
            {
                "Cancel" {exit}
                "ManagementGroup"
                {
                    $type = "managementgroup"
                }
                "Subscription"
                {
                    $type = "subscription"
                }
                "ResourceGroup"
                {
                    $type = "resourcegroup"
                }
                "All"
                {
                    $type = "all"
                }
                
            }

try
{
    Get-MgUser -Top 1 -ErrorAction stop
}
catch
{
connect-mggraph -scopes "directory.read.all, PrivilegedAccess.Read.AzureResources, PrivilegedAccess.Read.AzureADGroup, PrivilegedAccess.Read.AzureAD" #-TenantId $tenantID
select-mgprofile "beta"

}

$ApiUrl = "https://graph.microsoft.com/beta/privilegedAccess/azureResources/resources"
$ResourceProperties =@()
$resources = Invoke-MgGraphRequest -Uri $ApiUrl -method get
$checkformore = $resources.'@odata.nextlink'
do
{
    foreach ($item in $resources.value){
     $type = $item.type
     $id = $item.id 
     $externalid = $item.externalid
     $displayname = $item.displayname
     $ResourceProperties += New-Object Object |
                                Add-Member -NotePropertyName DisplayName -NotePropertyValue $displayname -PassThru |
                                Add-Member -NotePropertyName Type        -NotePropertyValue $type        -PassThru |
                                Add-Member -NotePropertyName ID          -NotePropertyValue $id          -PassThru |
                                Add-Member -NotePropertyName ExternalID  -NotePropertyValue $externalid  -PassThru 
    }
    $checkformore = $resources.'@odata.nextlink' #checking if there are more records 
    
    if($checkformore -ne $null)
    {
        write-host "getting more resources"
        $resources = Invoke-MgGraphRequest -Uri $checkformore -method get
    }
}
while ($checkformore -ne $null)

$findexid =@()
if($resourcequestion -eq "All")
{
    $findexid = ($ResourceProperties).externalid
    if($findexname -eq $null)
        {
            write-host "Resource Not Found, please check Tenant Logged Into or permissions"
            exit
        }
}
elseif($NameorIDSelect -eq "Name")
{
    $findexid = $ResourceProperties | where-object{$_.displayname -like $nameorid}
    if($findexid -eq $null)
    {
        write-host "Resource Not Found, please check Name Entered"
        exit
    }
    $findexid | select displayname, externalid
}
else{
    $findexid = $ResourceProperties | where-object{$_.externalid -match $NameorID}
    
    if($findexid -eq $null)
        {
            write-host "Resource Not Found, please check or ID entered"
            exit
        }
    $findexid | select displayname, externalid
}

Disconnect-MgGraph
write-host "waiting 10 seconds to disconnect from mggraph"
start-sleep 10

try
{
    write-host "trying aadpreview command"
    get-azureaduser -top 1 -ErrorAction stop
}
catch
{
    write-host "connecting to azureadpreview"
    connect-azuread # -TenantId $tenantID
}



$rbacroles =@()
    foreach ($rbacitem1 in $findexid)
        {
            write-host "Displayname " $rbacitem1.DisplayName 
            write-host "ExternalID  " $rbacitem1.ExternalID
            write-host "ID          " $rbacitem1.ID
            write-host "Type        " $rbacitem1.Type
            if($skipInheritance -eq "Yes"){
                $RBACPRA1 = Get-AzureADMSPrivilegedRoleAssignment -ProviderId AzureResources -resourceid $rbacitem1.Id | ?{$_.membertype -ne "Inherited"}
            }
            else
            {
                $RBACPRA1 = Get-AzureADMSPrivilegedRoleAssignment -ProviderId AzureResources -resourceid $rbacitem1.Id
            }
            if ($RBACPRA1.count -gt 2000) {$setsleep -eq $true}
            if ($RBACPRA1 -eq $null)
                { 
                    If($skipInheritance -eq "Yes")
                        {
                            write-host "No Direct Assignments Found for this Resource"
                        }
                    else
                        {
                            write-host "No Direct or Inherited Assignments Found for this Resource"
                        }
                }
            else
            {
                foreach ($praitem1 in $RBACPRA1)
                {
                    $rbacroledefinition = (Get-AzureADMSPrivilegedRoleDefinition -ProviderId AzureResources -ResourceId $praitem1.ResourceId -Id $praitem1.RoleDefinitionId).DisplayName
                    $rbacobjectinfo1 = Get-AzureADObjectByObjectId -ObjectIds $praitem1.subjectid
                    $rbacroles += New-Object Object |
                                    Add-Member -NotePropertyName RoleDefinitionName     -NotePropertyValue  $rbacroledefinition -PassThru |
                                    Add-Member -NotePropertyName ResourceDisplayName     -NotePropertyValue $rbacitem1.DisplayName -PassThru |
                                    Add-Member -NotePropertyName ResourceType            -NotePropertyValue $rbacitem1.Type -PassThru |
                                    Add-Member -NotePropertyName ResourceExternalID      -NotePropertyValue $rbacitem1.externalid -PassThru |
                                    Add-Member -NotePropertyName ResourceID              -NotePropertyValue $rbacitem1.id -PassThru |
                                    Add-Member -NotePropertyName ObjectDisplayName       -NotePropertyValue $rbacobjectinfo1.displayname -PassThru |
                                    Add-Member -NotePropertyName UserPrincipalName       -NotePropertyValue $rbacobjectinfo1.userprincipalname -PassThru |
                                    Add-Member -NotePropertyName ObjectID                -NotePropertyValue $rbacobjectinfo1.objectid -PassThru |
                                    Add-Member -NotePropertyName ObjectType              -NotePropertyValue $rbacobjectinfo1.objecttype -PassThru |
                                    Add-Member -NotePropertyName AssignmentState         -NotePropertyValue $praitem1.assignmentstate -PassThru |
                                    Add-Member -NotePropertyName MemberType              -NotePropertyValue $praitem1.membertype -PassThru |
                                    Add-Member -NotePropertyName AssignmentStartDateTime -NotePropertyValue $praitem1.startdatetime -PassThru |
                                    Add-Member -NotePropertyName AssignmentEndDateTime   -NotePropertyValue $praitem1.enddatetime -PassThru 
                    $rbacroles.count

                    # sleep added to keep from hitting a throttling limit to keep from hitting 2000 requests/sec limit
                    if ($setsleep -eq $true ) {Start-Sleep -Seconds 1}
                }
            }
    }


$rbacroles | export-csv -Path $filename -NoTypeInformation -Encoding UTF8
