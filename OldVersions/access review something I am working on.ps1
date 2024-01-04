
$groupselect2 = ($ARDefIDProperties | sort-object -Property displayname | Where-Object {$_.status -eq "Completed"}).id
$groupquestion2 =  select-group -grouptype $groupselect2 -selectType "Select Access Review"  -multivalue $true
if($groupquestion2 -eq "Cancel"){exit}



foreach ($groupselectitem2 in $groupquestion2)
{
    $confirmAR = Get-MgAccessReview -AccessReviewId $groupselectitem2
    $checkRemoveAR = select-group -grouptype $confirmAR.DisplayName -selectType "Select Access Review and OK to Delete" 
    if($checkRemoveAR -eq "Cancel")
    {
        write-host "Cancelled"
        
        
    }
    else 
    {
        write-host "would have deleted " $confirmAR.DisplayName + " ID " + $confirmAR.Id
    }
}