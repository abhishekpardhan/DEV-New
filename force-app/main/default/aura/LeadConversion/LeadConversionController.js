({
    doinit : function(component, event, helper) {
        component.set("v.Spinner",true);
		var rid = component.get("v.recordId");
        var action = component.get("c.checkStatus");
        action.setParams({
            "rid" : rid
        });
        action.setCallback(this,function(resp){
            var state = action.getState();
            component.set("v.Spinner",false);
            if(state == "SUCCESS"){
                var result = resp.getReturnValue();
                if(result == 'Task pending'){
                    $A.get("e.force:closeQuickAction").fire();
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "type" : "Error",
                        "message": "Kindly Complete 'Customer Profiling' on Lead conversion."
                    });
                    toastEvent.fire();
                }
                else if(resp.getReturnValue().includes("Exception")){
                    $A.get("e.force:closeQuickAction").fire();
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "type" : "Error",
                        "message": "Exception Found."+resp.getReturnValue()
                    });
                    toastEvent.fire();
                }else{
                     component.set("v.convert",true);
                }
            }
            else{
                $A.get("e.force:closeQuickAction").fire();
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "type" : "Error",
                    "message": "An Error has occurred!"
                });
                toastEvent.fire();                
            }
        });
        $A.enqueueAction(action);      
    },
    
    
    bpress : function(component, event, helper) {
		var btnClicked = event.getSource();
        btnClicked.set("v.disabled",true);
        var rid = component.get("v.recordId");
        console.log('< rid > '+rid);
        var action = component.get("c.convertlead");
        action.setParams({
            "rid" : rid
        });
        action.setCallback(this,function(resp){
            var state = action.getState();
            if(state == "SUCCESS"){
                var result = resp.getReturnValue();
                console.log(JSON.stringify(result)); 
                
                if(result.error === true){
                    console.log('leadName-->', JSON.stringify(result.leadName));
                    console.log('customerName-->', JSON.stringify(result.customerName));
                    console.log('nameMissmatch-->', JSON.stringify(result.nameMissmatch));
                    if(result.nameMissmatch === true){                        
                        console.log('name missmatch found...');
                        component.set("v.leadCustomerName",result.leadName);
                        component.set("v.customerName",result.customerName);
                        component.set("v.isCreateCustomer",false);
                    }else{                       
                        $A.get("e.force:closeQuickAction").fire();
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Error!",
                            "type" : "Error",
                            "message": result.message
                        });
                        toastEvent.fire();
                    }
                }else{
                    $A.get("e.force:closeQuickAction").fire();
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "type" : "Success",
                        "message": "Lead is converted to Account and Opportunity."
                    });
                    toastEvent.fire();
                    var urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({
                        "url": "/"+result.accountId
                    });
                    urlEvent.fire();
                }
                /*if(result == 'Lead Status not Qualified'){
                    $A.get("e.force:closeQuickAction").fire();
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "type" : "Error",
                        "message": "Only Qualified leads can be converted."
                    });
                    toastEvent.fire();
                }
                else if(resp.getReturnValue().includes("Exception")){
                    $A.get("e.force:closeQuickAction").fire();
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "type" : "Error",
                        "message": "Exception Found."+resp.getReturnValue()
                    });
                    toastEvent.fire();
                }
                else{
                    $A.get("e.force:closeQuickAction").fire();
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "type" : "Success",
                        "message": "Lead is converted to Account and Opportunity."
                    });
                    toastEvent.fire();
                    var urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({
                        "url": "/"+resp.getReturnValue()
                    });
                    urlEvent.fire();
                }
                */
            }
            else{
                $A.get("e.force:closeQuickAction").fire();
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "type" : "Error",
                    "message": "Something went wrong, Please try again after some time."
                });
                toastEvent.fire();                
            }
        });
        $A.enqueueAction(action);
        
    },
    
    
    updateLead : function(component, event, helper) {
		var btnClicked = event.getSource();
        btnClicked.set("v.disabled",true);
        var rid = component.get("v.recordId");
        console.log('< rid > '+rid);
        var action = component.get("c.createCustomer");
        action.setParams({
            "rid" : rid,
            "customerName" : component.get("v.customerName")
        });
        console.log('< action > ' + action);
        action.setCallback(this,function(resp){
            var state = action.getState();
            if(state == "SUCCESS"){
                var result = resp.getReturnValue();
                console.log(JSON.stringify(result));  
                if(result.error === true){
                    $A.get("e.force:closeQuickAction").fire();
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "type" : "Error",
                        "message": result.message
                    });
                    toastEvent.fire();
                }else{
                    $A.get("e.force:closeQuickAction").fire();
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "type" : "Success",
                        "message": "Lead is converted to Account and Opportunity."
                    });
                    toastEvent.fire();
                    var urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({
                        "url": "/"+result.accountId
                    });
                    urlEvent.fire();
                }
                
            }
            else{
                $A.get("e.force:closeQuickAction").fire();
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "type" : "Error",
                    "message": "Something went wrong, Please try again after some time."
                });
                toastEvent.fire();                
            }
        });
        $A.enqueueAction(action);
        
    }
    
    
})