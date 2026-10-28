({
    closequoteandopp : function(component, event, helper) {
        component.set("v.modalview",true);
    },

    createnewquote : function(component, event, helper) {       
        component.set("v.modalview2",true);
        var action = component.get("c.getDefferedReason");
        action.setCallback(this,function(res){			
            var state = action.getState();
            if(state == "SUCCESS"){
                component.set("v.lstDefferedReasons",res.getReturnValue());
            }
        });
        $A.enqueueAction(action);
        return false;       
    },

    handleDateChange : function(component, event, helper) {
        let value = event.getSource().get("v.value");
        component.set("v.deferredTill", value);
    },
    
    closeModal : function(component, event, helper) {
        
        component.set("v.modalview",false);
        component.set("v.modalview2",false);
        component.set("v.showError2",false);
    },
    
    saveModal : function(component, event, helper) {
        let inputCmp = component.find("deferredTill");
        inputCmp.setCustomValidity("");
        inputCmp.reportValidity();

        let value = inputCmp.get("v.value");

        if (!value) {
            inputCmp.setCustomValidity("Please select a date");
            inputCmp.reportValidity();
            return;
        }

        let today = new Date().toISOString().split('T')[0];

        if (value < today) {
            inputCmp.setCustomValidity("Deferred Till must be today or a future date.");
            inputCmp.reportValidity();
            return;
        }

        if(value){ 
            var id = component.get("v.recordId");
            var action = component.get("c.closequote");
            action.setParams({
                "qid" : id,
                "deferredTill" : value
            });
            action.setCallback(this,function(resp){
                var state = action.getState();
                if(state == "SUCCESS"){
                    if (resp.getReturnValue().includes("Exception")) {
                        $A.get("e.force:closeQuickAction").fire();
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            title: "Error!",
                            type: "error",
                            message: resp.getReturnValue()
                        });
                        toastEvent.fire();
                    } else {
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Success!",
                            "type" : "Success",
                            "message": "Quote and Opportunity are Deferred."
                        });
                        toastEvent.fire();
                    }            
                    $A.get("e.force:refreshView").fire();
                }
                $A.get("e.force:closeQuickAction").fire();
                $A.enqueueAction(a);
                
            });
            $A.enqueueAction(action);
        }
        
    },
    
    saveModal2 : function(component, event, helper) {
        
        var reason = component.find("defferedReason").get("v.value");
        var qname = component.find("newquotename").get("v.value");
        var sReason = component.find("subReason").get("v.value");
        //alert('<< subReason >> '+sReason);
        if(reason && qname){
            component.set("v.modalview",false);
            component.set("v.modalview2",false);
            var id = component.get("v.recordId");
            var action = component.get("c.createnewquotee");
            action.setParams({
                "qid" : id,
                "defferedReason" : reason,
                "quoteName" : qname ,
                "subReason" : sReason
            });
            action.setCallback(this,function(resp){
                var state = action.getState();
                if(state == "SUCCESS"){
                    if(resp.getReturnValue() == 'Id is Null'){
                        $A.get("e.force:closeQuickAction").fire();
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Error!",
                            "type" : "Error",
                            "message": "Id is Null"
                        });
                        toastEvent.fire();
                    } else if (resp.getReturnValue().includes("Exception")) {
                        $A.get("e.force:closeQuickAction").fire();
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            title: "Error!",
                            type: "error",
                            message: resp.getReturnValue()
                        });
                        toastEvent.fire();
                    } else {
                        $A.get("e.force:closeQuickAction").fire();
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Success!",
                            "type" : "Success",
                            "message": "New Quote is created."
                        });
                        toastEvent.fire();
                        var urlEvent = $A.get("e.force:navigateToURL");
                        urlEvent.setParams({
                            "url": "/"+resp.getReturnValue()
                        });
                        urlEvent.fire();
                    }
                }
            })
            $A.enqueueAction(action);
        }
        else{
            component.set("v.showError2",true);
        }
    },
})