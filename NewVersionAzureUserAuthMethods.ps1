<#
Written By Derrick Baxter debaxter@microsoft.com
The below script uses the Azure Graph powershell module pulling all user Auth Methods

written: 5/4/23


You may need to have a global admin run the below rem'ed script to concent to the user to run this script

$sp = get-mgserviceprincipal | ?{$_.displayname -eq "Microsoft Graph"}
$resource = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"
$principalid = "user object id"
$scope1 ="user.read.all"
$scope2 ="directory.read.all"
$scope3 ="UserAuthenticationMethod.Read.All"
$today = Get-Date -Format "yyyy-MM-dd"
$expiredate1 = get-date
$expiredate2 = $expiredate1.AddDays(365).ToString("yyyy-MM-dd")
$params = @{
    ClientId = $SP.Id
    ConsentType = "Principal"
    ResourceId = $resource.id
    principalId = $principalid
    Scope = "$scope1" + " " + "$scope2"+ " " + "$scope3"
    startTime = "$today"
    expiryTime = "$expiredate2"
}
$InitialConsented = New-MgOauth2PermissionGrant -BodyParameter $params


You may need to update the connect-mggraph to have the -environment USGov or as needed -tenantid <tenantid> can be added as needed.

#>

connect-mggraph -scope "directory.read.all,UserAuthenticationMethod.Read.All, user.read.all"
Select-MgProfile "beta"
$auth  =@()
$value =@()
$keys  = @()
$AuthMethodObject = @()
$AuthMethodObject2 = @()

$queryURIheader1 = "https://graph.microsoft.com/v1.0/users/"
$queryURItrailer1 = "/authentication/methods"
#$userlist = get-mguser -all | select id, displayname, UserPrincipalName | sort-object -property displayname, userprincipalname
#$userlist = get-mguser -top 10 | select id, displayname, UserPrincipalName | sort-object -property displayname, userprincipalname
$userlist = get-mguser -UserId  8c9df1a2-713c-459c-b8c6-79773ac6be92 | select id, displayname, UserPrincipalName | sort-object -property displayname, userprincipalname
$counter = 0
foreach ($useritem in $userlist)
    {
        [string]$URIpassed = $queryURIheader1 + $useritem.id + $queryURItrailer1
        $queryreturned = Invoke-MgGraphRequest -Uri $URIpassed -method GET }

        $AuthMethodObject += New-Object Object |
            Add-Member -NotePropertyName Id -NotePropertyValue $useritem.id -PassThru |
            Add-Member -NotePropertyName DisplayName -NotePropertyValue $useritem.displayname -PassThru |
            Add-Member -NotePropertyName UserPrincipalName -NotePropertyValue $useritem.UserprincipalName -PassThru | 
            Add-Member -NotePropertyName emailMethod -NotePropertyValue -PassThru | 
            Add-Member -NotePropertyName fido2Method -NotePropertyValue -PassThru | 
            Add-Member -NotePropertyName MicrosoftAuthenticatorMethod -NotePropertyValue -PassThru | 
            Add-Member -NotePropertyName passwordMethod -NotePropertyValue -PassThru | 
            Add-Member -NotePropertyName phoneMethod -NotePropertyValue -PassThru | 
            Add-Member -NotePropertyName softwareOathMethod -NotePropertyValue -PassThru | 
            Add-Member -NotePropertyName temporaryAccessPathMethod -NotePropertyValue -PassThru | 
            Add-Member -NotePropertyName windowsHelloforBusinessMethod -NotePropertyValue -PassThru 


        $authlist = $queryreturned.Value
        foreach($authitem in $authlist)
            {
                $keys = $authitem.keys
                $values = $authitem.values
                foreach ($keyitem in $keys)
                {
                    #write-host $keyitem
                    #write-host $authitem.$keyitem
                    #$AuthMethodObject2 += New-Object Object |
                    $name1 = $useritem.id+"_"+$keyitem
                    $value1 = $authitem.$keyitem
                     $AuthMethodObject | Add-Member -NotePropertyName $name1 -NotePropertyValue $value1 -PassThru 
                     #$AuthMethodObject | Add-Member -NotePropertyName $value1 -NotePropertyValue $authitem.$keyitem -PassThru 
                      
                }

            }
        #start-sleep added to avoid 429 throttling issues, this may have to be increased if needed
        if($counter = 999)
        {
        start-sleep 1
        $counter = 0
        }
        else {$counter++}
    }

$AuthMethodObject | Sort-Object -Property Userprincipalname, displayname | ft

$AuthMethodObject | export-csv -Path "c:\temp\userauthmethods5-4-23.csv" -Encoding utf8 -NoTypeInformation