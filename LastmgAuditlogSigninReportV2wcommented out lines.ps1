<# Created 12/15/2020 
update 6/25/21 - modified search dates to GT and LT and date range search
update 4/11/22 - external user all and domain name searching
update 6/21/22 - made modifications to code
updated 3/28/23 - updated to show CA policies
Script is using 2.0.2.129  AzureADPreview available commands.  please make sure you are using at least this version of azuread
This script also uses many windows forms, boxes, textboxes and selection boxes
This script will launch Microsoft Excel at the end to allow viewing the result
Script creates a csv output of the last recorded signin logs for all Azure AD Users (members and guests) based on the applicatoin below.
The output is based on the last login to any application in Azure available in the range supplied
To get a specific application last signed in
IF using Microsoft Excel, the local time format is m/d/yyyy h:mm:ss AM/PM - you may need to change this column as a custom format 

IMPORTANT!!!

To consent for users to run this script a global admin will need to run the following
-------------------------------------------------------------------------------------------
"AuditLog.Read.All, directory.read.all,Policy.Read.ConditionalAccess"
$sp = get-mgserviceprincipal | ?{$_.displayname -eq "Microsoft Graph"}
$resource = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"
$principalid = "users object id"
$scope1 ="auditlog.read.all"
$scope2 ="directory.read.all"
$scope3 ="Policy.Read.ConditionalAccess"
$today = Get-Date -Format "yyyy-MM-dd"
$expiredate1 = get-date
$expiredate2 = $expiredate1.AddDays(365).ToString("yyyy-MM-dd")
$params = @{
    ClientId = $SP.Id
    ConsentType = "Principal"
    ResourceId = $resource.id
    principalId = $principalid
    Scope = "$scope1" + " " + "$scope2"+ " " + "$scope3"
    startTime = "$today"
    expiryTime = "$expiredate2"
    
}

$InitialConsented = New-MgOauth2PermissionGrant -BodyParameter $params
-------------------------------------------------------------------------------------------
You may need to update the connect-mggraph to have the -environment USGov or as needed -tenantid <tenantid> can be added as needed.



#>


    #clearing variables
    $aduserquestion = @()
    $lastlogin = @()
    $outfile = @()
    $appslist =@()
    $filenamesuffix =@()
    $logs =@()
    #$datetime = Get-Date -UFormat "%m-%d-%Y %T" |  ForEach-Object { $_ -replace ":", "." }


#Function to get and display an array of items sent to it for making a selection
function select-app ($appfilter,$userlist,$audittype,$readcreatefile, $selectType, $appslist, $multivalue, $logoutput, $pickdays)
    {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'select-object ' + $selectType
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


    foreach ($item in $appslist.AppDisplayName)
        {
            [void] $listBox.Items.Add($item)
        }
    foreach ($item in $displayname)
        {
            [void] $listBox.Items.Add($item)
        }
    foreach ($item in $audittype)
        {
            [void] $listBox.Items.Add($item)
        }
    foreach ($item in $userlist)
        {
            [void] $listBox.Items.Add($item)
        }
    foreach ($item in $readcreatefile)
        {
            [void] $listBox.Items.Add($item)
        }
    foreach ($item in $logoutput)
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

#The function get-textbox is used to read in information 
function get-textbox($searchobject, $searchtype, $multivalue)
    {
		Add-Type -AssemblyName System.Windows.Forms
		Add-Type -AssemblyName System.Drawing

		$form = New-Object System.Windows.Forms.Form
		$form.Text = 'Signins Logging Entry Form'
		$form.Size = New-Object System.Drawing.Size(400,300)
		$form.StartPosition = 'CenterScreen'
        $form.Top = $true
		$form.Topmost = $true

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
        $form.s

		$label = New-Object System.Windows.Forms.Label
		$label.Location = New-Object System.Drawing.Point(10,20)
		$label.Size = New-Object System.Drawing.Size(365,20)
		#$label.Text = 'Please enter the information in the space below:'
		$label.Text =  $searchtype
		$form.Controls.Add($label)
		$textBox = New-Object System.Windows.Forms.TextBox
		$textBox.Location = New-Object System.Drawing.Point(10,50)
		$textBox.Size = New-Object System.Drawing.Size(365,20)
		$form.Controls.Add($textBox)

		$form.Add_Shown({$textBox.Select()})
		$result = $form.ShowDialog()

		if ($result -eq [System.Windows.Forms.DialogResult]::OK)
			{
				$x = $textBox.Text
                
				#$x
			}
		elseif ($result -eq [System.Windows.Forms.DialogResult]::Cancel)
			{
			   exit
			}
		return $x
	}  
# end function get-textbox

# function get-filename is used to select-object  a file to open after complete

#open file with excel
Function Get-FileName($initialDirectory, $filename, $OutputFile)
    {
        $Excel = New-Object -ComObject Excel.Application
        $Workbook = $Excel.Workbooks.Open($OutputFile)
        $excel.Visible = $true
        $excel.Top = $true
        

    }
#end function Get-FileName

# function save-file is used to select-object  a directory and filename with a recommended filename prepopulated

Function save-file([string] $initialDirectory, $filename)
    {
        $outputfile = $filename
        $SaveFileDialog = New-Object windows.forms.savefiledialog  
        $SaveFileDialog.FileName = $filename
        $SaveFileDialog.initialDirectory = $initialDirectory
        $SaveFileDialog.title = "Save File to Disk"
        $SaveFileDialog.filter = "AzureADAppsList | AzureADAuditSigninApplicationList*.csv|Comma Seperated File|*.csv | All Files|*.* " 
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
#end function save-file 

# The function error-textbox is used to read in information 

function error-textbox($errormessage, $errortext)
    {
		Add-Type -AssemblyName System.Windows.Forms
		Add-Type -AssemblyName System.Drawing

		$form = New-Object System.Windows.Forms.Form
		$form.Text = $errormessage
		$form.Size = New-Object System.Drawing.Size(400,300)
		$form.StartPosition = 'CenterScreen'

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
		$label.Size = New-Object System.Drawing.Size(365,300)
		#$label.Text = 'Please enter the information in the space below:'
		$label.Text = $errortext
		$form.Controls.Add($label)
		#$textBox = New-Object System.Windows.Forms.TextBox
		#$textBox.Location = New-Object System.Drawing.Point(10,50)
		#$textBox.Size = New-Object System.Drawing.Size(365,20)
		$form.Controls.Add($textBox)
		$form.Topmost = $true
		#$form.Add_Shown({$textBox.Select()})
		$result = $form.ShowDialog()

		if ($result -eq [System.Windows.Forms.DialogResult]::OK)
			{
				$x = $textBox.Text
				#$x
			}
		elseif ($result -eq [System.Windows.Forms.DialogResult]::Cancel)
			{
			   exit
			}
		#return $x
	}
 # end function error-textbox

Function open-FileName($initialDirectory, $filename)
    {  
        [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")|Out-Null
        
        $x=@()
        $form=@()
        $OpenFileDialog =@()
        

        $form = (New-Object System.Windows.Forms.Form -Property @{TopMost = $true; TopLevel = $true})
        $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $OpenFileDialog.FileName = $filename
        $OpenFileDialog.initialDirectory = $initialDirectory
        #$OpenFileDialog.FileName = $filename
        $OpenFileDialog.filter = "Audit Signin Log | *report*.csv|All files (*.*)| *.csv"
        $return = $OpenFileDialog.ShowDialog($form.Select()) 
        

        if($OpenFileDialog.FileName -eq "" ) 
            {
            #   write-host "Its not Null" 
                exit
            } 
        else
            {
                $x = $OpenFileDialog.FileName  
                
            } 
        #$x
        return $x
    }
    #end function Get-FileName

    
    Function Get-Folder($initialDirectory="")
    {
        [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")|Out-Null
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        $foldername = New-Object System.Windows.Forms.FolderBrowserDialog
        $foldername.Description = "select-object  a folder"
        $foldername.rootfolder = "MyComputer"
        $foldername.SelectedPath = $initialDirectory
        $result = $foldername.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true; TopLevel = $true}))

        if ($result -eq [Windows.Forms.DialogResult]::OK)
        {
            $x = $foldername.SelectedPath
        }
        elseif ($result -eq [Windows.Forms.DialogResult]::Cancel)
        {
            Write-Host "File Save Dialog Cancelled!" -ForegroundColor Yellow
            exit
        }
        return $x
    } 
	#end function get-folder 
Function create-object($logs)
{
    $SigninLogProperties1 =@()
    foreach($item in $logs)
    {
        $apaclist = $item.AppliedConditionalAccessPolicies
        
        $locationcity = $item.location.city
        $locationcountryorregion = $item.location.CountryOrRegion
        $locationState = $item.location.State
        $SigninLogProperties1 += New-Object Object |
            Add-Member -NotePropertyName CorrelationID -NotePropertyValue $item.CorrelationID -PassThru |
            Add-Member -NotePropertyName CreatedDateTime -NotePropertyValue $item.CreatedDateTime -PassThru |
            Add-Member -NotePropertyName userprincipalname -NotePropertyValue $item.userprincipalname -PassThru |
            Add-Member -NotePropertyName UserId -NotePropertyValue $item.UserId -PassThru |
            Add-Member -NotePropertyName UserDisplayName -NotePropertyValue $item.UserDisplayName -PassThru |
            Add-Member -NotePropertyName AppDisplayName -NotePropertyValue $item.AppDisplayName -PassThru |
            Add-Member -NotePropertyName AppId -NotePropertyValue $item.AppId -PassThru |
            Add-Member -NotePropertyName IPAddress -NotePropertyValue $item.IPAddress -PassThru |
            Add-Member -NotePropertyName locationcity -NotePropertyValue $locationcity -PassThru |
            Add-Member -NotePropertyName locationcountryorregion -NotePropertyValue $locationcountryorregion -PassThru |
            Add-Member -NotePropertyName locationState -NotePropertyValue $locationState -PassThru
            $counter = 1
            foreach($apac in $apaclist)
            {
                $CA_ConditionsNotSatisfied = $apac.'ConditionsNotSatisfied'
                $CA_ConditionsSatisfied = $apac.'ConditionsSatisfied'
                $CA_DisplayName = $apac.'DisplayName'
                [string]$CA_EnforcedGrantControls = $apac.'EnforcedGrantControls'
                [string]$CA_EnforcedSessionControls = $apac.'EnforcedSessionControls'
                $CA_Id = $apac.'Id'
                $CA_Result = $apac.'Result'
                $SigninLogProperties | Add-Member -NotePropertyName CA_DisplayName_$counter -NotePropertyValue $CA_DisplayName -PassThru
                $SigninLogProperties | Add-Member -NotePropertyName CA_Id_$counter -NotePropertyValue $CA_Id -PassThru 
                $SigninLogProperties | Add-Member -NotePropertyName CA_Result_$counter -NotePropertyValue $CA_Result -PassThru 
                $SigninLogProperties | Add-Member -NotePropertyName CA_ConditionsNotSatisfied_$counter -NotePropertyValue $CA_ConditionsNotSatisfied -PassThru 
                $SigninLogProperties | Add-Member -NotePropertyName CA_ConditionsSatisfied_$counter -NotePropertyValue $CA_ConditionsSatisfied -PassThru 
                $SigninLogProperties | Add-Member -NotePropertyName CA_EnforcedGrantControls_$counter -NotePropertyValue $CA_EnforcedGrantControls -PassThru 
                $SigninLogProperties | Add-Member -NotePropertyName CA_EnforcedSessionControls_$counter -NotePropertyValue $CA_EnforcedSessionControls -PassThru 
                $CA_ConditionsNotSatisfied = @()
                $CA_ConditionsSatisfied = @()
                $CA_DisplayName = @()
                [string]$CA_EnforcedGrantControls = @()
                [string]$CA_EnforcedSessionControls = @()
                $CA_Id = @()
                $CA_Result = @()
                $counter++
            }
            
    }
    return $SigninLogProperties1
}

#Start of script -----------------------------------------------------------------------------------------------------
#logging in

$envtype = @("Global","USGov","USGovDoD","China" )
$envselected =  select-app -audittype $envtype -selectType "Cloud Selection"
switch -regex ($envselected) 
{
    "Cancel" 
    {
        Write-Host "Exiting" 
        exit
    }
    "Global"
    {
        $envselected2 = "Global"
    }
    "USGov"
    {
        $envselected2 = "USGov"
    }
    "USGovDoD"
    {
        $envselected2 = "USGovDod"
    }
    "China"
    {
        $envselected2 = "China"
    }
}
try {
    
    get-mguser -Top 1 -ErrorAction stop >$null
}
catch {
    Connect-MgGraph -scope "AuditLog.Read.All, directory.read.all,Policy.Read.ConditionalAccess" -Environment $envselected2
    Select-MgProfile -Name "beta"
}

	$daterange = $true
    #turn off errors to screen
    $ErrorActionPreference = 'SilentlyContinue'
    $numberofdaysinlogs =@()


        $audittype = @("Enter Log Date Search LT","Enter Log Date Search GT","Enter Log Date Range" )
        $loglookup =  select-app -audittype $audittype -selectType "Date Entry/Lookup" 
# getting date input GT, LT or Date Range lookup
        switch -regex ($loglookup) 
	     {
        "Cancel" 
            {
              Write-Host "Exiting" 
              exit
            }
        "Enter Log Date Range"
            {
                $searchstarttype = "Enter Start Date yyyy-MM-dd"
                $searchendtype = "Enter End Date yyyy-MM-dd"
                do
                {
                $findlogsstart =  get-textbox -searchobject $displayname -searchtype $searchstarttype
                $findlogsend =  get-textbox -searchobject $displayname -searchtype $searchendtype
                $startdatefilter = $findlogsstart
                $stopdatefilter = $findlogsend
                $filtercreatedDateTime = "createdDateTime gt " + $startdatefilter + " and createdDateTime lt " + $findlogsend
				                try
				                {
					                $logs = get-mgauditlogsignin -Filter $filtercreatedDateTime
					                $validdaterange = $false
				                }
			                    Catch
				                {
				                $daterange = $true
				                $errortext = "Error in Date Range"
				                $errortext = error-textbox -errortext $error[0].Exception.Message  -errormessage $errortext
				                #write-host "date range too far back"
				                #write-host $error[0].Exception.Message
				                }

                }
                while($validdaterange)
            
            }
        "Enter Log Date Search LT" 
            {
                $searchtype = "Enter Date yyyy-MM-dd"
                do
                {
                $findlogs =  get-textbox -searchobject $displayname -searchtype $searchtype
                $datefilter = $findlogs
                $filtercreatedDateTime = "createdDateTime lt " + $datefilter
				                try
				                {
					                $logs = get-mgauditlogsignin -Filter $filtercreatedDateTime
					                $validdaterange = $false
				                }
			                    Catch
				                {
				                $daterange = $true
				                $errortext = "Error in Date Range"
				                $errortext = error-textbox -errortext $error[0].Exception.Message  -errormessage $errortext
				                #write-host "date range too far back"
				                #write-host $error[0].Exception.Message
				                }

                }
                while($validdaterange)
            
            }

            
        "Enter Log Date Search GT"
            {
                $searchtype = "Enter Date yyyy-MM-dd"
                do
                {
                $findlogs =  get-textbox -searchobject $displayname -searchtype $searchtype
                $datefilter = $findlogs
                $filtercreatedDateTime = "createdDateTime gt " + $datefilter
				                try
				                {
					                $logs = get-mgauditlogsignin -Filter $filtercreatedDateTime
					                $validdaterange = $false
				                }
			                    Catch
				                {
				                $daterange = $true
				                $errortext = "Error in Date Range"
				                $errortext = error-textbox -errortext $error[0].Exception.Message  -errormessage $errortext
				                #write-host "date range too far back"
				                #write-host $error[0].Exception.Message
				                }

                }
                while($validdaterange)
            
            }
         }


#----------- Prompt for search type 
    #which set of accounts to run the reports against
    #creating array to populate select-app box for report type
    $audittype = @()
    $aduserquestion =@()
    $adusers =@()
    $fileprefix =@()
    $tdy = get-date -Format "MM-dd-yyyy hh.mm.ss"
    $audittype = @("Find Users Object ID by Display Name")
    $audittype += "Enter User by Object ID"
    $audittype += "All Accounts - may take a long time"
    $audittype += "All Accounts Enabled ONLY- may take a long time"
    $audittype += "All Accounts Disabled ONLY- may take a long time"
    $audittype += "All Members - may take a long time"
    $audittype += "All Members Enabled ONLY- may take a long time"
    $audittype += "All Members Disabled ONLY- may take a long time"
    $audittype += "All Guests - may take a long time"
    $audittype += "All Guests Enabled - may take a long time"
    $audittype += "All Guests Disabled- may take a long time"
    $audittype += "All External Users"
    $audittype += "External users by domain name"
    
    $allusersinauditlog = get-mgauditlogsignin | sort-object userprincipalname -Unique
    $aduserquestion =  select-app -audittype $audittype -selectType "Account Filter" 

     switch -regex ($aduserquestion) 
	 {
    "Cancel" 
        {
          Write-Host "Exiting" 
          exit
        }
    "All External Users"
    {
            $adusers = get-mguser -all  | where-object {$_.userprincipalname -like "*#EXT#*"}
            $fileprefix = "All_ExternalAccounts_"+$tdy
    }
    "External users by domain name"
    {
            [string]$findexternaldomain =  get-textbox -searchobject $displayname -searchtype $searchstarttype
            [string]$searchinfo = $findexternaldomain.Replace(' ','')
            [string]$searchinfo2 = "*"+$searchinfo+"#EXT#*"
            
            $adusers = get-mguser -all  | where-object {$_.userprincipalname -like $searchinfo2}
            $fileprefix = "External_Accounts_by_domain_"+$searchinfo+$tdy
    }
    "All Accounts - may take a long time" 
        {
            $adusers = (get-mguser -all ).UserPrincipalName
            $fileprefix = "All_Accounts_"+$tdy
        }

    "All Accounts Enabled ONLY- may take a long time"
        {
            $adusers = (get-mguser -all  |Where-Object {$_.AccountEnabled -eq $true}).UserPrincipalName
            $fileprefix = "All_Enabled_Accounts_"+$tdy
        }
    "All Accounts Disabled ONLY- may take a long time" 
        {
            $adusers = (get-mguser -all  |Where-Object {$_.AccountEnabled -eq $false}).UserPrincipalName
            $fileprefix = "All_Disabled_Accounts_"+$tdy
        }
    "All Members - may take a long time"
        {
            $adusers = (get-mguser -all  |Where-Object {$_.usertype -eq "Member"}).UserPrincipalName
            $fileprefix = "All_Members_"+$tdy
        }
    "All Members Enabled ONLY- may take a long time"
        {
            $adusers = (get-mguser -all  |Where-Object {$_.AccountEnabled -eq $true -and $_.usertype -eq "Member"}).UserPrincipalName
            $fileprefix = "All_Enabled_Members_"+$tdy
        }
    "All Members Disabled ONLY- may take a long time"
        {
            $adusers = (get-mguser -all  |Where-Object {$_.AccountEnabled -eq $false -and $_.usertype -eq "Member"}).UserPrincipalName
            $fileprefix = "All_Disabled_Members_"+$tdy
        }
    "All Guests - may take a long time"
        {
            $adusers = (get-mguser -all  |Where-Object {$_.usertype -eq "Guest"}).UserPrincipalName
            $fileprefix = "All_Guests_"+$tdy
        }
    "All Guests Enabled - may take a long time"
        {
            $adusers = (get-mguser -all  |Where-Object {$_.AccountEnabled -eq $true -and $_.usertype -eq "Guest"}).UserPrincipalName
            $fileprefix = "All_Enabled_Guests_"+$tdy
        }
    "All Guests Disabled- may take a long time"
        {
            $adusers = (get-mguser -all |Where-Object {$_.AccountEnabled -eq $false -and $_.usertype -eq "Guest"}).UserPrincipalName
            $fileprefix = "All_Disabled_Guests_"+$tdy
        }
    "Enter User by Object ID" 
        {
            
            $searchtype = "Object ID (copy from Portal)"

            do
                {
                    $adusersearch =  get-textbox -searchobject $displayname -searchtype $searchtype
                    $adusersearch = $adusersearch[1] -as [string]
                    if ($adusersearch -eq "Cancel"){break}
                    elseif ($adusersearch.Length -eq "0") 
                    {
                        $notfound = $true 
                        $searchtype = "OID Search Failed - Try again"
                    }
                    else
                        {
                                $adusers = (get-mguser -ObjectId $adusersearch).UserPrincipalName
                                if ($adusers.Length -eq 0)
                                { 
                                    $notfound = $true
                                    $searchtype = "Error w OID Failed -Try Again?"
                                }
                                else
                                {
                                    $notfound = $false
                                }
                        }
                }
            
            while ($notfound -eq $true)

            $fileprefix = "FindAccount_by_ObjectID_" +$adusers.ObjectId + "_" + $adusers.DisplayName+$tdy
            break #-remove later if not needed

        }
    "Find Users Object ID by Display Name" 
        {
		#$adusersearch =@()
        $searchtype = "Display Name (start small)"
        $adusers =@()
        do 
            {
                $adusersearch = get-textbox -searchobject $displayname -searchtype $searchtype
                if ($adusersearch -eq "Cancel"){break}
                $adusersearch = $adusersearch[1] -as [string]
                $aduserfind = (get-mguser -all -Filter "startsWith(DisplayName, '$adusersearch')").userprincipalname
        
                    if ($aduserfind.count -ge 1)
                        {
                    
                            $adfounduser = select-app -userlist $aduserfind -selectType "select-object  User to Audit" -multivalue $true
                            $adusers = $adfounduser 
                            $fileprefix = "FindAccount_by_DisplayName_for_" + $adusers.DisplayName +$tdy+".csv"
                            $notfound = $false
                        }
                    else 
                        {
                            write-host $adusersearch " Account Not Found Please try again"
                            $searchtype = "Display Name NOT FOUND- Try again"
                            $notfound = $true
                        }
            }
            while ($notfound)

        }
    }

#-----------END of user type select-object  ($adusers)
#-----------selecting audit by application 

        $SigninLogProperties = @()
        $appfilter =@()
        $appfilter = @("All Apps Last Signin - may take a long time", "App Name")
        $appquestion = select-app -audittype $appfilter -selectType "Application Filter"
        $findusersinauditlog = (Compare-Object -IncludeEqual -ExcludeDifferent $allusersinauditlog.userprincipalname $adusers).inputobject
        
       $lastlogin = @()
        switch -regex ($appquestion) 
		{

        "Cancel" {
              Write-Host "Exiting" 
              exit
            }
            
         "All Apps Last Signin - may take a long time" 
			{
                $lastlogin =@()
                $file = $fileprefix + "_All Applications Report_" + $datetime +".csv"

                
                foreach($user in $findusersinauditlog)
                {
                    #Add rem if you do not want to view work in progress
                    write-host "Checking User : " $user
                    #creating Filter for UserPrincipalName DisplayName String 
                    $filter1 = " and userPrincipalName eq"
                    $filter2 =  $user.ToLower()
                    $filter3 = $filtercreatedDateTime+$filter1 + " '" +$filter2 + "'"
                    $list = get-mgauditlogsignin -filter "$filter3" | Sort-Object appdisplayname | select-object   appdisplayname 
                    $appslist = $list | Get-Unique -AsString                   
                    if($list -ne $null)
                    {
                    #select-object  the application name you would like to have a report on the Last Signin 
                        foreach ($app in $appslist)
                        {
                            #"Creating Application Filter String appDisplayName eq 'Application'"
                            $filter4 = "appDisplayName eq " 
                            $filter5 = $app.AppDisplayName
                            $filter6 = $filter4 + "'" + $filter5 + "'" 
                            $filter7 = " and "
                            $filter8 = $filter3 + $filter7 + $filter6
                                
                            $logs = get-mgauditlogsignin -top 1 -Filter $filter8 

                            if($logs -ne $null)
                                {
                                #remove rem if you want to view users with records in signin logs display (not recorded)
                                write-host "Account " $user " has a Last Signin to       : " $app.AppDisplayName
                                $SigninLogProperties = create-object -logs $logs
                                <#
                                foreach($item in $logs)
                                    {
                                        $apaclist = $item.AppliedConditionalAccessPolicies
                                        
                                        $locationcity = $item.location.city
                                        $locationcountryorregion = $item.location.CountryOrRegion
                                        $locationState = $item.location.State
                                        $SigninLogProperties += New-Object Object |
                                            Add-Member -NotePropertyName CorrelationID -NotePropertyValue $item.CorrelationID -PassThru |
                                            Add-Member -NotePropertyName CreatedDateTime -NotePropertyValue $item.CreatedDateTime -PassThru |
                                            Add-Member -NotePropertyName userprincipalname -NotePropertyValue $item.userprincipalname -PassThru |
                                            Add-Member -NotePropertyName UserId -NotePropertyValue $item.UserId -PassThru |
                                            Add-Member -NotePropertyName UserDisplayName -NotePropertyValue $item.UserDisplayName -PassThru |
                                            Add-Member -NotePropertyName AppDisplayName -NotePropertyValue $item.AppDisplayName -PassThru |
                                            Add-Member -NotePropertyName AppId -NotePropertyValue $item.AppId -PassThru |
                                            Add-Member -NotePropertyName IPAddress -NotePropertyValue $item.IPAddress -PassThru |
                                            Add-Member -NotePropertyName locationcity -NotePropertyValue $locationcity -PassThru |
                                            Add-Member -NotePropertyName locationcountryorregion -NotePropertyValue $locationcountryorregion -PassThru |
                                            Add-Member -NotePropertyName locationState -NotePropertyValue $locationState -PassThru
                                            $counter = 1
                                            foreach($apac in $apaclist)
                                            {
                                                $CA_ConditionsNotSatisfied = $apac.'ConditionsNotSatisfied'
                                                $CA_ConditionsSatisfied = $apac.'ConditionsSatisfied'
                                                $CA_DisplayName = $apac.'DisplayName'
                                                [string]$CA_EnforcedGrantControls = $apac.'EnforcedGrantControls'
                                                [string]$CA_EnforcedSessionControls = $apac.'EnforcedSessionControls'
                                                $CA_Id = $apac.'Id'
                                                $CA_Result = $apac.'Result'
                                                $SigninLogProperties | Add-Member -NotePropertyName CA_DisplayName_$counter -NotePropertyValue $CA_DisplayName -PassThru
                                                $SigninLogProperties | Add-Member -NotePropertyName CA_Id_$counter -NotePropertyValue $CA_Id -PassThru 
                                                $SigninLogProperties | Add-Member -NotePropertyName CA_Result_$counter -NotePropertyValue $CA_Result -PassThru 
                                                $SigninLogProperties | Add-Member -NotePropertyName CA_ConditionsNotSatisfied_$counter -NotePropertyValue $CA_ConditionsNotSatisfied -PassThru 
                                                $SigninLogProperties | Add-Member -NotePropertyName CA_ConditionsSatisfied_$counter -NotePropertyValue $CA_ConditionsSatisfied -PassThru 
                                                $SigninLogProperties | Add-Member -NotePropertyName CA_EnforcedGrantControls_$counter -NotePropertyValue $CA_EnforcedGrantControls -PassThru 
                                                $SigninLogProperties | Add-Member -NotePropertyName CA_EnforcedSessionControls_$counter -NotePropertyValue $CA_EnforcedSessionControls -PassThru 

                                                $counter++
                                            }
                                            
                                    }
                                    #>
                                }
                            else 
                                {
                                #remove rem if you want to view users with no records in signin logs display (not recorded)
                                write-host "Account " $user " has no recorded signins to : " $app.AppDisplayName
                                
                                }
                        
                        }
                    }
                }
                if ($SigninLogProperties.count -ne 0)
                {
                    $OutputFile = save-file -filename $file -initialDirectory $env:HOMEDRIVE
                    if ($OutputFile -eq "Cancel"){exit}
                    $SigninLogProperties | Export-Csv -Path $OutputFile -NoTypeInformation -force 
                }
                else
                {
                    $errortext = "No Records Found - no file created"
				    $errortext = error-textbox -errortext $errortext  -errormessage $errortext
                }
            }

        "select-object  App Name"
            {
                $lastlogin =@()
                $logs =@()
                $appchoice =@()
                $file =@()
                $appslist = get-mgauditlogsignin -all -filter $filtercreatedDateTime | Sort-Object appdisplayname -unique | select-object   appdisplayname  
                #$appslist = $list | Get-Unique -AsString
                $file = $fileprefix + "Find Applications Report_" +$tdy +".csv"
                $appchoice = select-app -appslist $appslist -selectType "Application to Audit" -multivalue $true
                if ($appchoice -eq "Cancel"){exit}
                foreach($user in $findusersinauditlog)
                {
                    #Add rem if you do not want to view work in progress
                    write-host "Checking User : " $user
                    #creating Filter for UserPrincipalName DisplayName String 
                    $filter1 = " and userPrincipalName eq"
                    $filter2 = $user.ToLower()
                    $filter3 = $filter1 + " '" +$filter2 + "'"

                    #select-object  the application name you would like to have a report on the Last Signin 
                    foreach ($app in $appchoice)
                    {
                        #"Creating Application Filter String appDisplayName eq 'Application'"
                        $filter4 = "appDisplayName eq " 
                        $filter5 = $app
                        $filter6 = $filter4 + "'" + $filter5 + "'" 
                        $filter7 = " and "
                        $filter8 = $filtercreatedDateTime+$filter3 + $filter7 + $filter6

                        $logs = get-mgauditlogsignin -top 1 -Filter $filter8 
                        if($logs.count -ne 0)
                            {
                            #remove rem if you want to view users with records in signin logs display (not recorded)
                            write-host "Account " $user " has a Last Signin to       : " $app
                            
                            $SigninLogProperties = create-object -logs $logs
                            <#
                            foreach($item in $logs)
                            {
                                $apaclist = $item.AppliedConditionalAccessPolicies
                                $locationcity = $item.location.city
                                $locationcountryorregion = $item.location.CountryOrRegion
                                $locationState = $item.location.State
                                $SigninLogProperties += New-Object Object |
                                    Add-Member -NotePropertyName CorrelationID -NotePropertyValue $item.CorrelationID -PassThru |
                                    Add-Member -NotePropertyName CreatedDateTime -NotePropertyValue $item.CreatedDateTime -PassThru |
                                    Add-Member -NotePropertyName userprincipalname -NotePropertyValue $item.userprincipalname -PassThru |
                                    Add-Member -NotePropertyName UserId -NotePropertyValue $item.UserId -PassThru |
                                    Add-Member -NotePropertyName UserDisplayName -NotePropertyValue $item.UserDisplayName -PassThru |
                                    Add-Member -NotePropertyName AppDisplayName -NotePropertyValue $item.AppDisplayName -PassThru |
                                    Add-Member -NotePropertyName AppId -NotePropertyValue $item.AppId -PassThru |
                                    Add-Member -NotePropertyName IPAddress -NotePropertyValue $item.IPAddress -PassThru |
                                    Add-Member -NotePropertyName locationcity -NotePropertyValue $locationcity -PassThru |
                                    Add-Member -NotePropertyName locationcountryorregion -NotePropertyValue $locationcountryorregion -PassThru |
                                    Add-Member -NotePropertyName locationState -NotePropertyValue $locationState -PassThru 
                                    
                                    $counter = 1
                                    foreach($apac in $apaclist)
                                    {
                                        $CA_ConditionsNotSatisfied = $apac.'ConditionsNotSatisfied'
                                        $CA_ConditionsSatisfied = $apac.'ConditionsSatisfied'
                                        $CA_DisplayName = $apac.'DisplayName'
                                        [string]$CA_EnforcedGrantControls = $apac.'EnforcedGrantControls'
                                        [string]$CA_EnforcedSessionControls = $apac.'EnforcedSessionControls'
                                        $CA_Id = $apac.'Id'
                                        $CA_Result = $apac.'Result'
                                        $SigninLogProperties | Add-Member -NotePropertyName CA_DisplayName_$counter -NotePropertyValue $CA_DisplayName -PassThru
                                        $SigninLogProperties | Add-Member -NotePropertyName CA_Id_$counter -NotePropertyValue $CA_DisplayName -PassThru 
                                        $SigninLogProperties | Add-Member -NotePropertyName CA_Result_$counter -NotePropertyValue $CA_Result -PassThru 
                                        $SigninLogProperties | Add-Member -NotePropertyName CA_ConditionsNotSatisfied_$counter -NotePropertyValue $CA_ConditionsNotSatisfied -PassThru 
                                        $SigninLogProperties | Add-Member -NotePropertyName CA_ConditionsSatisfied_$counter -NotePropertyValue $CA_ConditionsSatisfied -PassThru 
                                        $SigninLogProperties | Add-Member -NotePropertyName CA_EnforcedGrantControls_$counter -NotePropertyValue $CA_EnforcedGrantControls -PassThru 
                                        $SigninLogProperties | Add-Member -NotePropertyName CA_EnforcedSessionControls_$counter -NotePropertyValue $CA_EnforcedSessionControls -PassThru 

                                        $counter++
                                    }
                            }
                            #>
                            #$lastlogin | Export-Csv -Path $OutputFile -NoTypeInformation -force 
                            }
                        else 
                            {
                            #remove rem if you want to view users with no records in signin logs display (not recorded)
                            write-host "Account " $user " has no recorded signins to : " $app
                            
                            }
                    }
                }
                if ($SigninLogProperties.count -ne 0)
                {
                    $OutputFile = save-file -filename $file -initialDirectory $env:HOMEDRIVE
                    if ($OutputFile -eq "Cancel"){exit}
                    $SigninLogProperties | Export-Csv -Path $OutputFile -NoTypeInformation -force 
                }
                else
                {
                    $errortext = "No Records Found - no file created"
				    $errortext = error-textbox -errortext $errortext  -errormessage $errortext
                }
                #break
            }
        }
    #open the file in excel?
    $errortext = error-textbox -errortext "Open in Excel OK button to continue"  -errormessage "Open in Excel"
    if($errortext -eq "Cancel")
    {
        break
    }
    else
    {
        #$openfile = open-FileName -filename $Outputfile
        $getfile =  Get-FileName -OutputFile $OutputFile
        if($getfile -eq "Cancel"){break}
        $excel.quit()

    }
$excel.quit()
$ErrorActionPreference = 'Continue'