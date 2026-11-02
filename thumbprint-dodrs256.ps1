<#
written by derrick baxter
create rs256 bearer token, auth and sharepoint search
10/30/2026#>


$ErrorActionPreference = 'Stop'
 $tenantId = 'tenantid'
 $clientId = 'appid'
 $tokenEndpoint = "https://login.microsoftonline.us/$tenantId/oauth2/v2.0/token"
 $scope = 'https://dod-graph.microsoft.us/.default'
 # For customer: substitute IDs, login.microsoftonline.us, and GCC High/DoD Graph scope.

#getting thumbprint 
# ============================================================
# SELECT CERTIFICATE BY SHA-1 THUMBPRINT
# ============================================================

# Change this value to test either certificate
$thumbprint = 'YOUR-CERTIFICATE-SHA1-THUMBPRINT'

# Remove spaces from thumbprint
$thumbprint = $thumbprint.Replace(' ', '')

# Retrieve certificate from Windows certificate store
$cert = Get-Item "Cert:\CurrentUser\My\$thumbprint" -ErrorAction Stop

# Verify private key exists
if (-not $cert.HasPrivateKey) {
    throw 'Certificate does not have an accessible private key.'
}

Write-Host "Testing certificate:" $cert.Subject
Write-Host "Certificate SHA-1:" $cert.Thumbprint
Write-Host "Private key available:" $cert.HasPrivateKey


 function To-Base64Url([byte[]]$bytes) {
     return [Convert]::ToBase64String($bytes).TrimEnd('=').Replace('+','-').Replace('/','_')
 }
 $sha = [System.Security.Cryptography.SHA256]::Create()
 try { $digest = $sha.ComputeHash($cert.RawData) } finally { $sha.Dispose() }
 $x5tS256 = To-Base64Url $digest
 $header = @{ alg='RS256'; typ='JWT'; 'x5t#S256'=$x5tS256 }
 $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
 $claims = @{ aud=$tokenEndpoint; iss=$clientId; sub=$clientId; jti=[guid]::NewGuid().ToString(); iat=$now; nbf=$now; exp=$now+300 }
 $encodedHeader = To-Base64Url ([Text.Encoding]::UTF8.GetBytes(($header | ConvertTo-Json -Compress)))
 $encodedClaims = To-Base64Url ([Text.Encoding]::UTF8.GetBytes(($claims | ConvertTo-Json -Compress)))
 $unsigned = "$encodedHeader.$encodedClaims"
 $rsa = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($cert)
 if ($null -eq $rsa) { throw 'RSA private key unavailable.' }
 try {
     $sig = $rsa.SignData([Text.Encoding]::ASCII.GetBytes($unsigned), [System.Security.Cryptography.HashAlgorithmName]::SHA256, [System.Security.Cryptography.RSASignaturePadding]::Pkcs1)
 } finally { $rsa.Dispose() }
 $rs256SignedJwt = "$unsigned.$(To-Base64Url $sig)"
 Write-Host 'RS256 assertion generated; segments:' $rs256SignedJwt.Split('.').Count
 Write-Host 'Certificate SHA-1:' $cert.Thumbprint
 Write-Host 'x5t#S256:' $x5tS256



$body = @{
   client_id = $clientId
   scope = $scope
   grant_type = 'client_credentials'
   client_assertion_type = 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer'
   client_assertion = $rs256SignedJwt
 }
try {
   $tokenResponse = Invoke-RestMethod -Method POST -Uri $tokenEndpoint -Body $body -ContentType 'application/x-www-form-urlencoded' -ErrorAction Stop
   Write-Host 'CERTIFICATE AUTHENTICATION SUCCESSFUL' -ForegroundColor Green
   Write-Host 'Algorithm: RS256; token type:' $tokenResponse.token_type
   Write-Host 'Expires in:' $tokenResponse.expires_in 'seconds'
   Write-Host 'Access token received:' ([bool]$tokenResponse.access_token)
 } catch {
   Write-Host 'CERTIFICATE AUTHENTICATION FAILED' -ForegroundColor Red
   Write-Host $_.Exception.Message
   if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message }
 } finally {
   $body.Remove('client_assertion')
   $rs256SignedJwt = $null
 }


$headers = @{ Authorization = "Bearer $($tokenResponse.access_token)"; Accept='application/json' }
# With Sites.Read.All, site search may be used:
$sites = Invoke-RestMethod -Method GET -Uri 'https://dod-graph.microsoft.us/v1.0/sites?search=*&$top=10' -Headers $headers
$sites.value | Select-Object id,name,webUrl
