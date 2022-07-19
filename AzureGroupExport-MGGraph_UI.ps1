#######################
# Written by Derrick Baxter debaxter@microsoft.com
# the below script uses the Azure Graph powershell module pulling all roleassignments for groups
#
# 5/13/22
# debaxter@microsoft.com
# complete rewrite from Az UI version
# Group Members/Group Attributes
# Group Members and Group Attributes filter1- All/Assigned/Dynamic
# Group Members - All (gets all group members of all Groups)
# Group Members - Assigned Filters - All(assigned)/Azure Security/Office Security/Selected Azure Security/Selected Office Security/Selected Office Non-Security
# Group Members - Dynamic Filter - All(dynamic)/Azure/Office/Selected Azure/Selected Office
# Group Attributes - All (all groups)/Assigned (All assigned group attributes)/ Dynamic (all Dynamic Group Attributes)
#Using Powershell AzureADPreview version 2.0.138.0

#######################

#save file function window
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 
function select-directory([string] $initialDirectory, $filename)
    {
        $tdy = get-date -Format "MM-dd-yyyy hh.mm.ss"
        $outputfile = $filename + $tdy +".csv"
        $SaveFileDialog = New-Object windows.forms.savefiledialog  
        $SaveFileDialog.FileName = $outputfile 
        $SaveFileDialog.initialDirectory = $initialDirectory
        $SaveFileDialog.title = "Save File to Disk"
        $SaveFileDialog.filter = "AzureADGroupExportCSV | Azure AD Group Export *.csv|Comma Seperated File|*.csv | All Files|*.* " 
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
#selection UI
function select-group ($grouptype, $selectType, $groupselect, $multivalue)
    {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Select ' + $selectType
    $form.Size = New-Object System.Drawing.Size(400,400)
    $form.StartPosition = 'CenterScreen'
    $form.Top = $true
    $form.TopMost = $true

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(200,330)
    $okButton.Size = New-Object System.Drawing.Size(75,23)
    $okButton.Text = 'OK'
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $okButton
    $form.Controls.Add($okButton)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(275,330)
    $cancelButton.Size = New-Object System.Drawing.Size(75,23)
    $cancelButton.Text = 'Cancel'
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $cancelButton
    $form.Controls.Add($cancelButton)

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(20,20)
    $label.Size = New-Object System.Drawing.Size(265,20)
    $label.Text = 'Select 1 or more ' + $selectType
    $form.Controls.Add($label)


    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Location = New-Object System.Drawing.Point(60,60)
    $listBox.Size = New-Object System.Drawing.Size(365,60)
    $listBox.Height = 375
    if($multivalue)
    {
        $label.Text = $selectType 
    }
    else
    {
        $label.Text =  $selectType + ' Click One Item '
    }
    $form.Controls.Add($label)


    $listBox = New-Object System.Windows.Forms.ListBox
    $listBox.Location = New-Object System.Drawing.Point(10,50)
    $listBox.Size = New-Object System.Drawing.Size(365,20)
    $listBox.Height = 200
    
    if($multivalue)
        {
            $listBox.SelectionMode = 'MultiExtended'
        }



    foreach ($item in $grouptype)
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
            #$x
        }
    elseif ($result -eq [System.Windows.Forms.DialogResult]::Cancel)
        {
            
            exit
        }
    return $x
    } # end function select-app

    $audittype = @()
    $aduserquestion =@()
    $adusers =@()
    $fileprefix =@()
    $groupinfo  =@()


#remove the rem below and enter the tenant id, and rem the 2nd connect-azaccount
try
    {
    Get-MGUser -top 1 -ErrorAction Stop > $null
    }
catch
    {
    Connect-MgGraph -Scopes "group.read.all, directory.read.all, group.readwrite.all, groupmember.read.all, groupmember.readwrite.all"
    Select-MgProfile -Name "beta"
    }

do
{
    $groupquestion =@()
    $grouptype =@()
    $group  =@()
    $groupinfo =@()
    $OutputFile =@()
    $GMs =@()    
    $SorOGroup =@()
    $MainMenuQuestion  =@()
    $GroupTypeQuestion =@()
    $SorOQuestion      =@() 
    $mainmenu        = @("Group Members","Groups Attributes", "Group Owners", "Group License Assignments")
    $GroupTypeFilter = @("All","Assigned","Dynamic")

    $MainMenuQuestion  =  select-group -grouptype $mainmenu -selectType "Select Group Export Option"
    if ($MainMenuQuestion -eq "Cancel"){break}

    
    if($MainMenuQuestion -eq "Group Members")
        {
            $GroupTypeQuestion =  select-group -grouptype $GroupTypeFilter -selectType "Select Group Type"
            if ($GroupTypeQuestion-eq "Cancel"){break}
            if($GroupTypeQuestion -eq "Assigned" )
            {
                $SorOGroup       = @("All","Azure Security", "Office Security", "Selected Azure Security","Selected Office Security", "Selected Office Non-Security")
            }
            elseif($GroupTypeQuestion -eq "Dynamic" )
            {
                $SorOGroup       = @("All","Azure","Office", "Selected Azure", "Selected Office")
            }

        }

    if($MainMenuQuestion -eq "Group Members" -and $GroupTypeQuestion -ne "All")
    {
        $SorOQuestion     =  select-group -grouptype $SorOGroup -selectType "Select Filter Option"
        if ($SorOQuestion -eq "Cancel"){break}
    }

    if ($MainMenuQuestion.ToUpper() -eq "GROUP MEMBERS")
    {
        if($GroupTypeQuestion.toupper()-eq "DYNAMIC") #all dynamic group members
        {
            if($SorOQuestion.ToUpper()-eq "AZURE")
            {
                $group = get-mggroup -all | 
                    Where-Object{($_.grouptypes -contains "DynamicMembership" -and $_.grouptypes -notcontains "Unified" -and $_.securityenabled -eq $true) }| 
                    Select-Object displayname, id, description | 
                    Sort-Object DisplayName
            }
            elseif($SorOQuestion.ToUpper()-eq "OFFICE")
            {
                $group = get-mggroup -all | 
                    where-object{($_.grouptypes -contains "DynamicMembership" -and $_.grouptypes -contains "Unified"-and $_.securityenabled -eq $true) }| 
                    select-object displayname, id, description | 
                    Sort-Object DisplayName
            }
            elseif($SorOQuestion.ToUpper() -eq "SELECTED AZURE")
            {
                $groupselect = (get-mggroup -all | 
                    where-object{($_.grouptypes -contains "DynamicMembership" -and $_.grouptypes -notcontains "Unified" -and $_.securityenabled -eq $true) }| 
                    Sort-Object DisplayName).DisplayName
                $groupquestion =  select-group -grouptype $groupselect -selectType "Dynamic Security Groups filter"  -multivalue $true
                foreach ($item3 in $groupquestion)
                {
                    [string]$gname = $item3
                    $findgroup = get-mggroup -filter "DisplayName eq '$gname'"
                    $group += $findgroup 

                }
            }
            elseif($SorOQuestion.ToUpper() -eq "SELECTED OFFICE")
            {
                $groupselect = (get-mggroup -all | 
                    where-object{($_.grouptypes -contains "DynamicMembership" -and $_.grouptypes -contains "Unified" -and $_.securityenabled -eq $true) }| 
                    Sort-Object DisplayName).DisplayName
                $groupquestion =  select-group -grouptype $groupselect -selectType "Dynamic Security Groups filter"  -multivalue $true
                foreach ($item3 in $groupquestion)
                {
                    [string]$gname = $item3
                    $findgroup = get-mggroup -filter "DisplayName eq '$gname'"
                    $group += $findgroup 
                    
                }
            }
            else
            {
            $group = get-mggroup -all | 
               select-object displayname, id, description | 
                Sort-Object DisplayName
            }
        }
        elseif($GroupTypeQuestion.toupper() -eq "ASSIGNED") #all assigned group members
        {
            if($SorOQuestion.ToUpper() -eq "AZURE SECURITY")
            {
                $group = get-mggroup -all  | 
                    where-object{($_.GroupTypes.Count -eq 0 -or $_.grouptypes -notcontains "DynamicMembership"  -and $_.grouptypes -notcontains "Unified" -and $_.securityenabled -eq $true) }| 
                   select-object displayname, id, description | 
                    Sort-Object DisplayName
            }
            elseif($SorOQuestion.ToUpper()-eq "OFFICE SECURITY")
            {
                $group = get-mggroup -all | 
                    where-object{($_.GroupTypes.Count -eq 0 -or $_.grouptypes -notcontains "DynamicMembership"  -and $_.grouptypes -contains "Unified" -and $_.securityenabled -eq $true) }| 
                   select-object displayname, id, description | 
                    Sort-Object DisplayName
            }
            elseif($SorOQuestion.ToUpper()-eq "OFFICE NON-SECURITY")
            {
                $group = get-mggroup -all  | 
                    where-object{($_.GroupTypes.Count -eq 0 -or $_.grouptypes -notcontains "DynamicMembership"  -and $_.grouptypes -contains "Unified" -and $_.securityenabled -eq $false) }| 
                   select-object displayname, id, description | 
                    Sort-Object DisplayName
            }
            elseif($SorOQuestion.ToUpper()-eq "SELECTED AZURE SECURITY")
            {
                $groupselect = (get-mggroup -all  | 
                    where-object{($_.GroupTypes.Count -eq 0 -or $_.grouptypes -notcontains "DynamicMembership"   -and $_.grouptypes -notcontains "Unified"  -and $_.securityenabled -eq $true) }| 
                    Sort-Object DisplayName).DisplayName
                $groupquestion =  select-group -grouptype $groupselect -selectType "SELECTED AZURE SECURITY Groups filter"  -multivalue $true
                
                foreach ($item3 in $groupquestion)
                {
                    [string]$gname = $item3
                    $findgroup = get-mggroup -filter "DisplayName eq '$gname'"
                    $group += $findgroup 
                    
                }

            }
            elseif($SorOQuestion.ToUpper()-eq "SELECTED OFFICE SECURITY")
            {
                $groupselect = (get-mggroup -all  | 
                    where-object{($_.GroupTypes.Count -eq 0 -or $_.grouptypes -notcontains "DynamicMembership"   -and $_.grouptypes -contains "Unified"  -and $_.securityenabled -eq $true) }| 
                    Sort-Object DisplayName).DisplayName
                $groupquestion =  select-group -grouptype $groupselect -selectType "SELECTED OFFICE SECURITY Groups filter"  -multivalue $true
                
                foreach ($item3 in $groupquestion)
                {
                    [string]$gname = $item3
                    $findgroup = get-mggroup -filter "DisplayName eq '$gname'"
                    $group += $findgroup 
                    
                }

            }
            elseif($SorOQuestion.ToUpper()-eq "SELECTED OFFICE NON-SECURITY")
            {
                $groupselect = (get-mggroup -all  | 
                    where-object{($_.GroupTypes.Count -eq 0 -or $_.grouptypes -notcontains "DynamicMembership"   -and $_.grouptypes -contains "Unified"  -and $_.securityenabled -eq $true) }| 
                    Sort-Object DisplayName).DisplayName
                $groupquestion =  select-group -grouptype $groupselect -selectType "SELECTED OFFICE NON-SECURITY filter"  -multivalue $true
                
                foreach ($item3 in $groupquestion)
                {
                    [string]$gname = $item3
                    $findgroup = get-mggroup -filter "DisplayName eq '$gname'"
                    $group += $findgroup 
                    
                }

            }
            else
            {
                $group = get-mggroup -all | 
                    where-object{($_.GroupTypes.Count -eq 0 -or $_.grouptypes -notcontains "DynamicMembership") }| 
                    Sort-Object DisplayName
             }

        }
        else # must be All group members
        {
                $group = get-mggroup -all  | 
                #$group = get-mggroup -top 10 |
                   select-object displayname, id, description | 
                    Sort-Object DisplayName
        }

            foreach ($item in $group)
            {
                $findgroupmembers = get-mggroupmember -GroupId $item.id 
                if($findgroupmembers -ne 0) 
                {


                    foreach ($groupmember1 in $findgroupmembers)
                    {
                        $zero = $groupmember1.additionalproperties.values[0]
                        #$zero
                        if ($zero -match "graph.group")
                        {
                            $groupinfo = get-mggroup -GroupId $groupmember1.Id
                                    $GMs += New-Object Object |
                                        Add-Member -NotePropertyName GroupDisplayName -NotePropertyValue $item.DisplayName -PassThru |
                                        Add-Member -NotePropertyName GroupDescription -NotePropertyValue $item.Description -PassThru |
                                        Add-Member -NotePropertyName GroupID -NotePropertyValue $item.Id -PassThru |
                                        Add-Member -NotePropertyName MemberDisplayName -NotePropertyValue $groupinfo.displayName -PassThru |
                                        Add-Member -NotePropertyName MemberID -NotePropertyValue $groupinfo.id -PassThru |
                                        Add-Member -NotePropertyName MemberObjectType -NotePropertyValue "Group" -PassThru
                        }
                
                        elseif ($zero -match "graph.user")
                        {
                            $groupuser = get-mguser -UserId $groupmember1.Id
                                    $GMs += New-Object Object |
                                            Add-Member -NotePropertyName GroupDisplayName -NotePropertyValue $item.DisplayName -PassThru |
                                            Add-Member -NotePropertyName GroupDescription -NotePropertyValue $item.Description -PassThru |
                                            Add-Member -NotePropertyName GroupID -NotePropertyValue $item.Id -PassThru |
                                            Add-Member -NotePropertyName MemberDisplayName -NotePropertyValue $groupuser.DisplayName -PassThru |
                                            Add-Member -NotePropertyName MemberID -NotePropertyValue $groupuser.Id -PassThru |
                                            Add-Member -NotePropertyName MemberUserPrincipalName -NotePropertyValue $groupuser.UserPrincipalName -PassThru |
                                            Add-Member -NotePropertyName MemberObjectType -NotePropertyValue "User" -PassThru
                        }
                        elseif ($zero -match "graph.device")
                        {
                        $devid = $groupmember1.Id
                            $groupuser = get-mgdevice -Filter "Id eq '$devid'" 
                                    $GMs += New-Object Object |
                                            Add-Member -NotePropertyName GroupDisplayName -NotePropertyValue $item.DisplayName -PassThru |
                                            Add-Member -NotePropertyName GroupDescription -NotePropertyValue $item.Description -PassThru |
                                            Add-Member -NotePropertyName GroupID -NotePropertyValue $item.Id -PassThru |
                                            Add-Member -NotePropertyName MemberDisplayName -NotePropertyValue $groupuser.displayName -PassThru |
                                            Add-Member -NotePropertyName MemberID -NotePropertyValue $groupuser.id -PassThru |
                                            Add-Member -NotePropertyName MemberObjectType -NotePropertyValue "Device" -PassThru
                        }
                        else
                        {
                            $groupuser = Get-MgServicePrincipal -ServicePrincipalId $groupmember1.id
                                    $GMs += New-Object Object |
                                            Add-Member -NotePropertyName GroupDisplayName -NotePropertyValue $item.DisplayName -PassThru |
                                            Add-Member -NotePropertyName GroupDescription -NotePropertyValue $item.Description -PassThru |
                                            Add-Member -NotePropertyName GroupID -NotePropertyValue $item.Id -PassThru |
                                            Add-Member -NotePropertyName MemberDisplayName -NotePropertyValue $groupuser.displayName -PassThru |
                                            Add-Member -NotePropertyName MemberID -NotePropertyValue $groupuser.Appid -PassThru |
                                            Add-Member -NotePropertyName MemberObjectType -NotePropertyValue "ServicePrincipal" -PassThru
                
                        }
                    }
                }        
            }
         
        #creating header for CSV
        
        $file = $MainMenuQuestion +"_"+ $GroupTypeQuestion.toupper()+"_"+ $SorOQuestion
        $OutputFile = select-directory -filename $file -initialDirectory $env:HOMEDRIVE
        if ($OutputFile -eq "Cancel"){break}
        $GMs | export-csv -Path $OutputFile -NoTypeInformation -Force -Encoding UTF8
    }
    elseif($MainMenuQuestion.toupper()-eq "GROUP LICENSE ASSIGNMENTS")
    {
        $GroupTypeQuestion =  select-group -grouptype $GroupTypeFilter -selectType "Select Group Type"
        if ($GroupTypeQuestion-eq "Cancel"){break}
        
        if($GroupTypeQuestion -eq "Assigned" )
        {

        }
        elseif($GroupTypeQuestion -eq "Dynamic" )
        {

        }
        else # must be all
        {
            
        }
        
        $buildURI = "https://graph.microsoft.com/v1.0/groups/" + 
        $assignedlicenses = invoke-mggraphrequest -uri 'https://graph.microsoft.com/v1.0/groups/35d7166f-eeab-4c33-8882-9ac7617671ff?$select=assignedLicenses' -method GET
    }
    elseif($MainMenuQuestion.ToUpper() -eq "GROUP OWNERS") #  Group attributes ($MainMenuQuestion -eq "Group Attributes") #used to backup all information about a group needed to recreate assigned group, especially dynamic security groups w rule
    {
        $GOs =@()
        if($GroupTypeQuestion.toupper()-eq "DYNAMIC")
        {
                $group = get-mggroup -all $true |
                where-object{$_.grouptypes -contains "DynamicMembership"}|
                select-object displayname, id |
                Sort-Object DisplayName
                $findgroupowners =@()
                foreach($grouplisted in $group)
                {
                    $findgroupowners = Get-MgGroupOwner -GroupId $grouplisted.id 
                    if($findgroupowners.count -ne 0)
                    {
                        foreach($foundowner in $findgroupowners)
                        {
                            $GOs += New-Object Object |
                            Add-Member -NotePropertyName Group_DisplayName -NotePropertyValue $grouplisted.DisplayName -PassThru |
                            Add-Member -NotePropertyName Group_ID -NotePropertyValue $grouplisted.id -PassThru |
                            Add-Member -NotePropertyName Owner_ID -NotePropertyValue $foundowner.Id -PassThru 
                        }
                    }
                }

        }
        elseif($GroupTypeQuestion.toupper()-eq "ASSIGNED")
        {
                $group = get-mggroup -all $true |
                where-object{$_.grouptypes -notcontains "DynamicMembership"}|
                select-object displayname,id |
                Sort-Object DisplayName
                $findgroupowners =@()
                foreach($grouplisted in $group)
                {
                    $findgroupowners = Get-MgGroupOwner -GroupId $grouplisted.id 
                    if($findgroupowners.count -ne 0)
                    {
                        foreach($foundowner in $findgroupowners)
                        {
                            $GOs += New-Object Object |
                            Add-Member -NotePropertyName Group_DisplayName -NotePropertyValue $grouplisted.DisplayName -PassThru |
                            Add-Member -NotePropertyName Group_ID -NotePropertyValue $grouplisted.id -PassThru |
                            Add-Member -NotePropertyName Owner_ID -NotePropertyValue $foundowner.Id -PassThru 
                        }
                    }
                }
        }

        else # condition for all Group Attributes, all a&d and all s/o
        { 
            $group = get-mggroup -all | Sort-Object DisplayName
            $findgroupowners =@()
            foreach($grouplisted in $group)
            {
                $findgroupowners = Get-MgGroupOwner -GroupId $grouplisted.id 
                if($findgroupowners.count -ne 0)
                {
                    foreach($foundowner in $findgroupowners)
                    {
                        $GOs += New-Object Object |
                        Add-Member -NotePropertyName Group_DisplayName -NotePropertyValue $grouplisted.DisplayName -PassThru |
                        Add-Member -NotePropertyName Group_ID -NotePropertyValue $grouplisted.id -PassThru |
                        Add-Member -NotePropertyName Owner_ID -NotePropertyValue $foundowner.Id -PassThru 
                    }
                }
            }
        }

        
        #creating header for CSV
        $file = $MainMenuQuestion +"_"+ $GroupTypeQuestion.toupper()+"_"+ $SorOQuestion
        $OutputFile = select-directory -filename $file -initialDirectory $env:HOMEDRIVE
        if ($OutputFile -eq "Cancel"){break}
        $GOs | export-csv -Path $OutputFile -NoTypeInformation -Force -Encoding UTF8
    }

    else #  Group attributes ($MainMenuQuestion -eq "Group Attributes") #used to backup all information about a group needed to recreate assigned group, especially dynamic security groups w rule
    {
        if($GroupTypeQuestion.toupper()-eq "DYNAMIC")
        {
                $group = get-mggroup -all $true |
                where-object{$_.grouptypes -contains "DynamicMembership"}|
               select-object displayname,description, id, securityenabled, IsAssignableToRole, proxyaddresses, GroupTypes,  MailEnabled, Mail, mailnickname,AssignedLabels, MembershipRule |
                Sort-Object DisplayName

        }
        elseif($GroupTypeQuestion.toupper()-eq "ASSIGNED")
        {
                $group = get-mggroup -all $true |
                where-object{$_.grouptypes -notcontains "DynamicMembership"}|
               select-object displayname,description, id, securityenabled, IsAssignableToRole, proxyaddresses, GroupTypes,  MailEnabled, Mail, mailnickname,AssignedLabels, MembershipRule |
                Sort-Object DisplayName
            
        }

        else # condition for all Group Attributes, all a&d and all s/o
        { 
            $group = get-mggroup -all | Sort-Object DisplayName 
        }
            if (!$group)
            {
                            $groupinfo2 = "No groups"
                            $groupinfo += $groupinfo2
            }
            else
            {
                    $GAs=@()
                    foreach ($item in $group )
                    {
                        [string]$proxy = $item.ProxyAddresses
                        [string]$grouptypes = $item.grouptypes
                        [string]$labels = $item.assignedlables
                        $groupowner = Get-MgGroupOwner -GroupId $item.id
                    $GAs += New-Object Object |
                                    Add-Member -NotePropertyName Group_DisplayName -NotePropertyValue $item.DisplayName -PassThru |
                                    Add-Member -NotePropertyName Group_Description -NotePropertyValue $item.Description -PassThru |
                                    Add-Member -NotePropertyName GroupID -NotePropertyValue $item.Id -PassThru |
                                    Add-Member -NotePropertyName securityenabled -NotePropertyValue $item.securityenabled -PassThru |
                                    Add-Member -NotePropertyName IsAssignableToRole -NotePropertyValue $item.IsAssignableToRole -PassThru |
                                    Add-Member -NotePropertyName proxyaddresses -NotePropertyValue $proxy -PassThru |
                                    Add-Member -NotePropertyName GroupTypes -NotePropertyValue $grouptypes -PassThru |
                                    Add-Member -NotePropertyName MailEnabled -NotePropertyValue $item.MailEnabled -PassThru |
                                    Add-Member -NotePropertyName Mail -NotePropertyValue $item.Mail -PassThru |
                                    Add-Member -NotePropertyName mailnickname -NotePropertyValue $item.mailnickname -PassThru |
                                    Add-Member -NotePropertyName AssignedLabels -NotePropertyValue $labels -PassThru |
                                    Add-Member -NotePropertyName MembershipRule -NotePropertyValue $item.MembershipRule -PassThru 

                    } 
                
            } 
        
        #creating header for CSV
        $file = $MainMenuQuestion +"_"+ $GroupTypeQuestion.toupper()+"_"+ $SorOQuestion
        $OutputFile = select-directory -filename $file -initialDirectory $env:HOMEDRIVE
        if ($OutputFile -eq "Cancel"){break}
        $GAs | export-csv -Path $OutputFile -NoTypeInformation -Force -Encoding UTF8
    }


}
while ($MainMenuQuestion -ne "Cancel")