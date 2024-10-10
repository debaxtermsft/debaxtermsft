<#
written by derrick baxter 8/15/22
used to export all licenses and service plan information in 1 file
export all disabled service plans and how licenses are assigned direct or by a group 
skuid and name
sp id and name
group id and name
user objectid and name

This uses microsoft.graph module for powershell

You will be able to select the SKU Name to review 
You can then select/multiselect the users having license issues
it will then save the user license info and license state info


#>


[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 


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

function select-directory([string] $initialDirectory, $filename)
    {
        $tdy = get-date -Format "MM-dd-yyyy hh.mm.ss"
        $outputfile = $filename + $tdy +".csv"
        $SaveFileDialog = New-Object windows.forms.savefiledialog  
        $SaveFileDialog.FileName = $outputfile 
        $SaveFileDialog.initialDirectory = $initialDirectory
        $SaveFileDialog.title = "Save File to Disk"
        $SaveFileDialog.filter = "License Export File | License Export File *.csv|Comma Seperated File|*.csv | All Files|*.* " 
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

Connect-MgGraph -Scopes "directory.read.all"

$skus1 = Get-MgSubscribedSku -All | Sort-Object SkuPartNumber

$skuProperties =@()
foreach ($itemsku in $skus1)
{
    $skuinformation = Get-MgSubscribedSku |?{$_.skuid -eq $itemsku.skuid}
    $skusps = $skuinformation.ServicePlans
    foreach ($skuspitem in $skusps)
    {
        $skuProperties += New-Object Object |
        Add-Member -NotePropertyName Skuid -NotePropertyValue $skuinformation.SkuId -PassThru |
        Add-Member -NotePropertyName SkuName -NotePropertyValue $skuinformation.SkuPartNumber -PassThru | 
        Add-Member -NotePropertyName ServicePlanId -NotePropertyValue $skuspitem.ServicePlanId -PassThru | 
        Add-Member -NotePropertyName ServicePlanName -NotePropertyValue $skuspitem.ServicePlanName -PassThru 
    }

}

$useridswlicenses =@()
$skus = $skuProperties |  Sort-Object skuid -Unique    

$groupselect1 = ($skus | sort-object skuname -Unique).skuname
$groupquestion1 =  select-group -grouptype $groupselect1 -selectType "Select SKU"  -multivalue $true
if($groupquestion -eq "Cancel"){exit}
$skuselection =@()
foreach ($groupselectitem1 in $groupquestion1)
{
    $skuselection += $skuProperties | where-object{$_.skuname -eq $groupselectitem1} 
}

$skuselection = $skuselection | Sort-Object skuname -Unique

$UserProperties =@()
foreach ($skuitemfound in $skuselection)
{
$SkubuildURIheader1 = "https://graph.microsoft.com/v1.0/users?$"
$SkubuildURIheader2 = "filter=assignedLicenses/any(s:s/"
$SkubuildURIheader3 ="skuId eq " 
$skubuildURItrailer1 = ")&"
$skubuildURItrailer2 = "$"
$skubuildURItrailer3 = "select=displayName, id, assignedLicenses, assignedplans, licenseAssignmentStates"

[string]$SkuURIpassed = $SkubuildURIheader1 + $SkubuildURIheader2 + $SkubuildURIheader3+ $skuitemfound.SkuId + $skubuildURItrailer1 + $skubuildURItrailer2 + $skubuildURItrailer3
write-host $skuURIpassed

$userswlicenes = invoke-mggraphrequest -uri $SkuURIpassed -method GET
$useridswlicenses = $userswlicenes.value.id
    foreach ($uiditem in $useridswlicenses)
        {
             $findusername = get-mguser -userid $uiditem
            $UserProperties += New-Object Object |
            Add-Member -NotePropertyName ObjectId -NotePropertyValue $uiditem -PassThru |
            Add-Member -NotePropertyName DisplayName -NotePropertyValue $findusername.DisplayName -PassThru | 
            Add-Member -NotePropertyName SkuId -NotePropertyValue $skuitemfound.SkuId -PassThru | 
            Add-Member -NotePropertyName Skupartnumber -NotePropertyValue $skuitemfound.skuname -PassThru 
        }
}

#https://graph.microsoft.com/v1.0/users/mk.one@twdsavior18.com?$select=assignedLicenses,assignedPlans


$groupselect2 = ($UserProperties | sort-object displayname -Unique).displayname
$groupquestion2 =  select-group -grouptype $groupselect2 -selectType "Select User to check Licenses"  -multivalue $true
if($groupquestion2 -eq "Cancel"){exit}
$userselection =@()
foreach ($groupselectitem2 in $groupquestion2)
{
    $userselection += $userproperties | where-object{$_.displayname -eq $groupselectitem2}  
}


$DISABLEDSkuobject =@()
$UserLicenseProperties =@()

$UserLicenseProperties1 = $userselection | Select-Object -property Displayname, objectid | Sort-Object objectid -Unique
foreach ($ULItem in $UserLicenseProperties1)
{
#write-host " user id " $ULItem.objectid " Displayname " $ulitem.displayname
$buildURIheader = "https://graph.microsoft.com/v1.0/users/" 
$q = "?s"
$buildURItrailer =  "elect=assignedLicenses, assignedplans"
$buildURILicenseState = "elect=licenseAssignmentStates"
$userid = $ULItem.objectid
$builduripackage = $buildURIheader + $userID + $q+$buildURItrailer
$builduripackage2 = $buildURIheader + $userID + $q+$buildURILicenseState
$assignedlicenses = invoke-mggraphrequest -uri $builduripackage -method GET
$licensestates = invoke-mggraphrequest -uri $builduripackage2 -method GET
$aps =  $assignedlicenses.assignedplans
$al2 = $assignedlicenses.assignedLicenses 

    foreach($holdaps in $aps)
    {
        $findaps = $skuproperties | ?{$_.serviceplanid -eq $holdaps.serviceplanid}
        $UserLicenseProperties += New-Object Object |
        Add-Member -NotePropertyName ObjectId -NotePropertyValue $ULItem.objectid -PassThru |
        Add-Member -NotePropertyName Displayname -NotePropertyValue $ULItem.displayname -PassThru |
        Add-Member -NotePropertyName Skuid -NotePropertyValue $findaps.SkuId -PassThru |
        Add-Member -NotePropertyName SKUName -NotePropertyValue $findaps.SkuName -PassThru |
        Add-Member -NotePropertyName ServicePlanName -NotePropertyValue $findaps.ServicePlanName -PassThru |
        Add-Member -NotePropertyName ServicePlanId -NotePropertyValue $findaps.serviceplanid -PassThru |
        Add-Member -NotePropertyName capabilityStatus -NotePropertyValue $holdaps.capabilityStatus -PassThru |
        Add-Member -NotePropertyName DisabledServicePlanName -NotePropertyValue $null -PassThru |
        Add-Member -NotePropertyName DisabledServicePlan -NotePropertyValue $null -PassThru 
        
    }
    foreach($holdal2item in $al2)
    {
            $dsp = $holdal2item.disabledPlans
            if($dsp -ne 0)
            {
                $spinfo = $skuproperties | Where-Object{$_.serviceplanid -eq $holdal2item.disabledplans}
                $UserLicenseProperties += New-Object Object |
                        Add-Member -NotePropertyName ObjectId -NotePropertyValue $ULItem.objectid -PassThru |
                        Add-Member -NotePropertyName Displayname -NotePropertyValue $ULItem.displayname -PassThru |
                        Add-Member -NotePropertyName skuId -NotePropertyValue $spinfo.SkuId -PassThru |
                        Add-Member -NotePropertyName SKUName -NotePropertyValue $spinfo.Skupartnumber -PassThru |
                        Add-Member -NotePropertyName ServicePlanName -NotePropertyValue $spinfo.ServicePlanName -PassThru |
                        Add-Member -NotePropertyName ServicePlanId -NotePropertyValue $null -PassThru |
                        Add-Member -NotePropertyName capabilityStatus -NotePropertyValue $null -PassThru |
                        Add-Member -NotePropertyName DisabledServicePlanName -NotePropertyValue $spinfo.ServicePlanName -PassThru |
                        Add-Member -NotePropertyName DisabledServicePlan -NotePropertyValue $spinfo.serviceplanid -PassThru 
             }
    }
    $LAS2 = $licensestates.licenseassignmentstates

    foreach ($lasitem in $LAS2)
    {
        $findaps = $skuproperties | where-object{$_.skuid -eq $lasitem.skuid} | Sort-Object skuid -Unique
        #write-host "skuinfo " $findaps.skuname
        if($lasitem.assignedbygroup.count-ge 1)
        {
            $gpname = get-mggroup -GroupId $lasitem.assignedByGroup
            #write-host "groupname " $gpname.DisplayName
        }
        else {$gpname = "None" }
        $licensehold = $lasitem
        
        foreach ($assignedlicenseitem in $licensehold)
        {
            $dps = $assignedlicenseitem.disabledplans
            if($dps.Count -ge 1)
            {
                foreach ($dpitem in $dps)
                {
                    $finddpname = $skuproperties | Where-Object{$_.serviceplanid -eq $dpitem}
                    $DISABLEDSkuobject += New-Object Object |
                        Add-Member -NotePropertyName ObjectId -NotePropertyValue $ULItem.objectid -PassThru |
                        Add-Member -NotePropertyName Displayname -NotePropertyValue $ULItem.displayname -PassThru |
                        Add-Member -NotePropertyName GroupName -NotePropertyValue $gpname.DisplayName -PassThru |
                        Add-Member -NotePropertyName GroupID -NotePropertyValue $gpname.id -PassThru |
                        Add-Member -NotePropertyName SkuId -NotePropertyValue $finddpname.skuid -PassThru |
                        Add-Member -NotePropertyName SkuName -NotePropertyValue $finddpname.skuname -PassThru |
                        Add-Member -NotePropertyName DisabledServicePlanID -NotePropertyValue $finddpname.serviceplanid -PassThru |
                        Add-Member -NotePropertyName DisabledServicePlanName -NotePropertyValue $finddpname.serviceplanname -PassThru |
                        Add-Member -NotePropertyName error -NotePropertyValue $assignedlicenseitem.error -PassThru |
                        Add-Member -NotePropertyName state -NotePropertyValue $assignedlicenseitem.state -PassThru |
                        Add-Member -NotePropertyName lastupdatedDateTime -NotePropertyValue $assignedlicenseitem.lastUpdatedDateTime -PassThru 
                }
            }
            else {
    
                $DISABLEDSkuobject += New-Object Object |
                Add-Member -NotePropertyName ObjectId -NotePropertyValue $ULItem.objectid -PassThru |
                Add-Member -NotePropertyName Displayname -NotePropertyValue $ULItem.displayname -PassThru |
                Add-Member -NotePropertyName GroupName -NotePropertyValue $gpname.DisplayName -PassThru |
                Add-Member -NotePropertyName GroupID -NotePropertyValue $gpname.id -PassThru |
                Add-Member -NotePropertyName SKUId -NotePropertyValue $findaps.skuid -PassThru |
                Add-Member -NotePropertyName SKUName -NotePropertyValue $findaps.SkuName -PassThru |
                Add-Member -NotePropertyName DisabledServicePlanID -NotePropertyValue $null -PassThru |
                Add-Member -NotePropertyName DisabledServicePlanName -NotePropertyValue $null -PassThru |
                Add-Member -NotePropertyName error -NotePropertyValue $assignedlicenseitem.error -PassThru |
                Add-Member -NotePropertyName state -NotePropertyValue $assignedlicenseitem.state -PassThru |
                Add-Member -NotePropertyName lastupdatedDateTime -NotePropertyValue $assignedlicenseitem.lastUpdatedDateTime -PassThru 
            }
        }
    
    }

}

$file = "User_License_Info_"
$OutputFile = select-directory -filename $file -initialDirectory $env:HOMEDRIVE
if ($OutputFile -eq "Cancel"){exit}
$UserLicenseProperties | Sort-Object -property displayname, ServicePlanName, DisabledServicePlanName  | export-csv -Path $OutputFile -NoTypeInformation -Force -Encoding UTF8

$file = "User_License_States_"
$OutputFile = select-directory -filename $file -initialDirectory $env:HOMEDRIVE
if ($OutputFile -eq "Cancel"){exit}
$DISABLEDSkuobject  | sort-object -Property displayname, skuname, DisabledServicePlanName | export-csv -Path $OutputFile -NoTypeInformation -Force -Encoding UTF8

