/**
* Description		:	    Batch to update auth token of bdms
* JIRA ticket       :		 
* Last Modified By  :       KR SANSI
* Last Modified Date:       18/09/2024
* Revision Logs   	:    	V_1.0 - Created
* 
**/
public class UpdateAuthTokenBDMBatch implements Database.Batchable<sObject>, Database.allowsCallouts{

    public String query;
    
    public UpdateAuthTokenBDMBatch(String query){
        this.query = query;
    }
         
    public Database.queryLocator start(DataBase.BatchableContext bc){
       	System.debug('query-->'+this.query);
        return Database.getQueryLocator(this.query);
    }
    
    public void execute(DataBase.BatchableContext bc, List<User> userList ){    
        
 		System.debug('userList-->'+userList);
    	List<OauthToken> lstOauthToken = [SELECT Id, AccessToken, UserId, user.name, RequestToken, 
                                            CreatedDate, AppName, LastUsedDate, UseCount, DeleteToken, 
                                            AppMenuItemId FROM OauthToken  WHERE 
                                            userid IN : userList AND 
        									(appname = 'Salesforce for Android' OR appname = 'Salesforce1 for iOS')
                                           ];
		System.debug('lstOauthToken-->'+lstOauthToken);
        for (OauthToken token : lstOauthToken) {
            OauthFactory.deleteToken(token);
    	}        
    }
    
    public void finish(DataBase.BatchableContext bc){
        // do nothing
    }
     
}