#######################
# Written by Derrick Baxter debaxter@microsoft.com
# the below script uses the Graph powershell module pulling all roleassignments for groups
#
# debaxter
# complete rewrite for Azure Graph
# Group Members/Group Attributes
# Group Members and Group Attributes filter1- All/Assigned/Dynamic
# Group Members - All (gets all group members of all Groups)
# Group Members - Assigned Filters - All(assigned)/Azure/Office
# Group Members - Dynamic Filter - All(dynamic)/Azure/Office
# Group Attributes - All (all groups)/Assigned (All assigned group attributes)/ Dynamic (all Dynamic Group Attributes)
#Using Powershell Graph version
#CLI Version
# updated 5/12/22 using objects over arrays
# Group Attribute example
#  .\AzureGroupExport-MGGraph_CLI.ps1 -mainmenu 'Group Members' -GroupTypeFilter All -SecurityofOfficeGroup All -Outputdirectory "c:\temp\"
#  .\AzureGroupExport-MGGraph_CLI.ps1 -mainmenu 'Group Members' -GroupTypeFilter Assigned -SecurityofOfficeGroup Azure -Outputdirectory "c:\temp\"
# Group Members examples
#  .\AzureGroupExport-MGGraph_CLI.ps1 -mainmenu 'Group Attributes' -GroupTypeFilter All -SecurityofOfficeGroup All -Outputdirectory "c:\temp\"
# .\AzureGroupExport-MGGraph_CLI.ps1 -mainmenu 'Group Attributes' -GroupTypeFilter Dynamic -SecurityofOfficeGroup Office -Outputdirectory "c:\temp\"
#######################


    param([parameter(mandatory)][validateset("Group Members","Groups Attributes")][string] $mainmenu,
          [parameter(mandatory)][validateset("All","Assigned","Dynamic")] [string]$GroupTypeFilter,
          [parameter(mandatory)][validateset("All","Azure","Office")] [string]$SecurityofOfficeGroup,
          [parameter(mandatory)] [string]$Outputdirectory)


#remove the rem below and enter the tenant id, and rem the 2nd connect-azaccount
try
    {
    Get-MGDomain -ErrorAction Stop > $null
    }
catch
    {
    Connect-MgGraph -Scopes "group.read.all, directory.read.all, group.readwrite.all, groupmember.read.all, groupmember.readwrite.all"
    Select-MgProfile -Name "beta"
    }

    

    $group  =@()
    $groupinfo =@()
    $groupinfo2 =@()
    $GMs =@()
    if ($mainmenu -eq "Group Members")
    {
        if( $GroupTypeFilter -eq "Dynamic") #all dynamic group members
        {
            if($SecurityofOfficeGroup -eq "Azure")
            {
            $group = get-mggroup -all | 
                Where-Object{($_.grouptypes -contains "DynamicMembership" -and $_.grouptypes -notcontains "Unified" -and $_.securityenabled -eq $true) }| 
                Select-Object displayname, id, description | 
                Sort-Object DisplayName
            }
            elseif($SecurityofOfficeGroup -eq "Office")
            {and I
            $group = get-mggroup -all | 
                Where-Object{($_.grouptypes -contains "DynamicMembership" -and $_.grouptypes -contains "Unified"-and $_.securityenabled -eq $true) }| 
                Select-Object displayname, id, description | 
                Sort-Object DisplayName
            }

            else
            {
            $group = get-mggroup -all | 
                Select-Object displayname, id, description | 
                Sort-Object DisplayName
            }
        }
        elseif($GroupTypeFilter -eq "Assigned") #all assigned group members
        {
            if($SecurityofOfficeGroup -eq "Azure")
            {
                $group = get-MGgroup -all  | 
                    Where-Object{($_.GroupTypes.Count -eq 0 -or $_.grouptypes -notcontains "DynamicMembership"  -and $_.grouptypes -notcontains "Unified") }| 
                    Select-Object displayname, id, description | 
                    Sort-Object DisplayName
            }
            elseif($SecurityofOfficeGroup -eq "Office")
            {
                $group = get-MGgroup -all  | 
                    Where-Object{($_.GroupTypes.Count -eq 0 -or $_.grouptypes -notcontains "DynamicMembership"  -and $_.grouptypes -contains "Unified") }| 
                    Select-Object displayname, id, description | 
                    Sort-Object DisplayName
            }

            else
            {
                $group = get-MGgroup -all  | 
                    Where-Object{($_.GroupTypes.Count -eq 0 -or $_.grouptypes -notcontains "DynamicMembership") }| 
                    Sort-Object DisplayName
             }

        }
        else # must be All group members
        {
                $group = get-MGgroup -all  | 
                    Select-Object displayname, id, description | 
                    Sort-Object DisplayName
        }
    
        $zero =@()
        foreach ($thing in $group)
        {
        
            $mggroup = Get-MgGroupMember -GroupId  $thing.id
            if($mggroup.Count -ne 0) 
            {
                foreach ($groupmember1 in $mggroup)
                {
                    $zero = $groupmember1.additionalproperties.values[0]
                    #$zero
                    if ($zero -match "graph.group")
                    {
                        $groupinfo = get-mggroup -GroupId $groupmember1.Id
                                $GMs += New-Object Object |
                                    Add-Member -NotePropertyName GroupDisplayName -NotePropertyValue $thing.DisplayName -PassThru |
                                    Add-Member -NotePropertyName GroupDescription -NotePropertyValue $thing.Description -PassThru |
                                    Add-Member -NotePropertyName GroupID -NotePropertyValue $thing.Id -PassThru |
                                    Add-Member -NotePropertyName MemberDisplayName -NotePropertyValue $groupinfo.displayName -PassThru |
                                    Add-Member -NotePropertyName MemberID -NotePropertyValue $groupinfo.id -PassThru |
                                    Add-Member -NotePropertyName MemberObjectType -NotePropertyValue "Group" -PassThru
                    }
        
                    elseif ($zero -match "graph.user")
                    {
                        $groupuser = get-mguser -UserId $groupmember1.Id
                                $GMs += New-Object Object |
                                        Add-Member -NotePropertyName GroupDisplayName -NotePropertyValue $thing.DisplayName -PassThru |
                                        Add-Member -NotePropertyName GroupDescription -NotePropertyValue $thing.Description -PassThru |
                                        Add-Member -NotePropertyName GroupID -NotePropertyValue $thing.Id -PassThru |
                                        Add-Member -NotePropertyName MemberDisplayName -NotePropertyValue $groupuser.DisplayName -PassThru |
                                        Add-Member -NotePropertyName MemberID -NotePropertyValue $groupuser.Id -PassThru |
                                        Add-Member -NotePropertyName MemberObjectType -NotePropertyValue "User" -PassThru
                    }
                    elseif ($zero -match "graph.device")
                    {
                    $devid = $groupmember1.Id
                        $groupuser = get-mgdevice -Filter "Id eq '$devid'" 
                                $GMs += New-Object Object |
                                        Add-Member -NotePropertyName GroupDisplayName -NotePropertyValue $thing.DisplayName -PassThru |
                                        Add-Member -NotePropertyName GroupDescription -NotePropertyValue $thing.Description -PassThru |
                                        Add-Member -NotePropertyName GroupID -NotePropertyValue $thing.Id -PassThru |
                                        Add-Member -NotePropertyName MemberDisplayName -NotePropertyValue $groupuser.displayName -PassThru |
                                        Add-Member -NotePropertyName MemberID -NotePropertyValue $groupuser.id -PassThru |
                                        Add-Member -NotePropertyName MemberObjectType -NotePropertyValue "Device" -PassThru
                    }
                    else
                    {
                        $groupuser = Get-MgServicePrincipal -ServicePrincipalId $groupmember1.id
                                $GMs += New-Object Object |
                                        Add-Member -NotePropertyName GroupDisplayName -NotePropertyValue $thing.DisplayName -PassThru |
                                        Add-Member -NotePropertyName GroupDescription -NotePropertyValue $thing.Description -PassThru |
                                        Add-Member -NotePropertyName GroupID -NotePropertyValue $thing.Id -PassThru |
                                        Add-Member -NotePropertyName MemberDisplayName -NotePropertyValue $groupuser.displayName -PassThru |
                                        Add-Member -NotePropertyName MemberID -NotePropertyValue $groupuser.Appid -PassThru |
                                        Add-Member -NotePropertyName MemberObjectType -NotePropertyValue "ServicePrincipal" -PassThru
        
                    }
                }
            }
        }
        
        $tdy = get-date -Format "MM-dd-yyyy hh.mm.ss"
        $file = $outputdirectory + $mainmenu +"_"+ $GroupTypeFilter+"_"+ $SecurityofOfficeGroup+$tdy+".csv"
        $GMs| export-csv -Path $file -NoTypeInformation -Encoding utf8 -Force
    }
    else #  Group attributes ($MainMenuQuestion -eq "Group Attributes") #used to backup all information about a group needed to recreate assigned group, especially dynamic security groups w rule
    {
        if($GroupTypeFilter -eq "Dynamic")
        {
                $group = get-MGgroup -all  |
                Where-Object{$_.grouptypes -contains "DynamicMembership"}|
                Select-Object displayname,description, id, securityenabled, IsAssignableToRole, proxyaddresses, GroupTypes,  MailEnabled, Mail, mailnickname,AssignedLabels, MembershipRule |
                Sort-Object DisplayName

        }
        elseif($GroupTypeFilter -eq "Assigned")
        {
                $group = get-MGgroup -all  |
                Where-Object{$_.grouptypes -notcontains "DynamicMembership"}|
                Select-Object displayname,description, id, securityenabled, IsAssignableToRole, proxyaddresses, GroupTypes,  MailEnabled, Mail, mailnickname,AssignedLabels, MembershipRule |
                Sort-Object DisplayName
            
        }

        else # condition for all Group Attributes, all a&d and all s/o
        { 
            $group = get-MGgroup -all  |
                Select-Object displayname,description, id, securityenabled, IsAssignableToRole, proxyaddresses, GroupTypes,  MailEnabled, Mail, mailnickname,AssignedLabels, MembershipRule |
                Sort-Object DisplayName 
        }
        if ($group -eq 0)
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

        $tdy = get-date -Format "MM-dd-yyyy hh.mm.ss"
        $file = $outputdirectory + $mainmenu +"_"+ $GroupTypeFilter+"_"+ $SecurityofOfficeGroup+$tdy+".csv"
        $GAs| export-csv -Path $file -NoTypeInformation -Encoding utf8 -Force
        }
    }

