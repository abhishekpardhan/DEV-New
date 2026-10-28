/**
 * Description      :   Helper class for Event_Lead__c object trigger to perform various taks like creating Operational Case, creating Leads if customer type is either credit or Retails etc
 * 
 * 
 * Revision Logs    :   V_1.0 - Created
 * 
 **/
public class EventLeadTriggerHandler{

    /**
     * Method to create the Operational cases under 'NON PRC PICKUP ACCOUNT' if Event_Lead__c's Customer_Type__c is 'Pick up'
     **/
    public static void createCase(List<Event_Lead__c> listLead){
        try{
            List<Case__c> lstCase = new List<Case__c>();
            List<Account> lstAcc= [Select id from ACcount where name =: 'NON PRC PICKUP ACCOUNT' limit 1];
            Id rOperationCase = Schema.SObjectType.case__c.getRecordTypeInfosByName().get('Operation Issues').getRecordTypeId();
            if(lstAcc != null && lstAcc.size() > 0){
                for(Event_Lead__c objLead : listLead){
                    Case__c objcase = new Case__c();
                    objcase.Case_Type__c = 'New Pickup';
                    objcase.Status__c = 'Active';
                    objcase.Email__c = objLead.Email__c;
                    objcase.Phone__c = objLead.Mobile_Phone__c;
                    objcase.Event_Lead__c = objLead.Id;
                    objcase.Name__c = objLead.name;
                    objcase.recordtypeid = rOperationCase;
                    objcase.Account__C = lstAcc[0].Id;
                    objcase.Name__c = objLead.Contact_Person_Name__c;
                    lstCase.add(objcase);
                }
            }
            System.debug('< lstCase > '+lstCase +' ');
            if(lstCase.size() > 0){
                insert lstCase;
                changeConvertedLayout(listLead);
            }
        }catch(Exception e){
            System.debug('++ errorMessage ++ '+e.getMessage());
            System.debug('++ errorMessage ++ '+e.getLineNumber());
        }
    }
    
    /**
     * Method to create the Lead if Event_Lead__c's Customer_Type__c is either Credit or Retails
     **/
    public static void createLead(List<Event_Lead__c> listEventLead){
        try{
            List<Lead__c> lstLead = new List<Lead__c>();
            for(Event_Lead__c objLead : listEventLead){
                Lead__c Id = new Lead__c();
                Id.Name = objLead.name;
                Id.Email__c = objLead.Email__C;
                Id.Source__c = 'Directory';
                Id.City__c = objLead.City__c;
                Id.State__c = objLead.State__c;
                Id.Street__c = objLead.Address__c;
                Id.Zip_Postal_Code__c = objLead.Pin_Code__c;
                Id.Mobile_No__c = objLead.Mobile_Phone__c ;
                Id.Type__c = objLead.Customer_Type__c ;
                Id.Region__c = objLead.Region__c;
                Id.Status__c = 'Active';
                Id.Contact_Person_Name__c = objLead.Contact_Person_Name__c;
                Id.Salutation__c = objLead.Salutation__c;
                Id.Event_Lead__c = objLead.Id;
                lstLead.add(Id);
                
            }
            if(lstLead.size() > 0){
            //insert lstLead; 
                Database.DMLOptions dml = new Database.DMLOptions();
                dml.DuplicateRuleHeader.AllowSave = true;
                Database.SaveResult[] results = Database.insert(lstLead, dml); 
                changeConvertedLayout(listEventLead);
            }
        }catch(Exception e){
            System.debug('++ errorMessage ++ '+e.getMessage());
            System.debug('++ errorMessage ++ '+e.getLineNumber());
        }
    }
    
    
    /**
     * Method to update the Event_Lead__c record type to 'Converted Event Lead'
     **/
    public static void changeConvertedLayout(List<Event_Lead__c> lstEveLead){
        try{    
            Id leadConvertedID = Schema.SObjectType.Event_Lead__c.getRecordTypeInfosByName().get('Converted Event Lead').getRecordTypeId();        
            List<Event_Lead__c> updateEveLead = new List<Event_Lead__c>(); 
            for(Event_Lead__c objEveLead : [Select id, recordtypeId from Event_Lead__c where Id IN : lstEveLead]){
                objEveLead.recordtypeId = leadConvertedID;
                updateEveLead.add(objEveLead);
            }
            if(updateEveLead.size() > 0){
                update updateEveLead;
            }
        }catch(Exception e){
            System.debug('++ errorMessage ++ '+e.getMessage());
            System.debug('++ errorMessage ++ '+e.getLineNumber());
        }
    }
}