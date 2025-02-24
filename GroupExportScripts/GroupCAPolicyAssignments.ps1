<# Written by Derrick Baxter debaxter@microsoft.com
 the below script uses the Azure Graph powershell module to retrieve Groups assigned to Conditional Access Policies
(THESE SAVE PII, make sure you save them based on your Country/State/Local Laws)
 2/21/25
 Derrick J. Baxter

.\groupcAPolicyAssignments.ps1 -GroupOption All -ExportFileType html -Outputdirectory c:\temp\groupexportscripts\
.\groupcAPolicyAssignments.ps1 -GroupOption All -ExportFileType CSV -Outputdirectory c:\temp\groupexportscripts\

.\groupcAPolicyAssignments.ps1 -GroupOption 'Group ObjectID' -ExportFileType html -Outputdirectory c:\temp\groupexportscripts\ -GroupObjectID <group objectid>
.\groupcAPolicyAssignments.ps1 -GroupOption 'Group ObjectID' -ExportFileType CSV -Outputdirectory c:\temp\groupexportscripts\ -GroupObjectID <group objectid>

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
$scope ="Policy.Read.ConditionalAccess"


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
        [parameter (Position=2,mandatory)][validateset("HTML", "CSV")] [string]$ExportFileType,
        [parameter(Position=3,mandatory)] [string]$Outputdirectory)


try
    {
    Get-MGDomain -ErrorAction Stop > $null
    }
catch
    {
    Connect-MgGraph -Scopes "group.read.all, directory.read.all, Policy.Read.All"
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
$tdy = get-date -Format "MM-dd-yyyy_hh.mm.ss"
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