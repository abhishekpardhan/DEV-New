/**
 * Description      :   the interface to return the response of the billing API request.  
 * Created By       :   Akhsay Kumar    
 * Created Date     :       
 * Release          :      09th Dec, 2020
 * Last Modified on :      
 * Jira Ticket      :      
 **/

Global abstract class cls_APIResponse
{
    global String StatusCode = '0';
    global String   StatusMessage = '';
    global Boolean isCreated; 
    global Boolean isSuccess;
}