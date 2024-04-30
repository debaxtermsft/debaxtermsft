<#
Written by Derrick Baxter 4/20/24
This script uses Az module for powershell (microsoft.graph coming out soon)
Switches to get ALL subscriptions within a Tenant (you must have Reader, Owner or User Access Administrator)

Scans All or select subscriptions for RBAC roles assigned with Conditions
FileName is automatically created based on selection, time and date

All Subscriptions scanned in Tenant using -Allsubs All
.\rbacAnyofANyConditions.ps1 -tenandID "tenantID" -AllSubs All -OutputDirectory "c:\temp\""
-tenandID "tenantID" 
-AllSubs All
-OutputDirectory c:\temp\ 

Select Subscription scanned in Tenant using -subscriptionID 
.\rbacAnyofANyConditions.ps1 -tenandID "tenantID" -subscriptionID "subscriptionID" -OutputDirectory "c:\temp\"
-tenandID "tenantID" 
-subscriptionID "subscriptionID" 
-OutputDirectory "c:\temp\"


#>

param([parameter(mandatory)][string] $tenandID,
            [parameter (mandatory=$false)][validateset("All")][string]$AllSubs,
            [parameter(mandatory=$false)][string]$subscriptionID,  
            [parameter(mandatory)] [string]$OutputDirectory)
try
{
    get-azuser -ErrorAction stop >$null
}
catch
{
    $firstlogin = Connect-AzAccount -Tenant $tenandID
}

$tenantName = (get-azdomain -TenantId $tenantid).Name
$subscriptions = @()
$tdy = get-date -Format "MM-dd-yyyy hh.mm.ss"

if($AllSubs -eq "All")
{
    $subscriptions = Get-AzSubscription -TenantId $tenantid
    $file = $OutputDirectory +"RBACAssignmentsWithConditions_" + $tenandID+"_AllSubscriptionsInTenant_" +$tdy+".csv"
}
else
{
    $subscriptions = Get-AzSubscription -SubscriptionId $subscriptionID -TenantId $tenantid
    $file = $OutputDirectory +"RBACAssignmentsWithConditions_" + $tenandID+"_SelectedSubscription_"+$subscriptions+"_" +$tdy+".csv"
}

Write-host "Scanning Tenant : " $tenandID " with " $subscriptions.count " subscription(s)"
$rbacroles =@()
foreach ($subitem in $subscriptions)
{
    set-azcontext -SubscriptionId $subitem.id -Tenant $tenantid -ErrorAction SilentlyContinue  | Out-null
    write-host "Scanning subcription : " $subitem.Name $subitem.Id
    $condition =@()
    $condition = Get-AzRoleAssignment  | where-object{$_.condition -ne $null}
        if ($condition.count -ge 1)
        {
            foreach ($conditionItem in $condition)
            {
                $RoleAnyOfAny2 =  $conditionItem | where-object{$_.condition -like "*AnyOfAny*"}
                $rbacroles += New-Object Object |
                                Add-Member -NotePropertyName TenantName -NotePropertyValue $tenantName -PassThru |
                                Add-Member -NotePropertyName TenantId -NotePropertyValue $tenantid -PassThru |
                                Add-Member -NotePropertyName SubscriptionName -NotePropertyValue $subitem.Name -PassThru |
                                Add-Member -NotePropertyName SubscriptionId -NotePropertyValue $subitem.Id -PassThru |
                                Add-Member -NotePropertyName DisplayName -NotePropertyValue $conditionItem.DisplayName -PassThru |
                                Add-Member -NotePropertyName ObjectId -NotePropertyValue $conditionItem.ObjectID -PassThru |
                                Add-Member -NotePropertyName ObjectType -NotePropertyValue $conditionItem.ObjectType -PassThru |
                                Add-Member -NotePropertyName SignInName -NotePropertyValue $conditionItem.SignInName -PassThru |
                                Add-Member -NotePropertyName RoleDefinitionName -NotePropertyValue $conditionItem.RoleDefinitionName -PassThru |
                                Add-Member -NotePropertyName RoleDefinitionID -NotePropertyValue $conditionItem.RoleDefinitionId -PassThru |
                                Add-Member -NotePropertyName RoleAssignmentID -NotePropertyValue $conditionItem.RoleAssignmentId -PassThru |
                                Add-Member -NotePropertyName CanDelegate -NotePropertyValue $conditionItem.CanDelegate -PassThru |
                                Add-Member -NotePropertyName Scope -NotePropertyValue $conditionItem.Scope -PassThru |
                                Add-Member -NotePropertyName ConditionWAnyofAny -NotePropertyValue $conditionItem.Condition -PassThru 
        }
        }
        write-host "Pausing to avoid Throttling Issue, Increase as needed if you get throttled"
        start-sleep 1
}
$rbacroles | export-csv -Path $file -NoTypeInformation -Encoding utf8 -Force
write-host "Total RBAC assignments with Conditons Set : "$rbacroles.Count
$rbacroles | Select-Object SubscriptionName, Displayname, Objectid, RoleDefinitionName, RoleAssignmentID| ft -AutoSize