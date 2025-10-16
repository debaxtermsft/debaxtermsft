<#
Written by Derrick Baxter
10/09/2025

#>
param([parameter(mandatory=$false)][string] $tenantID,
    [parameter (mandatory)][int]$DaysBack,
    [parameter(mandatory)] [string]$Outputdirectory)


# Connect to Microsoft Graph

try
    {
        Get-MGDomain -ErrorAction Stop > $null
    }
catch
    {
        Connect-MgGraph -Scopes "AuditLog.Read.All" -TenantId $tenantID -NoWelcome
    }

# Base URI for audit logs
$baseUri   = "https://graph.microsoft.com/v1.0/auditLogs/directoryAudits"

# Define date range (last 30 days from today)
$startDate = (Get-Date).AddDays(-$DaysBack).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$endDate   = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

# Function to fetch all pages with throttling handling
function Get-AuditLogs {
    param (
        [string]$Uri
    )
    $allResults = @()
    $nextLink   = $Uri
    $retryDelay = 60  # Default delay in seconds

    do {
        try {
            $response    = Invoke-MgGraphRequest -Method GET -Uri $nextLink -ErrorAction Stop
            $allResults += $response.value
            $nextLink    = $response.'@odata.nextLink'
        }
        catch {
            if ($_.Exception.Response.StatusCode -eq 429) {
                Write-Host "429 Too Many Requests detected for $nextLink"
                $retryAfter = $_.Exception.Response.Headers["Retry-After"]
                $delay      = if ($retryAfter) { [int]$retryAfter } else { $retryDelay }
                Write-Host "Pausing for $delay seconds before retrying..."
                Start-Sleep -Seconds $delay
                continue
            }
            else {
                throw $_
            }
        }
    } while ($nextLink)

    return $allResults
}

# Fetch logs for GroupManagement, UserManagement, device and AdministrativeUnit
<#
$UserUri                  = "$baseUri`?`$filter=category eq 'UserManagement' and activityDateTime ge $startDate and activityDateTime le $endDate"
$UserAuditLogs            = Get-AuditLogs -Uri $UserUri
$dailyBreakdownUsers      = $UserAuditLogs | Group-Object { (Get-Date $_.activityDateTime).ToString("yyyy-MM-dd") } | Sort-Object Name

$GroupUri                 = "$baseUri`?`$filter=category eq 'GroupManagement' and activityDateTime ge $startDate and activityDateTime le $endDate"
$GroupAuditLogs           = Get-AuditLogs -Uri $GroupUri
$dailyBreakdownGroups     = $GroupAuditLogs | Group-Object { (Get-Date $_.activityDateTime).ToString("yyyy-MM-dd") } | Sort-Object Name

$DeviceUri                = "$baseUri`?`$filter=category eq 'Device' and activityDateTime ge $startDate and activityDateTime le $endDate"
$DeviceAuditLogs          = Get-AuditLogs -Uri $DeviceUri
$dailyBreakdownDevices    = $DeviceAuditLogs | Group-Object { (Get-Date $_.activityDateTime).ToString("yyyy-MM-dd") } | Sort-Object Name

$AdminUnitUri             = "$baseUri`?`$filter=category eq 'AdministrativeUnit' and activityDateTime ge $startDate and activityDateTime le $endDate"
$AdminUnitAuditLogs       = Get-AuditLogs -Uri $AdminUnitUri
$dailyBreakdownAdminUnits = $AdminUnitAuditLogs | Group-Object { (Get-Date $_.activityDateTime).ToString("yyyy-MM-dd") } | Sort-Object Name
#>
$AllUri = "$baseUri`?`$filter=category eq 'AdministrativeUnit' and activityDateTime ge $startDate and activityDateTime le $endDate"
$AllUri = "$baseUri`?`$filter=category eq 'AdministrativeUnit' or category eq 'GroupManagement' or category eq 'Usermanagement' or category eq 'Device' and activityDateTime ge $startDate and activityDateTime le $endDate"
$allAuditLogs = Get-AuditLogs -Uri $AllUri
$allDailyBreakdown = $allAuditLogs | Group-Object { (Get-Date $_.activityDateTime).ToString("yyyy-MM-dd") } | Sort-Object Name

# Initialize totals and arrays
$totalAddMember                       = 0
$totalRemoveMember                    = 0
$totalUpdateGroup                     = 0
$totalAddGroup                        = 0
$totalDeleteGroup                     = 0
$totalAddMemberAU                     = 0
$totalRemoveMemberAU                  = 0
$totalUpdateAU                        = 0
$totalChangeUserLicense               = 0
$totalAddUser                         = 0
$totalDeleteUser                      = 0
$totalUpdateUser                      = 0
$totalAddDevice                       = 0
$totalUpdateDevice                    = 0
$totalDeleteDevice                    = 0
$totalRemoveRegisteredOwnerfromDevice = 0
$totalAddRegisteredOwnertoDevice      = 0
$totalRemoveRegisteredusersfromDevice = 0
$totalAddRegistereduserstoDevice      = 0

#setting variable array
$AdminUnitProperties    = @()
$UserProperties         = @()
$GroupProperties        = @()
$DeviceProperties       = @()

# Process UserManagement
foreach ($day in $allDailyBreakdown) {
    $dayDate = $day.Name
    $dayLogs = $day.Group

    $UpdateUserCount        = ($dayLogs | Where-Object { $_.activityDisplayName -eq "Update user" -or $_.activityDisplayName -eq "Update device"}).Count
    $ChangeUserLicenseCount = ($dayLogs | Where-Object { $_.activityDisplayName -eq "Change user license" }).Count
    $AddUserCount           = ($dayLogs | Where-Object { $_.activityDisplayName -eq "Add user" -or $_.activityDisplayName -eq "Add device"}).Count
    $DeleteUserCount        = ($dayLogs | Where-Object { $_.activityDisplayName -eq "Delete user" -or $_.activityDisplayName -eq "Delete device" }).Count

    $totalUpdateUser        += $UpdateUserCount
    $totalAddUser           += $AddUserCount
    $totalDeleteUser        += $DeleteUserCount
    $totalChangeUserLicense += $ChangeUserLicenseCount

    
    $totalDailyUserActivity = $UpdateUserCount + $AddUserCount + $DeleteUserCount + $ChangeUserLicenseCount

    $UserProperties += New-Object PSObject |
        Add-Member -NotePropertyName "Date" -NotePropertyValue $((Get-Date $dayDate).ToString('MM/dd/yyyy')) -PassThru |
        Add-Member -NotePropertyName "Add user" -NotePropertyValue $AddUserCount -PassThru |
        Add-Member -NotePropertyName "Delete user" -NotePropertyValue $DeleteUserCount -PassThru |
        Add-Member -NotePropertyName "Update user" -NotePropertyValue $UpdateUserCount -PassThru |
        Add-Member -NotePropertyName "Change user license" -NotePropertyValue $ChangeUserLicenseCount -PassThru |
        Add-Member -NotePropertyName "Total Daily User Activity" -NotePropertyValue $totalDailyUserActivity -PassThru
}

# Process DeviceManagement
foreach ($day in $allDailyBreakdown) {
    $dayDate = $day.Name
    $dayLogs = $day.Group

    $UpdateDeviceCount             = ($dayLogs | Where-Object { $_.activityDisplayName -eq "Update device"}).Count
    $AddDeviceCount                = ($dayLogs | Where-Object { $_.activityDisplayName -eq "Add device" }).Count
    $DeleteDeviceCount             = ($dayLogs | Where-Object { $_.activityDisplayName -eq "Delete device" }).Count
    $AddRegDeviceOwnerCount        = ($dayLogs | Where-Object { $_.activityDisplayName -eq "Add registered owner to device" }).Count
    $RemoveRegownerfromDeviceCount = ($dayLogs | Where-Object { $_.activityDisplayName -eq "Remove registered owner from device" }).Count
    $AddRegUsers2DeviceCount       = ($dayLogs | Where-Object { $_.activityDisplayName -eq "Add registered users to device" }).Count
    $RemoveRegUsersfromDeviceCount = ($dayLogs | Where-Object { $_.activityDisplayName -eq "Remove registered users from device" }).Count

    $totalUpdateDevice                    += $UpdateDeviceCount
    $totalAddDevice                       += $AddDeviceCount
    $totalDeleteDevice                    += $DeleteDeviceCount
    $totalRemoveRegisteredOwnerfromDevice += $RemoveRegownerfromDeviceCount
    $totalAddRegisteredOwnertoDevice      += $AddRegUsers2DeviceCount
    $totalRemoveRegisteredusersfromDevice += $RemoveRegUsersfromDeviceCount
    $totalAddRegistereduserstoDevice      += $AddRegUsers2DeviceCount

    $totalDailyDeviceActivity = $UpdateDeviceCount + $AddDeviceCount + $DeleteDeviceCount + $AddRegDeviceOwnerCount + $RemoveRegownerfromDeviceCount + $AddRegUsers2DeviceCount + $RemoveRegUsersfromDeviceCount

    $deviceProperties += New-Object PSObject |
        Add-Member -NotePropertyName "Date" -NotePropertyValue $((Get-Date $dayDate).ToString('MM/dd/yyyy')) -PassThru |
        Add-Member -NotePropertyName "Add device" -NotePropertyValue $AddDeviceCount -PassThru |
        Add-Member -NotePropertyName "Delete device" -NotePropertyValue $DeleteDeviceCount -PassThru |
        Add-Member -NotePropertyName "Update device" -NotePropertyValue $UpdateDeviceCount -PassThru |
        Add-Member -NotePropertyName "ARO to device" -NotePropertyValue $AddRegDeviceOwnerCount -PassThru |
        Add-Member -NotePropertyName "RRO from device" -NotePropertyValue $RemoveRegownerfromDeviceCount -PassThru |
        Add-Member -NotePropertyName "ARU to device" -NotePropertyValue $AddRegUsers2DeviceCount -PassThru |
        Add-Member -NotePropertyName "RRU from device" -NotePropertyValue $RemoveRegUsersfromDeviceCount -PassThru |
        Add-Member -NotePropertyName "Total Daily Device Activity" -NotePropertyValue $totalDailyDeviceActivity -PassThru
}

# Process GroupManagement
foreach ($day in $allDailyBreakdown) {
    $dayDate = $day.Name
    $dayLogs = $day.Group

    $addMemberCount     = ($dayLogs | Where-Object { $_.activityDisplayName -eq "Add member to group" }).Count
    $removeMemberCount  = ($dayLogs | Where-Object { $_.activityDisplayName -eq "Remove member from group" }).Count
    $updateGroupCount   = ($dayLogs | Where-Object { $_.activityDisplayName -eq "Update group" }).Count
    $addGroupCount      = ($dayLogs | Where-Object { $_.activityDisplayName -eq "Add group" }).Count
    $deleteGroupCount   = ($dayLogs | Where-Object { $_.activityDisplayName -eq "Delete group" }).Count

    $totalAddMember     += $addMemberCount
    $totalRemoveMember  += $removeMemberCount
    $totalUpdateGroup   += $updateGroupCount
    $totalAddGroup      += $addGroupCount
    $totalDeleteGroup   += $deleteGroupCount

    $totalDailyGroupActivity = $addMemberCount + $removeMemberCount + $updateGroupCount + $addGroupCount + $deleteGroupCount

    $GroupProperties += New-Object PSObject |
        Add-Member -NotePropertyName "Date" -NotePropertyValue $((Get-Date $dayDate).ToString('MM/dd/yyyy')) -PassThru |
        Add-Member -NotePropertyName "Add member to group" -NotePropertyValue $addMemberCount -PassThru |
        Add-Member -NotePropertyName "Remove member from group" -NotePropertyValue $removeMemberCount -PassThru |
        Add-Member -NotePropertyName "Update group" -NotePropertyValue $updateGroupCount -PassThru |
        Add-Member -NotePropertyName "Add group" -NotePropertyValue $addGroupCount -PassThru |
        Add-Member -NotePropertyName "Delete group" -NotePropertyValue $deleteGroupCount -PassThru |
        Add-Member -NotePropertyName "Total Daily Group Activity" -NotePropertyValue $totalDailyGroupActivity -PassThru
}

# Process AdministrativeUnit
foreach ($day in $allDailyBreakdown) {
    $dayDate = $day.Name
    $dayLogs = $day.Group

    $AddMemberAUCount       = ($dayLogs | Where-Object { $_.activityDisplayName -eq "Add member to administrative unit" }).Count
    $RemoveMemberAUCount    = ($dayLogs | Where-Object { $_.activityDisplayName -eq "Remove member from administrative unit" }).Count
    $UpdateAUCount          = ($dayLogs | Where-Object { $_.activityDisplayName -eq "Update administrative unit" }).Count

    $totalAddMemberAU       += $AddMemberAUCount
    $totalRemoveMemberAU    += $RemoveMemberAUCount
    $totalUpdateAU          += $UpdateAUCount

    $totalDailyAUActivity   = $AddMemberAUCount + $RemoveMemberAUCount + $UpdateAUCount

    $AdminUnitProperties += New-Object PSObject |
        Add-Member -NotePropertyName "Date" -NotePropertyValue $((Get-Date $dayDate).ToString('MM/dd/yyyy')) -PassThru |
        Add-Member -NotePropertyName "Add member to administrative unit" -NotePropertyValue $AddMemberAUCount -PassThru |
        Add-Member -NotePropertyName "Remove member from administrative unit" -NotePropertyValue $RemoveMemberAUCount -PassThru |
        Add-Member -NotePropertyName "Update administrative unit" -NotePropertyValue $UpdateAUCount -PassThru |
        Add-Member -NotePropertyName "Total Daily Admin Unit Activity" -NotePropertyValue $totalDailyAUActivity -PassThru
}

# Calculate averages
$groupDays  = $GroupProperties.Count
$userDays   = $UserProperties.Count
$auDays     = $AdminUnitProperties.Count
$deviceDays = $DeviceProperties.Count

$avgAddMember         = if ($groupDays -gt 0) { [math]::Round($totalAddMember / $groupDays, 2) } else { 0 }
$avgRemoveMember      = if ($groupDays -gt 0) { [math]::Round($totalRemoveMember / $groupDays, 2) } else { 0 }
$avgUpdateGroup       = if ($groupDays -gt 0) { [math]::Round($totalUpdateGroup / $groupDays, 2) } else { 0 }
$avgAddGroup          = if ($groupDays -gt 0) { [math]::Round($totalAddGroup / $groupDays, 2) } else { 0 }
$avgDeleteGroup       = if ($groupDays -gt 0) { [math]::Round($totalDeleteGroup / $groupDays, 2) } else { 0 }
$avgTotalGroup        = if ($groupDays -gt 0) { [math]::Round(($totalAddMember + $totalRemoveMember + $totalUpdateGroup + $totalAddGroup + $totalDeleteGroup) / $groupDays, 2) } else { 0 }

$avgAddUser           = if ($userDays -gt 0) { [math]::Round($totalAddUser / $userDays, 2) } else { 0 }
$avgDeleteUser        = if ($userDays -gt 0) { [math]::Round($totalDeleteUser / $userDays, 2) } else { 0 }
$avgUpdateUser        = if ($userDays -gt 0) { [math]::Round($totalUpdateUser / $userDays, 2) } else { 0 }
$avgChangeUserLicense = if ($userDays -gt 0) { [math]::Round($totalChangeUserLicense / $userDays, 2) } else { 0 }
$avgTotalUser         = if ($userDays -gt 0) { [math]::Round(($totalAddUser + $totalDeleteUser + $totalUpdateUser + $totalChangeUserLicense) / $userDays, 2) } else { 0 }

$avgAddDevice         = if ($deviceDays -gt 0) { [math]::Round($totalAddDevice / $deviceDays, 2) } else { 0 }
$avgDeleteDevice      = if ($deviceDays -gt 0) { [math]::Round($totalDeleteDevice / $deviceDays, 2) } else { 0 }
$avgUpdateDevice      = if ($deviceDays -gt 0) { [math]::Round($totalUpdateDevice / $deviceDays, 2) } else { 0 }
$avgRRODevice         = if ($deviceDays -gt 0) { [math]::Round($totalRemoveRegisteredOwnerfromDevice / $deviceDays, 2) } else { 0 }
$avgARODevice         = if ($deviceDays -gt 0) { [math]::Round($totalAddRegisteredOwnertoDevice / $deviceDays, 2) } else { 0 }
$avgRRUDevice         = if ($deviceDays -gt 0) { [math]::Round($totalRemoveRegisteredusersfromDevice / $deviceDays, 2) } else { 0 }
$avgARUDevice         = if ($deviceDays -gt 0) { [math]::Round($totalAddRegistereduserstoDevice / $deviceDays, 2) } else { 0 }
$avgTotalDevice       = if ($deviceDays -gt 0) { [math]::Round(($totalAddDevice + $totalDeleteDevice + $totalUpdateDevice + $totalRemoveRegisteredOwnerfromDevice + $totalRemoveRegisteredusersfromDevice + $totalAddRegisteredOwnertoDevice + $RemoveRegUsersfromDeviceCount) / $deviceDays, 2) } else { 0 }

$avgAddMemberAU       = if ($auDays -gt 0) { [math]::Round($totalAddMemberAU / $auDays, 2) } else { 0 }
$avgRemoveMemberAU    = if ($auDays -gt 0) { [math]::Round($totalRemoveMemberAU / $auDays, 2) } else { 0 }
$avgUpdateAU          = if ($auDays -gt 0) { [math]::Round($totalUpdateAU / $auDays, 2) } else { 0 }
$avgTotalAU           = if ($auDays -gt 0) { [math]::Round(($totalAddMemberAU + $totalRemoveMemberAU + $totalUpdateAU) / $auDays, 2) } else { 0 }

# HTML header with CSS
$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <head>
    <title>Audit Activity Report</title>
    <script src='https://cdn.jsdelivr.net/npm/chart.js'></script>
     <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
        }
        h1, h2 {
            text-align: center;
            color: #333;
        }
        table {
            width: 90%;
            margin: 20px auto;
            border-collapse: collapse;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: center;
        }
        th {
            background-color: #f2f2f2;
            color: #333;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        .highlight {
            color: red;
            font-weight: bold;
        }
        .lowlight {
            color: green;
            font-weight: bold;
        }
        .total-row {
            background-color: #e0e0e0;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <h1>Audit Activity Report</h1>
"@

# GroupManagement Table
$html += "<h2>Group Management (Averages: Add $avgAddMember, Remove $avgRemoveMember, Update $avgUpdateGroup, Add Group $avgAddGroup, Delete $avgDeleteGroup, Total $avgTotalGroup)</h2>`n<table>`n<tr><th style=`"width: 300px;`">Date</th><th>Add Member</th><th>Remove Member</th><th>Update Group</th><th>Add Group</th><th>Delete Group</th><th>Total Daily Group Activity</th></tr>`n"
foreach ($entry in $GroupProperties) {
    $addMemberClass    = if ($entry."Add member to group" -gt $avgAddMember) { 'class="highlight"' } elseif ($entry."Add member to group" -lt $avgAddMember) { 'class="lowlight"' } else { '' }
    $removeMemberClass = if ($entry."Remove member from group" -gt $avgRemoveMember) { 'class="highlight"' } elseif ($entry."Remove member from group" -lt $avgRemoveMember) { 'class="lowlight"' } else { '' }
    $updateGroupClass  = if ($entry."Update group" -gt $avgUpdateGroup) { 'class="highlight"' } elseif ($entry."Update group" -lt $avgUpdateGroup) { 'class="lowlight"' } else { '' }
    $addGroupClass     = if ($entry."Add group" -gt $avgAddGroup) { 'class="highlight"' } elseif ($entry."Add group" -lt $avgAddGroup) { 'class="lowlight"' } else { '' }
    $deleteGroupClass  = if ($entry."Delete group" -gt $avgDeleteGroup) { 'class="highlight"' } elseif ($entry."Delete group" -lt $avgDeleteGroup) { 'class="lowlight"' } else { '' }
    $totalDailyClass   = if ($entry."Total Daily Group Activity" -gt $avgTotalGroup) { 'class="highlight"' } elseif ($entry."Total Daily Group Activity" -lt $avgTotalGroup) { 'class="lowlight"' } else { '' }

    $html += "    <tr>`n"
    $html += "        <td>$($entry.Date)</td>`n"
    $html += "        <td $addMemberClass>$($entry.'Add member to group')</td>`n"
    $html += "        <td $removeMemberClass>$($entry.'Remove member from group')</td>`n"
    $html += "        <td $updateGroupClass>$($entry.'Update group')</td>`n"
    $html += "        <td $addGroupClass>$($entry.'Add group')</td>`n"
    $html += "        <td $deleteGroupClass>$($entry.'Delete group')</td>`n"
    $html += "        <td $totalDailyClass>$($entry.'Total Daily Group Activity')</td>`n"
    $html += "    </tr>`n"
}
$totalAllGroup = $totalAddMember + $totalRemoveMember + $totalUpdateGroup + $totalAddGroup + $totalDeleteGroup
$html += "    <tr class=`"total-row`">`n"
$html += "        <td>Total ($((Get-Date $startDate).ToString('MM/dd/yyyy')) - $((Get-Date $endDate).ToString('MM/dd/yyyy')))</td>`n"
$html += "        <td>$totalAddMember</td>`n"
$html += "        <td>$totalRemoveMember</td>`n"
$html += "        <td>$totalUpdateGroup</td>`n"
$html += "        <td>$totalAddGroup</td>`n"
$html += "        <td>$totalDeleteGroup</td>`n"
$html += "        <td>$totalAllGroup</td>`n"
$html += "    </tr>`n</table>`n"

$datesGroup       = $GroupProperties | ForEach-Object { $_.Date }
$addMemberData    = $GroupProperties | ForEach-Object { $_.'Add member to group' }
$removeMemberData = $GroupProperties | ForEach-Object { $_.'Remove member from group' }
$updateGroupData  = $GroupProperties | ForEach-Object { $_.'Update group' }
$addGroupData     = $GroupProperties | ForEach-Object { $_.'Add group' }
$deleteGroupData  = $GroupProperties | ForEach-Object { $_.'Delete group' }

$html += @"
<canvas id='groupActivityChart' width='900' height='400'></canvas>
<script>
const labels       = $($(ConvertTo-Json $datesGroup));
const addMember    = $($(ConvertTo-Json $addMemberData));
const removeMember = $($(ConvertTo-Json $removeMemberData));
const updateGroup  = $($(ConvertTo-Json $updateGroupData));
const addGroup     = $($(ConvertTo-Json $addGroupData));
const deleteGroup  = $($(ConvertTo-Json $deleteGroupData));

const data = {
  labels: labels,
  datasets: [
    { label: 'Add Member', data: addMember, backgroundColor: 'rgba(54,162,235,0.7)' },
    { label: 'Remove Member', data: removeMember, backgroundColor: 'rgba(255,99,132,0.7)' },
    { label: 'Update Group', data: updateGroup, backgroundColor: 'rgba(255,206,86,0.7)' },
    { label: 'Add Group', data: addGroup, backgroundColor: 'rgba(75,192,192,0.7)' },
    { label: 'Delete Group', data: deleteGroup, backgroundColor: 'rgba(153,102,255,0.7)' }
  ]
};

const config = {
  type: 'bar',
  data: data,
  options: {
    responsive: true,
    plugins: {
      legend: { position: 'top' },
      title: { display: true, text: 'Group Management Activity (Stacked)' }
    },
    scales: {
      x: { stacked: true },
      y: { stacked: true }
    }
  }
};

new Chart(document.getElementById('groupActivityChart'), config);
</script>
"@

# UserManagement Table
$html += "<h2>User Management (Averages: Add $avgAddUser, Delete $avgDeleteUser, Update $avgUpdateUser, Change License $avgChangeUserLicense, Total $avgTotalUser)</h2>`n<table>`n<tr><th style=`"width: 300px;`">Date</th><th>Add User</th><th>Delete User</th><th>Update User</th><th>Change License</th><th>Total Daily User Activity</th></tr>`n"
foreach ($entry in $UserProperties) {
    $addUserClass       = if ($entry."Add user" -gt $avgAddUser) { 'class="highlight"' } elseif ($entry."Add user" -lt $avgAddUser) { 'class="lowlight"' } else { '' }
    $deleteUserClass    = if ($entry."Delete user" -gt $avgDeleteUser) { 'class="highlight"' } elseif ($entry."Delete user" -lt $avgDeleteUser) { 'class="lowlight"' } else { '' }
    $updateUserClass    = if ($entry."Update user" -gt $avgUpdateUser) { 'class="highlight"' } elseif ($entry."Update user" -lt $avgUpdateUser) { 'class="lowlight"' } else { '' }
    $changeLicenseClass = if ($entry."Change user license" -gt $avgChangeUserLicense) { 'class="highlight"' } elseif ($entry."Change user license" -lt $avgChangeUserLicense) { 'class="lowlight"' } else { '' }
    $totalDailyClass    = if ($entry."Total Daily User Activity" -gt $avgTotalUser) { 'class="highlight"' } elseif ($entry."Total Daily User Activity" -lt $avgTotalUser) { 'class="lowlight"' } else { '' }

    $html += "    <tr>`n"
    $html += "        <td>$($entry.Date)</td>`n"
    $html += "        <td $addUserClass>$($entry.'Add user')</td>`n"
    $html += "        <td $deleteUserClass>$($entry.'Delete user')</td>`n"
    $html += "        <td $updateUserClass>$($entry.'Update user')</td>`n"
    $html += "        <td $changeLicenseClass>$($entry.'Change user license')</td>`n"
    $html += "        <td $totalDailyClass>$($entry.'Total Daily User Activity')</td>`n"
    $html += "    </tr>`n"
}
$totalAllUser = $totalAddUser + $totalDeleteUser + $totalUpdateUser + $totalChangeUserLicense
$html += "    <tr class=`"total-row`">`n"
$html += "        <td>Total ($((Get-Date $startDate).ToString('MM/dd/yyyy')) - $((Get-Date $endDate).ToString('MM/dd/yyyy')))</td>`n"
$html += "        <td>$totalAddUser</td>`n"
$html += "        <td>$totalDeleteUser</td>`n"
$html += "        <td>$totalUpdateUser</td>`n"
$html += "        <td>$totalChangeUserLicense</td>`n"
$html += "        <td>$totalAllUser</td>`n"
$html += "    </tr>`n</table>`n"


$datesUser         = $UserProperties | ForEach-Object { $_.Date }
$addUserData       = $UserProperties | ForEach-Object { $_.'Add user' }
$deleteUserData    = $UserProperties | ForEach-Object { $_.'Delete user' }
$updateUserData    = $UserProperties | ForEach-Object { $_.'Update user' }
$changeLicenseData = $UserProperties | ForEach-Object { $_.'Change user license' }

$html += @"
<canvas id='userActivityChart' width='900' height='400'></canvas>
<script>
const labels2       = $($(ConvertTo-Json $datesUser));
const addUser       = $($(ConvertTo-Json $addUserData));
const deleteUser    = $($(ConvertTo-Json $deleteUserData));
const updateUser    = $($(ConvertTo-Json $updateUserData));
const changeLicense = $($(ConvertTo-Json $changeLicenseData));

const Userdata = {
  labels: labels2,
  datasets: [
    { label: 'Add User', data: addUser, backgroundColor: 'rgba(54,162,235,0.7)' },
    { label: 'Delete User', data: deleteUser, backgroundColor: 'rgba(255,99,132,0.7)' },
    { label: 'Update User', data: updateUser, backgroundColor: 'rgba(255,206,86,0.7)' },
    { label: 'Change License', data: changeLicense, backgroundColor: 'rgba(75,192,192,0.7)' }
  ]
};

const config2 = {
  type: 'bar',
  data: Userdata,
  options: {
    responsive: true,
    plugins: {
      legend: { position: 'top' },
      title: { display: true, text: 'User Management Activity (Stacked)' }
    },
    scales: {
      x: { stacked: true },
      y: { stacked: true }
    }
  }
};

new Chart(document.getElementById('userActivityChart'), config2);
</script>
"@



# DeviceManagement Table
$html += "<h2>Device Activity (Averages: Add $avgAddDevice, Delete $avgDeletedevice, Update $avgUpdateDevice, Add Reg Owner $avgARODevice, Remove Reg Owner $avgRRODevice, Add Reg User $avgARUDevice, Rem Reg User $avgRRUDevice, Total $avgTotaldevice)</h2>`n<table>`n<tr><th style=`"width: 300px;`" >Date</th><th>Add device</th><th>Delete device</th><th>Update device</th><th>ARO</th><th>RRO</th><th>ARU</th><th>RRU</th><th>Total Daily Device Activity</th></tr>`n"
foreach ($entry in $DeviceProperties) {
    $addDeviceClass    = if ($entry."Add device" -gt $avgAddDevice) { 'class="highlight"' } elseif ($entry."Add device" -lt $avgAddDevice) { 'class="lowlight"' } else { '' }
    $deleteDeviceClass = if ($entry."Delete device" -gt $avgDeleteDevice) { 'class="highlight"' } elseif ($entry."Delete device" -lt $avgDeleteUser) { 'class="lowlight"' } else { '' }
    $updateDeviceClass = if ($entry."Update device" -gt $avgUpdateDevice) { 'class="highlight"' } elseif ($entry."Update device" -lt $avgUpdateUser) { 'class="lowlight"' } else { '' }
    $ARODeviceClass    = if ($entry."Add registered owner to device" -gt $avgUpdateDevice) { 'class="highlight"' } elseif ($entry."ARO to device" -lt $avgUpdateUser) { 'class="lowlight"' } else { '' }
    $RRODeviceClass    = if ($entry."Remove registered owner from device" -gt $avgUpdateDevice) { 'class="highlight"' } elseif ($entry."RRO from device" -lt $avgUpdateUser) { 'class="lowlight"' } else { '' }
    $ARUDeviceClass    = if ($entry."Add registered users to device" -gt $avgUpdateDevice) { 'class="highlight"' } elseif ($entry."ARU to device" -lt $avgUpdateUser) { 'class="lowlight"' } else { '' }
    $RRUDeviceClass    = if ($entry."Remove registered user from device" -gt $avgUpdateDevice) { 'class="highlight"' } elseif ($entry."RRU from device" -lt $avgUpdateUser) { 'class="lowlight"' } else { '' }
    $totalDailyClass   = if ($entry."Total Daily Device Activity" -gt $avgTotalDevice) { 'class="highlight"' } elseif ($entry."Total Daily Device Activity" -lt $avgTotalDevice) { 'class="lowlight"' } else { '' }

    $html += "    <tr>`n"
    $html += "        <td>$($entry.Date)</td>`n"
    $html += "        <td $addDeviceClass>$($entry.'Add device')</td>`n"
    $html += "        <td $deleteDeviceClass>$($entry.'Delete device')</td>`n"
    $html += "        <td $updateDeviceClass>$($entry.'Update device')</td>`n"
    $html += "        <td $ARODeviceClass>$($entry.'ARO to device')</td>`n"
    $html += "        <td $RRODeviceClass>$($entry.'RRO from device')</td>`n"
    $html += "        <td $ARUDeviceClass>$($entry.'ARU to device')</td>`n"
    $html += "        <td $RRUDeviceClass>$($entry.'RRU from device')</td>`n"
    $html += "        <td $totalDailyClass>$($entry.'Total Daily Device Activity')</td>`n"
    $html += "    </tr>`n"
}
$totalAlldevice = $totalAddDevice + $totalDeleteDevice + $totalUpdateDevice  + $totalRemoveRegisteredOwnerfromDevice + $totalAddRegisteredOwnertoDevice  +  $totalRemoveRegisteredusersfromDevice + $totalAddRegistereduserstoDevice
$html += "    <tr class=`"total-row`">`n"
$html += "        <td>Total ($((Get-Date $startDate).ToString('MM/dd/yyyy')) - $((Get-Date $endDate).ToString('MM/dd/yyyy')))</td>`n"
$html += "        <td>$totalAddDevice</td>`n"
$html += "        <td>$totalDeleteDevice</td>`n"
$html += "        <td>$totalUpdateDevice</td>`n"
$html += "        <td>$totalAddRegisteredOwnertoDevice</td>`n"
$html += "        <td>$totalRemoveRegisteredOwnerfromDevice</td>`n"
$html += "        <td>$totalAddRegistereduserstoDevice</td>`n"
$html += "        <td>$totalRemoveRegisteredusersfromDevice</td>`n"
$html += "        <td>$totalAlldevice</td>`n"
$html += "    </tr>`n</table>`n"

$dates            = $deviceProperties | ForEach-Object { $_.Date }
$addDeviceData    = $deviceProperties | ForEach-Object { $_.'Add device' }
$deleteDeviceData = $deviceProperties | ForEach-Object { $_.'Delete device' }
$updateDeviceData = $deviceProperties | ForEach-Object { $_.'Update device' }
$ARODeviceData    = $deviceProperties | ForEach-Object { $_.'ARO to device' }
$RRODeviceData    = $deviceProperties | ForEach-Object { $_.'RRO from device' }
$ARUDeviceData    = $deviceProperties | ForEach-Object { $_.'ARU to device' }
$RRUDeviceData    = $deviceProperties | ForEach-Object { $_.'RRU from device' }
$totalDeviceData  = $deviceProperties | ForEach-Object { $_.'Total Daily Device Activity' }

$html += @"
<canvas id='deviceActivityChart' width='900' height='400'></canvas>
<script>
const devicelabels = $($(ConvertTo-Json $dates));
const addDevice    = $($(ConvertTo-Json $addDeviceData));
const deleteDevice = $($(ConvertTo-Json $deleteDeviceData));
const updateDevice = $($(ConvertTo-Json $updateDeviceData));
const ARODevice    = $($(ConvertTo-Json $ARODeviceData));
const RRODevice    = $($(ConvertTo-Json $RRODeviceData));
const ARUDevice    = $($(ConvertTo-Json $ARUDeviceData));
const RRUDevice    = $($(ConvertTo-Json $RRUDeviceData))

const devicedata = {
  labels: devicelabels,
  datasets: [
    { label: 'Add Device', data: addDevice, backgroundColor: 'rgba(54,162,235,0.5)' },
    { label: 'Delete Device', data: deleteDevice, backgroundColor: 'rgba(255,99,132,0.5)' },
    { label: 'Update Device', data: updateDevice, backgroundColor: 'rgba(255,206,86,0.5)' },
    { label: 'ARO', data: ARODevice, backgroundColor: 'rgba(75,192,192,0.5)' },
    { label: 'RRO', data: RRODevice, backgroundColor: 'rgba(153,102,255,0.5)' },
    { label: 'ARU', data: ARUDevice, backgroundColor: 'rgba(255,159,64,0.5)' },
    { label: 'RRU', data: RRUDevice, backgroundColor: 'rgba(199,199,199,0.5)' }    
  ]
};

const deviceconfig = {
    type: 'bar',
    data: devicedata,
    options: {
      responsive: true,
      plugins: {
        legend: { position: 'top' },
        title: { display: true, text: 'Device Activity (Stacked)' }
      },
      scales: {
        x: { stacked: true },
        y: { stacked: true }
      }
    }
  };

new Chart(document.getElementById('deviceActivityChart'), deviceconfig);
</script>
"@


# AdministrativeUnit Table
$html += "<h2>Administrative Unit (Averages: Add $avgAddMemberAU, Remove $avgRemoveMemberAU, Update $avgUpdateAU, Total $avgTotalAU)</h2>`n<table>`n<tr><th style=`"width: 300px;`" >Date</th><th>Add Member</th><th>Remove Member</th><th>Update AU</th><th>Total Daily</th></tr>`n"
foreach ($entry in $AdminUnitProperties) {
    $addMemberAUClass    = if ($entry."Add member to administrative unit" -gt $avgAddMemberAU) { 'class="highlight"' } elseif ($entry."Add member to administrative unit" -lt $avgAddMemberAU) { 'class="lowlight"' } else { '' }
    $removeMemberAUClass = if ($entry."Remove member from administrative unit" -gt $avgRemoveMemberAU) { 'class="highlight"' } elseif ($entry."Remove member from administrative unit" -lt $avgRemoveMemberAU) { 'class="lowlight"' } else { '' }
    $updateAUClass       = if ($entry."Update administrative unit" -gt $avgUpdateAU) { 'class="highlight"' } elseif ($entry."Update administrative unit" -lt $avgUpdateAU) { 'class="lowlight"' } else { '' }
    $totalDailyClass     = if ($entry."Total Daily Admin Unit Activity" -gt $avgTotalAU) { 'class="highlight"' } elseif ($entry."Total Daily Admin Unit  Activity" -lt $avgTotalAU) { 'class="lowlight"' } else { '' }

    $html += "    <tr>`n"
    $html += "        <td>$($entry.Date)</td>`n"
    $html += "        <td $addMemberAUClass>$($entry.'Add member to administrative unit')</td>`n"
    $html += "        <td $removeMemberAUClass>$($entry.'Remove member from administrative unit')</td>`n"
    $html += "        <td $updateAUClass>$($entry.'Update administrative unit')</td>`n"
    $html += "        <td $totalDailyClass>$($entry.'Total Daily Admin Unit Activity')</td>`n"
    $html += "    </tr>`n"
}
$totalAllAU = $totalAddMemberAU + $totalRemoveMemberAU + $totalUpdateAU
$html += "    <tr class=`"total-row`">`n"
$html += "        <td>Total ($((Get-Date $startDate).ToString('MM/dd/yyyy')) - $((Get-Date $endDate).ToString('MM/dd/yyyy')))</td>`n"
$html += "        <td>$totalAddMemberAU</td>`n"
$html += "        <td>$totalRemoveMemberAU</td>`n"
$html += "        <td>$totalUpdateAU</td>`n"
$html += "        <td>$totalAllAU</td>`n"
$html += "    </tr>`n</table>`n"

$datesAU       = $AdminUnitProperties | ForEach-Object { $_.Date }
$addMemberAU   = $AdminUnitProperties | ForEach-Object { $_.'Add member to administrative unit' }
$removeMemberAU= $AdminUnitProperties | ForEach-Object { $_.'Remove member from administrative unit' }
$updateAU      = $AdminUnitProperties | ForEach-Object { $_.'Update administrative unit' }
$totalAUData   = $AdminUnitProperties | ForEach-Object { $_.'Total Daily Admin Unit Activity' }

if ($AdminUnitProperties.Count -eq 1) {
    # Single-row fallback: simple bar chart and message
    $html += @"
<h2>Administrative Unit Activity Chart</h2>
<p>Only one day of activity detected. Stacked bar chart not shown.</p>
<canvas id='adminUnitChartSingle' width='900' height='400'></canvas>
<script>
const labels = ['Add Member', 'Remove Member', 'Update AU'];
const data = {
  labels: labels,
  datasets: [{
    label: 'Activity',
    data: [
      $($AdminUnitProperties[0].'Add member to administrative unit'),
      $($AdminUnitProperties[0].'Remove member from administrative unit'),
      $($AdminUnitProperties[0].'Update administrative unit')
    ],
    backgroundColor: [
      'rgba(54,162,235,0.7)',
      'rgba(255,99,132,0.7)',
      'rgba(255,206,86,0.7)'
    ]
  }]
};
const config = {
  type: 'bar',
  data: data,
  options: {
    plugins: {
      legend: { display: false },
      title: { display: true, text: 'Administrative Unit Activity (Single Day)' }
    }
  }
};
new Chart(document.getElementById('adminUnitChartSingle'), config);
</script>
"@
} else {
    # Multi-row: stacked bar chart
    $html += @"
<h2>Administrative Unit Activity Chart</h2>
<canvas id='adminUnitChart' width='900' height='400'></canvas>
<script>
const AUlabels       = $($(ConvertTo-Json $datesAU));
const addMemberAU    = $($(ConvertTo-Json $addMemberAU));
const removeMemberAU = $($(ConvertTo-Json $removeMemberAU));
const updateAU       = $($(ConvertTo-Json $updateAU));


const AUdata1 = {
  labels: AUlabels,
  datasets: [
    { label: 'Add Member', data: addMemberAU, backgroundColor: 'rgba(54,162,235,0.7)' },
    { label: 'Remove Member', data: removeMemberAU, backgroundColor: 'rgba(255,99,132,0.7)' },
    { label: 'Update AU', data: updateAU, backgroundColor: 'rgba(255,206,86,0.7)' }
  ]
};

const configAU = {
  type: 'bar',
  data: AUdata1,
  options: {
    responsive: true,
    plugins: {
      legend: { position: 'top' },
      title: { display: true, text: 'Administrative Unit Activity (Stacked)' }
    },
    scales: {
      x: { stacked: true },
      y: { stacked: true }
    }
  }
};

new Chart(document.getElementById('adminUnitChart'), configAU);
</script>
"@

# Combine and get unique dates
$combinedDates = ($datesUser + $datesGroup +$dates +$datesAU) | Select-Object -Unique | Sort-Object


## u & m stacked
$html += @"
<canvas id='combinedActivityChart' width='900' height='400'></canvas>
<script>
const labelsCombined = $($(ConvertTo-Json $combinedDates)); // Assuming same date range

const addUserC       = $($(ConvertTo-Json $addUserData));
const deleteUserC    = $($(ConvertTo-Json $deleteUserData));
const updateUserC    = $($(ConvertTo-Json $updateUserData));
const changeLicenseC = $($(ConvertTo-Json $changeLicenseData));

const addGroupC      = $($(ConvertTo-Json $addGroupData));
const deleteGroupC   = $($(ConvertTo-Json $deleteGroupData));
const updateGroupC   = $($(ConvertTo-Json $updateGroupData));
const AddmemberC   = $($(ConvertTo-Json $AddmemberData));
const RemovememberC   = $($(ConvertTo-Json $RemovememberData));

const addDeviceC    = $($(ConvertTo-Json $addDeviceData));
const deleteDeviceC = $($(ConvertTo-Json $deleteDeviceData));
const updateDeviceC = $($(ConvertTo-Json $updateDeviceData));
const ARODeviceC    = $($(ConvertTo-Json $ARODeviceData));
const RRODeviceC    = $($(ConvertTo-Json $RRODeviceData));
const ARUDeviceC    = $($(ConvertTo-Json $ARUDeviceData));
const RRUDeviceC    = $($(ConvertTo-Json $RRUDeviceData))

const combinedData = {
  labels: labelsCombined,
  datasets: [
    { label: 'Add User', data: addUser, backgroundColor: 'rgba(220,20,60,0.7)' },      // Crimson
    { label: 'Delete User', data: deleteUser, backgroundColor: 'rgba(255,0,0,0.7)' }, // Pure Red
    { label: 'Update User', data: updateUser, backgroundColor: 'rgba(178,34,34,0.7)' }, // Firebrick
    { label: 'Change License', data: changeLicense, backgroundColor: 'rgba(255,69,0,0.7)' }, // Red-Orange
    { label: 'Add Member', data: addMember, backgroundColor: 'rgba(30,144,255,0.7)' },    // Dodger Blue
    { label: 'Remove Member', data: removeMember, backgroundColor: 'rgba(70,130,180,0.7)' }, // Steel Blue
    { label: 'Update Group', data: updateGroup, backgroundColor: 'rgba(100,149,237,0.7)' }, // Cornflower Blue
    { label: 'Add Group', data: addGroup, backgroundColor: 'rgba(65,105,225,0.7)' },       // Royal Blue
    { label: 'Delete Group', data: deleteGroup, backgroundColor: 'rgba(0,0,139,0.7)' },     // Dark Blue
    { label: 'Add Device', data: addDevice, backgroundColor: 'rgba(34,139,34,0.5)' },    // Forest Green
    { label: 'Delete Device', data: deleteDevice, backgroundColor: 'rgba(0,128,0,0.5)' }, // Green
    { label: 'Update Device', data: updateDevice, backgroundColor: 'rgba(60,179,113,0.5)' }, // Medium Sea Green
    { label: 'ARO', data: ARODevice, backgroundColor: 'rgba(46,139,87,0.5)' },           // Sea Green
    { label: 'RRO', data: RRODevice, backgroundColor: 'rgba(0,100,0,0.5)' },            // Dark Green
    { label: 'ARU', data: ARUDevice, backgroundColor: 'rgba(107,142,35,0.5)' },         // Olive Drab
    { label: 'RRU', data: RRUDevice, backgroundColor: 'rgba(152,251,152,0.5)' },         // Pale Green
    { label: 'Add Member', data: addMemberAU, backgroundColor: 'rgba(255,215,0,0.7)' },    // Gold
    { label: 'Remove Member', data: removeMemberAU, backgroundColor: 'rgba(255,255,0,0.7)' }, // Yellow
    { label: 'Update AU', data: updateAU, backgroundColor: 'rgba(238,232,170,0.7)' }        // Pale Goldenrod  
  ]
};

const configCombined = {
  type: 'bar',
  data: combinedData,
  options: {
    responsive: true,
    plugins: {
      legend: { position: 'top' },
      title: { display: true, text: 'Combined User, Group, Device and AU Management Activity (Stacked)' }
    },
    scales: {
      x: { stacked: true },
      y: { stacked: true }
    }
  }
};

new Chart(document.getElementById('combinedActivityChart'), configCombined);
</script>
"@

## u & m stacked

}


# Close HTML
$html += "</body></html>"

# Save to file
$file = $Outputdirectory+"GroupBacklogExport_"
$tdy = get-date -Format "MM-dd-yyyy_hh.mm.ss"

$outputFile = $file+$tdy+"_AuditActivityReport.html"
$html | Out-File -FilePath $outputFile -Encoding UTF8
Write-Host "Report saved to $outputFile"