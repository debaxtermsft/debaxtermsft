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
#######################


    param([parameter(mandatory)][validateset("Group Members","Groups Attributes")][string] $mainmenu,
          [parameter(mandatory)][validateset("All","Assigned","Dynamic")] [string]$GroupTypeFilter,
          [parameter(mandatory)][validateset("All","Azure","Office")] [string]$SorOGroup,
          [parameter(mandatory)] [string]$OutputFile)


#remove the rem below and enter the tenant id, and rem the 2nd connect-azaccount
try
    {
    Get-AzureADDomain -ErrorAction Stop > $null
    }
catch
    {
    connect-azuread
    }


   
 


    
    #$MainMenuQuestion  
    #$GroupTypeQuestion
    #$SorOQuestion  

    
    $groupoutput =@()
    $groupquestion =@()
    $grouptype =@()
    $group  =@()
    $groupmembers =@()
    $groupinfo =@()
    $groupinfo2 =@()

    if ($MainMenuQuestion -eq "Group Members")
    {
    write-host "got here" $MainMenuQuestion
        if($GroupTypeQuestion-eq "Dynamic") #all dynamic group members
        {
        write-host "got here " $GroupTypeQuestion
            if($SorOQuestion-eq "Azure")
            {
            $group = get-azureadmsgroup -all $true | 
                ?{($_.grouptypes -contains "DynamicMembership" -and $_.grouptypes -notcontains "Unified" -and $_.securityenabled -eq $true) }| 
                select displayname, id, description | 
                Sort-Object DisplayName
            }
            elseif($SorOQuestion-eq "Office")
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
        write-host "got here assigned"
            if($SorOQuestion -eq "Azure")
            {
            write-host "got here " $GroupTypeQuestion
                $group = get-azureadmsgroup -all $true | 
                    ?{($_.GroupTypes.Count -eq 0 -or $_.grouptypes -notcontains "DynamicMembership"  -and $_.grouptypes -notcontains "Unified") }| 
                    select displayname, id, description | 
                    Sort-Object DisplayName
            }
            elseif($SorOQuestion-eq "Office")
            {
            write-host "got here " $GroupTypeQuestion
                $group = get-azureadmsgroup -all $true | 
                    ?{($_.GroupTypes.Count -eq 0 -or $_.grouptypes -notcontains "DynamicMembership"  -and $_.grouptypes -contains "Unified") }| 
                    select displayname, id, description | 
                    Sort-Object DisplayName
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
        #$file = $MainMenuQuestion +"_"+ $GroupTypeQuestion+"_"+ $SorOQuestion
        #$OutputFile = save-file -filename $file -initialDirectory $env:HOMEDRIVE
        #if ($OutputFile -eq "Cancel"){break}
        $groupoutput |  Out-File -FilePath $outputfile -Encoding utf8 -Force
        #adding info to CSV
        $groupinfo | Out-File -FilePath $outputfile -Encoding utf8 -Append
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
            foreach ($item in $group)
            {

                        $groupinfo2 = $item.DisplayName +","+ $item.Description +"," + $item.Id + ","+ $item.securityenabled+ ","+ $item.IsAssignableToRole + "," +  $item.proxyaddresses + "," +  $item.GroupTypes + "," +  $item.MailEnabled+ "," +  $item.Mail+ "," +  $item.mailnickname+ "," +  $item.AssignedLabels+ "," +  $item.MembershipRule
                        $groupinfo += $groupinfo2
            }
        }
        #creating header for CSV
        $groupoutput = "Group_DisplayName,Group_Description,Id,securityenabled,IsAssignableToRole ,proxyaddresses ,GroupTypes ,MailEnabled,Mail,mailnickname,AssignedLabels,MembershipRule"
        #$file = $MainMenuQuestion +"_"+ $GroupTypeQuestion+"_"+ $SorOQuestion
        #$OutputFile = save-file -filename $file -initialDirectory $env:HOMEDRIVE
        #if ($OutputFile -eq "Cancel"){break}
        $groupoutput |  Out-File -FilePath $outputfile -Encoding utf8 -Force
        #adding info to CSV
        $groupinfo | Out-File -FilePath $outputfile -Encoding utf8 -Append
    }


