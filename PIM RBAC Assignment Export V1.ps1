#######################
# the below script uses the AzureADPreview powershell module pulling all roleassignments for groups
# It was created to pull the PIM Active and Eligible Role assignments for Subscriptions and Management groups
# 06/22/2022 
# V1
# written by derrick baxter
#######################

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

function select-options ()
{

    # selection to save the output to a single file or one file per subscriptions or management group

    
    return $fileselection
}    

#logging into azuread
try
{
    get-azureaduser -top 1
}
catch
{
    Connect-Azuread
}
try
{
    get-azaduser -ErrorAction stop >$null
}
catch
{
    $firstlogin = Connect-AzAccount
}

# getting output directory
$fileselection   =@()
$outputdirectory =@()




$outputdirectory = save-directory
if ($outputdirectory -eq "Cancel"){exit}
# setting variable arrays
$RBACAssignments1   = @()
$RBACPRA1           =@()
$rbacobjectinfo1    =@()
$rbacroles          =@()
do
    {

        $oneormultiplefiles     = "Save all to 1 file or per selected sub/mgmt group"
        $multiplefilesoptions   = @("All in ONE File","One File per Selected sub or mgmt group")
        $fileselection =  select-listbox -grouptype $multiplefilesoptions -selectType $oneormultiplefiles
        if ($fileselection -eq "Cancel"){exit}
        $pimfilterselection     =@()
        $subselection           =@()
        # getting select of subscriptions or managementgroup
        $RBACSelecttype     = "RBAC Filter options "
        $pimresourcetype    = @("Subscription","Management Group")
        $pimfilterselection =  select-listbox -grouptype $pimresourcetype -selectType $RBACSelecttype
        
        if ($pimfilterselection -eq "Cancel"){break}
        elseif($pimfilterselection -eq "Subscription")
        {
            $subscriptionselection  =@()
            $RBACSelecttype         = "Select Subscription(s)"
            $pimresourcelist        = Get-AzureADMSPrivilegedResource -ProviderId AzureResources  | Select-Object type,Displayname, id, externalid | ?{$_.type -eq "subscription"} | sort-object displayname
            foreach ($resourceitem in $pimresourcelist)
            {
                [string]$subnameandid   = $resourceitem.externalid  + " : " +  $resourceitem.displayname 
                $subnameandid           = $subnameandid -replace "/subscriptions/",""

                $subselection           += $subnameandid
            }
            $subscriptionselection  =  select-listbox -grouptype $subselection -selectType $RBACSelecttype -multivalue $true
            if ($subscriptionselection -eq "Cancel"){break}
        }
        else
        {
            $subscriptionselection  =@()
            $subselection           =@()
            $RBACSelecttype         = "Select Management Group(s)"
            $pimresourcelist        = Get-AzureADMSPrivilegedResource -ProviderId AzureResources  | Select-Object type,Displayname, id, externalid | ?{$_.type -eq "managementgroup"} | sort-object displayname
            foreach ($resourceitem in $pimresourcelist)
            {
                [string]$subnameandid   = $resourceitem.externalid  + ":" +  $resourceitem.displayname 
                $subnameandid           = $subnameandid -replace "/providers/Microsoft.Management/managementGroups/",""

                $subselection           += $subnameandid
            }
            $subscriptionselection  =  select-listbox -grouptype $subselection -selectType $RBACSelecttype -multivalue $true
            if ($subscriptionselection -eq "Cancel"){break}

        }
        #looking up management groups subscriptions
        $exid =@()
        foreach ($item in $subscriptionselection)
        {
            $CharArray          = $item.Split(":")
            $externalidselected = $CharArray[0]
            $exid               += $externalidselected.replace(' ' , '')
            
        }
        $subscriptionselection = $exid

        if($pimfilterselection -ne "Subscription")
        {
            $subid =@()
            foreach($subselect in $exid)
            {
                $mgmtsubscription =  Get-AzManagementGroupSubscription -GroupName $subselect
                if ($mgmtsubscription -ne $null){
                    foreach ($mgsubitem in $mgmtsubscription)
                    {
                        $subname = Get-AzSubscription -SubscriptionName $mgsubitem.DisplayName | Select-Object id, name
                        
                        $subid += $subname.Id +" : " + $subname.Name 

                    }
                    $mgmtsubscriptionselection  =@()
                    $subselection           =@()
                    $mgmtSelecttype         = "Select Subscriptions in the Management Group"
                    $mgmtsubscriptionselection  =  select-listbox -grouptype $subid -selectType $mgmtSelecttype -multivalue $true
                    foreach ($item2 in $mgmtsubscriptionselection)
                    {
                        $CharArray1          = $item2.Split(":")
                        $externalidselected1 = $CharArray1[0]
                        $exid               += $externalidselected1.replace(' ' , '')
                    }

                    
                }

            }
            $subscriptionselection = $exid
        }
        
        foreach ($selecteditem in $subscriptionselection)
            {

                $RBACAssignments1   = Get-AzureADMSPrivilegedResource -ProviderId AzureResources | select id, externalid, type, displayname, status |Sort-Object externalid, displayname | ?{$_.externalid -match $selecteditem}
                if ($RBACAssignments1 -eq $null){ write-host "No PIM Assignments" $selecteditem}
                else
                {
                    foreach ($rbacitem1 in $RBACAssignments1)
                        {
                            $RBACPRA1 = Get-AzureADMSPrivilegedRoleAssignment -ProviderId AzureResources -resourceid $rbacitem1.Id
                            if ($RBACPRA1.count -gt 2000) {$setsleep -eq $true}
                            foreach ($praitem1 in $RBACPRA1)
                            {
                                $rbacroledefinition = (Get-AzureADMSPrivilegedRoleDefinition -ProviderId AzureResources -ResourceId $praitem1.ResourceId -Id $praitem1.RoleDefinitionId).DisplayName
                                $rbacobjectinfo1 = Get-AzureADObjectByObjectId -ObjectIds $praitem1.subjectid
                                $rbacroles += New-Object Object |
                                                Add-Member -NotePropertyName RoleDefinitionName     -NotePropertyValue  $rbacroledefinition -PassThru |
                                                Add-Member -NotePropertyName ResourceDisplayName     -NotePropertyValue $rbacitem1.DisplayName -PassThru |
                                                Add-Member -NotePropertyName ResourceType            -NotePropertyValue $rbacitem1.Type -PassThru |
                                                Add-Member -NotePropertyName ResourceExternalID      -NotePropertyValue $rbacitem1.externalid -PassThru |
                                                Add-Member -NotePropertyName ResourceID              -NotePropertyValue $rbacitem1.id -PassThru |
                                                Add-Member -NotePropertyName ObjectDisplayName       -NotePropertyValue $rbacobjectinfo1.displayname -PassThru |
                                                Add-Member -NotePropertyName UserPrincipalName       -NotePropertyValue $rbacobjectinfo1.userprincipalname -PassThru |
                                                Add-Member -NotePropertyName ObjectID                -NotePropertyValue $rbacobjectinfo1.objectid -PassThru |
                                                Add-Member -NotePropertyName ObjectType              -NotePropertyValue $rbacobjectinfo1.objecttype -PassThru |
                                                Add-Member -NotePropertyName AssignmentState         -NotePropertyValue $praitem1.assignmentstate -PassThru |
                                                Add-Member -NotePropertyName MemberType              -NotePropertyValue $praitem1.membertype -PassThru |
                                                Add-Member -NotePropertyName AssignmentStartDateTime -NotePropertyValue $praitem1.startdatetime -PassThru |
                                                Add-Member -NotePropertyName AssignmentEndDateTime   -NotePropertyValue $praitem1.enddatetime -PassThru 
                                # sleep added to keep from hitting a throttling limit to keep from hitting 2000 requests/sec limit
                                if ($setsleep -eq $true ) {Start-Sleep -Seconds 1}
                            }

                        
                        # saving each selected subscription(s) or management group(s) into individual files

                        }
                        if($fileselection -eq "One File per Selected sub or mgmt group") 
                        { 
                        
                            $tdy        = get-date -Format "MM-dd-yyyy hh.mm.ss"
                            $filename1  = "PIM Assignment Export " + $pimfilterselection +" "+ $rbacitem1.DisplayName+" "+ $tdy +".csv"           
                            $OutputFile = "$outputdirectory"+"\"+"$filename1"
                            $rbacroles | export-csv -Path $outputfile -force -Encoding UTF8 -NoTypeInformation
                            $rbacroles =@()
                        }
                }
            
            }
        if($fileselection -eq "All in ONE File") 
        { 
            
            $tdy        = get-date -Format "MM-dd-yyyy hh.mm.ss"
            $filename1  = "PIM Assignment Export Single Export " + $pimfilterselection + " " + $tdy +".csv"           
            $OutputFile = "$outputdirectory"+"\"+"$filename1"
            $rbacroles | export-csv -Path $outputfile -force -Encoding UTF8 -NoTypeInformation
            $rbacroles =@()
        }
    }   
while($subscriptionselection -ne "Cancel")