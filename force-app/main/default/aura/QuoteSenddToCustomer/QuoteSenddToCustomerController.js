({    
    doinit : function(component, event, helper) {
        var qId = component.get("v.recordId");
        var action = component.get("c.checkQuoteStatus");
        action.setParams({
            "quoteId" : qId,
        });
        action.setCallback(this,function(resp){
            var state = action.getState();
            //alert('state : '+state);
            if(state == "SUCCESS"){
                var quote = resp.getReturnValue();
                if(quote.Approval_Status__c == "Approved By Corporate Head Credit/Retail" || quote.Approval_Status__c == "Approved By CCD"){
                    var action2 = component.get("c.getContacts");
					action2.setParams({
						"quoteId" : qId,
					});
					action2.setCallback(this,function(resp){
						var state1 = action2.getState();
						if(state1 == "SUCCESS"){
							var lstCon = resp.getReturnValue();
							if(lstCon.length > 0){
								component.set("v.sendEmail",true);
								component.set("v.listQuoteWrapper",lstCon);
							}else{
								$A.get("e.force:closeQuickAction").fire();
								var toastEvent = $A.get("e.force:showToast");
								toastEvent.setParams({
									"title": "Error!",
									"type" : "Error",
									"message": "Contact is not found."
								});
								toastEvent.fire();
							}
						}
					});
					$A.enqueueAction(action2);
                }
                else{
                    component.set("v.sendEmail",false);
                    $A.get("e.force:closeQuickAction").fire();
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "type" : "Error",
                        "message": "Quote is not approved yet."
                    });
                    toastEvent.fire();
                }
            }
        });
        $A.enqueueAction(action);
    },   
    sendToCustomer : function(component, event, helper) {
        component.set("v.Spinner",true);
        var listQuoteWrapper = component.get("v.listQuoteWrapper");
        var isSelect = false;
        var type ='';
        for(var i =0 ;i< listQuoteWrapper.length ; i++){
           // console.log('listQuoteWrapper[0] >> '+listQuoteWrapper[0].isSelected);
            if(listQuoteWrapper[i].isSelected){
                isSelect = true;
                if(listQuoteWrapper[i].typeId == 'To'){
                	type = 'To';
            	}
            }
        }
        //console.log('<< isSelect >> '+isSelect);
        //console.log('<< type >> '+type);
        if(!isSelect){
            component.set("v.message",'Please select atleast 1 Contact.');
            component.set("v.Spinner",false);
            component.set("v.errorMessage",true);
			return false;            
        }else if(type != 'To'){
            component.set("v.message",'Atleast 1 contact should have Type To');
            component.set("v.Spinner",false);
            component.set("v.errorMessage",true);
   			return false;
        }else{
            component.set("v.message",'');
            component.set("v.errorMessage",false);
        }
        var qId = component.get("v.recordId");
        var action = component.get("c.sendEmail");
        action.setParams({
            "qId" : qId,
            "listQuoteWrapper" : JSON.stringify(listQuoteWrapper)
        });
        //alert('<<<< qId new>>>>'+qId);
        action.setCallback(this,function(resp){
            var state = action.getState();           
            if(state == "SUCCESS"){              
                var returnValue = resp.getReturnValue();
                component.set("v.Spinner",false); 
                if(returnValue == 'No Attachment' || returnValue == 'No Email' || returnValue.includes('Exception')){
                    $A.get("e.force:closeQuickAction").fire();
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Error!",
                        "type" : "Error",
                        "message": returnValue
                    });
                    toastEvent.fire();
                }
                else{
                    $A.get("e.force:closeQuickAction").fire();
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "type" : "Success",
                        "message": "Email has been sent successfully."
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
            }
        });
        $A.enqueueAction(action);
    },
    closeModel : function(component, event, helper) {
    	component.set("v.sendEmail",false);
        $A.get("e.force:closeQuickAction").fire();
	}
})