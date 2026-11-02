/**
* @File Name          : LeadDuplicateServiceTest.cls
* @Description        : Test class for LeadDuplicateService (EPIC4_UST6)
*                       Runs as dedicated test users:
*                         - Normal user  : no exemption -> duplicate PAN is blocked
*                         - Exempt user  : has LEAD_DUPLICATE_EXEMPTION -> check is bypassed
*                       Both users get PSG_TerritoryManager + a test-only field-access permission set.
*==============================================================================
* Ver         Date                     Author                    Modification
*==============================================================================
* 1.0        26-10-2026                Aakash Kumar                   Initial Version
* 1.1        27-10-2026                Vishal Kumar                   @TestSetup, runAs users, PSG_TerritoryManager
**/
@IsTest
private class LeadDuplicateServiceTest {

    // Change to the profile your real Lead users have, if different
    private static final String PROFILE_NAME = 'Standard User';

    // Permission set assigned to real Lead users
    private static final String PERM_SET_NAME = 'PSG_TerritoryManager';

    private static final String NORMAL_ALIAS = 'ldnorm';
    private static final String EXEMPT_ALIAS = 'ldexmp';

    private static final String LEAD_PAN    = 'ABCDE1234F';   // existing Lead PAN
    private static final String ACCOUNT_PAN = 'KLMNO9012P';   // existing Account PAN
    private static final String UPDATE_PAN  = 'PQRST3456U';   // Lead used for update tests
    private static final String UNIQUE_PAN  = 'ZZZZZ9999Z';   // never duplicated

    private static Integer leadCounter = 0;

    // ---------------------------------------------------------------------
    // Setup
    // ---------------------------------------------------------------------
    @TestSetup
    static void setupData() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Profile userProfile = [SELECT Id FROM Profile WHERE Name = :PROFILE_NAME LIMIT 1];

            User normalUser = buildUser(userProfile.Id, NORMAL_ALIAS);
            User exemptUser = buildUser(userProfile.Id, EXEMPT_ALIAS);
            insert new List<User>{ normalUser, exemptUser };
            PermissionSet territoryManagerPs = [SELECT Id FROM PermissionSet
                                                WHERE Name = :PERM_SET_NAME LIMIT 1];
            PermissionSet fieldAccessPs = new PermissionSet(
                Name  = 'LeadDupTest_FieldAccess',
                Label = 'LeadDupTest Field Access'
            );
            insert fieldAccessPs;
            grantObjectAndFieldAccess(fieldAccessPs.Id, new List<Schema.SObjectType>{
                Lead.SObjectType,
                Account.SObjectType,
                Integration_Transaction__c.SObjectType
            });

            List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>{
                new PermissionSetAssignment(AssigneeId = normalUser.Id, PermissionSetId = territoryManagerPs.Id),
                new PermissionSetAssignment(AssigneeId = exemptUser.Id, PermissionSetId = territoryManagerPs.Id),
                new PermissionSetAssignment(AssigneeId = normalUser.Id, PermissionSetId = fieldAccessPs.Id),
                new PermissionSetAssignment(AssigneeId = exemptUser.Id, PermissionSetId = fieldAccessPs.Id)
            };

            // 2. Exemption permission set (custom permission) -> exempt user only
            List<CustomPermission> exemptionPerms = [SELECT Id FROM CustomPermission
                                                     WHERE DeveloperName = :ConstantUtility.LEAD_DUPLICATE_EXEMPTION LIMIT 1];
            if (!exemptionPerms.isEmpty()) {
                PermissionSet exemptionPs = new PermissionSet(
                    Name  = 'LeadDupTest_Exemption',
                    Label = 'LeadDupTest Exemption'
                );
                insert exemptionPs;
                insert new SetupEntityAccess(ParentId = exemptionPs.Id, SetupEntityId = exemptionPerms[0].Id);
                assignments.add(new PermissionSetAssignment(AssigneeId = exemptUser.Id, PermissionSetId = exemptionPs.Id));
            }
            insert assignments;
        }

        // Business data - inserted as the normal test user so triggers / queueables
        // run with the same permissions as in the test methods
        System.runAs(getUser(NORMAL_ALIAS)) {
            List<Lead> leads = new List<Lead>{
                createLead('Existing Lead', LEAD_PAN),
                createLead('Update Lead', UPDATE_PAN)
            };
            Database.insert(leads, getDmlOptions(true));
            Database.insert(createAccount(ACCOUNT_PAN), getDmlOptions(true));
        }
    }

    // ---------------------------------------------------------------------
    // User / permission helpers
    // ---------------------------------------------------------------------
    private static User buildUser(Id profileId, String alias) {
        String uniqueKey = alias + String.valueOf(Crypto.getRandomInteger()).replace('-', '');
        User u = new User(
            FirstName         = 'LeadDup',
            LastName          = alias,
            Alias             = alias,
            Email             = uniqueKey + '@test.sfx.com',
            Username          = uniqueKey + '@test.sfx.com.leaddup',
            ProfileId         = profileId,
            TimeZoneSidKey    = 'Asia/Kolkata',
            LocaleSidKey      = 'en_IN',
            EmailEncodingKey  = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        populateRequiredUserFields(u);
        return u;
    }

    /**
     * Org-specific required User fields. For picklists, the preferred value is used
     * if active, otherwise the default / first active value.
     */
    private static void populateRequiredUserFields(User u) {
        Map<String, String> preferredValues = new Map<String, String>{
            'Region__c'          => 'CORPORATE OFFICE',
            'Journey_Type__c'    => 'Car',
            'Sportfire_Group__c' => 'Group 1',
            'Type__c'            => 'Global'
        };
        Map<String, Schema.SObjectField> userFields = Schema.SObjectType.User.fields.getMap();

        for (String fieldName : preferredValues.keySet()) {
            Schema.SObjectField field = userFields.get(fieldName.toLowerCase());
            if (field == null) {
                continue;
            }
            Schema.DescribeFieldResult dfr = field.getDescribe();
            String preferred = preferredValues.get(fieldName);
            Schema.DisplayType fieldType = dfr.getType();

            if (fieldType == Schema.DisplayType.PICKLIST || fieldType == Schema.DisplayType.MULTIPICKLIST) {
                String chosen;
                String defaultValue;
                String firstActive;
                for (Schema.PicklistEntry entry : dfr.getPicklistValues()) {
                    if (!entry.isActive()) {
                        continue;
                    }
                    if (firstActive == null) {
                        firstActive = entry.getValue();
                    }
                    if (entry.isDefaultValue()) {
                        defaultValue = entry.getValue();
                    }
                    if (entry.getValue().equalsIgnoreCase(preferred) || entry.getLabel().equalsIgnoreCase(preferred)) {
                        chosen = entry.getValue();
                    }
                }
                if (chosen == null) {
                    chosen = defaultValue != null ? defaultValue : firstActive;
                }
                if (chosen != null) {
                    u.put(fieldName, chosen);
                }
            } else if (fieldType == Schema.DisplayType.STRING || fieldType == Schema.DisplayType.TEXTAREA) {
                u.put(fieldName, preferred);
            }
        }
    }

    /**
     * Grants object CRUD and read/edit on every permissionable field (standard + custom)
     * of the given objects. Fields that can't be granted are skipped (allOrNone = false).
     */
    private static void grantObjectAndFieldAccess(Id permSetId, List<Schema.SObjectType> objectTypes) {
        List<ObjectPermissions> objectPerms = new List<ObjectPermissions>();
        List<FieldPermissions> fieldPerms = new List<FieldPermissions>();

        for (Schema.SObjectType objType : objectTypes) {
            String objName = objType.getDescribe().getName();
            objectPerms.add(new ObjectPermissions(
                ParentId                    = permSetId,
                SobjectType                 = objName,
                PermissionsRead             = true,
                PermissionsCreate           = true,
                PermissionsEdit             = true,
                PermissionsDelete           = false,
                PermissionsViewAllRecords   = false,
                PermissionsModifyAllRecords = false
            ));

            for (Schema.SObjectField field : objType.getDescribe().fields.getMap().values()) {
                Schema.DescribeFieldResult dfr = field.getDescribe();
                if (!dfr.isPermissionable()) {
                    continue;
                }
                fieldPerms.add(new FieldPermissions(
                    ParentId        = permSetId,
                    SobjectType     = objName,
                    Field           = objName + '.' + dfr.getName(),
                    PermissionsRead = true,
                    PermissionsEdit = dfr.isUpdateable() && !dfr.isCalculated()
                ));
            }
        }
        Database.insert(objectPerms, false);
        Database.insert(fieldPerms, false);
    }

    private static User getUser(String alias) {
        return [SELECT Id FROM User WHERE Alias = :alias AND LastName = :alias LIMIT 1];
    }

    // ---------------------------------------------------------------------
    // Data helpers
    // ---------------------------------------------------------------------

    /** GST = 2-digit state code + PAN + entity no + 'Z' + check digit */
    private static String buildGst(String stateCode, String pan) {
        return stateCode + pan.trim().toUpperCase() + '1Z5';
    }

    /** Unique Email / Phone / Company per Lead so standard duplicate rules don't fire */
    private static Lead createLead(String lastName, String pan) {
        leadCounter++;
        String suffix = String.valueOf(leadCounter) + String.valueOf(Crypto.getRandomInteger()).replace('-', '');
        return new Lead(
            LastName      = lastName + ' ' + leadCounter,
            Company       = 'Test Company ' + suffix,
            PAN_Number__c = pan,
            GST_Number__c = String.isBlank(pan) ? null : buildGst('07', pan),
            MobilePhone   = '98' + String.valueOf(10000000 + leadCounter),
            Email         = 'lead' + suffix + '@testmail.com',
            Street        = 'Test Street',
            City          = 'Test City',
            State         = 'Test State',
            PostalCode    = '283992'
        );
    }

    private static Account createAccount(String pan) {
        Map<String, Schema.RecordTypeInfo> rtInfos =
            Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();
        Schema.RecordTypeInfo rt = rtInfos.containsKey(ConstantUtility.PROSPECT_CUSTOMER_RT)
            ? rtInfos.get(ConstantUtility.PROSPECT_CUSTOMER_RT)
            : rtInfos.get(ConstantUtility.SFX_CUSTOMER_RT);
        System.assertNotEquals(null, rt, 'A supported Account record type must exist.');

        return new Account(
            Name         = 'PAN Duplicate Test Account',
            Pan_No__c    = pan,
            RecordTypeId = rt.getRecordTypeId()
        );
    }
    
    @IsTest
    static void testUpdateWithGstChange() {
        Lead candidateLead = [SELECT Id FROM Lead WHERE PAN_Number__c = :UPDATE_PAN LIMIT 1];
        candidateLead.PAN_Number__c = LEAD_PAN;
        candidateLead.GST_Number__c = buildGst('06', LEAD_PAN);
        Database.SaveResult result;
        System.runAs(getUser(NORMAL_ALIAS)) {
            result = Database.update(candidateLead, getDmlOptions(false));
        }
        System.assert(!result.isSuccess(), 'Changing GST should invoke duplicate validation when PAN matches another Lead.');
    }
    private static Database.DMLOptions getDmlOptions(Boolean allOrNone) {
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true;
        dml.OptAllOrNone = allOrNone;
        return dml;
    }

    private static Boolean hasDuplicateError(Database.SaveResult result) {
        for (Database.Error err : result.getErrors()) {
            if (err.getMessage().contains(ConstantUtility.DUPLICATE_MESSAGE_PREFIX)) {
                return true;
            }
        }
        return false;
    }

    private static String errorsToString(Database.SaveResult result) {
        List<String> messages = new List<String>();
        for (Database.Error err : result.getErrors()) {
            messages.add(err.getMessage());
        }
        return String.join(messages, ' | ');
    }
    @IsTest
    static void testBlankPan() {
        Database.SaveResult result;
        System.runAs(getUser(NORMAL_ALIAS)) {
            result = Database.insert(createLead('Blank PAN', null), getDmlOptions(false));
        }
        System.assert(!hasDuplicateError(result),
            'Blank PAN should not trigger PAN duplicate validation. Errors: ' + errorsToString(result));
    }

    @IsTest
    static void testDuplicatePanAgainstAccount() {
        Database.SaveResult result;
        System.runAs(getUser(NORMAL_ALIAS)) {
            result = Database.insert(createLead('Account Duplicate Lead', ACCOUNT_PAN), getDmlOptions(false));
        }
        System.assert(!result.isSuccess(), 'A Lead should be rejected when its PAN matches an eligible Account.');
    }
    
    @IsTest
    static void testUpdateWithoutGstChange() {
        Lead candidateLead = [SELECT Id FROM Lead WHERE PAN_Number__c = :UPDATE_PAN LIMIT 1];
        candidateLead.City = 'Updated City';
        Database.SaveResult result;
        System.runAs(getUser(NORMAL_ALIAS)) {
            result = Database.update(candidateLead, getDmlOptions(false));
        }
        System.assert(!hasDuplicateError(result),
            'Update without GST change should not run duplicate validation. Errors: ' + errorsToString(result));
    }

}