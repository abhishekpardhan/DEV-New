({    
    checkOut : function(component, event, helper) {
        component.set("v.Spinner",true);
        if (navigator.geolocation) {
            var lat;
            var long;
            navigator.geolocation.getCurrentPosition(success);
            function success(position) {
                lat = position.coords.latitude;
                long = position.coords.longitude;
                component.set("v.lat",lat);
                component.set("v.long",long);                
            }
        }
        window.setTimeout(
            $A.getCallback(function() {
                component.set("v.Spinner",false);
                component.set("v.isDisabled", true);
            }), 10000);
    },
    chekbtn : function(component, event, helper) {
        component.set("v.Spinner",true);
        var lat = component.get("v.lat");
        var lont = component.get("v.long");
        var eId = component.get("v.recordId");
        var action = '';
        if(eId.startsWith('a0I')){
            action = component.get("c.eventLocation");
        }else if(eId.startsWith('a0L')){
            action = component.get("c.JourneyLocation");
        }
        action.setParams({
            "eId" : eId,
            "latitude" : lat,
            "longitude":lont,
            "purpose" : "checkOut"
        });
        action.setCallback(this,function(resp){
            var state = action.getState(); 
            if(state == "SUCCESS"){	   
                component.set("v.Spinner",false);
                var returnValue = resp.getReturnValue();
                if(returnValue == 'Please first CheckIn current Event.'|| returnValue == 'Please first CheckIn current Journey.' || returnValue == 'Journey is already checkout.'|| returnValue == 'Please Enter the Remarks in Event.' || returnValue =='Current Event is already Check Out.' || returnValue =='Please first CheckIn/checkout all related Event.'||returnValue.includes('Exception')){
                    $A.get("e.force:closeQuickAction").fire();
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "type" : "Error",
                        "message": returnValue
                    });
                    toastEvent.fire();
                    $A.get('e.force:refreshView').fire();
                }
                else if(returnValue == 'checkOut success Task'){
                    var eId1 = component.get("v.recordId");
                    var actionTask = component.get("c.getTask");
                    actionTask.setParams({
                        "eId" : eId1,
                    });
                    actionTask.setCallback(actionTask,function(resp){
                        var stateTask = actionTask.getState();  
                        if(stateTask == "SUCCESS"){
                            var taskList = resp.getReturnValue();
                            console.log('taskList length'+taskList.length);
                            component.set("v.TaskExist",true);
                            component.set("v.listTaskWrapper",taskList);
                            
                        }else{
                            $A.get("e.force:closeQuickAction").fire();
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                "title": "Error!",
                                "type" : "Error",
                                "message": "An Error has occurred."
                            });
                            toastEvent.fire();
                            $A.get('e.force:refreshView').fire();
                            
                        }
                    });
                    $A.enqueueAction(actionTask);
                } 
                    else{
                        $A.get("e.force:closeQuickAction").fire();
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Success!",
                            "type" : "Success",
                            "message": "Check Out completed."
                        });
                        toastEvent.fire();
                        $A.get('e.force:refreshView').fire();
                    }
            }
            else{
                component.set("v.Spinner",false);
                $A.get("e.force:closeQuickAction").fire();
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "type" : "Error",
                    "message": "An Error has occurred."
                });
                toastEvent.fire();
                $A.get('e.force:refreshView').fire();
            }
        });
        $A.enqueueAction(action);
        
    },
    saveModal: function(component, event, helper) {
        component.set("v.Spinner",true);
        var lat = component.get("v.lat");
        var lont = component.get("v.long");
        var listTaskWrapper = component.get("v.listTaskWrapper");
        var isSelect = false;
        var remarksExi = '';
        for(var i =0 ;i< listTaskWrapper.length ; i++){
            console.log('listTaskWrapper[0] >> '+listTaskWrapper[0].isSelected);
            if(listTaskWrapper[i].isSelected){
                isSelect = true;
                if(listTaskWrapper[i].remarks == null || listTaskWrapper[i].remarks.trim() == ''){
                    remarksExi = 'No Data';
                    break;
                }
            }
        }
        if(!isSelect){
            component.set("v.message",'Please select atleast 1 Task');
            component.set("v.Spinner",false);
            component.set("v.errorMessage",true);
            return false;            
        }else if(remarksExi == 'No Data'){
            component.set("v.message",'Please Fill Remarks of selected Task.');
            component.set("v.Spinner",false);
            component.set("v.errorMessage",true);
            return false;
        }else{
            component.set("v.message",'');
            component.set("v.errorMessage",false);  
        }
        var eId = component.get("v.recordId");
        var action = component.get("c.changeStatusTask");
        action.setParams({
            "eId" : eId,
            "lstTaskWrapper" : JSON.stringify(component.get("v.listTaskWrapper")),
            "latitude" : lat,
            "longitude" : lont
        });
        action.setCallback(this,function(resp){
            var state = action.getState();
            if(state == "SUCCESS"){
                component.set("v.Spinner",false);
                var returnValue = resp.getReturnValue();
                if(returnValue.includes('Exception')){
                    $A.get("e.force:closeQuickAction").fire();
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "type" : "Error",
                        "message": returnValue
                    });
                    toastEvent.fire();
                    $A.get('e.force:refreshView').fire();
                    
                }else{
                    $A.get("e.force:closeQuickAction").fire();
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "type" : "Success",
                        "message": "Check Out completed."
                    });
                    toastEvent.fire();
                    $A.get('e.force:refreshView').fire(); 
                }
            }else {
                component.set("v.Spinner",false);
                $A.get("e.force:closeQuickAction").fire();
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "type" : "Error",
                    "message": "An Error has occurred."
                });
                toastEvent.fire();
                $A.get('e.force:refreshView').fire();
            }
        });
        $A.enqueueAction(action);
    },
    closeModel : function(component, event, helper) {
        component.set("v.TaskExist",false);
        $A.get("e.force:closeQuickAction").fire();
    },
    /*showSpinner: function(component, event, helper) {
        // make Spinner attribute true for display loading spinner 
        component.set("v.Spinner", true); 
    },
    
    // this function automatic call by aura:doneWaiting event 
    hideSpinner : function(component,event,helper){
        // make Spinner attribute to false for hide loading spinner    
        component.set("v.Spinner", false);
    } */
})