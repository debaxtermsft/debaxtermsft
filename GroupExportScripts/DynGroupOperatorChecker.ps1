<# Written by Derrick Baxter 
the below Powershell module to find and export dynamic groups with operators that could affect processing performance
4/20/2026 based on documentation for dynamic group performance
https://learn.microsoft.com/en-us/entra/identity/users/groups-dynamic-rule-more-efficient

HTML Output
.\DynGroupOperatorChecker.ps1  -ExportFileType HTML -GroupOption Contains
.\DynGroupOperatorChecker.ps1  -ExportFileType HTML -GroupOption Match
.\DynGroupOperatorChecker.ps1  -ExportFileType HTML -GroupOption memberOf
.\DynGroupOperatorChecker.ps1  -ExportFileType HTML -GroupOption All
CSV output
.\DynGroupOperatorChecker.ps1  -ExportFileType CSV -GroupOption Contains
.\DynGroupOperatorChecker.ps1  -ExportFileType CSV -GroupOption Match
.\DynGroupOperatorChecker.ps1  -ExportFileType CSV -GroupOption memberOf
.\DynGroupOperatorChecker.ps1  -ExportFileType CSV -GroupOption All



#>


param([parameter(Position=0,mandatory)][validateset("All","SingleGroupLookup","Contains","Match","memberOf")] [string]$GroupOption="All",
        [parameter(Position=1,mandatory=$false)][string]$GroupObjectID,
        [parameter (Position=4,mandatory=$false)][validateset("HTML", "CSV")] [string]$ExportFileType="CSV",
        [parameter(Position=2,mandatory=$false)][string] $tenantID,
        [parameter(Position=3,mandatory=$false)] [string]$Outputdirectory="C:\temp\")


# Connect to Microsoft Graph (if not already connected)

try
    {
    Get-MGDomain -ErrorAction Stop > $null
    }
catch
    {
        if ($null -eq $tenantID) 
        {
            Connect-MgGraph -Scopes "group.read.all"
        }
        else
        {
            Connect-MgGraph -Scopes "group.read.all" -tenantID $tenantID
        }
    }

 if ($GroupOption -eq "SingleGroupLookup")
 {
    $dynamicGroups = Get-MgGroup -groupid $GroupObjectID | select id, displayname, membershipRule
 }
 else
{
    # Get all dynamic groups
    $dynamicGroups = Get-MgGroup `
    -Filter "groupTypes/any(gt:gt eq 'DynamicMembership')" `
    -All `
    -ConsistencyLevel eventual `
    -Property id,displayName,membershipRule

    # Filter for groups using -contains, -match, or both
    $targetGroups = $dynamicGroups | Where-Object {
    $rule = $_.membershipRule
    
    $hasContains = $rule -match '(?i)-contains' -or $rule -match '(?i)contains'
    $hasMatch    = $rule -match '(?i)-match' -or $rule -match '(?i)match'
    $hasMemberof = $rule -match '(?i)-memberOf' -or $rule -match '(?i)memberOf'
    
    # Return true if it has -contains OR -match OR both
    $hasContains -or $hasMatch -or $hasMemberof
    }
}
# Add helpful calculated properties
$results = $targetGroups | Select-Object `
   DisplayName,
   Id,
   @{
       Name = 'Contains_Type'
       Expression = {
           $rule = $_.membershipRule
           $hasContains = $rule -match '(?i)-contains' -or $rule -match '(?i)contains'
           $hasMatch    = $rule -match '(?i)-match'    -or $rule -match '(?i)match'
           $hasMemberof    = $rule -match '(?i)-memberOf'    -or $rule -match '(?i)memberOf'
           
           if ($hasContains -and $hasMatch) { "Both (-contains and -match)" }
           elseif($hasContains -and $hasMemberof) { "Both (-contains and -memberOf)" }
           elseif($hasMatch -and $hasMemberof) { "Both (-match and -memberOf)" }
           elseif ($hasContains)            { "-contains" }
           elseif ($hasMatch)               { "-match" }
           elseif ($hasMemberof)               { "-memberOf" }
           else                             { "None" }
       }
   },
   MembershipRule

# Display results

#$results | Sort-Object Contains_Type, DisplayName | Format-Table -AutoSize -Wrap 

$filtered = switch ($groupoption.ToLower()) {

    'all' {
        $results
        break
    }

    'match' {
        $results | Where-Object { $_.Contains_Type -match 'match' }
        break
    }

    'contains' {
        $results | Where-Object { $_.Contains_Type -match 'contains' }
        break
    }

    'memberof' {
        $results | Where-Object { $_.Contains_Type -match 'memberof' }
        break
    }

    default {
        # Support comma-separated combos like "match,memberof"
        $options = $groupoption -split ',' | ForEach-Object { $_.Trim().ToLower() }

        $results | Where-Object {
            $ct = $_.Contains_Type.ToLower()
            ($options | Where-Object { $ct -match $_ }).Count -gt 0
        }
    }
}

$filtered | Sort-Object Contains_Type, DisplayName | Format-Table -AutoSize -Wrap

$tdy = get-date -Format "MM-dd-yyyy_hh.mm.ss"
 $outputfile = $GroupOption+"_DynamicGroup_contains_match_memberof_"+$tdy+"."+$ExportFileType
 $fullfileoutput = $Outputdirectory+$GroupOption+"_DynamicGroup_contains_match_memberof_"+$tdy+"."+$ExportFileType

<#if ($ExportFileType -eq "CSV")
    {
        $filtered | Export-Csv -Path $outputfile -NoTypeInformation
        Write-Host "CSV export complete: $outputfile" -ForegroundColor Green
    }
else #>


if ($ExportFileType -eq 'HTML') {

    $filtered |
    Select-Object DisplayName, Id, Contains_Type, MembershipRule |

    ConvertTo-Html `
        -Title "Dynamic Group Operator Report" `
        -PreContent "<h2>Dynamic Group Operator Report - $GroupOption</h2>" `
        -PostContent "<p>Generated: $(Get-Date)</p>" `
        -Head @"
<style>
body { font-family: Segoe UI; font-size: 10pt; }
table { border-collapse: collapse; width: 100%; }
th { background-color: #0078D4; color: white; padding: 6px; text-align: left; }
td { border: 1px solid #ddd; padding: 5px; vertical-align: top; }
tr:nth-child(even) { background-color: #f2f2f2; }
</style>
"@ |

    Out-File -FilePath "$fullfileoutput" -Encoding utf8

    Write-Host "HTML export complete: $fullfileoutput" -ForegroundColor Green
}
else{
            $filtered | Export-Csv -Path "$fullfileoutput" -NoTypeInformation
        Write-Host "CSV export complete: $fullfileoutput" -ForegroundColor Green
}



