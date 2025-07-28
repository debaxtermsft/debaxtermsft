<#
Written by Derrick Baxter
updated : 7/28/2025
If the policy is set to 180 days, If the policy is set today 7/15/2024 the expiration date will be 01/16/2025 based on the documentation with 5 days pause to avoid emails when the expiration policy is enabled for that group.
https://learn.microsoft.com/en-us/entra/identity/users/groups-lifecycle#activity-based-automatic-renewal 
“Now consider an expiration policy that was set so that a group expires after N days of inactivity. 
To keep from sending an expiration email the day that group expiration is enabled (because there's no record activity yet), Microsoft Entra first waits five days. Then:”
This gives admins/owners time to check/provide activity to groups if needed/wanted
All
automatically uses 30 days if -daysback is not used
.\groupexpirationexport.ps1 -groupquestion All -Outputdirectory ".\"  -exportfiletype HTML or CSV
look 1 day check - about to expire
.\groupexpirationexport.ps1 -groupquestion All -Outputdirectory ".\" -DaysBack 1 -exportfiletype HTML or CSV
look 15 check
.\groupexpirationexport.ps1 -groupquestion All -Outputdirectory ".\" -DaysBack 15 -exportfiletype HTML or CSV
30 day check
.\groupexpirationexport.ps1 -groupquestion All -Outputdirectory ".\" -DaysBack 30 -exportfiletype HTML or CSV

Check if Security Groups have been accidentally set
-tenantID "tenantid" -groupquestion All -CheckSecurityGroupExpiration Yes -DaysBack 180 -ExportFileType HTML -Outputdirectory c:\temp\

by Group ObjectID
-groupquestion GroupOID -Outputdirectory ".\" -GroupObjectId 50771417-3b12-4cab-a980-46720ea696e2 -DaysBack 30 -exportfiletype HTML or CSV
automatically uses 30 days if -daysback is not used
-groupquestion GroupOID -Outputdirectory ".\" -GroupObjectId 50771417-3b12-4cab-a980-46720ea696e2 -exportfiletype HTML or CSV


If a unified group is expired and not extended, it can be restored using the portal or powershell : 
https://learn.microsoft.com/en-us/entra/identity/users/groups-restore-deleted
#> 


param([parameter(mandatory=$false)][string] $tenantID,
    [parameter (mandatory)][validateset("All", "GroupOID")] [string]$groupquestion,
    [parameter(mandatory=$false)][validateset("GroupName", "ObjectID")][string]$GroupNameorObjectId,
    [parameter(mandatory=$false)][validateset("Yes", "No")][string]$CheckSecurityGroupExpiration="Yes",
    [parameter (mandatory)][int]$DaysBack,
    [parameter (Position=2,mandatory)][validateset("HTML", "CSV")] [string]$ExportFileType,
    [parameter(mandatory)] [string]$Outputdirectory)

#import-Module Microsoft.Graph.Beta.Groups


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
if($CheckSecurityGroupExpiration -eq "No"){
        $groupexpiration = get-mggroup -all | Select-Object -Property displayname, Mail,id, CreatedDateTime, ExpirationDateTime, RenewedDateTime, DeletedDateTime, grouptypes |Sort-Object -Descending -Property ExpirationDateTime |Where-Object{$_.grouptypes -contains "Unified" -and $_.expirationDateTime -ne $null}
    }
else {
    #modified due to issue with AAD security group having renewedDateTime and expirationDateTime incorrectly set and group expiration policy deleting security groups, this will return all groups w expirationDateTime set
        $groupexpiration = get-mggroup -all | Select-Object -Property displayname, Mail,id, CreatedDateTime, ExpirationDateTime, RenewedDateTime, DeletedDateTime, grouptypes |Sort-Object -Descending -Property ExpirationDateTime |Where-Object{$_.expirationDateTime -ne $null -and $_.grouptypes -notcontains "Unified"}
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
                    Add-Member -NotePropertyName DisplayName        -NotePropertyValue $item.DisplayName        -PassThru |
                    Add-Member -NotePropertyName Mail               -NotePropertyValue $item.Mail               -PassThru |
                    Add-Member -NotePropertyName ID                 -NotePropertyValue $item.Id                 -PassThru |
                    Add-Member -NotePropertyName CreatedDateTime    -NotePropertyValue $item.CreatedDateTime    -PassThru |
                    Add-Member -NotePropertyName ExpirationDateTime -NotePropertyValue $item.ExpirationDateTime -PassThru |
                    Add-Member -NotePropertyName RenewedDateTime    -NotePropertyValue $item.RenewedDateTime    -PassThru |
                    Add-Member -NotePropertyName LastActivity       -NotePropertyValue $LastActivity            -PassThru |
                    Add-Member -NotePropertyName DeletedDateTime    -NotePropertyValue $item.DeletedDateTime    -PassThru |
                    Add-Member -NotePropertyName GroupTypes         -NotePropertyValue $GroupTypesString         -PassThru 
                $01daysleft = $true
            }		

	}
}
$GroupExpirationProperties.count 


$file = "GroupExpirationExport"
$tdy = get-date -Format "MM-dd-yyyy_hh.mm.ss"
if($ExportFileType -eq "CSV")
{
    $outputfile = $Outputdirectory + $file+$tdy+".csv"
    $GroupExpirationProperties | sort-object expirationDateTime, Displayname  -Descending| export-csv -Path $outputfile -NoTypeInformation -Encoding UTF8
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
background-color: #4CAF50;
color: white;
}
</style>
"@

$htmlContent = $GroupExpirationProperties | Sort-object Group_DisplayName ,PrincipalDisplayName | ConvertTo-Html -Title "Group Application Assignments Export" -As "Table"
$htmlContent = $htmlContent -replace "</head>", "$cssStyle`n</head>"
$htmlContent | Out-File $htmlfile
}
        