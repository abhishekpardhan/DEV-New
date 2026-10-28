({
    doInit : function(component, event, helper) {
        // alert("Inside The Code");
        var result = new Date();
        var Max = new Date();
        var MDay = new Date();
        result.setMonth(result.getMonth() - 5);
        Max.setMonth(Max.getMonth() + 3);
        var todayDate = $A.localizationService.formatDate(result, "YYYY-MM");
        var today = $A.localizationService.formatDate(Max, "YYYY-MM");
        var CurrentMonth = $A.localizationService.formatDate(MDay, "YYYY-MM");
        component.set("v.Month", CurrentMonth);
        component.set("v.MaxDate", today);
        component.set("v.MinDate", todayDate);
        
        var action = component.get("c.GetRegionList");
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log(response.getReturnValue());
            if (state == "SUCCESS") {
                component.set("v.Region", response.getReturnValue());
            }
            else {
                console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);
        
        var action1 = component.get("c.GetUserListId");
        action1.setParams({            
            
        });
        action1.setCallback(this, function(response) {
            var state = response.getState();
            console.log(response.getReturnValue());
            if (state == "SUCCESS") {
                component.set("v.UserListid", response.getReturnValue());
            }
            else {
                console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action1);
    },
    /*    selectUser : function(component, event, helper) {
        var action = component.get("c.GetUserList");
        action.setParams({            
            "Region" : component.get("v.RegionSelected")

        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log(response.getReturnValue());
            if (state == "SUCCESS") {
                component.set("v.UserList", response.getReturnValue());
            }
            else {
                console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);
    }, */
    LoadJourney : function(component, event, helper) {
        //      helper.LoadJourneyHelper(component,event,helper);
        var StDate = component.get('v.Month');
        var array = StDate.split('-');
        var Yeara = array[0];
        var Montha = array[1];
        //   alert(component.get('v.RegionSelected'));
        //       alert(Yeara);
        //       alert(Montha);
        var action = component.get("c.getUser");
        action.setParams({            
            //   "ID" : component.get('v.SelectedId'),
            "Region": component.get('v.RegionSelected'),
            "Year": Yeara,
            "Month": Montha
        });
        action.setCallback(this, function(response){
            
            var state = response.getState(); 
            //  alert(state);
            if(state === 'SUCCESS' || state === 'DRAFT'){
                
                var responseValue = response.getReturnValue();
                var arrayMapKeys = [];
                //    console.log('responseValue', responseValue);
                //    console.log('responce key'+ Object.keys(responseValue));
                //  alert(responseValue);
                //  component.set('v.userMap', responseValue);
                //  console.log(component.get('v.userMap'));
                for(var key in responseValue){
                    //       alert(responseValue[key]);
                    //      alert(key);
                    arrayMapKeys.push({key: key, value: responseValue[key]});
                    
                }
                //  console.log('zxcvbnm'+ arrayMapKeys );
                component.set('v.userMap', arrayMapKeys);
                //  console.log('asdfghjkl'+ component.get("v.userMap"));
            }
            else if (state === 'INCOMPLETE'){         
            }
                else if (state === 'ERROR'){
                    var errors = response.getError();
                    console.log('Error', errors);
                }
        },'ALL');
        $A.enqueueAction(action);
        
    }, 
    searchUser : function(component, event, helper) {
        var action = component.get('c.SearchUser');
        action.setParams({            
            "ID" : component.get('v.SelectedId')
        });
        action.setCallback(this, function(response){
            
            var state = response.getState(); 
            //  alert(state);
            if(state === 'SUCCESS' || state === 'DRAFT'){
                var responseValue = response.getReturnValue();
                console.log('responseValue', responseValue);
                //   alert(responseValue);
                component.set('v.SelectedUser', responseValue);
                helper.LoadJourneyHelper(component,event,helper);
            }
            else if (state === 'INCOMPLETE'){         
            }
                else if (state === 'ERROR'){
                    var errors = response.getError();
                    console.log('Error', errors);
                }
        },'ALL');
        $A.enqueueAction(action);
        
    }, 
    openOnWindow: function(component, event, helper){
        //   var id = event.currentTarget.value;
        //   var id = component.find("button1").get("v.value");
        //  alert(id);
        //   window.open('https://safeforce1.lightning.force.com/'+id ,'_blank');
        var getid = component.find("button1");
        var id = Array.isArray(getid) ? getid[0].get("v.value") : getid.get("v.value");
        // alert(id);
        window.open('https://safeforce1.lightning.force.com/'+id ,'_blank'); 
    },
    openOnWindow1: function(component, event, helper){
        //   var id = event.currentTarget.value;
        //   var id = component.find("button2").get("v.value");
        //   alert(id);
        //   window.open('https://safeforce1.lightning.force.com/'+id ,'_blank');
        var getid = component.find("button2");
        var id = Array.isArray(getid) ? getid[0].get("v.value") : getid.get("v.value");
        alert(id);
        window.open('https://safeforce1.lightning.force.com/'+id ,'_blank');
    },
    openOnWindow3: function(component, event, helper){
        //   var id = event.currentTarget.value;
        //  var id = component.find("button3").get("v.value");
        //  var getid = component.find("button3");
        //  var id = Array.isArray(getid) ? getid[0].get("v.value") : getid.get("v.value");
        var id = event.target.id;
        //   alert(id);
        
        window.open('https://safeforce1.lightning.force.com/'+id ,'_blank');
    },
    closeExpense: function(component){
        component.set("v.openJourney", false);
    },
    opentab : function(component, event, helper) {
        var id = event.currentTarget.name;
        // alert(id);
        component.set("v.SelectedJourney", id);
        component.set("v.openJourney", true);
        var actionable = component.get('c.JourneyDetail');
        actionable.setParams({            
            "jorId" : id
        });
        actionable.setCallback(this, function(response){
            var state = response.getState(); 
            //alert(state);
            if(state === 'SUCCESS' || state === 'DRAFT'){
                var responseValue = response.getReturnValue();
                console.log('responseValue', responseValue);
                component.set('v.journeyDetail', responseValue);
            }
            else if (state === 'INCOMPLETE'){         
            }
                else if (state === 'ERROR'){
                    var errors = response.getError();
                    console.log('Error', errors);
                }
        },'ALL');
        $A.enqueueAction(actionable);        
        var action = component.get('c.GetEventList');
        //  alert(id);
        action.setParams({            
            "JourneyId" : id
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
        var action1 = component.get('c.GetExList');
        action1.setParams({            
            "JourneyId" : id
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
        
        /*var action2 = component.get('c.getApprovalHistory');
        action2.setParams({            
            "JourneyId" : id
        });
        action2.setCallback(this, function(response){
           
            var state = response.getState(); 
            //alert(state);
            if(state === 'SUCCESS' || state === 'DRAFT'){
                var responseValue = response.getReturnValue();
                console.log('responseValue', responseValue);
                component.set('v.ApprovalHistory', responseValue);
            }
            else if (state === 'INCOMPLETE'){         
            }
                else if (state === 'ERROR'){
                    var errors = response.getError();
                    console.log('Error', errors);
                }
        },'ALL');
        $A.enqueueAction(action2); */
        
    },
    updateJourney : function(component, event, helper) {
        // alert(component.get('v.ApprovedAmount'));
        // alert(component.get('v.Remark'));
        var act = component.find("approved").get("v.value");
        var rem = component.find("remark").get("v.value");
        //   alert(act);
        //    alert(rem);
        var amount = component.get('v.ApproveAmmount');
        var remark = component.get('v.Remark');
        // alert(component.get('v.ApproveAmmount'));
        // alert(remark);
        if(amount > 0 && remark == ""){
            // alert("Remark is mandatory");
        }
        else{
            var action1 = component.get('c.ApproveAmmount');
            action1.setParams({            
                //   Amount : component.get('v.ApprovedAmount'),
                //   Remark  : component.get('v.Remark'),
                Amount : act,
                Remark  : rem,
                JourneyId : component.get('v.SelectedJourney')
            });
            action1.setCallback(this, function(response){
                
                var state = response.getState(); 
                // alert(state);
                if(state === 'SUCCESS' || state === 'DRAFT'){
                    var responseValue = response.getReturnValue();
                    console.log('responseValue', responseValue);
                    // component.set('v.EventList', responseValue);
                    //    alert (responseValue);
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        // mode: 'sticky',
                        type: 'success',
                        message: responseValue,
                        duration: 1000
                    });
                    toastEvent.fire();    
                }
                else if (state === 'INCOMPLETE'){         
                }
                    else if (state === 'ERROR'){
                        var errors = response.getError();
                        console.log('Error', errors);
                    }
            },'ALL');
            $A.enqueueAction(action1);
            
            component.set("v.openJourney", false);
            
            var StDate = component.get('v.Month');
            var array = StDate.split('-');
            var Yeara = array[0];
            var Montha = array[1];
            var action = component.get("c.GetJourneyList");
            action.setParams({            
                Year : Yeara,
                Month : Montha,
                CurrentUserId : component.get("v.SelectedUser")
                
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
                console.log(response.getReturnValue());
                if (state == "SUCCESS") {
                    component.set("v.JourneyList", response.getReturnValue());
                }
                else {
                    console.log("Failed with state: " + state);
                }
            });
            $A.enqueueAction(action);
            var action1 = component.get("c.GetJourneyListTravel");
            action1.setParams({            
                Year : Yeara,
                Month : Montha,
                CurrentUserId : component.get("v.SelectedUser")
                
            });
            action1.setCallback(this, function(response) {
                var state = response.getState();
                console.log(response.getReturnValue());
                if (state == "SUCCESS") {
                    component.set("v.JourneyList1", response.getReturnValue());
                }
                else {
                    console.log("Failed with state: " + state);
                }
            });
            $A.enqueueAction(action1);
            helper.LoadJourneyHelper(component,event,helper);
        }
    },
    searchrsn : function(component, event, helper) {
        var Idbtn = component.find("Idbtn");
        var Regionbtn = component.find("Regionbtn");
        var Regionsrc = component.find("Regionsrc");
        var Idsrc = component.find("Idsrc");
        $A.util.addClass(Idbtn, "slds-hide");
        $A.util.removeClass(Idbtn, "slds-show");
        $A.util.addClass(Regionbtn, "slds-show");
        $A.util.removeClass(Regionbtn, "slds-hide");
        $A.util.addClass(Regionsrc, "slds-hide");
        $A.util.removeClass(Regionsrc, "slds-show");
        $A.util.addClass(Idsrc, "slds-show");
        $A.util.removeClass(Idsrc, "slds-hide");
    },
    
    searchid : function(component, event, helper) {
        var Idbtn = component.find("Idbtn");
        var Regionbtn = component.find("Regionbtn");
        var Regionsrc = component.find("Regionsrc");
        var Idsrc = component.find("Idsrc");
        $A.util.addClass(Idbtn, "slds-show");
        $A.util.removeClass(Idbtn, "slds-hide");
        $A.util.addClass(Regionbtn, "slds-hide");
        $A.util.removeClass(Regionbtn, "slds-show");
        $A.util.addClass(Regionsrc, "slds-show");
        $A.util.removeClass(Regionsrc, "slds-hide");
        $A.util.addClass(Idsrc, "slds-hide");
        $A.util.removeClass(Idsrc, "slds-show");
    },
    selectMonth : function(component, event, helper) {
        helper.LoadJourneyHelper(component,event,helper);
    },
    selectUser : function(component, event, helper) {
        helper.LoadJourneyHelper(component,event,helper);
        //  alert(component.get('v.SelectedUsername'));
        
        var action1 = component.get("c.GetUserId");
        action1.setParams({            
            userName : component.get('v.SelectedUsername')
            
        });
        action1.setCallback(this, function(response) {
            var state = response.getState();
            console.log(response.getReturnValue());
            if (state == "SUCCESS") {
                //      alert(response.getReturnValue());
                component.set("v.SelectedUser", response.getReturnValue());
                helper.LoadJourneyHelper(component,event,helper);
            }
            else {
                console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action1);
        
        //    alert('alerted user:'+component.get("v.SelectedUser"));
        //   if(component.get("v.SelectedUser") != null){
        //    helper.LoadJourneyHelper(component,event,helper);
        // }
    },
    createInvoice: function(component,event, helper){
        var StDate = component.get('v.Month');
        var array = StDate.split('-');
        var Yeara = array[0];
        var Montha = array[1];
        
        var CreateInvoice = component.get('c.createTravelInvoices');
        // alert('2nd method');
        CreateInvoice.setParams({
            UserId : component.get('v.SelectedUser'),
            Year : Yeara,
            Month : Montha,
            
        });
        CreateInvoice.setCallback(this, function(response){
            var state = response.getState();
            //   alert(state);
            var responseValue = response.getReturnValue();
            // console.log('responsevalue', responseValue);
          //  alert(responseValue);
            if(responseValue == 'Invoice Created'){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    // mode: 'sticky',
                    type: 'success',
                    message: responseValue,
                    duration: 1000
                });
                toastEvent.fire();    
            }else{
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    // mode: 'sticky',
                    type: 'error',
                    message: responseValue,
                    duration: 1000
                });
                toastEvent.fire();
            }   
            
            //   component.set('v.TotalApprovedAmountCon', responseValue);
        });
        $A.enqueueAction(CreateInvoice, false);
        helper.LoadUserList(component,event, helper);
    },
    createTravelInvoice: function(component,event, helper){
        try{
            // alert('into the code');
            var StDate = component.get('v.Month');
            //alert(StDate);
            var array = StDate.split('-');
            var Yeara = array[0];
            var Montha = array[1];
            //   alert(Yeara);
            //   alert(Montha);
            
            var action1 = component.get('c.createConveyanceInvoice');
            action1.setParams({            
                UserId : component.get('v.SelectedUser'),
                Year : Yeara,
                Month : Montha
            });
            action1.setCallback(this, function(response){
                
                var state = response.getState(); 
                //      alert(state);
                if(state === 'SUCCESS' || state === 'DRAFT'){
                    var responseValue = response.getReturnValue();
                   // alert(responseValue);
                   if(responseValue == 'Invoice Created'){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    // mode: 'sticky',
                    type: 'success',
                    message: responseValue,
                    duration: 1000
                });
                toastEvent.fire();    
            }else{
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    // mode: 'sticky',
                    type: 'error',
                    message: responseValue,
                    duration: 1000
                });
                toastEvent.fire();
            }
                    console.log('responseValue', responseValue);
                    //	      component.set('v.ExList', responseValue);
                }
                else if (state === 'INCOMPLETE'){         
                }
                    else if (state === 'ERROR'){
                        var errors = response.getError();
                        console.log('Error', errors);
                    }
            },'ALL');
            $A.enqueueAction(action1);
            helper.LoadUserList(component,event, helper);
        }catch(e){
            //     alert(e.message);
            //    alert(e.name);
        }
    },
    opentab1 : function(component, event, helper) {
        var id = event.currentTarget.name;
        // alert(id);
        component.set("v.SelectedExpence", id);
        component.set("v.openExpence", true);
        var actionable = component.get('c.ExpenceDetail');
        actionable.setParams({            
            "ExpId" : id
        });
        actionable.setCallback(this, function(response){
            var state = response.getState(); 
            //alert(state);
            if(state === 'SUCCESS' || state === 'DRAFT'){
                var responseValue = response.getReturnValue();
                console.log('responseValue', responseValue);
                component.set('v.ExpenceDetail', responseValue);
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
    closeExpense1: function(component){
        component.set("v.openExpence", false);
    },
    updateExpence : function(component, event, helper) {
        var act = component.find("approvedExpence").get("v.value");
        // alert (act);
        //    alert(component.get('v.SelectedExpence'));
        var action1 = component.get('c.ApproveExpenceAmmount');
        action1.setParams({            
            Amount : act,
            ExpenceId : component.get('v.SelectedExpence')
        });
        action1.setCallback(this, function(response){
            var state = response.getState(); 
            //       alert(state);
            if(state === 'SUCCESS' || state === 'DRAFT'){
                var responseValue = response.getReturnValue();
                console.log('responseValue', responseValue);
                // component.set('v.EventList', responseValue);
                //  alert (responseValue);
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    // mode: 'sticky',
                    type: 'success',
                    message: responseValue,
                    duration: 1000
                });
                toastEvent.fire();
            }
            else if (state === 'INCOMPLETE'){         
            }
                else if (state === 'ERROR'){
                    var errors = response.getError();
                    console.log('Error', errors);
                }
        },'ALL');
        $A.enqueueAction(action1);
        
        component.set("v.openExpence", false);
        var action2 = component.get('c.GetExList');
        action2.setParams({            
            "JourneyId" : component.get("v.SelectedJourney")
        });
        action2.setCallback(this, function(response){
            
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
        $A.enqueueAction(action2);
        //  helper.LoadJourneyHelper(component,event,helper);
        var actionable = component.get('c.JourneyDetail');
        actionable.setParams({            
            "jorId" : component.get("v.SelectedJourney")
        });
        actionable.setCallback(this, function(response){
            var state = response.getState(); 
            //alert(state);
            if(state === 'SUCCESS' || state === 'DRAFT'){
                var responseValue = response.getReturnValue();
                console.log('responseValue', responseValue);
                component.set('v.journeyDetail', responseValue);
            }
            else if (state === 'INCOMPLETE'){         
            }
                else if (state === 'ERROR'){
                    var errors = response.getError();
                    console.log('Error', errors);
                }
        },'ALL');
        $A.enqueueAction(actionable);
        helper.LoadJourneyHelper(component,event,helper);
    },
    openOnNewWindow: function(component, event, helper){
        var id = event.currentTarget.name;
        //  alert(id);
        window.open('https://safeforce1.lightning.force.com/'+id ,'_blank');
    },
    
    // function automatic called by aura:waiting event  
    showSpinner: function(component, event, helper) {
        // make Spinner attribute true for displaying loading spinner 
        component.set("v.spinner", true); 
    },
    
    // function automatic called by aura:doneWaiting event 
    hideSpinner : function(component,event,helper){
        // make Spinner attribute to false for hiding loading spinner    
        component.set("v.spinner", false);
    }
})