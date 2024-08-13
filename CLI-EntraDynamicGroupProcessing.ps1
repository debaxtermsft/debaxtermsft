#######################
<# Written by Derrick Baxter debaxter@microsoft.com
 the below script uses the Azure Graph powershell module to pause/start ALL Groups, pause/start selected dynamic groups, Show ALL currently Paused Groups, Search for ObjectID of Group by displayname

 8/12/24
 debaxter@microsoft.com

NOTE: It is not recommended to Pause and Start Groups more than 1 time / every 24 hours
Multiple Pause/Starts will not decrease processing times and may negatively impact processing times

 Parameters : 
./CLI-EntraDynamicGroupProcessing.ps1 
Find Group ObjectID by "like" displayname startswith, no * needed just the first couple characters
-CloudQuestion Global -StartPauseQuestion FindGroupID -GroupDisplayName "AA_"
Start All paused groups
-CloudQuestion Global -StartPauseQuestion StartALL
Pause ALL Groups 
-CloudQuestion Global -StartPauseQuestion PauseALL
Start a specific group currently paused
-CloudQuestion Global -StartPauseQuestion StartSelect -GroupObjectId 3474a94d-7bf7-47fb-a7c6-83f7b40332f5
Pause a specific group currently started
-CloudQuestion Global -StartPauseQuestion PauseSelect -GroupObjectId 3474a94d-7bf7-47fb-a7c6-83f7b40332f5
Show all currently paused groups
-CloudQuestion Global -StartPauseQuestion ShowPaused


Using Powershell microsoft.graph
This script will provide a windows interface to Start/Pause all/selected(multi-select) Dynamic Group Processing
Export of Dynamic Groups currently paused added for records/backup
##########################
IMPORTANT!!!

To consent for users to run this script a global admin will need to run the following
-------------------------------------------------------------------------------------------
$sp = get-mgserviceprincipal | ?{$_.displayname -eq "Microsoft Graph"}
$resource = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"
$principalid = "users object id"
$scope1 ="group.readwrite.all"
$scope2 ="directory.read.all"

$today = Get-Date -Format "yyyy-MM-dd"
$expiredate1 = get-date
$expiredate2 = $expiredate1.AddDays(365).ToString("yyyy-MM-dd")
$params = @{
    ClientId = $SP.Id
    ConsentType = "Principal"
    ResourceId = $resource.id
    principalId = $principalid
    Scope = "$scope1" + " " + "$scope2"
    startTime = "$today"
    expiryTime = "$expiredate2"

}

$InitialConsented = New-MgOauth2PermissionGrant -BodyParameter $params
-------------------------------------------------------------------------------------------
#>

param([parameter(mandatory=$false)][string] $tenantID,
            [parameter (mandatory)][validateset("Global", "USGov","USGovDoD","Germany","China")] [string]$CloudQuestion,
            [parameter (mandatory)][validateset("PauseALL", "StartALL","PauseSelect","StartSelect","FindGroupID","ShowPaused")] [string]$StartPauseQuestion,
            [parameter(mandatory=$false)][string]$GroupObjectId,
            [parameter(mandatory=$false)][string]$GroupDisplayName)

            
try
    {
    Get-MGDomain -ErrorAction Stop > $null
    }
catch
    {
    Connect-MgGraph -Scopes "group.readwrite.all, directory.read.all" -NoWelcome -Environment $CloudQuestion
    }

$GDisabled =@()
$tdy = get-date -Format "MM-dd-yyyy_hh.mm.ss"

switch -exact ($StartPauseQuestion) 
{
    "ShowPaused"
    {
        $group = get-mggroup -all -property id, displayname, MembershipRuleProcessingState | Select-Object displayname, id, MembershipRuleProcessingState | Where-Object{$_.MembershipRuleProcessingState -like "Pause*"} | sort-object DisplayName
	$group
    }
    "FindGroupID"
    {
	$gvar = $GroupDisplayName+"*"
	$group =  get-mggroup -all | ?{$_.displayname -like "$gvar"} | Sort-Object displayname, id, description
	$group | select id, displayname, mail
     }
    #Pausing all dynamic group processing
    "PauseALL"
    {

        Write-Host "Pausing ALL Dynamic Groups"
        Write-Host "ARE YOU SURE YOU WANT TO PAUSE ALL GROUPS WITH DYNAMIC MEMBERSHIP?" -ForegroundColor red -BackgroundColor white f
        $ContinueQuestion  = Read-Host "Type 'yes' to confirm: "
        if($ContinueQuestion.ToUpper() -eq "YES")
        {
            $group = get-mggroup -All -property id, displayname, MembershipRuleProcessingState | Select-Object displayname, id, MembershipRuleProcessingState | Where-Object{$_.MembershipRuleProcessingState -like "On*"} | sort-object DisplayName
            foreach($item in $group)
            {
                write-host "Pausing Group " $item.id " Name " $item.displayname -ForegroundColor black -BackgroundColor red
                write-host "CTRL+C to stop at any time" -ForegroundColor black -BackgroundColor white
                Update-MgGroup -MembershipRuleProcessingState paused -GroupId $item.id
                start-sleep 1                
            }
        }
        else {break}
    }
    # Start/Unpause ALL Dynamic Groups
    "StartALL"
    {
        Write-Host "Starting ALL Dynamic Groups"
        Write-Host "ARE YOU SURE YOU WANT TO START ALL GROUPS WITH DYNAMIC MEMBERSHIP?" -ForegroundColor red -BackgroundColor white f
        $ContinueQuestion2  = Read-Host "Type 'yes' to confirm: "
        if($ContinueQuestion2.ToUpper() -eq "YES")
        {
        $group = get-mggroup -all -property id, displayname, MembershipRuleProcessingState | Select-Object displayname, id, MembershipRuleProcessingState | Where-Object{$_.MembershipRuleProcessingState -like "Pause*"} | sort-object DisplayName
            foreach($item in $group)
            {
                write-host "Starting Group " $item.id " Name " $item.displayname  -ForegroundColor green -BackgroundColor black
                Update-MgGroup -MembershipRuleProcessingState On -GroupId $item.id
                start-sleep 1
            }
        }
        else {break}
    }
    #"Pause Select Dynamic Group Processing"
    "PauseSelect"
    {
        $groupinfo = Get-MgGroup -GroupId $GroupObjectId | Select-Object DisplayName, Id
        write-host "Pausing Group " $groupinfo.id " Name " $GroupObjectId
        update-MgGroup -MembershipRuleProcessingState Paused -GroupId $groupinfo.id 
    }
    #"Start Dynamic Group Processing"
    "StartSelect"
    {
        $groupinfo = Get-MgGroup -GroupId $GroupObjectId | Select-Object DisplayName, Id
        write-host "Starting Group " $groupinfo.id " Name " $GroupObjectId
        update-MgGroup -MembershipRuleProcessingState On -GroupId $GroupObjectId
    }
}
