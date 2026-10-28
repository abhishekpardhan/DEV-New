/**
* Description		: This Queueable is used to merge the contacts.
* Created By       	: KR SANSI - IBM
* Created Date     	: 6th Aug, 2024
* Release          	: 6th Aug, 2024
* Last Modified on 	:
* Jira Ticket      	:  
**/
public class MergeContactQueueable implements Queueable{

    public String email;
    public String mobilePhone; 
    public boolean forNext;
    List<String> emailList;
    List<String> mobilePhoneList;        

    // constructor to initialize the start and end date with true for next iteration
    public MergeContactQueueable(List<String> mobilePhoneList, List<String> emailList, boolean forNext, String mobilePhone, String email){
        this.emailList = emailList;
        this.mobilePhoneList = mobilePhoneList;
        this.forNext = forNext;  
        this.mobilePhone = mobilePhone;
        this.email = email;
    }
     
     
    public void execute(QueueableContext qc){
        
        
        Set<String> fieldApiNameSet = new Set<String>{'MobilePhone', 'FirstName', 'LastName', 'MiddleName', 'Email', 'Designation__c', 'Department', 'Department__c',
                                 'Contact_State__c', 'MailingStreet', 'MailingCity', 'MailingState', 'MailingPostalCode',
                                   'MailingCountry', 'MailingLatitude', 'MailingLongitude','OtherStreet', 'OtherCity', 'OtherState', 'OtherPostalCode',
                                   'OtherCountry', 'OtherLatitude', 'OtherLongitude', 'Address_Type__c', 'Location_Type__c',
                                 'Other_Address_Type__c', 'Pickup_Location__c'};
           
        if(forNext){
            // do nothing, it's for single contact to merge                             
        }else{
            List<AggregateResult> allContacts;
            if(mobilePhoneList.size() > 0){
                allContacts = [SELECT COUNT(Id), MobilePhone, Email FROM Contact
                WHERE MobilePhone IN : this.mobilePhoneList AND Email IN: this.emailList AND
                MobilePhone != null AND Email != null /*AND Is_Active__c = True AND                
                (Opportunity_Name__c = '' OR Opportunity_Name__c = null) AND
                (Lead__c = '' OR Lead__c = null)*/ AND  
                (AccountId = '' OR AccountId = null)                               
                GROUP BY MobilePhone, Email HAVING COUNT(Id) > 1  ];
            }else{
                allContacts = [SELECT COUNT(Id), MobilePhone, Email FROM Contact
                WHERE  
                MobilePhone != null AND Email != null /*AND Is_Active__c = True AND               
                (Opportunity_Name__c = '' OR Opportunity_Name__c = null) AND
                (Lead__c = '' OR Lead__c = null) */AND  
                (AccountId = '' OR AccountId = null)                               
                GROUP BY MobilePhone, Email HAVING COUNT(Id) > 1];
            }
            
            System.debug('allContacts-->'+allContacts); 
            System.debug('allContacts-->'+allContacts.size());
            if(allContacts.size() > 0){    
                AggregateResult contactDetail = allContacts[0];
                this.mobilePhone = String.valueOf(contactDetail.get('MobilePhone'));
                this.email = String.valueOf(contactDetail.get('email'));
            }
        }  
        
        System.debug('this.mobilePhone-->'+this.mobilePhone);
        System.debug('this.email-->'+this.email); 
        if(this.mobilePhone != null && this.email != null){
            List<Contact> mergeContactList = [SELECT Id, MobilePhone, FirstName, LastName, MiddleName, Email, Designation__c, Department, Department__c,
                                        Contact_State__c, Address_Type__c, Location_Type__c,
                                        Other_Address_Type__c, Pickup_Location__c, MailingStreet, MailingCity, MailingState, MailingPostalCode,
                                        MailingCountry, MailingLatitude, MailingLongitude,       
                                        OtherStreet, OtherCity, OtherState, OtherPostalCode,
                                        OtherCountry, OtherLatitude, OtherLongitude
                                    FROM Contact 
                                    WHERE MobilePhone =: this.mobilePhone AND Email =: this.email AND 
                                    MobilePhone != null AND Email != null /*AND Is_Active__c = true AND               
                                    (Opportunity_Name__c = '' OR Opportunity_Name__c = null) AND
                                    (Lead__c = '' OR Lead__c = null) */AND  
                                    (AccountId = '' OR AccountId = null)          
                                    ORDER BY CreatedDate DESC LIMIT 3]; 
            Contact masterContact = mergeContactList[0];
            mergeContactList.remove(0);
            System.debug('masterContact-->'+masterContact);
            
            System.debug('mergeContactList-->'+mergeContactList);
            for(String fieldApiName : fieldApiNameSet){
                if(String.isEmpty(String.valueOf(masterContact.get(fieldApiName))) || fieldApiName == 'Pickup_Location__c'){
                    for(Contact con : mergeContactList){ 
                        
                        if(fieldApiName == 'Pickup_Location__c'){
                            System.debug('masterContact.Pickup_Location__c-->'+masterContact.Pickup_Location__c);
                        	System.debug('con.Pickup_Location__c-->'+con.Pickup_Location__c);
                            if(masterContact.Pickup_Location__c == false && con.Pickup_Location__c == true){
								masterContact.Pickup_Location__c = true;                                
                            }
                        }else if(String.isNotEmpty(String.valueOf(con.get(fieldApiName)))){
                            masterContact.put(fieldApiName, con.get(fieldApiName));
                            break;
                        }
                    }
                }
            }
            
            try {
                if(mergeContactList.size() > 0){
                    TriggerUtility.byPassTrigger = true;
                    update masterContact;
                    merge masterContact mergeContactList;
                }   
                mergeContactList = [SELECT Id FROM Contact 
                                            WHERE MobilePhone =: this.mobilePhone AND 
                                            Email =: this.email AND /*Is_Active__c = true AND 
                                            (Opportunity_Name__c = '' OR Opportunity_Name__c = null) AND
                                            (Lead__c = '' OR Lead__c = null) AND */
                                            (AccountId = '' OR AccountId = null) AND 
                                            Id !=: masterContact.Id]; 
                if(mergeContactList.size() > 0){
                    MergeContactQueueable queueable = new MergeContactQueueable(this.mobilePhoneList, this.emailList, true, this.mobilePhone, this.email);                         
                    System.enqueueJob(queueable);
                }else{
                    MergeContactQueueable queueable = new MergeContactQueueable(this.mobilePhoneList, this.emailList, false, null, null);                          
                    System.enqueueJob(queueable);
                }
            }
            catch (Exception e) {
                // Process exception
                System.debug('An unexpected error has occurred: ' + e.getMessage()); 
            }
        }
    }
}