({
	doinit : function(component, event, helper) {
		var action = component.get('c.getReleaseList');
      
        action.setCallback(this, function(response){
            var state = response.getState(); 
            //alert(state);
            if(state === 'SUCCESS' || state === 'DRAFT'){
                var responseValue = response.getReturnValue();
                console.log('responseValue', responseValue);
                component.set('v.releaseList', responseValue);
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
    
    show : function(component,event,helper){
        var elements = document.getElementsByClassName("myTest");
        elements[0].style.display = 'block';
    },
    hide : function(component,event,helper){
        var elements = document.getElementsByClassName("myTest");
        elements[0].style.display = 'none';
    }
})