param([parameter(Position=0,mandatory)][validateset("All","Group ObjectID")] [string]$GroupOption,
[parameter(Position=1,mandatory=$false)][string]$GroupObjectID,
[parameter(Position=2,mandatory)][validateset("1 Group Attributes","2 Group Members","3 Group Owners", "4 Group Licenses", "5 Group Conditional Access Policies", "6 Group Application Assignments")][string] $exporttype,
[parameter(Position=3,mandatory)][validateset("All","Assigned","Dynamic")] [string]$GroupTypeFilter,
[parameter(Position=4,mandatory)][validateset("All","Azure","Office")] [string]$SecurityorOfficeGroup,
[parameter(Position=5,mandatory)] [string]$Outputdirectory)


[CmdletBinding(DefaultParametersetName='None')] 
param( 

    [Parameter(ParameterSetName='All',Mandatory=$false)][switch]$Favorite,      
    [Parameter(ParameterSetName='All',Mandatory=$true)][string]$FavoriteCar,
    [parameter(ParameterSetName='All',Position=3,mandatory)][validateset("All","Assigned","Dynamic")] [string]$GroupTypeFilter,
[parameter(ParameterSetName='All',Position=4,mandatory)][validateset("All","Azure","Office")] [string]$SecurityorOfficeGroup,

    [Parameter(ParameterSetName='GroupOID',Mandatory=$false)][switch]$Favorite,      
    [Parameter(ParameterSetName='GroupOID',Mandatory=$true)][string]$FavoriteCar,
    
    [parameter(Position=2,mandatory)][validateset("1 Group Attributes","2 Group Members","3 Group Owners", "4 Group Licenses", "5 Group Conditional Access Policies", "6 Group Application Assignments")][string] $exporttype,
    [parameter(Position=5,mandatory)] [string]$Outputdirectory)
)

$ParamSetName = $PsCmdLet.ParameterSetName



#$askforoptions = groupoptions   
groupoptions    
    switch -regex ($GroupOption) 
    {
        "All" 
        {
            $groupid = "all"
            $type = typeexport
            $AorD = allassigneddynamic
            $filename = efn
        }
        "Group ObjectID"
        {
            $groupid = $GroupObjectID
            $type = typeexport
            $filename = efn
        }

    }
    
#}
$tdy = get-date -Format "MM-dd-yyyy hh.mm.ss"
$filename = $GroupOption + "_" + $groupid + "_" + $exporttype + "_" + $GroupTypeFilter + "_" + $SecurityorOfficeGroup +"_" + $tdy+ ".csv" 



write-host "Group Option : " $GroupOption
write-host "Group Objectid : " $groupid
write-host "Group exporttype : " $exporttype
write-host "Group Group Type Filter : " $GroupTypeFilter
write-host "Group Security of Unified : " $SecurityorOfficeGroup
write-host "File Name : " $filename
write-host "OutputDirectory : " $Outputdirectory

#$test = groupoptions -GroupOption 'Group ObjectID' 5f9494a8-3e95-4df4-bb56-d237e5e20cb1