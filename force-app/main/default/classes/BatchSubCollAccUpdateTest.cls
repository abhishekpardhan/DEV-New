@isTest
public class BatchSubCollAccUpdateTest {

  @isTest
  static void testBatchExecution() {
    // Create a new instance of the batch class
    BatchSubCollAccUpdate batch = new BatchSubCollAccUpdate();

    // Simulate batch execution
    Database.executeBatch(batch, 10);
      
      Id msaIDs = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect Customer').getRecordTypeId();

      // Insert branch master record.                
        Branch_Master__c br = new Branch_Master__c();
        br.Branch_ID__c = 12345;
        br.PropelI_Branch_ID__c = 12345;
        insert br;
        System.assertNotEquals(br.id, null);
      // Insert MSA Account
        Account newMSAAcc = new Account();
        newMSAAcc.Name = 'unit testing';
        newMSAAcc.Region__c = 'Delhi';
        newMSAAcc.Vertical__c = 'ENGINEERING';
        newMSAAcc.Sub__c ='BUILDING MATERIAL';
        newMSAAcc.Propel_MSACode__c = 'MSA999999245';
        newMSAAcc.RecordTypeID = msaIDs;
        newMSAAcc.Propel_Key__c = '89';
        newMSAAcc.Contact_Person_Name__c ='Akshay Testing' ;
        newMSAAcc.Phone = '011232324';
        newMSAAcc.Mobile_No__c ='9999161406';
        newMSAAcc.Email__c = 'akshay@gmail.com';
        newMSAAcc.Type__c = 'Credit';
        newMSAAcc.Pan_No__c = 'DDDPD4567G';
        insert newMSAAcc;
        System.assertNotEquals(newMSAAcc.id, null);
// Create contact
        Contact newCon = new Contact();
        newCon.FirstName = 'Unit';
        newCon.LastName = 'Testing';
        newCon.Email = 'unittest@gmail.com';
        newCon.Phone = '9999161406';
        insert newCon;
        System.assertNotEquals(newCon.Id, null);
 // Insert an invoice.
        Invoice__c inv = new Invoice__c();
        inv.Propel_ID__c=54321;
        inv.Name='210201000003';
        inv.Bill_Number__c='21020100003';    
        //inv.Description__c= 'Debit Note';
        inv.Customer_Contract_ID__c= 29374;
        inv.Customer_Contract_Code__c='SFX00000057';
        // inv.Customer_Contract_Code__c='SAFEX324';
        inv.Charged_Freight_Amount__c= 5600;
        inv.Charged_ST_Amount__c= 6778.50;
        inv.Charged_Total_Amount__c=674590.85;
        inv.Out_Oct_Amount__c=768.00;
        inv.Out_Total_Amount__c=7483900.00;
        inv.Status_LID__c=98765;
        //inv.Bill_Type_Flag__c='';
        inv.Bill_Branch__c =br.Id;
        inv.Collection_Branch__c = br.Id;
        inv.Sub_Branch_Master__c = br.Id;
        inv.Bill_From_Date__c=Date.today();
        inv.Bill_To_Date__c=Date.today();
        inv.Bill_Due_Date__c=Date.today();
        inv.Bill_Date__c=Date.today();
        inv.MSA__c='MSA999999245';
        inv.Description__c = 'WMS_BILL';
        //inv.SFX_Code__c='SFX00000057';
        //inv.Rate_Card_Number__c='RC6873';
        inv.Submission_Date__c=Date.today();
        inv.Billing_Level__c='MSA';
        //inv.Parent_Invoice__c='a041s000003FS2zAAG';
        inv.Account__c=newMSAAcc.id;
        inv.Composite_Key__c='MSA999999245:210201000003';
        inv.Submitted_To__c = newCon.Id;
        inv.Submission_Date__c  = Date.today();
        insert inv;
        System.assertNotEquals(inv.Id, null);
        Id rId = Schema.SObjectType.task.getRecordTypeInfosByName().get('Submission').getRecordTypeId();// Create submission task.
        List<Task> tskList = new List<Task>();
        Task tsk = new task();
        tsk.subject = 'Bill submission Task - '+ inv.Bill_Number__c;
        tsk.recordtypeid = rId;
        tsk.whatid = inv.id;
        tsk.Priority = 'High';
        tsk.status = 'Open';
        tsk.Is_PropelI__c = true;
        tsk.Submitted_Date__c = Date.today();
        tsk.Automation__c = true;
        tsk.ActivityDate = date.newinstance(Date.today().year(), Date.today().month(), Date.today().day()).addDays(7);
        insert tsk;
    // Assert that the Account_Name__c field is populated on the tasks
    for (Task task : tskList) {
      System.Assert(task.Account_Name__c != null);
    }
  }
}