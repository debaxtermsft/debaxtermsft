#######################
# the below script uses the AZ powershell module pulling all roleassignments for groups
# V2 added in sorting selection by DisplayName, RoleDefinitionName and Scope
# V2 changed select-list box function name to more appropriate
# ALL RBAC Version
# 2/17/2022 
# updated 6/21/22 - changed to objects and added signinname to export
# V6
# updated to select multiple tenant and subscriptions then iterate through all selected
# removed unused functions and user/group/spn selection options for now
# written by debaxter@microsoft.com
#######################

$WarningPreference = "SilentlyContinue"
#function for picking a directory to save the file
function save-directory([string] $initialDirectory, $filename)
    {
        #$outputfile = $filename
        #$SaveFileDialog = New-Object windows.forms.savefiledialog  
        #$SaveFileDialog.FileName = $filename 
        #$SaveFileDialog.initialDirectory = $initialDirectory
        #$SaveFileDialog.title = "Select directory"
        #$result = $SaveFileDialog.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true; TopLevel = $true}))
  
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($dialog.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true; TopLevel = $true})) -eq [System.Windows.Forms.DialogResult]::OK) 
        {
            $directoryName = $dialog.SelectedPath
            Write-Host "Directory selected is $directoryName"
        }
        

        return $directoryName
    } 

#function for creating list boxes
function select-listbox ($grouptype, $selectType, $groupselect, $multivalue, $scopelist )
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

    foreach ($item in $scopelist)
        {
            [void] $listBox.Items.Add($item)
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
            
            break
        }
    return $x
    } # end function select-app

    $audittype = @()
    $aduserquestion =@()
    $adusers =@()
    $fileprefix =@()
    $roleinfo =@()
    $roleinfo2 =@()
#function to build the csv file and save
function build-file ($anotherlist, $scopetype, $filename)
{
        $roleinfo =@()
        $roleinfo2=@()
         if ($selectscope -eq "Cancel"){break}
        $rbacrolelist = $list |Sort-Object $scopetype 
        
            if ($rbacrolelist -eq $null)
            { 
                break
            }
            else
                {
            
                    foreach ($item3 in $rbacrolelist)
                    {
                        #$roleinfo2 = $item3.DisplayName  +","+  $item3.ObjectID+","+  $item3.ObjectType+","+  $item3.RoleDefinitionName+","+  $item3.Scope+","+  $item3.RoleDefinitionId +","+  $item3.RoleAssignmentId
                        #$roleinfo += $roleinfo2

                        $roleinfo += New-Object Object |
                        Add-Member -NotePropertyName DisplayName -NotePropertyValue $item3.DisplayName -PassThru |
                        Add-Member -NotePropertyName ObjectID -NotePropertyValue $item3.ObjectId -PassThru |
                        Add-Member -NotePropertyName ObjectType -NotePropertyValue $item3.ObjectType -PassThru |
                        Add-Member -NotePropertyName SignInName -NotePropertyValue $item3.SigninName -PassThru | 
                        Add-Member -NotePropertyName RoleDefinitionName -NotePropertyValue $item3.RoleDefinitionName -PassThru |
                        Add-Member -NotePropertyName Scope -NotePropertyValue $item3.Scope -PassThru |
                        Add-Member -NotePropertyName RoleDefinitionID -NotePropertyValue $item3.RoleDefinitionID -PassThru |
                        Add-Member -NotePropertyName RoleAssignmentID -NotePropertyValue $item3.RoleAssignmentID -PassThru 
                        
                        
                    }
                }
        $tdy = get-date -Format "MM-dd-yyyy hh.mm.ss"
        $filename1 = $filename +" " + $subscriptionselected.name+" "+$subscriptionselected.id +" "+ $domainselected +" "+ $tdy +".csv"           
        $OutputFile = "$outputdirectory"+"\"+"$filename1"
        
        $roleinfo | export-csv -Path $outputfile -force -Encoding UTF8 -NoTypeInformation
        

}

#logging into az
try
{
    get-azaduser -ErrorAction stop >$null
}
catch
{
    $firstlogin = Connect-AzAccount
}



$AASRolegroupoutput =@()

if ($OutputFile -eq "Cancel"){break}


#Getting all domains in Azcontext after login : Making sure any tenants that need auth are prompted
$getdomains = (get-azdomain).name

$domainquestion =  select-listbox -grouptype $getdomains -selectType "Multiselect Domain Filter"  -multivalue $true
if ($domainquestion -eq "Cancel"){break}

$othertenants =@()
foreach ($selecteddomain in $domainquestion)
{
$othertenants += get-azdomain | ?{$_.id -ne $firstlogin.Context.Tenant.id -and $_.Name -eq $selecteddomain}
}

foreach ($domainitem in $othertenants )
{
    write-host "Adding Tenant : " $domainitem.Id " Tenant Name : " $domainitem.Name
    Add-AzAccount -Tenant $domainitem.id  
}
$getsubscriptions =@()
#getting all subscriptions for domains selected
foreach ($domainselected in $domainquestion)
{
    $domainid = (get-azdomain |?{$_.Name -eq $domainselected}).Id
    $getsubscriptions += (Get-AzSubscription -TenantId $domainid).Name
}
$subsxquestion =  select-listbox -grouptype $getsubscriptions -selectType "Multiselect Subscription filter"  -multivalue $true
if ($subsxquestion -eq "Cancel"){break}

$subs =@()
Foreach ($subanswer in $subsxquestion)
{
    $subs += Get-AzSubscription |?{$_.Name -eq "$subanswer" -and $_.tenantid -eq $domainitem.TenantId}
}


$counter = 0
$outputdirectory = save-directory
$groupquestion=@()

$grouptype = @("All RBAC","All Users","All Groups", "All Service Principals", "Identity Unknown")
$groupquestion =  select-listbox -grouptype $grouptype -selectType $RBACSelecttype
if ($groupquestion -eq "Cancel"){break}    

$RBACSelecttype = "RBAC Filter option: Domain $domainselected"
$scopetype = @("DisplayName","Scope","RoleDefinitionName")
$selectscope = select-listbox -scopelist $scopetype -selectType "Sort by Filter"
if ($selectscope -eq "Cancel"){break}

 

    foreach ($subscriptionselected in $subs)
        {
            $list =@()
            $list2 =@()
            
            $file =@()
            $outputfile =@()
            $rbacrole =@()
            $rbaclist =@()
            $rbacrolelist =@()
            $roleinfo =@()
            $roleinfo2 =@()
            $item =@()
            $item2 =@()
            $item3 =@()
            $AASRolegroupoutput =@()
            $scopetype =@()
            $scopeselect =@()

            $file = $groupquestion

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
                    write-host "Scanning RBAC Roles in Subscription : " $subscriptionselected.Name
                    Set-AzContext -Subscription $subscriptionselected.id #-Tenant $subselectect.TenantId

                if ($groupquestion -eq "All RBAC")
                {                
                    $users = get-azroleassignment # | Where-Object {$_.SignInName -ne $null} 
                    foreach ($userfound in $users)
                    {
                        $list += $userfound
                    }

                    build-file -anotherlist $list -filename $file  -scopetype $selectscope -outputdirectory $outputdirectory
                }

                elseif ($groupquestion -eq "All Groups")
                {
                    $objecttype = "Group"

                    $list = get-azroleassignment | Where-Object {$_.ObjectType -eq $objecttype}  #|select DisplayName, RoleAssignmentId, Scope, RoleDefinitionName, RoleDefinitionId, ObjectID, ObjectType |Sort-Object DisplayName, RoleDefinitionName
                    build-file -passlist $list -filename $file  -scopetype $selectscope -outputdirectory $outputdirectory
                }
                # gets all User role assignments
                elseif ($groupquestion -eq "All Users")
                {
                    $objecttype = "User"
                    $list = get-azroleassignment  | Where-Object {$_.ObjectType -eq $objecttype -and $_.SignInName -ne $null} 
                    build-file -passlist $list -filename $file -scopetype $selectscope -outputdirectory $outputdirectory
                }
                # gets all ServicePrincipal role assignments
                elseif ($groupquestion -eq "All Service Principals")
                {
                    $objecttype = "ServicePrincipal"
                    $list = get-azroleassignment  | Where-Object {$_.ObjectType -eq $objecttype} 
                    build-file -passlist $list -filename $file  -scopetype $selectscope -outputdirectory $outputdirectory
                }
                # gets all role assignments

                # gets all Identity Unknown role assignments - Either User, Group, SPN was deleted
                elseif ($groupquestion -eq "Identity Unknown")
                {
        
                    $objecttype = "Unknown"
                    
                    $list = get-azroleassignment  | Where-Object {$_.displayname -eq $null -and $_.SignInName -eq $null}
                    build-file -passlist $list -filename $file  -scopetype $selectscope -outputdirectory $outputdirectory
                }

        }
    
    #}
