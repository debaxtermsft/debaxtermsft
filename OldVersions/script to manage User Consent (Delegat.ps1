# script to manage User Consent (Delegated permission).  The following script does 
#    - Remove all MS Graph Delegated permissions (if any) for the user
#    - Perform user consent for an initial set of MS Graph permission
#    - Update the consented permission list with some additional permissions
#    - Remove some permissions from the consented permission list
#    - Remove (revoke) all consented permissions for the user

# Continue to output logs - SilentlyContinue to keep going
$GLOBAL:DebugPreference="SilentlyContinue"
 
$ClientAppId = "<Fill in your Application ID>"
$resourceAppIdThatOwnsScope = "00000003-0000-0000-c000-000000000000" # MS Graph App ID
$principalid = "<Fill in your User Object ID>"
$scope1 = "User.Read.All"
$scope2 = "Mail.Send"
$scope3 = "AuditLog.Read.All"
$scope4 = "Domain.Read.All"
$tenantId = "<Fill in your tenant ID>"
 
Connect-MgGraph -TenantId $tenantId -Scopes "Directory.Read.All","DelegatedPermissionGrant.ReadWrite.All"
 
# Get the ServicePrincipal Object ID for the client application
# MS Graph Request
#  https://graph.microsoft.com/v1.0/servicePrincipals?$filter=appId eq '<ClientAppId>'
$SPtoManageConsent = Get-MgServicePrincipal -Filter "appId eq '$ClientAppId'"
$SPClientId = $SPtoManageConsent.Id
Write-Host "Client App ServicePrincipal ObjectID: $SPClientId"
 
# Get the ServicePrincipal Object ID for the Resource Application MS Graph
# MS Graph Request
# GET https://graph.microsoft.com/v1.0/servicePrincipals?$filter=appId eq '00000003-0000-0000-c000-000000000000'
$resourceSP = Get-MgServicePrincipal -Filter "appId eq '$resourceAppIdThatOwnsScope'"
$resourceId = $resourceSP.Id
Write-Host "Resource App (MS Graph) ServicePrincipal ObjectID: $resourceId"
 
# Check to see the user has already consented any MS Graph permission to this application
$spOAuth2PermissionsGrants = $null
$spOAuth2PermissionsGrants = Get-MgOauth2PermissionGrant -Filter "clientId eq '$SPClientId' and resourceId eq '$resourceId' and principalId eq '$principalid'"
# MS Graph Request
# GET https://graph.microsoft.com/v1.0/oauth2PermissionGrants?$filter=clientId eq '<client App ServicePrincipal ObjectID>' and resourceId eq '<Resource App ServicePrincipal ObjectID>' and principalId eq '<user ObjectID>'
if ($spOAuth2PermissionsGrants)
    {
        Write-Host "Removing OAuth2 Permission Grant"
        ($spOAuth2PermissionsGrants) | FL
        Remove-MgOauth2PermissionGrant -OAuth2PermissionGrantId $spOAuth2PermissionsGrants.Id
    }
 
# Granting initial permission set to user
 
$params = @{
    ClientId = $SPClientId
    ConsentType = "Principal"
    ResourceId = $resourceId
    principalId = $principalid
    Scope = "$scope1" + " " + "$scope2"
}
 
Write-Host "Giving user iniital Consented Permissions $scope1 and $scope2"
# MS Graph Request
# POST https://graph.microsoft.com/v1.0/oauth2PermissionGrants
# Request Body:
<# {
    "clientId": "<Client ServicePrincipal ObjectID>",
    "consentType": "Principal",
    "principalId": "<User ObjectID>",
    "resourceId": "<MS Graph ServicePrincipal ObjectID>"",
    "scope": "User.Read.All Mail.Send"
} #>
 
$InitialConsented = New-MgOauth2PermissionGrant -BodyParameter $params
Write-Host "Consented permission - Oauth2PermissionGrant Object:"
($InitialConsented) | FL
 
# Get Consented Permission ID
$consentId = $InitialConsented.Id
 
Write-Host "Update consented permission list with 2 more permisions: $scope3 and $scope4"
$scope = $InitialConsented.Scope + " " + "$scope3" + " " + "$scope4"
 
# MS Graph Request
# PATCH https://graph.microsoft.com/v1.0/oauth2PermissionGrants/<OAuth2PermissionGrantId>
# Request body:
<# {
    "scope": "User.Read.All Mail.Send AuditLog.Read.All Domain.Read.All"
} #>
 
Update-MgOauth2PermissionGrant -OAuth2PermissionGrantId $consentId -Scope $scope.Trim(" ")
 
# MS Graph Request
# GET https://graph.microsoft.com/v1.0/oauth2PermissionGrants/<OAuth2PermissionGrantId>
$spOAuth2PermissionsGrants = Get-MgOauth2PermissionGrant -OAuth2PermissionGrantId $consentId
 
Write-Host("Updated OAuth2Per3missiongGrant Object")
($spOAuth2PermissionsGrants) | FL
 
Write-Host "Removing these permissions $scope1 and $scope3 from the consented list"
$newscope = "$scope2" + " " + "$scope4"
 
# MS Graph Request
# PATCH https://graph.microsoft.com/v1.0/oauth2PermissionGrants/<OAuth2PermissionGrantId>
# Request body:
<# {
    "scope": "Mail.Send Domain.Read.All"
} #>
 
Update-MgOauth2PermissionGrant -OAuth2PermissionGrantId $consentId -Scope $newscope.Trim(" ")
$spOAuth2PermissionsGrants = Get-MgOauth2PermissionGrant -OAuth2PermissionGrantId $consentId
Write-Host("Updated OAuth2PermissiongGrant Object")
($spOAuth2PermissionsGrants) | FL
 
 
Write-Host "Remvoving all consented permissions for this user"
# MS Graph Request
# DELETE https://graph.microsoft.com/v1.0/oauth2PermissionGrants/<OAuth2PermissionGrantId>
Remove-MgOauth2PermissionGrant -OAuth2PermissionGrantId $consentId
 
Write-Host "done..."
Disconnect-MgGraph