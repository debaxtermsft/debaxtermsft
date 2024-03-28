<# 
Written by Derrick Baxter
3/14/24
3/28/24 Updated / Cleaned up code
Retrieves directory object count/quota and object counts of users, groups, devices, applications and service principals
pick the signin activity below (unrem) and run
Update the $outputfile location from c:\temp\name as wanted - date and .csv are automatically added to avoid overwritting  
NOTE: DeletedRecoveryEstimate is an ESTIMATED recovery if perm deleted
.\DO.ps1 -Outputdirectory c:\temp\
format example along with CSV export

DirectoryQuotaTotal DirectoryQuotaUsed DirectoryQuotaApproximateRemaining UserObjects GroupObjects ApplicationObjects ServicePrincipalObjects DeviceObjects DeletedUserObjects DeletedGroupObjects
------------------- ------------------ ---------------------------------- ----------- ------------ ------------------ ----------------------- ------------- ------------------ -------------------
             300000               1509                             298491         300          255                 34                     621            12                  3                   3


DirectoryQuotaTotal                : 300000
DirectoryQuotaUsed                 : 1509
DirectoryQuotaApproximateRemaining : 298491
UserObjects                        : 300
GroupObjects                       : 255
ApplicationObjects                 : 34
ServicePrincipalObjects            : 621
DeviceObjects                      : 12
DeletedUserObjects                 : 3
DeletedGroupObjects                : 3
DeletedApplicationObjects          : 1
DeletedServicePrincipalObjects     : 1
DeletedDeviceObjects               : 0
DeletedRecoveryEstimate            : 8

IMPORTANT!!!

To consent for users to run this script a global admin will need to run the following
-------------------------------------------------------------------------------------------

$sp = get-mgserviceprincipal | ?{$_.displayname -eq "Microsoft Graph"}
$resource = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"
$principalid = "users object id"
$scope1 ="directory.read.all"
$today = Get-Date -Format "yyyy-MM-dd"
$expiredate1 = get-date
$expiredate2 = $expiredate1.AddDays(365).ToString("yyyy-MM-dd")
$params = @{
    ClientId = $SP.Id
    ConsentType = "Principal"
    ResourceId = $resource.id
    principalId = $principalid
    Scope = "$scope1" 
    startTime = "$today"
    expiryTime = "$expiredate2"
    
}

$InitialConsented = New-MgOauth2PermissionGrant -BodyParameter $params
-------------------------------------------------------------------------------------------
You may need to update the connect-mggraph to have the -environment USGov or as needed -tenantid <tenantid> can be added as needed.

#>
param([parameter(Position=0,mandatory)][string]$Outputdirectory)
#testing if user is already logged into graph
try
    {
    Get-MGDomain -ErrorAction Stop > $null
    }
catch
    {
    Connect-MgGraph -Scopes "directory.read.all"
    }
# Retrieving Org Quota
$org                = get-mgorganization | select -ExpandProperty AdditionalProperties
$total              = $org.directorySizeQuota.total
$used               = $org.directorySizeQuota.used
$remaining          = $total - $used
# Retrieving Current object counts
$users              = (get-mguser -all).count
$groups             = (get-mggroup -all).count
$devices            = (get-mgdevice -all).count
$applications       = (get-mgapplication -all).count
$serviceprincipals  = (get-mgserviceprincipal -all).count
$objects            = $users + $groups + $devices +$applications + $serviceprincipals
# Retrieving Deleted Object Counts - These do count against the quota
$deletedUserCount               = (Get-MgDirectoryDeleteduser -all).count
$deletedgroupCount              = (Get-MgDirectoryDeletedgroup -all).count
$deletedapplicationCount        = (Get-MgDirectoryDeletedApplication -all).count
$deletedserviceprincipalCount   = (Get-MgDirectoryDeletedserviceprincipal -all).count
$deleteddeviceCount             = (Get-MgDirectoryDeleteddevice -all).count
$deletedRecoveryEstimate        = $deleteddeviceCount + $deletedserviceprincipalCount  + $deletedapplicationCount  + $deletedgroupCount + $deleteduserCount 
# Building the Object to be exported
$DirectoryObjectCount           =@()
$DirectoryObjectCount           += New-Object Object |
                                    Add-Member -NotePropertyName DirectoryQuotaTotal -NotePropertyValue $total -PassThru | 
                                    Add-Member -NotePropertyName DirectoryQuotaUsed -NotePropertyValue $used -PassThru |
                                    Add-Member -NotePropertyName DirectoryQuotaApproximateRemaining -NotePropertyValue $Remaining -PassThru |
                                    Add-Member -NotePropertyName UserObjects -NotePropertyValue $users -PassThru |
                                    Add-Member -NotePropertyName GroupObjects -NotePropertyValue $groups -PassThru |
                                    Add-Member -NotePropertyName ApplicationObjects -NotePropertyValue $applications -PassThru |
                                    Add-Member -NotePropertyName ServicePrincipalObjects -NotePropertyValue $serviceprincipals -PassThru |
                                    Add-Member -NotePropertyName DeviceObjects -NotePropertyValue $devices -PassThru |
                                    Add-Member -NotePropertyName DeletedUserObjects -NotePropertyValue $deletedUserCount -PassThru |
                                    Add-Member -NotePropertyName DeletedGroupObjects -NotePropertyValue $deletedgroupCount -PassThru |
                                    Add-Member -NotePropertyName DeletedApplicationObjects -NotePropertyValue $deletedapplicationCount -PassThru |
                                    Add-Member -NotePropertyName DeletedServicePrincipalObjects -NotePropertyValue $deletedserviceprincipalCount -PassThru |
                                    Add-Member -NotePropertyName DeletedDeviceObjects -NotePropertyValue $deleteddeviceCount -PassThru |
                                    Add-Member -NotePropertyName DeletedRecoveryEstimate -NotePropertyValue $deletedRecoveryEstimate -PassThru 

$tdy                            = get-date -Format "MM-dd-yyyy hh.mm.ss"
$file                           = $outputdirectory +"EntraDirectoryQuota_and_objectcounter_"+$tdy+".csv"
$DirectoryObjectCount | export-csv -path $file -NoTypeInformation -Encoding UTF8
#Rem out the display of the variable if you do not want to have this exported to the screen
$DirectoryObjectCount | FT
$DirectoryObjectCount | FL