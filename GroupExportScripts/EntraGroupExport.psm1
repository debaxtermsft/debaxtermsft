<# Written by Derrick Baxter 
the below Powershell module to export
Group Attributes
Group Members
Group CA policy Assignments
Group License Assignments
Group Application Assignments
Group Expiration Policy 

export-EntraGroupMembers  -GroupOption All -GroupTypeFilter All -SecurityofOfficeGroup All -Outputdirectory C:\temp\GroupExportScripts\demo\ -ExportFileType html
export-EntraGroupMembers -GroupOption All -GroupTypeFilter All -SecurityofOfficeGroup Office -Outputdirectory C:\temp\GroupExportScripts\demo\ -ExportFileType html
export-EntraGroupMembers -GroupOption All -GroupTypeFilter All -SecurityofOfficeGroup Azure -Outputdirectory C:\temp\GroupExportScripts\demo\ -ExportFileType html

export-EntraGroupMembers  -GroupOption All -GroupTypeFilter Assigned -SecurityofOfficeGroup All -Outputdirectory C:\temp\GroupExportScripts\demo\ -ExportFileType html
export-EntraGroupMembers  -GroupOption All -GroupTypeFilter Assigned -SecurityofOfficeGroup All -Outputdirectory C:\temp\GroupExportScripts\demo\ -ExportFileType html
export-EntraGroupMembers  -GroupOption All -GroupTypeFilter Dynamic -SecurityofOfficeGroup All -Outputdirectory C:\temp\GroupExportScripts\demo\ -ExportFileType html
export-EntraGroupMembers  -GroupOption All -GroupTypeFilter Dynamic -SecurityofOfficeGroup All -Outputdirectory C:\temp\GroupExportScripts\demo\ -ExportFileType html


export-EntraGroupMembers  -GroupOption 'Group ObjectID' -GroupObjectID <GroupObjectiD> -GroupTypeFilter All -SecurityofOfficeGroup All -Outputdirectory C:\temp\GroupExportScripts\demo\ -ExportFileType html

export-EntraGroupAttributes -GroupOption All -ExportFileType html -Outputdirectory C:\temp\GroupExportScripts\demo\
export-EntraGroupAttributes -GroupOption 'Group ObjectID' -GroupObjectID <GroupObjectiD> -ExportFileType html -Outputdirectory C:\temp\GroupExportScripts\demo\

export-EntraGroupCAPolicyAssignments -GroupOption All -ExportFileType html -Outputdirectory c:\temp\groupexportscripts\
export-EntraGroupCAPolicyAssignments -GroupOption All -ExportFileType CSV -Outputdirectory c:\temp\groupexportscripts\

export-EntraGroupCAPolicyAssignments -GroupOption 'Group ObjectID' -ExportFileType html -Outputdirectory c:\temp\groupexportscripts\ -GroupObjectID <group objectid>
export-EntraGroupCAPolicyAssignments -GroupOption 'Group ObjectID' -ExportFileType CSV -Outputdirectory c:\temp\groupexportscripts\ -GroupObjectID <group objectid>

export-EntraGroupLicenseAssignments -GroupOption all -ExportFileType CSV -Outputdirectory  C:\temp\GroupExportScripts\
export-EntraGroupLicenseAssignments -GroupOption all -ExportFileType HTML -Outputdirectory  C:\temp\GroupExportScripts\

export-EntraGroupLicenseAssignments -GroupOption 'Group ObjectID' -GroupObjectID <GroupObjectiD> -ExportFileType CSV -Outputdirectory  C:\temp\GroupExportScripts\
export-EntraGroupLicenseAssignments -GroupOption 'Group ObjectID' -GroupObjectID <GroupObjectiD> -ExportFileType HTML -Outputdirectory  C:\temp\GroupExportScripts\

export-EntraGroupApplicationAssignments -GroupOption 'Group ObjectID' -GroupObjectID "group objectid guid"f -ExportFileType HTML -Outputdirectory C:\temp\GroupExportScripts\
export-EntraGroupApplicationAssignments -GroupOption 'Group ObjectID' -GroupObjectID "group objectid guid" -ExportFileType CSV -Outputdirectory C:\temp\GroupExportScripts\

export-EntraGroupApplicationAssignments -GroupOption All  -Outputdirectory C:\temp\GroupExportScripts\ -ExportFileType HTML
export-EntraGroupApplicationAssignments -GroupOption All  -Outputdirectory C:\temp\GroupExportScripts\ -ExportFileType csv

 2/25/25
 Derrick J. Baxter

update 3/18/25 
Added in Group Expiration Policy export 


IMPORTANT!!!

To consent for users to run this script a global admin will need to run the following
-------------------------------------------------------------------------------------------
$sp = get-mgserviceprincipal | ?{$_.displayname -eq "Microsoft Graph"}
$resource = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"
$principalid = "users object id"
$scope1 ="group.read.all"
$scope2 ="directory.read.all"
$scope3 ="groupmember.read.all"
$scope4 ="Policy.Read.ConditionalAccess"
$scope5 ="Application.Read.All"

$today = Get-Date -Format "yyyy-MM-dd"
$expiredate1 = get-date
$expiredate2 = $expiredate1.AddDays(365).ToString("yyyy-MM-dd")
$params = @{
    ClientId = $SP.Id
    ConsentType = "Principal"
    ResourceId = $resource.id
    principalId = $principalid
    Scope = "$scope1" + " " + "$scope2"+ " " + "$scope3"+ " " + "$scope4"+ " " + "$scope5"
    startTime = "$today"
    expiryTime = "$expiredate2"

}

$InitialConsented = New-MgOauth2PermissionGrant -BodyParameter $params
-------------------------------------------------------------------------------------------
You may need to update the connect-mggraph to have the -environment USGov or as needed -tenantid <tenantid> can be added as needed.


#>
function export-EntraGroupAttributes{
param([parameter(Position=0,mandatory)][validateset("All","Group ObjectID")] [string]$GroupOption="All",
        [parameter(Position=1,mandatory=$false)][string]$GroupObjectID,
        [parameter(Position=2,mandatory=$false)][validateset("All","Assigned","Dynamic")] [string]$GroupTypeFilter="All",
        [parameter(Position=3,mandatory=$false)][validateset("All","Azure","Office")] [string]$SecurityofOfficeGroup="All",
        [parameter (Position=5,mandatory)][validateset("HTML", "CSV")] [string]$ExportFileType,
        [parameter(Position=4,mandatory)] [string]$Outputdirectory)


If($GroupOption -eq "All")
    {
        $file = "GroupAttributeExport_" + $groupoption + "_" + $GroupTypeFilter + "_" + $SecurityofOfficeGroup + "_" 
    }
else 
    {
        $file = "GroupAttributeExport_" + $groupoption + "_" + $GroupObjectID + "_" + $GroupTypeFilter + "_" + $SecurityofOfficeGroup + "_" 
    }
        
try
    {
    Get-MGDomain -ErrorAction Stop > $null
    }
catch
    {
    Connect-MgGraph -Scopes "group.read.all, directory.read.all"
    }


        $group =@()
if($GroupOption -eq "All")
    {
        switch -exact ($GroupTypeFilter) 
        {
            "Assigned"
            {
                $group = get-mggroup -all  |
                where-object{$_.grouptypes -notcontains "DynamicMembership"}|
                    select-object displayname,description, id, securityenabled, IsAssignableToRole, proxyaddresses, GroupTypes,  MailEnabled, Mail, mailnickname,AssignedLabels, MembershipRule |
                    Sort-Object DisplayName
            }
            "Dynamic"
            {
                $group = get-mggroup -all |
                where-object{$_.grouptypes -contains "DynamicMembership"}|
                    select-object displayname,description, id, securityenabled, IsAssignableToRole, proxyaddresses, GroupTypes,  MailEnabled, Mail, mailnickname,AssignedLabels, MembershipRule |
                    Sort-Object DisplayName
            }
            "All"
            {
                $group = get-mggroup -all | Sort-Object DisplayName 
            }
        }
    }
    else 
    {
        $group = get-mggroup -GroupId $GroupObjectID
    }
    #$group.count
        if(!$group)
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
                     
                    $GOlookup =@()
                    $GODNList =@()
                    $GOID2 =@()
                    try {
                        $groupownerobjectidlookup = Get-MgGroupOwner -GroupId $item.id -ErrorAction SilentlyContinue
                        $GOID2 = $groupownerobjectidlookup.id -join ", "
                        #write-host " Owner Count " $groupownerobjectidlookup.count
                        if ($groupownerobjectidlookup.count -ge 1){
                            
                            foreach ($itemGO in $groupownerobjectidlookup)
                            {
                                $GOlookup += (get-mguser -UserId $itemGO.id).DisplayName
                            
                            }
                            $GODNList = $GOlookup -join ", "
                        }
                        else {
                            $GODNList = "No Owner Listed"
                            $GOID2 = "No Onwer listed"                        }
                    }
                    catch {
                        write-host "No Group Owner Listed "

                    }

                    $GAs += New-Object Object |
                                Add-Member -NotePropertyName Group_DisplayName -NotePropertyValue $item.DisplayName -PassThru |
                                Add-Member -NotePropertyName Group_Description -NotePropertyValue $item.Description -PassThru |
                                Add-Member -NotePropertyName GroupID -NotePropertyValue $item.Id -PassThru |
                                Add-Member -NotePropertyName securityenabled -NotePropertyValue $item.securityenabled -PassThru |
                                Add-Member -NotePropertyName IsAssignableToRole -NotePropertyValue $item.IsAssignableToRole -PassThru |
                                Add-Member -NotePropertyName proxyaddresses -NotePropertyValue $proxy -PassThru |
                                Add-Member -NotePropertyName GroupTypes -NotePropertyValue $grouptypes -PassThru |
                                Add-Member -NotePropertyName MailEnabled -NotePropertyValue $item.MailEnabled -PassThru |
                                Add-Member -NotePropertyName Mail -NotePropertyValue $item.Mail -PassThru |
                                Add-Member -NotePropertyName mailnickname -NotePropertyValue $item.mailnickname -PassThru |
                                Add-Member -NotePropertyName AssignedLabels -NotePropertyValue $labels -PassThru |
                                Add-Member -NotePropertyName MembershipRule -NotePropertyValue $item.MembershipRule -PassThru |
                                Add-Member -NotePropertyName GroupOwnerDisplayname -NotePropertyValue $GODNList -PassThru |
                                Add-Member -NotePropertyName GroupOwnerObjecId -NotePropertyValue $GOid2 -PassThru 

                } 
            
        } 
        

$tdy = get-date -Format "MM-dd-yyyy_HH.mm.ss"
if($ExportFileType -eq "CSV")
{
$outputfile = $Outputdirectory + $file +$tdy+".csv"
$GAs | sort-object Group_DisplayName | export-csv -Path $outputfile -NoTypeInformation -Encoding UTF8
}
else
{
$htmlfile = $Outputdirectory + $file +$tdy+".html"

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
    background-color:rgb(19, 228, 243);
    color: white;
}
</style>
"@

$htmlContent = $GAs | Sort-object Group_DisplayName| ConvertTo-Html -Title "Group Attribute Export" -As "Table"
$htmlContent = $htmlContent -replace "</head>", "$cssStyle`n</head>"
$htmlContent | Out-File $htmlfile
}
        
}
#end of export group attributes function
function export-EntraGroupMembers 
{
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
Connect-MgGraph -Scopes "group.read.all, directory.read.all, groupmember.read.all, Policy.Read.All, Application.Read.All"
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


$tdy = get-date -Format "MM-dd-yyyy_HH.mm.ss"
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

$htmlContent = $GMs | Sort-object GroupDisplayName,MemberDisplayName | ConvertTo-Html -Title "Group Member Export" -As "Table"
$htmlContent = $htmlContent -replace "</head>", "$cssStyle`n</head>"
$htmlContent | Out-File $htmlfile
}

}
function export-EntraGroupCAPolicyAssignments 
{

    param([parameter(Position=0,mandatory)][validateset("All","Group ObjectID")] [string]$GroupOption="All",
    [parameter(Position=1,mandatory=$false)][string]$GroupObjectID,
    [parameter (Position=2,mandatory)][validateset("HTML", "CSV")] [string]$ExportFileType,
    [parameter(Position=3,mandatory)] [string]$Outputdirectory)


try
{
Get-MGDomain -ErrorAction Stop > $null
}
catch
{
Connect-MgGraph -Scopes "group.read.all, directory.read.all, groupmember.read.all, Policy.Read.All, Application.Read.All"
}



    #(old call)$CAs = Invoke-MgGraphRequest -Uri 'https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies' -method get
if($GroupOption -eq "All")
{
    write-host "all"
    $CAs = Invoke-MgGraphRequest -Uri 'https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies?$filter=conditions/users/includeGroups/any() or conditions/users/excludeGroups/any()?$select=id,displayName,conditions' -Method GET
}
else 
{
#        $URI = 'https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies?$filter=conditions/users/includeGroups/any(g: g eq '$GroupObjectID') or conditions/users/excludeGroups/any(g: g eq '$GroupObjectID')'
write-host "not all"
    $buildURIheader1 = "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies?$"
    $buildURIheader2 = "filter=conditions/users/includeGroups/any(g: g eq '"
    $buildURItrailer1 = "') or conditions/users/excludeGroups/any(g: g eq '"
    $buildURItrailer2 = "')"
    $buildURItrailer3 = "?$"
    $buildURItrailer4 = "select=id,displayName,conditions"

    [string]$URIpassed = $buildURIheader1 + $buildURIheader2 + $GroupObjectID + $buildURItrailer1 + $GroupObjectID+ $buildURItrailer2 + $buildURItrailer3 + $buildURItrailer4
    $CAs = Invoke-MgGraphRequest -Uri $URIpassed -Method GET
}
    $cavalue = $cas.'value'
    #$cavalue.conditions.users.includeGroups
    #$cavalue.conditions.users.excludeGroups

    $CAGroupobject  = @()
    If ($cavalue.id.count -ge 1)
    {
        foreach($CAitem in $cavalue)
        {
            $CAName = $CAItem.displayName
            $CAID = $CAItem.id
            $CAInclude1 = $CAItem.conditions.users.includeGroups
            $CAExclude1 = $CAItem.conditions.users.excludeGroups
            foreach($CAIncludeitem in $CAinclude1)
            {
                $CAIncludeGroupname = Get-MgGroup -GroupId $CAIncludeitem
                $CAGroupobject += New-Object Object |
                Add-Member -NotePropertyName "Conditional Access Policy Name" -NotePropertyValue $CAName -PassThru |
                Add-Member -NotePropertyName "Conditional Access Policy Id" -NotePropertyValue $CAID -PassThru |
                Add-Member -NotePropertyName "Conditional Access Policy IncludedGroups" -NotePropertyValue $CAIncludeitem -PassThru |
                Add-Member -NotePropertyName "Conditional Access Policy IncludedGroups Name" -NotePropertyValue $CAIncludeGroupname.DisplayName -PassThru |
                Add-Member -NotePropertyName "Conditional Access Policy ExcludedGroups" -NotePropertyValue $null -PassThru |
                Add-Member -NotePropertyName "Conditional Access Policy ExcludedGroups Name" -NotePropertyValue $null -PassThru 
            }
            foreach ($CAExcludeitem in $CAExclude1)
            {
                $Groupname = (Get-MgGroup -GroupId $CAexcludeitem).DisplayName
                $Groupname
                $CAGroupobject += New-Object Object |
                Add-Member -NotePropertyName "Conditional Access Policy Name" -NotePropertyValue $CAName -PassThru |
                Add-Member -NotePropertyName "Conditional Access Policy Id" -NotePropertyValue $CAID -PassThru |
                Add-Member -NotePropertyName "Conditional Access Policy IncludedGroups" -NotePropertyValue $null -PassThru |
                Add-Member -NotePropertyName "Conditional Access Policy IncludedGroups Name" -NotePropertyValue $null -PassThru |
                Add-Member -NotePropertyName "Conditional Access Policy ExcludedGroups Name" -NotePropertyValue $Groupname -PassThru |
                Add-Member -NotePropertyName "Conditional Access Policy ExcludedGroups" -NotePropertyValue $CAExcludeitem -PassThru 
                
            }

        }

    }

if ($GroupOption -ne "All") 
{
$CAGroupobject = $CAGroupobject | Where-Object{$_.'Conditional Access Policy IncludedGroups' -eq "0ba8b0a3-9971-4b79-a064-aefcdd82545f" -or $_.'Conditional Access Policy ExcludedGroups' -eq "0ba8b0a3-9971-4b79-a064-aefcdd82545f"}
}
$tdy = get-date -Format "MM-dd-yyyy_HH.mm.ss"
if($ExportFileType -eq "CSV")
{
$outputfile = $Outputdirectory + "GroupsConditionalAccessPolicyAssignments_"+$tdy+".csv"
$CAGroupobject | sort-object "Conditional Access Policy Name","Conditional Access Policy IncludedGroups Name", "Conditional Access Policy ExcludedGroups Name"| export-csv -Path $outputfile -NoTypeInformation -Encoding UTF8
}
else
{
$htmlfile = $Outputdirectory + "GroupsConditionalAccessPolicyAssignments_"+$tdy+".html"

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

$htmlContent = $CAGroupobject | Sort-object "Conditional Access Policy Name","Conditional Access Policy IncludedGroups Name", "Conditional Access Policy ExcludedGroups Name" | ConvertTo-Html -Title "Group CA Policy Assignments" -As "Table"
$htmlContent = $htmlContent -replace "</head>", "$cssStyle`n</head>"
$htmlContent | Out-File $htmlfile
}
}
function export-EntraGroupLicenseAssignments
{

    param([parameter(Position=0,mandatory)][validateset("All","Group ObjectID")] [string]$GroupOption="All",
    [parameter(Position=1,mandatory=$false)][string]$GroupObjectID,
    [parameter (Position=2,mandatory)][validateset("HTML", "CSV")] [string]$ExportFileType,
    [parameter(Position=3,mandatory)] [string]$Outputdirectory)
    
    try
        {
        Get-MGDomain -ErrorAction Stop > $null
        }
    catch
        {
        Connect-MgGraph -Scopes "group.read.all, directory.read.all, user.read.all,LicenseAssignment.Read.All"
        }
    
        
    switch -exact ($GroupOption) 
    {
        "All" 
        {
            $sps =get-mgsubscribedSku |  Select-Object skupartnumber , serviceplans
            #get only groups with license assignments 
            #Graph call to get only groups with assigned licenses by calling only graph to get licenese in the tenant then checking which groups are assigned to those licenses
            $skus = Get-MgSubscribedSku
            $SKUinfos = @()
            $SkubuildURIheader1 = "https://graph.microsoft.com/v1.0/groups?$"
            $SkubuildURIheader2 = "filter=assignedLicenses/any(s:s/"
            $SkubuildURIheader3 ="skuId eq " 
            $skubuildURItrailer1 = ")&"
            $skubuildURItrailer2 = "$"
            $skubuildURItrailer3 = "select=displayName, id"
            $GroupnameSKUinfos =@()
            foreach ($skuitem in $skus)
            {
                [string]$SkuURIpassed = $SkubuildURIheader1 + $SkubuildURIheader2 + $SkubuildURIheader3+ $skuitem.skuId + $skubuildURItrailer1 + $skubuildURItrailer2 + $skubuildURItrailer3
                #$graphlicense = Invoke-MgGraphRequest -Uri 'https://graph.microsoft.com/v1.0/groups?$filter=assignedLicenses/any(s:s/skuId eq c42b9cae-ea4f-4ab7-9717-81576235ccac)&$select=displayName, id' -method GET
                $groupwithskureturned = Invoke-MgGraphRequest -Uri $SkuURIpassed -method GET
                        foreach ($iditem in $groupwithskureturned.value.'id') 
                        { 
                            $GroupnameSKUinfos += New-Object Object | 
                                        Add-Member -NotePropertyName GroupID -NotePropertyValue $iditem -PassThru  |
                                        Add-Member -NotePropertyName SkuId -NotePropertyValue $skuitem.skuid -PassThru |
                                        Add-Member -NotePropertyName SkuName -NotePropertyValue $skuitem.SkuPartNumber -PassThru 
    
                        }
            }
    
    
            #$groups = get-mggroup -all 
            $buildURIheader = "https://graph.microsoft.com/v1.0/groups/" 
            $q = "?s"
            $buildURItrailer =  "elect=assignedLicenses"
            $item = @()
            $sortedgroup = $skuinfos | Select-Object GroupID | sort-object groupobjectid | get-unique -asstring | Where-Object{$_.GroupID -eq $skuinfos.SkuName}
            $DISABLEDSkuobject =@()
            $sortedgroupinfo = $GroupnameSKUinfos | Sort-Object -Unique groupid
            foreach ($item in $sortedgroupinfo)
            {
                $builduripackage = $buildURIheader + $item.GroupID + $q+$buildURItrailer
                $assignedlicenses = invoke-mggraphrequest -uri $builduripackage -method GET
                foreach ($assignedlicenseitem in $assignedlicenses.assignedLicenses)
                {
                if($assignedlicenseitem.disabledPlans -ge 1)
                {
                    foreach ($disabledskuitem in $assignedlicenseitem.disabledPlans)
                    {
                        $DISABLEDSkuobject += New-Object Object |
                            Add-Member -NotePropertyName GroupID -NotePropertyValue $item.GroupID -PassThru |
                            Add-Member -NotePropertyName SKUId -NotePropertyValue $assignedlicenseitem.skuid -PassThru |
                            Add-Member -NotePropertyName DisabledServicePlanID -NotePropertyValue $disabledskuitem -PassThru
                    }
                }
                else {
                    $DISABLEDSkuobject += New-Object Object |
                        Add-Member -NotePropertyName GroupID -NotePropertyValue $item.GroupID -PassThru |
                        Add-Member -NotePropertyName SKUId -NotePropertyValue $assignedlicenseitem.skuid -PassThru |
                        Add-Member -NotePropertyName DisabledServicePlanID -NotePropertyValue $disabledskuitem -PassThru
                }
                }
    
            }
            $FinalSkuobject =@()
            foreach ($founddisabledplanitem in $disABLEDSkuobject)
                {
                    $GDN = (get-mggroup -GroupId $founddisabledplanitem.groupid ).DisplayName
                    $sps = get-mgsubscribedSku | ?{$_.SkuId -eq $founddisabledplanitem.SKUId} 
                    $sppartnumber = ($sps).skupartnumber
                    $spserviceplan = $sps.ServicePlans | Select-Object ServicePlanId, serviceplanname | ?{$_.serviceplanid -eq $founddisabledplanitem.DisabledServicePlanID}
                    $FinalSkuobject += New-Object Object |
                        Add-Member -NotePropertyName GroupID -NotePropertyValue $founddisabledplanitem.GroupID -PassThru |
                        Add-Member -NotePropertyName GroupName -NotePropertyValue $GDN -PassThru |
                        Add-Member -NotePropertyName SKUId -NotePropertyValue $founddisabledplanitem.skuid -PassThru |
                        Add-Member -NotePropertyName SKUPartNumber -NotePropertyValue $sppartnumber -PassThru |
                        Add-Member -NotePropertyName DisabledServicePlanID -NotePropertyValue $founddisabledplanitem.DisabledServicePlanID -PassThru |
                        Add-Member -NotePropertyName DisabledServicePlanName -NotePropertyValue $spserviceplan.ServicePlanName -PassThru
    
                }
                <#
                $tdy = get-date -Format "MM-dd-yyyy hh.mm.ss"
                $file = $MainMenuQuestion +"_"+ $GroupTypeQuestion.toupper() +"_"
                $OutputFile = select-directory -filename $file -initialDirectory $env:HOMEDRIVE
                if ($OutputFile -eq "Cancel"){exit}
                $FinalSkuobject | export-csv -Path $OutputFile -NoTypeInformation -Force -Encoding UTF8
                #>
        }
        "Group ObjectID" 
        {
            $sps =get-mgsubscribedSku |  Select-Object skupartnumber , serviceplans
            $sps2 = $sps.serviceplans
            #get only groups with license assignments 
            #Graph call to get only groups with assigned licenses by calling only graph to get licenese in the tenant then checking which groups are assigned to those licenses
            $skus = Get-MgSubscribedSku
            $SKUinfos = @()
            $SkubuildURIheader1 = "https://graph.microsoft.com/v1.0/groups?$"
            $SkubuildURIheader2 = "filter=assignedLicenses/any(s:s/"
            $SkubuildURIheader3 ="skuId eq " 
            $skubuildURItrailer1 = ")&"
            $skubuildURItrailer2 = "$"
            $skubuildURItrailer3 = "select=displayName, id"
            $GroupnameSKUinfos =@()
            foreach ($skuitem in $skus)
            {
                [string]$SkuURIpassed = $SkubuildURIheader1 + $SkubuildURIheader2 + $SkubuildURIheader3+ $skuitem.skuId + $skubuildURItrailer1 + $skubuildURItrailer2 + $skubuildURItrailer3
                #$graphlicense = Invoke-MgGraphRequest -Uri 'https://graph.microsoft.com/v1.0/groups?$filter=assignedLicenses/any(s:s/skuId eq c42b9cae-ea4f-4ab7-9717-81576235ccac)&$select=displayName, id' -method GET
                $groupwithskureturned = Invoke-MgGraphRequest -Uri $SkuURIpassed -method GET
                        #foreach ($iditem in $groupwithskureturned.value.'id') 
                        foreach ($iditem in $groupwithskureturned.value) 
                        { 
                            $GroupnameSKUinfos += New-Object Object | 
                                        Add-Member -NotePropertyName GroupDisplayname -NotePropertyValue $iditem.displayname -PassThru  |
                                        Add-Member -NotePropertyName GroupID -NotePropertyValue $iditem.id -PassThru  |
                                        Add-Member -NotePropertyName SkuId -NotePropertyValue $skuitem.skuid -PassThru |
                                        Add-Member -NotePropertyName SkuName -NotePropertyValue $skuitem.SkuPartNumber -PassThru 
    
                        }
    
            }
    
            $buildURIheader = "https://graph.microsoft.com/v1.0/groups/" 
            $q = "?s"
            $buildURItrailer =  "elect=assignedLicenses"
            $item = @()
            $sortedgroup = $skuinfos | Select-Object GroupID | sort-object groupobjectid | get-unique -asstring | Where-Object{$_.GroupID -eq $skuinfos.SkuName}
            $DISABLEDSkuobject =@()
    
            $sortedgroupinfo = $GroupnameSKUinfos | Sort-Object -Unique groupid
    
            $groupnamelookup = Get-MgGroup -GroupId $GroupObjectID
    
            $findgroup =@()
            $findgroup2 =@()
            foreach ($selectedlicensegroup in $sortedgroupinfo)
            {
    
                $findgroup = $sortedgroupinfo | Where-Object {$_.GroupDisplayname -match $groupnamelookup.DisplayName}
                $findgroup2 += $findgroup
    
            }
    
            foreach ($item in $findgroup2)
            {
                $builduripackage = $buildURIheader + $item.GroupID + $q+$buildURItrailer
                $assignedlicenses = invoke-mggraphrequest -uri $builduripackage -method GET
                foreach ($assignedlicenseitem in $assignedlicenses.assignedLicenses)
                {
                if($assignedlicenseitem.disabledPlans -ge 1)
                {
                    foreach ($disabledskuitem in $assignedlicenseitem.disabledPlans)
                    {
                        $DISABLEDSkuobject += New-Object Object |
                            Add-Member -NotePropertyName GroupID -NotePropertyValue $item.GroupID -PassThru |
                            Add-Member -NotePropertyName SKUId -NotePropertyValue $assignedlicenseitem.skuid -PassThru |
                            Add-Member -NotePropertyName DisabledServicePlanID -NotePropertyValue $disabledskuitem -PassThru
                    }
                }
                else {
                    $DISABLEDSkuobject += New-Object Object |
                        Add-Member -NotePropertyName GroupID -NotePropertyValue $item.GroupID -PassThru |
                        Add-Member -NotePropertyName SKUId -NotePropertyValue $assignedlicenseitem.skuid -PassThru |
                        Add-Member -NotePropertyName DisabledServicePlanID -NotePropertyValue $disabledskuitem -PassThru
                }
                }
    
            }
            $FinalSkuobject =@()
            foreach ($founddisabledplanitem in $disABLEDSkuobject)
                {
                    $GDN = (get-mggroup -GroupId $founddisabledplanitem.groupid ).DisplayName
                    $sps = get-mgsubscribedSku | ?{$_.SkuId -eq $founddisabledplanitem.SKUId} 
                    $sppartnumber = ($sps).skupartnumber
                    $spserviceplan = $sps.ServicePlans | Select-Object ServicePlanId, serviceplanname | ?{$_.serviceplanid -eq $founddisabledplanitem.DisabledServicePlanID}
                    $FinalSkuobject += New-Object Object |
                        Add-Member -NotePropertyName GroupID -NotePropertyValue $founddisabledplanitem.GroupID -PassThru |
                        Add-Member -NotePropertyName GroupName -NotePropertyValue $GDN -PassThru |
                        Add-Member -NotePropertyName SKUId -NotePropertyValue $founddisabledplanitem.skuid -PassThru |
                        Add-Member -NotePropertyName SKUPartNumber -NotePropertyValue $sppartnumber -PassThru |
                        Add-Member -NotePropertyName DisabledServicePlanID -NotePropertyValue $founddisabledplanitem.DisabledServicePlanID -PassThru |
                        Add-Member -NotePropertyName DisabledServicePlanName -NotePropertyValue $spserviceplan.ServicePlanName -PassThru
    
                }
    
        }
    }
                
    
    $tdy = get-date -Format "MM-dd-yyyy_HH.mm.ss"
    $sortedfinal = @()
    $sortedfinal = $FinalSkuobject | Sort-Object DisabledServicePlanName -Unique
    if($ExportFileType -eq "CSV")
    {
    $outputfile = $Outputdirectory + "GroupLicenseAssignments_"+$tdy+".csv"
    $sortedfinal | sort-object GroupName,SKUPartNumber| export-csv -Path $outputfile -NoTypeInformation -Encoding UTF8
    }
    else
    {
$htmlfile = $Outputdirectory + "GroupLicenseAssignments_"+$tdy+".html"

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

$htmlContent = $sortedfinal | Sort-object GroupName,SKUPartNumber | ConvertTo-Html -Title "Group License Assignments" -As "Table"
$htmlContent = $htmlContent -replace "</head>", "$cssStyle`n</head>"
$htmlContent | Out-File $htmlfile
}
    
}
function export-EntraGroupApplicationAssignments
{

    param([parameter(Position=0,mandatory)][validateset("All","Group ObjectID")] [string]$GroupOption="All",
    [parameter(Position=1,mandatory=$false)][string]$GroupObjectID,
    [parameter (Position=2,mandatory)][validateset("HTML", "CSV")] [string]$ExportFileType,
    [parameter(Position=3,mandatory)] [string]$Outputdirectory)
    
    try
        {
        Get-MGDomain -ErrorAction Stop > $null
        }
    catch
        {
        Connect-MgGraph -Scopes "group.read.all, directory.read.all, groupmember.read.all, Policy.Read.All, Application.Read.All"
        }
    
    
        if($GroupOption -eq "All")
        {
            $MGGROUP = get-mggroup -all  | Sort-Object DisplayName
        }
        else 
        {
            $MGGROUP = get-mggroup -GroupId $GroupObjectID 
        }
    
        $apgroup        = @()
        $Gapps          = @()
        foreach ($apgroup in $MGGROUP) 
            { 
                $applist = get-mggroupappRoleAssignment -groupid $apgroup.id |Where-Object{$_.PrincipalId -ne $null}
                foreach ($applistitem in $applist)
                {
                    $Gapps += New-Object Object |
                    Add-Member -NotePropertyName Group_DisplayName -NotePropertyValue $apgroup.DisplayName -PassThru |
                    Add-Member -NotePropertyName Group_ID -NotePropertyValue $apgroup.id -PassThru |
                    Add-Member -NotePropertyName Id -NotePropertyValue $applistitem.Id -PassThru |
                    Add-Member -NotePropertyName AppRoleId -NotePropertyValue $applistitem.AppRoleId -PassThru |
                    Add-Member -NotePropertyName PrincipalDisplayName -NotePropertyValue $applistitem.PrincipalDisplayName -PassThru |
                    Add-Member -NotePropertyName PrincipalId -NotePropertyValue $applistitem.PrincipalId -PassThru |
                    Add-Member -NotePropertyName PrincipalType -NotePropertyValue $applistitem.PrincipalType -PassThru |
                    Add-Member -NotePropertyName ResourceDisplayName -NotePropertyValue $applistitem.ResourceDisplayName -PassThru |
                    Add-Member -NotePropertyName ResourceId -NotePropertyValue $applistitem.ResourceId -PassThru    
                }
            }
    
    
    $tdy = get-date -Format "MM-dd-yyyy_HH.mm.ss"
    if($ExportFileType -eq "CSV")
    {
        $outputfile = $Outputdirectory + "GroupApplicationAssignments_"+$tdy+".csv"
        $Gapps | sort-object Group_DisplayName ,PrincipalDisplayName| export-csv -Path $outputfile -NoTypeInformation -Encoding UTF8
    }
    else
    {
$htmlfile = $Outputdirectory + "GroupApplicationAssignments_"+$tdy+".html"

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

$htmlContent = $Gapps | Sort-object Group_DisplayName ,PrincipalDisplayName | ConvertTo-Html -Title "Group License Assignments" -As "Table"
$htmlContent = $htmlContent -replace "</head>", "$cssStyle`n</head>"
$htmlContent | Out-File $htmlfile
}
    
}

function export-EntraGroupPolicyExpiration
{

    param([parameter(mandatory=$false)][string] $tenantID,
    [parameter (mandatory)][validateset("All", "GroupOID")] [string]$groupquestion,
    [parameter(mandatory=$false)][string]$GroupObjectId,
    [parameter (mandatory)][int]$DaysBack,
    [parameter (Position=2,mandatory)][validateset("HTML", "CSV")] [string]$ExportFileType,
    [parameter(mandatory)] [string]$Outputdirectory)

import-Module Microsoft.Graph.Beta.Groups


if(!$tenantID)
{
    try
        {
        Get-MGDomain -ErrorAction Stop > $null
        }
    catch
        {
            connect-mggraph -scopes "Directory.Read.All, Group.read.all" 
        }
}
else
 {
    try
        {
        Get-MGDomain -ErrorAction Stop > $null
        }
    catch
        {
            connect-mggraph -scopes "Directory.Read.All, Group.read.all" -TenantId $tenantID
        }
 }

#getting todays date
$date = Get-Date
if ($groupquestion -eq "GroupOID")
{
    $groupexpiration = get-mggroup -id $GroupObjectId | Select-Object -Property displayname, Mail,id, CreatedDateTime, ExpirationDateTime, RenewedDateTime, DeletedDateTime, grouptypes 
}
else 
{
$groupexpiration = get-mggroup -all | Select-Object -Property displayname, Mail,id, CreatedDateTime, ExpirationDateTime, RenewedDateTime, DeletedDateTime, grouptypes |Sort-Object -Descending -Property ExpirationDateTime |Where-Object{$_.grouptypes -contains "Unified" -and $_.expirationDateTime -ne $null}
}
$GLA = (get-MgGroupLifecyclePolicy).grouplifetimeindays+5

$GroupExpirationProperties =@()

foreach($item in $groupexpiration)
   {
        $daysleft = (new-timespan -end $item.expirationDateTime -start $date).days
        $LastActivity = (new-timespan -start $item.RenewedDateTime -end $date).days
	[string]$GroupTypesString = $item.grouptypes
        if ($null -ne $item.DeletedDateTime){write-host "Deleted on "$item.DeletedDateTime}
        else
        {
		if($daysleft -le $DaysBack) #checking if the groups expirationDatetime is -le 1
            {
                write-host "groupID is LE 1 day" $item.id " : " $item.displayname " : " $item.expirationDateTime " : "$daysleft
                $GroupExpirationProperties += New-Object Object |
                    Add-Member -NotePropertyName DaysLeft           -NotePropertyValue $daysleft                -PassThru |
                    Add-Member -NotePropertyName GroupDisplayName   -NotePropertyValue $item.DisplayName        -PassThru |
                    Add-Member -NotePropertyName Mail               -NotePropertyValue $item.Mail               -PassThru |
                    Add-Member -NotePropertyName GroupID            -NotePropertyValue $item.Id                 -PassThru |
                    Add-Member -NotePropertyName LastActivity       -NotePropertyValue $LastActivity            -PassThru |
                    Add-Member -NotePropertyName ExpirationDateTime -NotePropertyValue $item.ExpirationDateTime -PassThru |
                    Add-Member -NotePropertyName RenewedDateTime    -NotePropertyValue $item.RenewedDateTime    -PassThru |
                    Add-Member -NotePropertyName CreatedDateTime    -NotePropertyValue $item.CreatedDateTime    -PassThru |
                    Add-Member -NotePropertyName DeletedDateTime    -NotePropertyValue $item.DeletedDateTime    -PassThru |
                    Add-Member -NotePropertyName GroupTypes         -NotePropertyValue $GroupTypesString         -PassThru 
                $01daysleft = $true
            }		

	}
}

$file = "GroupPolicyExpirationExport_"
$tdy = get-date -Format "MM-dd-yyyy_HH.mm.ss"
if($ExportFileType -eq "CSV")
{
    $outputfile = $Outputdirectory + $file+$tdy+".csv"
    $GroupExpirationProperties | sort-object expirationDateTime, GroupDisplayname  -Descending| export-csv -Path $outputfile -NoTypeInformation -Encoding UTF8
}
else
{
$htmlfile = $Outputdirectory + $file+$tdy+".html"

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
background-color:rgb(250, 151, 22);
color: white;
}
</style>
"@

$htmlContent = $GroupExpirationProperties | Sort-object expirationdateTime,GroupDisplayName | ConvertTo-Html -Title "Group Policy Expiration Export" -As "Table"
$htmlContent = $htmlContent -replace "</head>", "$cssStyle`n</head>"
$htmlContent | Out-File $htmlfile
}
        

}


<#
function export-EntraGroupDynamicRuleUserValidator
{
    
}
#>

function export-EntraGroupMemberCount
{

    param([parameter(mandatory=$false)][string] $tenantID,
    [parameter (mandatory)][validateset("All", "GroupOID")] [string]$groupquestion,
    [parameter(mandatory=$false)][string]$GroupNameorObjectId,
    [parameter (Position=2,mandatory)][validateset("HTML", "CSV")] [string]$ExportFileType,
    [parameter(mandatory)] [string]$Outputdirectory)

import-Module Microsoft.Graph.Beta.Groups


if(!$tenantID)
{
    try
        {
        Get-MGDomain -ErrorAction Stop > $null
        }
    catch
        {
            connect-mggraph -scopes "Directory.Read.All, Group.read.all" 
        }
}
else
 {
    try
        {
        Get-MGDomain -ErrorAction Stop > $null
        }
    catch
        {
            connect-mggraph -scopes "Directory.Read.All, Group.read.all" -TenantId $tenantID
        }
 }

 $date = Get-Date
 if ($groupquestion -eq "GroupOID")
 {
     $groups = get-mggroup -id $GroupObjectId | Select-Object -Property displayname, Mail,id, CreatedDateTime, ExpirationDateTime, RenewedDateTime, DeletedDateTime, grouptypes 
 }
 else 
 {
    $groups = get-mggroup -all 
 }

 $counts = @()
 foreach ($item in $groups) 
 {
    $groupcount = (get-mggroupmember -GroupId $item.id).count
    write-host $item.id " group oid " $item.displayname " this group has : " ($groupcount).count " members"
    $counts += New-Object Object |
        Add-Member -NotePropertyName Group_DisplayName -NotePropertyValue $item.DisplayName -PassThru |
        Add-Member -NotePropertyName Group_id -NotePropertyValue $item.id -PassThru |
        Add-Member -NotePropertyName GroupMemberCount -NotePropertyValue $groupcount -PassThru
}


$file = "GroupMemberCountExport_"
$tdy = get-date -Format "MM-dd-yyyy_HH.mm.ss"
if($ExportFileType -eq "CSV")
{
    $outputfile = $Outputdirectory + $file+$tdy+".csv"
    $GroupExpirationProperties | sort-object Group_DisplayName | export-csv -Path $outputfile -NoTypeInformation -Encoding UTF8
}
else
{
$htmlfile = $Outputdirectory + $file+$tdy+".html"

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
background-color:rgba(7, 19, 255, 0.89);
color: white;
}
</style>
"@

$htmlContent = $counts | Sort-object Group_DisplayName | ConvertTo-Html -Title "Group Member Count Export" -As "Table"
$htmlContent = $htmlContent -replace "</head>", "$cssStyle`n</head>"
$htmlContent | Out-File $htmlfile
}


}

Export-ModuleMember -Function export-EntraGroupAttributes
Export-ModuleMember -Function export-EntraGroupMembers 
Export-ModuleMember -Function export-EntraGroupCAPolicyAssignments
Export-ModuleMember -Function export-EntraGroupLicenseAssignments
Export-ModuleMember -Function export-EntraGroupApplicationAssignments
Export-ModuleMember -Function export-EntraGroupPolicyExpiration
Export-ModuleMember -Function export-EntraGroupMemberCount
