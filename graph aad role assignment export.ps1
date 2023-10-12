<#
 the below script uses the AzureAD powershell module pulling all roleassignments for groups
10/12/23
# updates 
# written by debaxter



IMPORTANT!!!

To consent for users to run this script a global admin will need to run the following
-------------------------------------------------------------------------------------------
$sp = get-mgserviceprincipal | ?{$_.displayname -eq "Microsoft Graph"}
$resource = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"
$principalid = "users object id"
$scope1 ="group.read.all"
$scope2 ="directory.read.all"
$scope3 ="groupmember.read.all"
$scope4 ="Policy.Read.ConditionalAccess"
$scope5 ="Application.Read.All"

$params = @{
    ClientId = $SP.Id
    ConsentType = "Principal"
    ResourceId = $resource.id
    principalId = $principalid
    Scope = "$scope1" + " " + "$scope2"+ " " + "$scope3"+ " " + "$scope4"+ " " + "$scope5"
}

$InitialConsented = New-MgOauth2PermissionGrant -BodyParameter $params
-------------------------------------------------------------------------------------------
You may need to update the connect-mggraph to have the -environment USGov or as needed -tenantid <tenantid> can be added as needed.

#>

Import-Module Microsoft.Graph.DeviceManagement.Enrollment
function save-file([string] $initialDirectory, $filename)
    {
        $outputfile = $filename
        $SaveFileDialog = New-Object windows.forms.savefiledialog  
        $SaveFileDialog.FileName = $filename 
        $SaveFileDialog.initialDirectory = $initialDirectory
        $SaveFileDialog.title = "Save File to Disk"
        $SaveFileDialog.filter = "AzureADRoleExports | AAD Roles Export*.csv|Comma Seperated File|*.csv | All Files|*.* " 
        $SaveFileDialog.ShowHelp = $True   

        $result = $SaveFileDialog.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true; TopLevel = $true}))
        
        if($SaveFileDialog.Filenames -eq "" ) 
            {
             #   write-host "Its not Null" 
                exit
            } 
        else
            {
                $x = $SaveFileDialog.Filename  
            }
        return $x
    } 


try
    {
    Get-MGDomain -ErrorAction Stop > $null
    }
catch
    {
    Connect-MgGraph -Scopes "group.read.all, directory.read.all, groupmember.read.all, Policy.Read.All, Application.Read.All"
    Select-MgProfile -Name "beta"
    }

        $members =@()
        #foreach ($item in $aadrole)
        #{
            $filter1 = "roleDefinitionId eq "+"'"+$item.Id+"'"
            #$aadrolemember = Get-MgRoleManagementDirectoryRoleAssignment -Filter "$filter1" 
            $aadrolemember = Get-MgRoleManagementDirectoryRoleAssignment -all | Sort-Object RoleDefinitionId
            write-host "Role assignment count : " $aadrolemember.count
           if ($aadrolemember -ne $null)
           {
                foreach ($item2 in $aadrolemember) 
                    {
                        
                        $filter1 = "roleDefinitionId eq "+"'"+$item2.RoleDefinitionId+"'"
                        $filter2 = " and "
                        $filter3 = "principalid eq "+"'"+$item2.PrincipalId+"'"
                        $filter4 = $filter1+$filter2+$filter3
                        $aadroleassignment = Get-MgRoleManagementDirectoryRoleAssignment -Filter "$filter4" 
                        $dirobjecttype = get-mgdirectoryobjectbyid -ids $item2.PrincipalId
                        $aadroledefinition = Get-MgRoleManagementDirectoryRoleDefinition -UnifiedRoleDefinitionId $item2.RoleDefinitionId
                        foreach($aadroleassignmentitem in $aadroleassignment)
                        {
                            if ($dirobjecttype.additionalproperties.values -like "*microsoft.graph.user*")
                            {
                                    $dirobject = get-mguser -userid $item2.PrincipalId 
                                    write-host "Found user " $dirobject.displayname  " in aad role " $aadroledefinition.displayname " Scope " $aadroleassignmentitem.DirectoryScopeId
                                    $type = "User"
                            }
                        
                            elseif ($dirobjecttype.additionalproperties.values -like "*microsoft.graph.group*")
                            {
                                    $dirobject = get-mggroup -groupId $item2.PrincipalId 
                                    write-host "Found group " $dirobject.displayname  " in aad role " $aadroledefinition.displayname " Scope " $aadroleassignmentitem.DirectoryScopeId
                                    $type = "Group"
                            }
                            else
                            {
                                    $dirobject =  get-mgserviceprincipal -ServicePrincipalId $item2.PrincipalId 
                                    write-host "Found SERVICE PRINCIPAL" $dirobject.displayname " in aad role " $aadroledefinition.displayname " Scope " $aadroleassignmentitem.DirectoryScopeId
                                    $type = "ServicePrincipal"

                            }
                                  $members += New-Object Object |
                                            Add-Member -NotePropertyName DisplayName -NotePropertyValue $dirobject.displayname -PassThru |
                                            Add-Member -NotePropertyName ObjectID -NotePropertyValue $dirobject.id -PassThru |
                                            Add-Member -NotePropertyName AADRoleName -NotePropertyValue $aadroledefinition.displayname -PassThru |
                                            Add-Member -NotePropertyName AADRoleDefinitionID -NotePropertyValue $aadroledefinition.ID -PassThru |
                                            Add-Member -NotePropertyName AADObjectType -NotePropertyValue $Type -PassThru |
                                            Add-Member -NotePropertyName AADRoleassignmentID -NotePropertyValue $aadroleassignmentitem.id -PassThru |
                                            Add-Member -NotePropertyName AADDirectoryScope -NotePropertyValue $aadroleassignmentitem.DirectoryScopeId -PassThru
                        }

                    }
           }
           #start-sleep 1
        #}
        #return $members
        $tdy = get-date -Format "MM-dd-yyyy hh.mm.ss"
        $outputfile = "AADRoleAssignmentExport_"+$tdy+".csv"
        $OutputFile = save-file -filename $outputfile -initialDirectory $env:HOMEDRIVE
        if ($OutputFile -eq "Cancel"){break}
        $members  | Sort-Object AADRoleName, DisplayName | export-csv -Path $OutputFile -NoTypeInformation -Encoding utf8 -Force

    
