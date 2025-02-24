<# Written by Derrick Baxter debaxter@microsoft.com
the below script uses the Azure Graph powershell module to retrieve Groups assigned to applications
(THESE SAVE PII, make sure you save them based on your Country/State/Local Laws)
 2/21/25
 Derrick J. Baxter

 Group Assigned to Applications

 .\GroupAppAssignments.ps1 -GroupOption 'Group ObjectID' -GroupObjectID "group objectid guid" -ExportFileType HTML -Outputdirectory C:\temp\GroupExportScripts\
  .\GroupAppAssignments.ps1 -GroupOption 'Group ObjectID' -GroupObjectID "group objectid guid" -ExportFileType CSV -Outputdirectory C:\temp\GroupExportScripts\

.\GroupLicenseAssignments.ps1 -GroupOption All  -Outputdirectory C:\temp\GroupExportScripts\ -ExportFileType HTML
.\GroupLicenseAssignments.ps1 -GroupOption All  -Outputdirectory C:\temp\GroupExportScripts\ -ExportFileType csv

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
$scope4 ="Application.Read.All"

$today = Get-Date -Format "yyyy-MM-dd"
$expiredate1 = get-date
$expiredate2 = $expiredate1.AddDays(365).ToString("yyyy-MM-dd")
$params = @{
    ClientId = $SP.Id
    ConsentType = "Principal"
    ResourceId = $resource.id
    principalId = $principalid
    Scope = "$scope1" + " " + "$scope2"+ " " + "$scope3"+ " " + "$scope4"
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
    Connect-MgGraph -Scopes "group.read.all, directory.read.all, groupmember.read.all, Application.Read.All"
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


$tdy = get-date -Format "MM-dd-yyyy_hh.mm.ss"
if($ExportFileType -eq "CSV")
{
    $outputfile = $Outputdirectory + "GroupAssignedApplications_"+$tdy+".csv"
    $Gapps | sort-object Group_DisplayName ,PrincipalDisplayName| export-csv -Path $outputfile -NoTypeInformation -Encoding UTF8
}
else
{
$htmlfile = $Outputdirectory + "GroupAssignedApplications_"+$tdy+".html"

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

$htmlContent = $Gapps | Sort-object Group_DisplayName ,PrincipalDisplayName | ConvertTo-Html -Title "Last Signin Activity by DisplayName" -As "Table"
$htmlContent = $htmlContent -replace "</head>", "$cssStyle`n</head>"
$htmlContent | Out-File $htmlfile
}
        