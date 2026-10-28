/**
 * Description		:		Journey View component View controller
 * Created By       :       Deepika
 * Created Date     :       jan, 2025
 * Last Modified on :
 * Jira Ticket      :       https://safexpress.atlassian.net/browse/SAC-1166
 **/
({
    // Method to load month journey view at the time of loading 
    doInit : function(component, event, helper) {  
        var result = new Date();
        var Max = new Date();
        var MDay = new Date();
        result.setMonth(result.getMonth() - 2);
        Max.setMonth(Max.getMonth() + 3);
        var todayDate = $A.localizationService.formatDate(result, "YYYY-MM");
        var today = $A.localizationService.formatDate(Max, "YYYY-MM");
        var CurrentMonth = $A.localizationService.formatDate(MDay, "YYYY-MM");
        component.set("v.Month", CurrentMonth);
        component.set("v.MaxDate", today);
        component.set("v.MinDate", todayDate);
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        component.set("v.Id", userId);
        if (!component.get("v.Month1")) {
            component.set("v.Month1", CurrentMonth);
        }
        
        
        const [year, month] = component.get("v.Month1").split("-");
        const firstDay = `${year}-${month}-01`;
        const daysInMonth = new Date(year, month, 0).getDate();
        const lastDay = `${year}-${month}-${daysInMonth < 10 ? '0' + daysInMonth : daysInMonth}`;
        component.set("v.MinDateForDay", firstDay);
        component.set("v.MaxDateForDay", lastDay);
        
        helper.LoadTableMonth1(component,event,helper);
        var action = component.get('c.GetExpeseType');
        action.setCallback(this, function(respo){
            var respo = respo.getReturnValue();
            component.set('v.ExpenseType', respo);
        });
        $A.enqueueAction(action, false);
        
        var action5 = component.get('c.getusersNumber'); 
        action5.setParams({
            UserId :$A.get("$SObjectType.CurrentUser.Id") ,
        });
        action5.setCallback(this, function(response){
            var state = response.getState();
            //  alert('State'+ state);
            var respo = response.getReturnValue();
            //  alert(respo);
            if(respo > 0){
                var hideButton = component.find("TeamJourney");  
                $A.util.removeClass(hideButton,"slds-hide"); 
                $A.util.addClass(hideButton, "slds-show"); 
            }
            component.set('v.number', respo);
            console.log(component.get("v.number"));
        });
        //   alert(component.get('v.Users'));
        $A.enqueueAction(action5, false);
        
    },
    // Method to get list of journeys 
    LoadTable : function(component, event, helper){
        var action = component.get('c.GetJourneyListToApprove');
        action.setParams({
            StartDate : component.get('v.StartDate'),
            EndDate : component.get('v.EndDate'),
            CurrentUserId : $A.get("$SObjectType.CurrentUser.Id")
        });
        action.setCallback(this, function(response){
            var responseValue = response.getReturnValue();
            // console.log('responsevalue', responseValue);
            component.set('v.JourneyList', responseValue);
        });
        $A.enqueueAction(action, false);
    },
    // calling helper Method
    LoadTableMonth : function(component, event, helper){
        helper.LoadTableMonth1(component,event,helper);
    },
    
    // Method to toggle vindow on click of a row
    handleSectionToggle: function (component, event) {
        var openSections = event.getParam('openSections');
        var id = JSON.stringify(openSections);
        component.set('v.JorId', id);
        
        var action = component.get('c.GetEventList');
        action.setParams({            
            "JourneyId" : JSON.stringify(openSections)
            
        });
        action.setCallback(this, function(response){
            
            var state = response.getState(); 
            //alert(state);
            if(state === 'SUCCESS' || state === 'DRAFT'){
                var responseValue = response.getReturnValue();
                console.log('responseValue', responseValue);
                component.set('v.EventList', responseValue);
            }
            else if (state === 'INCOMPLETE'){         
            }
                else if (state === 'ERROR'){
                    var errors = response.getError();
                    console.log('Error', errors);
                }
        },'ALL');
        $A.enqueueAction(action);
        var openSections = event.getParam('openSections');
        var action1 = component.get('c.GetExList');
        action1.setParams({            
            "JourneyId" : JSON.stringify(openSections)
            
        });
        action1.setCallback(this, function(response){
            
            var state = response.getState(); 
            //alert(state);
            if(state === 'SUCCESS' || state === 'DRAFT'){
                var responseValue = response.getReturnValue();
                console.log('responseValue', responseValue);
                component.set('v.ExList', responseValue);
            }
            else if (state === 'INCOMPLETE'){         
            }
                else if (state === 'ERROR'){
                    var errors = response.getError();
                    console.log('Error', errors);
                }
        },'ALL');
        $A.enqueueAction(action1);
    },
    // Mehod to redirect to the detail page of the record
    doRedirect:function (component, event){
        var id = event.currentTarget.name;
        
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": id
        });
        navEvt.fire(); 
    },
    // Method to open record detail page on another window
    openOnNewWindow: function(component, event, helper){
        var id = event.currentTarget.name;
        window.open('https://safeforce1.lightning.force.com/'+id ,'_blank');
    },
    // Method to open map on click of the map icon
    openMap: function(component, event, helper) {
        var Identity = event.currentTarget.getAttribute("data-value");
        console.log(Identity);
        component.set("v.isOpen", true);
        var action = component.get('c.GetMapData1');
        action.setParams({ JorId: Identity });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === 'SUCCESS') {
                var mapMarkers = response.getReturnValue();
                component.set('v.mapMarkers', mapMarkers);
                if (mapMarkers.length > 0) {
                    // Set center to the first marker's location
                    component.set('v.center', mapMarkers[0].location);
                }
                component.set('v.zoomLevel', 15);  // Adjust zoom for closer view
                component.set('v.markersTitle', 'Journey and Event Locations');
                component.set('v.showFooter', false);
                
            } else if (state === 'ERROR') {
                var errors = response.getError();
                console.log('Error', errors);
            }
        });

        $A.enqueueAction(action);
    },    
    // Method to close map window on click of close button
    closeMap: function(component, event, helper) {
        // for Hide/Close Model,set the "isOpen" attribute to "Fasle"  
        component.set("v.isOpen", false);
    },
    // Method to open form on click of add new button
    openForm: function(component, event, helper){
        component.set("v.openNewExpense", true);
        var Ident = event.getSource().get("v.name");
        //    alert(Ident);
    },
    // Method to close New expense form on click of a close button
    closeExpense: function(component){
        component.set("v.openNewExpense", false);
    },
    // Method of save expense on click of save button  
    SaveExpense: function(component, event, helper){
        var Type = component.get("v.CreateExpense.Expense_Type__c");
        var Other = component.get("v.CreateExpense.If_Others_Please_specify__c");
        var Name = component.get("v.CreateExpense.Name");
        if(Name == ''){
            alert('Name is mandatory.');
        }else if(Type == 'Select Type' || Type == ''){
            alert('Please Select an Expense Type.');
        }else if(Type == 'Others' && Other == ''){
            alert('Please specify other Expense.');
        }        
            else{
                var Ide = component.get('v.JorId');
                var Ide1 = Ide.replace('[','');
                var Ide2 = Ide1.replace(']','');
                var Ide3 = Ide2.replace('"','');
                var Ide4 = Ide3.replace('"','');
                //    alert(Ide4);
                var action = component.get('c.CreateExpense');
                // alert(action);
                action.setParams({ 
                    exp : component.get('v.CreateExpense') ,
                    JourId: Ide4
                });
                action.setCallback(this,function(Response){
                    var State = Response.getState();
                    if(State === 'SUCCESS'){
                        var responseValue = Response.getReturnValue();
                        //  alert('Expense Saved Successfully');
                        component.set("v.NewExpense",Response.getReturnValue());
                        var ExpenseId = component.get("v.NewExpense");
                        //  component.set("v.openNewExpense", false);
                    }else if(State === 'ERROR'){
                        // alert('error');
                        var error = Response.getError();
                        console.log(error);
                        
                    }
                });
                $A.enqueueAction(action);
                
                var action1 = component.get('c.GetExList');
                action1.setParams({            
                    "JourneyId" : Ide4
                    
                });
                action1.setCallback(this, function(response){
                    
                    var state = response.getState(); 
                    //alert(state);
                    if(state === 'SUCCESS' || state === 'DRAFT'){
                        var responseValue = response.getReturnValue();
                        console.log('responseValue', responseValue);
                        component.set('v.ExList', responseValue);
                    }
                    else if (state === 'INCOMPLETE'){         
                    }
                        else if (state === 'ERROR'){
                            var errors = response.getError();
                            console.log('Error', errors);
                        }
                },'ALL');
                $A.enqueueAction(action1);
                helper.LoadTableMonth1(component,event,helper);
            }
        component.set("v.openNewExpense", false);
        component.set('v.CreateExpense','' );
        alert('Expense Saved Successfully');    
    },
    // Method to navigate to sObject
    dothis: function(component, event, helper){
        var Identity = event.currentTarget.getAttribute("data-value");
        // alert (Identity);
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
            "recordId": Identity,
            "slideDevName": "detail"
        });
        navEvt.fire(); 
    } ,
    // Method to submit for approval month vise
    SubmitforApproval: function(component, event, helper){
        var action = component.get('c.submitForApproval');
        var Identity = component.get('v.JourneyList');
        // alert(Identity);
        action.setParams({            
            "jour" : component.get('v.JourneyList')
            
        });
        action.setCallback(this, function(response){
            
            var state = response.getState(); 
            // alert(state);
            if(state === 'SUCCESS' || state === 'DRAFT'){
                var responseValue = response.getReturnValue();
                console.log('responseValue', responseValue);
                // component.set('v.EventList', responseValue);
                alert(responseValue);
            }
            else if (state === 'INCOMPLETE'){         
            }
                else if (state === 'ERROR'){
                    var errors = response.getError();
                    console.log('Error', errors);
                }
        },'ALL');
        $A.enqueueAction(action);
        helper.LoadTableMonth1(component,event,helper);
        
    },
    // Method to submit for approval journey vise
    SubmitforApprovalSingle: function(component, event, helper){
        var action = component.get('c.submitForApprovalSingle');
        var Ident = event.getSource().get("v.name");
        action.setParams({            
            "jorId" : Ident
            
        });
        action.setCallback(this, function(response){
            
            var state = response.getState(); 
            // alert(state);
            if(state === 'SUCCESS' || state === 'DRAFT'){
                var responseValue = response.getReturnValue();
                console.log('responseValue', responseValue);
                // component.set('v.EventList', responseValue);
                alert(responseValue);
            }
            else if (state === 'INCOMPLETE'){         
            }
                else if (state === 'ERROR'){
                    var errors = response.getError();
                    console.log('Error', errors);
                }
        },'ALL');
        $A.enqueueAction(action);
        helper.LoadTableMonth1(component,event,helper);
        
    },
    // method to hide My journey and show teams journey
    hideMyJourneyView : function(component, event, helper){
        var hideJourneyView = component.find("MyJourney");
        var MyJourneyBtn = component.find("MyJourneyBtn");
        var TeamJourney = component.find("TeamJourney");
        var TeamJourneyView = component.find("TeamJourneyView");
        var ProfileViewCard = component.find("NormalHeading");
        var Teamview = component.find("ProfileDeatilHeading");
        $A.util.addClass(hideJourneyView, "slds-hide");
        $A.util.removeClass(TeamJourney, "slds-show");
        $A.util.addClass(TeamJourney, "slds-hide");
        $A.util.addClass(MyJourneyBtn, "slds-show");
        $A.util.removeClass(MyJourneyBtn, "slds-hide");
        $A.util.addClass(TeamJourneyView, "slds-show");
        $A.util.removeClass(TeamJourneyView, "slds-hide");
        $A.util.addClass(ProfileViewCard, "slds-hide");
        $A.util.removeClass(ProfileViewCard, "slds-show");
        $A.util.addClass(Teamview, "slds-show");
        $A.util.removeClass(Teamview, "slds-hide");
        var action = component.get('c.getallusers');
        action.setParams({
            UserId :$A.get("$SObjectType.CurrentUser.Id"),
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            //  alert('State'+ state);
            var respo = response.getReturnValue();
            component.set('v.Users', respo);
            console.log(component.get("v.Users"));
        });
        //   alert(component.get('v.Users'));
        $A.enqueueAction(action, false);
        
        //Setting Current month for team view
        var result = new Date();
        var Max = new Date();
        var MDay = new Date();
        result.setMonth(result.getMonth() - 2);
        Max.setMonth(Max.getMonth() + 3);
        var todayDate = $A.localizationService.formatDate(result, "YYYY-MM");
        var today = $A.localizationService.formatDate(Max, "YYYY-MM");
        var CurrentMonth = $A.localizationService.formatDate(MDay, "YYYY-MM");
        component.set("v.Month1", CurrentMonth);
        component.set("v.MaxDate1", today);
        component.set("v.MinDate1", todayDate);
        helper.LoadTableMonthTeam(component, event, helper);
    },
    // method to hide teams journey and show my journey
    hideTeamView : function(component, event, helper){
        console.log('hide team view');
        var hideJourneyView = component.find("MyJourney");
        var MyJourneyBtn = component.find("MyJourneyBtn");
        var TeamJourney = component.find("TeamJourney");
        var TeamJourneyView = component.find("TeamJourneyView");
        var Teamview1 = component.find("ProfileDeatilHeading");
        var ProfileViewCard1 = component.find("NormalHeading");
        $A.util.addClass(hideJourneyView, "slds-show");
        $A.util.removeClass(hideJourneyView, "slds-hide");
        $A.util.removeClass(TeamJourney, "slds-hide");
        $A.util.addClass(TeamJourney, "slds-show");
        $A.util.addClass(MyJourneyBtn, "slds-hide");
        $A.util.removeClass(MyJourneyBtn, "slds-show");
        $A.util.addClass(TeamJourneyView, "slds-hide");
        $A.util.removeClass(TeamJourneyView, "slds-show");
        $A.util.removeClass(Teamview1, "slds-show");
        $A.util.addClass(Teamview1, "slds-hide");
        $A.util.removeClass(ProfileViewCard1, "slds-hide");
        $A.util.addClass(ProfileViewCard1, "slds-show");
    },
    // method to save selected user id in team journey view
    selectUser : function(component, event, helper) {
        var user = component.find("User").get("v.value");
        console.log('user:::' + user);
        // If no user selected, reset and return
        if (user=='' ||user== null) {
            component.set("v.SelectedUser", null);
        }else{
            component.set("v.SelectedUser", user);
        }
        helper.ResetPaginationValues(component);
        helper.LoadTableMonthTeam(component, event, helper);
    },
    LoadTableMonthTeam: function(component, event, helper){
        helper.ResetPaginationValues(component);
        helper.LoadTableMonthTeam(component, event, helper);
    },
    openRejection: function(component, event, helper){
        var Reco = event.getSource().get("v.name") ; 
        // alert(Reco);
        component.set("v.Rejection", true);
        component.set("v.RejectedJourney", Reco);
    },
    closeRejectionReason: function(component, event, helper){
        component.set("v.Rejection", false);
    },
    
    JourneyApprovalByManager: function(component, event, helper){
        try{
            //  alert('Step 1');
            var sub = component.get("v.SelectedUser");
            var Rec = $A.get("$SObjectType.CurrentUser.Id");
            var Reco = event.getSource().get("v.name") ; 
            var actionable = component.get('c.approveJourney');
            actionable.setParams({            
                Submitter : sub,
                Receiver : Rec,
                record : Reco 
            });
            actionable.setCallback(this, function(response){
                var state = response.getState(); 
                //  alert(state);
                if(state === 'SUCCESS' || state === 'DRAFT'){
                    var responseValue = response.getReturnValue();
                    console.log('responseValue', responseValue);
                    // component.set('v.EventList', responseValue);
                    alert(responseValue);
                }
                else if (state === 'INCOMPLETE'){         
                }
                    else if (state === 'ERROR'){
                        var errors = response.getError();
                        console.log('Error', errors);
                    }
            },'ALL');
            $A.enqueueAction(actionable);
        } catch(e) {
            alert(e.getMessage());
        }
    },
    JourneyrejectedByManager: function(component, event, helper){
        //  alert('Step 1');
        var sub = component.get("v.SelectedUser");
        var Rec = $A.get("$SObjectType.CurrentUser.Id");
        var Reco = component.get("v.RejectedJourney"); 
        //   alert(Reco);
        var actionable = component.get('c.rejectJourney');
        //      alert(actionable);
        actionable.setParams({            
            Submitter : sub,
            Receiver : Rec,
            record : Reco,
            Comment :  component.get("v.comment")
        });
        actionable.setCallback(this, function(response){
            var state = response.getState(); 
            //  alert(state);
            if(state === 'SUCCESS' || state === 'DRAFT'){
                var responseValue = response.getReturnValue();
                console.log('responseValue', responseValue);
                // component.set('v.EventList', responseValue);
                alert(responseValue);
            }
            else if (state === 'INCOMPLETE'){         
            }
                else if (state === 'ERROR'){
                    var errors = response.getError();
                    console.log('Error', errors);
                }
        },'ALL');
        $A.enqueueAction(actionable);
        
    },
    
    
    JourneySubmitAuditDetails: function (component, event, helper) {
        var journeyId = event.getSource().get("v.name"); // Get Journey ID from button name attribute
        
        // Determine which journey list to use based on the button's data attribute
        var journeyListType = event.getSource().get("v.value"); // Assume value attribute holds list type
        var journeyList = component.get("v." + journeyListType); // Get the list dynamically
        
        // Find the specific journey being updated
        var selectedJourney = journeyList.find(j => j.Id === journeyId);
        if (!selectedJourney) {
            alert("Journey not available for updating!");
            return;
        }
        
        var journeyAudited = selectedJourney.Journey_Audited__c;
        var auditorRemarks = selectedJourney.Remarks_To_be_filled_by_Auditors__c;
        //alert('JOURNEY ::: '+journeyAudited+' ::: '+auditorRemarks);
        // **Validation Check: Ensure the values are not empty**
        if (journeyAudited === undefined || journeyAudited === null||!journeyAudited) {
            alert("Please check the 'Journey Audited' checkbox before submitting.");
            return;
        }
        if (!auditorRemarks || auditorRemarks.trim() === "") {
            alert("Please enter 'Auditor Remarks' before submitting.");
            return;
        }
         
        // Call helper method to update record
        helper.updateJourneyRecord(component, journeyId,'Journey__c', 'Remarks_To_be_filled_by_Auditors__c', auditorRemarks,journeyAudited);
    },
    handleMonthChange : function(component, event, helper) {
        const monthStr = component.get("v.Month1"); // e.g. "2025-04"
        if (monthStr) {
            const [year, month] = monthStr.split("-");
            const firstDay = `${year}-${month}-01`;
            
            // Get last day of month
            const daysInMonth = new Date(year, month, 0).getDate();
            const lastDay = `${year}-${month}-${daysInMonth < 10 ? '0' + daysInMonth : daysInMonth}`;
            component.set("v.MinDateForDay", firstDay);
            component.set("v.MaxDateForDay", lastDay);
            component.set("v.SelectedDate", "");
           helper.ResetPaginationValues(component);
        }
        
        // Load journey data if needed
        helper.LoadTableMonthTeam(component, event, helper);
    },
    
    handleDaySelection : function(component, event, helper) {
        const selectedDate = component.get("v.SelectedDate");
        const min = component.get("v.MinDateForDay");
        const max = component.get("v.MaxDateForDay");
        
        // Ensure that the dates are valid before comparing them
        const isValidDate = selectedDate && selectedDate >= min && selectedDate <= max;
        
        if (isValidDate) {
            component.set("v.DateError", false); // Clear the error
            helper.ResetPaginationValues(component); // Reset pagination values
            // Load table with selected date
            helper.LoadTableMonthTeam(component, event, helper);
        } else {
            component.set("v.DateError", true); // Show error for invalid date
            component.set("v.SelectedDate", ""); // Clear the selected date
            // Optionally clear the table data to avoid showing old data
            component.set("v.JourneyListTeam", []); 
        }
    },

    // Navigate to the previous page
    navigateToPreviousPage: function(component, event, helper) {
        let currentPage = component.get("v.currentPage");
        if (currentPage > 1) {
            component.set("v.currentPage", currentPage - 1);
            helper.LoadTableMonth1(component,event,helper);
        }
    },
    
    // Navigate to the next page
    changePage: function(component, event, helper) {
        let direction = event.getSource().get("v.name"); // e.g., 'next1', 'prev3'
        let match = direction.match(/(next|prev)(\d)/);
        
        if (!match) return;
        
        let actionType = match[1]; // 'next' or 'prev'
        let tabIndex = match[2];   // '1' to '5'
        
        let currentPageAttr = `v.tab${tabIndex}CurrentPage`;
        let totalPagesAttr = `v.tab${tabIndex}TotalPages`;
        let loadMethod = `loadTab${tabIndex}Data`;
        
        let currentPage = component.get(currentPageAttr);
        let totalPages = component.get(totalPagesAttr);
        
        if (actionType === "next" && currentPage < totalPages) {
            component.set(currentPageAttr, currentPage + 1);
        } else if (actionType === "prev" && currentPage > 1) {
            component.set(currentPageAttr, currentPage - 1);
        } else {
            return;
        }
        
        if (typeof helper[loadMethod] === "function") {
            helper[loadMethod](component);
        } else {
            console.error(`Method ${loadMethod} not found in helper`);
        }
    },
    JourneyStatusNotToBeClaimed: function(component, event, helper) {
        try {
            var Reco = event.getSource().get("v.name"); 
            var action = component.get('c.setStatusNotToBeClaimed');
            action.setParams({            
                record : Reco 
            });
            // Add callback to handle the response
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var result = response.getReturnValue();
                    if (result === true) {
                        // Show success message
                        alert('Journey status updated successfully.');
                    } else {
                        // Show failure message
                        alert('Failed to update Journey status.');
                    }
                } else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors && errors[0] && errors[0].message) {
                        alert('Error: ' + errors[0].message);
                    } else {
                        alert('Unknown error occurred.');
                    }
                }
            });
            $A.enqueueAction(action);
        } catch (e) {
            alert(e.message);
        }
    }
})