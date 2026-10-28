/**
 * Created by deepaksingh on 01/11/21.
 */

public without sharing class customLookUpController {
    @AuraEnabled(cacheable=true)
    public static List<sObject> search(String searchTerm, String fieldName, string myObject, String filter) {
        String myQuery = null;
        System.debug('myQuery ' + myQuery);
        if (filter != null && filter != '') {
           // myQuery = 'Select Parent.Parent.Name,Parent.ParentId,Parent.Name,Id,Name,RecordTypeId, ' + fieldName + ' from ' + myObject + ' Where ' + fieldName + ' Like  \'%' + searchTerm + '%\' AND ' + filter + ' LIMIT  10';
        } else {
            if (searchTerm == null || searchTerm == '') {
                // myQuery = 'Select Id, '+fieldName+' from ' + myObject + ' Where LastViewedDate != NULL ORDER BY LastViewedDate DESC LIMIT  5';
            } else {
                myQuery = 'Select Parent.Parent.Name,Parent.ParentId,Parent.Name,Id,Name,RecordTypeId, ' + fieldName + ' from ' + myObject + '  Where ' + fieldName + ' Like  \'%' + searchTerm + '%\'' +
                        'OR '+ fieldName + ' Like  \'' + searchTerm + '%\' LIMIT  15'; 
            }
        }
        System.debug('myQuery ' + myQuery);
        List<sObject> lookUpList = database.query(myQuery);
        List<Account> accounts = (List<Account>) lookUpList; // TypeCasting to sObject to Account
        String rateCardRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Rate Card').getRecordTypeId();
        List<Account> accList = new List<Account>();
        for (Account account : accounts) {
            if (account.RecordTypeId == rateCardRecordTypeId) {
                accList.add(account);
            }
        }
        List<sObject> objList = (List<sObject>) accList; 
        return objList;
    }
}