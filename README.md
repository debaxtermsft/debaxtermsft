- 👋 Hi, I’m @debaxtermsft

These scripts were created for customers to be able to backup all group\groupmemberships and all group\group attributes.

Used with the RBAC export scripts it is possible to rebuild the lost/deleted group, group membership and RBAC roles it may have been assigned (security groups)

The RBAC export also can help if users/groups/service principals are deleted (due to a deleted or moved subscription) having the ability to find and reassign the RBAC roles.

When a security group is deleted it cannot be restored.  Using these scripts it is possible to rebuild that group and assign the RBAC roles (locating the objectid from previous exports)

When a subscription is moved/deleted all RBAC roles will become Identity Unknowns.  

Using a previous export it can now be possible to find that objectid and reassociate / reassign the proper RBAC roles.

AAD Export utility is soon to be uploaded so all lost users/groups/service principals can be assigned the permissions they used to have without having to remember/track down what they used to have.

CLI & UI RBAC export powershell scripts

Used to backup RBAC for all users/groups/service principals

Both will ask to sign in:

CLI will ask for the tenant and subsriptions to export

CLI will ask for the tenantID, then either -AllSubs All (which will iterate through all subscriptions available to the person/spn running the script)  Make sure the user/spn running has reader or greater permissions to view ALL subscriptions or it will not get them.

CLI will ask for the directory (if saving local or to Azure Storage Account) and save the files by tenant+subscriptionid+selection-scope-sorting+date and time.csv

UI will prompt for a directory to save the files.

UI will prompt for multiselect directory(ies), subscription(s), All RBAC, Users, Groups, Service principals, Unknown Identities, then sorting and automatically save like the CLI

tenant+subscriptionid+selection-scope-sorting+date and time.csv

You are then given the options to export

All RBAC – this will export All RBAC assignments in the currently selected Tenant

All Users – All User assignments for the tenant are exported

All Groups – All Group assignments for the tenant are exported

All SPN/apps – All SPN/App assignments for the tenant are exported

All Unknowns – All “Identity Unknowns” for the tenant are exported – very useful if a security group is deleted or if a customer deletes/moves a tenant. 

For users/groups/SPNs that were deleted they will see the Identity Unknown in the Portal or Unknown ObjectType

This option will give an export of all Unknowns with the Object ID.

Using this export along with any previous exports they admin can find the original ObjectID to determine who that user/groups/spn was to rebuild/recreate it.

(Identity Unknown/Object was deleted without removing the Role Assignment) Who/what was it:

Grabbing the Unknown Identity, and a previous exports object ID they can now find everything about that object by searching previous exports and finding the object ID.

CLI & UI Groupmember/Group Attribute export powershell scripts

used for companies to backup their group memberships (assigned or dynamic)/(security/office) 

along with the ability to backup the attributes for rebuilding the groups

Group Members/Group Attributes

Group Members and Group Attributes filter1- All/Assigned/Dynamic

Group Members - All (gets all group members of all Groups)

Group Members - Assigned Filters - All(assigned)/Azure Security/Office Security/Selected Azure Security/Selected Office Security/Selected Office Non-Security

Group Members - Dynamic Filter - All(dynamic)/Azure/Office/Selected Azure/Selected Office

Group Attributes - All (all groups)/Assigned (All assigned group attributes)/ Dynamic (all Dynamic Group Attributes)

CLI File will be saved for MainMenuQuestion +"_"+ $GroupTypeQuestion+"_"+ $SorOQuestion+Date and Time.csv

UI will prompt for group members or group attributes

Select an Option and hit OK ( Cancel from Any option will exit the script)
<!---
debaxtermsft/debaxtermsft is a ✨ special ✨ repository because its `README.md` (this file) appears on your GitHub profile.
You can click the Preview link to take a look at your changes.
--->
