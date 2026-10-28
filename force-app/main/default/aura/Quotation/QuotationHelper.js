({
	helperMethod : function() {
		
	},
	
	addSpecialDest : function(component,event,helper, index){
        
        var specialState = component.find("specialState").get("v.value");
        var specialCity = component.find("specialCity").get("v.value");
        var specialSurface = component.find("specialSurface").get("v.value");
        var specialAir = component.find("specialAir").get("v.value");
        var listValue = component.get("v.specialValues");
        console.log('111'+component.get("v.isUpdateSpecDest"));
        if(component.get("v.isUpdateSpecDest"))
        {
        	console.log('1112');
        	//var listValue = component.get("v.specialValues");
        	if(listValue != null && listValue.length > 0)
	    	{
	    		console.log('1113');
	    		var item = {State: specialState, City: specialCity, SurfacePrice: specialSurface, AirPrice: specialAir} ;
	    		console.log('1114'+JSON.stringify(item));
	    		listValue[index] = {State: "", City: "", SurfacePrice: 0, AirPrice: 0};
	    		console.log('1115'+JSON.stringify(listValue));
	    		var duplicateStateMsg = this.validateSpecialDest(component,event,helper, specialState, specialCity, listValue);	
				{
					if(duplicateStateMsg != null && duplicateStateMsg != "")
					{
						alert(duplicateStateMsg);  
						return;
					}
				}
				listValue[index] = item;
	    		component.set("v.specialValues", listValue);
	    		//listValue.splice(index+1, 1);
	    	}
	    	
	    	component.set("v.specialSurface", 0);
	        component.set("v.specialAir", 0);
	        component.set("v.specialState", "Select State");
	        component.set("v.specialCity", "Select City");
	        component.set("v.isUpdateSpecDest", false);
        } else
        {
	        var list = [ { State: specialState, City: specialCity, SurfacePrice: specialSurface, AirPrice: specialAir } ];			
	        var duplicateStateMsg = this.validateSpecialDest(component,event,helper, specialState, specialCity, component.get("v.specialValues"));	
			{
				if(duplicateStateMsg != null && duplicateStateMsg != "")
				{
					alert(duplicateStateMsg);  
					return;
				}
			}
	        if(listValue.length > 0)
	        {            
	        	listValue.push({State: specialState, City: specialCity, SurfacePrice: specialSurface, AirPrice: specialAir});
	        	component.set("v.specialValues",listValue);
	        }
	        else{            
	        	component.set("v.specialValues",list);
	        }
        }
        component.set("v.showSpecialTable", true);
        component.set("v.showModal", false);
    },
    
    validateSpecialDest : function(component,event,helper, state, city, specialValuesList)
    {
    	if(state == null || state == "")
    	{
    		return "Please select state.";
    	}
    	if(city == null || city == "")
    	{
    		return "Please select city";
    	}
    	//var specialValuesList = component.get("v.specialValues");
    	
    	if(specialValuesList != null && specialValuesList.length> 0)
    	{
    		for (var i = 0; i < specialValuesList.length; i++) 
    		{ 
    			var existingState = specialValuesList[i].State;
    			var existingCity = specialValuesList[i].City;
    			if(existingState == state)
    			{
    				if(existingCity == city)
	    			{
    					return state+" and "+city+" are already selected.";
	    			}
    			}
    		}
    	}
    	return "";
    },
    
    addStateSurcharge : function(component,event,helper, index)
	{
	                    
		var state = component.find("surchargeState").get("v.value");
		var surface = component.find("surchargeSurface").get("v.value");
		var air = component.find("surchargeAir").get("v.value");
       // var surDesc = component.find("stateDesription").get("v.value");
        //alert('surDesc >> '+surDesc);
		var listSur = component.get("v.lstStateSurcharge");
	   	//alert('listSur----',listSur);  
	    if(state.includes(";"))
		{
			state = state.replace(/;/g, ",");
		}
	    
	    if(component.get("v.isUpdatestateSurch"))
        {
	    	if(listSur != null && listSur.length > 0)
	    	{
                var item = { State: state,  SurfacePrice: surface, AirPrice: air  }  ;
	    		console.log('1114' ,JSON.stringify(item));
	    		listSur[index] = { State: "",  SurfacePrice: 0, AirPrice: 0 };
	    		console.log('1115'+JSON.stringify(listSur));
	    		var duplicateStateMsg = this.validateStateSurcharge(component,event,helper, state, listSur);	
				{
					if(duplicateStateMsg != null && duplicateStateMsg != "")
					{
						alert(duplicateStateMsg);  
						return;
					}
				}
				listSur[index] = item;
	    		component.set("v.lstStateSurcharge", listSur);
	    		
	    		component.set("v.stateSurchSurface", 0);
		        component.set("v.stateSurchAir", 0);
		        component.set("v.stateSurch", "");
                component.set("v.stateSurchDescription", "");
		        component.set("v.isUpdatestateSurch", false);
	    	}
        } else
        {
            //alert('else');
        	var list = 	[
                { State: state,  SurfacePrice: surface, AirPrice: air}                            
					];	
			var duplicateStateMsg = this.validateStateSurcharge(component,event,helper, state, component.get("v.lstStateSurcharge"));	
			{
				if(duplicateStateMsg != null && duplicateStateMsg != "")
				{
					alert(duplicateStateMsg);  
					return;
				}
			}	
			if(listSur.length > 0){            
				listSur.push({ State: state,  SurfacePrice: surface, AirPrice: air });
				component.set("v.lstStateSurcharge",listSur);
			}
			else{            
				component.set("v.lstStateSurcharge",list);
			}
        }
		console.log('<< listSur >> '+listSur);           
		component.set("v.showCustomStateSur",false);
		component.set("v.showSurchargeTable",true);
	},
	
	validateStateSurcharge : function(component,event,helper, selectedState, existingRecords)
	{
		if(selectedState == null || selectedState == "")
		{
			return "Please select atleast one state.";
			
		} else
		{	
			var selectedStates = selectedState.split(",");
			if(selectedStates.length > 5 )
			{
				//return "Please do not select more than 5 states in a single quote.";
			}
			var existingRecords = component.get("v.lstStateSurcharge");
			for (var i = 0; i < selectedStates.length; i++) { 
				if(existingRecords != null && existingRecords.length > 0)
				{
					for(var j = 0; j < existingRecords.length; j++)
					{
						if(existingRecords[j] != null && existingRecords[j].State != null )
						{
							var existingRecStates = existingRecords[j].State.split(",");
							if(existingRecStates.includes(selectedStates[i]))
							{
								//alert(selectedStates[i]+" is already selected.");
								return selectedStates[i]+" is already selected.";
							}	
						}
					}
				}
			}
		}
		return ""; 
	},
	
	getDocElementId : function(component,event,helper, docElementId)
	{
		if(component.get("v.disableEdit"))
		{
			docElementId = docElementId.toUpperCase();
		}
		return docElementId;
    }
})