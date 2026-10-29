<#Example configuration (replace placeholders): 
Tenant YOUR-TENANT-ID; app YOUR-APPLICATION-CLIENT-ID; commercial authority login.microsoftonline.com; Graph graph.microsoft.com. Certificate subject CN=EntraCertAuthLab. 
Replace Tenant ID, Application (client) ID, certificate SHA-1 thumbprint, authority and Graph scope. 
GCC High authority login.microsoftonline.us with graph.microsoft.us; DoD authority login.microsoftonline.us with dod-graph.microsoft.us. For SPO-specific calls use the correct SharePoint resource instead of Graph. 

Environment      | Microsoft Graph endpoint
===========================================
Commercial / GCC | graph.microsoft.com
GCC High         | graph.microsoft.us
DoD	             | dod-graph.microsoft.us

#>


# creating certificate powershell
$cert = New-SelfSignedCertificate -Subject 'CN=EntraCertAuthLab' -CertStoreLocation 'Cert:\CurrentUser\My' -KeyAlgorithm RSA -KeyLength 2048 -HashAlgorithm SHA256 -KeySpec Signature -KeyUsage DigitalSignature -KeyExportPolicy Exportable -NotAfter (Get-Date).AddYears(1) 

New-Item -ItemType Directory -Path 'C:\temp\EntraCertLab' -Force | Out-Null 
Export-Certificate -Cert $cert -FilePath 'C:\temp\EntraCertLab\EntraCertAuthLab.cer' 
$pfxPassword = Read-Host 'Enter PFX export password' -AsSecureString 
Export-PfxCertificate -Cert $cert -FilePath 'C:\temp\EntraCertLab\EntraCertAuthLab.pfx' -Password $pfxPassword 
$cert | Format-List Subject,Thumbprint,HasPrivateKey,NotAfter 

#Upload only the .cer under Entra ID > App registrations > your app > Certificates & secrets > Certificates. 

#openssl
openssl pkcs12 -in "C:\temp\EntraCertLab\EntraCertAuthLab.pfx" -out "C:\temp\EntraCertLab\EntraCertAuthLab.pem" -nodes 

#The PEM is unencrypted. On the local Windows machine, confirm the file exists and verify the public certificate fingerprint: 
Test-Path 'C:\temp\EntraCertLab\EntraCertAuthLab.pem' 
openssl x509 -in 'C:\temp\EntraCertLab\EntraCertAuthLab.pem' -noout -fingerprint -sha1 

#Azure CLI certificate sign-in and token request 
# Commercial lab only; change to AzureUSGovernment for GCC High / DoD 
Use Az Module in Powershell
az cloud set --name AzureCloud 
az login --service-principal --tenant 'YOUR-TENANT-ID' --username 'YOUR-APPLICATION-CLIENT-ID' --password 'C:\temp\EntraCertLab\EntraCertAuthLab.pem' --allow-no-subscriptions 
az account get-access-token --resource 'https://graph.microsoft.com/' --query '{tokenType:tokenType,expiresOn:expiresOn}' --output json 

<#Generate PS256 client assertion in PowerShell 7 
Use the same certificate with accessible private key. 
This script produces $ps256SignedJwt and immediately submits it to Entra. 
It does not print the assertion. 
Please note the graph tokenendpoint : please confirm graph.microsoft.us or dod-graph.microsoft.us
#>

<# Start #>
$ErrorActionPreference = 'Stop' 
$tenantId = 'YOUR-TENANT-ID' 
$clientId = 'YOUR-APPLICATION-CLIENT-ID' 
$tokenEndpoint = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" 
$scope = 'https://graph.microsoft.com/.default' 
# For customer: substitute IDs, login.microsoftonline.us, and GCC High/DoD Graph scope. 
$matches = @(Get-ChildItem Cert:\CurrentUser\My | Where-Object Subject -eq 'CN=EntraCertAuthLab') 
if ($matches.Count -ne 1) { throw 'Select one exact certificate by SHA-1 thumbprint.' } 
$cert = $matches[0] 
if (-not $cert.HasPrivateKey) { throw 'No accessible private key.' } 
function To-Base64Url([byte[]]$bytes) { 
    return [Convert]::ToBase64String($bytes).TrimEnd('=').Replace('+','-').Replace('/','_') 
} 
$sha = [System.Security.Cryptography.SHA256]::Create() 
try { $digest = $sha.ComputeHash($cert.RawData) } finally { $sha.Dispose() } 
$x5tS256 = To-Base64Url $digest 
$header = @{ alg='PS256'; typ='JWT'; 'x5t#S256'=$x5tS256 } 
$now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() 
$claims = @{ aud=$tokenEndpoint; iss=$clientId; sub=$clientId; jti=[guid]::NewGuid().ToString(); iat=$now; nbf=$now; exp=$now+300 } 
$encodedHeader = To-Base64Url ([Text.Encoding]::UTF8.GetBytes(($header | ConvertTo-Json -Compress))) 
$encodedClaims = To-Base64Url ([Text.Encoding]::UTF8.GetBytes(($claims | ConvertTo-Json -Compress))) 
$unsigned = "$encodedHeader.$encodedClaims" 
$rsa = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($cert) 
if ($null -eq $rsa) { throw 'RSA private key unavailable.' } 
try { 
    $sig = $rsa.SignData([Text.Encoding]::ASCII.GetBytes($unsigned), [System.Security.Cryptography.HashAlgorithmName]::SHA256, [System.Security.Cryptography.RSASignaturePadding]::Pss) 
} finally { $rsa.Dispose() } 
$ps256SignedJwt = "$unsigned.$(To-Base64Url $sig)" 
Write-Host 'PS256 assertion generated; segments:' $ps256SignedJwt.Split('.').Count 
Write-Host 'Certificate SHA-1:' $cert.Thumbprint 
Write-Host 'x5t#S256:' $x5tS256 
<# end #>

# Submit assertion with Invoke-RestMethod 
# Run immediately after section above, before assertion expires. 
$body = @{ 
  client_id = $clientId 
  scope = $scope 
  grant_type = 'client_credentials' 
  client_assertion_type = 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer' 
  client_assertion = $ps256SignedJwt 
} 
try { 
  $tokenResponse = Invoke-RestMethod -Method POST -Uri $tokenEndpoint -Body $body -ContentType 'application/x-www-form-urlencoded' -ErrorAction Stop 
  Write-Host 'CERTIFICATE AUTHENTICATION SUCCESSFUL' -ForegroundColor Green 
  Write-Host 'Algorithm: PS256; token type:' $tokenResponse.token_type 
  Write-Host 'Expires in:' $tokenResponse.expires_in 'seconds' 
  Write-Host 'Access token received:' ([bool]$tokenResponse.access_token) 
} catch { 
  Write-Host 'CERTIFICATE AUTHENTICATION FAILED' -ForegroundColor Red 
  Write-Host $_.Exception.Message 
  if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message } 
} finally { 
  $body.Remove('client_assertion') 
  $ps256SignedJwt = $null 
} 
 
<# Should return 
==========
CERTIFICATE AUTHENTICATION SUCCESSFUL
==========
Authentication Method: Certificate / PS256
Token Type: Bearer
Expires In: 3599 seconds
Access Token Received: True

#>
<#
Verify Graph authorization separately 
First ensure Graph application permission Sites.Read.All or Sites. Selected has admin consent. For 
Sites.Selected, a separate grant to the specific site is also required. An access token alone does not prove SharePoint site access. 
#>

# Reuse $tokenResponse from the successful PowerShell token request. 
$headers = @{ Authorization = "Bearer $($tokenResponse.access_token)"; Accept='application/json' } 
# With Sites.Read.All, site search may be used: 
$sites = Invoke-RestMethod -Method GET -Uri 'https://graph.microsoft.com/v1.0/sites?search=*' -Headers $headers 
$sites.value | Select-Object id,name,webUrl 
# With Sites.Selected, test a site explicitly granted to the app: 
# $site = Invoke-RestMethod -Method GET -Uri 'https://graph.microsoft.com/v1.0/sites/contoso.sharepoint.com:/sites/TestSite' -Headers $headers 

<# return should be
id                                   name                            webUrl
--                                                                                                    ----                            ------
yourdomain.sharepoint.com,guid,guid  255AccessGroup                  https://domain.sharepoint.com/…
yourdomain.sharepoint.com,guid, guid DirectReportsDG01               https://domain.sharepoint.com/…
s#>
