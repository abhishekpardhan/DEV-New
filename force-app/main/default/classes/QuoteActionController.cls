//Controller class for NewQuoteCreationAction Component to defer the existing code and create new active quote
// Last Modified By Abhishek on 09/03/26
public class QuoteActionController {
    
    //Method to update the Quote as deferred and updtaing the respective opportunity as Closed Lost
    @AuraEnabled
    public static String closequote(Id qid, Date deferredTill){
        try{
            if(qid != null){
                
                Quote__c qt = [select id,name,approval_status__c,Opportunity__c from quote__c where id=: qid limit 1];
                if(qt != null){                    
                    qt.Status__c = 'Deferred';
                    qt.recordtypeid = Schema.SObjectType.Quote__c.getRecordTypeInfosByName().get('Deferred Recordtype').getRecordTypeId();
                    update qt;
                }
                if(qt.Opportunity__c != null){                    
                    Opportunity__c opp = [select id,Existing_Customer_Details__c,name,Stage__c,Lost_Reason__c,If_Other_Please_Specify__c from opportunity__c where id =: qt.Opportunity__c limit 1];                    
                    opp.Stage__c = 'Passive';
                    opp.Passive_Till__c = deferredTill;
                    opp.ValidationBypassDateTime__c = System.now();                 
                    update opp;
                }
                
            }
        }catch(Exception e){
            system.debug('Exception:'+e.getMessage());
            return 'Exception:'+e.getMessage();
        }
        return 'Success';
    }
    
    //Method to defer the existing code and creating new quote as active
    @AuraEnabled
    public static String createnewquotee(Id qid,String defferedReason,String quoteName, String subReason){
        try{
            Id rId = Schema.SObjectType.Quote__c.getRecordTypeInfosByName().get('Deferred Recordtype').getRecordTypeId();
            Id rNewId = Schema.SObjectType.Quote__c.getRecordTypeInfosByName().get('New Quote').getRecordTypeId();
            if(qid != null){                
                Quote__c qt = [select id,name,approval_status__c,Opportunity__c,Sub_Reason__c,Deffered_Reason__c from quote__c where id =: qid limit 1];
                quote__c qtc = new quote__c();
                if(qt != null){
                    qt.Deffered_Reason__c = DefferedReason;
                    qt.Status__c = 'Deferred';
                    qt.recordtypeid = rId;
                    qt.Sub_Reason__c = subReason;
                    update qt;                    
                    qtc.Name = quoteName;
                    qtc.Opportunity__c = qt.Opportunity__c;
                    qtc.Status__c = 'Active';
                    qtc.recordtypeid = rNewId;                    
                    insert qtc;                    
                    
                }
                return qtc.Id;
            }
            else{
                return 'Id is Null';
            }
            
        }catch(Exception e){
            system.debug('Exception:'+e.getMessage());
            return 'Exception:'+e.getMessage();
        }
    } 
    
    //Method to get 'Lost_Reason__c' picklist field values
    /*@AuraEnabled
    public static List<string> getLostReason(){
        List<String> lstReason = new List<String>();
        try{
            Schema.DescribeFieldResult fieldResult = Opportunity__c.Lost_Reason__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for( Schema.PicklistEntry f : ple)
            {
                lstReason.add(f.getValue());
            } 
            
        }catch(Exception e){
            system.debug('Exception:'+e.getMessage());
        }
        return lstReason;
    }*/
    
    //Method to get 'Deffered_Reason__c' picklist field values
    @AuraEnabled
    public static List<string> getDefferedReason(){
        List<String> lstReason = new List<String>();
        try{
            Schema.DescribeFieldResult fieldResult = Quote__c.Deffered_Reason__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for( Schema.PicklistEntry f : ple)
            {
                lstReason.add(f.getValue());
            } 
        }catch(Exception e){
            system.debug('Exception:'+e.getMessage());
        }
        return lstReason;
    }
}