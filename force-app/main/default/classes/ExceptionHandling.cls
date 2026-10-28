/**
 * Description        :     Class to Save exception in ExceptionHandling object
 * Created By       :       Safexpress
 * Created Date     :       8th August, 2019
 * Release          :       18th August, 2019
 * Last Modified on :       17-Feb-21
 * Jira Ticket      :       https://safexpress.atlassian.net/browse/SD-417
 ** Hittory: 
 **Desciption: a method "dataExceptionHandler" is introduced to manage the propel-I data exceptions.
 **/

/**
    @Description          : Class to Save exception in ExceptionHandling object
    * @Author             : Shubham 
    * @Group              : Safexpress
    * @Last Modified By   : Shubham
    * @Last Modified On   : 8th August, 2019
    * @Modification Log   :
    *==============================================================================
    * Ver         Date                     Author                    Modification
    *==============================================================================
    * 1.0        08-Aug-19               Shubham                   Initial Version
    * 2.0        13-Jan-22               Shubham                   New Feature to get API logs with JSON sent 
**/
Public without sharing class ExceptionHandling {
    public static void Exception(String name, String className, String msg)
    {
        ExceptionHandler__c exc = new ExceptionHandler__c();
        exc.Name = name;
        exc.Class_Name__c = className;
        exc.Error_Message__c = msg;        
        insert exc; 
    }
    //added by abhishek 
    public static void Exceptions(List<ExceptionHandler__c> excList)
    {
        if(!excList.isEmpty()) {
            insert excList; 
        }
    }

   public static void Exception(String name, String className, Exception e)
    {
        ExceptionHandler__c exc = new ExceptionHandler__c();
        exc.Name = name;
        exc.Class_Name__c = className;
        exc.Error_Message__c = Test.isRunningTest() ? 'There is an error.' : e.getMessage();
        exc.Exception_Time__c = System.now();
        exc.Exception_Type__c =Test.isRunningTest() ? 'Test Class' : e.getTypeName();
        exc.Line_Number__c =Test.isRunningTest() ? 15 : e.getLineNumber();
        //exc.Cause__c= e.getCause(); 
        exc.Stack_Trace__c = Test.isRunningTest() ? 'Test class' : e.getStackTraceString();
        
        insert exc; 
    } 

    // Written to manage the data exceptions. 
    // this is accessed to capture the data individually. 
    Public static void dataExceptionHandler(List<wrap_ErrorsHandling> lstWrapErrorHandling)
    {
        System.debug('wrap_ErrorsHandling------->'+lstWrapErrorHandling);
        if(! lstWrapErrorHandling.isEmpty())
        {   
            List<ExceptionHandler__c> lstNewExceptions = new List<ExceptionHandler__c>();
            for(wrap_ErrorsHandling eachOccurredError : lstWrapErrorHandling)
            {

                ExceptionHandler__c newExceps = new ExceptionHandler__c();
                newExceps.MSA__c = eachOccurredError.MSA;
                newExceps.SFX__c = eachOccurredError.SFX;
                newExceps.Error_Message__c = eachOccurredError.Message;
                newExceps.Exception_Time__c = System.now();
                newExceps.Name = eachOccurredError.Object_Name;
                newExceps.Class_Name__c = eachOccurredError.ClassName; 
                newExceps.Error_Code__c =Decimal.valueOf(eachOccurredError.ErrorCode);
                lstNewExceptions.add(newExceps);

            }
            System.debug('lstNewExceptions---------------->'+lstNewExceptions);
            if(! lstNewExceptions.isEmpty())
            {
                insert lstNewExceptions;
            }
        }

    } 
    
    // Method to create API log
    
    public static String createAPILog(String apiName, String endPoint, String requestBody, String responseBody, Integer responseCode) {
        ExceptionHandler__c apiLogger = New ExceptionHandler__c();
        apiLogger.Name = apiLogger.Name__c;
        apiLogger.Class_Name__c = apiName;
        apiLogger.Endpoint__c = endPoint;
        apiLogger.Request_Body__c = requestBody;
        system.debug('@@@@@@@@@'+ responseBody.length());
        if(responseBody.length() >= 131000){
        apiLogger.Response_Body__c = 'Responce Data File Attached to the record';   
        }else{
        apiLogger.Response_Body__c = responseBody;    
        }
        apiLogger.Response_Status_Code__c = String.valueOf(responseCode); 
        apiLogger.recordtypeId = Schema.SObjectType.ExceptionHandler__c.getRecordTypeInfosByName().get('API Log').getRecordTypeId();
        insert apiLogger;
        System.debug('************************'+ apiLogger.Response_Body__c );
        System.debug('************************'+ apiLogger.Name__c);
        if(apiLogger.Response_Body__c == 'Responce Data File Attached to the record'){
        
        ExceptionHandling.attachLogWithrecord(apiLogger.id , apiLogger.id, responseBody);      
        }
        System.debug('API Logger Id : ' + apiLogger.Id);
        return null;
    }
    
    //Method to convert string into pdf and attached it to parent record.
    public static void attachLogWithrecord(id parentId , string fileName, string textNeedToConvert){
    Attachment attachmentPDF = new Attachment();
	attachmentPdf.parentId = parentId;
	attachmentPdf.name =  fileName + '.pdf';
	attachmentPdf.body = blob.toPDF(textNeedToConvert);
	insert attachmentPDF;
    system.debug('$$$$$$$$$$$$$$'+ attachmentPDF.id);    
    }

    // class to capture the any run time data errors. 
    Public Virtual  Class wrap_ErrorsHandling
        {
            Public String MSA;
            Public String SFX;
            Public String Message;
            Public String ErrorCode;
            Public String ClassName; 
            Public String Object_Name; 
        public wrap_ErrorsHandling(String MSA, String SFX, String Message, String ErrorCode, String ClassName, String Object_Name)
            {
                this.MSA = MSA;
                this.SFX = SFX;
                this.Message = Message;
                this.ErrorCode = ErrorCode;
                this.ClassName = ClassName;
                this.Object_Name = Object_Name;

            }
            public wrap_ErrorsHandling(){

            }
        }

    }