$ErrorActionPreference='Stop'
$out=$PSScriptRoot
function Query($name,$soql,$tooling=$false){
    $args=@('data','query','--target-org','Dev1','--query',$soql,'--json')
    if($tooling){$args+='--use-tooling-api'}
    $raw=& sf @args
    $raw | Out-File -Encoding utf8 "$out/$name.json"
    $data=$raw | ConvertFrom-Json
    if($data.status -ne 0){throw "$name : $($data.message)"}
    if(!$data.result.done){throw "Incomplete query: $name"}
    Write-Output "$name : $($data.result.totalSize) records"
    return ,$data.result.records
}
$org=Query 'organization' 'SELECT Id, Name, IsSandbox FROM Organization'
$orgRecord=@($org | Where-Object {$_.Id})
if($orgRecord.Count -ne 1 -or $orgRecord[0].Id -cne '00DC1000005VGonMAG' -or !$orgRecord[0].IsSandbox){throw 'Unexpected org identity'}
$null=Query 'groups' "SELECT Id, DeveloperName, Name, Type, DoesIncludeBosses FROM Group WHERE Type='Regular' AND (DeveloperName LIKE 'SG_RGN_%' OR DeveloperName LIKE 'VH_%' OR DeveloperName IN ('Safexperience_Team','Alliance_Partner_Management'))"
$null=Query 'members' "SELECT Id, GroupId, Group.DeveloperName, UserOrGroupId FROM GroupMember WHERE GroupId IN (SELECT Id FROM Group WHERE Type='Regular' AND (DeveloperName LIKE 'SG_RGN_%' OR DeveloperName LIKE 'VH_%' OR DeveloperName IN ('Safexperience_Team','Alliance_Partner_Management')))"
$null=Query 'roles' "SELECT Id, Name, DeveloperName, ParentRoleId FROM UserRole"
$null=Query 'role-groups' "SELECT Id, Type, RelatedId, DeveloperName, Name FROM Group WHERE Type IN ('Role','RoleAndSubordinates','RoleAndSubordinatesInternal')"
$null=Query 'lead-owd' "SELECT QualifiedApiName, InternalSharingModel, ExternalSharingModel FROM EntityDefinition WHERE QualifiedApiName='Lead'" $true
$null=Query 'lead-object-permissions' "SELECT ParentId, Parent.Name, Parent.Label, Parent.IsOwnedByProfile, PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete, PermissionsViewAllRecords, PermissionsModifyAllRecords FROM ObjectPermissions WHERE SobjectType='Lead'"
$null=Query 'lead-record-types' "SELECT Id, DeveloperName, Name, IsActive FROM RecordType WHERE SobjectType='Lead'"
$null=Query 'lead-triggers' "SELECT Id, Name, Status FROM ApexTrigger WHERE TableEnumOrId='Lead'" $true
$null=Query 'lead-app' "SELECT DurableId, DeveloperName, Label FROM AppDefinition WHERE DeveloperName='safexpress2_0'"
Write-Output 'Read-only queries completed. No org mutations.'
