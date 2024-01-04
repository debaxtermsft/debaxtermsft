

$graphuserlist = get-mguser -top 2 | select userprincipalname 
$counter = 0
foreach($item in $graphuserlist) {
    $counter = 999
    $usersignin = get-mgauditlogsignin -top 1 -filter "createddatetime ge 2023-03-01 and userprincipalname eq '$item'"

    if($usersignin -ne $null) {write-host "there is a log for " $item }
    else
    {
        write-host " no log into Azure apps for " $item
    }
    $counter++
    if($counter -eq 999)
    {
    start-sleep 1
    $counter = 0
    }
}