/**
 * Description      :   Trigger on User object to create fedration id which needs to be mapped wit AD server for SSO
 * Release          :   17th may, 2021
 * Revision Logs    :   V_1.0 - Created
 * Modified By       :   Abhishek Pardhan Date: 02th feb, 2026 - Updated
**/    
trigger trg_User on User (before insert, before update,after insert, after update) {
    if(Trigger.isBefore) {
        if(Trigger.isUpdate) {
            cls_trgUserHandler.restrictUser(Trigger.New, Trigger.oldMap);
        }
    }

    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            cls_trgUserHandler.amLeadShr(Trigger.newmap, null); // Start RC changes SAC- 97
            cls_trgUserHandler.oppSharingNewUser(Trigger.New);// Added By Adarsh - SAC-166. // End RC changes SAC-97
        }
        if(Trigger.isUpdate) {
            cls_trgUserHandler.amLeadShr(Trigger.newmap, Trigger.oldmap);
            cls_trgUserHandler.oppSharingOldUser(Trigger.New,Trigger.oldMap);// Added By Adarsh - SAC-166
        }

        cls_trgUserHandler.handleUserUpdateAndInsert(
            Trigger.new,
            Trigger.oldMap,
            Trigger.isInsert,
            Trigger.isUpdate
        );

    }
    
}