/*------------------------------------------------------------------------------------------
*Author: Safexpress.com
*Description: used to add the token in the custom setting
*Test Class: 
*Code Coverage: 
*Histroy
--------------------------------------------------------------------------------------------*/
Public Class cls_AddTokenBillingSystem
{
    // mtheod to update the refreshed token in custom setting.
    public static void addToken(String Token, String userId)
    {
        try
        { 
            //Custom setting to keep the billing system access token. 
            PropelAPI_Token__c propToken = PropelAPI_Token__c.getInstance(userId);
            if(Token != Null)
            {
                propToken.String0__c = propToken.String1__c = propToken.String2__c = propToken.String3__c = propToken.String4__c = propToken.String5__c = propToken.String6__c = propToken.String7__c = propToken.String8__c = propToken.String9__c = ''; 
            }
            integer start = 0;
            integer ending = 255;
            integer length = Token.length();
            integer numberOfLoop = length/255;
            Integer remaining = math.mod(length, 255);
            system.debug('length------------>'+length);
            system.debug('remaining--------------->'+remaining);
            for(integer i = 0; i<=numberOfLoop - 1 ; i++)
            {
                string fieldName = 'String'+i+'__c';
                //string fieldName = 'propToken.String'+i+'__c';
                system.debug('fieldName-------------->'+fieldName);            
                string fieldName1 = Token.substring(start, ending);
                propToken.put(fieldName, fieldName1 ); 
                system.debug('fieldName1------------>'+fieldName1);
                start = start + 255;
                ending = ending + 255;
            }
            ending = ending - 255;
            ending = ending + remaining ;
            string fieldName2 = 'String'+numberOfLoop+'__c';
            string fieldName3 = Token.substring(start, ending);
            propToken.put(fieldName2, fieldName3 );
            update propToken;
        }
        catch(Exception e)
        {
            String name = 'cls_AddTokenBillingSystem';
            String ClassName = 'cls_AddTokenBillingSystem';
            ExceptionHandling.Exception( name, ClassName, e);
        }  
    } 

    //Method to get token
    public static String GetToken(Id UserId)
    {
    
        String Token = '';
        PropelAPI_Token__c propToken = PropelAPI_Token__c.getInstance(UserId);
        List<String> mainString = new List<String>{propToken.String0__c,propToken.String1__c,propToken.String2__c,propToken.String3__c,propToken.String4__c,propToken.String5__c,propToken.String6__c,propToken.String7__c,propToken.String8__c,propToken.String9__c};
        token = String.join(mainString, '');
        return Token;
                    
    }
}