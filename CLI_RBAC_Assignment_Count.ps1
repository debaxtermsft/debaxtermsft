#######################
# the below script uses the AZ powershell module pulling all roleassignments for groups
# Version 1 CLI 
# CLI driven
# .\CLI_RBAC_Assignment_Count.ps1 
#-mainmenu 'All RBAC, All Groups, All Users, All Service Principals or Identity Unknown"
#manditory
# -tenandID "your tenant id" 
#manditory (either -Allsubs or 1 Subscriptionid) 
# -AllSubs All (will get all subs in the tenants entered)
# -subscriptionID "subscriptionid" 
# manditory
#-Outputdirectory "your destination directory
# filename will be created for you by the selections + time and date (should be impossible to overwrite) 
# File will be named $Outputdirectory+"\"+$tenandID+"_" +$subscriptionselected.id+"_" +$scope+"_" +$tdy+".csv"
# PII can and most likely will be included, make sure your local laws are enforced
# written by debaxter@microsoft.com
#######################



param([parameter(mandatory)][string] $tenandID,
            [parameter (mandatory=$false)][validateset("All")] [string]$AllSubs,
            [parameter(mandatory=$false)][string]$subscriptionID,  
            [parameter(mandatory)] [string]$Outputdirectory)
$WarningPreference = "SilentlyContinue"    
$mainmenu -eq "RBAC Assignment Count"

    if($AllSubs -eq "All")
    {
        $subscription = Get-AzSubscription | ?{$_.TenantID -eq $tenandID}
    }
    else
    {
        $subscription = Get-AzSubscription -SubscriptionId $subscriptionID
    }

    $counter = 0

#logging into az
try
{
    get-azaduser -ErrorAction stop >$null
}
catch
{
    $firstlogin = Connect-AzAccount
}



    foreach ($subscriptionselected in $subscription)
        {
            $list =@()
            $rbaclist =@()
            $rbacrolelist =@()

            $file = $mainmenu

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
            write-host "Getting RBAC Assignment Count : " $subscriptionselected.Name

            Set-AzContext -Subscription $subscriptionselected.id  #-Tenant $subselectect.TenantId
          
            $list = (get-azroleassignment).count
            $rbacrolelist = $list 
        
            if ($rbacrolelist -eq $null)
            { 
                break
            }
            
            else
            {
                if ($counter -eq 0)
                {
            
                    $rbacroles=@()
                }

                        $rbacroles += New-Object Object |
                                        Add-Member -NotePropertyName SubscriptionDisplayName -NotePropertyValue $subscriptionselected.Name -PassThru |
                                        Add-Member -NotePropertyName SubscriptionId -NotePropertyValue $subscriptionselected.id -PassThru |
                                        Add-Member -NotePropertyName RBACAssignmentCount -NotePropertyValue $rbacrolelist -PassThru
                ++$counter
          }

        }
    
$tdy = get-date -Format "MM-dd-yyyy hh.mm.ss"
$file = $Outputdirectory +"\" + $tenandID+"_" + $mainmenu +"_RBAC Assignment Count"+ "_" +$tdy+".csv"
$rbacroles | export-csv -Path $file -NoTypeInformation -Encoding utf8 -Force
    