/**
* Description		:		class for trg_Quote Trigger
* Release          :       17th july, 2019
* JIRA Ticket 		:		https://safexpress.atlassian.net/browse/SD-388 , SD-498
* Coverage			:		83%
**/
public class quotetriggerHelper {
    //This method is to extract the values of a user's Regional manager and Regional Retail Manager using the Roles and Profiles and then using those values in the Approval Processes.
    
    public static void updateApprovals(List<quote__c> lstQuote){
        List<Id> lstId = new List<Id>();
        List<Id> lstUsId = new List<Id>();
        List<Id> lstqId = new List<Id>();
        map<Id,string> mapIdRegion = new map<Id,string>();        
        map<Id,Id> mapUserAM = new map<Id,Id>();
        List<User> lstUser = new List<User>();
        Map<Id ,Id> mapParentAcc = new Map<Id ,Id>();
        Set<Id> lstAccId = new Set<Id>();
        Map<Id,Id> mapChildAcc = new Map<Id,Id>();
        Map<Id,Account_Team__c> mapAccTeam = new Map<Id,Account_Team__c>();
        try{
            for(quote__c q: lstQuote){
                if(!lstId.contains(q.Opportunity__c)){
                    lstId.add(q.Opportunity__c);
                }
                lstqId.add(q.id);
            }
            
            for(Opportunity__c objOpp : [Select Id,Account__c,ownerId from Opportunity__c where ID IN : lstId]){
                lstUsId.add(objOpp.ownerId);
                if(!String.isBlank(objOpp.Account__c)){
                    mapParentAcc.put(objOpp.Id , objOpp.Account__c);
                    if(!lstAccId.contains(objOpp.Account__c)){
                        lstAccId.add(objOpp.Account__c);
                        
                    }
                }
            }
            System.debug('lstAccId------>'+lstAccId);
            
            for(Account_Team__c team : [Select Id, BDMPropelI__r.Id, BDMPropelI__r.email ,National1__c, Account__c from Account_Team__c where Account__c In: lstAccId AND National1__c = true]){
                mapAccTeam.put(team.Account__c ,team);
            }
            
            /*lstId = new List<Id>();
            for(Account objAcc : [Select Id , (Select Id,National1__c from childAccounts where National1__c = true limit 1) from Account where Id IN : lstAccId]){
                if(objAcc.ChildAccounts.size() > 0){
                    lstId.add(objAcc.ChildAccounts[0].Id);
                    mapChildAcc.put(objAcc.Id , objAcc.ChildAccounts[0].Id);
                }
            }
            system.debug(lstId);
            for(Account objAcc : [Select Id ,(Select Id,BDMPropelI__r.Id,BDMPropelI__r.email ,National1__c from Account_Teams__r where National1__c = true limit 1) from Account where Id IN : lstId]){
                if(objAcc.Account_Teams__r.size() > 0){
                    mapAccTeam.put(objAcc.Id , objAcc.Account_Teams__r);
                }
            }*/
            
            for(user u: [select id,name,Region__c,managerid from user where id IN: lstUsId]){
                mapIdRegion.put(u.Id,u.Region__c);
                mapUserAM.put(u.Id,u.ManagerId);
            }
            System.debug('mapIdRegion------>'+mapIdRegion);
            map<String,Id> mapRMId = new map<String,Id>();//map of region and RM.
            map<String,Id> mapRRMId = new map<String,Id>();//map of region and RRM.
            map<String,Id> mapRNSId = new map<String,Id>();//map of region and regional new sales Added by Monika on 16-07-2019
            Id SalesHeadCorpRoleId = [select id,name from userrole where name='New Sales Head Corporate' limit 1].Id;
            Id TPLRoleId = [select id,name from userrole where name='3PL Head' limit 1].Id;
            Id RvnueMngmentId = [select id,name from userrole where name='Revenue Mgmt Head' limit 1].Id; //Added by Monika 09-12-2019
            Id TPLHEADID = [select id,name from userrole where name='3PL Head' limit 1].Id;
            
            User TPLUser = [select id,name from user where userroleId =:TPLRoleId limit 1];
            User RvnueMngmentUser = [select id,name from user where userroleId =:RvnueMngmentId limit 1]; //Added by Monika 09-12-2019
            User TPLHEADUSER = [select id,name from user where userroleId =:TPLHEADID limit 1];
            
            List<User> lstus = [select id,name from user where userroleId =:SalesHeadCorpRoleId limit 1];//'00e0l000000HsIF'
            
            Id RetailHeadCorpProfileId = [select id from profile where name = 'Retail Head Corporate' limit 1].Id;
            
            List<User> lstRetailHeadCorporate = [select id,name from user where profileid =: RetailHeadCorpProfileId limit 1];//'00e0l000000HsIK'             
            
            Id RMProfileId = [select id from profile where name = 'Regional Manager' limit 1].Id;
            Id RRMProfileId = [select id from profile where name = 'Regional Retail Manager' limit 1].Id; //Added by Monika on 16-07-2019
            Id RNSProfileId = [select id from profile where name = 'Regional New Sales Manager' limit 1].Id;
            
            system.debug([select id,name,profileid,region__c from user where region__c IN: mapIdRegion.values()]);
            for(user u: [select id,name,profileid,region__c from user where region__c IN: mapIdRegion.values()]){
                if(u.ProfileId == RMProfileId){
                    mapRMId.put(u.Region__c,u.Id);
                }
                if(u.ProfileId == RRMProfileId){ //Added by Monika on 16-07-2019
                    mapRRMId.put(u.Region__c,u.Id); //Added by Monika on 16-07-2019
                }
                else if(u.ProfileId == RNSProfileId){
                    mapRNSId.put(u.Region__c,u.Id);
                }
            }
            List<Quote__c> lstUpdQuote = new List<Quote__c>();
            for(quote__c q: [select id,name,AM__c,RM__c,Regional_Sales_Manager__c,Regional_Retail_Manager__c,Sales_Head_Corporate__c,Opportunity__c,Qrm__c,National_1__c,CreatedById,Opportunity__r.ownerId,Opportunity__r.Type__c from quote__c where ID in: lstqId]){
                // q.AM__c = mapUserAM.get(q.Opportunity__r.ownerId);
                q.RM__c = mapRMId.get(mapIdRegion.get(q.Opportunity__r.ownerId));  
                system.debug('RM:'+q.RM__c);
                q.Regional_Retail_Manager__c = mapRRMId.get(mapIdRegion.get(q.Opportunity__r.ownerId));
                system.debug('RRM:'+q.Regional_Retail_Manager__c);
                q.Regional_Sales_Manager__c = mapRNSId.get(mapIdRegion.get(q.Opportunity__r.ownerId));//Added by Monika on 14-11-2019
                if(q.Opportunity__r.Type__c == 'Retail' && !lstRetailHeadCorporate.isEmpty()){
                    q.Sales_Head_Corporate__c = lstRetailHeadCorporate[0].Id;
                }
                else if(q.Opportunity__r.Type__c == 'Credit' || q.Opportunity__r.Type__c == 'Transportation+3PL'){
                    if(lstus != null){
                        q.Sales_Head_Corporate__c = lstus[0].Id;
                    }
                }
                else if(q.Opportunity__r.Type__c == '3PL'){
                    // if(TPLUser != null){//Commented by Monika 09-12-2019
                    //  q.Sales_Head_Corporate__c = TPLUser.Id; //Commented by Monika 09-12-2019
                    
                    /*if(RvnueMngmentUser != null){ //Added by Monika 09-12-2019  
q.Sales_Head_Corporate__c = TPLHEADUSER.Id;   //Added by Monika 09-12-2019}
}*/ //Commented by adarsh 06-02-2023 from line 105-107
                    if(lstus != null){
                        q.Sales_Head_Corporate__c = lstus[0].Id;
                    }
                }
                // Id VPProfileId = [select id from profile where name = 'VP' limit 1].Id;
                // q.VP__c = [select id,name from user where profileid =:VPProfileId limit 1].Id;
                system.debug(mapAccTeam);
                system.debug(mapAccTeam.size());
                
                if(mapAccTeam.size() > 0){
                    system.debug('Enter 1');
                    if(mapParentAcc.containsKey(q.Opportunity__c) && mapParentAcc.get(q.Opportunity__c) != null){
                        system.debug('Enter 2');
                        if(mapAccTeam.containsKey(mapParentAcc.get(q.Opportunity__c)) && mapAccTeam.get(mapParentAcc.get(q.Opportunity__c)) != null){
                            system.debug('Enter 3');
                            if(mapAccTeam.get(mapParentAcc.get(q.Opportunity__c)).BDMPropelI__r.Id == '0057F000002y8oaQAA'){
                                system.debug('Enter 4');
                                q.Qrm__c = mapAccTeam.get(mapParentAcc.get(q.Opportunity__c)).BDMPropelI__r.Id;
                            }
                            else{
                                system.debug('Enter 5');
                                q.Qrm__c = System.Label.Renewal_quotes;//Added by Monika on 14-11-2019
                            }
                        }
                    }
                    /*if(mapParentAcc.get(q.Opportunity__c) != null){
                        system.debug('Enter 1');
                        if(mapChildAcc.get(mapParentAcc.get(q.Opportunity__c)) != null){
                            system.debug('Enter 2');
                            if(mapAccTeam.get(mapChildAcc.get(mapParentAcc.get(q.Opportunity__c))) != null){
                                system.debug('Enter 3');
                                if(mapAccTeam.get(mapChildAcc.get(mapParentAcc.get(q.Opportunity__c))).BDMPropelI__r.Id == '0057F000002y8oaQAA'){//Added by Monika on 14-11-2019
                                    system.debug('Enter 4');
                                    q.Qrm__c = mapAccTeam.get(mapChildAcc.get(mapParentAcc.get(q.Opportunity__c))).BDMPropelI__r.Id;
                                }
                                else{
                                    system.debug('Enter 5');
                                    q.Qrm__c = System.Label.Renewal_quotes;//Added by Monika on 14-11-2019
                                }
                            }
                        }
                    }*/
                }                
                lstUpdQuote.add(q);
            }
            if(!lstUpdQuote.isEmpty()){
                update lstUpdQuote;
                quoteAccessForApproval(lstUpdQuote);
            }
        }catch(Exception e){
            system.debug('Exception:'+e.getMessage());
            system.debug('Exception:'+e.getLineNumber());
        }
    }

    public static void quoteAccessForApproval(List<Quote__c> lstQuote) {

        Map<Id, Set<Id>> oppToUsers = new Map<Id, Set<Id>>();
        Set<Id> oppIds = new Set<Id>();

        for (Quote__c q : [
            SELECT Id, Opportunity__c, Regional_Retail_Manager__c, RM__c
            FROM Quote__c
            WHERE Opportunity__r.Type__c IN ('PRC', 'Retail')
            AND Id IN :lstQuote
        ]) {
            if (q.Opportunity__c == null) continue;

            oppIds.add(q.Opportunity__c);

            if (!oppToUsers.containsKey(q.Opportunity__c)) {
                oppToUsers.put(q.Opportunity__c, new Set<Id>());
            }

            if (q.Regional_Retail_Manager__c != null)
                oppToUsers.get(q.Opportunity__c).add(q.Regional_Retail_Manager__c);

            if (q.RM__c != null)
                oppToUsers.get(q.Opportunity__c).add(q.RM__c);
        }

        if (oppToUsers.isEmpty()) return;

        // Fetch existing shares
        Set<String> existing = new Set<String>();

        for (Opportunity__Share s : [
            SELECT ParentId, UserOrGroupId
            FROM Opportunity__Share
            WHERE ParentId IN :oppIds
        ]) {
            existing.add(s.ParentId + '-' + s.UserOrGroupId);
        }

        // Create missing shares
        List<Opportunity__Share> shares = new List<Opportunity__Share>();

        for (Id oppId : oppToUsers.keySet()) {
            for (Id userId : oppToUsers.get(oppId)) {
                String key = oppId + '-' + userId;

                if (!existing.contains(key)) {
                    shares.add(new Opportunity__Share(
                        ParentId = oppId,
                        UserOrGroupId = userId,
                        AccessLevel = 'Edit',
                        RowCause = Schema.Opportunity__Share.RowCause.Manual
                    ));
                }
            }
        }

        if (!shares.isEmpty()) {
            insert shares;
        }
    }

    //Method to show error if existing quote is active while creating new one.
    public static void checkActiveQuotes(List<quote__c> lstQuote){
        List<Id> lstOppId = new List<Id>();
        Map<Id,Integer> mapOppIdQuoteCount = new Map<Id,Integer>();
        try{
            
            for(quote__c qc : lstQuote){
                
                lstOppId.add(qc.Opportunity__c);
            }            
            
            for(Opportunity__c opp : [select id,name,(select id,name,Status__c from Quotes__r where Status__c NOT IN ('Deferred','Rejected')) from Opportunity__c where Id IN: lstOppId]){                
                if(opp.Quotes__r.size() > 0){
                    mapOppIdQuoteCount.put(opp.Id,opp.Quotes__r.size());
                }
                else{
                    mapOppIdQuoteCount.put(opp.Id,0);
                }
            }
            for(quote__c qc : lstQuote){
                
                if(mapOppIdQuoteCount.get(qc.Opportunity__c) > 0){
                    qc.addError('Error : An existing quote is already active. Please defer that before creating new one!');
                }
            }    
            
        }catch(Exception e){
            system.debug('Exception:'+e.getMessage());
        }
    }
    
    //Method to update the remarks on Quote added by different users.
    public static void updateQuoteRemarks(List<quote__c> lstQuote){
        try{
            Id currentUser = UserInfo.getUserId();
            datetime dt = system.now();
            datetime dt2 = dt.addHours(5);
            datetime dt3 = dt2.addMinutes(30);
            Map<Id,User> mapUserIdName = new Map<Id,User>([select Id,name from user]);
            for(quote__c qt : lstQuote){
                if(String.isBlank(qt.Remarks__c)){
                    qt.Remarks__c = mapUserIdName.get(currentUser).Name +' '+ dt3 + ' ' +qt.Enter_Remarks__c;
                }
                else{
                    qt.Remarks__c += '\r\n' + mapUserIdName.get(currentUser).Name +' '+ dt3 + ' ' +qt.Enter_Remarks__c;
                }
                qt.Enter_Remarks__c = '';
            }
        }catch(Exception e){
            system.debug('Exception:'+e.getMessage());
        }
    }
    public static void changeName(List<quote__c> newQuote){
        
        Set<Id> lstOppId = new Set<Id>();
        Map<Id,String> mapOppName = new Map<Id,String>();
        try{
            
            for(quote__c qc : newQuote){
                if(!lstOppId.contains(qc.Opportunity__c)){
                    lstOppId.add(qc.Opportunity__c);
                }
            }            
            
            for(Opportunity__c opp : [select id,name from Opportunity__c where Id IN: lstOppId]){
                mapOppName.put(opp.Id,opp.name);
            }
            for(quote__c qc : newQuote){
                if((mapOppName.get(qc.Opportunity__c) +'-'+qc.name.toUpperCase()).length() <= 80){
                    qc.name = mapOppName.get(qc.Opportunity__c) +'-'+qc.name.toUpperCase(); 
                }
            }    
            
        }catch(Exception e){
            system.debug('Exception:'+e.getMessage());
            system.debug('Exception:'+e.getLineNUmber());
        }
    }
    
    //Method to update the quotelineitems version when quote rejectd in approval process.
    public static void quoteRejected(List<quote__c> lstQuote){
        
        Map<Id,List<Quote_Line_Item__c>> mapQuoteQLI = new Map<Id,List<Quote_Line_Item__c>>();
        Map<Id,Decimal> mapQuoteVersion = new Map<Id,Decimal>();
        List<Quote_Line_Item__c> lstQliupd = new List<Quote_Line_Item__c>();
        List<Quote_Line_Item__c> lstQliIns = new List<Quote_Line_Item__c>();
        List<Quote_Line_Item__c> lstQli = new List<Quote_Line_Item__c>();
        for(Quote_Line_Item__c qil : [select id,Name,Version__c from quote_line_item__c where Quote__c IN :lstQuote]){
            
            
        }
        
        for(quote__c q : [select id,(select id,Name,Version__c,quote__c,Surface_Price__c,Air_Price__c,check__c,City__c,Minimum_Freight__c,
                                     Rate__c,State__c,Type__c,Zone__c from Quote_Line_Items__r order by Version__c DESC NULLS LAST) from quote__c where Id IN :lstQuote]){
                                         if(q.Quote_Line_Items__r.size() > 0){
                                             mapQuoteQLI.put(q.Id,q.Quote_Line_Items__r);
                                             mapQuoteVersion.put(q.Id,q.Quote_Line_Items__r[0].Version__c);
                                         }
                                     }
        
        system.debug('mapQuoteQLI++'+mapQuoteQLI);
        system.debug('mapQuoteVersion++'+mapQuoteVersion);
        
        for(quote__c q : lstQuote){
            
            if(mapQuoteQLI.containsKey(q.Id)){
                lstQli = mapQuoteQLI.get(q.Id) ;
            }
            for(Quote_Line_Item__c qli : lstQli){
                system.debug('qli++'+qli);
                if(qli.version__c == NULL){
                    system.debug('qli.version__c++'+qli.version__c);
                    Decimal vers = mapQuoteVersion.get(q.Id);
                    system.debug('vers++'+vers);
                    if(vers != NULL){
                        qli.Version__c = vers + 1;
                    }
                    else{
                        qli.Version__c = 1;
                    }
                    system.debug('qli.Version__c++'+qli.Version__c);
                    lstQliupd.add(qli);
                }
                
            }
            
        }
        
        if(!lstQliupd.isEmpty()){           
            update lstQliupd;
        }          
        
        if(!lstQli.isEmpty()){
            
            for(Quote_Line_Item__c qlitem : lstQliupd){
                Quote_Line_Item__c qtl = new Quote_Line_Item__c();
                qtl = qlitem;
                qtl.Id = null;
                qtl.Version__c = null;
                lstQliIns.add(qtl);
            }
            
        }
        
        if(!lstQliIns.isEmpty()){
            insert lstQliIns;
        }
        
        
    }
    
    //To add quotelineitems from previous deferred quote when new quote is created.
    public static void newquoteinserted(List<quote__c> lstQuote){
        
        Map<String, Opportunity__c> oppUpdateMap = new Map<String, Opportunity__c>();
        for(quote__c q : lstQuote){
            if(q.Opportunity__c != null){
                oppUpdateMap.put(q.Opportunity__c, new Opportunity__c(Id = q.Opportunity__c, LatestQuote__c = q.Id));
            }
        }
        // Start SAC-1106 || Deepika Thakur || IBM
        if(!oppUpdateMap.isEmpty()){
            update oppUpdateMap.values();
        }
        // Commented by K SANSI, as below code doesn't make sense
        /*
        map<Id,Id> mapQuoteOppId = new map<Id,Id>();
        map<Id,Id> mapOppQuoteId = new map<Id,Id>();
        map<Id,List<Quote_Line_Item__c>> mapOppQuoteLI = new map<Id,List<Quote_Line_Item__c>>();
        Set<Opportunity__c> listOppToBeUpdated = new Set<Opportunity__c>();
        List<quote_line_item__c> lstQliIns = new List<quote_line_item__c>();
        for(quote__c q : lstQuote){
            
            mapQuoteOppId.put(q.Id,q.Opportunity__c);
            mapOppQuoteId.put(q.Opportunity__c,q.Id);
        }
        system.debug('1');
        map<id,Opportunity__c> mapOpportunity = new map<id,Opportunity__c>([select id,name,LatestQuote__c,(select id,name from Quotes__r ORDER BY CreatedDate DESC LIMIT 1) from Opportunity__c where Id in: mapQuoteOppId.values()]);
        system.debug('mapOpportunity++'+mapOpportunity);
        for(quote__c q : [select id,name,opportunity__c,(select id,Name,Version__c,quote__c,Surface_Price__c,Air_Price__c,check__c,City__c,Minimum_Freight__c,
                                                         Rate__c,State__c,Type__c,Zone__c from Quote_Line_Items__r where Version__c = NULL) from quote__c where Opportunity__c IN: mapQuoteOppId.values()]){
                                                             
                                                             if(q.Quote_Line_Items__r.size() > 0){
                                                                 mapOppQuoteLI.put(q.opportunity__c,q.Quote_Line_Items__r);
                                                             }
                                                         }
        system.debug('mapOppQuoteLI++'+mapOppQuoteLI);
                
        for(quote__c q : lstQuote){
            
            integer size = mapOpportunity.get(q.Opportunity__c).Quotes__r.size();
            system.debug('size++'+size);
            if(size > 0){
                // Start SAC-1106 || Deepika Thakur || IBM
                mapOpportunity.get(q.Opportunity__c).LatestQuote__c = q.Id; 
                listOppToBeUpdated.add(mapOpportunity.get(q.Opportunity__c));
                // End SAC-1106 
                List<Quote_Line_Item__c> lstQlit = new List<Quote_Line_Item__c>();
                if(mapOppQuoteLI.containsKey(q.Opportunity__c)){
                    mapOppQuoteLI.get(q.Opportunity__c);    
                }
                system.debug('lstQli++'+lstQlit);
                if(!lstQlit.isEmpty()){
                    for(Quote_Line_Item__c qli : lstQlit){
                        system.debug('qli++'+qli);
                        Quote_Line_Item__c qtl = new Quote_Line_Item__c();
                        qtl = qli;
                        qtl.Id = null;
                        qtl.Version__c = null;
                        qtl.Quote__c = q.Id;
                        lstQliIns.add(qtl);
                    }
                }
            }
            
            
        }
        system.debug('lstQliIns++'+lstQliIns);
        system.debug('listOppToBeUpdated++'+listOppToBeUpdated);
        
        // End SAC-1106 

        if(!lstQliIns.isEmpty()){
            insert lstQliIns;
        }
        */
    }
    // created by shubham rastogi to validate renewal opportunity
    public static void validateOpportunity(List<Quote__c> quoteList){
        Set<Id> oppIds = new Set<Id>();
        Map<String, Boolean> validOppMap = new Map<String, Boolean>();
        for(Quote__c quote : quoteList){
            if(quote.Opportunity__c != null){
                oppIds.add(quote.Opportunity__c);
            }
        }
        Map<Id, String> maapingData = new Map<Id, String>();
        
        for(Opportunity__c opp : [Select Id, Name, Customer_Type__c from Opportunity__c Where Id In : oppIds]){
            maapingData.put(opp.Id, opp.Customer_Type__c);
        }
        
        for(Renewal_SFX_RC_Mapping__c rec : [select Id, Name, Opportunity__c from Renewal_SFX_RC_Mapping__c where Opportunity__c In: oppIds]){
            validOppMap.put(rec.Opportunity__c, true);
        }
        
        for(Quote__c quote : quoteList){
            if(maapingData.containsKey(quote.Opportunity__c) && maapingData.get(quote.Opportunity__c) == 'Renewal Opportunity' && !validOppMap.containsKey(quote.Opportunity__c)){
                quote.Opportunity__c.addError('Cannot create a Quote for an Opportunity having no SFX and Rate Cards.');
            }
        }
    }
    
 
    //SAC-919 || Deepika Thakur ||IBM
    public static void checkOppoContact(List<quote__c> lstQuote){
        Map<id, id> mapOppCon = new Map<id,id>();
        List<Id> oppIds = new List<Id>();
        System.debug(lstQuote);
        for(Quote__c quote : lstQuote){
            oppIds.add(quote.Opportunity__c);
        }
        for(Opportunity_Contact__c opp_con : [SELECT Id, Name, Opportunity__c FROM Opportunity_Contact__c Where Proposal_Send__c = TRUE AND Opportunity__c IN : oppIds]){
            mapOppCon.put(opp_con.Opportunity__c,opp_con.Id );            
        }
        for(Quote__c q : lstQuote){
            if(!mapOppCon.containsKey(q.Opportunity__c)){
                q.addError('Error : Please add Opportunity Contact!');
               }
        }
    }
    
    
    public static void updateValidForContractTagging(List<Opportunity__c> opportunityList){
        TriggerUtility.byPassTrigger = true;
        update opportunityList;
        TriggerUtility.byPassTrigger = false;
    }
    // SAC- 1363 - By Tarun Sachdeva
    public static void updateAppStatus(List<quote__c> lstQuote){
     Set<Id> lstOfOpportunityId = new Set<Id>();
     Map<Id,String> mapOfOpp = new Map<Id, String>();
        for(Quote__c newQuo : lstQuote){
         lstOfOpportunityId.add(newQuo.Opportunity__c);
        }
     List<Opportunity__c> relatedOpp = [Select id,Type__c from Opportunity__c where id IN :lstOfOpportunityId];
        for(Opportunity__c oldOpp :relatedOpp){
           mapOfOpp.put(oldOpp.id,oldOpp.Type__c);
         }
        for(Quote__c recOfQu : lstQuote){
            if(mapOfOpp.containsKey(recOfQu.Opportunity__c)){
                if(recOfQu.Approval_Status__c == ConstantUtility.Submit_Approval_Status){
                    if(recOfQu.RM__c != null){
                        if(mapOfOpp.get(recOfQu.Opportunity__c) != ConstantUtility.Lead_Type_3PL && mapOfOpp.get(recOfQu.Opportunity__c) != ConstantUtility.Lead_Type_Retail){
                           recOfQu.Approval_Status__c = ConstantUtility.RM_Approval_Status;
                          }
                        else if(mapOfOpp.get(recOfQu.Opportunity__c) == ConstantUtility.Lead_Type_Retail){
                           recOfQu.Approval_Status__c = ConstantUtility.Regional_Approval_Status; 
                        }
                     }
                    else if(mapOfOpp.get(recOfQu.Opportunity__c) == ConstantUtility.Lead_Type_3PL || recOfQu.RM__c == null){
                        
                           recOfQu.Approval_Status__c = ConstantUtility.Corporate_Approval_Status;  
                         }
                    
                    }

             }
        }
    }
    
        
/*Description: Converting workflow rule 
* author : Tarun Sachdeva
* SAC-1457
*/
    public static void updateOpportunityDetails(List<Quote__c> lstQuote){
        Set<Id> opportunityid = new Set<Id>();
        for(Quote__c quote : lstQuote){
            if(quote.Opportunity__c != null){
                opportunityid.add(quote.Opportunity__c);
            }
        }
        List<Opportunity__c> updateOppLst = new List<Opportunity__c>();
        List<Opportunity__c> oppLst = new List<Opportunity__c>([Select Id,Stage__c,Total_Quotation__c from Opportunity__c Where Id IN: opportunityid]);
        if(!oppLst.isEmpty()){
            for(Opportunity__c opp: oppLst){
                if(opp.Total_Quotation__c == 0){
                    opp.Stage__c = 'Quotation';
                }
                if(opp.Total_Quotation__c >= 1 && opp.Stage__c != 'Negotiation'){
                    opp.Stage__c = 'Negotiation';   
                }
               updateOppLst.add(opp); 
            }
        }
        if(!updateOppLst.isEmpty()){
            update updateOppLst;
        }
    }
   
}