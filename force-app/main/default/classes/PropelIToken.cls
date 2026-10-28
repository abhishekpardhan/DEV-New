public class PropelIToken {
    // Method to add new token 
    // 0057F000002y4xPQAQ
    public static void addToken(String Token, Id UserId){
        try{ PropelAPI_Token__c propToken = PropelAPI_Token__c.getInstance(userId);
        if(Token != Null){
        propToken.String0__c = propToken.String1__c = propToken.String2__c = propToken.String3__c = propToken.String4__c = propToken.String5__c = propToken.String6__c = propToken.String7__c = propToken.String8__c = propToken.String9__c = ''; 
        }
        integer start = 0;
        integer ending = 255;
        integer length = Token.length();
        integer numberOfLoop = length/255;
        Integer remaining = math.mod(length, 255);
        system.debug('111111111'+length);
        system.debug('555555555'+remaining);
        for(integer i = 0; i<=numberOfLoop - 1 ; i++){
            string fieldName = 'String'+i+'__c';
         //   string fieldName = 'propToken.String'+i+'__c';
            system.debug('@@@@@@@@@'+fieldName);            
            string fieldName1 = Token.substring(start, ending);
            propToken.put(fieldName, fieldName1 ); 
            system.debug('444444444444'+fieldName);
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
            catch(Exception e){
            String name = 'Propel-I Token';
            String ClassName = 'PropelIToken.addToken';
            ExceptionHandling.Exception( name, ClassName, e);
    }
    }
    
    //Method to get token
    public static String GetToken(Id UserId){
      
   String Token = '';
        PropelAPI_Token__c propToken = PropelAPI_Token__c.getInstance(UserId);
        List<String> mainString = new List<String>{propToken.String0__c,propToken.String1__c,propToken.String2__c,propToken.String3__c,propToken.String4__c,propToken.String5__c,propToken.String6__c,propToken.String7__c,propToken.String8__c,propToken.String9__c};
       // Token = propToken.String0__c + propToken.String1__c + propToken.String2__c + propToken.String3__c + propToken.String4__c + propToken.String5__c + propToken.String6__c + propToken.String7__c + propToken.String8__c + propToken.String9__c;
       token = String.join(mainString, '');
            return Token;
             
    }
    
    //  + propToken.String4__c + propToken.String5__c + propToken.String6__c + propToken.String7__c + propToken.String8__c + propToken.String9__c
   // code to get new propel-I token.
  /*  public static void GenerateNewToken(){
    PropelAPI_Token__c Token = PropelAPI_Token__c.getInstance('0057F000002y4xPQAQ');
    Token.PreviousToken__c = Token.CurrentToken__c ;
    Token.CurrentToken__c = 'Token Received from PropelI';
    update Token;
    */
   // Use below syntex to access token at any api
   // PropelAPI_Token__c Token = PropelAPI_Token__c.getInstance('0057F000002y4xPQAQ');
   // Token.CurrentToken__c  has the value of token
   // }

}