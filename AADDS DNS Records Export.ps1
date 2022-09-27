<#
Written by Derrick Baxter 9.27.2022
Used to export DNS Records to a backup CSV file
to recreate any lost records follow the document below
https://learn.microsoft.com/en-us/powershell/module/dnsserver/add-dnsserverresourcerecord?view=windowsserver2022-ps

from command line: All
".\aadds dns records export.ps1" -AADDS yourdomain.com -DCIPAddress 10.1.1.4 -recordtype All -OutputFile ALLDNS.csv
Just host A records
".\aadds dns records export.ps1" -AADDS aadds.twdsavior18.com -DCIPAddress 10.1.1.4 -recordtype 'Host Records' -OutputFile DNS.csv
#>

param([parameter(mandatory)][string] $AADDS,
      [parameter(mandatory)] [string]$DCIPAddress,
      [parameter(mandatory)][validateset("Host Records","All")] [string]$recordtype,
      [parameter(mandatory)] [string]$OutputFile)

$WarningPreference = "SilentlyContinue"  

import-module -name dnsserver

if($recordtype -eq "All")
{
    $DNS = Get-DnsServerResourceRecord -zonename $AADDS -ComputerName $DCIPAddress
}
else {
    $DNS = Get-DnsServerResourceRecord -zonename $AADDS -ComputerName $DCIPAddress -RRType A
}
$members =@()
foreach($dnsrecorditem in $DNS)
{
    $IP = $dnsrecorditem.recorddata.ipv4address.IPAddressToString
    $members += New-Object Object |
                Add-Member -NotePropertyName HostName -NotePropertyValue $dnsrecorditem.HostName -PassThru |
                Add-Member -NotePropertyName IPAddress -NotePropertyValue $IP -PassThru | 
                Add-Member -NotePropertyName RecordType -NotePropertyValue $dnsrecorditem.RecordType -PassThru | 
                Add-Member -NotePropertyName Type -NotePropertyValue $dnsrecorditem.Type -PassThru 

}

$members | export-csv -Path $OutputFile -NoTypeInformation -Encoding UTF8