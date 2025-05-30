<#######################
# updated 1/16/25 module changes required updating
#the below script uses the AZ powershell module pulling all roleassignments for groups
# Version 1 CLI 
# CLI driven
# .\CLI_Export_RBAC.ps1 
# -mainmenu 'All RBAC, All Groups, All Users, All Service Principals or Identity Unknown"
# -tenandID "your tenant id" 
# -IsCustom ALL, BuiltIn, or IsCustom
# not manditory -AllSubs All (will get all subs in the tenants entered)
# -subscriptionID "subscriptionid" 
# -scopetype DisplayName, scope, roledefinition name sorting
# -Outputdirectory "your destination directory
# -ObjectId "ObjectId"

# filename will be created for you by the selections + time and date (should be impossible to overwrite) 
# File will be named $Outputdirectory+"_" +$tenandID+"_" +$subscriptionselected.id+"_" +$mainmenu+"_" + $tenandID+"_" +$subscriptionselected.id+"_" +$scope+"_" +$tdy+".csv"
# PII can and most likely will be included, make sure your local laws are enforced
# written by 

NOTE: Output Directory MUST be followed with a backslash ie c:\temp\ NOT c:\temp

Example : 1 subscription Check
.\CLI_RBAC_Export_V4.ps1 -tenandID "tenantid" -mainmenu 'All RBAC' -scopetype Scope -Outputdirectory "c:\temp\" -subscriptionID "SubscriptionID" -iscustom All

Example : 2 All RBAC for All Subscriptions 
.\CLI_RBAC_Export_V4.ps1 -AllSubs All -tenandID "tenantid" -mainmenu 'All RBAC' -scopetype Scope -Outputdirectory "c:\temp\" -iscustom All

Example : 3 ObjectID search for all Subscriptions

.\CLI_RBAC_Export_V5.ps1 -tenandID "tenantID" -mainmenu ObjectID -ObjectID "ObjectID GUID" -scopetype DisplayName -Outputdirectory "c:\temp\" -RoleDefinitionType IsCustom -AllSubs All
Example : 4 Object search on single subscription

.\CLI_RBAC_Export_V5.ps1 -tenandID "Tenantid"" -mainmenu ObjectID -ObjectID "ObjectID" -scopetype DisplayName -Outputdirectory "c:\temp\" -subscriptionID "subscriptionIS" -RoleDefinitionType IsCustom

#######################>



param([parameter(mandatory)][string] $tenandID,
            [parameter (mandatory=$false)][validateset("All")] [string]$AllSubs,
            [parameter(mandatory=$false)][string]$subscriptionID,  
            [parameter(mandatory=$false)][string]$ObjectID,
            [parameter(mandatory)][validateset("ObjectID", "All RBAC","All Users","All Groups", "All Service Principals", "Identity Unknown", "InheritanceCheck", "Cancel")][string] $mainmenu,
            [parameter(mandatory=$false)][validateset("DisplayName","Scope","RoleDefinitionName")] [string]$scopetype = "DisplayName",
            [parameter(mandatory=$false)][validateset("BuiltIn", "IsCustom", "All")] [string]$RoleDefinitionType = "All",
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
	write-host $tenandID "tenantid"
    Connect-AzAccount -tenant $tenandID -WarningAction Ignore # -informationaction ignore 
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
    write-host "Subscriptions Accessible w Current User Signed In, Check your RBAC Roles if any are missing"
    $subscription 
}
$list =@()
$file =@()
$rbacrolelist =@()

    foreach ($subscriptionselected in $subscription)
        {
            $file = $mainmenu
            $list =@()
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

                    $list += get-azroleassignment | Where-Object {$_.ObjectType -eq $objecttype}  
                }
                # gets all User role assignments
                "All Users"
                {
                    $objecttype = "User"
                    $list += get-azroleassignment  | Where-Object {$_.ObjectType -eq $objecttype -and $_.SignInName -ne $null} 
                }
                # gets all ServicePrincipal role assignments
                "All Service Principals"
                {
                    $objecttype = "ServicePrincipal"
                    $list += get-azroleassignment  | Where-Object {$_.ObjectType -eq $objecttype} 
                }
                # gets all Identity Unknown role assignments - Either User, Group, SPN was deleted
                "Identity Unknown"
                {
                    $objecttype = "Unknown"
                    $list += get-azroleassignment  | Where-Object {$_.displayname -eq $null -and $_.SignInName -eq $null}
                }
                "ObjectID"
                {
                    write-host "in Objectid"
                    $objecttype = "ObjectId"
                    $list += get-azroleassignment -ObjectId  "$ObjectID"
                    $list
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
             if ($rbacrolelist -ne $null)

                {
                    $rbacroles=@()
                       foreach ($listitem in $rbacrolelist )
                       {
                            $IsCustom = Get-AzRoleDefinition -id $listitem.RoleDefinitionId
                            #$IsCustom.IsCustom
                            if($RoleDefinitionType -eq "IsCustom" -and $IsCustom.IsCustom -eq "True")
                            {
                                
                                #write-host "IsCustom"
                                $rbacroles += New-Object Object |
                                Add-Member -NotePropertyName DisplayName -NotePropertyValue $listitem.DisplayName -PassThru |
                                Add-Member -NotePropertyName ObjectId -NotePropertyValue $listitem.ObjectID -PassThru |
                                Add-Member -NotePropertyName ObjectType -NotePropertyValue $listitem.ObjectType -PassThru |
                                Add-Member -NotePropertyName SignInName -NotePropertyValue $listitem.SignInName -PassThru |
                                Add-Member -NotePropertyName RoleDefinitionID -NotePropertyValue $listitem.RoleDefinitionId -PassThru |
                                Add-Member -NotePropertyName RoleDefinitionName -NotePropertyValue $listitem.RoleDefinitionName -PassThru |
                                Add-Member -NotePropertyName RoleDefinitionIsCustom -NotePropertyValue $IsCustom.IsCustom -PassThru |
                                Add-Member -NotePropertyName RoleAssignmentID -NotePropertyValue $listitem.RoleAssignmentId -PassThru |
                                Add-Member -NotePropertyName Scope -NotePropertyValue $listitem.Scope -PassThru 

                            }
                            elseif($RoleDefinitionType -eq "BuiltIn"-and $IsCustom.IsCustom -ne "True")
                            {
                                #write-host "BuiltIn"
                                $IsCustom = Get-AzRoleDefinition -id $listitem.RoleDefinitionId 
                                $rbacroles += New-Object Object |
                                Add-Member -NotePropertyName DisplayName -NotePropertyValue $listitem.DisplayName -PassThru |
                                Add-Member -NotePropertyName ObjectId -NotePropertyValue $listitem.ObjectID -PassThru |
                                Add-Member -NotePropertyName ObjectType -NotePropertyValue $listitem.ObjectType -PassThru |
                                Add-Member -NotePropertyName SignInName -NotePropertyValue $listitem.SignInName -PassThru |
                                Add-Member -NotePropertyName RoleDefinitionID -NotePropertyValue $listitem.RoleDefinitionId -PassThru |
                                Add-Member -NotePropertyName RoleDefinitionName -NotePropertyValue $listitem.RoleDefinitionName -PassThru |
                                Add-Member -NotePropertyName RoleDefinitionIsCustom -NotePropertyValue $IsCustom.IsCustom -PassThru |
                                Add-Member -NotePropertyName RoleAssignmentID -NotePropertyValue $listitem.RoleAssignmentId -PassThru |
                                Add-Member -NotePropertyName Scope -NotePropertyValue $listitem.Scope -PassThru 

                            }
                            elseif($RoleDefinitionType -eq "All") 
                            {
                                #write-host "All"
                                $IsCustom = Get-AzRoleDefinition -id $listitem.RoleDefinitionId 
                                $rbacroles += New-Object Object |
                                Add-Member -NotePropertyName DisplayName -NotePropertyValue $listitem.DisplayName -PassThru |
                                Add-Member -NotePropertyName ObjectId -NotePropertyValue $listitem.ObjectID -PassThru |
                                Add-Member -NotePropertyName ObjectType -NotePropertyValue $listitem.ObjectType -PassThru |
                                Add-Member -NotePropertyName SignInName -NotePropertyValue $listitem.SignInName -PassThru |
                                Add-Member -NotePropertyName RoleDefinitionID -NotePropertyValue $listitem.RoleDefinitionId -PassThru |
                                Add-Member -NotePropertyName RoleDefinitionName -NotePropertyValue $listitem.RoleDefinitionName -PassThru |
                                Add-Member -NotePropertyName RoleDefinitionIsCustom -NotePropertyValue $IsCustom.IsCustom -PassThru |
                                Add-Member -NotePropertyName RoleAssignmentID -NotePropertyValue $listitem.RoleAssignmentId -PassThru |
                                Add-Member -NotePropertyName Scope -NotePropertyValue $listitem.Scope -PassThru 
                            }

                        }
                }
        if (!$rbacroles)
        {
        write-host "No RBAC Roles Found in Subscription" 
        }
        else {
        $tdy = get-date -Format "MM-dd-yyyy hh.mm.ss"
        $file = $Outputdirectory + $tenandID+"_" + $subscriptionselected +"_" + $mainmenu +"_" + $RoleDefinitionType+"_" + $scopetype+ "_" +$tdy+".csv"
        $rbacroles | export-csv -Path $file -NoTypeInformation -Encoding utf8 -Force
        }
        }
    write-host "Open files at " $Outputdirectory