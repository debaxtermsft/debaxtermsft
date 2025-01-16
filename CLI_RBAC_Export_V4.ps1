#######################
# updated 1/16/25 module changes required updating
#the below script uses the AZ powershell module pulling all roleassignments for groups
# Version 1 CLI 
# CLI driven
# .\CLI_Export_RBAC.ps1 
#-mainmenu 'All RBAC, All Groups, All Users, All Service Principals or Identity Unknown"
# -tenandID "your tenant id" 
# not manditory -AllSubs All (will get all subs in the tenants entered)
# -subscriptionID "subscriptionid" 
# -scopetype DisplayName, scope, roledefinition name sorting
# -Outputdirectory "your destination directory
# filename will be created for you by the selections + time and date (should be impossible to overwrite) 
# File will be named $Outputdirectory+"_" +$tenandID+"_" +$subscriptionselected.id+"_" +$mainmenu+"_" + $tenandID+"_" +$subscriptionselected.id+"_" +$scope+"_" +$tdy+".csv"
# PII can and most likely will be included, make sure your local laws are enforced
# written by debaxter@microsoft.com

Example : 1 subscription Check
.\CLI_RBAC_Export_V4.ps1 -tenandID "tenantid" -mainmenu 'All RBAC' -scopetype Scope -Outputdirectory "c:\temp\" -subscriptionID "SubscriptionID"

Example : 2 All RBAC for All Subscriptions 
.\CLI_RBAC_Export_V4.ps1 -AllSubs All -tenandID "tenantid" -mainmenu 'All RBAC' -scopetype Scope -Outputdirectory "c:\temp\"
#######################



param([parameter(mandatory)][string] $tenandID,
            [parameter (mandatory=$false)][validateset("All")] [string]$AllSubs,
            [parameter(mandatory=$false)][string]$subscriptionID,  
            [parameter(mandatory)][validateset("All RBAC","All Users","All Groups", "All Service Principals", "Identity Unknown", "InheritanceCheck", "Cancel")][string] $mainmenu,
            [parameter(mandatory)][validateset("DisplayName","Scope","RoleDefinitionName")] [string]$scopetype,
          #[parameter(mandatory)][validateset("All","Azure","Office")] [string]$SorOGroup,
            [parameter(mandatory)] [string]$Outputdirectory)
$WarningPreference = "SilentlyContinue"    

#logging into az
try
{
    Get-AzDomain -ErrorAction stop >$null
}
catch
{
    Update-AzConfig -EnableLoginByWam $false
    Connect-AzAccount -tenantid $tenantid -informationaction ignore -WarningAction Ignore
}

$id = @()
if($AllSubs -eq "All")
{
    $subscriptionALL = Get-AzSubscription
    $subscription = ($subscriptionALL | where-object{$_.tenantid -eq $tenandID}).Id
    write-host "Subscriptions Accessible w Current User Signed In, Check your RBAC Roles if any are missing"
    $subscription 
}
else
{
    $subscription = $subscriptionID
}
$list =@()
$file =@()
$rbacrolelist =@()

    foreach ($subscriptionselected in $subscription)
        {
            $file = $mainmenu
            write-host "Scanning RBAC Roles in Subscription : " $subscriptionselected
            Set-AzContext -Subscription $subscriptionselected #-Tenant $subselectect.TenantId
            switch -exact ($mainmenu) 
            {
                "Cancel" {exit}
                "All RBAC"
                {
                    $users = get-azroleassignment # | Where-Object {$_.SignInName -ne $null} 
                    foreach ($userfound in $users)
                    {
                        $list += $userfound
                    }
                }
                "All Groups"
                {
                    $objecttype = "Group"

                    $list = get-azroleassignment | Where-Object {$_.ObjectType -eq $objecttype}  
                }
                # gets all User role assignments
                "All Users"
                {
                    $objecttype = "User"
                    $list = get-azroleassignment  | Where-Object {$_.ObjectType -eq $objecttype -and $_.SignInName -ne $null} 
                }
                # gets all ServicePrincipal role assignments
                "All Service Principals"
                {
                    $objecttype = "ServicePrincipal"
                    $list = get-azroleassignment  | Where-Object {$_.ObjectType -eq $objecttype} 
                }
                # gets all Identity Unknown role assignments - Either User, Group, SPN was deleted
                "Identity Unknown"
                {
                    $objecttype = "Unknown"
                    $list = get-azroleassignment  | Where-Object {$_.displayname -eq $null -and $_.SignInName -eq $null}
                }
                "InheritanceCheck"
                {
                    $objecttype = "InheritanceCheck"
                    $resources = get-azresource | Sort-Object ResourceId
                    foreach($resourceFounditem in $resources)
                    {
                        $id = $resourceFounditem.ResourceId
                        $templist = Get-AzRoleAssignment -scope $id | Sort-Object Scope
                        #add in checker to see if the scope eq to the resourceFounditem
                        $list += $templist
                    }
                    
                }
            }
            $rbacrolelist = $list | Sort-Object $scopetype 
             if ($rbacrolelist -eq $null)
            { 
                break
            }
            else
                {
                    $rbacroles=@()
                       foreach ($listitem in $rbacrolelist )
                       {
                        $rbacroles += New-Object Object |
                                        Add-Member -NotePropertyName DisplayName -NotePropertyValue $listitem.DisplayName -PassThru |
                                        Add-Member -NotePropertyName ObjectId -NotePropertyValue $listitem.ObjectID -PassThru |
                                        Add-Member -NotePropertyName ObjectType -NotePropertyValue $listitem.ObjectType -PassThru |
                                        Add-Member -NotePropertyName SignInName -NotePropertyValue $listitem.SignInName -PassThru |
                                        Add-Member -NotePropertyName RoleDefinitionName -NotePropertyValue $listitem.RoleDefinitionName -PassThru |
                                        Add-Member -NotePropertyName Scope -NotePropertyValue $listitem.Scope -PassThru |
                                        Add-Member -NotePropertyName RoleDefinitionID -NotePropertyValue $listitem.RoleDefinitionId -PassThru |
                                        Add-Member -NotePropertyName RoleAssignmentID -NotePropertyValue $listitem.RoleAssignmentId -PassThru
                        }
                }
        $tdy = get-date -Format "MM-dd-yyyy hh.mm.ss"
        $file = $Outputdirectory + $tenandID+"_" + $subscriptionselected +"_" + $mainmenu +"_" + $scopetype+ "_" +$tdy+".csv"
        $rbacroles | export-csv -Path $file -NoTypeInformation -Encoding utf8 -Force
        }
    write-host "Open files at " $Outputdirectory
