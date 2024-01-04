get-date 
$logNI = get-mgauditLogSignIn -all -Filter "createdDateTime ge $startDate  " | Where-Object{$_.SignInEventTypes -like "nonInteractiveUser"}| sort-object CreatedDateTime 
get-date

$logsfilter = get-mgauditLogSignIn -all -Filter "createdDateTime ge $startDate and signInEventTypes/any(t: t eq 'nonInteractiveUser') " | sort-object CreatedDateTime

get-date