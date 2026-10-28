/**
 * Description		:		Journey View component controller Helper
 * Created By       :       Deepika
 * Created Date     :       jan, 2025
 * Last Modified on :
 * Jira Ticket      :       https://safexpress.atlassian.net/browse/SAC-1166
 **/
({
    MAX_FILE_SIZE: 4500000, //Max file size 4.5 MB 
    CHUNK_SIZE: 750000,      //Chunk Max size 750Kb 
    LoadEvent : function(component, event, helper) {
        var action = component.get('c.GetEventList');
        action.setParams({            
            JourneyId : component.get("v.recordId")
        });
        action.setCallback(this, function(response){
            var responseValue = response.getReturnValue();
            console.log('responsevalue', responseValue);
            component.set('v.EventList', responseValue);
        });
        $A.enqueueAction(action, false);
    },
    // Method to load all the journeys of the selected month and to get total number of journey, Amount, event,distance
    LoadTableMonth1 : function(component, event, helper){
        component.set("v.OpenIf", true);             
        var StDate = component.get('v.Month');
        var result = new Date();
        var CurrentDate = $A.localizationService.formatDate(result, "YYYY-MM"); 
        var action = component.get("c.getCurrentUserProfileName");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var profileName = response.getReturnValue();
                console.log('profileName', profileName);
                //alert(profileName);
                
                if(profileName === 'Corporate salesforce team' /*||
                   profileName === 'Conveyance Team'*/) {
                    component.set("v.AuditSectionVisibility", true);
                }else{
                    component.set("v.AuditSectionVisibility", false);
                    var action = component.get("c.getCurrentUserCustomPermissions");
                    action.setCallback(this, function(response) {
                        var state = response.getState();
                        if (state === "SUCCESS") {
                            var hasCustomPermission = response.getReturnValue();
                            //alert(hasCustomPermission);
                            if(hasCustomPermission) {
                                component.set("v.AuditSectionVisibility", true);
                            }else{
                                component.set("v.AuditSectionVisibility", false);
                            }
                        } else {
                        }
                    });
                    $A.enqueueAction(action); 
                }
            } else {
                console.error("Failed to get profile name: ", response.getError());
            }
        });
        $A.enqueueAction(action);  
        
         
        
        if(StDate < CurrentDate){
            component.set("v.ButtonDisable", false);
            // alert('Done');
        }else{
            component.set("v.ButtonDisable", true);
            // alert('Note Done');
        }
        
        var array = StDate.split('-');
        var Yeara = array[0];
        var Montha = array[1];
        // alert (typeof "Yeara1");
        
        var action1 = component.get('c.GetJourneyListToApprove');
        action1.setParams({
            Year : Yeara,
            Month : Montha,
            CurrentUserId : $A.get("$SObjectType.CurrentUser.Id")
        });
        action1.setCallback(this, function(response){
            var state = response.getState();
            var responseValue = response.getReturnValue();
            // console.log('responsevalue', responseValue);
            component.set('v.JourneyList', responseValue);
        });
        $A.enqueueAction(action1, false);
        
        var action2 = component.get('c.GetJourneyListApproved');
        action2.setParams({
            Year : Yeara,
            Month : Montha,
            CurrentUserId : $A.get("$SObjectType.CurrentUser.Id")
        });
        action2.setCallback(this, function(response){
            var state = response.getState();
            var responseValue = response.getReturnValue();
            // console.log('responsevalue', responseValue);
            component.set('v.myJourneyListApproved', responseValue);
        });
        $A.enqueueAction(action2, false);
        

        var action3 = component.get('c.GetJourneyListRejected');
        action3.setParams({
            Year : Yeara,
            Month : Montha,
            CurrentUserId : $A.get("$SObjectType.CurrentUser.Id")
        });
        action3.setCallback(this, function(response){
            var state = response.getState();
            var responseValue = response.getReturnValue();
            // console.log('responsevalue', responseValue);
            component.set('v.myJourneyListRejected', responseValue);
        });
        $A.enqueueAction(action3, false);
        

        var action4 = component.get('c.GetJourneyListToBeSubmitted');
        console.log('responsevalue', Yeara +' : '+Montha);
        action4.setParams({
            Year : Yeara,
            Month : Montha,
            CurrentUserId : $A.get("$SObjectType.CurrentUser.Id")
        });
        action4.setCallback(this, function(response){
            var state = response.getState();
            var responseValue = response.getReturnValue();
            console.log('responsevalue', responseValue);
            component.set('v.myJourneyListToBeSubmitted', responseValue);
        });
        $A.enqueueAction(action4, false);
        

        var action5 = component.get('c.GetJourneyListNotToBeClaimed');
        action5.setParams({
            Year : Yeara,
            Month : Montha,
            CurrentUserId : $A.get("$SObjectType.CurrentUser.Id")
        });
        action5.setCallback(this, function(response){
            var state = response.getState();
            var responseValue = response.getReturnValue();
            // console.log('responsevalue', responseValue);
            component.set('v.myJourneyListNotToBeClaimed', responseValue);
        });
        $A.enqueueAction(action5, false);
        


        var act = component.get('c.GetJourneyCount');
        // alert('2nd method');
        act.setParams({
            Year : Yeara,
            Month : Montha,
            CurrentUserId : $A.get("$SObjectType.CurrentUser.Id")
        });
        act.setCallback(this, function(response){
            var responseValue = response.getReturnValue();
            // console.log('responsevalue', responseValue);
            component.set('v.TotalJourney', responseValue);
        });
        $A.enqueueAction(act, false);
        
        
        var act1 = component.get('c.GetJourneyTotalAmount');
        // alert('2nd method');
        act1.setParams({
            Year : Yeara,
            Month : Montha,
            CurrentUserId : $A.get("$SObjectType.CurrentUser.Id")
        });
        act1.setCallback(this, function(response){
            var responseValue = response.getReturnValue();
            // console.log('responsevalue', responseValue);
            component.set('v.TotalAmount', responseValue);
        });
        $A.enqueueAction(act1, false);
        
        var act2 = component.get('c.GetJourneyTotalEvent');
        // alert('2nd method');
        act2.setParams({
            Year : Yeara,
            Month : Montha,
            CurrentUserId : $A.get("$SObjectType.CurrentUser.Id")
        });
        act2.setCallback(this, function(response){
            var responseValue = response.getReturnValue();
            // console.log('responsevalue', responseValue);
            component.set('v.TotalEvent', responseValue);
        });
        $A.enqueueAction(act2, false);
        
        var act3 = component.get('c.GetJourneyTotalDistance');
        // alert('2nd method');
        act3.setParams({
            Year : Yeara,
            Month : Montha,
            CurrentUserId : $A.get("$SObjectType.CurrentUser.Id")
        });
        act3.setCallback(this, function(response){
            var responseValue = response.getReturnValue();
            // console.log('responsevalue', responseValue);
            component.set('v.TotalDistance', responseValue);
        });
        $A.enqueueAction(act3, false);
        
        var act4 = component.get('c.GetJourneyTotalApprovedAmount');
        // alert('2nd method');
        act4.setParams({
            Year : Yeara,
            Month : Montha,
            CurrentUserId : $A.get("$SObjectType.CurrentUser.Id")
        });
        act4.setCallback(this, function(response){
            var responseValue = response.getReturnValue();
            // console.log('responsevalue', responseValue);
            component.set('v.TotalApprovedAmount', responseValue);
        });
        $A.enqueueAction(act4, false);
    },
    LoadTableMonthTeam : function(component, event, helper){
        var monthValue = component.get('v.Month1');
        var selectedDateValue = component.get('v.SelectedDate');
        var Yeara, Montha, dayVal;
        
        if (!$A.util.isEmpty(selectedDateValue)) {
            // If day is selected, split from selected date
            let dayParts = selectedDateValue.split('-');
            Yeara = dayParts[0];
            Montha = dayParts[1];
            dayVal = dayParts[2];
        } else if (!$A.util.isEmpty(monthValue)) {
            // If only month is selected
            let monthParts = monthValue.split('-');
            Yeara = monthParts[0];
            Montha = monthParts[1];
            dayVal = null; // No specific day
        }
        
       // alert('Selected Values: Year: ' + Yeara + ' Month: ' + Montha + ' Day: ' + dayVal);

        this.loadTabData(component, "v.tab1CurrentPage", "GetJourneyListMonthTeam", "v.JourneyListTeam");
        this.loadTabData(component, "v.tab2CurrentPage", "GetJourneyListMonthTeamApproved", "v.JourneyListApproved");
        this.loadTabData(component, "v.tab3CurrentPage", "GetJourneyListMonthTeamRejected", "v.JourneyListRejected");
        this.loadTabData(component, "v.tab4CurrentPage", "GetJourneyListMonthTeamNotToBeClaimed", "v.JourneyListNotToBeClaimed");
        this.loadTabData(component, "v.tab5CurrentPage", "GetJourneyListMonthTeamToBeSubmitted", "v.JourneyListToBeSubmitted");

        const pageSize = 10;
        const tabConfigs = [
            { method: 'GetJourneyListMonthTeamCount', totalCountAttr: 'v.tab1TotalCount', totalPagesAttr: 'v.tab1TotalPages' },
            { method: 'GetJourneyListMonthTeamApprovedCount', totalCountAttr: 'v.tab2TotalCount', totalPagesAttr: 'v.tab2TotalPages' },
            { method: 'GetJourneyListMonthTeamRejectedCount', totalCountAttr: 'v.tab3TotalCount', totalPagesAttr: 'v.tab3TotalPages' },
            { method: 'GetJourneyListMonthTeamNotToBeClaimedCount', totalCountAttr: 'v.tab4TotalCount', totalPagesAttr: 'v.tab4TotalPages' },
            { method: 'GetJourneyListMonthTeamToBeSubmittedCount', totalCountAttr: 'v.tab5TotalCount', totalPagesAttr: 'v.tab5TotalPages' }
        ];
        
        tabConfigs.forEach(config => {
            let action = component.get(`c.${config.method}`);
        action.setParams({
            Year: Yeara,
            Month: Montha,
            Day: dayVal,
            CurrentUserId: component.get('v.SelectedUser')
        });
        action.setCallback(this, function(response) {
            if (response.getState() === "SUCCESS") {
                let totalCount = response.getReturnValue();
                component.set(config.totalCountAttr, totalCount);
                let totalPages = Math.max(1, Math.ceil(totalCount / pageSize));
                component.set(config.totalPagesAttr, totalPages);
            } else {
                console.error(`Error fetching count for ${config.method}:`, response.getError());
            }
        });
        $A.enqueueAction(action);
    });

        
        var act = component.get('c.GetJourneyCountTeam');   
        // alert('2nd method');
        act.setParams({
            Year : Yeara,
            Month : Montha,
            Day : dayVal,
            CurrentUserId : component.get('v.SelectedUser')
        });
        act.setCallback(this, function(response){
            var responseValue = response.getReturnValue();
            // console.log('responsevalue', responseValue);
            component.set('v.TotalJourneyTeam', responseValue);
        });
        $A.enqueueAction(act, false);
        
        
        var act1 = component.get('c.GetJourneyTotalAmountTeam');
        // alert('2nd method');
        act1.setParams({
            Year : Yeara,
            Month : Montha,
            Day : dayVal,
            CurrentUserId : component.get('v.SelectedUser')
        });
        act1.setCallback(this, function(response){
            var responseValue = response.getReturnValue();
            // console.log('responsevalue', responseValue);
            component.set('v.TotalAmountTeam', responseValue);
        });
        $A.enqueueAction(act1, false);
        
        var act2 = component.get('c.GetJourneyTotalEventTeam');
        // alert('2nd method');
        act2.setParams({
            Year : Yeara,
            Month : Montha,
            Day : dayVal,
            CurrentUserId : component.get('v.SelectedUser')
        });
        act2.setCallback(this, function(response){
            var responseValue = response.getReturnValue();
            // console.log('responsevalue', responseValue);
            component.set('v.TotalEventTeam', responseValue);
        });
        $A.enqueueAction(act2, false);
        
        var act3 = component.get('c.GetJourneyTotalDistanceTeam');
        // alert('2nd method');
        act3.setParams({
            Year : Yeara,
            Month : Montha,
            Day : dayVal,
            CurrentUserId : component.get('v.SelectedUser')
        });
        act3.setCallback(this, function(response){
            var responseValue = response.getReturnValue();
            // console.log('responsevalue', responseValue);
            component.set('v.TotalDistanceTeam', responseValue);
        });
        $A.enqueueAction(act3, false);  
        
        /*var act4 = component.get('c.GetUserData');
         alert('2nd method');
        act4.setParams({
            userId : component.get('v.SelectedUser')
        });
        act4.setCallback(this, function(response){
            var responseValue = response.getReturnValue();
            // console.log('responsevalue', responseValue);
            component.set('v.SelectedUserProfile', responseValue);
        });
        $A.enqueueAction(act4, false);*/
        
        var act5 = component.get('c.GetJourneyTotalApprovedAmountTeam');
        // alert('2nd method');
        act5.setParams({
            Year : Yeara,
            Month : Montha,
            Day : dayVal,
            CurrentUserId : component.get('v.SelectedUser')
        });
        act5.setCallback(this, function(response){
            var responseValue = response.getReturnValue();
            // console.log('responsevalue', responseValue);
            component.set('v.TotalApprovedAmountTeam', responseValue);
        });
        $A.enqueueAction(act5, false);  
        
    },
    
    updateJourneyRecord: function (component, journeyId, objectName, fieldName, fieldValue, auditedValue) {
      //  var action = component.get("c.updateJourney"); // Call Apex method
        var action = component.get("c.publishEventDetails"); // Call Apex method
       // alert('JOURNEY ::: '+auditedValue+' ::: '+fieldValue);

        action.setParams({
            objectId: journeyId,
            objectName: objectName,
            fieldName: fieldName,
            fieldValue : fieldValue,
            audited : auditedValue
        });
        
        action.setCallback(this, function(response) {
            let state = response.getState();
            if (state === "SUCCESS") {
                let result = response.getReturnValue(); // has result.status & result.message
                
                let toastEvent = $A.get("e.force:showToast");
                if (toastEvent) {
                    toastEvent.setParams({
                        title: result.status === "success" ? "Success" : "Error",
                        message: result.message,
                        type: result.status
                    });
                    toastEvent.fire();
                } else {
                    alert(result.message); // fallback
                }
            } else if (state === "ERROR") {
                let errors = response.getError();
                let message = (errors && errors[0] && errors[0].message) || "Unknown error";
                alert("Exception: " + message);
            }
        });
        $A.enqueueAction(action);
    },
    
    loadTab1Data: function(component) {
        this.loadTabData(component, "v.tab1CurrentPage", "GetJourneyListMonthTeam", "v.JourneyListTeam");
    },
    loadTab2Data: function(component) {
        this.loadTabData(component, "v.tab2CurrentPage", "GetJourneyListMonthTeamApproved", "v.JourneyListApproved");
    },
    loadTab3Data: function(component) {
        this.loadTabData(component, "v.tab3CurrentPage", "GetJourneyListMonthTeamRejected", "v.JourneyListRejected");
    },
    loadTab4Data: function(component) {
        this.loadTabData(component, "v.tab4CurrentPage", "GetJourneyListMonthTeamNotToBeClaimed", "v.JourneyListNotToBeClaimed");
    },
    loadTab5Data: function(component) {
        this.loadTabData(component, "v.tab5CurrentPage", "GetJourneyListMonthTeamToBeSubmitted", "v.JourneyListToBeSubmitted");
    },
        
        loadTabData: function(component, pageAttr, apexMethod, targetAttr) {
            component.set("v.isLoading", true);
            let pageNumber = component.get(pageAttr);
            let monthValue = component.get('v.Month1');
            let selectedDateValue = component.get('v.SelectedDate');
            let Yeara, Montha, dayVal;
            
            if (!$A.util.isEmpty(selectedDateValue)) {
                let dayParts = selectedDateValue.split('-');
                Yeara = dayParts[0];
                Montha = dayParts[1];
                dayVal = dayParts[2];
            } else if (!$A.util.isEmpty(monthValue)) {
                let monthParts = monthValue.split('-');
                Yeara = monthParts[0];
                Montha = monthParts[1];
                dayVal = null;
            }
            
            let action = component.get(`c.${apexMethod}`);
            action.setParams({
                pageSize: 10,
                pageNumber: pageNumber,
                Year: Yeara,
                Month: Montha,
                Day: dayVal,
                CurrentUserId: component.get('v.SelectedUser')
            });
            action.setCallback(this, function(response) {
                try {
                    if (response.getState() === "SUCCESS") {
                        component.set(targetAttr, response.getReturnValue());
                    } else {
                        console.error(`Error in ${apexMethod}:`, response.getError());
                    }
                } catch (e) {
                    console.error('Exception in callback:', e);
                } finally {
                    component.set("v.isLoading", false);
                }
            });
            
            $A.enqueueAction(action);
        },
    ResetPaginationValues: function(component){
        component.set("v.tab1CurrentPage",1);
        component.set("v.tab1TotalPages",1);
        component.set("v.tab2CurrentPage",1);
        component.set("v.tab2TotalPages",1);
        component.set("v.tab3CurrentPage",1);
        component.set("v.tab3TotalPages",1);
        component.set("v.tab4CurrentPage",1);
        component.set("v.tab4TotalPages",1);
        component.set("v.tab5CurrentPage",1);
        component.set("v.tab5TotalPages",1);
    }
})