({    
    checkIn : function(component, event, helper) {    
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
    
    clickbtn: function(component, event, helper) {
        component.set("v.Spinner", true); 
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
            "purpose" : "checkin"
        });
        
        action.setCallback(this,function(resp){
            var state = action.getState();            
            if(state == "SUCCESS"){     
                component.set("v.Spinner", false); 
                var returnValue = resp.getReturnValue();
                if(returnValue == 'Not possible as Event is Cancelled.' || returnValue == 'Current Event is already Check In.'|| returnValue ==  'Please create journey record as you want to claim this Event.' || returnValue == 'Journey is already completed.Please ask administrator to Re-open the journey.' || returnValue =='Please first checkIn related Journey.' || returnValue.includes('PLease checkout last Event') || returnValue == 'Current Journey is already CheckIn.' || returnValue.includes('PLease checkout last Journey')|| returnValue.includes('Exception')){
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
                else{
                    $A.get("e.force:closeQuickAction").fire();
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "type" : "Success",
                        "message": "Check In completed."
                    });
                    toastEvent.fire();
                    $A.get('e.force:refreshView').fire();
                }
            }
            else{
                component.set("v.Spinner", false); 
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
        });        $A.enqueueAction(action);
    },
    
   /* showSpinner: function(component, event, helper) {
        // make Spinner attribute true for display loading spinner 
        component.set("v.Spinner", true); 
    },
    
    // this function automatic call by aura:doneWaiting event 
    hideSpinner : function(component,event,helper){
        // make Spinner attribute to false for hide loading spinner    
        component.set("v.Spinner", false);
    } */
})