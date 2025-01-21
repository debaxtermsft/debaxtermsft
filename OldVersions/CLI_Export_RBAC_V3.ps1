#######################
# updated 6/21/22 added signinname 
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
#######################



param([parameter(mandatory)][string] $tenandID,
            [parameter (mandatory=$false)][validateset("All")] [string]$AllSubs,
            [parameter(mandatory=$false)][string]$subscriptionID,  
            [parameter(mandatory)][validateset("All RBAC","All Users","All Groups", "All Service Principals", "Identity Unknown", "InheritanceCheck", "Cancel")][string] $mainmenu,
            [parameter(mandatory)][validateset("DisplayName","Scope","RoleDefinitionName")] [string]$scopetype,
          #[parameter(mandatory)][validateset("All","Azure","Office")] [string]$SorOGroup,
            [parameter(mandatory)] [string]$Outputdirectory)
$WarningPreference = "SilentlyContinue"    

    if($AllSubs -eq "All")
    {
        $subscription = Get-AzSubscription | ?{$_.TenantID -eq $tenandID}
    }
    else
    {
        $subscription = Get-AzSubscription -SubscriptionId $subscriptionID
    }



#function for picking a directory to save the file


#logging into az
try
{
    get-azaduser -ErrorAction stop >$null
}
catch
{
    $firstlogin = Connect-AzAccount
}





$counter = 0

$id = @()
 

    foreach ($subscriptionselected in $subscription)
        {
            $list =@()
            $file =@()
            $rbaclist =@()
            $rbacrolelist =@()
            $roleinfo =@()
            $roleinfo2 =@()
            $item =@()
            $item2 =@()
            $item3 =@()
            $AASRolegroupoutput =@()

            $file = $mainmenu

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
                    write-host "Scanning RBAC Roles in Subscription : " $subscriptionselected

                        Set-AzContext -Subscription $subscriptionselected.id #-Tenant $subselectect.TenantId
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

                    #build-file -anotherlist $list -filename $file  -scopetype $selectscope -outputdirectory $outputdirectory
                }
                "All Groups"
                {
                    $objecttype = "Group"

                    $list = get-azroleassignment | Where-Object {$_.ObjectType -eq $objecttype}  #|select DisplayName, RoleAssignmentId, Scope, RoleDefinitionName, RoleDefinitionId, ObjectID, ObjectType |Sort-Object DisplayName, RoleDefinitionName
                    #build-file -passlist $list -filename $file  -scopetype $selectscope -outputdirectory $outputdirectory
                }
                # gets all User role assignments
                "All Users"
                {
                    $objecttype = "User"
                    $list = get-azroleassignment  | Where-Object {$_.ObjectType -eq $objecttype -and $_.SignInName -ne $null} 
                    #build-file -passlist $list -filename $file -scopetype $selectscope -outputdirectory $outputdirectory
                }
                # gets all ServicePrincipal role assignments
                "All Service Principals"
                {
                    $objecttype = "ServicePrincipal"
                    $list = get-azroleassignment  | Where-Object {$_.ObjectType -eq $objecttype} 
                    #build-file -passlist $list -filename $file  -scopetype $selectscope -outputdirectory $outputdirectory
                }
                # gets all role assignments

                # gets all Identity Unknown role assignments - Either User, Group, SPN was deleted
                "Identity Unknown"
                {
        
                    $objecttype = "Unknown"
                    
                    $list = get-azroleassignment  | Where-Object {$_.displayname -eq $null -and $_.SignInName -eq $null}
                    #build-file -passlist $list -filename $file  -scopetype $selectscope -outputdirectory $outputdirectory
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

            $rbacrolelist = $list |Sort-Object $scopetype 
        
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
        $file = $Outputdirectory +"_" + $tenandID+"_" + $subscriptionselected.id +"_" + $mainmenu +"_" + $scope+ "_" +$tdy+".csv"
        $rbacroles | export-csv -Path $file -NoTypeInformation -Encoding utf8 -Force
        }
    
    
    

    