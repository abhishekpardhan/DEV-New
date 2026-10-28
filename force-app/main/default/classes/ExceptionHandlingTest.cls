/**
 * Description    	:		Test class for ExceptionHandling apex class
 * Created By       :       Shubham Girdhar
 * Created Date     :       8th August, 2019
 * Release          :       18th August, 2019
 * Last Modified on :       
 * Jira Ticket      :       https://safexpress.atlassian.net/browse/SD-417
 * Coverage			  :		 100%
 **/
@istest
public class ExceptionHandlingTest {
static testMethod void test1(){
   try{ string name = 'abcd';
    string className = 'abcdef';
   }catch(Exception e){
    Test.startTest();
     string name = 'abcd';
    string className = 'abcdef';
    ExceptionHandling.Exception(name, className, e);   
    Test.stopTest();
   }
    
    ExceptionHandling.wrap_ErrorsHandling excepError = new ExceptionHandling.wrap_ErrorsHandling('MSA00000122','SFX00000109','There is an internal error.','901','PropelISFXUpsert','Account:SFX' );
       /* excepError.MSA = 'MSA00000122';
        excepError.SFX = 'SFX00000109';
        excepError.Message ='There is an internal error.' ;
        excepError.ErrorCode = '901';
        excepError.ClassName = 'PropelISFXUpsert'; 
        excepError.Object_Name = 'Account:SFX';  */
    
    List<ExceptionHandling.wrap_ErrorsHandling> lstExceptions = new List<ExceptionHandling.wrap_ErrorsHandling>();
    lstExceptions.add(excepError);
    Exception e;
     ExceptionHandling.dataExceptionHandler(lstExceptions);
    ExceptionHandling.Exception('Test', 'Test', 'test'); 
    ExceptionHandling.Exception('Test', 'Test', e); 
    ExceptionHandling.createAPILog('Test Name', 'Test Endpoint', 'Test request Body', 'Test Responce', 200);
    
}
    }