<# Written by Derrick Baxter debaxter@microsoft.com
the below script uses the Azure Graph powershell module to retrieve Groups Attributes (needed to recreate a security group or any group)
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
$sp = get-mgserviceprincipal -all| ?{$_.displayname -eq "Microsoft Graph"}
$resource = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"
$principalid = "users object id"
$scope1 ="group.read.all"
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
You may need to update the connect-mggraph to have the -environment USGov or as needed -tenantid <tenantid> can be added as needed.

#>

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
        

$tdy = get-date -Format "MM-dd-yyyy_hh.mm.ss"
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
    background-color: #4CAF50;
    color: white;
}
</style>
"@

$htmlContent = $GAs | Sort-object Group_DisplayName| ConvertTo-Html -Title "Group Attribute Export" -As "Table"
$htmlContent = $htmlContent -replace "</head>", "$cssStyle`n</head>"
$htmlContent | Out-File $htmlfile
}
        
