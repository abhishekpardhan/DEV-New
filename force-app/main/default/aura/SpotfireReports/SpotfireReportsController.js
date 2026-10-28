({
	doInit : function(component, event, helper) {
               
		var action = component.get("c.getReportLinks");
        
        action.setCallback(this,function(resp){
            var state = action.getState(); 
            if(state == "SUCCESS"){	              
                var returnValue = resp.getReturnValue();
                console.log('returnValue --> ',returnValue);
                if(returnValue.length > 0 && returnValue[0].srNo.includes('Exception')){
                    component.set("v.error",true);
                    component.set("v.errorMessage",'Exception Found '+returnValue[0].srNo);
                }
                else if(returnValue.length > 0){ 
                    component.set("v.linkExist",true);
                    component.set("v.wrapperReportLinks",returnValue);   
                }
                else{
                    component.set("v.error",true);
                    component.set("v.errorMessage",'No Reports Found');
                }
            }          
            else{
                component.set("v.error",true);
                component.set("v.errorMessage",'An Error has Occured!');
            }
        });
        $A.enqueueAction(action);
	}
})