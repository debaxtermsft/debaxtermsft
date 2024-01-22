<#
 Written by Derrick Baxter 
 the below script uses the Graph powershell module pulling all roleassignments for groups

debaxter
complete rewrite for Azure Graph
debaxter@microsoft.com
Updated with licenses 7/20/22
Updated with Conditional Access Policy Export 7/21/22
complete rewrite from Az UI version
Group Members/Group Attributes
Group Members and Group Attributes filter1- All/Assigned/Dynamic
Group Members - All (gets all group members of all Groups)
Group Members - Assigned Filters - All(assigned)/Azure Security/Office Security
Group Members - Dynamic Filter - All(dynamic)/Azure/Office
Group Attributes - All (all groups)/Assigned (All assigned group attributes)/ Dynamic (all Dynamic Group Attributes)
Group Licenses - All (gets all groups with licenses)
Group Licenses - Selected (select the groups with licenses assigned to export)
Export Conditional Access Policies with included/excluded groups
Using Powershell microsoft.graph
Using Powershell Graph version
CLI Version
 updated 5/12/22 using objects over arrays
 Group Attribute example
  .\AzureGroupExport-MGGraph_CLI.ps1 -mainmenu 'Group Members' -GroupTypeFilter All -SecurityorOfficeGroup All -Outputdirectory "c:\temp\"
  .\AzureGroupExport-MGGraph_CLI.ps1 -mainmenu 'Group Members' -GroupTypeFilter Assigned -SecurityorOfficeGroup Azure -Outputdirectory "c:\temp\"
 Group Members examples
  .\AzureGroupExport-MGGraph_CLI.ps1 -mainmenu 'Group Attributes' -GroupTypeFilter All -SecurityorOfficeGroup All -Outputdirectory "c:\temp\"
 .\AzureGroupExport-MGGraph_CLI.ps1 -mainmenu 'Group Attributes' -GroupTypeFilter Dynamic -SecurityorOfficeGroup Office -Outputdirectory "c:\temp\"

You may need to have a global admin run the below rem'ed script to consent to the user to run this script

$sp = get-mgserviceprincipal | ?{$_.displayname -eq "Microsoft Graph"}
$resource = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"
$principalid = "user object id"
$scope1 ="group.read.all"
$scope2 ="directory.read.all"
$scope3 ="groupmember.read.all"
$today = Get-Date -Format "yyyy-MM-dd"
$expiredate1 = get-date
$expiredate2 = $expiredate1.AddDays(365).ToString("yyyy-MM-dd")
$params = @{
    ClientId = $SP.Id
    ConsentType = "Principal"
    ResourceId = $resource.id
    principalId = $principalid
    Scope = "$scope1" + " " + "$scope2"+ " " + "$scope3"
    startTime = "$today"
    expiryTime = "$expiredate2"
}
$InitialConsented = New-MgOauth2PermissionGrant -BodyParameter $params


You may need to update the connect-mggraph to have the -environment USGov or as needed -tenantid <tenantid> can be added as needed.



#> 

    <#param([parameter(mandatory)][validateset("Groups Attributes","Group Members","Group Owners", "Group Licenses", "Groups in Conditional Access Policies", "Groups in Application")][string] $mainmenu,
          [parameter(mandatory)][validateset("All","Assigned","Dynamic")] [string]$GroupTypeFilter,
          [parameter(mandatory)][validateset("All","Azure","Office")] [string]$SecurityofOfficeGroup,
          [parameter(mandatory)] [string]$Outputdirectory) #>


    param([parameter(Position=0,mandatory)][validateset("All","Group ObjectID")] [string]$GroupOption,
          [parameter(Position=1,mandatory=$false)][string]$GroupObjectID,
          [parameter(Position=2,mandatory)][validateset("Groups Attributes","Group Members","Group Owners", "Group Licenses", "Groups in Conditional Access Policies", "Groups in Application")][string] $exporttype,
          [parameter(Position=3,mandatory)][validateset("All","Assigned","Dynamic")] [string]$GroupTypeFilter,
          [parameter(Position=4,mandatory)][validateset("All","Azure","Office")] [string]$SecurityofOfficeGroup,
          [parameter(Position=5,mandatory)] [string]$Outputdirectory)
#" group1, group2, group3"
#remove the rem below and enter the tenant id, and rem the 2nd connect-azaccount
try
    {
    Get-MGDomain -ErrorAction Stop > $null
    }
catch
    {
    Connect-MgGraph -Scopes "group.read.all, directory.read.all,groupmember.read.all"
    Select-MgProfile -Name "beta"
    }

    

    $group  =@()
    $groupinfo =@()
    $groupinfo2 =@()
    $GMs =@()
    if ($mainmenu -eq "Group Members")
    {
        if( $GroupTypeFilter -eq "Dynamic") #all dynamic group members
        {
            if($SecurityofOfficeGroup -eq "Azure")
            {
            $group = get-mggroup -all | 
                Where-Object{($_.grouptypes -contains "DynamicMembership" -and $_.grouptypes -notcontains "Unified" -and $_.securityenabled -eq $true) }| 
                Select-Object displayname, id, description | 
                Sort-Object DisplayName
            }
            elseif($SecurityofOfficeGroup -eq "Office")
            {and I
            $group = get-mggroup -all | 
                Where-Object{($_.grouptypes -contains "DynamicMembership" -and $_.grouptypes -contains "Unified"-and $_.securityenabled -eq $true) }| 
                Select-Object displayname, id, description | 
                Sort-Object DisplayName
            }

            else
            {
            $group = get-mggroup -all | 
                Select-Object displayname, id, description | 
                Sort-Object DisplayName
                start-sleep 6
            }
        }
        elseif($GroupTypeFilter -eq "Assigned") #all assigned group members
        {
            if($SecurityofOfficeGroup -eq "Azure")
            {
                $group = get-MGgroup -all  | 
                    Where-Object{($_.GroupTypes.Count -eq 0 -or $_.grouptypes -notcontains "DynamicMembership"  -and $_.grouptypes -notcontains "Unified") }| 
                    Select-Object displayname, id, description | 
                    Sort-Object DisplayName
            }
            elseif($SecurityofOfficeGroup -eq "Office")
            {
                $group = get-MGgroup -all  | 
                    Where-Object{($_.GroupTypes.Count -eq 0 -or $_.grouptypes -notcontains "DynamicMembership"  -and $_.grouptypes -contains "Unified") }| 
                    Select-Object displayname, id, description | 
                    Sort-Object DisplayName
            }

            else
            {
                $group = get-MGgroup -all  | 
                    Where-Object{($_.GroupTypes.Count -eq 0 -or $_.grouptypes -notcontains "DynamicMembership") }| 
                    Sort-Object DisplayName
             }

        }
        else # must be All group members of dynamic and office "Unified"
        {
                $group = get-MGgroup -all  | 
                    Select-Object displayname, id, description | 
                    Sort-Object DisplayName
        }
    
        $zero =@()
        foreach ($groupitem in $group)
        {
        
            $mggroup = Get-MgGroupMember -GroupId  $groupitem.id
            if($mggroup.Count -ne 0) 
            {
                foreach ($groupmember1 in $mggroup)
                {
                    $zero = $groupmember1.additionalproperties.values[0]
                    #$zero
                    if ($zero -match "graph.group")
                    {
                        $groupinfo = get-mggroup -GroupId $groupmember1.Id
                                $GMs += New-Object Object |
                                    Add-Member -NotePropertyName GroupDisplayName   -NotePropertyValue $groupitem.DisplayName   -PassThru |
                                    Add-Member -NotePropertyName GroupDescription   -NotePropertyValue $groupitem.Description   -PassThru |
                                    Add-Member -NotePropertyName GroupID            -NotePropertyValue $groupitem.Id            -PassThru |
                                    Add-Member -NotePropertyName MemberDisplayName  -NotePropertyValue $groupinfo.displayName   -PassThru |
                                    Add-Member -NotePropertyName MemberID           -NotePropertyValue $groupinfo.id            -PassThru |
                                    Add-Member -NotePropertyName MemberObjectType   -NotePropertyValue "Group"                  -PassThru
                    }
        
                    elseif ($zero -match "graph.user")
                    {
                        $groupuser = get-mguser -UserId $groupmember1.Id
                                $GMs += New-Object Object |
                                        Add-Member -NotePropertyName GroupDisplayName   -NotePropertyValue $groupitem.DisplayName   -PassThru |
                                        Add-Member -NotePropertyName GroupDescription   -NotePropertyValue $groupitem.Description   -PassThru |
                                        Add-Member -NotePropertyName GroupID            -NotePropertyValue $groupitem.Id            -PassThru |
                                        Add-Member -NotePropertyName MemberDisplayName  -NotePropertyValue $groupuser.DisplayName   -PassThru |
                                        Add-Member -NotePropertyName MemberID           -NotePropertyValue $groupuser.Id            -PassThru |
                                        Add-Member -NotePropertyName MemberObjectType   -NotePropertyValue "User"                   -PassThru
                    }
                    elseif ($zero -match "graph.device")
                    {
                    $devid = $groupmember1.Id
                        $groupuser = get-mgdevice -Filter "Id eq '$devid'" 
                                $GMs += New-Object Object |
                                        Add-Member -NotePropertyName GroupDisplayName   -NotePropertyValue $groupitem.DisplayName   -PassThru |
                                        Add-Member -NotePropertyName GroupDescription   -NotePropertyValue $groupitem.Description   -PassThru |
                                        Add-Member -NotePropertyName GroupID            -NotePropertyValue $groupitem.Id            -PassThru |
                                        Add-Member -NotePropertyName MemberDisplayName  -NotePropertyValue $groupuser.displayName   -PassThru |
                                        Add-Member -NotePropertyName MemberID           -NotePropertyValue $groupuser.id            -PassThru |
                                        Add-Member -NotePropertyName MemberObjectType   -NotePropertyValue "Device"                 -PassThru
                    }
                    else
                    {
                        $groupuser = Get-MgServicePrincipal -ServicePrincipalId $groupmember1.id
                                $GMs += New-Object Object |
                                        Add-Member -NotePropertyName GroupDisplayName   -NotePropertyValue $groupitem.DisplayName   -PassThru |
                                        Add-Member -NotePropertyName GroupDescription   -NotePropertyValue $groupitem.Description   -PassThru |
                                        Add-Member -NotePropertyName GroupID            -NotePropertyValue $groupitem.Id            -PassThru |
                                        Add-Member -NotePropertyName MemberDisplayName  -NotePropertyValue $groupuser.displayName   -PassThru |
                                        Add-Member -NotePropertyName MemberID           -NotePropertyValue $groupuser.Appid         -PassThru |
                                        Add-Member -NotePropertyName MemberObjectType   -NotePropertyValue "ServicePrincipal"       -PassThru
        
                    }
                }
            }
        }
        
        $tdy = get-date -Format "MM-dd-yyyy hh.mm.ss"
        $file = $outputdirectory + $mainmenu +"_"+ $GroupTypeFilter+"_"+ $SecurityofOfficeGroup+$tdy+".csv"
        $GMs| export-csv -Path $file -NoTypeInformation -Encoding utf8 -Force
    }
    else #  Group attributes ($MainMenuQuestion -eq "Group Attributes") #used to backup all information about a group needed to recreate assigned group, especially dynamic security groups w rule
    {
        if($GroupTypeFilter -eq "Dynamic")
        {
                $group = get-MGgroup -all  |
                Where-Object{$_.grouptypes -contains "DynamicMembership"}|
                Select-Object displayname,description, id, securityenabled, IsAssignableToRole, proxyaddresses, GroupTypes,  MailEnabled, Mail, mailnickname,AssignedLabels, MembershipRule |
                Sort-Object DisplayName

        }
        elseif($GroupTypeFilter -eq "Assigned")
        {
                $group = get-MGgroup -all  |
                Where-Object{$_.grouptypes -notcontains "DynamicMembership"}|
                Select-Object displayname,description, id, securityenabled, IsAssignableToRole, proxyaddresses, GroupTypes,  MailEnabled, Mail, mailnickname,AssignedLabels, MembershipRule |
                Sort-Object DisplayName
            
        }

        else # condition for all Group Attributes, all a&d and all s/o
        { 
            $group = get-MGgroup -all  | Sort-Object DisplayName 
        }
        if ($group -eq 0)
        {
                        $groupinfo2 = "No groups"
                        $groupinfo += $groupinfo2
        }
        else
        {
                    $GAs=@()
                       foreach ($item in $group )
                       {
                           [string]$proxy = $item.ProxyAddresses
                           [string]$grouptypes = $item.grouptypes
                           [string]$labels = $item.assignedlables
                           $groupowner = Get-MgGroupOwner -GroupId $item.id
                        $GAs += New-Object Object |
                                        Add-Member -NotePropertyName Group_DisplayName  -NotePropertyValue $item.DisplayName        -PassThru |
                                        Add-Member -NotePropertyName Group_Description  -NotePropertyValue $item.Description        -PassThru |
                                        Add-Member -NotePropertyName GroupID            -NotePropertyValue $item.Id                 -PassThru |
                                        Add-Member -NotePropertyName securityenabled    -NotePropertyValue $item.securityenabled    -PassThru |
                                        Add-Member -NotePropertyName IsAssignableToRole -NotePropertyValue $item.IsAssignableToRole -PassThru |
                                        Add-Member -NotePropertyName proxyaddresses     -NotePropertyValue $proxy                   -PassThru |
                                        Add-Member -NotePropertyName GroupTypes         -NotePropertyValue $grouptypes              -PassThru |
                                        Add-Member -NotePropertyName MailEnabled        -NotePropertyValue $item.MailEnabled        -PassThru |
                                        Add-Member -NotePropertyName Mail               -NotePropertyValue $item.Mail               -PassThru |
                                        Add-Member -NotePropertyName mailnickname       -NotePropertyValue $item.mailnickname       -PassThru |
                                        Add-Member -NotePropertyName AssignedLabels     -NotePropertyValue $labels                  -PassThru |
                                        Add-Member -NotePropertyName MembershipRule     -NotePropertyValue $item.MembershipRule     -PassThru | 
                                        Add-Member -NotePropertyName GroupOwner         -NotePropertyValue $groupowner.id           -PassThru 
                        }            

        $tdy = get-date -Format "MM-dd-yyyy hh.mm.ss"
        $file = $outputdirectory + $mainmenu +"_"+ $GroupTypeFilter+"_"+ $SecurityofOfficeGroup+$tdy+".csv"
        $GAs| export-csv -Path $file -NoTypeInformation -Encoding utf8 -Force
        }
    }

