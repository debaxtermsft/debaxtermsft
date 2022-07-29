- 👋 Hi, I’m @debaxtermsft

These scripts were created for customers to be able to backup all AAD Roles, RBAC Roles, and group\groupmemberships and all group\group attributes.

Used with the AAD and RBAC export scripts it is possible to rebuild the lost/deleted group, group membership, AAD Roles and RBAC roles it may have been assigned (security groups)

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

Group Attributes – Group Attributes needed to rebuild an Assigned or Dynamic Group (w Rule), mailnickname, security, isassignable (to aad role)

Group Attributes - All (all groups)

Group Attributes – Assigned (All assigned group attributes)

Group Attributes - Dynamic (all Dynamic Group Attributes)

Group Members – Exports all Groups Group Members and Group Name

Group Members – Select All (exports all groups members for all group in the currently signed into tenant)

Group Members - Assigned - All(exports all assigned group members)

Group Members – Assigned - Azure Security (only All exports Assigned Azure Security Group Members)

Group Members – Assigned - Office Security (exports All Assigned Unified/Office Security Group Members)

Group Members – Assigned -Selected Azure Security (Lets you select which Assigned Azure Security Group to export Members)

Group Members – Assigned -Selected Office Security (Lets you select which Assigned Office/Unified Security Group to export Members)

Group Members – Assigned -Selected Office Non-Security (Lets you select which Assigned Office/Unified Group to export Members)

Group Members – Dynamic - Filter - All(dynamic)/Azure/Office/Selected Azure/Selected Office (although dynamic groups do not need to have members imported later, the export can help a customer determine if users that are in or should not be in the group)

Group Members – Dynamic – All Dynamic Group Members

Group Members – Dynamic – Azure – All Azure Dynamic Group Members

Group Members – Dynamic – Office – All Office/Unified Dynamic Group Members

Group Members – Dynamic – Selected Azure (lets you select which dynamic azure group to export members)

Group Members – Dynamic – Selected Office/Unified (lets you select which dynamic office/unified group to export members)

Group Owners – Gets the group(s) owner(s)

Group Owners – All (all group owners in all groups)

Group Owners – Selected (select the group(s) you want owner

Group Licenses – Exports the Group ObjectID, Group Displayname, License SKU and SKUPartName (E5, EMS, AAD P1, etc), and disabled Plan ID and disabled plan Name (very helpful when rebuilding a group)

Group Licenses - All (gets all groups with licenses)

Group Licenses - Selected (Select the group(s) with Licenses to export

Group Conditional Access Policies – Locates all CAs and exports the included and excluded groups (very helpful if a device security group is deleted with a CA to let users signin, use MFA, etc, which apps may be blocked/granted, etc…

Groups in Applications – exports all application with Groups assigned

CLI File will be saved for MainMenuQuestion +"_"+ $GroupTypeQuestion+"_"+ $SorOQuestion+Date and Time.csv

UI will prompt for group members or group attributes

Select an Option and hit OK ( Cancel from Any option will exit the script)
<!---
debaxtermsft/debaxtermsft is a ✨ special ✨ repository because its `README.md` (this file) appears on your GitHub profile.
You can click the Preview link to take a look at your changes.
--->
