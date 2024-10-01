<# 
Written by Derrick Baxter 10.1.24

Updated Version of the TLS checker with Visuals (green pass/red failed)
https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/reference-connect-tls-enforcement#powershell-script-to-check-tls-12
#>

Function Get-ADSyncToolsTls12RegValue
{
    [CmdletBinding()]
    Param
    (
        # Registry Path
        [Parameter(Mandatory=$true,
                   Position=0)]
        [string]
        $RegPath,

# Registry Name
        [Parameter(Mandatory=$true,
                   Position=1)]
        [string]
        $RegName
    )
    $regItem = Get-ItemProperty -Path $RegPath -Name $RegName -ErrorAction Ignore
    $output = "" | select Path,Name,Value
    $output.Path = $RegPath
    $output.Name = $RegName

If ($regItem -eq $null)
    {
        $output.Value = "Not Found"
    }
    Else
    {
        $output.Value = $regItem.$RegName
    }
    $output
}

$regSettings = @()
$regKey = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319'
$regSettings += Get-ADSyncToolsTls12RegValue $regKey 'SystemDefaultTlsVersions'
$regSettings += Get-ADSyncToolsTls12RegValue $regKey 'SchUseStrongCrypto'

$regKey = 'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319'
$regSettings += Get-ADSyncToolsTls12RegValue $regKey 'SystemDefaultTlsVersions'
$regSettings += Get-ADSyncToolsTls12RegValue $regKey 'SchUseStrongCrypto'

$regKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server'
$regSettings += Get-ADSyncToolsTls12RegValue $regKey 'Enabled'
$regSettings += Get-ADSyncToolsTls12RegValue $regKey 'DisabledByDefault'

$regKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client'
$regSettings += Get-ADSyncToolsTls12RegValue $regKey 'Enabled'
$regSettings += Get-ADSyncToolsTls12RegValue $regKey 'DisabledByDefault'

#$regSettings
$GoodEntry = @()
$badEntry = @()

foreach($item in $regSettings)
{
    if ($item.path -eq "HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319" -and $item.Name -eq "SystemDefaultTlsVersions" -and $item.value -eq 1)
    {
        $goodentry += $item
    }
    elseif ($item.path -eq "HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319" -and $item.Name -eq "SystemDefaultTlsVersions" -and $item.value -ne 1) 
    {
        $badentry += $item
    }
    if ($item.path -eq "HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319" -and $item.Name -eq "SchUseStrongCrypto" -and $item.value -eq 1)
    {
        $goodentry += $item
    }
    elseif ($item.path -eq "HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319" -and $item.Name -eq "SchUseStrongCrypto" -and $item.value -ne 1) 
    {
        $badentry += $item
    }
    if ($item.path -eq "HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319" -and $item.Name -eq "SystemDefaultTlsVersions" -and $item.value -eq 1)
    {
        $goodentry += $item
    }
    elseif ($item.path -eq "HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319" -and $item.Name -eq "SystemDefaultTlsVersions" -and $item.value -ne 1) 
    {
        $badentry += $item
    }
    if ($item.path -eq "HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319" -and $item.Name -eq "SchUseStrongCrypto" -and $item.value -eq 1)
    {
        $goodentry += $item
    }
    elseif ($item.path -eq "HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319" -and $item.Name -eq "SchUseStrongCrypto" -and $item.value -ne 1) 
    {
        $badentry += $item
    }
    if ($item.path -eq "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server" -and $item.Name -eq "Enabled" -and $item.value -eq 1)
    {
        $goodentry += $item
    }
    elseif ($item.path -eq "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server" -and $item.Name -eq "Enabled" -and $item.value -ne 1) 
    {
        $badentry += $item
    }

    if ($item.path -eq "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server" -and $item.Name -eq "DisabledByDefault" -and $item.value -eq 0)
    {
        $goodentry += $item
    }
    elseif ($item.path -eq "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server" -and $item.Name -eq "DisabledByDefault" -and $item.value -ne 1) 
    {
        $badentry += $item
    }

    if ($item.path -eq "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" -and $item.Name -eq "Enabled" -and $item.value -eq 1)
    {
        $goodentry += $item
    }
    elseif ($item.path -eq "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" -and $item.Name -eq "Enabled" -and $item.value -ne 1) 
    {
        $badentry += $item
    }
    if ($item.path -eq "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" -and $item.Name -eq "DisabledByDefault" -and $item.value -eq 0)
    {
        $goodentry += $item
    }
    elseif ($item.path -eq "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client" -and $item.Name -eq "DisabledByDefault" -and $item.value -ne 1) 
    {
        $badentry += $item
    }
}
if($GoodEntry -ne $null){
    write-host "Reigstry Entries are Correct for TLS 1.2"
$goodEntry | Format-Table | Out-String|% {Write-Host $_  -ForegroundColor Green -BackgroundColor Black }}
if($badEntry -ne $null){
    write-host "Reigstry Entries are NOT Correct for TLS 1.2"
$badEntry | Format-Table | Out-String|% {Write-Host $_  -ForegroundColor Red -BackgroundColor Black }}
