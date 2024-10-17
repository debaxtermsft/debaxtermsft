<#
written by derrick baxter 8/15/22
Updated 10/17/24
used to export all licenses and service plan information in 1 file
export all disabled service plans and how licenses are assigned direct or by a group 
Added All or selected user popup

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

#Connect-MgGraph -Scopes "group.read.all, directory.read.all, group.readwrite.all, groupmember.read.all, groupmember.readwrite.all,AuditLog.Read.All"
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
	    $userandoid = $findusername.DisplayName + " : " + $uiditem
	     $upn = $findusername.UserPrincipalName
            $UserProperties += New-Object Object |
            Add-Member -NotePropertyName ObjectId -NotePropertyValue $uiditem -PassThru |
            Add-Member -NotePropertyName DisplayName -NotePropertyValue $findusername.DisplayName -PassThru | 
            Add-Member -NotePropertyName SkuId -NotePropertyValue $skuitemfound.SkuId -PassThru | 
            Add-Member -NotePropertyName Skupartnumber -NotePropertyValue $skuitemfound.skuname -PassThru |
            Add-Member -NotePropertyName userandoid -NotePropertyValue $userandoid -PassThru |
            Add-Member -NotePropertyName UserPrincipalName -NotePropertyValue $upn -PassThru 
        }
}


# select ALL or selected users popup

$LicenseSelecttype    = @("Export All users with Licenses","Select Users with Licenses")
$Licensefilterselection =  select-group -grouptype $LicenseSelecttype -selectType "All or Select"

if($Licensefilterselection -eq "Export All users with Licenses")
{
    $userselection = $userproperties
}
else {
    $groupselect2 = ($userproperties | sort-object userprincipalname -Unique).userprincipalname
    $groupquestion2 =  select-group -grouptype $groupselect2 -selectType "Select User to check Licenses"  -multivalue $true
    if($groupquestion2 -eq "Cancel"){exit}
        $userselection =@()
        foreach ($groupselectitem2 in $groupquestion2)
        {
            $userselection += $userproperties | where-object{$_.userprincipalname -eq $groupselectitem2}  
        }
}


<#
user selection is correct at this point w upn and SKUid working
#>
$UserLicensePlanProperties = @()
foreach($founduserlicenseinfoitem in $userselection)
{
	$lookupUserLicenseDetails = get-mgUserLicenseDetail -userId $founduserlicenseinfoitem.userprincipalname | Where-Object{$_.skuid -eq $founduserlicenseinfoitem.skuid}
	$serviceplanslist = $lookupUserLicenseDetails.serviceplans
	foreach ($lookupitem in $serviceplanslist  )
		{
		        $UserLicensePlanProperties += New-Object Object |
        		Add-Member -NotePropertyName ObjectId -NotePropertyValue $founduserlicenseinfoitem.objectid -PassThru |
		        Add-Member -NotePropertyName Displayname -NotePropertyValue $founduserlicenseinfoitem.displayname -PassThru |
		        Add-Member -NotePropertyName UserPrincipalName -NotePropertyValue $founduserlicenseinfoitem.UserPrincipalName -PassThru |
		        Add-Member -NotePropertyName Skuid -NotePropertyValue $founduserlicenseinfoitem.Skuid -PassThru |
		        Add-Member -NotePropertyName SKUName -NotePropertyValue $founduserlicenseinfoitem.Skupartnumber -PassThru |
		        Add-Member -NotePropertyName ServicePlanName -NotePropertyValue  $lookupitem.ServicePlanName -PassThru |
			Add-Member -NotePropertyName ServicePlanId -NotePropertyValue $lookupitem.ServicePlanId  -PassThru |
			Add-Member -NotePropertyName ProvisioningStatus -NotePropertyValue $lookupitem.ProvisioningStatus  -PassThru |
			Add-Member -NotePropertyName AppliesTo -NotePropertyValue $lookupitem.AppliesTo -PassThru 

		}
}

$file = "User_License_Plan_"
$OutputFile = select-directory -filename $file -initialDirectory $env:HOMEDRIVE
if ($OutputFile -eq "Cancel"){exit}
$UserLicensePlanProperties | Sort-Object -property UserPrincipalName, SkuID, ServicePlanName  | export-csv -Path $OutputFile -NoTypeInformation -Force -Encoding UTF8
