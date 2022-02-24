#######################
# Written by Derrick Baxter debaxter@microsoft.com
#the below script uses the AZ powershell module pulling all roleassignments for groups
#
# 2/23/2022
#debaxter@microsoft.com
#complete rewrite
# Group Members/Group Attributes
# Group Members and Group Attributes filter1- All/Assigned/Dynamic
# Group Members - All (gets all group members of all Groups)
# Group Members - Assigned Filters - All(assigned)/Azure Security/Office Security/Selected Azure Security/Selected Office Security/Selected Office Non-Security
# Group Members - Dynamic Filter - All(dynamic)/Azure/Office/Selected Azure/Selected Office
# Group Attributes - All (all groups)/Assigned (All assigned group attributes)/ Dynamic (all Dynamic Group Attributes)
#Using Powershell AzureADPreview version 2.0.138.0

#######################

#save file function window
function save-file([string] $initialDirectory, $filename)
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
    Get-AzureADDomain -ErrorAction Stop > $null
    }
catch
    {
    connect-azuread
    }


do
{
    $groupoutput =@()
    $groupquestion =@()
    $grouptype =@()
    $group  =@()
    $groupmembers =@()
    $groupinfo =@()
    $groupinfo2 =@()
    $OutputFile =@()
    

 $SorOGroup =@()

    $MainMenuQuestion  =@()
    $GroupTypeQuestion =@()
    $SorOQuestion      =@() 

    $mainmenu        = @("Group Members","Groups Attributes")
    $GroupTypeFilter = @("All","Assigned","Dynamic")


    $MainMenuQuestion  =  select-group -grouptype $mainmenu -selectType "Select Group Export Option"
    if ($MainMenuQuestion -eq "Cancel"){break}
    $GroupTypeQuestion =  select-group -grouptype $GroupTypeFilter -selectType "Select Group Type"
    if ($GroupTypeQuestion-eq "Cancel"){break}
    
    if($MainMenuQuestion -eq "Group Members")
        {
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
    
    #$MainMenuQuestion.ToUpper()  
    #$GroupTypeQuestion.toupper()
    #$SorOQuestion.ToUpper()  

    if ($MainMenuQuestion.ToUpper() -eq "GROUP MEMBERS")
    {
    write-host "got here" $MainMenuQuestion
        if($GroupTypeQuestion.toupper()-eq "DYNAMIC") #all dynamic group members
        {
        write-host "got here " $GroupTypeQuestion
            if($SorOQuestion.ToUpper()-eq "AZURE")
            {
            $group = get-azureadmsgroup -all $true | 
                ?{($_.grouptypes -contains "DynamicMembership" -and $_.grouptypes -notcontains "Unified" -and $_.securityenabled -eq $true) }| 
                select displayname, id, description | 
                Sort-Object DisplayName
            }
            elseif($SorOQuestion.ToUpper()-eq "OFFICE")
            {and I
            $group = get-azureadmsgroup -all $true | 
                ?{($_.grouptypes -contains "DynamicMembership" -and $_.grouptypes -contains "Unified"-and $_.securityenabled -eq $true) }| 
                select displayname, id, description | 
                Sort-Object DisplayName
            }
            elseif($SorOQuestion.ToUpper() -eq "SELECTED AZURE")
            {
            write-host "got here " $SorOQuestion
                $groupselect = (get-azureadmsgroup -all $true | 
                    ?{($_.grouptypes -contains "DynamicMembership" -and $_.grouptypes -notcontains "Unified" -and $_.securityenabled -eq $true) }| 
                    Sort-Object DisplayName).DisplayName
                $groupquestion =  select-group -grouptype $groupselect -selectType "Dynamic Security Groups filter"  -multivalue $true
                foreach ($item3 in $groupquestion)
                {
                    $findgroup = get-azureadgroup -SearchString $item3
                    $groupmembers = get-azureadgroupmember -ObjectId $findgroup.objectid | select displayname, objectid, userprincipalname, usertype, objecttype
        
                    foreach ($item4 in $groupmembers)
                        {
                            #$item3.DisplayName, $item3.id, $item4.DisplayName
                            $groupinfo2 = $findgroup.DisplayName +","+ $findgroup.Description +"," + $findgroup.ObjectId + ","+ $item4.displayName +","+ $item4.objectid +","+ $item4.userprincipalname  +","+ $item4.UserType +","+ $item4.objecttype
                            $groupinfo += $groupinfo2
                        }
                }
            }
            elseif($SorOQuestion.ToUpper() -eq "SELECTED OFFICE")
            {
            write-host "got here " $SorOQuestion
                $groupselect = (get-azureadmsgroup -all $true | 
                    ?{($_.grouptypes -contains "DynamicMembership" -and $_.grouptypes -contains "Unified" -and $_.securityenabled -eq $true) }| 
                    Sort-Object DisplayName).DisplayName
                $groupquestion =  select-group -grouptype $groupselect -selectType "Dynamic Security Groups filter"  -multivalue $true
                foreach ($item3 in $groupquestion)
                {
                    $findgroup = get-azureadgroup -SearchString $item3
                    $group += $findgroup 
                    
                }
            }
            else
            {
            $group = get-azureadmsgroup -all $true | 
                select displayname, id, description | 
                Sort-Object DisplayName
            }
        }
        elseif($GroupTypeQuestion.toupper() -eq "ASSIGNED") #all assigned group members
        {
        write-host "got here assigned"
            if($SorOQuestion.ToUpper() -eq "AZURE SECURITY")
            {
            write-host "got here " $GroupTypeQuestion
                $group = get-azureadmsgroup -all $true | 
                    ?{($_.GroupTypes.Count -eq 0 -or $_.grouptypes -notcontains "DynamicMembership"  -and $_.grouptypes -notcontains "Unified" -and $_.securityenabled -eq $true) }| 
                    select displayname, id, description | 
                    Sort-Object DisplayName
            }
            elseif($SorOQuestion.ToUpper()-eq "OFFICE SECURITY")
            {
            write-host "got here " $GroupTypeQuestion
                $group = get-azureadmsgroup -all $true | 
                    ?{($_.GroupTypes.Count -eq 0 -or $_.grouptypes -notcontains "DynamicMembership"  -and $_.grouptypes -contains "Unified" -and $_.securityenabled -eq $true) }| 
                    select displayname, id, description | 
                    Sort-Object DisplayName
            }
            elseif($SorOQuestion.ToUpper()-eq "OFFICE NON-SECURITY")
            {
            write-host "got here " $GroupTypeQuestion
                $group = get-azureadmsgroup -all $true | 
                    ?{($_.GroupTypes.Count -eq 0 -or $_.grouptypes -notcontains "DynamicMembership"  -and $_.grouptypes -contains "Unified" -and $_.securityenabled -eq $false) }| 
                    select displayname, id, description | 
                    Sort-Object DisplayName
            }
            elseif($SorOQuestion.ToUpper()-eq "SELECTED AZURE SECURITY")
            {
             write-host "got here " $GroupTypeQuestion
                $groupselect = (get-azureadmsgroup -all $true | 
                    ?{($_.GroupTypes.Count -eq 0 -or $_.grouptypes -notcontains "DynamicMembership"   -and $_.grouptypes -notcontains "Unified"  -and $_.securityenabled -eq $true) }| 
                    Sort-Object DisplayName).DisplayName
                $groupquestion =  select-group -grouptype $groupselect -selectType "SELECTED AZURE SECURITY Groups filter"  -multivalue $true
                
                foreach ($item3 in $groupquestion)
                {
                    $findgroup = get-azureadmsgroup -SearchString $item3
                    $group += $findgroup 
                    
                }

            }
            elseif($SorOQuestion.ToUpper()-eq "SELECTED OFFICE SECURITY")
            {
             write-host "got here " $GroupTypeQuestion
                $groupselect = (get-azureadmsgroup -all $true | 
                    ?{($_.GroupTypes.Count -eq 0 -or $_.grouptypes -notcontains "DynamicMembership"   -and $_.grouptypes -contains "Unified"  -and $_.securityenabled -eq $true) }| 
                    Sort-Object DisplayName).DisplayName
                $groupquestion =  select-group -grouptype $groupselect -selectType "SELECTED OFFICE SECURITY Groups filter"  -multivalue $true
                
                foreach ($item3 in $groupquestion)
                {
                    $findgroup = get-azureadmsgroup -SearchString $item3
                    $group += $findgroup 
                    
                }

            }
            elseif($SorOQuestion.ToUpper()-eq "SELECTED OFFICE NON-SECURITY")
            {
             write-host "got here " $GroupTypeQuestion
                $groupselect = (get-azureadmsgroup -all $true | 
                    ?{($_.GroupTypes.Count -eq 0 -or $_.grouptypes -notcontains "DynamicMembership"   -and $_.grouptypes -contains "Unified"  -and $_.securityenabled -eq $true) }| 
                    Sort-Object DisplayName).DisplayName
                $groupquestion =  select-group -grouptype $groupselect -selectType "SELECTED OFFICE NON-SECURITY filter"  -multivalue $true
                
                foreach ($item3 in $groupquestion)
                {
                    $findgroup = get-azureadmsgroup -SearchString $item3
                    $group += $findgroup 
                    
                }

            }
            else
            {
            write-host "got here all"
                $group = get-azureadmsgroup -all $true | 
                    ?{($_.GroupTypes.Count -eq 0 -or $_.grouptypes -notcontains "DynamicMembership") }| 
                    Sort-Object DisplayName
             }

        }
        else # must be All group members
        {
                $group = get-azureadmsgroup -all $true | 
                    select displayname, id, description | 
                    Sort-Object DisplayName
        }
    
        
            foreach ($item in $group)
            {
                $findgroupmembers = get-azureadgroupmember -ObjectId $item.id | select displayname, objectid, userprincipalname, UserType, objecttype | Sort-Object DisplayName
                if($findgroupmembers -eq 0) 
                {
                        $groupinfo2 = $item.DisplayName +","+ $item.Description +"," + $item.ObjectId + ",No Members"
                        $groupinfo += $groupinfo2
                }        

                else
                {
                foreach ($item4 in $findgroupmembers)
                    {
                        #$item3.DisplayName, $item3.id, $item4.DisplayName
                        $groupinfo2 = $item.DisplayName +","+ $item.Description +"," + $item.Id + ","+ $item4.displayName +","+ $item4.objectid +","+ $item4.userprincipalname  +","+ $item4.UserType +","+ $item4.objecttype
                        $groupinfo += $groupinfo2
                    }
                }
            }
         
        #creating header for CSV
        $groupoutput = "'Group Display Name','Group Description','Group ObjectID','Member DisplayName','Member ObjectID','Member UserPrincipalName','User Type','Object Type"
        $file = $MainMenuQuestion +"_"+ $GroupTypeQuestion.toupper()+"_"+ $SorOQuestion
        $OutputFile = save-file -filename $file -initialDirectory $env:HOMEDRIVE
        if ($OutputFile -eq "Cancel"){break}
        $groupoutput |  Out-File -FilePath $outputfile -Encoding utf8 -Force
        #adding info to CSV
        $groupinfo | Out-File -FilePath $outputfile -Encoding utf8 -Append
    }
    else #  Group attributes ($MainMenuQuestion -eq "Group Attributes") #used to backup all information about a group needed to recreate assigned group, especially dynamic security groups w rule
    {
        if($GroupTypeQuestion.toupper()-eq "DYNAMIC")
        {
                $group = get-azureadmsgroup -all $true |
                ?{$_.grouptypes -contains "DynamicMembership"}|
                select displayname,description, id, securityenabled, IsAssignableToRole, proxyaddresses, GroupTypes,  MailEnabled, Mail, mailnickname,AssignedLabels, MembershipRule |
                Sort-Object DisplayName

        }
        elseif($GroupTypeQuestion.toupper()-eq "ASSIGNED")
        {
                $group = get-azureadmsgroup -all $true |
                ?{$_.grouptypes -notcontains "DynamicMembership"}|
                select displayname,description, id, securityenabled, IsAssignableToRole, proxyaddresses, GroupTypes,  MailEnabled, Mail, mailnickname,AssignedLabels, MembershipRule |
                Sort-Object DisplayName
            
        }

        else # condition for all Group Attributes, all a&d and all s/o
        { 
            $group = get-azureadmsgroup -all $true |
                select displayname,description, id, securityenabled, IsAssignableToRole, proxyaddresses, GroupTypes,  MailEnabled, Mail, mailnickname,AssignedLabels, MembershipRule |
                Sort-Object DisplayName 
        }
        if ($group -eq 0)
        {
                        $groupinfo2 = "No groups"
                        $groupinfo += $groupinfo2
        }
        else
        {
            foreach ($item in $group)
            {

                        $groupinfo2 = $item.DisplayName +","+ $item.Description +"," + $item.Id + ","+ $item.securityenabled+ ","+ $item.IsAssignableToRole + "," +  $item.proxyaddresses + "," +  $item.GroupTypes + "," +  $item.MailEnabled+ "," +  $item.Mail+ "," +  $item.mailnickname+ "," +  $item.AssignedLabels+ "," +  $item.MembershipRule
                        $groupinfo += $groupinfo2
            }
        }
        #creating header for CSV
        $groupoutput = "Group_DisplayName,Group_Description,Id,securityenabled,IsAssignableToRole ,proxyaddresses ,GroupTypes ,MailEnabled,Mail,mailnickname,AssignedLabels,MembershipRule"
        $file = $MainMenuQuestion +"_"+ $GroupTypeQuestion.toupper()+"_"+ $SorOQuestion
        $OutputFile = save-file -filename $file -initialDirectory $env:HOMEDRIVE
        if ($OutputFile -eq "Cancel"){break}
        $groupoutput |  Out-File -FilePath $outputfile -Encoding utf8 -Force
        #adding info to CSV
        $groupinfo | Out-File -FilePath $outputfile -Encoding utf8 -Append
    }


}
while ($MainMenuQuestion -ne "Cancel")