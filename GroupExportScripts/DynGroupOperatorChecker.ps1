<# Written by Derrick Baxter 
the below Powershell module to find and export dynamic groups with operators that could affect processing performance
4/20/2026 based on documentation for dynamic group performance
https://learn.microsoft.com/en-us/entra/identity/users/groups-dynamic-rule-more-efficient
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

# Optional: Export to CSV
$tdy = get-date -Format "MM-dd-yyyy_hh.mm.ss"
 $outputfile = $Outputdirectory+"_"+$GroupOption+"_DynamicGroup_contains_match_memberof_"+$ExportFileType+"_"+$tdy+".csv"
 $filtered | Export-Csv -Path $outputfile -NoTypeInformation