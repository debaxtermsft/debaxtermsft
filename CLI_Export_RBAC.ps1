﻿#######################
# the below script uses the AZ powershell module pulling all roleassignments for groups
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
            [parameter(mandatory)][validateset("All RBAC","All Users","All Groups", "All Service Principals", "Identity Unknown")][string] $mainmenu,
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

                if ($mainmenu -eq "All RBAC")
                {                
                    
                    $list = get-azroleassignment  
                    $users = get-azroleassignment # | Where-Object {$_.SignInName -ne $null} 
                    foreach ($userfound in $users)
                    {
                        $list += $userfound
                    }

                    #build-file -anotherlist $list -filename $file  -scopetype $selectscope -outputdirectory $outputdirectory
                }

                elseif ($mainmenu -eq "All Groups")
                {
                    $objecttype = "Group"

                    $list = get-azroleassignment | Where-Object {$_.ObjectType -eq $objecttype}  #|select DisplayName, RoleAssignmentId, Scope, RoleDefinitionName, RoleDefinitionId, ObjectID, ObjectType |Sort-Object DisplayName, RoleDefinitionName
                    #build-file -passlist $list -filename $file  -scopetype $selectscope -outputdirectory $outputdirectory
                }
                # gets all User role assignments
                elseif ($mainmenu -eq "All Users")
                {
                    $objecttype = "User"
                    $list = get-azroleassignment  | Where-Object {$_.ObjectType -eq $objecttype -and $_.SignInName -ne $null} 
                    #build-file -passlist $list -filename $file -scopetype $selectscope -outputdirectory $outputdirectory
                }
                # gets all ServicePrincipal role assignments
                elseif ($mainmenu -eq "All Service Principals")
                {
                    $objecttype = "ServicePrincipal"
                    $list = get-azroleassignment  | Where-Object {$_.ObjectType -eq $objecttype} 
                    #build-file -passlist $list -filename $file  -scopetype $selectscope -outputdirectory $outputdirectory
                }
                # gets all role assignments

                # gets all Identity Unknown role assignments - Either User, Group, SPN was deleted
                elseif ($mainmenu -eq "Identity Unknown")
                {
        
                    $objecttype = "Unknown"
                    
                    $list = get-azroleassignment  | Where-Object {$_.displayname -eq $null -and $_.SignInName -eq $null}
                    #build-file -passlist $list -filename $file  -scopetype $selectscope -outputdirectory $outputdirectory
                }

            $rbacrolelist = $list |Sort-Object $scopetype 
        
            if ($rbacrolelist -eq $null)
            { 
                break
            }
            else
                {
            
                    foreach ($item3 in $rbacrolelist)
                    {
                        $roleinfo2 = $item3.DisplayName  +","+  $item3.ObjectID+","+  $item3.ObjectType+","+  $item3.RoleDefinitionName+","+  $item3.Scope+","+  $item3.RoleDefinitionId +","+  $item3.RoleAssignmentId
                        $roleinfo += $roleinfo2
                    }
                }
         $tdy = get-date -Format "MM-dd-yyyy hh.mm.ss"
#        $filename1 = $filename +" " + $subscriptionselected.name+" "+$subscriptionselected.id +" "+ $domainselected +" "+ $tdy +".csv"           
#        $OutputFile = "$outputdirectory"+"\"+"$filename1" 
        $file = $Outputdirectory +"_" + $tenandID+"_" + $subscriptionselected.id +"_" + $mainmenu +"_" + $scope+ "_" +$tdy+".csv"
        $AASRolegroupoutput = "'DisplayName','ObjectID','ObjectType','RoleDefinitionName','Scope','RoleDefinitionID','RoleAssignmentID'"
        $AASRolegroupoutput |  Out-File -FilePath $file -Encoding utf8 -Force
        $roleinfo | Out-File -FilePath $file -Encoding utf8 -Append
        }
    
    #}
    

    