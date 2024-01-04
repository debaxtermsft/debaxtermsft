
$numberofauthmethodsfound = $queryreturned.value.count
$AuthMethodObject =@()

$AuthMethodObject += New-Object Object |
Add-Member -NotePropertyName Id -NotePropertyValue $useritem.id -PassThru |
Add-Member -NotePropertyName DisplayName -NotePropertyValue $useritem.displayname -PassThru |
Add-Member -NotePropertyName UserPrincipalName -NotePropertyValue $useritem.UserprincipalName -PassThru 
$counter = 0
$returneditem =@()
$var1s = @()
$kar1s = @()
$vsitem = @()
$ksitem = @()
$newqr = $queryreturned.value
foreach($returneditem in $queryreturned.value)
{
    #$counter
    #$returneditem.keys[$counter]

    $var1s =  $returneditem.values#[$counter]
    $kar1s =  $returneditem.keys#[$counter] 
    #$var1s
    #$kar1s
    foreach ($ksitem in $kar1s){write-host "ksitem" $ksitem}#{write-host $ksitem "here"}
    foreach ($vsitem in $var1s){write-host "vsitem" $vsitem}#{if($vsitem -like "*microsoft.graph*"){write-host $vsitem "microsoft.graph"}else{write-host $vsitem "property "}}
}

$1st = $queryreturned.value[0]  
$2nd = $queryreturned.value[1]
$3rd = $queryreturned.value[2]

$counter = 0
foreach ($3rditem in $3rd.values) 
    { 
        $k = $3rditem.keys[$counter]
        $v = $3rditem.values[$counter]
        if($3rd.values[$counter] -like "*microsoftAuthenticator*")
        {
            write-host "microsoft authenticator" 
            write-host $k
            write-host $v
        }
        $counter++
    }