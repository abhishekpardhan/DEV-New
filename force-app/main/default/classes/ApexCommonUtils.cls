public without sharing class ApexCommonUtils {
    /**
     * Checks whether the Lead Drop Approval feature is enabled.
     * @return True when the setting exists and Is_active__c is true;
     * otherwise, false.
     */
    public static Boolean isFeatureEnabled() {
        Org_Setting__mdt setting = Org_Setting__mdt.getInstance('Trigger');
        if (setting == null) {
            return false;
        }
        return setting.Is_active__c;
    }
}