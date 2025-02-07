<#
Written by Derrick Baxter 2/5/25

Check all custom Resource Role definitions for possible permissions issue that needs updated.
Download the resourceperms.csv from github in the same directory

Using Az Powershell module

only required options are -tenantid and -outputdirectory MUST HAVE trailing \  ex: c:\temp\ NOT c:\temp

allsubs option ALL - scans all subs YOU have permissions to view (owner, contributor or UAA)
-subscriptionid "subguid" to scan only 1 subscription

-importpermfile FULL DIRECTORY and FILE "c:\temp\resourceperms.csv"
#>

param([parameter(mandatory)][string] $tenandID,
            [parameter (mandatory=$false)][validateset("All")] [string]$AllSubs,
            [parameter(mandatory=$false)][string]$subscriptionID,  
            [parameter(mandatory)][string]$ImportPermsFile,
            [parameter(mandatory)] [string]$Outputdirectory)
$WarningPreference = "SilentlyContinue"    

$resourceperms = import-csv -Path "$ImportPermsFile" -Encoding utf8
if(!$resourceperms)
{write-host "perms file didn't load"
 break}

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





write-host "resource Perm 0 to check it loaded" $resourceperms[0]
foreach ($subscriptionselected in $subscription)
{
            $file = $mainmenu
            $list =@()
            write-host "Scanning RBAC Roles in Subscription : " $subscriptionselected
            Set-AzContext -Subscription $subscriptionselected #-Tenant $subselectect.TenantId


        $customroledefinitions = Get-AzRoleDefinition -Custom

        $foundNetworkRD = @()
        $ResourceCustomroles = @()


        foreach ($item in $customroledefinitions)
        {
        #    write-host "searching actions in " $item.name
            foreach ($itemperm in $resourceperms)
            {
                [string]$perm = $itemperm.permissions
        #        write-host "perm search for " $perm
                $foundNetworkRD += $item | ?{$_.actions -like "$perm" -or $_.NotActions -like "$perm"}
            }
        }

        foreach ($founditem in $foundNetworkRD)
        {
            [string]$action1 = $founditem.actions
            [string]$notaction1 = $founditem.NotActions
            [string]$dataaction1 = $founditem.Dataactions
            [string]$notdataaction1 = $founditem.NotDataactions
            [string]$assignablescopes1 = $founditem.AssignableScopes
            [string]$condition1 = $founditem.condition
            [string]$conditionversion1 = $founditem.ConditionVersion

            $ResourceCustomroles += New-Object Object |
                Add-Member -NotePropertyName Name -NotePropertyValue $founditem.Name -PassThru |
                Add-Member -NotePropertyName Id -NotePropertyValue $founditem.Id -PassThru |
                Add-Member -NotePropertyName IsCustom -NotePropertyValue $founditem.IsCustom -PassThru |
                Add-Member -NotePropertyName Description -NotePropertyValue $founditem.description -PassThru |
                Add-Member -NotePropertyName actions -NotePropertyValue $action1 -PassThru |
                Add-Member -NotePropertyName NotActions -NotePropertyValue $notaction1 -PassThru |
                Add-Member -NotePropertyName Dataactions -NotePropertyValue $dataaction1 -PassThru |
                Add-Member -NotePropertyName NotDataactions -NotePropertyValue $notdataaction1 -PassThru |
                Add-Member -NotePropertyName AssignableScopes -NotePropertyValue $assignablescopes1 -PassThru |
                Add-Member -NotePropertyName Condition -NotePropertyValue $condition1 -PassThru |
                Add-Member -NotePropertyName ConditionVersion -NotePropertyValue $conditionversion1 -PassThru 
        }
$ResourceCustomroles
    if (!$ResourceCustomroles)
    {
    write-host "No Custom Resource  Roles Found in Subscription Selected " $subscriptionselected
    }
    else {
    $tdy = get-date -Format "MM-dd-yyyy hh.mm.ss"
    $file = $Outputdirectory + $tenandID+"_" + $subscriptionselected +"_" +$tdy+".csv"

    $ResourceCustomroles | Sort-Object Name -Unique | export-csv -path $file -NoTypeInformation -Encoding utf8
    }
}