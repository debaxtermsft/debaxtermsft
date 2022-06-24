#######################
# the below script uses the AzureADPreview powershell module pulling all roleassignments for groups
# It was created to pull the PIM Active and Eligible Role assignments for Azure AD Roles
# 06/24/2022 
# V1
# this will pull either all or selected azure ad administrator roles
# it will require logging into your tenant, selecting a destination folder and selecting either all or selected roles
# the file will automatically be saved to the directory with the present days date/time stamp to avoid overwriting existing files
# written by derrick baxter

Import-Module azureadpreview
# added to hide the notice about azuread soon to be deprecated - graph api version soon to be available
$WarningPreference = "SilentlyContinue"
#function for picking a directory to save the file
function save-directory([string] $initialDirectory, $filename)
    {

        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($dialog.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true; TopLevel = $true})) -eq [System.Windows.Forms.DialogResult]::OK) 
        {
            $directoryName = $dialog.SelectedPath
            Write-Host "Directory selected is $directoryName"
        }
        

        return $directoryName
    } 

#function for creating list boxes
function select-listbox ($grouptype, $selectType, $multivalue)
    {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Select ' + $selectType
    $width = 400
    $length = 300
    $form.Size = New-Object System.Drawing.Size(500,400)
    $form.StartPosition = 'CenterScreen'
    $form.Top = $true
    $form.TopMost = $true

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(300,330)
    $okButton.Size = New-Object System.Drawing.Size(75,23)
    $okButton.Text = 'OK'
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $okButton
    $form.Controls.Add($okButton)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(375,330)
    $cancelButton.Size = New-Object System.Drawing.Size(75,23)
    $cancelButton.Text = 'Cancel'
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $cancelButton
    $form.Controls.Add($cancelButton)

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10,20)
    $label.Size = New-Object System.Drawing.Size(365,30)
    $label.Text = 'Please select ' + $selectType
    $form.Controls.Add($label)

    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Location = New-Object System.Drawing.Point(10,50)
    $listBox.Size = New-Object System.Drawing.Size(465,30)
    $listbox.HorizontalScrollbar = $true
    $listBox.Height = 180
    $listBox.Font = New-Object System.Drawing.Font("Courier New",8,[System.Drawing.FontStyle]::Regular)
    
    if($multivalue)
        {
            $listBox.SelectionMode = 'MultiExtended'
        }
    foreach ($item in $grouptype)
        {
            [void] $listBox.Items.Add($item)
        }
    $form.Controls.Add($listBox)
    $form.Topmost = $true
    $result = $form.ShowDialog()
    if ($result -eq [System.Windows.Forms.DialogResult]::OK)
        {
            $x = $listBox.SelectedItems
            #$x
        }
    elseif ($result -eq [System.Windows.Forms.DialogResult]::Cancel)
        {
            
            break
        }
    return $x
    } # end function select-app


$outputdirectory    =@()
$AADRoleSelecttype  = @()
$pimaadroletype     = @()
$pimfilterselection =@()


#get the tenant details
try
{
    get-azureaduser -top 1
}
catch
{
    Connect-Azuread
}
$tenantid = (Get-AzureADTenantDetail).objectid
#getting output directory, file name is automatically created
$outputdirectory = save-directory
if ($outputdirectory -eq "Cancel"){exit}

#selection of all roles or select/multi-select aad roles
$AADRoleSelecttype     = "AAD Role Selection"
$pimaadroletype    = @("Export All AAD Roles","Select AAD Roles to Export")
$pimfilterselection =  select-listbox -grouptype $pimaadroletype -selectType $AADRoleSelecttype

$aadroles = Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadroles -ResourceId $tenantid | select-object displayname, resourceid, externalid | Sort-Object displayname
$aadrolesinfo =@()
#gets the aad roles
if($pimfilterselection -eq "Select AAD Roles to Export")
{
    $AADselection  =@()
    $AADSelecttype           =@()
    $AADSelecttype         = "Select Azure AD Admin Role(s)"
    $AADselection  =  select-listbox -grouptype $aadroles.displayname -selectType $AADSelecttype -multivalue $true
    foreach ($aadroleselected in $AADselection)
    {
        $aadroles = Get-AzureADMSPrivilegedRoleDefinition -ProviderId aadroles -ResourceId $tenantid | ?{$_.displayname -eq $aadroleselected}
        $aadrolesinfo += $aadroles
    }
    $AADselection =@()
    $AADselection = $aadrolesinfo
}
else {
    $AADselection =@()
    $AADselection = $aadroles
}
$aadroles =@()
$aadroleassignment =@()
$foundobject =@()
#gets roles assignments
foreach ($aaditem in $AADselection)
{
    $aadroleassignment = Get-AzureADMSPrivilegedRoleAssignment -ProviderId aadroles -resourceid $tenantid |  ?{$_.roledefinitionid -match $aaditem.externalid}
#    write-host "Finding roles for : " $aaditem.DisplayName
#    write-host "Total Roles Assigned to " $aaditem.DisplayName " is " $aadroleassignment.count
    foreach ($assignmentid in $aadroleassignment)
    {
        $findobject = Get-AzureADObjectByObjectId -ObjectIds $assignmentid.subjectid

        if ($findobject.objecttype -eq "User")
        {
        $aadroles += New-Object Object |
            Add-Member -NotePropertyName AADRoleDisplayName -NotePropertyValue $aaditem.DisplayName -PassThru |
            Add-Member -NotePropertyName AADID              -NotePropertyValue $aaditem.Id -PassThru |
            Add-Member -NotePropertyName AADExternalID      -NotePropertyValue $aaditem.externalid -PassThru |
            Add-Member -NotePropertyName ResourceID         -NotePropertyValue $aaditem.ResourceId -PassThru |
            #objectinfo
            Add-Member -NotePropertyName DisplayName        -NotePropertyValue $findobject.displayname -PassThru |
            Add-Member -NotePropertyName ObjectID           -NotePropertyValue $findobject.objectid -PassThru |
            Add-Member -NotePropertyName AssignmentID           -NotePropertyValue $assignmentid.id -PassThru |
            Add-Member -NotePropertyName AssignmentStartDateTime -NotePropertyValue $assignmentid.startdatetime -PassThru |
            Add-Member -NotePropertyName AssignmentEndDateTime  -NotePropertyValue $assignmentid.enddatetime -PassThru |
            Add-Member -NotePropertyName AssignmentState        -NotePropertyValue $assignmentid.AssignmentState -PassThru |
            Add-Member -NotePropertyName AssignmentMemberType   -NotePropertyValue $assignmentid.MemberType -PassThru |
            #additional properties
            Add-Member -NotePropertyName ObjectType  -NotePropertyValue $findobject.objecttype -PassThru |
            Add-Member -NotePropertyName mail  -NotePropertyValue $findobject.mail -PassThru |
            Add-Member -NotePropertyName userprincipalname  -NotePropertyValue $findobject.UserPrincipalName -PassThru |
            Add-Member -NotePropertyName ApplicationID  -NotePropertyValue $findobject.AppId -PassThru 

            
        }
        elseif($findobject.objecttype -eq "Group")
        {
            $aadroles += New-Object Object |
            Add-Member -NotePropertyName AADRoleDisplayName -NotePropertyValue $aaditem.DisplayName -PassThru |
            Add-Member -NotePropertyName AADID              -NotePropertyValue $aaditem.Id -PassThru |
            Add-Member -NotePropertyName AADExternalID      -NotePropertyValue $aaditem.externalid -PassThru |
            Add-Member -NotePropertyName ResourceID         -NotePropertyValue $aaditem.ResourceId -PassThru |
            #objectinfo
            Add-Member -NotePropertyName DisplayName        -NotePropertyValue $findobject.displayname -PassThru |
            Add-Member -NotePropertyName ObjectID           -NotePropertyValue $findobject.objectid -PassThru |
            Add-Member -NotePropertyName AssignmentStartDateTime -NotePropertyValue $assignmentid.startdatetime -PassThru |
            Add-Member -NotePropertyName AssignmentEndDateTime  -NotePropertyValue $assignmentid.enddatetime -PassThru |
            Add-Member -NotePropertyName AssignmentState        -NotePropertyValue $assignmentid.AssignmentState -PassThru |
            Add-Member -NotePropertyName AssignmentMemberType   -NotePropertyValue $assignmentid.MemberType -PassThru |
                        #additional properties
            Add-Member -NotePropertyName ObjectType  -NotePropertyValue $findobject.objecttype -PassThru |
            Add-Member -NotePropertyName mail  -NotePropertyValue $findobject.mail -PassThru |
            Add-Member -NotePropertyName userprincipalname  -NotePropertyValue $findobject.UserPrincipalName -PassThru |
            Add-Member -NotePropertyName ApplicationID  -NotePropertyValue $findobject.AppId -PassThru 
            

        }
        else 
        {
            $aadroles += New-Object Object |
            Add-Member -NotePropertyName AADRoleDisplayName -NotePropertyValue $aaditem.DisplayName -PassThru |
            Add-Member -NotePropertyName AADID              -NotePropertyValue $aaditem.Id -PassThru |
            Add-Member -NotePropertyName AADExternalID      -NotePropertyValue $aaditem.externalid -PassThru |
            Add-Member -NotePropertyName ResourceID         -NotePropertyValue $aaditem.ResourceId -PassThru |
            #objectinfo
            Add-Member -NotePropertyName DisplayName        -NotePropertyValue $findobject.displayname -PassThru |
            Add-Member -NotePropertyName ObjectID           -NotePropertyValue $findobject.objectid -PassThru |
            Add-Member -NotePropertyName AssignmentStartDateTime -NotePropertyValue $assignmentid.startdatetime -PassThru |
            Add-Member -NotePropertyName AssignmentEndDateTime  -NotePropertyValue $assignmentid.enddatetime -PassThru |
            Add-Member -NotePropertyName AssignmentState        -NotePropertyValue $assignmentid.AssignmentState -PassThru |
            Add-Member -NotePropertyName AssignmentMemberType   -NotePropertyValue $assignmentid.MemberType -PassThru |
            #additional properties
            Add-Member -NotePropertyName ObjectType  -NotePropertyValue $findobject.objecttype -PassThru |
            Add-Member -NotePropertyName mail  -NotePropertyValue $findobject.mail -PassThru |
            Add-Member -NotePropertyName userprincipalname  -NotePropertyValue $findobject.UserPrincipalName -PassThru |
            Add-Member -NotePropertyName ApplicationID  -NotePropertyValue $findobject.AppId -PassThru 
            
        }


    }

}

$tdy        = get-date -Format "MM-dd-yyyy hh.mm.ss"
$filename1  = "PIM Assignment Export AAD Roles and Admins" + $pimfilterselection + " " + $tdy +".csv"           
$OutputFile = "$outputdirectory"+"\"+"$filename1"
$aadroles | export-csv -Path $outputfile -force -Encoding UTF8 -NoTypeInformation
