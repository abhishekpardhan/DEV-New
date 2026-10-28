/**
 * Description		:		An apex class to send the attached file (On Quote) to customer
 * Release			:		July 17, 2019
 * JIRA Ticket		:		https://safexpress.atlassian.net/browse/SD-394
 * Coverage			:		82%
 **/
public without sharing class QuoteSendToCustomer{
    
    //Method to send the quote to customer via email along with attached files
    @AuraEnabled
    public static String sendEmail(Id qId ,String listQuoteWrapper){        
        String errorMessage = '';
        if(qId != null){    
            try{
				List<QuoteSendToCustomerWrapper> lstQuoteSendToCustomerWrapper = (List<QuoteSendToCustomerWrapper>) System.JSON.deserialize(listQuoteWrapper,List<QuoteSendToCustomerWrapper>.class);            
                System.debug('<< lstQuoteSendToCustomerWrapper +++ '+lstQuoteSendToCustomerWrapper);
                List<Quote__c> lstQuote = [Select id ,name ,Opportunity__r.id,Approval_Status__c from Quote__c where ID =: qId limit 1];                
                List<Opportunity__c> lstOpp = [Select id,OwnerId from Opportunity__c where Id  =: lstQuote[0].Opportunity__r.id limit 1];                 
                EmailTemplate templateId = [Select id,developername from EmailTemplate where developername = 'Quote_Send_To_Customer' limit 1];
                User us = [Select Id ,email from User where Id =: lstOpp[0].OwnerId limit 1];
				List<String> toAddresses = new List<String>(); 
                List<String> ccAddress = new List<String>(); 
				ccAddress.add(us.email);
                for (QuoteSendToCustomerWrapper objQuoteWrapper : lstQuoteSendToCustomerWrapper){
                    if(objQuoteWrapper.isSelected){
                        if(objQuoteWrapper.typeId == 'To'){
                            toAddresses.add(objQuoteWrapper.objContact.Email);
                        }else{
                            ccAddress.add(objQuoteWrapper.objContact.Email);
                        }
                    }
				}
                System.debug('++toAddresses ++ '+toAddresses);
                System.debug('++ccAddress ++ '+ccAddress);
				List<ContentDocumentLink> lstConDocLink = [SELECT ContentDocument.Id,ContentDocument.FileType ,ContentDocument.createdDate , ContentDocument.FileExtension FROM ContentDocumentLink WHERE LinkedEntityId =: qId and ContentDocument.FileExtension='pdf' order by ContentDocument.createdDate Desc]; //Monika limit 1
                
                List<ContentVersion> lstContentversion = new List<ContentVersion>{};
                System.debug('++lstConDocLink ++ '+lstConDocLink); //Monika
				if(lstConDocLink!=null && lstConDocLink.size() > 0){
                    lstContentversion.add([SELECT Id, Title, FileType, FileExtension, VersionData, isLatest, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId =: lstConDocLink[0].ContentDocument.Id ]);                        
                   // lstContentversion.add([SELECT Id, Title, FileType, FileExtension, VersionData, isLatest, ContentDocumentId FROM ContentVersion WHERE ContentDocumentId =: lstConDocLink[1].ContentDocument.Id ]); //Monika   
                	System.debug('++lstContentversion ++ '+lstContentversion); //Monika
                    List<Messaging.Emailfileattachment> lstEmailAttch = new List<Messaging.Emailfileattachment>();
					List<OrgWideEmailAddress> owa = [select id from OrgWideEmailAddress where Address =: System.Label.SendQuoteSenderEmailId limit 1];
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage(); 
                    Messaging.Emailfileattachment emilAttch = new Messaging.Emailfileattachment();
                   // Messaging.Emailfileattachment emilAttch1 = new Messaging.Emailfileattachment();
					emilAttch.setFileName(lstContentversion[0].title);
                   // emilAttch1.setFileName(lstContentversion[1].title); //Monika
					emilAttch.setContentType('application/pdf');
                   // emilAttch1.setContentType('application/pdf');//monika
					emilAttch.setBody(lstContentversion[0].VersionData);
					//emilAttch1.setBody(lstContentversion[1].VersionData);//Monika
					lstEmailAttch.add(emilAttch);
                   // lstEmailAttch.add(emilAttch1);//Monika

                	System.debug('++emilAttch ++ '+emilAttch); //Monika
                   //System.debug('++emilAttch1 ++ '+emilAttch1); //Monika

                    					
					if(templateId != null){
						email.setTemplateId(templateId.Id);
					}      
					email.setTargetObjectId(lstQuoteSendToCustomerWrapper[0].objContact.Id);
                    System.debug('++lstQuoteSendToCustomerWrapper[0] ++ '+lstQuoteSendToCustomerWrapper);
					boolean treatAsRecipient = false;
					email.setTreatTargetObjectAsRecipient(treatAsRecipient);
					email.setToAddresses(toAddresses );
                    // email.setEntityAttachments(new List<Id>{lstContentversion[0].Id});		//Added this line and commented below line
                    system.debug('lstContentversion[0]'+ lstContentversion[0].Id);
                   // system.debug('lstContentversion[0]'+ lstContentversion[1].Id);
                    email.setFileAttachments(lstEmailAttch);
                    email.setWhatId(lstOpp[0].Id);
					email.setCcAddresses(ccAddress);
                    system.debug('owa'+ owa);
                    if(owa.size() > 0){
                        email.setOrgWideEmailAddressId(owa[0].Id);
                    }
					email.setSaveAsActivity(false);
                    System.debug('<< email >> '+email);
					Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});                       
				}else{
					errorMessage = 'No Attachment';
					return errorMessage;
				}   
                lstQuote[0].Status__c = 'Sent to Customer';
                if(!lstQuote.isEmpty()){
                    update lstQuote;
                }
                return (String)qId;
            }catch(Exception e){
                errorMessage = 'Exception '+e.getMessage();
                return errorMessage;
            }
        }else{
            return null;    
        }
    }
    
    //Method to get the current approval status of Quote
    @AuraEnabled
    public static Quote__c checkQuoteStatus(Id quoteId){

		Quote__c q = [select id,Approval_Status__c, Opportunity__c,status__c from quote__c where id =: quoteId limit 1];
	
		return q;

    }
    
    //Method to query the contacts under the Quote's Opportunity
	@AuraEnabled
    public static List<QuoteSendToCustomerWrapper> getContacts(Id quoteId){
		List<Id> conIdList = new List<Id>();
        List<Contact> conList = new List<Contact>();//added by adarsh //referring - https://safexpress.atlassian.net/browse/SAC-133
		List<quote__c> lstQuo = [select id,Approval_Status__c, Opportunity__c,status__c from quote__c where id =: quoteId limit 1];
		List<QuoteSendToCustomerWrapper> lstCustomerWrapper = new List<QuoteSendToCustomerWrapper>();
		QuoteSendToCustomerWrapper objQuoteSendToCustomerWrapper = null;
        QuoteSendToCustomerWrapper objQuoteSendToCustomerWrapper1 = null;
        //added by adarsh Line 121-131
    	//referring - https://safexpress.atlassian.net/browse/SAC-133
        if(lstQuo[0].Opportunity__c != null){
            List<Opportunity_Contact__c> oppConList = [Select Id,Opportunity__c, Contact__c,Proposal_Send__c, CreatedDate From Opportunity_Contact__c Where Proposal_Send__c = true And Opportunity__c  =: lstQuo[0].Opportunity__c And name != 'INTEGRATION OPPORTUNITY'];//Adarsh
            if(!oppConList.isEmpty()){
                for(Opportunity_Contact__c oppCon : oppConList ){
                    conIdList.add(oppCon.Contact__c);
                } 
            }
        }
        if(!conIdList.isEmpty()){
            conList = [Select Id, Email, Name, Designation__c, Department__c From Contact Where Id IN : conIdList];//Adarsh
        }
		//List<Opportunity__c> lstOpp = [Select id,(Select id ,Email ,name,Designation__c,Department__c from Contacts__r where email != null and Proposal_Send__c = true) from Opportunity__c where Id  =: lstQuo[0].Opportunity__c limit 1];  //commented by adarsh due to flow changed from contact to opportunity contact.
        List<Opportunity__c> lstOppINT = [Select id,(Select id ,Email ,name,Designation__c,Department__c from Contacts__r where email != null and Proposal_Send__c = true) from Opportunity__c where name  ='INTEGRATION OPPORTUNITY']; //Monika
        
        for(Contact objCon : conList){ //Adarsh //https://safexpress.atlassian.net/browse/SAC-133
			objQuoteSendToCustomerWrapper = new QuoteSendToCustomerWrapper(objCon);
			lstCustomerWrapper.add(objQuoteSendToCustomerWrapper);
		} 
        for(Contact intcontact : lstOppINT[0].Contacts__r){ //Monika
				objQuoteSendToCustomerWrapper1 = new QuoteSendToCustomerWrapper(intcontact);//Monika
                 lstCustomerWrapper.add(objQuoteSendToCustomerWrapper1);//Monika
                }//Monika
		return lstCustomerWrapper;
		
    }
    
    //Wrapper class
    public class QuoteSendToCustomerWrapper{

        @AuraEnabled public Contact objContact;
        @AuraEnabled public String typeId;
        @AuraEnabled public boolean isSelected;
        
        public QuoteSendToCustomerWrapper(Contact con ){ 
            objContact = con;
            isSelected = false;
            typeId = 'To';
        }
    }
}