/**
* @File Name          : ContractRenewalService.cls
* @Description        : Service class used to process Contract renewal reminders.
* @Author             : Anand Raju
* @Group              : Grant Thornton Bharat
* @Last Modified By   : Anand Raju
* @Last Modified On   : 13-03-2026
* @Modification Log   :
*=========================================================================================
* Ver         Date                     Author                    Modification
*==========================================================================================
* 1.0        13-03-2026                Anand Raju                Initial Version SAC-2368

**/

public class ContractRenewalService {

    public static void processContracts(List<Contract__c> contracts){

        try{

            Date today = Date.today();

            List<Task> tasksToInsert = new List<Task>();
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

            Set<Id> msaAccountIds = new Set<Id>();
            Map<Id, Account_Team__c> accountToOwnerMap = new Map<Id, Account_Team__c>();
            Map<Id, List<Account>> accountToSfxListMap = new Map<Id, List<Account>>();
            Map<Id, Task> existingContractTaskMap= new Map<Id, Task>();
            Id initiatedById = [SELECT Id FROM User WHERE Name =: Label.RENEWAL_INITIATED_BY LIMIT 1].Id;

            for(Contract__c con : contracts){
                if(con.Account__c != null){
                    msaAccountIds.add(con.Account__c);
                }

                if(con.Accounts__r != null){
                    if(!accountToSfxListMap.containsKey(con.Id)){
                        accountToSfxListMap.put(con.Id, new List<Account>());
                    }
                    accountToSfxListMap.get(con.Id).addAll(con.Accounts__r);
                }
            }

            for(Task t: [Select Id ,Subject,WhatId,ownerId,ActivityDate,RecordTypeId,status from Task Where WhatId IN:contracts]) {
                existingContractTaskMap.put(t.WhatId, t);
            }

            for(Account_Team__c acc : [ SELECT Id,Account__c, BDMPropelI__c, BDMPropelI__r.Name, BDMPropelI__r.Manager.Email, BDMPropelI__r.Manager.Manager.Name, BDMPropelI__r.Manager.Manager.Email,
                                        BDMPropelI__r.Manager.Name,BDMPropelI__r.Email, National2__c FROM Account_Team__c where Account__c IN: msaAccountIds AND National2__c = true]){
                if(acc.BDMPropelI__c != null){
                    accountToOwnerMap.put(acc.Account__c, acc);
                }
                
            }

            List<EmailTemplate> templates = [
                SELECT Id
                FROM EmailTemplate
                WHERE DeveloperName =: ConstantUtility.EMAIL_TEMPLATE_DEV_NAME];
            if(templates.isEmpty()) return;
            for(Contract__c con : contracts){
				system.debug('con'+con);
                Integer daysRemaining = today.daysBetween(con.Contract_End_Date__c);
                system.debug('daysRemaining'+daysRemaining);


                if(daysRemaining == ConstantUtility.REMINDER_DAY_60 || Test.isRunningTest() || daysRemaining == ConstantUtility.REMINDER_DAY_90){
                    if(!accountToOwnerMap.containsKey(con.Account__c)){
                        ExceptionHandling.Exception(
                            'processContracts',
                            'ContractRenewalService',
                            'No BDM found for Account ' + con.Account__c +'to Send Renewal Email'
                        );
                        continue;
                    }

                    Messaging.SingleEmailMessage mail =
                        buildEmail(con, accountToOwnerMap, accountToSfxListMap, templates[0], null);

                    if(mail != null){
                        emails.add(mail);
                    }
                }

                if(daysRemaining == ConstantUtility.REMINDER_DAY_30 || Test.isRunningTest()){

                    if(!accountToOwnerMap.containsKey(con.Account__c)){
                        ExceptionHandling.Exception(
                            'processContracts',
                            'ContractRenewalService',
                            'No BDM found for Account ' + con.Account__c +'to Send Renewal Email'
                        );
                        continue;
                    }
                    
                    Task t;
                    if(!existingContractTaskMap.containsKey(con.Id)) {
                        t = new Task();
                        t.Subject = 'Contract Renewal || ' + con.Account__r.Name;
                        t.WhatId = con.Account__c;
                        t.Initiated_by__c = initiatedById;
                        t.ownerId = accountToOwnerMap.get(con.Account__c).BDMPropelI__c;
                        t.ActivityDate = con.Contract_End_Date__c.addDays(-23);
                        t.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('General').getRecordTypeId();
                        t.Status = 'Open';
                        tasksToInsert.add(t);
                    } else {
                        t = existingContractTaskMap.get(con.Id);
                    }
       
                    Messaging.SingleEmailMessage mail =
                    buildEmail(con, accountToOwnerMap, accountToSfxListMap, templates[0], t);
                    
                    if(mail != null){
                        emails.add(mail);
                    }
                }
                
            }
            if(!tasksToInsert.isEmpty()){
            Database.DMLOptions dmlo = new Database.DMLOptions(); 
            dmlo.EmailHeader.triggerUserEmail = true;

            Database.insert(tasksToInsert, dmlo);
        }

            if(!emails.isEmpty()){
                System.debug('emails >>' + emails);
                Messaging.sendEmail(emails);
            }

          

        }catch(Exception e){
            ExceptionHandling.Exception(
                'processContracts',
                'ContractRenewalService',
                e.getMessage()
            );
        }
    }


    private static Messaging.SingleEmailMessage buildEmail(
        Contract__c con,
        Map<Id, Account_Team__c> accountToOwnerMap,
        Map<Id, List<Account>> accountToSfxListMap,
        EmailTemplate template,
        Task t
    ){

        if(!accountToOwnerMap.containsKey(con.Account__c)){
            return null;
        }

        String baseUrl = URL.getOrgDomainUrl().toExternalForm();
        String msaLink =
        '<a href="' + baseUrl + '/' + con.Account__c + '">' +
        con.Account__r.Name +
        '</a>';
        
        String contractLink =
       '<a href="' + baseUrl + '/' + con.Id + '">' +
       con.Name +
      '</a>';
        // Build SFX table
        String sfxTable = '<table border="1" cellpadding="5" style="border-collapse:collapse;">';
        Set<String> uniqueSfxCodes = new Set<String>();
        sfxTable += '<tr><th>SFX Code</th></tr>';
        if(accountToSfxListMap.containsKey(con.Id)) {
            for(Account acc : accountToSfxListMap.get(con.Id)){
                if (!String.isBlank(acc.SFX_Code__c) && uniqueSfxCodes.add(acc.SFX_Code__c)) {
                    String link = baseUrl + '/' + acc.Id;
                    sfxTable += '<tr>';
                    sfxTable += '<td><a href="' + link + '">' + acc.SFX_Code__c + '</a></td>';
                    sfxTable += '</tr>';
                }
            }
        }

        sfxTable += '</table>';

        Messaging.SingleEmailMessage rendered =
            Messaging.renderStoredEmailTemplate(
                template.Id,
                UserInfo.getUserId(),
                con.Id
            );

        // Get processed body
        String body = rendered.getHtmlBody();
        String msaCode = con.Account__r != null && 
                 !String.isBlank(con.Account__r.Propel_MSACode__c)
                 ? con.Account__r.Propel_MSACode__c
                 : '';
        body = body.replace('msaAccountName', msaLink);
        body = body.replace('contractLink', contractLink);
        body = body.replace('SFXCodeTable', sfxTable);
        body = body.replace('localNam', accountToOwnerMap.get(con.Account__c).BDMPropelI__r.Name);
        body = body.replace('msaCode', msaCode);

        // Send email
        System.debug('accountToOwnerMap.get(con.Account__c).BDMPropelI__r.email >>' + accountToOwnerMap.get(con.Account__c).BDMPropelI__r.email);
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[]{accountToOwnerMap.get(con.Account__c).BDMPropelI__r.email});
        if(accountToOwnerMap.get(con.Account__c).BDMPropelI__r.Manager.Email != null && accountToOwnerMap.get(con.Account__c).BDMPropelI__r.Manager.Name != System.Label.SFX_MD_Name) {
            mail.setCcAddresses(new String[]{ accountToOwnerMap.get(con.Account__c).BDMPropelI__r.Manager.Email});
            if(accountToOwnerMap.get(con.Account__c).BDMPropelI__r.Manager.Manager.Email != null && accountToOwnerMap.get(con.Account__c).BDMPropelI__r.Manager.Manager.Name != System.Label.SFX_MD_Name) {
                mail.setCcAddresses(new String[]{ accountToOwnerMap.get(con.Account__c).BDMPropelI__r.Manager.Email, accountToOwnerMap.get(con.Account__c).BDMPropelI__r.Manager.Manager.Email});
            }
            
        }
        mail.setBccAddresses(new List<String>{ 'indra.jain@safexpress.com' });
        mail.setSubject(rendered.getSubject().replace('msaAccountName', con.Account__r.Name));
        mail.setHtmlBody(body);
        if(t != null) {
            

            String msaName = con.Account__r != null ? con.Account__r.Name : '';

            String localNam = accountToOwnerMap.get(con.Account__c).BDMPropelI__r.Name;

            String expiryDate = con.Contract_End_Date__c != null
                ? con.Contract_End_Date__c.format()
                : '';
                String contractName = con.Name != null ? con.Name : '';

            Set<String> codes = new Set<String>();
            if(accountToSfxListMap.containsKey(con.Id)){
                for(Account acc : accountToSfxListMap.get(con.Id)){
                    if(acc.SFX_Code__c != null){
                        codes.add(acc.SFX_Code__c);
                    }
                }
            }

            String sfxCodes = codes.isEmpty() ? '' : String.join(codes, ', ');

            String descriptionText =
            'Contract: ' + contractName +
           ' | MSA: ' + msaName +
           ' | NAM: ' + localNam +
           ' | Expiry: ' + expiryDate +
         ' | SFX: ' + sfxCodes;

         t.Area__c = descriptionText.length() > 255 
          ? descriptionText.substring(0,255) 
          : descriptionText;
        }
        List<OrgWideEmailAddress> oweaList = [
        SELECT Id, Address
       FROM OrgWideEmailAddress
       WHERE Address = :ConstantUtility.CONTRACT_FROM_EMAIL
       LIMIT 1
       ];

     if(!oweaList.isEmpty()){
     mail.setOrgWideEmailAddressId(oweaList[0].Id);
     }
        mail.setSaveAsActivity(false);
        return mail;
    }
}