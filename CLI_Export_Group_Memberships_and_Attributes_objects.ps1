#######################
# Written by Derrick Baxter debaxter@microsoft.com
#the below script uses the AZ powershell module pulling all roleassignments for groups
#
# 2/24/2022
#debaxter@microsoft.com
#complete rewrite
# Group Members/Group Attributes
# Group Members and Group Attributes filter1- All/Assigned/Dynamic
# Group Members - All (gets all group members of all Groups)
# Group Members - Assigned Filters - All(assigned)/Azure/Office
# Group Members - Dynamic Filter - All(dynamic)/Azure/Office
# Group Attributes - All (all groups)/Assigned (All assigned group attributes)/ Dynamic (all Dynamic Group Attributes)
#Using Powershell AzureADPreview version 2.0.138.0
#CLI Version
# updated 3/2/22 using objects over arrays
#######################


    param([parameter(mandatory)][validateset("Group Members","Groups Attributes")][string] $mainmenu,
          [parameter(mandatory)][validateset("All","Assigned","Dynamic")] [string]$GroupTypeFilter,
          [parameter(mandatory)][validateset("All","Azure","Office")] [string]$SecurityofOfficeGroup,
          [parameter(mandatory)] [string]$Outputdirectory)


#remove the rem below and enter the tenant id, and rem the 2nd connect-azaccount
try
    {
    Get-AzureADDomain -ErrorAction Stop > $null
    }
catch
    {
    connect-azuread
    }

    
    $groupoutput =@()
    $groupquestion =@()
    $grouptype =@()
    $group  =@()
    $groupmembers =@()
    $groupinfo =@()
    $groupinfo2 =@()

    if ($MainMenuQuestion -eq "Group Members")
    {
        if($GroupTypeQuestion-eq "Dynamic") #all dynamic group members
        {
            if($SorOQuestion-eq "Azure")
            {
            $group = get-azureadmsgroup -all $true | 
                ?{($_.grouptypes -contains "DynamicMembership" -and $_.grouptypes -notcontains "Unified" -and $_.securityenabled -eq $true) }| 
                select displayname, id, description | 
                Sort-Object DisplayName
            }
            elseif($SecurityofOfficeGroup-eq "Office")
            {and I
            $group = get-azureadmsgroup -all $true | 
                ?{($_.grouptypes -contains "DynamicMembership" -and $_.grouptypes -contains "Unified"-and $_.securityenabled -eq $true) }| 
                select displayname, id, description | 
                Sort-Object DisplayName
            }

            else
            {
            $group = get-azureadmsgroup -all $true | 
                select displayname, id, description | 
                Sort-Object DisplayName
            }
        }
        elseif($GroupTypeQuestion -eq "Assigned") #all assigned group members
        {
            if($SorOQuestion -eq "Azure")
            {
                $group = get-azureadmsgroup -all $true | 
                    ?{($_.GroupTypes.Count -eq 0 -or $_.grouptypes -notcontains "DynamicMembership"  -and $_.grouptypes -notcontains "Unified") }| 
                    select displayname, id, description | 
                    Sort-Object DisplayName
            }
            elseif($SecurityofOfficeGroup-eq "Office")
            {
                $group = get-azureadmsgroup -all $true | 
                    ?{($_.GroupTypes.Count -eq 0 -or $_.grouptypes -notcontains "DynamicMembership"  -and $_.grouptypes -contains "Unified") }| 
                    select displayname, id, description | 
                    Sort-Object DisplayName
            }

            else
            {
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
    
        $GMs=@()
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
                       foreach ($listitem in $findgroupmembers )
                       {
                        $GMs += New-Object Object |
                                        Add-Member -NotePropertyName GroupDisplayName -NotePropertyValue $item.DisplayName -PassThru |
                                        Add-Member -NotePropertyName GroupDescription -NotePropertyValue $item.Description -PassThru |
                                        Add-Member -NotePropertyName GroupID -NotePropertyValue $item.Id -PassThru |
                                        Add-Member -NotePropertyName MemberDisplayName -NotePropertyValue $listitem.displayName -PassThru |
                                        Add-Member -NotePropertyName MemberObjectID -NotePropertyValue $listitem.objectid -PassThru |
                                        Add-Member -NotePropertyName MemberUPN -NotePropertyValue $listitem.userprincipalname -PassThru |
                                        Add-Member -NotePropertyName MemberUserType -NotePropertyValue $listitem.UserType -PassThru |
                                        Add-Member -NotePropertyName MemberObjectType -NotePropertyValue $listitem.objecttype -PassThru
                        }
                }
            }
        
        $tdy = get-date -Format "MM-dd-yyyy hh.mm.ss"
        $file = $outputdirectory + $mainmenu +"_"+ $GroupTypeFilter+"_"+ $SecurityofOfficeGroup+$tdy+".csv"
        $GMs| export-csv -Path $file -NoTypeInformation -Encoding utf8 -Force
    }
    else #  Group attributes ($MainMenuQuestion -eq "Group Attributes") #used to backup all information about a group needed to recreate assigned group, especially dynamic security groups w rule
    {
        if($GroupTypeQuestion-eq "Dynamic")
        {
                $group = get-azureadmsgroup -all $true |
                ?{$_.grouptypes -contains "DynamicMembership"}|
                select displayname,description, id, securityenabled, IsAssignableToRole, proxyaddresses, GroupTypes,  MailEnabled, Mail, mailnickname,AssignedLabels, MembershipRule |
                Sort-Object DisplayName

        }
        elseif($GroupTypeQuestion-eq "Assigned")
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
                    $GAs=@()
                       foreach ($item in $group )
                       {
                        $GAs += New-Object Object |
                                        Add-Member -NotePropertyName Group_DisplayName -NotePropertyValue $item.DisplayName -PassThru |
                                        Add-Member -NotePropertyName Group_Description -NotePropertyValue $item.Description -PassThru |
                                        Add-Member -NotePropertyName GroupID -NotePropertyValue $item.Id -PassThru |
                                        Add-Member -NotePropertyName securityenabled -NotePropertyValue $item.securityenabled -PassThru |
                                        Add-Member -NotePropertyName IsAssignableToRole -NotePropertyValue $item.IsAssignableToRole -PassThru |
                                        Add-Member -NotePropertyName proxyaddresses -NotePropertyValue $item.proxyaddresses -PassThru |
                                        Add-Member -NotePropertyName GroupTypes -NotePropertyValue $item.GroupTypes -PassThru |
                                        Add-Member -NotePropertyName MailEnabled -NotePropertyValue $item.MailEnabled -PassThru |
                                        Add-Member -NotePropertyName Mail -NotePropertyValue $item.Mail -PassThru |
                                        Add-Member -NotePropertyName mailnickname -NotePropertyValue $item.mailnickname -PassThru |
                                        Add-Member -NotePropertyName AssignedLabels -NotePropertyValue $item.AssignedLabels -PassThru |
                                        Add-Member -NotePropertyName MembershipRule -NotePropertyValue $item.MembershipRule -PassThru
                        }            

        $tdy = get-date -Format "MM-dd-yyyy hh.mm.ss"
        $file = $outputdirectory + $mainmenu +"_"+ $GroupTypeFilter+"_"+ $SecurityofOfficeGroup+$tdy+".csv"
        $GAs| export-csv -Path $file -NoTypeInformation -Encoding utf8 -Force
    }


