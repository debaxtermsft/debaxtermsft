#find all users in current audit logs
$allusers = get-mgauditlogsignin | sort-object userprincipalname -Unique
#check if the users in the audit logs are equal to users being looked up.

$findsaviors = $allusers | ?{$_.userprincipalname -like "*saviors*"}
$findderrick = $allusers | ?{$_.userprincipalname -like "*derrick*"}
$adusers = get-mguser -all 

Compare-Object -IncludeEqual -ExcludeDifferent $A $B

$SigninLogPropertiestest =@()
foreach($item in $logs)
{
$SigninLogPropertiestest += New-Object Object |
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
                                                $SigninLogPropertiestest | Add-Member -NotePropertyName CA_ConditionsNotSatisfied+$counter -NotePropertyValue $CA_ConditionsNotSatisfied -PassThru 
                                                $SigninLogPropertiestest | Add-Member -NotePropertyName CA_ConditionsSatisfied+$counter -NotePropertyValue $CA_ConditionsSatisfied -PassThru 
                                                $SigninLogPropertiestest | Add-Member -NotePropertyName CA_DisplayName+$counter -NotePropertyValue $CA_DisplayName -PassThru 
                                                $SigninLogPropertiestest | Add-Member -NotePropertyName CA_EnforcedGrantControls+$counter -NotePropertyValue $CA_EnforcedGrantControls -PassThru 
                                                $SigninLogPropertiestest | Add-Member -NotePropertyName CA_EnforcedSessionControls+$counter -NotePropertyValue $CA_EnforcedSessionControls -PassThru 
                                                $SigninLogPropertiestest | Add-Member -NotePropertyName CA_Id+$counter -NotePropertyValue $CA_Id -PassThru 
                                                $SigninLogPropertiestest | Add-Member -NotePropertyName CA_Result+$counter -NotePropertyValue $CA_Result -PassThru
                                                $counter++
                                            }


}