({
    getData : function(component, event, msaId, mode) {
        console.log(msaId);
        console.log(mode);
        var oppId = '';
        if(mode == 'Edit'){
            var pageReference = component.get("v.pageReference");
            oppId = pageReference.state.c__Id;
        }
        
        var action = component.get("c.getSFXAndRateCards");
        action.setParams({ msaId : msaId, mode : mode, oppId : oppId});
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                console.log(result);
                component.set("v.showSpinner", false);
                if(result == 'not allowed'){
                    component.set("v.showErrorMessage", true);
                }else if(result == 'There is no SFX and Rate Card available for given MSA.'){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type" : "success",
                        "title": "Success!",
                        "message": result
                    });
                    toastEvent.fire();
                    component.set("v.showSpinner", false);
                }else{
                    console.log(result);
                    var info = result.split('&&&');
                    var data1 = JSON.parse(info[0]);
                    var data2 = JSON.parse(info[1]);
                    
                    var sfx = [];
                    var rateCards = [];
                    
                    var isAllCheck = true;
                    
                    if(data2 != null && data2.length > 0){
                        data2.forEach(rec => {
                            sfx.push(rec.SFX__r.SFX_Code__c);
                            rateCards.push(rec.Rate_Card__r.Name);
                        })
                    }
                    console.log(sfx);
                    console.log(rateCards); 
                            
                    data1.forEach(rec =>{
                      	if(sfx.includes(rec.sfxRecord.SFX_Code__c)){
                            rec.sfxRecord.checked = true;
                        }else{
                            isAllCheck = false;
                            rec.sfxRecord.checked = false;
                        }
                        
                        rec.rateCardRecords.forEach(data =>{
                        	if(rateCards.includes(data.Name)){
                            	data.checked = true;
                        	}else{
                            	data.checked = false;
                        	}
                    	})
                    })
                    console.log(data1);
                    component.set("v.records", data1);
                    component.set("v.showSFX", true);
                   	component.set("v.isAllCheckSfx", isAllCheck);
                    component.set("v.showSpinner", false);
                }
                
            }
            else if (state === "INCOMPLETE") {
                
            }else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type" : "success",
                            "title": "Success!",
                            "message": errors[0].message
                        });
                        toastEvent.fire();
                    }
                } else {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type" : "success",
                        "title": "Success!",
                        "message": "Unknown Error"
                    });
                    toastEvent.fire();
                }
            }
        });
        $A.enqueueAction(action);
    },
    saveData : function(component, event, sfxList) {
        var data = component.get("v.oppRecord")
        var recId = '';
        
        var mode = component.get("v.mode");
        var pageReference = component.get("v.pageReference");
        if(mode == 'edit'){
            recId = pageReference.state.c__Id
        }else{
         	recId = data.Id;
        }
        
        var action = component.get("c.updateSFXAndRC");
        action.setParams({ sfxList : sfxList, recId : recId});
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                console.log(result);
                if(result == 'Success'){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type" : "success",
                        "title": "Success!",
                        "message": "Record update successfully."
                    });
                    toastEvent.fire();
                    var mode = component.get("v.mode");
        			var pageReference = component.get("v.pageReference");
        			if(mode == 'edit'){
            			window.location.href = '/'+pageReference.state.c__Id
        			}else{
         				window.location.href = ''; 
        			}
                }else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type" : "error",
                        "title": "Error!",
                        "message": "An unexpected error occured. Please reload the page and try again."
                    });
                    toastEvent.fire();
                    component.set("v.showSpinner", false);
                }
            }
            else if (state === "INCOMPLETE") {
                
            }else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "type" : "success",
                            "title": "Success!",
                            "message": errors[0].message
                        });
                        toastEvent.fire();
                    }
                } else {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "type" : "success",
                        "title": "Success!",
                        "message": "Unknown Error"
                    });
                    toastEvent.fire();
                }
            }
        });
        $A.enqueueAction(action);
    }
})