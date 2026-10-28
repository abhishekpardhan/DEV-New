/**
* @File Name          : CaseTriggerHandler.cls
* @Description        : Main handler class for the Case trigger
* @Author             : Deepak
* @Group              : Techmatrix
* @Last Modified By   : Rudra Singh | GT Bharat
* @Last Modified On   : 12/06/2026
* @Modification Log   :
*==============================================================================
* Ver         Date            Author              Modification
*==============================================================================
* 1.0        29-06-2021       Deepak              Initial Version
* 2.0        22-12-2025       Rudra Singh         SAC-2154
* 3.0        12/06/2026       Rudra Singh         Added sendEnquiryCaseStatusToEnterpriseApp() —
*                                                 fires on Case Status change for ENTERPRISE APP
*                                                 Waybill Enquiry cases; creates Integration_Transaction__c
*                                                 with OperationType_Enterprise_EnquiryCaseStatus label
*                                                 which routes to ExternalCaseStatusQueueable
**/


public without sharing class CaseTriggerHandler extends TriggerHandler {
    private List<Case> newCases;
    private Map<Id, Case> oldCasesMap;
    public static Boolean flag = true;
    public CaseTriggerHandler() {
        this.newCases = (List<Case>) Trigger.new;
        this.oldCasesMap = (Map<Id, Case>) Trigger.oldMap;
    }

        private void enqueueFreshserviceTickets() {
        Set<Id> freshserviceCaseIds = new Set<Id>();

        for (Case caseObj : this.newCases) {
            if (
                caseObj.Id != null &&
                String.isBlank(caseObj.Fresh_Service_Ticket_No__c)
            ) {
                freshserviceCaseIds.add(caseObj.Id);
            }
        }

        if (!freshserviceCaseIds.isEmpty()) {
            System.enqueueJob(new FreshserviceQueueable(freshserviceCaseIds));
        }
    }
    
    public override void beforeInsert() {
        mapUniqueField();
        checkDuplicateCase();
        mapRecordTypeId();
     //   updateSubType();
        mapPickUpDateAndTime();
        updateBusinessType();
        updateSubTypeForPOD();
        updateAddressFromPincode();
        copyModeOfTranPort();
        MapOTRSFields();
        linkBookingBranch();
        mapConsignorDetails();
        checkCallBackDateBeforeInsert();
    }
    public override void beforeUpdate() {
        System.debug(' beforeUpdate CaseTriggerHandler');
        mapUniqueField();
       // checkDuplicateCase();
        updateSubTypeForPOD();
        mapRecordTypeId();
        updateBusinessType();
        copyModeOfTranPort();
        MapOTRSFields();
        updateAddressFromPincode();
        mapConsignorDetails();
        preventManualFreshserviceClosure();
        updateClosedOrCancelledCheck();
        linkBookingBranch();
        callBackTimeValidation();
        checkCallBackDate();
        //createLeadOnB2BCases(); //Commented this method by abhishek pardhan As per This story:- SAC-1480
       
    }
    public override void afterInsert() {
        
        List<String> caseIds = new List<String>();
        // Created By - K SANSI, SCI-164, need to send to propeli for toll free cases  
        for(Case caseObj : this.newCases){             
            if( caseObj.Origin == 'IConnect' || caseObj.Origin == 'REVERSE PICKUP' || caseObj.Origin == 'Digispace' || 
               (caseObj.Origin == 'Salesforce' && caseObj.Case_Nature__c == 'Request' && caseObj.Case_Type__c == 'Booking Request') 
               || (caseObj.Origin != null && caseObj.Origin.toLowerCase() == 'enterprise app'  && caseObj.Case_Nature__c == 'Request' && caseObj.Case_Type__c == 'Booking Request' && caseObj.isGuestUser__c == false ))
            { System.debug('in if block -? enterprise app'+ caseObj.Origin.toLowerCase());
                caseIds.add(caseObj.Id);
            }
        }
        if(!caseIds.isEmpty()){
            //System.enqueueJob(new PreBookingAPIQueueable(caseIds));
            IntegrationUtility.CreateIntegrationLog createITLogObject = new IntegrationUtility.CreateIntegrationLog();
            createITLogObject.objectName = 'Case'; 
            createITLogObject.recordIdList = caseIds;
            createITLogObject.operationType = System.Label.OperationType_PropelI_CaseCreation; 
            if (!Test.isRunningTest()) {
            IntegrationUtility.createIntegrationTransaction(createITLogObject);
            }
        }
        
        updateWaybillDetail();
        updateSubject();
        //createLeadOnB2BCases(); //Commented this method by abhishek pardhan As per This story:- SAC-1480
        sendCaseAssignmentNotification();
    }
    public override void afterUpdate() {
        updateWaybillDetail();
        updateSubject();
        sendCaseAssignmentNotification();
        // Added By Shubham
        
        if(System.Label.ProtonAPIEnable == 'TRUE'){
            System.debug('Proton API Called');
            sendCaseToProton(); 
        }
         
        if(flag){
            flag = false;
        //sendEmailOnCaseCompleted();  //Created flow to trigger email || DEEPIKA || IBM
        
        // Created By - K SANSI, SCI-164, needs to send cases to propelI for PreBookingId    
        sendCaseToPropeli();    
        }
        
        /*List<String> casesToPassIConnect = new List<String>();
        for(Case caseObj : newCases){
            if(caseObj.Booking_Status__c != oldCasesMap.get(caseObj.Id).Booking_Status__c && caseObj.Origin == 'IConnect'){
                casesToPassIConnect.add(caseObj.Id);
            }
        }
        if(!casesToPassIConnect.isEmpty()){
            IConnectPostUpdateAPI.updateSupportCasesIConnect(JSON.serialize(casesToPassIConnect));
        }*/

        sendEnquiryCaseStatusToEnterpriseApp();
    

    Freshservice_UtilClass.syncMappedCaseUpdatesToFreshservice(
            this.newCases,
            this.oldCasesMap
        );
    }
    public void sendEnquiryCaseStatusToEnterpriseApp() {
        try {
            List<String> caseIds = new List<String>();
            for (Case caseObj : newCases) {
                Case oldCase = oldCasesMap.get(caseObj.Id);
                if (caseObj.Origin == ConstantUtility.CASE_ORIGIN_ENTERPRISE_APP
                        && caseObj.Case_Type__c == ConstantUtility.CASE_TYPE_WAYBILL_ENQUIRY
                        && caseObj.Status != oldCase.Status) {
                    caseIds.add(caseObj.Id);
                }
            }
            if (!caseIds.isEmpty()) {
                IntegrationUtility.CreateIntegrationLog logObj = new IntegrationUtility.CreateIntegrationLog();
                logObj.objectName    = 'Case';
                logObj.recordIdList  = caseIds;
                logObj.operationType = System.Label.OperationType_Enterprise_EnquiryCaseStatus;
                if (!Test.isRunningTest()) {
                    IntegrationUtility.createIntegrationTransaction(logObj);
                }
            }
        } catch (Exception exp) {
            LoggerUtil.createErrorLog('CaseTriggerHandler', 'sendEnquiryCaseStatusToEnterpriseApp',
                exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        }
    }
    public void updateBusinessType() {
        try {
            for (Case caseObj : newCases) {
                if (caseObj.Case_Nature__c != null && caseObj.Case_Nature__c == ConstantUtility.CASE_NATURE_REQUEST && caseObj.Case_Type__c != null && caseObj.Case_Type__c == ConstantUtility.CASE_TYPE_BOOKING_REQUEST && caseObj.Sub_Type__c != null) {
                    if (caseObj.Sub_Type__c != null && (caseObj.Sub_Type__c == ConstantUtility.SUB_TYPE_Retail_Non_PRC || caseObj.Sub_Type__c == ConstantUtility.SUB_TYPE_Reverse_Inbound_Retail_Non_PRC
                                                        || caseObj.Sub_Type__c == ConstantUtility.SUB_TYPE_Retail_C2H || caseObj.Sub_Type__c == ConstantUtility.SUB_TYPE_Retail_E2M || caseObj.Sub_Type__c == ConstantUtility.SUB_TYPE_Retail_Sanik_Express)) {
                                                            caseObj.Business_Type__c = ConstantUtility.BUSINESS_TYPE_RETAIL_NON_PRC ;
                                                        }
                    if (caseObj.Sub_Type__c != null && caseObj.Sub_Type__c == ConstantUtility.SUB_TYPE_Credit_Outbound) {
                        caseObj.Business_Type__c = ConstantUtility.BUSINESS_TYPE_CREDIT_OUTBOUND ;
                    }
                    if (caseObj.Sub_Type__c != null && caseObj.Sub_Type__c == ConstantUtility.SUB_TYPE_Reverse_Inbound_Credit) {
                        caseObj.Business_Type__c = ConstantUtility.BUSINESS_TYPE_CREDIT_INBOUND ;
                    }
                    if (caseObj.Sub_Type__c != null && caseObj.Sub_Type__c == ConstantUtility.SUB_TYPE_Reverse_Inbound_Retail_PRC) {
                        caseObj.Business_Type__c = ConstantUtility.BUSINESS_TYPE_RETAIL_INBOUND_WITH_PRC ;
                    }
                    if (caseObj.Sub_Type__c != null && caseObj.Sub_Type__c == ConstantUtility.SUB_TYPE_Retail_PRC) {
                        caseObj.Business_Type__c = ConstantUtility.BUSINESS_TYPE_RETAIL_WITH_PRC ;
                    }
                    if (caseObj.Sub_Type__c != null && caseObj.Sub_Type__c == 'Credit- Inbound') {
                        caseObj.Business_Type__c = ConstantUtility.BUSINESS_TYPE_CREDIT_INBOUND ;
                    }
                    if (caseObj.Sub_Type__c != null && caseObj.Sub_Type__c == 'Credit- Outbound') {
                        caseObj.Business_Type__c = ConstantUtility.BUSINESS_TYPE_CREDIT_OUTBOUND ;
                    }
                    if (caseObj.Sub_Type__c != null && caseObj.Sub_Type__c == 'ANYWHERE TO ANYWHERE') {
                        caseObj.Business_Type__c = 'ANYWHERE TO ANYWHERE';
                    }
                }
            }
            
        } catch (Exception exp) {
            System.debug(' Exception Message :: ' + exp.getMessage() + ' Class Name : CaseTriggerHandler at Line :: ' + exp.getLineNumber());
            LoggerUtil.createErrorLog('CaseTriggerHandler', 'updateCustomerTypeAndBusinessType', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        }
    }
    /**
@Author          : Deepak
@Company         : TechMatrix Consulting
@Description     : This method is used to update the sub Type of the cases created from chat-bot depends on Case Type
@Date            : 02/08/2021
*/
    //Commented this method by abhishek pardhan because this method is not called from anywhere.
    // public void updateSubType() {
    //     try {
    //         for (Case caseObj : newCases) {
    //             System.debug(':: Test ::'+ caseObj);
    //             System.debug(':: Test Sub_Type__c ::'+ caseObj.Sub_Type__c);
    //             if (caseObj.Sub_Type__c != null && caseObj.Case_Type__c != null && caseObj.Case_Type__c == ConstantUtility.CASE_TYPE_SERVICE_ISSUE) {
    //                 if (caseObj.Sub_Type__c == '1') {
    //                     caseObj.Sub_Type__c = ConstantUtility.SUB_TYPE_PILFERRED;
    //                 }
    //                 if (caseObj.Sub_Type__c == '2') {
    //                     caseObj.Sub_Type__c = ConstantUtility.SUB_TYPE_SHORT_PART_SHIPMENT;
    //                 }
    //                 if (caseObj.Sub_Type__c == '3') {
    //                     caseObj.Sub_Type__c = ConstantUtility.SUB_TYPE_WRONG_DELIVERY;
    //                 }
    //                 if (caseObj.Sub_Type__c == '4') {
    //                     caseObj.Sub_Type__c = ConstantUtility.SUB_TYPE_DELIVERY_NOT_DONE;
    //                 }
    //                 if (caseObj.Sub_Type__c == '5') {
    //                     caseObj.Sub_Type__c = ConstantUtility.SUB_TYPE_INTERCHANGE;
    //                 }
    //                 if (caseObj.Sub_Type__c == '6') {
    //                     caseObj.Sub_Type__c = ConstantUtility.SUB_TYPE_DELAY_IN_DELIVERY;
    //                 }
    //                 if (caseObj.Sub_Type__c == '7') {
    //                     caseObj.Sub_Type__c = 'Others';
    //                 }
    //             }
    //             if (caseObj.Sub_Type__c != null && caseObj.Case_Type__c != null && caseObj.Case_Type__c == ConstantUtility.CASE_TYPE_ESCALATION) {
    //                 if (caseObj.Sub_Type__c == '1') {
    //                     caseObj.Sub_Type__c = 'Service Failure';
    //                 }
    //                 if (caseObj.Sub_Type__c == '2') {
    //                     caseObj.Sub_Type__c = 'Others';
    //                 }
    //             }
    //             if (caseObj.Sub_Type__c != null && caseObj.Case_Type__c != null && caseObj.Case_Type__c == ConstantUtility.CASE_TYPE_FREIGHT_DISPUTE) {
    //                 if (caseObj.Sub_Type__c == '1') {
    //                     caseObj.Sub_Type__c = 'Refund';
    //                 }
    //             }
    //             if (caseObj.Sub_Type__c != null && caseObj.Case_Type__c != null && (caseObj.Case_Type__c == ConstantUtility.CASE_TYPE_PICKUP_ISSUE || caseObj.Case_Type__c == ConstantUtility.CASE_TYPE_FEEDBACK)) {
    //                 if (caseObj.Sub_Type__c == '1') {
    //                     caseObj.Sub_Type__c = 'Others';
    //                 }
    //             }
    //         }
            
    //     } catch (Exception exp) {
    //         System.debug(' Exception Message :: ' + exp.getMessage() + ' Class Name : CaseTriggerHandler at Line :: ' + exp.getLineNumber());
    //         LoggerUtil.createErrorLog('CaseTriggerHandler', 'updateSubType', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
    //     }
    // }
    
    /**
@Author          : Deepak
@Company         : TechMatrix Consulting
@Description     : This method is used to map the recordTypeId Based on recordType Id;
@Date            : 02/08/2021
*/
    public void mapRecordTypeId() {
        try {
            for (Case caseObj : newCases) {
                if (caseObj.Case_Nature__c != null && Schema.SObjectType.Case.getRecordTypeInfosByName().get(caseObj.Case_Nature__c) != null) {
                    caseObj.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(caseObj.Case_Nature__c).getRecordTypeId();
                }
                if (caseObj.Case_Nature__c == ConstantUtility.CASE_NATURE_REQUEST && caseObj.Case_Nature__c != null && Schema.SObjectType.Case.getRecordTypeInfosByName().get(ConstantUtility.CASE_TYPE_BOOKING_REQUEST) != null) {
                    caseObj.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(ConstantUtility.CASE_TYPE_BOOKING_REQUEST).getRecordTypeId();
                }
            }
            
        } catch (Exception exp) {
            System.debug(' Exception Message :: ' + exp.getMessage() + ' Class Name : CaseTriggerHandler at Line :: ' + exp.getLineNumber());
            LoggerUtil.createErrorLog('CaseTriggerHandler', 'mapRecordTypeId', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        }
    }
    
    /** ---------------------------------------------------------
Author:        Azad Singh
Description:   Method to update the waybill date and edd on Case
History :
Date            Author             Comments
------------------------------------------------------------
29/06/2021      Azad Singh      Initial Release
-----------------------------------------------------------
*/
    public void updateWaybillDetail() {
        // CaseWaybillUpdateHandler.updateWaybillDetail(newCases);
    }

    public void linkBookingBranch() {

        Set<String> branchNames = new Set<String>();
        for (Case c : newCases) {
            if ( c.Booking_Branch__c != null && (oldCasesMap == null || oldCasesMap.get(c.Id) == null || oldCasesMap.get(c.Id).Booking_Branch__c != c.Booking_Branch__c)) {
                branchNames.add(c.Booking_Branch__c.trim());
            }
        }

        if (branchNames.isEmpty()) return;

        Map<String, Id> branchNameToId = new Map<String, Id>();

        for (Branch_Master__c bm : [
            SELECT Id, Name
            FROM Branch_Master__c
            WHERE Name IN :branchNames AND is_PropelI_Branch__c = True
        ]) {
            branchNameToId.put(bm.Name, bm.Id);
        }

        for (Case c : newCases) {
            if (c.Booking_Branch__c != null && 
                branchNameToId.containsKey(c.Booking_Branch__c.trim())) {

                c.BookingBranch__c = branchNameToId.get(c.Booking_Branch__c.trim());
            }
        }
    }

    /**
    @Author          : Deepak
    @Company         : TechMatrix Consulting
    @Description     : This method is used to update the subject of the case Based on Type of the case
    @Date            : 18/08/2021
    */
    public void updateSubject() {
        try {
            List<Id> casesIds = new List<Id>();
            for (Case caseObj : newCases) {
                if (caseObj.Case_Type__c != null && caseObj.Subject == null) {
                    casesIds.add(caseObj.Id);
                }
            }
            if (casesIds.size() > 0) {
                List<Case> casesToUpdate = new List<Case>();
                for (Case caseObj : [SELECT Case_Type__c,Case_Nature__c,Sub_Type__c,Subject,CaseNumber FROM Case WHERE Id IN :casesIds limit 1000]) {
                    String caseType = caseObj.Case_Type__c != null ? caseObj.Case_Type__c : '';
                    String subType = caseObj.Sub_Type__c != null ? caseObj.Sub_Type__c : '';
                    caseObj.Subject = caseObj.CaseNumber + '-' + caseObj.Case_Nature__c + '-' + caseType + '-' + subType;
                    caseObj.Safexperience_Reference_Number__c = caseObj.CaseNumber;
                    casesToUpdate.add(caseObj);
                }
                TriggerHandler.bypass(ConstantUtility.CASE_TRIGGER_HANDLER);
                update casesToUpdate;
                TriggerHandler.clearBypass(ConstantUtility.CASE_TRIGGER_HANDLER);
            }
        } catch (Exception exp) {
            System.debug(' Exception Message :: ' + exp.getMessage() + ' Class Name : CaseTriggerHandler at Line :: ' + exp.getLineNumber());
            LoggerUtil.createErrorLog('CaseTriggerHandler', 'updateSubject', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        }
    }
    /**
@Author          : Deepak
@Company         : TechMatrix Consulting
@Description     : This method is used to update the sub type of the case Based on Type and Mode of Payment of the Case
@Date            : 18/08/2021
*/
    public void updateSubTypeForPOD() {
        try {
            List<Id> casesIds = new List<Id>();
            
            for (Case caseObj : newCases) {
                if (caseObj.Case_Type__c != null && caseObj.Case_Type__c == ConstantUtility.CASE_TYPE_POD && caseObj.Mode_Of_Payment__c != null) {
                    caseObj.Sub_Type__c = caseObj.Mode_Of_Payment__c.equalsIgnoreCase(ConstantUtility.CREDIT) ? ConstantUtility.POD_CREDIT : ConstantUtility.POD_RETAIL ;
                }
            }
            
        } catch (Exception exp) {
            System.debug(' Exception Message :: ' + exp.getMessage() + ' Class Name : CaseTriggerHandler at Line :: ' + exp.getLineNumber());
            LoggerUtil.createErrorLog('CaseTriggerHandler', 'updateSubType', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        }
    }
    /**
@Author          : Deepak
@Company         : TechMatrix Consulting
@Description     : This method is used to update the address fields using pincode information
@Date            : 21/10/2021
*/
    public void updateAddressFromPincode() {
        try {
            Set<String> pincodes = new Set<String>();
            for (Case caseObj : newCases) {
                if (caseObj.Origin != null) {
                    if (caseObj.Origin_Pincode__c != null) {
                        pincodes.add(caseObj.Origin_Pincode__c);
                        caseObj.Consignor_Pincode__c = caseObj.Origin_Pincode__c;
                    }
                    if (caseObj.Destination_PinCode__c != null) {
                        pincodes.add(caseObj.Destination_PinCode__c);
                        caseObj.Consignee_Pincode__c = caseObj.Destination_PinCode__c;
                    }
                    //                    if (caseObj.Consignee_Pincode__c != null) {
                    //                        pincodes.add(caseObj.Consignee_Pincode__c);
                    //                    }
                    //                    if (caseObj.Consignor_Pincode__c != null) {
                    //                        pincodes.add(caseObj.Consignor_Pincode__c);
                    //                    }
                    
                }
            }
            if (pincodes.size() > 0) {
                system.debug('pincodes'+pincodes);
                Map<String, Pincode__c> addressMap = getMappedAddress(pincodes);
                system.debug('addressMap'+addressMap);
                for (Case caseObj : newCases) {
                    if (caseObj.Origin != null) {
                        if (caseObj.Origin_Pincode__c != null && addressMap.containsKey(caseObj.Origin_Pincode__c)) {
                            Pincode__c pincodeObj = addressMap.get(caseObj.Origin_Pincode__c);
                            // caseObj.Origin_Address__c = caseObj.Origin != ConstantUtility.ORIGIN_WHATS_APP ? getAddress(pincodeObj) : caseObj.Origin_Address__c;
                            caseObj.Origin_Address__c = caseObj.Consignor_Address_Line_1__c;
                            caseObj.Origin_Branch__c = pincodeObj.Branch_Name__c;
                            caseObj.Origin_Branch_Code__c = pincodeObj.Branch_Cd__c;
                            caseObj.Origin_City__c = pincodeObj.City__c;
                            caseObj.Origin_State__c = pincodeObj.State__c;
                        }
                        if (caseObj.Destination_PinCode__c != null) {
                            Pincode__c pincodeObj = addressMap.get(caseObj.Destination_PinCode__c);
                            system.debug(addressMap.get(caseObj.Destination_PinCode__c));
                            //caseObj.Destination_Address__c = caseObj.Origin != ConstantUtility.ORIGIN_WHATS_APP ? getAddress(pincodeObj) : caseObj.Destination_Address__c;
                            system.debug('caseObj.Destination_PinCode__c'+caseObj.Destination_PinCode__c);
                            system.debug(caseObj.Consignee_Address_Line_1__c+pincodeObj);
                            caseObj.Destination_Address__c = caseObj.Consignee_Address_Line_1__c;
                            if(pincodeObj != null){
                                caseObj.Destination_Branch__c = pincodeObj.Branch_Name__c;
                                caseObj.Destination_Branch_Code__c = pincodeObj.Branch_Cd__c;
                                caseObj.Destination_City__c = pincodeObj.City__c;
                                caseObj.Destination_State__c = pincodeObj.State__c;
                            }                            
                        }
                    }
                }
            }
        } catch (Exception exp) {
            System.debug(' Exception Message :: ' + exp.getMessage() + ' Class Name : CaseTriggerHandler at Line :: ' + exp.getLineNumber());
            LoggerUtil.createErrorLog('CaseTriggerHandler', 'updateAddressFromPincode', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        }
    }
    private static Map<String, Pincode__c> getMappedAddress(Set<String> pincodes) {
        system.debug('pincodes'+pincodes);
        Map<String, Pincode__c> pincodeMap = new Map<String, Pincode__c>();
        for (Pincode__c pincode : [SELECT Pincode__c,City__c,State__c,Country__c,Branch_Name__c,PO_Name__c,Branch_Id__c,Branch_Cd__c FROM Pincode__c WHERE Pincode__c IN :pincodes limit 1000]) {
            system.debug('enter-loop');
            system.debug('pincode'+pincode);
            pincodeMap.put(pincode.Pincode__c, pincode);
        }
        system.debug('pincodeMap'+pincodeMap);
        return pincodeMap;
    }
    @TestVisible
    private static String getAddress(Pincode__c pincode) {
        String address = '';
        address += pincode.Branch_Name__c != null ? pincode.Branch_Name__c + ', ' : '';
        address += pincode.PO_Name__c != null ? pincode.PO_Name__c + ', ' : '';
        address += pincode.City__c != null ? pincode.City__c + ', ' : '';
        address += pincode.State__c != null ? pincode.State__c + ', ' : '';
        address += pincode.Pincode__c != null ? pincode.Pincode__c + ', ' : '';
        address += pincode.Country__c != null ? pincode.Country__c : '';
        //  address += pincode.Branch_Name__c != null ? '=' + pincode.Branch_Name__c : '=';
        return address;
    }
    
    
    /**
@Author          : Deepak
@Company         : TechMatrix Consulting
@Description     : This method is used to create the custom lead record to enquiry B2B type cases
@Date            : 21/10/2021
Commented this method by abhishek pardhan As per This story:- SAC-1480
*/
    // public void createLeadOnB2BCases() {
    //     try {
    //         List<Id> contactIds = new List<Id>();
    //         for (Case caseObj : newCases) {
    //             if (caseObj.Case_Nature__c == ConstantUtility.CASE_NATURE_ENQUIRY && caseObj.Case_Type__c == ConstantUtility.CASE_TYPE_B2B && caseObj.ContactId != null) {
    //                 contactIds.add(caseObj.ContactId);
    //             }
    //         }
    //         if (contactIds.size() > 0) {
    //             Map<Id, Contact> contactMap = new Map<Id, Contact>([SELECT Id,Salutation, Name,Email,MobilePhone,Phone FROM Contact WHERE Id IN :contactIds limit 1000]);
    //             List<Lead__c> customLeads = new List<Lead__c>();
    //             for (Case caseObj : newCases) {
    //                 if (caseObj.Case_Nature__c == ConstantUtility.CASE_NATURE_ENQUIRY && caseObj.Case_Type__c == ConstantUtility.CASE_TYPE_B2B && caseObj.ContactId != null) {
    //                     Lead__c lead = new Lead__c();
    //                     lead.Name = contactMap.get(caseObj.ContactId).Name;
    //                     lead.Salutation__c = contactMap.get(caseObj.ContactId).Salutation;
    //                     lead.Contact_Person_Name__c = contactMap.get(caseObj.ContactId).Name;
    //                     lead.Email__c = contactMap.get(caseObj.ContactId).Email;
    //                     lead.Phone__c = contactMap.get(caseObj.ContactId).MobilePhone;
    //                     lead.Mobile_No__c = contactMap.get(caseObj.ContactId).Phone;
    //                     lead.Type__c = caseObj.Sub_Type__c;
    //                     lead.Street__c = caseObj.Requester_Location__c;
    //                     lead.Source__c = 'Safexperience Centre';
    //                     lead.Support_Case__c = caseObj.Id;
    //                     lead.Status__c = 'Active';
    //                     customLeads.add(lead);
    //                 }
    //             }
    //             System.debug('customLeads  ' + customLeads);
    //             if (customLeads.size() > 0) {
    //                 insert customLeads;
    //             }
    //         }
    //     } catch (Exception exp) {
    //         System.debug(' Exception Message :: ' + exp.getMessage() + ' Class Name : CaseTriggerHandler at Line :: ' + exp.getLineNumber());
    //         LoggerUtil.createErrorLog('CaseTriggerHandler', 'createLeadOnB2BCases', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
    //     }
    // }
    
    /**
    @Author          : Deepak
    @Company         : TechMatrix Consulting
    @Description     : This method is used to copy the Clone transport mode to transport mode
    @Date            : 16/11/2021
    */
    public void copyModeOfTranPort() {
        try {
            for (Case caseObj : newCases) {
                if (caseObj.Transport_Mode_Clone__c != null && caseObj.Transport_Mode__c == null) {
                    caseObj.Transport_Mode__c = caseObj.Transport_Mode_Clone__c;
                }
            }
        } catch (Exception exp) {
            System.debug(' Exception Message :: ' + exp.getMessage() + ' Class Name : CaseTriggerHandler at Line :: ' + exp.getLineNumber());
            LoggerUtil.createErrorLog('CaseTriggerHandler', 'copyModeOfTranPort', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        }
    }
    
    /*public static void changePickUpTime(String pickUpToTime, String pickUpDate){
        String response = '';
        if(pickUpToTime != null && pickUpDate != null){
            Integer dd = Integer.valueOf(pickUpDate.split('/')[0]);
            Datetime currentDateTime = Datetime.now();  
            Integer currentHour = currentDateTime.hour(); 
            Integer count = 1; 
            Map<String, String> timeResponseMap = new Map<String, String>();
            if(dd == currentDateTime.day()){
                
                for(Integer temp = currentHour ; temp < 20 ; temp++){
                    //System.debug('Math.Mod(temp, 2)-->'+Math.Mod(temp, 2));
                    if(Math.Mod(temp, 2) == 0){
                        String am = 'AM';
                        String pm = 'AM';
                        
                        if(temp >= 12){
                            am = 'PM';
                        }
                        
                        if((temp+2) >= 12){
                            pm = 'PM';
                        }
                        String startTime = String.valueOf(temp);
                        if(temp  > 12 ){
                            startTime = String.valueOf(temp-12);
                        }
                        if(temp <10){
                            startTime = '0'+startTime;
                        }
                        
                        String endTime = String.valueOf(temp+2);
                        if((temp+2)  > 12 ){
                            endTime = String.valueOf((temp-10));                            
                        }
                        if(Integer.valueOf(endTime) <10){
                            endTime = '0'+endTime;
                        }
                        
                        String timeStr = startTime+':00 '+am+' - '+endTime+':00 '+pm;
                        timeResponseMap.put(String.valueOf(count), timeStr); 
                        count++;
                    }  
                }
                response = timeResponseMap.containsKey(pickUpToTime)?timeResponseMap.get(pickUpToTime):'';
            }else{
                response = ConstantUtility.SERIAL_TIME_SLOT_MAP.get(pickUpToTime);
            }
        }
        
    }*/
    /**
    @Author          : Deepak
    @Company         : TechMatrix Consulting
    @Description     : This method is used to Map the pickup date and pickup time for what's app booking
    @Date            : 24/11/2021
    */
    public void mapPickUpDateAndTime() {
        try {
            for (Case caseObj : newCases) {
                system.debug('caseObj.PickUp_To_Time__c====>'+caseObj.PickUp_To_Time__c);
                system.debug('caseObj.PickUp_Time__c====>'+caseObj.PickUp_Time__c);
                system.debug('ConstantUtility.SERIAL_TIME_SLOT_MAP====>'+ConstantUtility.SERIAL_TIME_SLOT_MAP_NEW);
                
                system.debug('pahuch gye'+ConstantUtility.SERIAL_TIME_SLOT_MAP_NEW.containsKey(caseObj.PickUp_To_Time__c));

                if (caseObj.PickUp_To_Time__c != null && caseObj.PickUp_Time__c == null && ConstantUtility.SERIAL_TIME_SLOT_MAP_NEW.containsKey(caseObj.PickUp_To_Time__c)) {
                    
                    caseObj.PickUp_Time__c = ConstantUtility.SERIAL_TIME_SLOT_MAP.get(caseObj.PickUp_To_Time__c);
                    String pickUpTime = caseObj.PickUp_To_Time__c.replace('for ','');
                    caseObj.PickUp_Time__c = pickUpTime;
                    
                }
                if (caseObj.PickUp_To_Date__c != null && caseObj.PickUp_Date__c == null) { // DD/MM/YYYY
                    Integer dd = Integer.valueOf(caseObj.PickUp_To_Date__c.split('/')[0]);
                    Integer mon = Integer.valueOf(caseObj.PickUp_To_Date__c.split('/')[1]);
                    Integer year = Integer.valueOf(caseObj.PickUp_To_Date__c.split('/')[2]);
                    caseObj.PickUp_Date__c = Date.newInstance(year, mon, dd);
                }
                if(caseObj.Origin == 'API'){
                    caseObj.Origin = 'REVERSE PICKUP';
                }
            }
        } catch (Exception exp) {
            System.debug(' Exception Message :: ' + exp.getMessage() + ' Class Name : CaseTriggerHandler at Line :: ' + exp.getLineNumber());
            LoggerUtil.createErrorLog('CaseTriggerHandler', 'mapPickUpDateAndTime', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        }
    }
    /**
    @Author          : Deepak
    @Company         : TechMatrix Consulting
    @Description     : This method is used Populate the OTRS fields
    @Date            : 25/11/2021
    */
    public void MapOTRSFields() {
        try {
            for (Case caseObj : newCases) {
               caseObj.Main_Category__c = ConstantUtility.MAIN_CATEGORY_CUSTOMER_ESCALATION;
              
                system.debug('caseObj.Main_Category__c'+caseObj.Main_Category__c);
                if (caseObj.Sub_Type__c == ConstantUtility.SUB_TYPE_PILFERRED) {
                       caseObj.Main_Category__c = ConstantUtility.MAIN_CATEGORY_CUSTOMER_ESCALATION_POST_DELIVERY; //SAC-2154
                    caseObj.Sub_Category__c = ConstantUtility.SUB_CATEGORY_SPECIAL_DELIVERY_REQUEST;
                    caseObj.Issue_Type__c = ConstantUtility.ISSUE_TYPE_OPEN_DELIVERY;
                    system.debug(caseObj.Sub_Category__c+caseObj.Issue_Type__c);
                }
                if (caseObj.Sub_Type__c == ConstantUtility.SUB_TYPE_SHORT_PART_SHIPMENT || caseObj.Sub_Type__c == ConstantUtility.SUB_TYPE_WRONG_DELIVERY
                    || caseObj.Sub_Type__c == ConstantUtility.SUB_TYPE_INTERCHANGE) 
                    {
                         caseObj.Main_Category__c = ConstantUtility.MAIN_CATEGORY_CUSTOMER_ESCALATION_POST_DELIVERY; //SAC-2154
                        caseObj.Sub_Category__c = ConstantUtility.SUB_CATEGORY_DELIVERY_PROCESS_REQUEST;
                        caseObj.Issue_Type__c = ConstantUtility.ISSUE_TYPE_WRONG_DELIVERY;
                    }
                if (caseObj.Sub_Type__c == ConstantUtility.SUB_TYPE_SHIPMENT_ON_HOLD) {
                        caseObj.Sub_Category__c = ConstantUtility.SUB_CATEGORY_WAYBILL_ESCALATION;
                        caseObj.Issue_Type__c = ConstantUtility.ISSUE_TYPE_AT_GATEWAY;
                    }
                     if (caseObj.Sub_Type__c == ConstantUtility.SUB_TYPE_DAMAGE
                  ) {
                        caseObj.Main_Category__c = ConstantUtility.MAIN_CATEGORY_CUSTOMER_ESCALATION_POST_DELIVERY; //SAC-2154
                        caseObj.Sub_Category__c = ConstantUtility.SUB_CATEGORY_WAYBILL_ESCALATION;
                        caseObj.Issue_Type__c = ConstantUtility.ISSUE_TYPE_AT_GATEWAY;
                    }
                if (caseObj.Sub_Type__c == ConstantUtility.SUB_TYPE_DELAY_IN_DELIVERY || caseObj.Sub_Type__c == ConstantUtility.SUB_TYPE_DELIVERY_NOT_DONE) {
                    // SAC- 733 || Deepika Thakur || IBM
                    caseObj.Main_Category__c = ConstantUtility.SUB_CATEGORY_WAYBILL_ESCALATION;
                    caseObj.Sub_Category__c = '';
                    //caseObj.Sub_Category__c = ConstantUtility.SUB_CATEGORY_WAYBILL_ESCALATION;
                    caseObj.Issue_Type__c = '';
                }
                if (caseObj.Sub_Type__c == ConstantUtility.SUB_TYPE_ADDRESS_CHANGE) {
                    caseObj.Sub_Category__c = ConstantUtility.SUB_CATEGORY_DELIVERY_PROCESS_REQUEST;
                    caseObj.Issue_Type__c = ConstantUtility.ISSUE_TYPE_ADDRESS_CHANGE;
                }
                if (caseObj.Sub_Type__c == ConstantUtility.SUB_TYPE_DOD_DACC_CANCELLATION) {
                    caseObj.Sub_Category__c = ConstantUtility.SUB_CATEGORY_DELIVERY_PROCESS_REQUEST;
                    caseObj.Issue_Type__c = ConstantUtility.ISSUE_TYPE_DOD_CANCELLATION;
                }
                if (caseObj.Sub_Type__c == ConstantUtility.SUB_TYPE_SHIPMENT_RE_BOOKING) {
                    caseObj.Sub_Category__c = ConstantUtility.SUB_CATEGORY_DELIVERY_PROCESS_REQUEST;
                    caseObj.Issue_Type__c = ConstantUtility.ISSUE_TYPE_RE_BOOKING;
                }
                
                
            }
        } catch (Exception exp) {
            System.debug(' Exception Message :: ' + exp.getMessage() + ' Class Name : CaseTriggerHandler at Line :: ' + exp.getLineNumber());
            LoggerUtil.createErrorLog('CaseTriggerHandler', 'MapOTRSFields', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        }
    }
    /**
    @Author          : Deepak
    @Company         : TechMatrix Consulting
    @Description     : This method is used to Map the contact information to consignor
    @Date            : 24/11/2021
    */
    public void mapConsignorDetails() {
        try {
            Set<Id> contactIds = new Set<Id>();
            for (Case caseObj : newCases) {
                if (caseObj.ContactId != null) {
                    contactIds.add(caseObj.ContactId);
                }
            }
            if (contactIds.size() > 0) {
                Map<Id, Contact> contactMap = new Map<Id, Contact>([SELECT Name,Email,Phone,MobilePhone FROM Contact WHERE Id IN :contactIds limit 1000]);
                for (Case caseObj : newCases) {
                    if (caseObj.ContactId != null) {
                        if (caseObj.Consignor_Email__c == null) {
                            caseObj.Consignor_Email__c = contactMap.get(caseObj.ContactId).Email;
                        }
                        if (caseObj.Consignor_Name__c == null) {
                            caseObj.Consignor_Name__c = contactMap.get(caseObj.ContactId).Name;
                        }
                        if (caseObj.Consignor_Phone__c == null) {
                            caseObj.Consignor_Phone__c = contactMap.get(caseObj.ContactId).MobilePhone;
                        }
                    }
                }
            }
        } catch (Exception exp) {
            System.debug(' Exception Message :: ' + exp.getMessage() + ' Class Name : CaseTriggerHandler at Line :: ' + exp.getLineNumber());
            LoggerUtil.createErrorLog('CaseTriggerHandler', 'mapConsignorDetails', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        }
    }
    
    /**
    @Author          : Deepak
    @Company         : TechMatrix Consulting
    @Description     : This method is used Check to Map the field for duplicate check Case
    @Date            : 30/11/2021
    */
    public void mapUniqueField() {
        try {
            for (Case caseObj : newCases) {
                caseObj.Unique_Field__c = getUniqueString(caseObj);
            }
        } catch (Exception exp) {
            System.debug(' Exception Message :: ' + exp.getMessage() + ' Class Name : CaseTriggerHandler at Line :: ' + exp.getLineNumber());
            LoggerUtil.createErrorLog('CaseTriggerHandler', 'mapUniqueField', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        }
    }
    /**
    @Author          : Deepak
    @Company         : TechMatrix Consulting
    @Description     : This method is used Check to Duplicate Case
    @Date            : 30/11/2021
    */
    public void checkDuplicateCase() {
        try {
            Set<String> uniqueStrings = new Set<String>();
            for (Case caseObj : newCases) {
                if (caseObj.Case_Nature__c != null && ( caseObj.Case_Nature__c == ConstantUtility.CASE_NATURE_COMPLAINT)) {       //caseObj.Case_Nature__c == ConstantUtility.CASE_NATURE_REQUEST ||
                    if (Trigger.isInsert || (Trigger.isUpdate && caseObj.Unique_Field__c != oldCasesMap.get(caseObj.Id).Unique_Field__c)) {
                        uniqueStrings.add(getUniqueString(caseObj));
                    }
                }
            }
            if (uniqueStrings.size() > 0) {
                Set<String> oldUniqueStrings = new Set<String>();
                for (Case oldCase : [SELECT Id,CaseNumber,Unique_Field__c FROM Case WHERE Unique_Field__c IN:uniqueStrings AND IsClosed = false limit 1000]) {
                    oldUniqueStrings.add(oldCase.Unique_Field__c);
                }
                
                for (Case caseObj : newCases) {
                    if (caseObj.Case_Nature__c != null && ( caseObj.Case_Nature__c == ConstantUtility.CASE_NATURE_COMPLAINT)) {    //caseObj.Case_Nature__c == ConstantUtility.CASE_NATURE_REQUEST ||
                        String uniqueString = getUniqueString(caseObj);
                        if (oldUniqueStrings.contains(uniqueString)) {
                            caseObj.addError('Duplicate Open Case Found with Case Nature, Case Type and Waybill #');
                        }
                    }
                }
            }
        } catch (Exception exp) {
            System.debug(' Exception Message :: ' + exp.getMessage() + ' Class Name : CaseTriggerHandler at Line :: ' + exp.getLineNumber());
            LoggerUtil.createErrorLog('CaseTriggerHandler', 'mapUniqueField', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        }
    }
    
    public static String getUniqueString(Case caseObj) {
        String unique = '';
        if (caseObj.Case_Nature__c != null && caseObj.Case_Type__c != null && caseObj.WaybillNo__c != null) {
            unique += caseObj.Case_Nature__c + '_';
            unique += caseObj.Case_Type__c + '_';
            unique += caseObj.WaybillNo__c ;
        }
        return unique;
    }
        
    /**
    @Author          : Deepak
    @Company         : TechMatrix Consulting
    @Description     : This method is used to send the Custom notification to the Owner of the case.
    @Date            : 30/11/2021
    */
    public void sendCaseAssignmentNotification() {
        try {
            Map<Id, Id> caseIdVsUserIdMap = new Map<Id, Id>();
            for (Case caseObj : newCases) {
                // On Insert
                if (Trigger.isInsert && String.valueOf(caseObj.OwnerId).startsWith('005')) {
                    caseIdVsUserIdMap.put(caseObj.Id, caseObj.OwnerId);
                }
                // On update
                if (Trigger.isUpdate && String.valueOf(caseObj.OwnerId).startsWith('005') && caseObj.OwnerId != oldCasesMap.get(caseObj.Id).OwnerId) {
                    caseIdVsUserIdMap.put(caseObj.Id, caseObj.OwnerId);
                }
            }
            if (!caseIdVsUserIdMap.isEmpty()) {
                CustomNotificationType type = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = :System.Label.Case_Assignment_Notification_Name limit 1000];
                for (Id caseId : caseIdVsUserIdMap.keySet()) {
                    Messaging.CustomNotification notification = new Messaging.CustomNotification();
                    notification.setTitle(System.Label.Case_Assignment_Notification_Title);
                    notification.setBody(System.Label.Case_Assignment_Notification_Body);
                    notification.setSenderId(UserInfo.getUserId());
                    notification.setNotificationTypeId(type.id);
                    notification.setTargetId(caseId); // target object id
                    if (!Test.isRunningTest()) {
                    notification.send(new Set<String>{
                        caseIdVsUserIdMap.get(caseId)
                            });
                        }
                }
            }
        } catch (Exception exp) {
            System.debug(' Exception Message :: ' + exp.getMessage() + ' Class Name : CaseTriggerHandler at Line :: ' + exp.getLineNumber());
            LoggerUtil.createErrorLog('CaseTriggerHandler', 'sendCaseAssignmentNotification', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        }
    }

        // Prevent manual Freshservice closure.
    private void preventManualFreshserviceClosure() {
        Boolean hasPermission = FeatureManagement.checkPermission('Allow_Freshservice_Case_Closure');

        for (Case caseObj : newCases) {
            if (
                String.isNotBlank(caseObj.Fresh_Service_Ticket_No__c) &&
                caseObj.Status != oldCasesMap.get(caseObj.Id).Status &&
                (caseObj.Status == ConstantUtility.COMPLETED || caseObj.Status == ConstantUtility.CLOSED) &&
                !Freshservice_UtilClass.allowFreshserviceCaseClosure &&
                !hasPermission
            ) {
                caseObj.Status.addError('This Case can only be closed from Freshservice.');
            }
        }
    }


    /**
    @Author          : Deepak
    @Company         : TechMatrix Consulting
    @Description     : This method is used to update the checkbox if case cancelled or closed
    @Date            : 30/11/2021
    */
    public void updateClosedOrCancelledCheck() {
        try {
            for (Case caseObj : newCases) {
                if ((caseObj.Status == ConstantUtility.CLOSED || caseObj.Status == ConstantUtility.CANCELLED) && caseObj.Status != oldCasesMap.get(caseObj.Id).Status) {
                    caseObj.Is_Closed_or_Cancelled__c = true;
                }
            }
        } catch (Exception exp) {
            System.debug(' Exception Message :: ' + exp.getMessage() + ' Class Name : CaseTriggerHandler at Line :: ' + exp.getLineNumber());
            LoggerUtil.createErrorLog('CaseTriggerHandler', 'updateClosedOrCancelledCheck', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        }
    }
    
    public void sendCaseToProton() {
         
        try {
            for(case newCase : newCases){
                if(newCase.Case_Type__c == 'Booking Request' && oldCasesMap.get(newCase.Id).Status == 'New' && newCase.Status == 'Created'){
                    // String Token = ProtonCasePostAPI.getProtonAccessToken(newCase.Id);
                    ProtonCasePostAPI.createPreBooking(newCase.Id); //,Token)
                }else if(newCase.Case_Type__c == 'Booking Request' && newCase.Status == 'Created' && oldCasesMap.get(newCase.Id).Pre_Booking_Id__c != ''){
                    // String Token = ProtonCasePostAPI.getProtonAccessToken();
                    ProtonCasePostAPI.updatePreBooking(newCase.Id ); //,Token);
                }
            }
        } catch (Exception exp) {
            System.debug(' Exception Message :: ' + exp.getMessage() + ' Class Name : sendCaseToProton at Line :: ' + exp.getLineNumber());
            LoggerUtil.createErrorLog('CaseTriggerHandler', 'sendCaseToProton', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        }
    }
    //Send mail on the case status completed.
   /* public void sendEmailOnCaseCompleted() {
        system.debug('newCases'+newCases);
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        try{
            for(case newCase : newCases){
                if((oldCasesMap.get(newCase.Id).Status == 'New' || oldCasesMap.get(newCase.Id).Status == 'Created' || oldCasesMap.get(newCase.Id).Status == 'In Progress' || oldCasesMap.get(newCase.Id).Status == 'Merged' || oldCasesMap.get(newCase.Id).Status == 'Cancelled') && newCase.Status == 'Completed'){
                    List<String> toAddressList = new List<String>();
                    OrgWideEmailAddress[] owea = [select Id,Address from OrgWideEmailAddress where Address = 'noreply@safexpress.com'];
                    system.debug('owea.get(0).Id'+owea.get(0).Id);
                    if(newCase.ContactEmail != null){
                        toAddressList.add(newCase.ContactEmail);
                    }else{
                        toAddressList.add(newCase.SuppliedEmail);
                    }
                    String conName;
                    if(newCase.ContactId != null){
                        conName = [Select Id,Name From Contact Where Id=:newCase.ContactId].Name;
                    }else{
                        conName = newCase.SuppliedEmail;
                        String[] strArr = conName.split('@');
                        conName = strArr[0];
                    }
                    String body = '<html><body>Hello '+ conName +',<br/><br/>'+'Your case no '+ newCase.CaseNumber +' has been completed.<br/> Customer satisfaction is our highest priority. Feel Free to talk to us about any queries or feedback on our Tollfree number 1800 113 113.<br/><br/> Thank You<br/>Safexpress';
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setOrgWideEmailAddressId(owea.get(0).Id);
                    mail.setToAddresses(toAddressList);
                    mail.setSubject('Case Completed Details');
                    mail.setHtmlBody(body);
                    mail.setSaveAsActivity(false);
                    mail.setWhatId(newCase.Id);
                    //mail.setPlainTextBody('Welcome to safexpress');
                    emailList.add(mail);
                }
            }
            if(!emailList.isEmpty()){
                system.debug('emailList'+emailList);
                Messaging.sendEmail(emailList);
                //List<Messaging.SendEmailResult> errList = Messaging.sendEmail(emailList);
                //System.debug(errList);
            }
        }
        catch(Exception exp){
            System.debug(' Exception Message :: ' + exp.getMessage() + 'getLineNumber:: ' + exp.getLineNumber());
        }
    }*/
    //Validation on callback time
    public void callBackTimeValidation() {
       /* try {
            for(case newCase : newCases){
                system.debug('newCase'+newCase);
                String ampm = System.now().format('a');
                String timenow = System.now().format('HH');
                if(newCase.Preferred_CallBack_Time__c != null){
                    if(newCase.Preferred_CallBack_Date__c == system.today()){
                        String data = ConstantUtility.TIME_SLOT_MAP.get(newCase.Preferred_CallBack_Time__c).substring(0,2);
                        system.debug(Integer.valueof(timenow));
                        system.debug(Integer.valueof(data));
                        if(Integer.valueof(timenow) >= Integer.valueof(data)){
                            system.debug('enter');
                            newCase.Preferred_CallBack_Time__c.adderror( 'Please select future time.' );
                        }
                    }
                }
            }
        }catch (Exception exp) {
            System.debug(' Exception Message :: ' + exp.getMessage() + ' Class Name : sendCaseToProton at Line :: ' + exp.getLineNumber());
        }*/
        try {
            for(case newCase : newCases){
                system.debug('newCase'+newCase);
                String ampm = System.now().format('a');
                String timenow = System.now().format('hh');
                if(newCase.Preferred_CallBack_Time__c != null){
                    if(newCase.Preferred_CallBack_Date__c == system.today()){
                        String callTimeAmPm = newCase.Preferred_CallBack_Time__c.substring(17,19);
                        String callTime = newCase.Preferred_CallBack_Time__c.substring(11,13);
                        if(callTimeAmPm == 'AM'){
                            if(ampm == 'PM'){
                                system.debug('ampm');
                                if(Integer.valueof(callTime) >= Integer.valueof(timenow)){
                                    system.debug('pm=='+Integer.valueof(callTime));
                                    newCase.Preferred_CallBack_Time__c.adderror( 'Please select future time.' );
                                }
                            }else{
                                if(Integer.valueof(callTime) <= Integer.valueof(timenow)){
                                    system.debug('am=='+Integer.valueof(callTime));
                                    newCase.Preferred_CallBack_Time__c.adderror( 'Please select future time.' );
                                }
                            }
                        }else{
                            if(ampm != 'AM'){
                                if(callTime == '12'){
                                    system.debug('12');
                                    newCase.Preferred_CallBack_Time__c.adderror( 'Please select future time.' );
                                }
                                else{
                                    if(timenow == '12'){
                                        if(Integer.valueof(callTime) >= Integer.valueof(timenow)){
                                            system.debug('callTime'+Integer.valueof(callTime));
                                            system.debug('timenow'+Integer.valueof(timenow));
                                            newCase.Preferred_CallBack_Time__c.adderror( 'Please select future time.' );
                                        }
                                    }else{
                                        if(Integer.valueof(callTime) <= Integer.valueof(timenow)){
                                            system.debug('call'+Integer.valueof(callTime));
                                            newCase.Preferred_CallBack_Time__c.adderror( 'Please select future time.' );
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }catch (Exception exp) {
            System.debug(' Exception Message :: ' + exp.getMessage() + ' Class Name : sendCaseToProton at Line :: ' + exp.getLineNumber());
        }
    }
    //check validation on current and future date of callback date.
    public void checkCallBackDate() {
        try {
            for(case newCase : newCases){
                if(oldCasesMap.get(newCase.Id).Status == 'New' && (newCase.Status == 'Completed' || newCase.Status == 'Created'|| newCase.Status == 'In Progress'|| newCase.Status == 'Merged'|| newCase.Status == 'Cancelled')){
                    system.debug('5');
                }else if(oldCasesMap.get(newCase.Id).Status == 'Created' && (newCase.Status == 'Completed' || newCase.Status == 'New'|| newCase.Status == 'In Progress'|| newCase.Status == 'Merged'|| newCase.Status == 'Cancelled')){
                    system.debug('1');
                }else if(oldCasesMap.get(newCase.Id).Status == 'In Progress' && (newCase.Status == 'Completed' || newCase.Status == 'Created'|| newCase.Status == 'New'|| newCase.Status == 'Merged'|| newCase.Status == 'Cancelled')){
                    system.debug('2');
                }else if(oldCasesMap.get(newCase.Id).Status == 'Merged' && (newCase.Status == 'Completed' || newCase.Status == 'Created'|| newCase.Status == 'In Progress'|| newCase.Status == 'New'|| newCase.Status == 'Cancelled')){
                    system.debug('3');
                }else if(oldCasesMap.get(newCase.Id).Status == 'Cancelled' && (newCase.Status == 'Completed' || newCase.Status == 'Created'|| newCase.Status == 'In Progress'|| newCase.Status == 'Merged'|| newCase.Status == 'New')){
                    system.debug('4');
                }else if(oldCasesMap.get(newCase.Id).Status == 'Completed' && (newCase.Status == 'Cancelled' || newCase.Status == 'Created'|| newCase.Status == 'In Progress'|| newCase.Status == 'Merged'|| newCase.Status == 'New')){
                    
                }else{
                    if((oldCasesMap.get(newCase.Id).Preferred_CallBack_Date__c == null && newCase.Preferred_CallBack_Date__c != null) || (oldCasesMap.get(newCase.Id).Preferred_CallBack_Date__c != null && oldCasesMap.get(newCase.Id).Preferred_CallBack_Date__c != newCase.Preferred_CallBack_Date__c)){
                        if(newCase.Preferred_CallBack_Date__c  < system.today()){
                            system.debug('newCase.Preferred_CallBack_Date__c'+newCase.Preferred_CallBack_Date__c);
                            newCase.Preferred_CallBack_Date__c.adderror( 'Please select today or future date.' );
                        }
                    }
                }
            }
        }
        catch (Exception exp) {
            System.debug(' Exception Message :: ' + exp.getMessage() + ' Class Name : CaseTriggerHandler at Line :: ' + exp.getLineNumber());
            LoggerUtil.createErrorLog('CaseTriggerHandler', 'updateClosedOrCancelledCheck', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        }
    }
    //check validation on current and future date of callback date.
    public void checkCallBackDateBeforeInsert() {
        try {
            for(case newCase : newCases){
                if(newCase.Preferred_CallBack_Date__c != null){
                    if(newCase.Preferred_CallBack_Date__c  < system.today()){
                        newCase.Preferred_CallBack_Date__c.adderror( 'Please select today or future date.' );
                    }
                }
            }
        }
        catch (Exception exp) {
            System.debug(' Exception Message :: ' + exp.getMessage() + ' Class Name : CaseTriggerHandler at Line :: ' + exp.getLineNumber());
            LoggerUtil.createErrorLog('CaseTriggerHandler', 'updateClosedOrCancelledCheck', exp.getTypeName(), exp.getMessage(), exp.getStackTraceString(), null);
        }
    }
        
    /**
    @Author          : K SANSI - SCI-164
    @Company         : IBM
    @Description     : This method is used to send the case to Propeli for PreBookingId, 
                        if case is created via Website, Whatsup, Chat-Board, DigiSpace, SFDC
    @Date            : 20/09/2023
    */
    
    public void sendCaseToPropeli(){
        List<String> caseIds = new List<String>();
        for (Case caseObj : this.newCases) {
             System.debug('caseObj --> '+caseObj);
            if(
                (caseObj.PropelI_PreBooking_Id__c == null || caseObj.PropelI_PreBooking_Id__c == '') &&
                (caseObj.Pre_Booking_Count__c == null || caseObj.Pre_Booking_Count__c < 3) &&
                /*caseObj.Origin != 'IConnect' &&*/ 
                caseObj.Case_Nature__c == 'Request' && 
                caseObj.Case_Type__c == 'Booking Request' &&                
                ( /*(caseObj.Origin == 'Salesforce') || */
                 (caseObj.Status == 'In Progress' && caseObj.Status != oldCasesMap.get(caseObj.Id).Status )  ) 
            ){
                caseIds.add(caseObj.Id);
            }             
        }
        System.debug('caseIds --> '+caseIds);
        if(!caseIds.isEmpty()){
            
            //System.enqueueJob(new PreBookingAPIQueueable(caseIds)); 
            IntegrationUtility.CreateIntegrationLog createITLogObject = new IntegrationUtility.CreateIntegrationLog();
            createITLogObject.objectName = 'Case'; 
            createITLogObject.recordIdList = caseIds;
            createITLogObject.operationType = System.Label.OperationType_PropelI_CaseCreation; 
            if (!Test.isRunningTest()) {
            IntegrationUtility.createIntegrationTransaction(createITLogObject);
        }
    }
    }
    
    
}