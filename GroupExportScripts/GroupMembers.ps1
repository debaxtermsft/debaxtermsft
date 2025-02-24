<# Written by Derrick Baxter debaxter@microsoft.com
the below script uses the Azure Graph powershell module to retrieve Groups memberships (needed if a security group is deleted)
(THESE SAVE PII, make sure you save them based on your Country/State/Local Laws)
 2/21/25
Derrick J. Baxter

 Group Members/Group Attributes
 Group Members and Group Attributes filter1- All/Assigned/Dynamic
 Group Members - All (gets all group members of all Groups)
 Group Members - Assigned Filters - All(assigned)/Azure Security/Office Security/Selected Azure Security/Selected Office Security/Selected Office Non-Security
 Group Members - Dynamic Filter - All(dynamic)/Azure/Office/Selected Azure/Selected Office
 Group Attributes - All (all groups)/Assigned (All assigned group attributes)/ Dynamic (all Dynamic Group Attributes)
 Group Licenses - All (gets all groups with licenses)
 Group Licenses - Selected (select the groups with licenses assigned to export)
 Export Conditional Access Policies with included/excluded groups
Using Powershell microsoft.graph


IMPORTANT!!!

To consent for users to run this script a global admin will need to run the following
-------------------------------------------------------------------------------------------
$sp = get-mgserviceprincipal | ?{$_.displayname -eq "Microsoft Graph"}
$resource = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"
$principalid = "users object id"
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
-------------------------------------------------------------------------------------------
You may need to update the connect-mggraph to have the -environment USGov or as needed -tenantid <tenantid> can be added as needed.

#>

param([parameter(Position=0,mandatory)][validateset("All","Group ObjectID")] [string]$GroupOption="All",
        [parameter(Position=1,mandatory=$false)][string]$GroupObjectID,
        [parameter(Position=2,mandatory=$false)][validateset("All","Assigned","Dynamic")] [string]$GroupTypeFilter="All",
        [parameter(Position=3,mandatory=$false)][validateset("All","Azure","Office")] [string]$SecurityofOfficeGroup="All",
        [parameter (Position=5,mandatory)][validateset("HTML", "CSV")] [string]$ExportFileType,
        [parameter(Position=4,mandatory)] [string]$Outputdirectory)

try
    {
    Get-MGDomain -ErrorAction Stop > $null
    }
catch
    {
    Connect-MgGraph -Scopes "group.read.all, directory.read.all, groupmember.read.all"
    }
$GMs = @()
    if($GroupOption -eq "All")
    {
        switch -exact ($GroupTypeFilter) 
        {

            "Assigned"
            {
                
                switch -exact ($SecurityofOfficeGroup) 
                {

                    "Azure"
                    {
                        
                        $group = get-mggroup -all  | 
                        where-object{($_.GroupTypes.Count -eq 0 -or $_.grouptypes -notcontains "DynamicMembership"  -and $_.grouptypes -notcontains "Unified" ) }| 
                            select-object displayname, id, description | 
                            Sort-Object DisplayName
                    }
                    "Office"
                    {
                        
                        $group = get-mggroup -all | 
                        where-object{($_.GroupTypes.Count -eq 0 -or $_.grouptypes -notcontains "DynamicMembership"  -and $_.grouptypes -contains "Unified" ) }| 
                            select-object displayname, id, description | 
                            Sort-Object DisplayName
                    }

                    "All"
                    {
                        $group = get-mggroup -all | 
                            where-object{($_.GroupTypes.Count -eq 0 -or $_.grouptypes -notcontains "DynamicMembership") }| 
                            Sort-Object DisplayName
                    }
                }

            }
            "Dynamic"
            {
                
                
                switch -exact ($SecurityofOfficeGroup) 
                {
                    "Azure"
                    {
                        
                        $group = get-mggroup -all | 
                        Where-Object{($_.grouptypes -contains "DynamicMembership" -and $_.grouptypes -notcontains "Unified") }| 
                        Select-Object displayname, id, description | 
                        Sort-Object DisplayName
                    }
                    "Office"
                    {
                        
                        $group = get-mggroup -all | 
                        where-object{($_.grouptypes -contains "DynamicMembership" -and $_.grouptypes -contains "Unified") }| 
                        select-object displayname, id, description | 
                        Sort-Object DisplayName
                    }
                    "All"
                    {
                        
                        $group = get-mggroup -all | 
                        where-object{$_.grouptypes -contains "DynamicMembership"}|
                        select-object displayname, id, description | 
                            Sort-Object DisplayName
                    }
            }
            }
            "All"
            {
                
                $group = get-mggroup -all  | 
                   select-object displayname, id, description | 
                    Sort-Object DisplayName
            }
        }
    }
    else 
    {
        $group = get-mggroup -GroupId $GroupObjectID
    }
    
    $group.count 
    foreach ($item in $group)
        {
            $findgroupmembers = get-mggroupmember -GroupId $item.id 
            
            if($findgroupmembers.count -ne 0) 
            {
                foreach ($groupmember1 in $findgroupmembers)
                {
                    $zero = $groupmember1.additionalproperties.values[0]
                    
                    #$zero
                    if ($zero -match "graph.group")
                    {
                        
                        $groupinfo = get-mggroup -GroupId $groupmember1.Id
                                $GMs += New-Object Object |
                                    Add-Member -NotePropertyName GroupDisplayName -NotePropertyValue $item.DisplayName -PassThru |
                                    Add-Member -NotePropertyName GroupDescription -NotePropertyValue $item.Description -PassThru |
                                    Add-Member -NotePropertyName GroupID -NotePropertyValue $item.Id -PassThru |
                                    Add-Member -NotePropertyName MemberDisplayName -NotePropertyValue $groupinfo.displayName -PassThru |
                                    Add-Member -NotePropertyName MemberID -NotePropertyValue $groupinfo.id -PassThru |
                                    Add-Member -NotePropertyName MemberObjectType -NotePropertyValue "Group" -PassThru
                    }
            
                    elseif ($zero -match "graph.user")
                    {
                        
                        $groupuser = get-mguser -UserId $groupmember1.Id
                                $GMs += New-Object Object |
                                        Add-Member -NotePropertyName GroupDisplayName -NotePropertyValue $item.DisplayName -PassThru |
                                        Add-Member -NotePropertyName GroupDescription -NotePropertyValue $item.Description -PassThru |
                                        Add-Member -NotePropertyName GroupID -NotePropertyValue $item.Id -PassThru |
                                        Add-Member -NotePropertyName MemberDisplayName -NotePropertyValue $groupuser.DisplayName -PassThru |
                                        Add-Member -NotePropertyName MemberID -NotePropertyValue $groupuser.Id -PassThru |
                                        Add-Member -NotePropertyName MemberUserPrincipalName -NotePropertyValue $groupuser.UserPrincipalName -PassThru |
                                        Add-Member -NotePropertyName MemberObjectType -NotePropertyValue "User" -PassThru
                    }
                    elseif ($zero -match "graph.device")
                    {
                        
                        $devid = $groupmember1.Id
                        $groupuser = get-mgdevice -Filter "Id eq '$devid'" 
                                $GMs += New-Object Object |
                                        Add-Member -NotePropertyName GroupDisplayName -NotePropertyValue $item.DisplayName -PassThru |
                                        Add-Member -NotePropertyName GroupDescription -NotePropertyValue $item.Description -PassThru |
                                        Add-Member -NotePropertyName GroupID -NotePropertyValue $item.Id -PassThru |
                                        Add-Member -NotePropertyName MemberDisplayName -NotePropertyValue $groupuser.displayName -PassThru |
                                        Add-Member -NotePropertyName MemberID -NotePropertyValue $groupuser.id -PassThru |
                                        Add-Member -NotePropertyName MemberObjectType -NotePropertyValue "Device" -PassThru
                    }
                    else
                    {
                        
                        $groupuser = Get-MgServicePrincipal -ServicePrincipalId $groupmember1.id
                                $GMs += New-Object Object |
                                        Add-Member -NotePropertyName GroupDisplayName -NotePropertyValue $item.DisplayName -PassThru |
                                        Add-Member -NotePropertyName GroupDescription -NotePropertyValue $item.Description -PassThru |
                                        Add-Member -NotePropertyName GroupID -NotePropertyValue $item.Id -PassThru |
                                        Add-Member -NotePropertyName MemberDisplayName -NotePropertyValue $groupuser.displayName -PassThru |
                                        Add-Member -NotePropertyName MemberID -NotePropertyValue $groupuser.Appid -PassThru |
                                        Add-Member -NotePropertyName MemberObjectType -NotePropertyValue "ServicePrincipal" -PassThru
            
                    }
                }
            }
        }        

    #creating header for CSV
    

$tdy = get-date -Format "MM-dd-yyyy_hh.mm.ss"
if($ExportFileType -eq "CSV")
{
$outputfile = $Outputdirectory + "GroupMembers_"+$tdy+".csv"
$GMs | sort-object groupdisplayname,MemberDisplayName| export-csv -Path $outputfile -NoTypeInformation -Encoding UTF8
}
else
{
$htmlfile = $Outputdirectory + "GroupsMembers_"+$tdy+".html"

$cssStyle = @"
<style>
table {
    width: 100%;
    border-collapse: collapse;
}
th, td {
    border: 1px solid #dddddd;
    text-align: left;
    padding: 8px;
}
tr:nth-child(even) {
    background-color: #f2f2f2;
}
th {
    background-color: #4CAF50;
    color: white;
}
</style>
"@

$htmlContent = $GMs | Sort-object GroupDisplayName,MemberDisplayName | ConvertTo-Html -Title "Last Signin Activity by DisplayName" -As "Table"
$htmlContent = $htmlContent -replace "</head>", "$cssStyle`n</head>"
$htmlContent | Out-File $htmlfile
}
