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

function Get-DynRuleAnalysis {
    param([Parameter(Mandatory)][string]$Rule)

    # Normalize spacing (keeps original rule intact for output)
    $r = $Rule

    # Basic operator presence (per guidance to reduce Match/Contains/memberOf) [2](https://learn.microsoft.com/en-us/entra/identity/users/groups-dynamic-rule-more-efficient)[3](https://learn.microsoft.com/en-us/entra/identity/users/manage-dynamic-group)
    $hasContains = [regex]::IsMatch($r, '(?i)\s-contains\s')
    $hasMatch    = [regex]::IsMatch($r, '(?i)\s-(not)?match\s')   # match or notmatch
    $hasMemberOf = [regex]::IsMatch($r, '(?i)\s-memberof\s')

    # Count AND/OR occurrences (what you asked for)
    $andCount = ([regex]::Matches($r, '(?i)\s-and\s')).Count
    $orCount  = ([regex]::Matches($r, '(?i)\s-or\s')).Count

    # Extract simple comparisons: (user.prop|device.prop)  OP  "value" or 'value'
    # NOTE: This is "best effort" parsing; dynamic rules can be more complex.
    $cmpRegex = '(?i)(?<prop>(user|device)\.[a-z0-9_.]+)\s*(?<op>-eq|-ne|-contains|-match|-notmatch|-startswith|-endswith)\s*(?<val>"[^"]*"|''[^'']*'')'
    $cmps = [regex]::Matches($r, $cmpRegex) | ForEach-Object {
        [pscustomobject]@{
            Prop = $_.Groups['prop'].Value
            Op   = $_.Groups['op'].Value.ToLower()
            Val  = $_.Groups['val'].Value.Trim('"').Trim("'")
        }
    }

    # Heuristic 1: OR chain of same property with -eq => candidate for -in [2](https://learn.microsoft.com/en-us/entra/identity/users/groups-dynamic-rule-more-efficient)
    $inCandidates = $cmps |
        Where-Object { $_.Op -eq '-eq' } |
        Group-Object Prop |
        Where-Object { $_.Count -ge 3 -and $orCount -ge 2 }

    $inSuggestions = foreach ($g in $inCandidates) {
        $vals = ($g.Group.Val | Sort-Object -Unique)
        # Keep list short in the suggestion output; too long risks 3072 char limit [4](https://learn.microsoft.com/en-us/entra/identity/users/groups-dynamic-membership)
        $preview = ($vals | Select-Object -First 15)
        $suffix  = if ($vals.Count -gt 15) { " ... (+$($vals.Count-15) more)" } else { "" }
        "$($g.Name) -in [""$($preview -join '","')""$suffix]"
    }

    # Heuristic 2: AND chain of same property with -ne => candidate for -notin [2](https://learn.microsoft.com/en-us/entra/identity/users/groups-dynamic-rule-more-efficient)
    $notInCandidates = $cmps |
        Where-Object { $_.Op -eq '-ne' } |
        Group-Object Prop |
        Where-Object { $_.Count -ge 3 -and $andCount -ge 2 }

    $notInSuggestions = foreach ($g in $notInCandidates) {
        $vals = ($g.Group.Val | Sort-Object -Unique)
        $preview = ($vals | Select-Object -First 15)
        $suffix  = if ($vals.Count -gt 15) { " ... (+$($vals.Count-15) more)" } else { "" }
        "$($g.Name) -notin [""$($preview -join '","')""$suffix]"
    }

    # Heuristic 3: Redundant criteria detection (simple)
    # Example from guidance: avoid overlapping conditions [2](https://learn.microsoft.com/en-us/entra/identity/users/groups-dynamic-rule-more-efficient)
    $redundantNotes = @()
    $byProp = $cmps | Group-Object Prop
    foreach ($p in $byProp) {
        $eqVals = $p.Group | Where-Object Op -eq '-eq' | Select-Object -ExpandProperty Val -Unique
        $swVals = $p.Group | Where-Object Op -eq '-startswith' | Select-Object -ExpandProperty Val -Unique
        foreach ($eq in $eqVals) {
            foreach ($sw in $swVals) {
                if ($eq.StartsWith($sw)) {
                    $redundantNotes += "Potential redundancy on $($p.Name): -eq '$eq' overlaps -startswith '$sw'"
                }
            }
        }
    }

    # Build recommendations aligned to Learn doc [2](https://learn.microsoft.com/en-us/entra/identity/users/groups-dynamic-rule-more-efficient)[3](https://learn.microsoft.com/en-us/entra/identity/users/manage-dynamic-group)
    $recs = New-Object System.Collections.Generic.List[string]
    if ($hasMatch)    { $recs.Add("Reduce -match/-notmatch where possible; prefer -eq or -startswith.") }
    if ($hasContains) { $recs.Add("Reduce -contains where possible; it can increase processing time.") }
    if ($orCount -ge 5) { $recs.Add("High -or count ($orCount). Consider consolidating same-property comparisons using -in.") }
    if ($andCount -ge 5) { $recs.Add("High -and count ($andCount). Consider simplifying or removing redundant criteria.") }
    if ($hasMemberOf) { $recs.Add("memberOf can add complexity and slow processing; review if it can be avoided.") }

    foreach ($s in $inSuggestions)     { $recs.Add("Candidate rewrite: $s") }
    foreach ($s in $notInSuggestions)  { $recs.Add("Candidate rewrite: $s") }
    foreach ($n in $redundantNotes)    { $recs.Add($n) }

    # Always include a “review” recommendation when anything is flagged (what you requested)
    if ($recs.Count -gt 0) {
        $recs.Add("Recommendation: review this rule for simplification per Microsoft guidance (Match/Contains/OR chains).")
    }

    [pscustomobject]@{
        HasContains = $hasContains
        HasMatch    = $hasMatch
        HasMemberOf = $hasMemberOf
        AndCount    = $andCount
        OrCount     = $orCount
        InSuggestions    = ($inSuggestions -join ' | ')
        NotInSuggestions = ($notInSuggestions -join ' | ')
        Recommendations  = ($recs -join ' ; ')
    }
}


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
# Build results with analysis + recommendations
$results = foreach ($g in $dynamicGroups) {
    $a = Get-DynRuleAnalysis -Rule $g.MembershipRule

    [pscustomobject]@{
        DisplayName   = $g.DisplayName
        Id            = $g.Id
        MembershipRule = $g.MembershipRule

        HasContains   = $a.HasContains
        HasMatch      = $a.HasMatch
        HasMemberOf   = $a.HasMemberOf
        AndCount      = $a.AndCount
        OrCount       = $a.OrCount

        InSuggestions    = $a.InSuggestions
        NotInSuggestions = $a.NotInSuggestions
        Recommendations  = $a.Recommendations
    }
}

# Filter based on your existing GroupOption choices
$filtered = switch ($GroupOption.ToLower()) {
    'contains' { $results | Where-Object { $_.HasContains } }
    'match'    { $results | Where-Object { $_.HasMatch } }
    'memberof' { $results | Where-Object { $_.HasMemberOf } }
    default    { $results }  # "All" and "SingleGroupLookup"
}

#$filtered | Sort-Object OrCount, AndCount, DisplayName | Format-Table -AutoSize -Wrap


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

$tdy = Get-Date -Format "MM-dd-yyyy_hh.mm.ss"
$fullfileoutput = Join-Path $Outputdirectory ("{0}_DynGroupOperatorChecker_{1}.{2}" -f $GroupOption,$tdy,$ExportFileType)

if ($ExportFileType -eq 'HTML') {
    $head = @"
<style>
body { font-family: Segoe UI, Arial; }
table { border-collapse: collapse; width: 100%; }
th, td { border: 1px solid #ddd; padding: 6px; vertical-align: top; }
th { background: #f2f2f2; }
</style>
"@
    $filtered |
        ConvertTo-Html -Head $head -Title "DynGroupOperatorChecker - $GroupOption" |
        Out-File -FilePath $fullfileoutput -Encoding UTF8
    Write-Host "HTML export complete: $fullfileoutput" -ForegroundColor Green
}
else {
    $filtered | Export-Csv -Path $fullfileoutput -NoTypeInformation
    Write-Host "CSV export complete: $fullfileoutput" -ForegroundColor Green
}


