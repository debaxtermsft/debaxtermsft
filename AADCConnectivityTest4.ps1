<#PSScriptInfo
 
.VERSION 4.1.1
 
.GUID 98fc7cbf-c135-4928-9cd7-499aea978c76
 
.DESCRIPTION AAD Communications Test: Use this script to test basic network connectivity to on-premises and online endpoints as well as name resolution.
 
.AUTHOR Aaron Guilmette - Update Derrick Baxter
 
.COMPANYNAME Microsoft
 
.COPYRIGHT 2020
 
.TAGS Azure AzureAD Office365 AADConnect seamless sso prerequisites azure ad connect installation
 
.LICENSEURI
 
.PROJECTURI https://www.undocumented-features.com/2018/02/10/aad-connect-network-and-name-resolution-test/
 
.ICONURI
 
.EXTERNALMODULEDEPENDENCIES
 
.REQUIREDSCRIPTS
 
.EXTERNALSCRIPTDEPENDENCIES
 
.RELEASENOTES
#>

<#
.SYNOPSIS
Test basic system, connectivity, and name resolution compatibility for AAD Connect.
 
Use this script to test basic network connectivity to on-premises and
online endpoints as well as name resolution.
 
If you are uncertain about your server's ability to connect to Office 365 for
the purposes of deploying Azure AD Connect or to local network resources for
configuring a multi-forest deployment, you can attempt to use this tool to report on
connectivity and name resolution success/failure. For more information, read the blog at
https://www.undocumented-features.com/2018/02/10/aad-connect-network-and-name-resolution-test/
or check out the entire history at https://www.undocumented-features.com/tag/aadnetwork/.
 
.PARAMETER ActiveDirectory
Run Active Directory checks (Single Label Domain, NetBIOS domain,
AD Recycle Bin enabled, Forest Functional Level)
 
.PARAMETER AllTests
Run all tests with default settings (ActiveDirectory, AzureADCredentialCheck, OnlineEndpoints
with Commercial endpoints, Network, Dns, SystemConfiguration). Can also set a Boolean FALSE
for parameters.
 
.PARAMETER AzureCredentialCheck
Check the specified credential for Azure AD suitability (valid password, is a
member of global administrators).
 
.PARAMETER DCs
Use this parameter to specify DCs to test against. Required if running on-
premises network or DNS tests. This is auto-populated from the LOGONSERVER
environment variable. If the server is not joined to a domain, populate this
attribute with a DC for the domain/forest you will be configuration AAD Connect
against.
 
.PARAMETER DebugLogging
Enable debug error logging to log file.
 
.PARAMETER Dns
Use this parameter to only run on-premises Dns tests. Requires FQDN and DCs
parameters to be specified.
 
.PARAMETER FixedDcRpcPort
Use this optional parameter to specify a fixed Rpc port for DC communications.
See https://support.microsoft.com/en-us/help/224196/restricting-active-directory-rpc-traffic-to-a-specific-port
for more information.
 
.PARAMETER InstallModules
Use this parameter to install modules used during tests, including MSOnline,
NuGet, PowerShell Gallery, Install-Module, and the Remote Server Administration
Tools.
 
.PARAMETER Logfile
Self-explanatory.
 
.PARAMETER Network
Use this parameter to only run local network tests. Requires FQDN and DCs parameters
to be specified if they are not automatically populated. They may not be automatically
populated if the server running this tool has not been joined to a domain. That is a
supported configuration; however, you will need to specify a forest FQDN and at least
one DC.
 
.PARAMETER OnlineEndPoints
Use this parameter to conduct communication tests against online endpoints.
 
.PARAMETER OnlineEndPointTarget
Use this optional parameter to select GCC, Commercial, DOD, or GCC High environments.
 
.PARAMETER OptionalADPortTest
Use this optional parameter to specify ports that you may not need for communications.
While the public documentation says port 88 is required for Kerberos, it may not be used
in certain circumstances (such as adding an AD connector to a remote forest after AAD
connect has been intalled). Optional ports include:
- 88 (Kerberos)
- 636 (Secure LDAP)
- 3269 (Secure Global Catalog)
 
You can enable secure LDAP after the AAD Connect installation has completed.
 
.PARAMETER SkipDcDnsPortCheck
If you are not using DNS services provided by the AD Site / Logon DC, then you may want
to skip checking port 53. You must still be able to resolve ._ldap._tcp.<forestfqdn>
in order for the Active Directory Connector configuration to succeed.
 
.PARAMETER SystemConfiguration
Report on system configuration items, including installed Windows Features, TLS
registry entries and proxy configurations.
 
.EXAMPLE
.\AADConnect-CommunicationsTest.ps1
Runs all tests and writes to default log file location (YYYY-MM-DD_AADConnectivity.txt)
 
.EXAMPLE
.\AADConnect-CommunicationsTest.ps1 -Dns -Network
Runs Dns and Network tests and writes to default log file location (YYYY-MM-DD_AADConnectivity.txt).
 
.EXAMPLE
.\AADConnect-CommunicationsTest.ps1 -OnlineEndPoints -OnlineEndPointTarget DOD
Runs OnlineEndPoints test using the U.S. Department of Defense online endpoints list
and writes to default log file location (YYYY-MM-DD_AADConnectivity.txt).
 
.EXAMPLE
.\AADConnect-CommunicationsTest.ps1 -AzureCredentialCheck -Network -DCs dc1.contoso.com -ForestFQDN contoso.com
Runs Azure Credential Check and local networking tests using DC dc1.contoso.com and
the forest contoso.com and writes to the default log file location
(YYYY-MM-DD_AADConnectivity.txt).
 
.EXAMPLE
.\AADConnect-CommunicationsTest.ps1 -AllTests -Network:$false
Run All system tests using defaults, excluding Network tests.
 
.LINK
https://www.undocumented-features.com/2018/02/10/aad-connect-network-and-name-resolution-test/
 
.LINK
https://aka.ms/aadnetwork
 
.NOTES
- 2020-04-29 Updated DOD/GCCH endpoints.
                Added check for RODCs in current site.
- 2020-04-03 Rebranded as v4 and uploaded to PowerShellGallery.com
- 2020-01-28 Updated endpoints.
                Updated to retrieve Azure AD Tenant ID for checking <tenantid>.registration.appproxy.net.
                Added Windows2016Forest forest mode to system configuration function.
                Cleaned up some error handling.
- 2019-05-07 Updated to skip ActiveDirectory checks if ForestFQDN and DCs values are empty and can't be calculated.
                Updated logging for desktop/client versions in System Configuration.
- 2019-03-13 Resolved issue with Azure credential check not running automatically.
                Resolved issue with Azure credential not displaying the user identity.
                Resolved issue with 'optional' network services testing in OnlineEndPoints test.
- 2019-03-12 Restructured how parameters are processed using PSBoundParameters.
                Removed SkipAzureADCredentialCheck parameter.
                Added additional error trapping around Resolve-DnsName.
                Refreshed endpoints for AAD.
                Added AllTests parameter. AllTests also supports setting specific tests to Boolean FALSE.
- 2018-10-28 Updated InstallModules param checking.
- 2018-10-24 Initial release checking RSOP data for PowerShell Transcription GPO.
- 2018-09-14 Added check for installation edition (server, server core, client, nano) based on https://docs.microsoft.com/en-us/windows/desktop/CIMWin32Prov/win32-operatingsystem.
- 2018-08-30 Added -InstallModules switch.
- 2018-07-30 Removed single-label domain references.
- 2018-07-23 Added supported AD forest modes in System Configruation.
                Added AD Recycle Bin configuration check.
                Added ActiveDirectory parameter.
- 2018-07-17 Updated Commerical/GCC endpoints:
                $CRL += http://ocsp.msocsp.com
                $RequiredResources += adminwebservice-s1-co2.microsoftonline.com
                $RequiredResourcesEndpoints += https://adminwebservice-s1-co2.microsoftonline.com/provisioningwebservice.svc
- 2018-06-15 Fixed Windows 2016 detection display issue.
                 Fixed issue querying PowerShell Transcription.
- 2018-06-14 Updated query for system.net/defaultproxy/proxy.
                Added reg key for Wow6432Node/SchUseStrongCrypto for TLS 1.2.
                Added OS-specific support for determining .NET versions.
                Added OS-specific registry keys to test for TLS 1.2 configuration.
- 2018-04-05 Removed proxy.cloudwebappproxy.net from Seamless SSO endpoint test.
- 2018-04-03 Updated endpoints for Seamless SSO.
- 2018-04-03 Added endpoints management.core.windows.net, s1.adhybridhealth.azure.com
- 2018-04-02 Added endpoints for Seamless SSO.
- 2018-02-16 Added optional port for Secure Global Catalog (3269)
- 2018-02-14 Added FixedDcRpcPort, OptionalADPortTest, SystemConfiguration parameters
- 2018-02-14 Added test for servicebus.windows.net to online endpoints
- 2018-02-14 Expanded system configuration tests to capture TLS 1.2 configuration
- 2018-02-14 Expanded system configuration tests to capture required server features
- 2018-02-13 Added OnlineEndPointTarget parameter for selecting Commercial, GCC, DOD, or GCC high.
- 2018-02-13 Added proxy config checks.
- 2018-02-12 Added additional CRL/OCSP endpoints for Entrust and Verisign.
- 2018-02-12 Added additional https:// test endpoints.
- 2018-02-12 Added DebugLogging parameter and debug logging data.
- 2018-02-12 Added extended checks for online endpoints.
- 2018-02-12 Added check for Azure AD credential (valid/invalid password, is Global Admin)
- 2018-02-12 Updated parameter check when running new mixes of options.
- 2018-02-11 Added default values for ForestFQDN and DCs.
- 2018-02-11 Added SkipDcDnsPortCheck parameter.
- 2018-02-10 Resolved issue where tests would run twice under some conditions.
- 2018-02-09 Initial release.
#>

param (
    [switch]$ActiveDirectory,
    [switch]$AllTests,
    [switch]$AzureCredentialCheck,
    [Parameter(HelpMessage="Specify the azure credential to check in the form of user@domain.com or user@tenant.onmicrosoft.com")]$Credential,
    [array]$DCs, 
    [switch]$DebugLogging,
    [switch]$Dns,
    [int]$FixedDcRpcPort,
    [string]$ForestFQDN,
    [switch]$InstallModules,
    [string]$Logfile = (Get-Date -Format yyyy-MM-dd) + "_AADConnectConnectivity.txt",
    [switch]$Network,
    [switch]$OnlineEndPoints,
    [ValidateSet("Commercial","DOD","GCC","GCCHigh")]
    [string]$OnlineEndPointTarget = "Commercial",
    [switch]$OptionalADPortTest,
    [ValidateSet("PasswordWriteBack")][string[]]$OptionalFeatureCheck,
    [switch]$SkipDcDnsPortCheck,
    [switch]$SystemConfiguration
)

$Version = "4.0"
# Hide the test-netconnection progress meter
$ExistingProgressPreference = $ProgressPreference
$global:ProgressPreference = 'SilentlyContinue'

# If no DCs are supplied and no LOGON server value is available, then set
# $ActiveDirectory to $false and exclude ActiveDirectory from executed tests
If (!$DCs)
{
    If ($env:LOGONSERVER -and $env:USERDNSDOMAIN)
    {
        $DCs = (Get-ChildItem Env:\Logonserver).Value.ToString().Trim("\") + "." + (Get-ChildItem Env:\USERDNSDOMAIN).Value.ToString()
    }
    Else
    {
        $ActiveDirectory = $false
    }
}

# If no ForestFQDN is supplied, check for it. If UserDnsDomain isn't populated,
# set $ActiveDirectory to $false and exclude ActiveDirectory from executed tasks
If (!$ForestFQDN)
{
    If ($env:USERDNSDOMAIN)
    {
        $ForestFQDN = (Get-ChildItem Env:\USERDNSDOMAIN).Value.ToString()
    }
    Else
    {
        $ActiveDirectory = $false
    }
}

## Functions
# Logging function
function Write-Log([string[]]$Message, [string]$LogFile = $Script:LogFile, [switch]$ConsoleOutput, [ValidateSet("SUCCESS", "INFO", "WARN", "ERROR", "DEBUG")][string]$LogLevel)
{
    $Message = $Message + $Input
    If (!$LogLevel) { $LogLevel = "INFO" }
    switch ($LogLevel)
    {
        SUCCESS { $Color = "Green" }
        INFO { $Color = "White" }
        WARN { $Color = "Yellow" }
        ERROR { $Color = "Red" }
        DEBUG { $Color = "Gray" }
    }
    if ($Message -ne $null -and $Message.Length -gt 0)
    {
        $TimeStamp = [System.DateTime]::Now.ToString("yyyy-MM-dd HH:mm:ss")
        if ($LogFile -ne $null -and $LogFile -ne [System.String]::Empty)
        {
            Out-File -Append -FilePath $LogFile -InputObject "[$TimeStamp] [$LogLevel] $Message"
        }
        if ($ConsoleOutput -eq $true)
        {
            Write-Host "[$TimeStamp] [$LogLevel] :: $Message" -ForegroundColor $Color
        }
    }
}

# Test Office 365 Credentials
function AzureCredential
{
    If ($SkipAzureCredentialCheck) { "Skipping Azure AD Credential Check due to parameter.";  Continue}
    Write-Log -LogFile $Logfile -LogLevel INFO -Message "Starting Office 365 global administrator and credential tests."
    If (!$Credential)
    {
        #Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Credential required to validate Office 365 credentials. Enter global admin credential."
        $Credential = Get-Credential -Message "Office 365 Global Administrator"
    }
    # Attempt MSOnline installation
    Try
    {
        MSOnline
    }
    Catch
    {
        Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Unable to proceed with MSOnline check. Please install the Microsoft Online Services Module separately and re-run the script." -ConsoleOutput
        
    }
    
    # Attempt to log on as user
    try
    {
        Write-Log -LogFile $Logfile -LogLevel INFO -Message "Attempting logon as $($Credential.UserName) to Azure Active Directory."
        $LogonResult = Connect-MsolService -Credential $Credential -ErrorAction Stop
        If ($LogonResult -eq $null)
        {
            Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "Successfully logged on to Azure Active Directory as $($Credential.UserName)." -ConsoleOutput
            ## Attempt to check membership in Global Admins, which is labelled as "Company Administrator" in the tenant
            $RoleId = (Get-MsolRole -RoleName "Company Administrator").ObjectId
            If ((Get-MsolRoleMember -RoleObjectId $RoleId).EmailAddress -match "\b$($Credential.UserName)")
            {
                Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "User $($Credential.Username) is a member of Global Administrators." -ConsoleOutput
            }
            Else
            {
            Write-Log -LogFile $Logfile -LogLevel ERROR -Message "User $($Credential.UserName) is not a member of Global Administrators. In order for Azure Active Directory synchronization to be successful, the user must have the Global Administrators role granted in Office 365. Grant the appropriate access or select another user account to test."        
            }
        }
        Else
        {
            #Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Unable to verify logon to Azure Active Directory as $($Credential.UserName)." -ConsoleOutput        
        }
    }
    catch
    {
        #Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Unable to log on to Azure Active Directory as $($Credential.UserName). Check $($Logfile) for additional details." -ConsoleOutput
        #Write-Log -LogFile $Logfile -LogLevel ERROR -Message "$($_.Exception.Message)"
    }
    
    # Attempt to get Tenant ID
    If (Get-Module AzureAD -ListAvailable -erroraction silentlycontinue)
    { try
        {
            Import-Module AzureAD
            $AADLogonResult = Connect-AzureAD $Credential -ErrorAction Stop
            if ($AADLogonResult.TenantID) { $TenantID = "$($AADLogonResult.TenantId).registration.msappproxy.net" }
        }
        catch
        {
            #Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Exception while attempting to log onto Azure AD. Exception data:"
            #Write-Log -LogFile $Logfile -LogLevel ERROR -Message "$($_.Exception.Message)"
        }
    }
} # End Function AzureCredential

# Test for/install MSOnline components
function MSOnline
{
    Write-Log -LogFile $Logfile -LogLevel INFO -Message "Checking Microsoft Online Services Module."
    If (!(Get-Module -ListAvailable MSOnline -erroraction silentlycontinue) -and $InstallModules)
    {
        # Check if Elevated
        $wid = [system.security.principal.windowsidentity]::GetCurrent()
        $prp = New-Object System.Security.Principal.WindowsPrincipal($wid)
        $adm = [System.Security.Principal.WindowsBuiltInRole]::Administrator
        if ($prp.IsInRole($adm))
        {
            Write-Log -LogFile $Logfile -LogLevel SUCCESS -ConsoleOutput -Message "Elevated PowerShell session detected. Continuing."
        }
        else
        {
            Write-Log -LogFile $Logfile -LogLevel ERROR -ConsoleOutput -Message "This application/script must be run in an elevated PowerShell window. Please launch an elevated session and try again."
            Break
        }
        
        Write-Log -LogFile $Logfile -LogLevel INFO -ConsoleOutput -Message "This requires the Microsoft Online Services Module. Attempting to download and install."
        wget https://download.microsoft.com/download/5/0/1/5017D39B-8E29-48C8-91A8-8D0E4968E6D4/en/msoidcli_64.msi -OutFile $env:TEMP\msoidcli_64.msi
        If (!(Get-Command Install-Module))
        {
            wget https://download.microsoft.com/download/C/4/1/C41378D4-7F41-4BBE-9D0D-0E4F98585C61/PackageManagement_x64.msi -OutFile $env:TEMP\PackageManagement_x64.msi
        }
        If ($DebugLogging) { Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Installing Sign-On Assistant." }
        msiexec /i $env:TEMP\msoidcli_64.msi /quiet /passive
        If ($DebugLogging) { Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Installing PowerShell Get Supporting Libraries." }
        msiexec /i $env:TEMP\PackageManagement_x64.msi /qn
        If ($DebugLogging) { Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Installing PowerShell Get Supporting Libraries (NuGet)." }
        Install-PackageProvider -Name Nuget -MinimumVersion 2.8.5.201 -Force -Confirm:$false
        If ($DebugLogging) { Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Installing Microsoft Online Services Module." }
        Install-Module MSOnline -Confirm:$false -Force
        If (!(Get-Module -ListAvailable MSOnline))
        {
            Write-Log -LogFile $Logfile -LogLevel ERROR -ConsoleOutput -Message "This Configuration requires the MSOnline Module. Please download from https://connect.microsoft.com/site1164/Downloads/DownloadDetails.aspx?DownloadID=59185 and try again."
            
            Break
        }
    }
    If (Get-Module -ListAvailable MSOnline) { Import-Module MSOnline -Force }
    Else { Write-Log -LogFile $Logfile -LogLevel ERROR -ConsoleOutput -Message "This Configuration requires the MSOnline Module. Please download from https://connect.microsoft.com/site1164/Downloads/DownloadDetails.aspx?DownloadID=59185 and try again." }
    
    # Check for Azure AD Module
    Write-Log -LogFile $Logfile -LogLevel INFO -Message "Checking for Microsoft Azure AD Module."
    if (!($Result = Get-Module -ListAvailable AzureAD))
    {
        try
        {
            Write-Log -LogFile $Logfile -LogLevel INFO -Message "Attempting to install Azure AD Module."
            Install-Module AzureAD -Force -SkipPublisherCheck -erroraction stop
        }
        catch { Write-Log -LogFile $Logfile -Message $_.Exception.Message.ToString() -LogLevel ERROR }
    }
    Write-Log -LogFile $Logfile -LogLevel INFO -Message "Finished Microsoft Online Service Module check."
} # End Function MSOnline

# Test Online Networking Only
function OnlineEndPoints
{
    switch -regex ($OnlineEndPointTarget)
    {
        'commercial|gcc'
        {
            Write-Log -LogFile $Logfile -LogLevel INFO -Message "Starting Online Endpoints tests (Commercial/GCC)."
            Write-Log -LogFile $Logfile -LogLevel INFO -Message "See https://support.office.com/en-us/article/office-365-urls-and-ip-address-ranges-8548a211-3fe7-47cb-abb1-355ea5aa88a2"
            Write-Log -LogFile $Logfile -LogLevel INFO -Message "for more details on Commercial/GCC endpoints."
            $CRL = @(
                "http://ocsp.msocsp.com",
                "http://crl.microsoft.com/pki/crl/products/microsoftrootcert.crl",
                "http://mscrl.microsoft.com/pki/mscorp/crl/msitwww2.crl",
                "http://ocsp.verisign.com",
                "http://ocsp.entrust.net")
            $RequiredResources = @(
                "management.azure.com",
                "policykeyservice.dc.ad.msft.net",
                "adhsprodwusehsyncia.servicebus.windows.net",
                "adhsprodwusaadsynciadata.blob.core.windows.net",
                "adhsprodwusaadsynciadata.blob.core.windows.net",
                "aadcdn.msauthimages.net",
                "aadcdn.msauth.net",
                "ssprdedicatedsbprodscu.servicebus.windows.net",
                "passwordreset.microsoftonline.com",
                "prdf.aadg.msidentity.com",
                "www.tm.f.prd.aadg.trafficmanager.net",
                "adminwebservice.microsoftonline.com",
                #"adminwebservice-s1-co2.microsoftonline.com", # Removed 2020-01-28
                "login.microsoftonline.com",
                "provisioningapi.microsoftonline.com",
                "login.windows.net",
                "secure.aadcdn.microsoftonline-p.com",
                "management.core.windows.net",
                #"bba800-anchor.microsoftonline.com", # Removed 2020-01-28
                "graph.windows.net",
                "aadcdn.msauth.net",
                "aadcdn.msftauth.net",
                "ccscdn.msauth.net",
                "ccscdn.msftauth.net",
                "becws.microsoftonline.com", # added 2020-01-28
                "api.passwordreset.microsoftonline.com" # Self-service Password Reset, added 2020-01-28
                )
            $RequiredResourcesEndpoints = @(
                "https://adminwebservice.microsoftonline.com/provisioningservice.svc",
                 "https://passwordreset.microsoftonline.com",
                "https://ssprdedicatedsbprodscu.servicebus.windows.net",
                # "https://adminwebservice-s1-co2.microsoftonline.com/provisioningservice.svc", # Removed 2020-01-28
                "https://login.microsoftonline.com",
                "https://provisioningapi.microsoftonline.com/provisioningwebservice.svc",
                "https://login.windows.net",
                "https://secure.aadcdn.microsoftonline-p.com/ests/2.1.5975.9/content/cdnbundles/jquery.1.11.min.js"
                )
            $OptionalResources = @(
                "s1.adhybridhealth.azure.com",
                "autoupdate.msappproxy.net",
                "adds.aadconnecthealth.azure.com",
                "account.activedirectory.windowsazure.com", # myapps portal, added 2020-01-28
                "enterpriseregistration.windows.net", # device registration
                "clientconfig.microsoftonline-p.net" #added 2020-01-28
                )
            $OptionalResourcesEndpoints = @(
                "https://ssprdedicatedsbprodscu.servicebus.windows.net",
                "https://policykeyservice.dc.ad.msft.net/clientregistrationmanager.svc",
                "https://device.login.microsoftonline.com" # Hybrid device registration
            )
            $SeamlessSSOEndpoints = @(
                "autologon.microsoftazuread-sso.com",
                "aadg.windows.net.nsatc.net",
                "0.register.msappproxy.net",
                "0.registration.msappproxy.net",
                "proxy.cloudwebappproxy.net"
            )
            # Tenant Registration Endpoint
            If ($TenantID) { $SeamlessSSOEndpoints += $Tenant } # Added 2020-01-28
            # Use the AdditionalResources array to specify items that need a port test on a port other
            # than 80 or 443.
            $AdditionalResources = @(
                # "watchdog.servicebus.windows.net:5671" # Removed 2020-01-28
                )
        }
        
        'dod|gcchigh'
        {
            Write-Log -LogFile $Logfile -LogLevel INFO -Message "Starting Online Endpoints tests (DOD)."
            Write-Log -LogFile $Logfile -LogLevel INFO -Message "See https://support.office.com/en-us/article/office-365-u-s-government-dod-endpoints-5d7dce60-4892-4b58-b45e-ee42fe8a907f"
            Write-Log -LogFile $Logfile -LogLevel INFO -Message "for more details on DOD/GCCHigh endpoints."
            $CRL = @(
                "http://ocsp.msocsp.com",
                "https://mscrl.microsoft.com/pki/mscorp/crl/msitwww2.crl",
                "http://crl.microsoft.com/pki/crl/products/microsoftrootcert.crl",
                "http://ocsp.verisign.com",
                "http://ocsp.entrust.net")
            $RequiredResources = @(
                "adhsprodwusaadsynciadata.blob.core.windows.net",
                "prdf.aadg.msidentity.com",
                "www.tm.f.prd.aadg.trafficmanager.net",
                "www.tm.f.prd.aadg.trafficmanager.net",
                "aadcdn.msauthimages.net",
                "aadcdn.msauth.net",
                "ssprdedicatedsbprodscu.servicebus.windows.net",
                "passwordreset.microsoftonline.com",
                "adminwebservice.microsoftonline.com",
                "adminwebservice.gov.us.microsoftonline.com",
                "adminwebservice-s1-bn1a.microsoftonline.com",
                "becws.gov.us.microsoftonline.com," # added 2020-01-28
                "dod-graph.microsoft.us", # added 2020-01-28
                "adminwebservice-s1-dm2a.microsoftonline.com",
                "graph.microsoftazure.us", # added 2020-01-28
                "login.microsoftonline.us",
                "login.microsoftonline.com",
                "login.microsoftonline-p.com",
                "loginex.microsoftonline.com",
                "login-us.microsoftonline.com",
                "login.windows.net",
                "graph.windows.net",
                "aadcdn.msauth.net", # have not verified
                "aadcdn.msftauth.net", # have not verified
                "ccscdn.msauth.net", # have not verified
                "ccscdn.msftauth.net", # have not verified
                "provisioningapi.gov.us.microsoftonline.com",
                "provisioningapi-s1-dm2a.microsoftonline.com",
                "provisioningapi-s1-dm2r.microsoftonline.com",
                "secure.aadcdn.microsoftonline-p.com",
                "clientconfig.microsoftonline-p.net" # added 2020-01-28
            )
            $RequiredResourcesEndpoints = @(
                "https://adminwebservice.gov.us.microsoftonline.com/provisioningservice.svc",
                "https://adminwebservice-s1-bn1a.microsoftonline.com/provisioningservice.svc",
                "https://adminwebservice-s1-dm2a.microsoftonline.com/provisioningservice.svc",
                "https://login.microsoftonline.us"
                "https://login.microsoftonline.com",
                "https://loginex.microsoftonline.com",
                "https://login-us.microsoftonline.com",
                "https://login.windows.net",
                "https://passwordreset.microsoftonline.com",
                "https://ssprdedicatedsbprodscu.servicebus.windows.net",
                "https://provisioningapi.gov.us.microsoftonline.com/provisioningwebservice.svc",
                "https://provisioningapi-s1-dm2a.microsoftonline.com/provisioningwebservice.svc",
                "https://provisioningapi-s1-dm2r.microsoftonline.com/provisioningwebservice.svc"

                "https://secure.aadcdn.microsoftonline-p.com/ests/2.1.5975.9/content/cdnbundles/jquery.1.11.min.js")
            # These optional endpoints are newly listed for DOD/GCCHigh
            $OptionalResources = @(
                "management.azure.com", 
                "policykeyservice.aadcdi.azure.us" # Azure AD Connect Health
                # ,"enterpriseregistration.windows.net" # Not currently listed for DOD/GCCH
            )
            
            $OptionalResourcesEndpoints = @(
                "https://policykeyservice.aadcdi.azure.us/clientregistrationmanager.svc" # Azure AD Connect Health
                # ,"https://enterpriseregistration.windows.net" # Not currently listed for DOD/GCCH
            )
            # Use the AdditionalResources array to specify items that need a port test on a port other
            # than 80 or 443.
            $AdditionalResources = @(
                # "watchdog.servicebus.windows.net:5671" # ServiceBus endpoints no longer needed
                )
            #>
        }
    }
    
    # CRL Endpoint tests
    Write-Log -LogFile $Logfile -LogLevel INFO -Message "Testing CRL endpoint tests (Invoke-WebRequest)." -ConsoleOutput
    foreach ($url in $CRL)
    {
        try
        {
            $Result = Invoke-WebRequest -Uri $url -erroraction stop -wa silentlycontinue
            Switch ($Result.StatusCode)
            {
                200 { Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "Successfully obtained CRL from $($url)." -ConsoleOutput }
                400 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to obtain CRL from $($url): Bad request." -ConsoleOutput;  }
                401 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to obtain CRL from $($url): Unauthorized." -ConsoleOutput;  }
                403 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to obtain CRL from $($url): Forbidden." -ConsoleOutput;  }
                404 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to obtain CRL from $($url): Not found." -ConsoleOutput;  }
                407 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to obtain CRL from $($url): Proxy authentication required." -ConsoleOutput;  }
                502 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to obtain CRL from $($url): Bad gateway (likely proxy)." -ConsoleOutput;  }
                503 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to obtain CRL from $($url): Service unavailable (transient, try again)." -ConsoleOutput;  }
                504 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to obtain CRL from $($url): Gateway timeout (likely proxy)." -ConsoleOutput;  }
                default
                {
                    Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Unable to obtain CRL from $($url)" -ConsoleOutput
                    Write-Log -LogFile $Logfile -LogLevel ERROR -Message "$($Result)"            
                }
            }
        }
        catch
        {
            Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Exception: Unable to obtain CRL from $($url)" -ConsoleOutput
            Write-Log -LogFile $Logfile -LogLevel ERROR -Message "$($_.Exception.Message)"
        }
        finally
        {
            If ($DebugLogging)
            {
                Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Debug log entry for $($url)."
                Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $Result.StatusCode
                Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $Result.StatusDescription
                If ($Result.RawContent.Length -lt 400)
                {
                    $DebugContent = $Result.RawContent -join ";"
                    Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $DebugContent
                }
                Else
                {
                    $DebugContent = $Result.RawContent.Substring(0, 400) -join ";"
                    Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $DebugContent
                }
            }
        }
    } # End Foreach CRL
        
    # Required Resource tests
    Write-Log -LogFile $Logfile -LogLevel INFO -Message "Testing Required Resources (TCP:443)." -ConsoleOutput
    foreach ($url in $RequiredResources)
    {
        try { [array]$ResourceAddresses = (Resolve-DnsName $url -ErrorAction stop).IP4Address }
        catch { $ErrorMessage = $_;  Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Unable to resolve host $($url)." -ConsoleOutput; Write-Log -LogFile $Logfile -LogLevel ERROR -Message $($ErrorMessage); Continue }
        foreach ($ip4 in $ResourceAddresses)
        {
            try
            {
                $timestart = get-date 
                $Result443 = Test-NetConnection $ip4 -Port 443 -erroraction stop -wa silentlycontinue
                $timeend = get-date 
                $totaltime = $timeend - $timestart
                $totaltimeseconds = $totaltime.TotalSeconds

                if($Result443.TcpTestSucceeded -eq "True")
                {
                #switch ($Result443.TcpTestSucceeded)
                
                    Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "TCP connection to $($url) [$($ip4)]:443 successful. Taking : $totaltimeseconds : seconds to complete" -ConsoleOutput 
                }
                else
                {
                    Write-Log -LogFile $Logfile -LogLevel ERROR -Message "TCP connection to $($url) [$($ip4)]:443 failed." -ConsoleOutput
                }
                
                
                
                $timestart = get-date 
                $Result80 = Test-NetConnection $ip4 -Port 80 -erroraction stop -wa silentlycontinue
                $timeend = get-date 
                $totaltime = $timeend - $timestart
                $totaltimeseconds = $totaltime.TotalSeconds                
                
                if ($Result80.TcpTestSucceeded -eq "True")
                {
                    $message = 
                     Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "TCP connection to $($url) [$($ip4)]:80 successful. Taking : $totaltimeseconds : seconds to complete" -ConsoleOutput 
                }
                else
                {
                     Write-Log -LogFile $Logfile -LogLevel ERROR -Message "TCP connection to $($url) [$($ip4)]:80 failed." -ConsoleOutput
                }

            }
            catch
            {
                Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Error resolving or connecting to $($url) [$($ip4)]:443" -ConsoleOutput
                Write-Log -LogFile $Logfile -LogLevel ERROR -Message "$($_.Exception.Message)"
            }
            finally
            {
                If ($DebugLogging)
                {
                    Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Debug log entry for $($url) [$($Result.RemoteAddress)]:443."
                    Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Remote endpoint: $($url)"
                    Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Remote port: $($Result.RemotePort)"
                    Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Interface Alias: $($Result.InterfaceAlias)"
                    Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Source Interface Address: $($Result.SourceAddress.IPAddress)"
                    Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Succeeded: $($Result.PingSucceeded)"
                    Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Reply Time (RTT) Status: $($Result.PingReplyDetails.Status)"
                    Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Reply Time (RTT) RoundTripTime: $($Result.PingReplyDetails.RoundtripTime)"
                    Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "TCPTestSucceeded: $($Result.TcpTestSucceeded)"
                }
            }
        } 
    } # End Foreach Resources
        
    # Option Resources tests
    Write-Log -LogFile $Logfile -LogLevel INFO -Message "Testing Optional Resources (TCP:443)." -ConsoleOutput
    foreach ($url in $OptionalResources)
    {
        try { [array]$ResourceAddresses = (Resolve-DnsName $url -ErrorAction stop).IP4Address }
        catch { $ErrorMessage = $_; Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Unable to resolve host $($url)." -ConsoleOutput; Write-Log -LogFile $Logfile -LogLevel ERROR -Message $($ErrorMessage); Continue }
        
        foreach ($ip4 in $ResourceAddresses)
        {
            try
            {
$timestart = get-date 
                $Result443 = Test-NetConnection $ip4 -Port 443 -erroraction stop -wa silentlycontinue
                $timeend = get-date 
                $totaltime = $timeend - $timestart
                $totaltimeseconds = $totaltime.TotalSeconds

                if($Result443.TcpTestSucceeded -eq "True")
                {
                #switch ($Result443.TcpTestSucceeded)
                
                    Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "TCP connection to $($url) [$($ip4)]:443 successful. Taking : $totaltimeseconds : seconds to complete" -ConsoleOutput 
                }
                else
                {
                    Write-Log -LogFile $Logfile -LogLevel ERROR -Message "TCP connection to $($url) [$($ip4)]:443 failed." -ConsoleOutput
                }
                $timestart = get-date 
                $Result80 = Test-NetConnection $ip4 -Port 80 -erroraction stop -wa silentlycontinue
                $timeend = get-date 
                $totaltime = $timeend - $timestart
                $totaltimeseconds = $totaltime.TotalSeconds  
                if ($Result80.TcpTestSucceeded -eq "True")
                {
                    $message = 
                     Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "TCP connection to $($url) [$($ip4)]:80 successful. Taking : $totaltimeseconds : seconds to complete" -ConsoleOutput 
                }
                else
                {
                     Write-Log -LogFile $Logfile -LogLevel ERROR -Message "TCP connection to $($url) [$($ip4)]:80 failed." -ConsoleOutput
                }
            }
            catch
            {
                Write-Log -LogFile $Logfile -LogLevel WARN -Message "Error resolving or connecting to $($url) [$($ip4)]:443" -ConsoleOutput
                Write-Log -LogFile $Logfile -LogLevel WARN -Message "$($_.Exception.Message)"
            }
            finally
            {
                If ($DebugLogging)
                {
                    Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Debug log entry for $($url) [$($Result.RemoteAddress)]:443."
                    Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Remote endpoint: $($url)"
                    Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Remote port: $($Result.RemotePort)"
                    Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Interface Alias: $($Result.InterfaceAlias)"
                    Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Source Interface Address: $($Result.SourceAddress.IPAddress)"
                    Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Succeeded: $($Result.PingSucceeded)"
                    Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Reply Time (RTT) Status: $($Result.PingReplyDetails.Status)"
                    Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Reply Time (RTT) RoundTripTime: $($Result.PingReplyDetails.RoundtripTime)"
                    Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "TCPTestSucceeded: $($Result.TcpTestSucceeded)"
                }
            }
        }
    } # End Foreach OptionalResources
        
    # Required Resources Endpoints tests
    Write-Log -LogFile $Logfile -LogLevel INFO -Message "Testing Required Resources Endpoints (Invoke-Webrequest)." -ConsoleOutput
    foreach ($url in $RequiredResourcesEndpoints)
    {
        try
        {
            $Result = Invoke-WebRequest -Uri $url -erroraction stop -wa silentlycontinue
            Switch ($Result.StatusCode)
            {
                200 { Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "Successfully connected to $($url)." -ConsoleOutput }
                400 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Bad request." -ConsoleOutput;  }
                401 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Unauthorized." -ConsoleOutput;  }
                403 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Forbidden." -ConsoleOutput;  }
                404 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Not found." -ConsoleOutput;  }
                407 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Proxy authentication required." -ConsoleOutput;  }
                502 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Bad gateway (likely proxy)." -ConsoleOutput;  }
                503 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Service unavailable (transient, try again)." -ConsoleOutput;  }
                504 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Gateway timeout (likely proxy)." -ConsoleOutput;  }
                default
                {
                    Write-Log -LogFile $Logfile -LogLevel ERROR -Message "OTHER: Failed to contact $($url)" -ConsoleOutput
                    Write-Log -LogFile $Logfile -LogLevel ERROR -Message "$($Result)" -ConsoleOutput            
                }
            }
        }
        catch
        {
            Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Exception: Unable to contact $($url)" -ConsoleOutput
            Write-Log -LogFile $Logfile -LogLevel ERROR -Message "$($_.Exception.Message)"
        }
        finally
        {
            If ($DebugLogging)
            {
                Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Debug log entry for $($url)."
                Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $Result.StatusCode
                Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $Result.StatusDescription
                If ($Result.RawContent.Length -lt 400)
                {
                    $DebugContent = $Result.RawContent -join ";"
                    Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $DebugContent
                }
                Else
                {
                    $DebugContent = $Result.RawContent -join ";"
                    Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $DebugContent.Substring(0, 400)
                }
            }
        }
    } # End Foreach RequiredResourcesEndpoints
    
    # Optional Resources Endpoints tests
    Write-Log -LogFile $Logfile -LogLevel INFO -Message "Testing Optional Resources Endpoints (Invoke-Webrequest)." -ConsoleOutput
    foreach ($url in $OptionalResourcesEndpoints)
    {
        try
        {
            $Result = Invoke-WebRequest -Uri $url -erroraction stop -wa silentlycontinue
            Switch ($Result.StatusCode)
            {
                200 { Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "Successfully connected to $($url)." -ConsoleOutput }
                400 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Bad request." -ConsoleOutput;  }
                401 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Unauthorized." -ConsoleOutput;  }
                403 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Forbidden." -ConsoleOutput;  }
                404 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Not found." -ConsoleOutput;  }
                407 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Proxy authentication required." -ConsoleOutput;  }
                502 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Bad gateway (likely proxy)." -ConsoleOutput;  }
                503 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Service unavailable (transient, try again)." -ConsoleOutput;  }
                504 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Failed to contact $($url): Gateway timeout (likely proxy)." -ConsoleOutput;  }
                default
                {
                    Write-Log -LogFile $Logfile -LogLevel ERROR -Message "OTHER: Failed to contact $($url)" -ConsoleOutput
                    Write-Log -LogFile $Logfile -LogLevel ERROR -Message "$($Result)" -ConsoleOutput
                }
            }
        }
        catch
        {
            Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Exception: Unable to contact $($url)" -ConsoleOutput
            Write-Log -LogFile $Logfile -LogLevel ERROR -Message "$($_.Exception.Message)"
        }
        finally
        {
            If ($DebugLogging)
            {
                Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Debug log entry for $($url)."
                Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $Result.StatusCode
                Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $Result.StatusDescription
                If ($Result.RawContent.Length -lt 400)
                {
                    $DebugContent = $Result.RawContent -join ";"
                    Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $DebugContent
                }
                Else
                {
                    $DebugContent = $Result.RawContent -join ";"
                    Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $DebugContent.Substring(0, 400)
                }
            }
        }
    } # End Foreach RequiredResourcesEndpoints
        
    # Seamless SSO Endpoints
    Write-Log -LogFile $Logfile -LogLevel INFO -Message "Testing Seamless SSO Endpoints (TCP:443 and 80)." -ConsoleOutput
    foreach ($url in $SeamlessSSOEndpoints)
    {
        try
        {
            [array]$ResourceAddresses = (Resolve-DnsName $url -ErrorAction stop).IP4Address
        }
        catch
        {
            Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Unable to resolve host $($url)." -ConsoleOutput
            Write-Log -LogFile $Logfile -LogLevel ERROR -Message "$($_.Exception.Message)"
            Continue
        }
        
        foreach ($ip4 in $ResourceAddresses)
        {
            try
            {
                $timestart = get-date 
                $Result443 = Test-NetConnection $ip4 -Port 443 -erroraction stop -wa silentlycontinue
                $timeend = get-date 
                $totaltime = $timeend - $timestart
                $totaltimeseconds = $totaltime.TotalSeconds

                if($Result443.TcpTestSucceeded -eq "True")
                {
                #switch ($Result443.TcpTestSucceeded)
                
                    Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "TCP connection to $($url) [$($ip4)]:443 successful. Taking : $totaltimeseconds : seconds to complete" -ConsoleOutput 
                }
                else
                {
                    Write-Log -LogFile $Logfile -LogLevel ERROR -Message "TCP connection to $($url) [$($ip4)]:443 failed." -ConsoleOutput
                }
                $timestart = get-date 
                $Result80 = Test-NetConnection $ip4 -Port 80 -erroraction stop -wa silentlycontinue
                $timeend = get-date 
                $totaltime = $timeend - $timestart
                $totaltimeseconds = $totaltime.TotalSeconds  
                if ($Result80.TcpTestSucceeded -eq "True")
                {
                    $message = 
                     Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "TCP connection to $($url) [$($ip4)]:80 successful. Taking : $totaltimeseconds : seconds to complete" -ConsoleOutput 
                }
                else
                {
                     Write-Log -LogFile $Logfile -LogLevel ERROR -Message "TCP connection to $($url) [$($ip4)]:80 failed." -ConsoleOutput
                }
            }
            catch
            {
                Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Error resolving or connecting to $($url) [$($ip4)]:443" -ConsoleOutput
                Write-Log -LogFile $Logfile -LogLevel ERROR -Message "$($_.Exception.Message)"
                
            }
            finally
            {
                If ($DebugLogging)
                {
                    Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Debug log entry for $($url) [$($Result.RemoteAddress)]:443."
                    Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Remote endpoint: $($url)"
                    Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Remote port: $($Result.RemotePort)"
                    Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Interface Alias: $($Result.InterfaceAlias)"
                    Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Source Interface Address: $($Result.SourceAddress.IPAddress)"
                    Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Succeeded: $($Result.PingSucceeded)"
                    Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Reply Time (RTT) Status: $($Result.PingReplyDetails.Status)"
                    Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Reply Time (RTT) RoundTripTime: $($Result.PingReplyDetails.RoundtripTime)"
                    Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "TCPTestSucceeded: $($Result.TcpTestSucceeded)"
                }
            }
        }
    } # End Foreach Resources
        
    # Additional Resources tests
    If ($AdditionalResources)
    {
        Write-Log -LogFile $Logfile -LogLevel INFO -Message "Testing Additional Resources Endpoints (Invoke-Webrequest)." -ConsoleOutput
        foreach ($url in $AdditionalResources)
        {
            if ($url -match "\:")
            {
                $Name = $url.Split(":")[0]
                try { [array]$Resources = (Resolve-DnsName $Name -ErrorAction stop).IP4Address }
                catch
                {
                    Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Unable to resolve host $($Name)." -ConsoleOutput
                    Write-Log -LogFile $Logfile -LogLevel ERROR -Message "$($_.Exception.Message)"
                    Continue }
                
                #[array]$Resources = (Resolve-DnsName $Name).Ip4Address
                $ResourcesPort = $url.Split(":")[1]
            }
            Else
            {
                $Name = $url
                try
                {
                    [array]$Resources = (Resolve-DnsName $Name -ErrorAction stop).IP4Address
                }
                catch
                {
                    Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Unable to resolve host $($url)." -ConsoleOutput
                    Write-Log -LogFile $Logfile -LogLevel ERROR -Message "$($_.Exception.Message)"
                    Continue
                }
                
                #[array]$Resources = (Resolve-DnsName $Name).IP4Address
                $ResourcesPort = "443"
            }
            foreach ($ip4 in $Resources)
            {
                try
                {

                $timestart = get-date 
                $Result443 = Test-NetConnection $ip4 -Port 443 -erroraction stop -wa silentlycontinue
                $timeend = get-date 
                $totaltime = $timeend - $timestart
                $totaltimeseconds = $totaltime.TotalSeconds

                if($Result443.TcpTestSucceeded -eq "True")
                {
                #switch ($Result443.TcpTestSucceeded)
                
                    Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "TCP connection to $($url) [$($ip4)]:443 successful. Taking : $totaltimeseconds : seconds to complete" -ConsoleOutput 
                }
                else
                {
                    Write-Log -LogFile $Logfile -LogLevel ERROR -Message "TCP connection to $($url) [$($ip4)]:443 failed." -ConsoleOutput
                }
                $timestart = get-date 
                $Result80 = Test-NetConnection $ip4 -Port 80 -erroraction stop -wa silentlycontinue
                $timeend = get-date 
                $totaltime = $timeend - $timestart
                $totaltimeseconds = $totaltime.TotalSeconds  
                if ($Result80.TcpTestSucceeded -eq "True")
                {
                    $message = 
                     Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "TCP connection to $($url) [$($ip4)]:80 successful. Taking : $totaltimeseconds : seconds to complete" -ConsoleOutput 
                }
                else
                {
                     Write-Log -LogFile $Logfile -LogLevel ERROR -Message "TCP connection to $($url) [$($ip4)]:80 failed." -ConsoleOutput
                }



                }
                catch
                {
                    Write-Log -LogFile $Logfile -LogLevel WARN -Message "Error resolving or connecting to $($Name) [$($ip4)]:$($ResourcesPort)" -ConsoleOutput
                    Write-Log -LogFile $Logfile -LogLevel WARN -Message "$($_.Exception.Message)"
                    
                }
                finally
                {
                    If ($DebugLogging)
                    {
                        Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Debug log entry for $($Name) [$($Result.RemoteAddress)]:443."
                        Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Remote endpoint: $($Name)"
                        Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Remote port: $($Result.RemotePort)"
                        Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Interface Alias: $($Result.InterfaceAlias)"
                        Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Source Interface Address: $($Result.SourceAddress.IPAddress)"
                        Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Succeeded: $($Result.PingSucceeded)"
                        Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Reply Time (RTT) Status: $($Result.PingReplyDetails.Status)"
                        Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Reply Time (RTT) RoundTripTime: $($Result.PingReplyDetails.RoundtripTime)"
                        Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "TCPTestSucceeded: $($Result.TcpTestSucceeded)"
                    }
                }
            } # End ForEach ip4
        } # End ForEach AdditionalResources
    } # End IF AdditionalResources
    
    Write-Log -LogFile $Logfile -LogLevel INFO -Message "Finished Online Endpoints tests."
} # End Function OnlineEndPoints

# Test for Optional Feature availability
function OptionalFeatureCheck
{
    If (!$Credential)
    {
        $Credential = Get-Credential -Message "Office 365 Global Administrator account"
    }
    
    If (!(Get-Module MSOnline)) { Import-Module MSOnline }
    else
    {
        try { $Result = Get-Command Get-MsolAccountSku -erroraction Stop }
        catch { Write-Log -LogFile ERROR -ConsoleOutput -LogLevel ERROR -Message "$($_.Exception.Message)" }
    }
    If (!($Result)) { Connect-MsolService -Credential $Credential }
    
    switch ($OptionalFeatureCheck)
    {
        "PasswordWriteBack" {
            [array]$Skus = Get-MsolAccountSku
            [array]$SkusWithAADPremiumServicePlan = @()
            foreach ($Sku in $Skus)
            {
                if ($Sku.ServiceStatus.ServicePlan.ServiceName -match "AAD_PREMIUM") { $SkusWithAADPremiumServicePlan += $Sku.SkuPartNumber }
            }
            If ($SkusWithAADPremiumServicePlan)
            {
                $SkusWithAADPremiumServicePlan | % { Write-Log -LogFile $Logfile -LogLevel INFO -Message "$($_) contains an Azure AD Premium Service to enable Password Write Back."}
            }
        }
    }
} # End function OptionalFeatureCheck

# Test Local Networking Only
function Network
{
    Write-Log -LogFile $Logfile -LogLevel INFO -Message "Starting local network port tests." -ConsoleOutput
    If (!$DCs)
    {
        Write-Log -LogFile $Logfile -LogLevel ERROR -Message "If testing on-premises networking, you must specify at least one on-premises domain controller." -ConsoleOutput
        Write-Log -LogFile $Logfile -LogLevel INFO -Message "You can skip this test in the future with the parameter: -Network:`$false" -ConsoleOutput
    }
    
    Else
    {
        Foreach ($Destination in $DCs)
        {
            foreach ($Port in $Ports)
            {
                Try
                {
                
                $timestart = get-date 
                $Result = (Test-NetConnection -ComputerName $Destination -Port $Port -erroraction Stop -wa SilentlyContinue)
                $timeend = get-date 
                $totaltime = $timeend - $timestart
                $totaltimeseconds = $totaltime.TotalSeconds 
                    if ($Result.TcpTestSucceeded -eq "True")
                    {
                     Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "TCP connection to $($Destination):$($Port) succeeded. in $totaltimeseconds " -ConsoleOutput
                    }
                    else
                        {
                            Write-Log -LogFile $Logfile -LogLevel ERROR -Message "TCP connection to $($Destination):$($Port) failed." -ConsoleOutput
                            Write-Log -LogFile $Logfile -LogLevel ERROR -Message "$Result"
                        }
                    
                }
                Catch
                {
                    Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Exception: Error attempting TCP connection to $($Destination):$($Port)." -ConsoleOutput
                    Write-Log -LogFile $Logfile -LogLevel ERROR -Message "$($_.Exception.Message)"
                }
                Finally
                {
                    If ($DebugLogging)
                    {
                        Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Debug log entry for $($Destination) [$($Result.RemoteAddress)]:$($Port)."
                        Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Remote endpoint: $($Destination)"
                        Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Remote port: $($Result.RemotePort)"
                        Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Interface Alias: $($Result.InterfaceAlias)"
                        Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Source Interface Address: $($Result.SourceAddress.IPAddress)"
                        Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Succeeded: $($Result.PingSucceeded)"
                        Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Reply Time (RTT) Status: $($Result.PingReplyDetails.Status)"
                        Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Reply Time (RTT) RoundTripTime: $($Result.PingReplyDetails.RoundtripTime)"
                        Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "TCPTestSucceeded: $($Result.TcpTestSucceeded)"
                    }
                }
            } # End Foreach Port in Ports
            foreach ($Port in $OptionalADPorts)
            {
                Try
                {
                

                $timestart = get-date 
                $Result = (Test-NetConnection -ComputerName $Destination -Port $Port -erroraction Stop -wa SilentlyContinue)
                $timeend = get-date 
                $totaltime = $timeend - $timestart
                $totaltimeseconds = $totaltime.TotalSeconds  
                    Switch ($Result.TcpTestSucceeded)
                    {
                        True
                        {
                            Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "TCP connection to $($Destination):$($Port) succeeded. in $totaltimeseconds" -ConsoleOutput
                        }
                        False
                        {
                            Write-Log -LogFile $Logfile -LogLevel WARN -Message "TCP connection to $($Destination):$($Port) failed." -ConsoleOutput
                            Write-Log -LogFile $Logfile -LogLevel WARN -Message "$Result"
                        }
                    } # End Switch
                }
                Catch
                {
                    Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Error attempting TCP connection to $($Destination):$($Port)." -ConsoleOutput
                    Write-Log -LogFile $Logfile -LogLevel ERROR -Message "$($_.Exception.Message)"    
                }
                Finally
                {
                    If ($DebugLogging)
                    {
                        Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Debug log entry for $($Destination) [$($Result.RemoteAddress)]:$($Port)."
                        Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Remote endpoint: $($Destination)"
                        Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Remote port: $($Result.RemotePort)"
                        Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Interface Alias: $($Result.InterfaceAlias)"
                        Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Source Interface Address: $($Result.SourceAddress.IPAddress)"
                        Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Succeeded: $($Result.PingSucceeded)"
                        Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Reply Time (RTT) Status: $($Result.PingReplyDetails.Status)"
                        Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Ping Reply Time (RTT) RoundTripTime: $($Result.PingReplyDetails.RoundtripTime)"
                        Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "TCPTestSucceeded: $($Result.TcpTestSucceeded)"
                    }
                }
            } # End Foreach Port in OptionalADPorts
            
        } # End Foreach Destination
        Write-Log -LogFile $Logfile -LogLevel INFO -Message "Finished local network port tests."
    }
} # End Function Network

# Test local DNS resolution for domain controllers
function Dns
{
    Write-Log -LogFile $Logfile -LogLevel INFO -Message "Starting local DNS resolution tests."
    If (!$ForestFQDN)
    {
        Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Local Dns resolution, you must specify for Active Directory Forest FQDN." -ConsoleOutput
        Write-Log -LogFile $Logfile -LogLevel INFO -Message "Local Dns resolution, you must specify for Active Directory Forest FQDN." -ConsoleOutput
    }
    
    If (!$DCs)
    {
        Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Local DNS resolution testing requires the DCs parameter to be specified." -ConsoleOutput
        Break
    }
    # Attempt DNS Resolution
    $DnsTargets = @("_ldap._tcp.$ForestFQDN") + $DCs
    Foreach ($HostName in $DnsTargets)
    {
        Try
        {
            $DnsResult = (Resolve-DnsName -Type ANY $HostName -erroraction Stop -wa SilentlyContinue)
            If ($DnsResult.Name)
            {
                Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "Successfully resolved $($HostName)." -ConsoleOutput
            }
            Else
            {
                Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Error attempting DNS resolution for $($HostName)." -ConsoleOutput
                Write-Log -LogFile $Logfile -LogLevel ERROR -Message $DnsResult
            }
        }
        Catch
        {
            Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Exception: Error attempting DNS resolution for $($HostName)." -ConsoleOutput
            Write-Log -LogFile $Logfile -LogLevel ERROR -Message "$($_.Exception.Message)"
        }
        Finally
        {
            If ($DebugLogging)
            {
                Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "Debug log entry for $($HostName)."
                Write-Log -LogFile $Logfile -LogLevel DEBUG -Message $DnsResult
            }
        }
    }
    Write-Log -LogFile $Logfile -LogLevel INFO -Message "Finished local DNS resolution tests."
} # End function Dns

function ActiveDirectory
{
    # Install if -InstallModules switch was used
    If (!(Get-Module -ListAvailable ActiveDirectory) -and $InstallModules)
    {
        # Check if Elevated
        $wid = [system.security.principal.windowsidentity]::GetCurrent()
        $prp = New-Object System.Security.Principal.WindowsPrincipal($wid)
        $adm = [System.Security.Principal.WindowsBuiltInRole]::Administrator
        if ($prp.IsInRole($adm))
        {
            Write-Log -LogFile $Logfile -LogLevel SUCCESS -ConsoleOutput -Message "Elevated PowerShell session detected. Continuing."
        }
        else
        {
            Write-Log -LogFile $Logfile -LogLevel ERROR -ConsoleOutput -Message "This application/script must be run in an elevated PowerShell window. Please launch an elevated session and try again."
            Break
        }
        Try { $Result = Add-WindowsFeature Rsat-Adds }
        Catch
        {
            Write-Log -LogFile $Logfile -ConsoleOutput -Message "Error adding Windows Feature Rsat-Adds."
            Write-Log -LogFile $Logfile -Message "Exception: $($_.Exception.Message)"
        }
        Finally
        {
            Switch ($Result.Success)
            {
                True { Write-Log -LogFile $Logfile -ConsoleOutput -LogLevel SUCCESS -Message "Remote Server Administration Tools for Active Directory Domain Services installation completed successfully." }
                False { Write-Log -LogFile $Logfile -ConsoleOutput -Loglevel ERROR -Message "Remote Server Administration Tools for Active Directory Domain Services installation failed." }
            }
        }
    }
    If (Get-Module -ListAvailable ActiveDirectory)
    {
        Write-Log -LogFile $Logfile -Loglevel INFO -Message "Starting Active Directory tests."
        # Forest Configuration
        [string]$ForestMode = (Get-ADForest $ForestFQDN).ForestMode
        switch ($ForestMode)
        {
            Windows2000Forest { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Forest is Windows 2000 mode. Unsupported. Upgrade forest functional level." -ConsoleOutput }
            Windows2003Forest { Write-Log -LogFile $Logfile -LogLevel INFO -Message "Forest is Windows Server 2003 mode. Supported." }
            Windows2003InterimForest { Write-Log -Logfile $Logfile -Loglevel ERROR -Message "Windows Server 2003 interim function mode. Unsupported. Upgrade forest functional level." }
            Windows2008Forest { Write-Log -LogFile $Logfile -LogLevel INFO -Message "Forest is Windows Server 2008 mode. Supported." }
            Windows2008R2Forest { Write-Log -LogFile $Logfile -LogLevel INFO -Message "Forest is Windows Server 2008 R2 mode. Supported." }
            Windows2012R2Forest { Write-Log -LogFile $Logfile -LogLevel INFO -Message "Forest is Windows Server 2012 R2 mode. Supported." }
            Windows8Forest { Write-Log -LogFile $Logfile -LogLevel INFO -Message "Forest is Windows 8 mode. Supported." }
            Windows2012Forest { Write-Log -LogFile $Logfile -LogLevel INFO -Message "Forest is Windows Server 2012 Mode. Supported." }
            Windows2016Forest { Write-Log -LogFile $Logfile -LogLevel INFO -Message "Forest is Windows Server 2016 Mode. Supported."}
        }
        
        # Forest and domain character checks
        [string]$ForestNetBIOS = (Get-ADForest $ForestFQDN).NetBIOSName
        [string]$DomainNetBIOS = (Get-ADDomain).NetBIOSName
        
        If ($ForestNetBIOS -match "\." -or $DomainNetBIOS -match "\.")
        {
            Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Domain NetBIOS name contains a period. AAD Connect cannot be installed in this environment." -ConsoleOutput
        }
        Else { Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "Domain NetBIOS name does not contain a period. Passed." }
        
        # AD Recycle Bin
        If (Get-Command Get-ADOptionalFeature -erroraction silentlycontinue)
        {
            $RecycleBin = (Get-ADOptionalFeature -Filter { name -eq "Recycle Bin Feature" })
        }
        If (!($RecycleBin.EnabledScopes))
        {
            Write-Log -LogFile $Logfile -LogLevel INFO -Message "AD Recycle Bin IS NOT ENABLED. It is recommended to enable the AD Recycle Bin."
            Write-Log -LogFile $Logfile -LogLevel INFO -Message "To enable, run Enable-ADOptionalFeature -'Recycle Bin Feature' -Scope ForestOrConfigurationSet -Target $($ForestFQDN)"
        }
        Else { Write-Log -LogFile $Logfile -LogLevel INFO -Message "AD Recycle Bin is ENABLED." }
        
        # Check for Read-Only Domain Controllers
        $CurrentSite = [System.DirectoryServices.ActiveDirectory.ActiveDirectorySite]::GetComputerSite().Name
        $RODCsInSite = Get-ADDomainController -Discover -SiteName $CurrentSite| ?{$_.IsReadOnly -eq "True"}
        If ($RODCcsInSite -ge 1)
        {
            Write-Log -LogFile $Logfile -LogLevel WARN -Message "Current site may contain Read-Only Domain Controllers. Read-Only Domain Controllers are not permitted for writeback operations or Password Hash Sync. Please verify if any DCs in the site $($CurrentSite) are Read-Only Domain Controllers."
        }
    }
    Else { Write-Log -LogFile $Logfile -LogLevel WARN -Message "Active Directory Module is not loaded. Please install using Install-WindowsFeature RSAT-ADDS or the -InstallModules switch." }
} # End function ActiveDirectory

function SystemConfiguration
{
    ## Show system configuration
    Write-Log -LogFile $Logfile -LogLevel INFO -Message "Starting system configuration gathering."
    [string]$OSVersion = ([System.Environment]::OSVersion.Version.Major.ToString() + "." + [System.Environment]::OSVersion.Version.Minor.ToString())
    [string]$OperatingSystem = (Get-WmiObject -Class Win32_OperatingSystem -Namespace "root\cimv2").Caption
    [string]$OSBitness = [System.Environment]::Is64BitOperatingSystem
    [string]$OSMachineName = [System.Environment]::MachineName.ToString()
    [string]$OperatingSystemSKU = (Get-WmiObject -Class Win32_OperatingSystem).OperatingSystemSKU
    Write-Log -LogFile $Logfile -LogLevel INFO -Message "System name: $($OSMachineName)"
    Write-Log -LogFile $Logfile -LogLevel INFO -Message "64-bit operating system detected: $($OSBitness)"
    Write-Log -LogFile $Logfile -LogLevel INFO -Message "Operating System: $($OperatingSystem) $($OSVersion)"
    Switch ($OperatingSystemSKU)
    {
        0 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Undefined. Unable to determine operating system type. Azure AD Connect installation will probably fail." }
        1 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Ultimate. Installation not supported." }
        2 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Home Basic Edition. Installation not supported." }
        3 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Home Premium Edition. Installation not supported." }
        4 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Enterprise Edition. Installation not supported." }
        6 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Business Edition. Installation not supported." }
        7 { Write-Log -LogFile $Logfile -LogLevel INFO -Message "Operating System Edition is Standard Server. Installation may be supported if the Operating System version is supported." }
        8 { Write-Log -LogFile $Logfile -LogLevel INFO -Message "Operating System Edition is Datacenter Server. Installation may be supported if the Operating System version is supported." }
        9 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Small Business Server. Installation not supported." }
        10 { Write-Log -LogFile $Logfile -LogLevel INFO -Message "Operating System Edition is Enterprise Server. Installation may be supported if the Operating System version is supported." }
        11 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Starter. Installation not supported." }
        12 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Datacenter Server Core. Installation not supported." }
        13 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Standard Server Core. Installation not supported." }
        14 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Enterprise Server Core. Installation not supported." }
        17 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Web Server. Installation not supported." }
        19 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Home Server. Installation not supported." }
        20 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Storage Express Server. Installation not supported." }
        21 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Storage Standard Server. Installation not supported." }
        22 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Storage Workgroup Server. Installation not supported." }
        23 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Storage Enterprise Server. Installation not supported." }
        24 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Server for Small Business. Installation not supported." }
        25 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Small Business Server Premium. Installation not supported." }
        27 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Enterprise N. Installation not supported." }
        28 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Ultimate N. Installation not supported." }
        29 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Web Server Core. Installation not supported." }
        36 { Write-Log -LogFile $Logfile -LogLevel INFO -Message "Operating System Edition is Standard Server (without Hyper-V). Installation may be supported if Operating System version is supported." }
        37 { Write-Log -LogFile $Logfile -LogLevel INFO -Message "Operating System Edition is Datacenter Server (without Hyper-V). Installation may be supported if Operating System version is supported." }
        38 { Write-Log -LogFile $Logfile -LogLevel INFO -Message "Operating System Edition is Enterprise Server (without Hyper-V). Installation may be supported if Operating System version is supported." }
        39 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Datacenter Core Server (without Hyper-V). Installation not supported." }
        40 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Standard Core Server (without Hyper-V). Installation not supported." }
        41 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Enterprise Core Server (without Hyper-V). Installation not supported." }
        42 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Hyper-V Server. Installation not supported." }
        43 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Storage Server Express (Server Core). Installation not supported." }
        44 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Storage Server Standard (Server Core). Installation not supported." }
        45 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Storage Server Workgroup (Server Core). Installation not supported." }
        45 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Storage Server Enterprise (Server Core). Installation not supported." }
        50 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Server Essentials. Installation not supported." }
        63 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Small Business Server Premium (Server Core). Installation not supported." }
        64 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Computer Cluster Server (without Hyper-V). Installation not supported." }
        97 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Windows RT. Installation not supported." }
        101 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Home. Installation not supported." }
        103 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Professional with Media Center. Installation not supported." }
        104 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Mobile. Installation not supported." }
        123 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is IoT (Internet of Things) Core. Installation not supported." }
        143 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Datacenter Server (Nano). Installation not supported." }
        144 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Standard Server (Nano). Installation not supported." }
        147 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Datacenter Server (Server Core). Installation not supported." }
        148 { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Operating System Edition is Standard Server (Server Core). Installation not supported." }
        default {Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Unable to determine Operating System Edition SKU value."}
    }
    
    # Netsh WinHTTP proxy
    Write-Log -LogFile $Logfile -LogLevel INFO -Message "WinHTTP proxy settings (netsh winhttp show proxy):"
    $WinHTTPProxy = (netsh winhttp show proxy)
    $WinHTTPProxy = ($WinHTTPProxy -join " ").Trim()
    Write-Log -LogFile $Logfile -LogLevel INFO -Message $WinHTTPProxy
    
    # .NET Proxy
    Write-Log -LogFile $Logfile -LogLevel INFO -Message ".NET proxy settings (machine.config/configuration/system.net/defaultproxy):"
    [xml]$machineconfig = gc $env:windir\Microsoft.NET\Framework64\v4.0.30319\Config\machine.config
    if (!$machineconfig.configuration.'system.net'.defaultproxy)
    {
        Write-Log -LogFile $Logfile -LogLevel INFO -Message "No proxy configuration exists in $env:windir\Microsoft.NET\Framework64\v4.0.30319\Config\machine.config."
    }
    else
    {
        Write-Log -LogFile $Logfile -LogLevel INFO -Message "The following proxy configuration exists in $env:windir\Microsoft.NET\Framework64\v4.0.30319\Config\machine.config."
        $nodes = $machineconfig.ChildNodes.SelectNodes("/configuration/system.net/defaultproxy/proxy") | Sort -Unique
        Write-Log -Logfile $Logfile -LogLevel INFO -Message "UseSystemDefault: $($nodes.usesystemdefault)"
        Write-Log -LogFile $Logfile -LogLevel INFO -Message "ProxyAddress: $($nodes.proxyaddress)"
        Write-Log -LogFile $Logfile -LogLevel INFO -Message "BypassOnLocal $($nodes.bypassonlocal)"
    }
    Write-Log -LogFile $Logfile -LogLevel INFO -Message "For more .NET proxy configuration parameters, see https://docs.microsoft.com/en-us/dotnet/framework/configure-apps/file-schema/network/proxy-element-network-settings"
    
    # .NET Framework Versions
    $NetFrameWorkVersion = (Get-ItemProperty "HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\" -ErrorAction SilentlyContinue).Release.ToString()
    switch ($NetFrameWorkVersion)
    {
        { $NetFrameWorkVersion -ge 461808 } { Write-Log -LogFile $Logfile -LogLevel INFO -Message "The version of .NET Framework installed is 4.7.2 or greater.";Break }
        { $NetFrameWorkVersion -ge 461308 } { Write-Log -LogFile $Logfile -LogLevel INFO -Message "The version of .NET Framework installed is 4.7.1 or greater."; Break }
        { $NetFrameWorkVersion -ge 460798 } { Write-Log -LogFile $Logfile -LogLevel INFO -Message "The version of .NET Framework installed is 4.7 or greater."; Break }
        { $NetFrameWorkVersion -ge 394802 } { Write-Log -LogFile $Logfile -LogLevel INFO -Message "The version of .NET Framework installed is 4.6.2 or greater."; Break }
        { $NetFrameWorkVersion -ge 394254 } { Write-Log -LogFile $Logfile -LogLevel INFO -Message "The version of .NET Framework installed is 4.6.1 or greater."; Break }
        { $NetFrameWorkVersion -ge 393295 } { Write-Log -LogFile $Logfile -LogLevel INFO -Message "The version of .NET Framework installed is 4.6 or greater."; Break }
        { $NetFrameWorkVersion -ge 379893 } { Write-Log -LogFile $Logfile -LogLevel INFO -Message "The version of .NET Framework installed is 4.5.2 or greater."; Break }
        { $NetFrameWorkVersion -ge 378675 } { Write-Log -LogFile $Logfile -LogLevel INFO -Message "The version of .NET Framework installed is 4.5.1 or greater."; Break }
        { $NetFrameWorkVersion -ge 378389 } { Write-Log -LogFile $Logfile -LogLevel INFO -Message "The version of .NET Framework installed is 4.5 or greater."
                                              Write-Log -LogFile $Logfile -LogLevel WARN -Message "In order to install AAD Connect, upgrade to at least .NET Framework 4.5.1.";    Break }
        default { Write-Log -LogFile $Logfile -LogLevel WARN -Message "Unable to determine version of .NET Framework. AAD Connect requires .NET Framework 4.5.1 or greater.";  Break}
    }
    
    # Check service packs
    $ServicePack = (Get-ItemProperty "HKLM\Software\Microsoft\Windows NT\CurrentVersion" -erroraction silentlycontinue).ServicePack
    switch ($OSVersion)
    {
        "6.1" { If (!$ServicePack) { Write-Log -LogFile $Logfile -LogLevel WARN -Message "Windows Server 2008 R2 requires Service Pack 1 if Password Hash Synchronization will be used.";  } }
        default { Write-Log -LogFile $Logfile -LogLevel INFO -Message "No service packs are required for this version of Windows."}    
    }
    
    # Check PowerShell Versions
    switch ($OSVersion)
    {
        "6.0" { If ($PSVersionTable.Major -lt 3) { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Windows Server 2008 requires Windows Management Framework 3.0 or higher.";  } }
        "6.1" { If ($PSVersionTable.Major -lt 4) { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Windows Server 2008 R2 requires Windows Management Framework 4.0 or higher."; } }
        "6.2" { If ($PSVersionTable.Major -lt 4) { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Windows Server 2012 requires Windows Management Framework 4.0 or higher."; } }
        "10.0" { Write-Log -LogFile $Logfile -LogLevel INFO -Message "Windows Server 2016 or Windows Server 2019 have the required PowerShell version."}
    }
    
    # Server Features parameters
    Write-Log -LogFile $Logfile -LogLevel INFO -Message "Attempting to check installed features."
    If (Get-Command Get-WindowsFeature -ErrorAction SilentlyContinue)
    {
        Write-Log -LogFile $Logfile -LogLevel INFO -Message "Command available. Checking installed features."
        $ServerFeatures = Get-WindowsFeature | ? {
            $_.Name -eq 'Server-Gui-Mgmt-Infra' -or `
            $_.Name -eq 'Server-Gui-Shell' -or `
            $_.Name -eq 'NET-Framework-45-Features' -or `
            $_.Name -eq 'NET-Framework-45-Core'
        }
        foreach ($Feature in $ServerFeatures)
        {
            switch ($Feature.InstallState)
            {
                Installed { Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "Required feature $($Feature.DisplayName) [$($Feature.Name)] is installed." }
                Available { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "Required feature $($Feature.DisplayName) [$($Feature.Name)] is not installed." }
            } # End Switch FeatureIsInstalled
        } # End Foreach Feature
        Write-Log -LogFile $Logfile -LogLevel INFO -Message "Finished checking installed features."
    } # End Server Feaatures
    Else { Write-Log -LogFile $Logfile -LogLevel WARN -Message "Command not available. Unable to check installed features." }
    
    # Check for TLS capabilities
    switch ($OSVersion)
    {
        "10.0"    {
            switch -regex ($OperatingSystem)
            {
                "(?i)(Server)" {
                    Write-Log -Logfile $Logfile -ConsoleOutput -LogLevel INFO -Message "Checking TLS settings for Windows Server 2016 and Windows Server 2019."
                    $KeysArray = @(
                        @{ Path = "HKLM:SOFTWARE\Microsoft\.NETFramework\v4.0.30319"; Item = "SchUseStrongCrypto"; type = "REG_DWORD"; Value = "1" },
                        @{ Path = "HKLM:SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319"; Item = "SchUseStrongCrypto"; type = "REG_DWORD"; Value = "1" }
                    )
                }
                default
                {
                    Write-Log -LogFile $Logfile -ConsoleOutput -LogLevel INFO -Message "Desktop operating system is not a candidate for AAD Connect Installation."    
                }
            }
        } # End 10.0 / Windows Server 2016 / 2019
        
        "6.3"    {
                    Write-Log -Logfile $Logfile -ConsoleOutput -LogLevel INFO -Message "Checking TLS settings for Windows Server 2012 R2."
                    $KeysArray = @(
                        @{ Path = "HKLM:SOFTWARE\Microsoft\.NETFramework\v4.0.30319"; Item = "SchUseStrongCrypto"; type = "REG_DWORD"; Value = "1" },
                        @{ Path = "HKLM:SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319"; Item = "SchUseStrongCrypto"; type = "REG_DWORD"; Value = "1" }
                    )
                } # End 6.3 / Windows Server 2012 R2
        
        "6.2"    {
                    Write-Log -Logfile $Logfile -ConsoleOutput -LogLevel INFO -Message "Checking TLS settings for Windows Server 2012."
                    $KeysArray = @(
                        @{ Path = "HKLM:SOFTWARE\Microsoft\.NETFramework\v4.0.30319"; Item = "SchUseStrongCrypto"; type = "REG_DWORD"; Value = "1" },
                        @{ Path = "HKLM:SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319"; Item = "SchUseStrongCrypto"; type = "REG_DWORD"; Value = "1" }
                    )
                } # End 6.2 / Windows Server 2012
        
        "6.1"    {
                    Write-Log -Logfile $Logfile -ConsoleOutput -LogLevel INFO -Message "Checking TLS settings for Windows Server 2008 R2."
                    $KeysArray = @(
                        @{ Path = "HKLM:SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client"; Item = "DisabledByDefault"; Type = "REG_DWORD"; Value = "0" },
                        @{ Path = "HKLM:SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client"; Item = "Enabled"; type = "REG_DWORD"; Value = "1" },
                        @{ Path = "HKLM:SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server"; Item = "DisabledByDefault"; type = "REG_DWORD"; Value = "0" },
                        @{ Path = "HKLM:SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Server"; Item = "Enabled"; type = "REG_DWORD"; Value = "1" },
                        @{ Path = "HKLM:SOFTWARE\Microsoft\.NETFramework\v4.0.30319"; Item = "SchUseStrongCrypto"; type = "REG_DWORD"; Value = "1" },
                        @{ Path = "HKLM:SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319"; Item = "SchUseStrongCrypto"; type = "REG_DWORD"; Value = "1" }
                        )
                } # End 6.1 / Windows Server 2008 R2

        "6.0"    { 
                    Write-Log -Logfile $Logfile -ConsoleOutput -LogLevel INFO -Message "Checking TLS settings for Windows Server 2008."
                    Write-Log -LogFile $Logfile -ConsoleOutput -LogLevel WARN -Message "TLS 1.2 cannot be enabled on Windows Server 2008."
                } # End 6.0 / Windows Server 2008
        
        default { Write-Log -LogFile $Logfile -ConsoleOutput -LogLevel WARN -Message "Unable to determine Windows Version. TLS checks will be skipped." }
    }
    
    If ($KeysArray)
    {
        foreach ($Key in $KeysArray)
        {
            try
            {
                $Result = (Get-ItemProperty -erroraction SilentlyContinue $Key.Path).$($Key.Item).ToString()
                If ($Result)
                {
                    If ($Result -match $Key.Value)
                    {
                        Write-Log -LogFile $Logfile -LogLevel INFO -Message "Key $($Key.Path)\$($Key.Item) with a value of $($Key.Value) is set correctly for TLS 1.2 Configuration."
                    }
                    Else
                    {
                        $RegKeyPath = ($Key.Path).Replace(":", "\")
                        Write-Log -LogFile $Logfile -LogLevel INFO -Message "Key $($Key.Path)\$($Key.Item) with a value of $($Key.Value) is not set correctly for TLS 1.2 Configuration."
                        Write-Log -LogFile $LogFile -LogLevel INFO -Message "Key $($Key.Path)\$($Key.Item) must be set to $($Key.Value) for TLS 1.2 support."
                        Write-Log -LogFile $Logfile -LogLevel INFO -Message "To configure, run: REG ADD ""$($RegKeyPath)"" /v $($Key.Item) /d $($Key.Value) /t REG_DWORD /f"
                    }
                }
                Else
                {
                    $RegKeyPath = ($Key.Path).Replace(":", "\")
                    Write-Log -LogFile $Logfile -LogLevel INFO -Message "Key $($Key.Path)\$($Key.Item) not found."
                    Write-Log -LogFile $LogFile -LogLevel INFO -Message "Key $($Key.Path)\$($Key.Item) must be set to $($Key.Value) for TLS 1.2 support."
                    Write-Log -LogFile $Logfile -LogLevel INFO -Message "To configure, run: REG ADD ""$($RegKeyPath)"" /v $($Key.Item) /d $($Key.Value) /t REG_DWORD /f"
                }
            }
            Catch
            {
                $RegKeyPath = ($Key.Path).Replace(":", "\")
                Write-Log -LogFile $Logfile -LogLevel INFO -Message "Exception or $($Key.Path)\$($Key.Item) not found."
                Write-Log -LogFile $LogFile -LogLevel INFO -Message "Key $($Key.Path)\$($Key.Item) must be set to $($Key.Value) for TLS 1.2 support."
                Write-Log -LogFile $Logfile -LogLevel INFO -Message "To configure, run: REG ADD ""$($RegKeyPath)"" /v $($Key.Item) /d $($Key.Value) /t REG_DWORD /f"
            }
        }
        Write-Log -LogFile $Logfile -LogLevel INFO -Message "Finished checking for TLS 1.2 Configuration settings."
    }
    
    # Check Group Policy PowerShell Transcription has been enabled
    Try { $GPOTranscription = (Get-ItemProperty "HKLM:SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription\" -ErrorAction SilentlyContinue).EnableTranscripting.ToString() }
    Catch { }
    If ($GPOTranscription)
    {
        switch ($GPOTranscription)
        {
            0 { $Value = "disabled" }; 1 { $Value = "enabled" }
        }
        Write-Log -LogFile $Logfile -LogLevel ERROR -Message "PowerShell transcription is configured through Group Policy. The current value is $($GPOTranscription) ($($Value))." -ConsoleOutput
        Write-Log -LogFile $Logfile -LogLevel ERROR -Message "PowerShell transcription group policy must be set to 'Disabled' or 'Not Configured' or the installation process will fail." -ConsoleOutput
        Write-Log -LogFile $Logfile -LogLevel INFO -Message "PowerShell transcription detected. Attempting to determine which policy has it enabled." -ConsoleOutput
        
        # Check if Elevated
        $wid = [system.security.principal.windowsidentity]::GetCurrent()
        $prp = New-Object System.Security.Principal.WindowsPrincipal($wid)
        $adm = [System.Security.Principal.WindowsBuiltInRole]::Administrator
        if ($prp.IsInRole($adm))
        {
            Write-Log -LogFile $Logfile -LogLevel SUCCESS -ConsoleOutput -Message "Elevated PowerShell session detected. Continuing."
            $RsopFile = (Get-Date -Format yyyy-MM-dd) + "_AADConnectConnectivityRSOP.txt"
            gpresult /f /SCOPE Computer /X $RsopFile
            [xml]$Rsop = gc $RsopFile
            [array]$data = ($Rsop.Rsop.ComputerResults | ? { $_.InnerXml -like '*transcription*' } | Select -ExpandProperty GPO).Name
            foreach ($policy in $data) { Write-Log -LogFile $Logfile -LogLevel ERROR -Message "The Group Policy Object $policy has a value configured for Turn on PowerShell Transcription. This will cause AAD Connect installation to fail." -ConsoleOutput}
        }
        else
        {
            Write-Log -LogFile $Logfile -LogLevel ERROR -ConsoleOutput -Message "Unable to export group policy information without elevation. Please launch an elevated session and try again."
        }
        
    }
    If (!$GPOTranscription) { Write-Log -LogFile $Logfile -LogLevel SUCCESS -Message "PowerShell transcription is not configured." }
    
    Write-Log -LogFile $Logfile -LogLevel INFO -Message "Finished gathering system configuration."
} # End Function System Configuration

## Begin script
Write-Log -LogFile $Logfile -LogLevel INFO -Message "========================================================="
Write-Log -LogFile $Logfile -LogLevel INFO -Message "Starting AAD Connect connectivity and resolution testing."

# If SkipDcDnsPortCheck is enabled, remove 53 from the list of ports to test on DCs
If ($SkipDcDnsPortCheck) { $Ports = @('135', '389', '445', '3268') }
Else { $Ports = @('53', '135', '389', '445', '3268') }

# Use this switch if a statically configured Rpc port for AD traffic has been configured
# on the target DC. This port may be called for Password Hash Sync configuration.
If ($FixedDcRpcPort)
{
    $Ports += $FixedDcRpcPort
    Write-Log -LogFile $Logfile -LogLevel INFO -Message "Port $($FixedDcRpcPort) will be tested as part of the DC/local network test."
    If ($DebugLogging)
    {
        Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "For more information on configuring a fixed RPC port for DC communications, please see"
        Write-Log -LogFile $Logfile -LogLevel DEBUG -Message "https://support.microsoft.com/en-us/help/224196/restricting-active-directory-rpc-traffic-to-a-specific-port"
    }
}

# Use the OptionalADPortTest switch to add the following ports: 88, 636, 3269
# In order to use ports 636 and 3269, domain controllers must be configured with a
# valid server certificate. See https://social.technet.microsoft.com/wiki/contents/articles/18254.ldaps-636-and-msft-gc-ssl-3269-service.aspx
# and https://social.technet.microsoft.com/wiki/contents/articles/2980.ldap-over-ssl-ldaps-certificate.aspx.
If ($OptionalADPortTest) { $OptionalADPorts += @('88', '636','3269') }

If ($AllTests -or $PSBoundParameters.Count -eq 0)
{
    If (!$PSBoundParameters.ContainsKey("AzureCredentialCheck")) { $AzureCredentialCheck = $true }
    If (!$PSBoundParameters.ContainsKey("Dns")) { $Dns = $true }
    If (!$PSBoundParameters.ContainsKey("Network")) { $Network = $true }
    If (!$PSBoundParameters.ContainsKey("OnlineEndPoints")) { $OnlineEndPoints = $true }
    If (!$PSBoundParameters.ContainsKey("ActiveDirectory")) { $ActiveDirectory = $true }
    If (!$PSBoundParameters.ContainsKey("SystemConfiguration")) { $SystemConfiguration = $true }
    If (!$PSBoundParameters.ContainsKey("OptionalFeatureCheck")) { $OptionalFeatureCheck = "PasswordWriteBack"}
}

If ($AzureCredentialCheck) { AzureCredential }
If ($Dns) { Dns }
If ($Network) { Network }
If ($OnlineEndPoints) {  
[net.servicepointmanager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
OnlineEndPoints}
If ($OptionalFeatureCheck) { OptionalFeatureCheck }
If ($ActiveDirectory) { ActiveDirectory }
If ($SystemConfiguration) { SystemConfiguration }

Write-Log -LogFile $Logfile -LogLevel INFO -Message "Done! Logfile is $($Logfile)." -ConsoleOutput
Write-Log -LogFile $Logfile -LogLevel INFO -Message "---------------------------------------------------------"