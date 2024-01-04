#######################
# the below script uses the AzureAD powershell module pulling all roleassignments for groups
# 3/2/2022
# updates 
# written by debaxter
#######################
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

function select-box ($selectedoption, $selectType, $groupselect, $multivalue)
    {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Select ' + $selectType
    $form.Size = New-Object System.Drawing.Size(400,300)
    $form.StartPosition = 'CenterScreen'
    $form.Top = $true
    $form.TopMost = $true

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(200,230)
    $okButton.Size = New-Object System.Drawing.Size(75,23)
    $okButton.Text = 'OK'
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $okButton
    $form.Controls.Add($okButton)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(275,230)
    $cancelButton.Size = New-Object System.Drawing.Size(75,23)
    $cancelButton.Text = 'Cancel'
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $cancelButton
    $form.Controls.Add($cancelButton)

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10,20)
    $label.Size = New-Object System.Drawing.Size(365,20)
    $label.Text = 'Please select ' + $selectType
    $form.Controls.Add($label)


    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Location = New-Object System.Drawing.Point(10,50)
    $listBox.Size = New-Object System.Drawing.Size(365,20)
    $listBox.Height = 180
    
    if($multivalue)
        {
            $listBox.SelectionMode = 'MultiExtended'
        }

    foreach ($item in $selectedoption)
        {
            [void] $listBox.Items.Add($item)
        }
    foreach ($item in $groupselect)
        {
            [void] $listBox.Items.Add($item)
        }

    $form.Controls.Add($listBox)
    $form.Topmost = $true
    $result = $form.ShowDialog()
    if ($result -eq [System.Windows.Forms.DialogResult]::OK)
        {
            $x = $listBox.SelectedItems
        }
    elseif ($result -eq [System.Windows.Forms.DialogResult]::Cancel)
        {
            
            exit
        }
    return $x
    } # end function select-app

function find-aadroleinfo($type)
{
        $aadrole = Get-AzureADDirectoryRole |Sort-Object DisplayName
        $members =@()
        clsget
        foreach ($item in $aadrole)
        {
           if ($type -eq "All")
           {
               $aadrolemember = get-AzureADDirectoryRolemember -objectid $item.ObjectId | sort-object objecttype, displayname
           }
           else
           {
               $aadrolemember = get-AzureADDirectoryRolemember -objectid $item.ObjectId | Where-Object {$_.ObjectType -eq $type} | sort-object objecttype, displayname
           }
           if ($aadrolemember -ne $null)
           {
                foreach ($item2 in $aadrolemember) 
                    {
                        
                        $filter1 = "roleDefinitionId eq "+"'"+$item.RoleTemplateId+"'"
                        $filter2 = " and "
                        $filter3 = "principalid eq "+"'"+$item2.objectid+"'"
                        $filter4 = $filter1+$filter2+$filter3
                        $aadroleassignment = get-azureadmsroleassignment -Filter "$filter4" #| select Displayname, Objectid, ObjectType, Id , DirectoryScopeId
                       # $aadroleassignment
                        if ($item2.ObjectType -eq "User")
                        {
                                $dirobject = get-azureaduser -ObjectId $item2.ObjectId 
                        }
                        
                        elseif ($item2.ObjectType -eq "Group")
                        {
                                $dirobject = get-azureadgroup -ObjectId $item2.ObjectId 
                        }
                        else
                        {
                               # write-host $item.DisplayName, $item2.displayname 
                                $dirobject =  Get-AzureADServicePrincipal -ObjectId $item2.ObjectId 
                        }
                              $members += New-Object Object |
                                        Add-Member -NotePropertyName DisplayName -NotePropertyValue $dirobject.displayname -PassThru |
                                        Add-Member -NotePropertyName UserPrincipalName -NotePropertyValue $dirobject.userprincipalname -PassThru |
                                        Add-Member -NotePropertyName ObjectID -NotePropertyValue $dirobject.objectid -PassThru |
                                        Add-Member -NotePropertyName AADRoleName -NotePropertyValue $item.displayname -PassThru |
                                        Add-Member -NotePropertyName AADRoleObjectID -NotePropertyValue $item2.ObjectID -PassThru |
                                        Add-Member -NotePropertyName AADObjectType -NotePropertyValue $item2.ObjectType -PassThru |
                                        #Add-Member -NotePropertyName AADResourceScope -NotePropertyValue $aadroleassignment.ResourceScope -PassThru |
                                        Add-Member -NotePropertyName AADRoleAssignmentID -NotePropertyValue $aadroleassignment.Id -PassThru |
                                        Add-Member -NotePropertyName AADDirectoryScopeID -NotePropertyValue $aadroleassignment.DirectoryScopeId -PassThru

                    }
           }
        }
        #return $members
        $tdy = get-date -Format "MM-dd-yyyy hh.mm.ss"
        $outputfile = $groupquestion +"_"+$tdy+".csv"
        $OutputFile = save-file -filename $outputfile -initialDirectory $env:HOMEDRIVE
        if ($OutputFile -eq "Cancel"){break}
        #$AADRolegroupoutput |  Out-File -FilePath $outputfile -Encoding utf8 -Force
        #$members | Out-File -FilePath $outputfile -Encoding utf8 -Append
        $members |  export-csv -Path $OutputFile -NoTypeInformation -Encoding utf8 -Force

}


try
    {
    Get-AzureADDomain -ErrorAction Stop > $null
    }
catch
    {
    connect-azuread
    }

$selector = @("All Roles","All Groups","All Users", "All Service Principals")

do
    {
        $group =@()
        $members =@()
        $aadrole =@()
        $aadrolemember =@()
        $groupquestion =  select-box -selectedoption $selector 
        if ($groupquestion -eq "Cancel"){break} 
        if ($groupquestion -eq "All Roles")
            {
                $type = "All"
                $members = find-aadroleinfo -type $type
            }
        elseif ($groupquestion -eq "All Users")
            {
                $type = "User"
                $members = find-aadroleinfo -type $type
            }
        elseif ($groupquestion -eq "All Groups")
            {
                $type = "Group"
                $members = find-aadroleinfo -type $type
            }
        else #must be a service principal
            {
                $type = "ServicePrincipal"
                $members = find-aadroleinfo -type $type
            }
    }
While ($groupquestion -ne "Cancel")