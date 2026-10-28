({
    recordUpdated: function(component, event, helper) {
        var eventParams = event.getParams();
        console.log(eventParams.changeType);
        if(eventParams.changeType === "LOADED" || eventParams.changeType === "CHANGED") {
            console.log('Enter');
            var data = component.get("v.oppRecord")
            if(data.Customer_Type__c == 'Renewal Opportunity'){
                var action = component.get("c.checkMapping");
                action.setParams({ oppId : data.Id, oppAccId : data.Account__c});
            
            	action.setCallback(this, function(response) {
                	var state = response.getState();
                	if (state === "SUCCESS") {
                    	var result = response.getReturnValue();
                    	console.log(result);
                        console.log(data);
                        if(result == 'No Record Found'){
                          	component.set("v.isModalOpen", true);
                        	helper.getData(component, event, data.Account__c, 'New');
                        }
                    	
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
            
        } else if(eventParams.changeType === "REMOVED") {
            var resultsToast = $A.get("e.force:showToast");
            resultsToast.setParams({
                "title": "Deleted",
                "message": "The record was deleted."
            });
            resultsToast.fire();
        } else if(eventParams.changeType === "ERROR") {
            console.log(eventParams);
            console.log('Update event received Error: ' + component.get("v.error"));
        }
    },
    doInit : function(component, event, helper){
      	var pageReference = component.get("v.pageReference");
        if(pageReference != null && pageReference.state.c__Id != null){
            console.log(pageReference.state.c__Id);
            component.set("v.mode", "edit");
            component.set("v.isModalOpen", true);
            component.set("v.showSpinner", true);
            helper.getData(component, event, pageReference.state.c__msa, 'Edit');
        }
    },
    cancelModal : function (component, event) {
        var mode = component.get("v.mode");
        var pageReference = component.get("v.pageReference");
        if(mode == 'edit'){
            window.location.href = '/'+pageReference.state.c__Id
        }else{
         	component.set("v.isModalOpen", false);   
        }
    }, 
    
    handleNext : function(component, event, helper){
        var originalData = component.get("v.records");
        var filterData = [];
        var isCheck = false;
        console.log(originalData);
        originalData.forEach(rec => {
            if(rec.sfxRecord.checked == true){
            	isCheck = true;
            	rec.rateCardRecords.forEach(info => {
            		info.checked = false;
        		})
        		console.log(rec);
            	filterData.push(rec);
        	}
        })
		if(isCheck == false){
    		var toastEvent = $A.get("e.force:showToast");
     		toastEvent.setParams({
       			"type" : "error",
             	"title": "Error!",
             	"message": "Please select a SFX to be renewed."
          	});
        	toastEvent.fire();
        }else{
            console.log(filterData);
            component.set("v.filterSFXInfo", filterData);
            component.set("v.showSFX", false);
            component.set("v.showRateCard", true);
        }
    },
    handlePrevious : function(component, event, helper){
        component.set("v.showSFX", true);
        component.set("v.showRateCard", false);
        component.set("v.isAllCheckRateCard", false);
    },
 	selectSFX : function(component, event, helper){
        var allTrue = true;
        
        var allData = component.get("v.records");
        allData.forEach(data =>{
            console.log(data.sfxRecord.checked);
            if(data.sfxRecord.checked == false){
            	allTrue = false
        	}
        })
        component.set("v.records", allData);    
       	component.set("v.isAllCheckSfx", allTrue);
    },
    selectAllSFX : function(component, event, helper){
        console.log(event.getSource().get("v.checked"));
        var value = event.getSource().get("v.checked");
        var allData = component.get("v.records");
        
        allData.forEach(data =>{
            data.sfxRecord.checked = value;
        })
        component.set("v.records", allData);    
       	component.set("v.isAllCheckSfx", value);
    },
	selectRateCard : function(component, event, helper){
        var allTrue = true;
        
        var allData = component.get("v.filterSFXInfo");
        allData.forEach(data =>{
            data.rateCardRecords.forEach(info => {
            	if(info.checked == false){
            		allTrue = false
        		}
        	})        
        })
        component.set("v.filterSFXInfo", allData);    
       	component.set("v.isAllCheckRateCard", allTrue);
    }, 
    selectAllRateCard : function(component, event, helper){
        console.log(event.getSource().get("v.checked"));
        var value = event.getSource().get("v.checked");
        var allData = component.get("v.filterSFXInfo");
        
        allData.forEach(data =>{
            data.rateCardRecords.forEach(info => {
            	info.checked = value;
        	})        
        })
        component.set("v.filterSFXInfo", allData);    
    },
  	handleSave :  function(component, event, helper){
    	var data = component.get("v.filterSFXInfo");
        var sfxList = [];
        var isCheck = false;
        data.forEach(rec => {
            if(rec.sfxRecord.checked){
            	var str = rec.sfxRecord.SFX_Code__c+'=';
            	var rateCards = '';
            	rec.rateCardRecords.forEach(data =>{
            		if(data.checked){
            			isCheck = true;
            			if(!rateCards.includes(data.Name)){
            				if(rateCards == null || rateCards == ''){
            					rateCards = data.Name
        					}else{
                     			rateCards = rateCards+', '+data.Name
                     		}
        				}
       	 			}
        		})
        		str = str+rateCards;
        		sfxList.push(str);
        	}
        })
        if(isCheck == false){
    		var toastEvent = $A.get("e.force:showToast");
     		toastEvent.setParams({
       			"type" : "error",
             	"title": "Error!",
             	"message": "Please select a Rate Card to be renewed."
          	});
        	toastEvent.fire();
        }else{
            console.log('sfxList ==>'+sfxList);
            component.set("v.showSpinner", true);
            helper.saveData(component, event, sfxList);
        }
 	}
})