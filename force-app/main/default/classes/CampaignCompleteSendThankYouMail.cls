/**
* @File Name          : CampaignCompleteSendThankYouMail.cls
* @Description        : In this class fetched related lead of Campaign and send an email(SAC-1619)
* @Author             : Manshi Joshi
* @Group              : IBM
*==============================================================================
* Ver         Date                     Author                    Modification
*==============================================================================
* 1.0        26-06-2025                Manshi                   Initial Version
**/
public class CampaignCompleteSendThankYouMail {
    @InvocableMethod
    public static void sendThankYouEmails(List<Id> campaignIds) {
        try{
            if (campaignIds == null || campaignIds.isEmpty()) return;
            
            // Fetch Campaign Owner emails
            Map<Id, Campaign__c> campaignMap = new Map<Id, Campaign__c>([
                SELECT Id, Owner.Email,Owner.Name
                FROM Campaign__c 
                WHERE Id IN :campaignIds
            ]);
            
            // Fetch related Leads
            List<Lead__c> leads = [
                SELECT Id, Name, Email__c, OwnerId, Owner.Name, Owner.Email, Campaign__c 
                FROM Lead__c
                WHERE Campaign__c IN :campaignIds 
                AND Email__c != null 
                AND Owner.Email != null
            ];
            List<Campaign_Lead__c> leads1 = [
                SELECT Id, Name, Lead_Email__c,Lead__r.Owner.Email, Campaign__c 
                FROM Campaign_Lead__c
                WHERE Campaign__c IN :campaignIds 
                AND Lead_Email__c != null 
            ];
            List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
            
            for (Lead__c lead : leads) {
                Campaign__c relatedCampaign = campaignMap.get(lead.Campaign__c);
                
                if (relatedCampaign == null || String.isBlank(lead.Email__c) || String.isBlank(lead.Owner.Email)) {
                    continue;
                }
                // Construct email body
                String emailBody = 'Dear Patron,\n\n' +
                    'I wanted to extend my sincere thanks for taking the time to meet us today. ' +
                    'We greatly value your patronage and appreciate the relationship.\n\n' +
                    'Rest assured, we will work upon the insights you have shared, we are fully committed ' +
                    'to supporting your needs and ensuring that our collaboration continues to be mutually beneficial.\n\n' +
                    'If you have any further questions or require additional information, please reach out to me.\n\n' +
                    'Thank you once again, and we look forward to your continued patronage.\n\n' +
                    'Regards,\n' + relatedCampaign.Owner.Name;
                
                // Build email
                //Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setSubject('Thank You for Meeting Us!');
                mail.setPlainTextBody(emailBody);
                mail.setToAddresses(new List<String>{ lead.Email__c });
                mail.setCcAddresses(new List<String>{ lead.Owner.Email,'customer.connect@safexpress.com' });
                mail.setReplyTo(relatedCampaign.Owner.Email);
                emailsToSend.add(mail);
            }
            for (Campaign_Lead__c lead : leads1) {
                Campaign__c relatedCampaign = campaignMap.get(lead.Campaign__c);
                
                if (relatedCampaign == null || String.isBlank(lead.Lead_Email__c)) {
                    continue;
                }
                // Construct email body
                String emailBody = 'Dear Patron,\n\n' +
                    'I wanted to extend my sincere thanks for taking the time to meet us today. ' +
                    'We greatly value your patronage and appreciate the relationship.\n\n' +
                    'Rest assured, we will work upon the insights you have shared, we are fully committed ' +
                    'to supporting your needs and ensuring that our collaboration continues to be mutually beneficial.\n\n' +
                    'If you have any further questions or require additional information, please reach out to me.\n\n' +
                    'Thank you once again, and we look forward to your continued patronage.\n\n' +
                    'Regards,\n' + relatedCampaign.Owner.Name;
                
                // Build email
                //Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setSubject('Thank You for Meeting Us!');
                mail.setPlainTextBody(emailBody);
                mail.setToAddresses(new List<String>{ lead.Lead_Email__c });
                mail.setCcAddresses(new List<String>{ lead.Lead__r.Owner.Email,'customer.connect@safexpress.com' });
                mail.setReplyTo(relatedCampaign.Owner.Email);
                emailsToSend.add(mail);
            }
            if (!emailsToSend.isEmpty()) {
                Messaging.sendEmail(emailsToSend);
            }
        }
        catch (Exception exp) {
            System.debug('Exception Message ::' + exp.getMessage() + ' Class Name : CampaignCompleteSendThankYouMail at Line ::' + exp.getLineNumber());
        }
    }
}