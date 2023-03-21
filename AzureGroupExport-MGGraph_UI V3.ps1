#######################
<# Written by Derrick Baxter debaxter@microsoft.com
 the below script uses the Azure Graph powershell module pulling all roleassignments for groups

 5/13/22
 debaxter@microsoft.com
 updated : fixed error/variable 
 Updated with licenses 7/20/22
 Updated with Conditional Access Policy Export 7/21/22
 complete rewrite from Az UI version
 Group Members/Group Attributes
 Group Members and Group Attributes filter1- All/Assigned/Dynamic
 Group Members - All (gets all group members of all Groups)
 Group Members - Assigned Filters - All(assigned)/Azure Security/Office Security/Selected Azure Security/Selected Office Security/Selected Office Non-Security
 Group Members - Dynamic Filter - All(dynamic)/Azure/Office/Selected Azure/Selected Office
 Group Attributes - All (all groups)/Assigned (All assigned group attributes)/ Dynamic (all Dynamic Group Attributes)
 Group Licenses - All (gets all groups with licenses)
 Group Licenses - Selected (select the groups with licenses assigned to export)
 Export Conditional Access Policies with included/excluded groups
Using Powershell microsoft.graph


IMPORTANT!!!

To consent for users to run this script a global admin will need to run the following
-------------------------------------------------------------------------------------------
$sp = get-mgserviceprincipal | ?{$_.displayname -like "Microsoft Graph Powershell*"}
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


#>
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
    Get-MGDomain -ErrorAction Stop > $null
    }
catch
    {
    Connect-MgGraph -Scopes "group.read.all, directory.read.all, groupmember.read.all, Policy.Read.All, Application.Read.All"
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
    $mainmenu        = @("Group Attributes","Group Members", "Group Owners", "Group Licenses", "Groups in Conditional Access Policies", "Groups in Application")


    $MainMenuQuestion  =  select-group -grouptype $mainmenu -selectType "Select Group Export Option"

    switch -exact ($MainMenuQuestion) 
    {
        "Cancel" {exit}
        "Groups in Conditional Access Policies"
        {
            $GroupTypeFilter = "All"
        }
        "Group Licenses" 
        {
            $GroupTypeFilter = @("All","Selected Groups with Licenses")
            $GroupTypeQuestion =  select-group -grouptype $GroupTypeFilter -selectType "Select Group Type"
            if ($GroupTypeQuestion-eq "Cancel"){exit}
        }
        "Groups in Application"
        {
            $GroupTypeFilter = ""
        }
        "Group Attributes"
        {
            $GroupTypeFilter = @("All","Assigned","Dynamic", "Selected Assigned","Selected Dynamic")    
            $GroupTypeQuestion =  select-group -grouptype $GroupTypeFilter -selectType "Select Group Type"
            if ($GroupTypeQuestion-eq "Cancel"){exit}
        }
        default
        {
            $GroupTypeFilter = @("All","Assigned","Dynamic")    
            $GroupTypeQuestion =  select-group -grouptype $GroupTypeFilter -selectType "Select Group Type"
            if ($GroupTypeQuestion-eq "Cancel"){exit}
        }
    }
    switch -exact ($MainMenuQuestion) 
    {
        "Cancel" {Exit}
        "Groups in Conditional Access Policies"
        {
            $CAs = Invoke-MgGraphRequest -Uri 'https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies' -method get
            $cavalue = $cas.'value'
            $CAGroupobject  = @()
            If ($CAExclude1.count -ge 1 -or !$CAInclude1.count -ge 1)
            {
                foreach($CAitem in $cavalue)
                {
                    $CAName = $CAItem.displayName
                    $CAInclude1 = $CAItem.conditions.users.includeGroups
                    $CAExclude1 = $CAItem.conditions.users.excludeGroups
                    foreach($CAIncludeitem in $CAinclude1)
                    {
                        $CAIncludeGroupname = Get-MgGroup -GroupId $CAIncludeitem
                        $CAGroupobject += New-Object Object |
                        Add-Member -NotePropertyName CAName -NotePropertyValue $CAName -PassThru |
                        Add-Member -NotePropertyName CAIncludedGroups -NotePropertyValue $CAIncludeitem -PassThru |
                        Add-Member -NotePropertyName CAIncludedGroupsName -NotePropertyValue $CAIncludeGroupname.DisplayName -PassThru |
                        Add-Member -NotePropertyName CAExcludedGroups -NotePropertyValue $null -PassThru |
                        Add-Member -NotePropertyName CAExcludedGroupsName -NotePropertyValue $null -PassThru 
                    }
                    foreach ($CAExcludeitem in $CAExclude1)
                    {
                        $CAexcludeGroupname = Get-MgGroup -GroupId $CAexcludeitem
                        $CAGroupobject += New-Object Object |
                        Add-Member -NotePropertyName CAName -NotePropertyValue $CAName -PassThru |
                        Add-Member -NotePropertyName CAIncludedGroups -NotePropertyValue $null -PassThru |
                        Add-Member -NotePropertyName CAIncludedGroupsName -NotePropertyValue $null -PassThru |
                        Add-Member -NotePropertyName CAExcludedGroups -NotePropertyValue $CAExcludeitem -PassThru |
                        Add-Member -NotePropertyName CAExcludedGroupsName -NotePropertyValue $CAexcludeGroupname.DisplayName -PassThru 
                    }

                }
                $file = $MainMenuQuestion +"_"+ $GroupTypeQuestion +"_"
                $OutputFile = select-directory -filename $file -initialDirectory $env:HOMEDRIVE
                if ($OutputFile -eq "Cancel"){exit}
                $CAGroupobject | export-csv -Path $OutputFile -NoTypeInformation -Force -Encoding UTF8
            }


        }
        "Group Members" 
        {
            switch -exact ($GroupTypeQuestion) 
            {
                "Cancel" {exit}
                "Assigned"
                {
                    
                    $SorOGroup       = @("All","Azure Security", "Office Security", "Selected Azure Security","Selected Office Security", "Selected Office Non-Security")
                    $SorOQuestion     =  select-group -grouptype $SorOGroup -selectType "Select Filter Option"
                    switch -exact ($SorOQuestion) 
                    {
                        "Cancel" {exit}
                        "Azure Security"
                        {
                            
                            $group = get-mggroup -all  | 
                            where-object{($_.GroupTypes.Count -eq 0 -or $_.grouptypes -notcontains "DynamicMembership"  -and $_.grouptypes -notcontains "Unified" -and $_.securityenabled -eq $true) }| 
                                select-object displayname, id, description | 
                                Sort-Object DisplayName
                        }
                        "Office Security"
                        {
                            
                            $group = get-mggroup -all | 
                            where-object{($_.GroupTypes.Count -eq 0 -or $_.grouptypes -notcontains "DynamicMembership"  -and $_.grouptypes -contains "Unified" -and $_.securityenabled -eq $true) }| 
                                select-object displayname, id, description | 
                                Sort-Object DisplayName
                        }
                        "Selected Azure Security"
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
                        "Selected Office Security"
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
                        "Selected Office Non-Security"
                        {
                            
                            $group = get-mggroup -all  | 
                            where-object{($_.GroupTypes.Count -eq 0 -or $_.grouptypes -notcontains "DynamicMembership"  -and $_.grouptypes -contains "Unified" -and $_.securityenabled -eq $false) }| 
                                select-object displayname, id, description | 
                                Sort-Object DisplayName
                            $groupquestion =  select-group -grouptype $groupselect -selectType "SELECTED OFFICE SECURITY Groups filter"  -multivalue $true
                            foreach ($item3 in $groupquestion)
                            {
                                [string]$gname = $item3
                                $findgroup = get-mggroup -filter "DisplayName eq '$gname'"
                                $group += $findgroup 
                                
                            }
                        }
                        "All"
                        {
                            $group = get-mggroup -all | 
                                where-object{($_.GroupTypes.Count -eq 0 -or $_.grouptypes -notcontains "DynamicMembership") }| 
                                Sort-Object DisplayName
                        }
                    }

                }
                "Dynamic"
                {
                    $SorOGroup       = @("All","Azure","Office", "Selected Azure", "Selected Office")
                    $SorOQuestion     =  select-group -grouptype $SorOGroup -selectType "Select Filter Option"
                    switch -exact ($SorOQuestion) 
                    {
                        "Cancel" {exit}
                        "Azure"
                        {
                            $group = get-mggroup -all | 
                            Where-Object{($_.grouptypes -contains "DynamicMembership" -and $_.grouptypes -notcontains "Unified" -and $_.securityenabled -eq $true) }| 
                            Select-Object displayname, id, description | 
                            Sort-Object DisplayName
                        }
                        "Office"
                        {
                            $group = get-mggroup -all | 
                            where-object{($_.grouptypes -contains "DynamicMembership" -and $_.grouptypes -contains "Unified"-and $_.securityenabled -eq $true) }| 
                            select-object displayname, id, description | 
                            Sort-Object DisplayName
                        }
                        "Selected Azure"
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
                        "Selected Office"
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
                        "All"
                        {
                            $group = get-mggroup -all | 
                            select-object displayname, id, description | 
                                Sort-Object DisplayName
                        }
                }
                }
                "All"
                {
                    $group = get-mggroup -all  | 
                       select-object displayname, id, description | 
                        Sort-Object DisplayName
                }
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
        
        $file = $MainMenuQuestion +"_"+ $GroupTypeQuestion.toupper()+"_"+ $SorOQuestion +"_"
        $OutputFile = select-directory -filename $file -initialDirectory $env:HOMEDRIVE
        if ($OutputFile -eq "Cancel"){exit}
        $GMs | export-csv -Path $OutputFile -NoTypeInformation -Force -Encoding UTF8
        }
        "Group Attributes" 
        {
            $group =@()
            switch -exact ($GroupTypeQuestion) 
            {
                "Cancel" {exit}
                "Assigned"
                {
                    $group = get-mggroup -all  |
                    where-object{$_.grouptypes -contains "DynamicMembership"}|
                        select-object displayname,description, id, securityenabled, IsAssignableToRole, proxyaddresses, GroupTypes,  MailEnabled, Mail, mailnickname,AssignedLabels, MembershipRule |
                        Sort-Object DisplayName
                }
                "Dynamic"
                {
                    $group = get-mggroup -all |
                    where-object{$_.grouptypes -notcontains "DynamicMembership"}|
                        select-object displayname,description, id, securityenabled, IsAssignableToRole, proxyaddresses, GroupTypes,  MailEnabled, Mail, mailnickname,AssignedLabels, MembershipRule |
                        Sort-Object DisplayName
                }
                "Selected Dynamic"
                {
                    #write-host " assigned / selected azure security"
                    $groupselect = (get-mggroup -all  | 
                        where-object{($_.GroupTypes.Count -eq 0 -or $_.grouptypes -contains "DynamicMembership" -and $_.securityenabled -eq $true) }| 
                        Sort-Object DisplayName).DisplayName
                    $groupquestion =  select-group -grouptype $groupselect -selectType "SELECTED AZURE Dynamic Groups filter"  -multivalue $true
                    foreach ($item3 in $groupquestion)
                    {
                        [string]$gname = $item3
                        $findgroup = get-mggroup -filter "DisplayName eq '$gname'"
                        $group += $findgroup 
                        
                    }
                }
                "Selected Assigned"
                    {
                    # write-host " assigned / selected office security"
                        $groupselect = (get-mggroup -all  | 
                            where-object{($_.GroupTypes.Count -eq 0 -or $_.grouptypes -notcontains "DynamicMembership"  -and $_.securityenabled -ne $true) }| 
                            Sort-Object DisplayName).DisplayName
                        $groupquestion =  select-group -grouptype $groupselect -selectType "SELECTED Assigned Groups filter"  -multivalue $true
                    
                        foreach ($item3 in $groupquestion)
                        {
                            [string]$gname = $item3
                            $findgroup = get-mggroup -filter "DisplayName eq '$gname'"
                            $group += $findgroup 
                            
                        }
                    }
            
                "All"
                {
                    $group = get-mggroup -all | Sort-Object DisplayName 
                }
            }
                if(!$group)
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
                $file = $MainMenuQuestion +"_"+ $GroupTypeQuestion.toupper()+"_"+ $SorOQuestion +"_"
                $OutputFile = select-directory -filename $file -initialDirectory $env:HOMEDRIVE
                if ($OutputFile -eq "Cancel"){exit}
                $GAs | export-csv -Path $OutputFile -NoTypeInformation -Force -Encoding UTF8
        }
        "Group Licenses" 
        {
            switch -exact ($GroupTypeQuestion) 
            {
                "Cancel" {exit}
                "All" 
                {
                    $sps =get-mgsubscribedSku |  Select-Object skupartnumber , serviceplans
                    #get only groups with license assignments 
                    #Graph call to get only groups with assigned licenses by calling only graph to get licenese in the tenant then checking which groups are assigned to those licenses
                    $skus = Get-MgSubscribedSku
                    $SKUinfos = @()
                    $SkubuildURIheader1 = "https://graph.microsoft.com/v1.0/groups?$"
                    $SkubuildURIheader2 = "filter=assignedLicenses/any(s:s/"
                    $SkubuildURIheader3 ="skuId eq " 
                    $skubuildURItrailer1 = ")&"
                    $skubuildURItrailer2 = "$"
                    $skubuildURItrailer3 = "select=displayName, id"
                    $GroupnameSKUinfos =@()
                    foreach ($skuitem in $skus)
                    {
                        [string]$SkuURIpassed = $SkubuildURIheader1 + $SkubuildURIheader2 + $SkubuildURIheader3+ $skuitem.skuId + $skubuildURItrailer1 + $skubuildURItrailer2 + $skubuildURItrailer3
                        #$graphlicense = Invoke-MgGraphRequest -Uri 'https://graph.microsoft.com/v1.0/groups?$filter=assignedLicenses/any(s:s/skuId eq c42b9cae-ea4f-4ab7-9717-81576235ccac)&$select=displayName, id' -method GET
                        $groupwithskureturned = Invoke-MgGraphRequest -Uri $SkuURIpassed -method GET
                                foreach ($iditem in $groupwithskureturned.value.'id') 
                                { 
                                    $GroupnameSKUinfos += New-Object Object | 
                                                Add-Member -NotePropertyName GroupID -NotePropertyValue $iditem -PassThru  |
                                                Add-Member -NotePropertyName SkuId -NotePropertyValue $skuitem.skuid -PassThru |
                                                Add-Member -NotePropertyName SkuName -NotePropertyValue $skuitem.SkuPartNumber -PassThru 

                                }
                    }


                    #$groups = get-mggroup -all 
                    $buildURIheader = "https://graph.microsoft.com/v1.0/groups/" 
                    $q = "?s"
                    $buildURItrailer =  "elect=assignedLicenses"
                    $item = @()
                    $sortedgroup = $skuinfos | Select-Object GroupID | sort-object groupobjectid | get-unique -asstring | Where-Object{$_.GroupID -eq $skuinfos.SkuName}
                    $DISABLEDSkuobject =@()
                    $sortedgroupinfo = $GroupnameSKUinfos | Sort-Object -Unique groupid
                    foreach ($item in $sortedgroupinfo)
                    {
                        $builduripackage = $buildURIheader + $item.GroupID + $q+$buildURItrailer
                        $assignedlicenses = invoke-mggraphrequest -uri $builduripackage -method GET
                        foreach ($assignedlicenseitem in $assignedlicenses.assignedLicenses)
                        {
                        if($assignedlicenseitem.disabledPlans -ge 1)
                        {
                            foreach ($disabledskuitem in $assignedlicenseitem.disabledPlans)
                            {
                                $DISABLEDSkuobject += New-Object Object |
                                    Add-Member -NotePropertyName GroupID -NotePropertyValue $item.GroupID -PassThru |
                                    Add-Member -NotePropertyName SKUId -NotePropertyValue $assignedlicenseitem.skuid -PassThru |
                                    Add-Member -NotePropertyName DisabledServicePlanID -NotePropertyValue $disabledskuitem -PassThru
                            }
                        }
                        else {
                            $DISABLEDSkuobject += New-Object Object |
                                Add-Member -NotePropertyName GroupID -NotePropertyValue $item.GroupID -PassThru |
                                Add-Member -NotePropertyName SKUId -NotePropertyValue $assignedlicenseitem.skuid -PassThru |
                                Add-Member -NotePropertyName DisabledServicePlanID -NotePropertyValue $disabledskuitem -PassThru
                        }
                        }

                    }
                    $FinalSkuobject =@()
                    foreach ($founddisabledplanitem in $disABLEDSkuobject)
                        {
                            $GDN = (get-mggroup -GroupId $founddisabledplanitem.groupid ).DisplayName
                            $sps = get-mgsubscribedSku | ?{$_.SkuId -eq $founddisabledplanitem.SKUId} 
                            $sppartnumber = ($sps).skupartnumber
                            $spserviceplan = $sps.ServicePlans | Select-Object ServicePlanId, serviceplanname | ?{$_.serviceplanid -eq $founddisabledplanitem.DisabledServicePlanID}
                            $FinalSkuobject += New-Object Object |
                                Add-Member -NotePropertyName GroupID -NotePropertyValue $founddisabledplanitem.GroupID -PassThru |
                                Add-Member -NotePropertyName GroupName -NotePropertyValue $GDN -PassThru |
                                Add-Member -NotePropertyName SKUId -NotePropertyValue $founddisabledplanitem.skuid -PassThru |
                                Add-Member -NotePropertyName SKUPartNumber -NotePropertyValue $sppartnumber -PassThru |
                                Add-Member -NotePropertyName DisabledServicePlanID -NotePropertyValue $founddisabledplanitem.DisabledServicePlanID -PassThru |
                                Add-Member -NotePropertyName DisabledServicePlanName -NotePropertyValue $spserviceplan.ServicePlanName -PassThru

                        }
                        $tdy = get-date -Format "MM-dd-yyyy hh.mm.ss"
                        $file = $MainMenuQuestion +"_"+ $GroupTypeQuestion.toupper() +"_"
                        $OutputFile = select-directory -filename $file -initialDirectory $env:HOMEDRIVE
                        if ($OutputFile -eq "Cancel"){exit}
                        $FinalSkuobject | export-csv -Path $OutputFile -NoTypeInformation -Force -Encoding UTF8
                }
                "Selected Groups with Licenses" 
                {
                    $sps =get-mgsubscribedSku |  Select-Object skupartnumber , serviceplans
                    $sps2 = $sps.serviceplans

                    #get only groups with license assignments 

                    #Graph call to get only groups with assigned licenses by calling only graph to get licenese in the tenant then checking which groups are assigned to those licenses
                    $skus = Get-MgSubscribedSku
                    $SKUinfos = @()
                    $SkubuildURIheader1 = "https://graph.microsoft.com/v1.0/groups?$"
                    $SkubuildURIheader2 = "filter=assignedLicenses/any(s:s/"
                    $SkubuildURIheader3 ="skuId eq " 
                    $skubuildURItrailer1 = ")&"
                    $skubuildURItrailer2 = "$"
                    $skubuildURItrailer3 = "select=displayName, id"
                    $GroupnameSKUinfos =@()
                    foreach ($skuitem in $skus)
                    {
                        [string]$SkuURIpassed = $SkubuildURIheader1 + $SkubuildURIheader2 + $SkubuildURIheader3+ $skuitem.skuId + $skubuildURItrailer1 + $skubuildURItrailer2 + $skubuildURItrailer3
                        #$graphlicense = Invoke-MgGraphRequest -Uri 'https://graph.microsoft.com/v1.0/groups?$filter=assignedLicenses/any(s:s/skuId eq c42b9cae-ea4f-4ab7-9717-81576235ccac)&$select=displayName, id' -method GET
                        $groupwithskureturned = Invoke-MgGraphRequest -Uri $SkuURIpassed -method GET
                                #foreach ($iditem in $groupwithskureturned.value.'id') 
                                foreach ($iditem in $groupwithskureturned.value) 
                                { 
                                    $GroupnameSKUinfos += New-Object Object | 
                                                Add-Member -NotePropertyName GroupDisplayname -NotePropertyValue $iditem.displayname -PassThru  |
                                                Add-Member -NotePropertyName GroupID -NotePropertyValue $iditem.id -PassThru  |
                                                Add-Member -NotePropertyName SkuId -NotePropertyValue $skuitem.skuid -PassThru |
                                                Add-Member -NotePropertyName SkuName -NotePropertyValue $skuitem.SkuPartNumber -PassThru 

                                }
                    }


                    #$groups = get-mggroup -all 
                    $buildURIheader = "https://graph.microsoft.com/v1.0/groups/" 
                    $q = "?s"
                    $buildURItrailer =  "elect=assignedLicenses"
                    $item = @()
                    $sortedgroup = $skuinfos | Select-Object GroupID | sort-object groupobjectid | get-unique -asstring | Where-Object{$_.GroupID -eq $skuinfos.SkuName}
                    $DISABLEDSkuobject =@()
                    $sortedgroupinfo = $GroupnameSKUinfos | Sort-Object -Unique groupid
                    $sortedlicensegroupquestion =@()
                    $sortedlicensegroupquestion =  select-group -grouptype $sortedgroupinfo.groupdisplayname -selectType "Select Licensed Group to Export"  -multivalue $true
                    $findgroup =@()
                    $findgroup2 =@()
                    foreach ($selectedlicensegroup in $sortedlicensegroupquestion)
                    {
                        $findgroup = $sortedgroupinfo | Where-Object {$_.GroupDisplayname -match $selectedlicensegroup}
                        $findgroup2 += $findgroup
                    }


                    foreach ($item in $findgroup2)
                    {
                        $builduripackage = $buildURIheader + $item.GroupID + $q+$buildURItrailer
                        $assignedlicenses = invoke-mggraphrequest -uri $builduripackage -method GET
                        foreach ($assignedlicenseitem in $assignedlicenses.assignedLicenses)
                        {
                        if($assignedlicenseitem.disabledPlans -ge 1)
                        {
                            foreach ($disabledskuitem in $assignedlicenseitem.disabledPlans)
                            {
                                $DISABLEDSkuobject += New-Object Object |
                                    Add-Member -NotePropertyName GroupID -NotePropertyValue $item.GroupID -PassThru |
                                    Add-Member -NotePropertyName SKUId -NotePropertyValue $assignedlicenseitem.skuid -PassThru |
                                    Add-Member -NotePropertyName DisabledServicePlanID -NotePropertyValue $disabledskuitem -PassThru
                            }
                        }
                        else {
                            $DISABLEDSkuobject += New-Object Object |
                                Add-Member -NotePropertyName GroupID -NotePropertyValue $item.GroupID -PassThru |
                                Add-Member -NotePropertyName SKUId -NotePropertyValue $assignedlicenseitem.skuid -PassThru |
                                Add-Member -NotePropertyName DisabledServicePlanID -NotePropertyValue $disabledskuitem -PassThru
                        }
                        }

                    }
                    $FinalSkuobject =@()
                    foreach ($founddisabledplanitem in $disABLEDSkuobject)
                        {
                            $GDN = (get-mggroup -GroupId $founddisabledplanitem.groupid ).DisplayName
                            $sps = get-mgsubscribedSku | ?{$_.SkuId -eq $founddisabledplanitem.SKUId} 
                            $sppartnumber = ($sps).skupartnumber
                            $spserviceplan = $sps.ServicePlans | Select-Object ServicePlanId, serviceplanname | ?{$_.serviceplanid -eq $founddisabledplanitem.DisabledServicePlanID}
                            $FinalSkuobject += New-Object Object |
                                Add-Member -NotePropertyName GroupID -NotePropertyValue $founddisabledplanitem.GroupID -PassThru |
                                Add-Member -NotePropertyName GroupName -NotePropertyValue $GDN -PassThru |
                                Add-Member -NotePropertyName SKUId -NotePropertyValue $founddisabledplanitem.skuid -PassThru |
                                Add-Member -NotePropertyName SKUPartNumber -NotePropertyValue $sppartnumber -PassThru |
                                Add-Member -NotePropertyName DisabledServicePlanID -NotePropertyValue $founddisabledplanitem.DisabledServicePlanID -PassThru |
                                Add-Member -NotePropertyName DisabledServicePlanName -NotePropertyValue $spserviceplan.ServicePlanName -PassThru

                        }
                        $tdy = get-date -Format "MM-dd-yyyy hh.mm.ss"

                        $file = $MainMenuQuestion +"_"+ $GroupTypeQuestion.toupper() +"_"
                        $OutputFile = select-directory -filename $file -initialDirectory $env:HOMEDRIVE
                        if ($OutputFile -eq "Cancel"){exit}
                        $FinalSkuobject | export-csv -Path $OutputFile -NoTypeInformation -Force -Encoding UTF8
                }
            }
        }
        "Group Owners" 
        {
            $GOs =@()
            switch -exact ($GroupTypeQuestion) 
            {
                "Cancel" {exit}
                "Assigned" 
                {
                    $group = get-mggroup -all |
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
                "Dynamic"
                {
                    $group = get-mggroup -all  |
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
                "All"
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
            }
            #creating header for CSV
            $file = $MainMenuQuestion +"_"+ $GroupTypeQuestion.toupper()+"_"+ $SorOQuestion
            $OutputFile = select-directory -filename $file -initialDirectory $env:HOMEDRIVE
            if ($OutputFile -eq "Cancel"){exit}
            $GOs | export-csv -Path $OutputFile -NoTypeInformation -Force -Encoding UTF8
        }
        "Groups in Application"        
        {
            $MGGROUP = get-mggroup -all  | Sort-Object DisplayName
            $apgroup        = @()
            $Gapps          = @()
            foreach ($apgroup in $MGGROUP) 
                { 
                    $applist = get-mggroupappRoleAssignment -groupid $apgroup.id |Where-Object{$_.PrincipalId -ne $null}
                    foreach ($applistitem in $applist)
                    {
                        $Gapps += New-Object Object |
                        Add-Member -NotePropertyName Group_DisplayName -NotePropertyValue $apgroup.DisplayName -PassThru |
                        Add-Member -NotePropertyName Group_ID -NotePropertyValue $apgroup.id -PassThru |
                        Add-Member -NotePropertyName Id -NotePropertyValue $applistitem.Id -PassThru |
                        Add-Member -NotePropertyName AppRoleId -NotePropertyValue $applistitem.AppRoleId -PassThru |
                        Add-Member -NotePropertyName PrincipalDisplayName -NotePropertyValue $applistitem.PrincipalDisplayName -PassThru |
                        Add-Member -NotePropertyName PrincipalId -NotePropertyValue $applistitem.PrincipalId -PassThru |
                        Add-Member -NotePropertyName PrincipalType -NotePropertyValue $applistitem.PrincipalType -PassThru |
                        Add-Member -NotePropertyName ResourceDisplayName -NotePropertyValue $applistitem.ResourceDisplayName -PassThru |
                        Add-Member -NotePropertyName ResourceId -NotePropertyValue $applistitem.ResourceId -PassThru    
                    }
                }
                
            #$gapps2 = $gapps | where-object{$_.ResourceDisplayName -ne $null}
            #creating header for CSV
            $file = $MainMenuQuestion +"_"
            $OutputFile = select-directory -filename $file -initialDirectory $env:HOMEDRIVE
            if ($OutputFile -eq "Cancel"){exit}
            $gapps | export-csv -Path $OutputFile -NoTypeInformation -Force -Encoding UTF8
        }
    }
}
while ($MainMenuQuestion -ne "Cancel")