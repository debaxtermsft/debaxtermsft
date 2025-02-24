<# Written by Derrick Baxter debaxter@microsoft.com
the below script uses the Azure Graph powershell module to retrieve Groups assigned licenses
(THESE SAVE PII, make sure you save them based on your Country/State/Local Laws)
 2/21/25
 Derrick J. Baxter
.\grouplicenseAssignments.ps1 -GroupOption All  -Outputdirectory C:\temp\GroupExportScripts\ -ExportFileType HTML
.\grouplicenseAssignments.ps1 -GroupOption All  -Outputdirectory C:\temp\GroupExportScripts\ -ExportFileType CSV



 Group Licenses - 
 Export Conditional Access Policies with included/excluded groups
Using Powershell microsoft.graph

.\grouplicenseAssignments.ps1 -GroupOption all -ExportFileType CSV -Outputdirectory  C:\temp\GroupExportScripts\
.\grouplicenseAssignments.ps1 -GroupOption all -ExportFileType HTML -Outputdirectory  C:\temp\GroupExportScripts\

.\grouplicenseAssignments.ps1 -GroupOption 'Group ObjectID' -GroupObjectID e156d297-c42a-44ca-a4cb-fc68eb3f40ad -ExportFileType CSV -Outputdirectory  C:\temp\GroupExportScripts\
.\grouplicenseAssignments.ps1 -GroupOption 'Group ObjectID' -GroupObjectID e156d297-c42a-44ca-a4cb-fc68eb3f40ad -ExportFileType HTML -Outputdirectory  C:\temp\GroupExportScripts\
IMPORTANT!!!

To consent for users to run this script a global admin will need to run the following
-------------------------------------------------------------------------------------------
$sp = get-mgserviceprincipal -all| ?{$_.displayname -eq "Microsoft Graph"}
$resource = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"
$principalid = "users object id"
$scope1 ="group.read.all"
$scope2 ="directory.read.all"
$scope3 ="user.read.all"
$scope4 = "LicenseAssignment.Read.All"


$today = Get-Date -Format "yyyy-MM-dd"
$expiredate1 = get-date
$expiredate2 = $expiredate1.AddDays(365).ToString("yyyy-MM-dd")
$params = @{
    ClientId = $SP.Id
    ConsentType = "Principal"
    ResourceId = $resource.id
    principalId = $principalid
    Scope = "$scope1" + " " + "$scope2"+ " " + "$scope3" + "$scope4"
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

If($GroupOption -eq "All")
    {
        $file = "GroupAssignedLicenseExport_" + $groupoption + "_" 
    }
else 
    {
        $file = "GroupAssignedLicenseExport_" + $groupoption + "_" + $GroupObjectID + "_" 
    }

try
    {
    Get-MGDomain -ErrorAction Stop > $null
    }
catch
    {
    Connect-MgGraph -Scopes "group.read.all, directory.read.all,LicenseAssignment.Read.All, User.Read.All"
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
            

$tdy = get-date -Format "MM-dd-yyyy_hh.mm.ss"
$sortedfinal = @()
$sortedfinal = $FinalSkuobject | Sort-Object DisabledServicePlanName -Unique
if($ExportFileType -eq "CSV")
{
$outputfile = $Outputdirectory + $file +$tdy+".csv"
$sortedfinal | sort-object GroupName,SKUPartNumber| export-csv -Path $outputfile -NoTypeInformation -Encoding UTF8
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
    background-color:rgb(232, 235, 49);
    color: white;
}
</style>
"@

$htmlContent = $sortedfinal | Sort-object GroupName,SKUPartNumber | ConvertTo-Html -Title "Group License Assignements" -As "Table"
$htmlContent = $htmlContent -replace "</head>", "$cssStyle`n</head>"
$htmlContent | Out-File $htmlfile
}
