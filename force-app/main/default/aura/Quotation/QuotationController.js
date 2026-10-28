({
    doinit : function(component, event, helper) {
        //alert('testtttt444');
        component.set('v.columns', [
            {label: 'Commandment', fieldName: 'Name', type: 'text'},
            {label: 'Surface', fieldName: 'SurfacePrice', editable:true, type: 'number'},
            {label: 'Air', fieldName: 'AirPrice', editable:true, type: 'number'},            
        ]);
            
            
            var selectedExState = "";   
            
            var id = component.get("v.recordId");
            console.log('id--'+id);    
            var readOnlyAction = component.get("c.checkReadonly");
            readOnlyAction.setParams({
            "qId" : id
            }); 
            readOnlyAction.setCallback(this,function(resp){
            var state = resp.getState();
            console.log('state--'+state);
            if(state == 'SUCCESS'){
            console.log('resp.getReturnValue()--'+resp.getReturnValue());
            component.set("v.isReadOnly", resp.getReturnValue());
            }
            });
            console.log('readOnlyAction++++');
            $A.enqueueAction(readOnlyAction);
            
            var action = component.get("c.checkQuote2");            
            action.setParams({
            "qid" : id
            });
            action.setCallback(this,function(resp){
            var state = resp.getState();
            if(state == 'SUCCESS'){
            console.log('checkQuote2 state++ '+state);
            var response = resp.getReturnValue();
            //If quote is already created and need to update
            if(response != null){
            var zone = response['Zone Prices'];
                      //component.find("Ex_State").set("v.value",zone[0].Exstate);
                      console.log('--component.find("Ex_State")--'+component.find("Ex_State"));
        console.log('--component.get("v.quoteExState")--'+component.get("v.quoteExState"));
        //component.set("v.isReadOnly", true);
        //component.set("v.quoteExState", "XYZ");
        if(zone != null){ 
            selectedExState = zone[0].Exstate;
            console.log("-quoteExState-- "+zone[0].Exstate+'-quoteExState- '+component.get("v.quoteExState"));
            
            console.log('--zone-'+zone.length);
            component.set("v.lstWrapper",zone);
        }
        component.set("v.disableEdit",true);
        component.set("v.showStateTable",true);
        var special = response['Special Destinations'];        
        if(special != null){
            component.set("v.specialValues",special);
            component.set("v.showSpecialTable",true);                    
        }
        var commandments = response['Commandments'];
        component.set("v.lstCommandment",commandments);
        var safextension = response['Safextension'];
        component.set("v.safextension",safextension);
        
        var surcharge = response['State Surcharge'];        
        if(surcharge != null){
            component.set("v.lstStateSurcharge",surcharge);
            component.set("v.showSurchargebutton",true); 
            component.set("v.showSurchargeTable",true);
            component.find("statesurcharge").set("v.value","Yes");
        }
    }
    else{   //If new quote to be created
    var action2 = component.get("c.getCommandment");
    action2.setCallback(this,function(resp2){
    var state2 = resp2.getState();
    if(state2 == 'SUCCESS'){
    console.log('lst comman ' , resp2.getReturnValue());
    component.set("v.lstCommandment",resp2.getReturnValue());
    //component.set("v.showStateTable",true);
}
 else{
 alert('elsein');
}
});
$A.enqueueAction(action2);

var listSafext = [
    { Name: 'Safextension 1', Rate: 0, MinimumFrt: 0},
    { Name: 'Safextension 2', Rate: 0, MinimumFrt: 0}
];
component.set("v.safextension",listSafext);

}
}
else{
    alert("elseout");
    
}
});
$A.enqueueAction(action); 

var action3 = component.get("c.getStates");
action3.setCallback(this,function(resp3){			
    var state3 = resp3.getState();
    if(state3 == 'SUCCESS'){
        component.set("v.lstStates",resp3.getReturnValue()[0]);
        component.set("v.lstStatesSurcharge",resp3.getReturnValue()[1]);
        component.set("v.quoteExState", selectedExState); 
        console.log('----component.set("v.quoteExState")---'+component.get("v.quoteExState"));
        //selectedExState = zone[0].Exstate;            
    }
    else{
        alert('Error States');
    }
});
$A.enqueueAction(action3);

/*var action4 = component.get("c.getCity");
        action4.setCallback(this,function(resp4){			
            var state4 = resp4.getState();
            if(state4 == 'SUCCESS'){
                component.set("v.lstCity",resp4.getReturnValue());                
            }
            else{
                alert('Error');
            }
         });
		$A.enqueueAction(action4);*/

},
    
    clickExState : function(component, event, helper) {
        
        component.set("v.showStateTable",true);
        //var Exstate = component.find("Ex_State").get("v.value");     
        var Exstate = component.get("v.quoteExState");    
        var action = component.get("c.getZone");
        action.setParams({
            "ExState" : Exstate                        
        });
        action.setCallback(this,function(resp){
            var state = resp.getState();
            if(state == 'SUCCESS'){
                console.log('--resp.getReturnValue()-'+resp.getReturnValue().length);
                component.set("v.lstWrapper",resp.getReturnValue());
                
            }
        });
        $A.enqueueAction(action);
        
    },
        
        surfacepriceChange : function(component, event, helper) {
            
            var pricetype = component.find("surfaceprice").get("v.value");
            //var airtype = component.find("airprice").get("v.value");
            component.set("v.showStateTable",true);
            //var Exstate = component.find("Ex_State").get("v.value"); 
            var Exstate = component.get("v.quoteExState"); 
            var action = component.get("c.getStates");
            action.setParams({
                "ExState" : Exstate                                 
            });
            action.setCallback(this,function(resp){
                var state = resp.getState();
                if(state == 'SUCCESS'){
                    console.log('--resp.getReturnValue()3-'+resp.getReturnValue().length);
                    component.set("v.lstWrapper",resp.getReturnValue());
                    
                }
            });
            $A.enqueueAction(action);
            
        },
            
            airpriceChange : function(component, event, helper) {
                
                var pricetype = component.find("surfaceprice").get("v.value");
                var airtype = component.find("airprice").get("v.value");
                component.set("v.showStateTable",true);
                //var Exstate = component.find("Ex_State").get("v.value"); 
                var Exstate = component.get("v.quoteExState"); 
                var action = component.get("c.getStates");
                action.setParams({
                    "ExState" : Exstate,
                    "ttype1" : "Surface",
                    "rtype1" : pricetype,
                    "ttype2" : "Air",
                    "rtype2" : airtype
                });
                action.setCallback(this,function(resp){
                    var state = resp.getState();
                    if(state == 'SUCCESS'){
                        console.log('--resp.getReturnValue()2-'+resp.getReturnValue().length);
                        component.set("v.lstWrapper",resp.getReturnValue());                
                    }
                });
                $A.enqueueAction(action);
                
            },
                
                onSave : function(component, event, helper) {
                    
                    var editedRecords =  component.find("accountDataTable").get("v.draftValues");
                    
                },
                    
                    showSpinner: function(component, event, helper) {
                        // make Spinner attribute true for display loading spinner 
                        component.set("v.Spinner", true); 
                    },
                        
                        hideSpinner : function(component,event,helper){
                            // make Spinner attribute to false for hide loading spinner    
                            component.set("v.Spinner", false);
                        },
                            
                            showModal  : function(component,event,helper){  
                                
                                if(!component.get("v.isUpdateSpecDest"))
                                {
                                    component.set("v.specialSurface", 0);
                                    component.set("v.specialAir", 0);
                                    component.set("v.specialState", "Select State");
                                    component.set("v.specialCity", "Select City");
                                }      
                                component.set("v.showModal", true);
                                var action = component.get("c.getDependentPicklist");
                                /* action.setParams({
                                    "objApiName" : "lead__c",
                                    "contrfieldApiName" : "state__c",
                                    "depfieldApiName" : "city__c"
                                });*/
                                action.setCallback(this,function(resp){
                                    var state = resp.getState();
                                    if(state == 'SUCCESS'){
                                        var StoreResponse = resp.getReturnValue(); 
                                        component.set("v.Dependency",StoreResponse);
                                    }
                                });
                                $A.enqueueAction(action);
                                
                            },
                                
                                editSpecialDest : function(component,event,helper)
{
    if(component.get("v.isReadOnly"))
    {
        return;
    }
    component.set("v.showModal", true);
    component.set("v.isUpdateSpecDest", true);
    
    var ctarget = event.currentTarget;
    var index = ctarget.dataset.value;
    component.set("v.specialDesIndex", index);
    var listValue = component.get("v.specialValues");
    var specDest = listValue[index];
    component.set("v.specialSurface", specDest.SurfacePrice);
    component.set("v.specialAir", specDest.AirPrice);
    component.set("v.specialState", specDest.State);
    component.set("v.specialCity", specDest.City);
    
    var emptylist = [];
    component.set("v.lstCity",emptylist);
    var sstate = specDest.State;
    
    var action = component.get("c.getDependentPicklist");
    /* action.setParams({
        "objApiName" : "lead__c",
        "contrfieldApiName" : "state__c",
        "depfieldApiName" : "city__c"
    });*/
    action.setCallback(this,function(resp){
        var state = resp.getState();
        if(state == 'SUCCESS'){
            var StoreResponse = resp.getReturnValue(); 
            component.set("v.Dependency",StoreResponse);
        }
        var StoreResponse = component.get("v.Dependency");
        var listOfkeys = [];
        var ControllerField = [];
        for (var singlekey in StoreResponse.keys) {
            listOfkeys.push(singlekey);
        }                        
        var ListOfDependentFields = StoreResponse[sstate];
        component.set("v.lstCity",ListOfDependentFields);   
    });
    $A.enqueueAction(action); 
},
    
    removeSpecialDest : function(component,event,helper)
{
    if(component.get("v.isReadOnly"))
    {
        return;
    }
    var ctarget = event.currentTarget;
    var index = ctarget.dataset.value;
    var listValue = component.get("v.specialValues");
    if(listValue != null && listValue.length > 0)
    {
        var removedSpcDest = listValue.splice(index, 1);
        var listToBeDetelte = component.get("v.lstToBeDelete");
        console.log('removedSpcDest--'+JSON.stringify(removedSpcDest));
        if(removedSpcDest.length > 0)
        {
            listToBeDetelte.push(removedSpcDest[0]);
            component.set("v.lstToBeDelete",listToBeDetelte);
        }
        
    }
    component.set("v.specialValues", listValue);
    if(listValue.length == 0)
    {
        component.set("v.showSpecialTable", false);
    }
    
},
    
    addSpecialDest : function(component,event,helper){
        helper.addSpecialDest(component,event,helper, component.get("v.specialDesIndex"));
    },
        closeModel : function(component,event,helper){
            component.set("v.showModal", false);
            component.set("v.showCustomStateSur", false);
            component.set("v.isUpdatestateSurch", false);
            component.set("v.isUpdateSpecDest", false);
        },
            
            removeStateSurcharge : function(component,event,helper)
{
    if(component.get("v.isReadOnly"))
    {
        return;
    }
    var ctarget = event.currentTarget;
    var index = ctarget.dataset.value;
    var listValue = component.get("v.lstStateSurcharge");
    if(listValue != null && listValue.length > 0)
    {
        var removedStateSurch = listValue.splice(index, 1);
        var listToBeDetelte = component.get("v.lstToBeDelete");
        console.log('removedStateSurch--'+JSON.stringify(removedStateSurch));
        if(removedStateSurch.length > 0 )
        {
            listToBeDetelte.push(removedStateSurch[0]);
            component.set("v.lstToBeDelete",listToBeDetelte);
        }
        
    }
    component.set("v.lstStateSurcharge", listValue);
    if(listValue.length == 0)
    {
        component.set("v.showSurchargeTable", false); 
    }
    
},
    
    editStateSurcharge : function(component,event,helper)
{
    if(component.get("v.isReadOnly"))
    {
        return;
    }
    component.set("v.showCustomStateSur",true);
    component.set("v.isUpdatestateSurch", true);
    
    var ctarget = event.currentTarget;
    var index = ctarget.dataset.value;
    component.set("v.stateSurchIndex", index);
    var listValue = component.get("v.lstStateSurcharge");
    var StateSurcharge = listValue[index];
    if(StateSurcharge != null && StateSurcharge.State != null && StateSurcharge.State.includes(",") )
    {
        StateSurcharge.State = StateSurcharge.State.replace(/,/g, ";");
    }
    //alert('!@--- '+JSON.stringify(StateSurcharge));
    component.set("v.stateSurch", StateSurcharge.State);
    component.set("v.stateSurchSurface", StateSurcharge.SurfacePrice);
    component.set("v.stateSurchAir", StateSurcharge.AirPrice);
    console.log('<< StateSurcharge.stateSurDescription >> '+StateSurcharge.stateSurDescription);
    component.set("v.stateSurchDescription", StateSurcharge.stateSurDescription);
},
    
    save : function(component,event,helper){
        
        console.log('sur des >>' ,component.get("v.stateSurchDescription"));
        var Exstate1 = component.get("v.quoteExState"); // Shubham Girdhar
        if (Exstate1 == null){
            alert('Please fill the complete form or attach the PDF file in Related tab');
        }else{
            
            
            var val2 = component.get("v.specialValues");
            var val = JSON.stringify(val2);
            var qid = component.get("v.recordId");
            var action = component.get("c.saveQLI");
            var cmd = component.get("v.lstCommandment");
            console.log("JSON.stringify(cmd)--"+JSON.stringify(cmd));
            var command = [];
            //var exstate = component.find("Ex_State").get("v.value");
            var exstate = component.get("v.quoteExState"); 
            /*for(var i=0;i<cmd.length;i++){
            if(cmd[i].check == true){
                command.push(cmd[i]);
            }
        }*/ 
            var lstDelete = component.get("v.lstToBeDelete");  
            console.log('lstDelete---'+lstDelete); 
            
            action.setParams({
                "lstVal" : val,
                "lstZoneState" : JSON.stringify(component.get("v.lstWrapper")),
                "lstCommandment" : JSON.stringify(cmd),
                "qId" : qid,
                "lstSafextension" : JSON.stringify(component.get("v.safextension")),
                "exstate" : exstate,
                "stateSurcharge" : JSON.stringify(component.get("v.lstStateSurcharge")),
                "lstDelete" : JSON.stringify(lstDelete) 
                
            });
            action.setCallback(this,function(response)
                               {
                                   if(response.getState() == 'SUCCESS')
                                   {
                                       //var result = response.getReturnValue();
                                       $A.get("e.force:closeQuickAction").fire();
                                       var toastEvent = $A.get("e.force:showToast");
                                       toastEvent.setParams({
                                           "title": "Success!",
                                           "type" : "Success",
                                           "message": "Quotation is submitted successfully."
                                       });
                                       toastEvent.fire();
                                   } else if (response.getState() === "ERROR")
                                   {
                                       var errors = response.getError();
                                       //alert('response.getError()--'+JSON.stringify(errors[0])) 
                                       if (errors) {
                                           if (errors[0] && errors[0].message) {
                                               alert('Error: '+errors[0].message);
                                           } else if(errors[0].fieldErrors)
                                           {
                                               console.log("---------"+JSON.stringify(errors));
                                           }
                                           
                                       }
                                   }
                               });
            $A.enqueueAction(action);
        } 
    }
,
    
    closeQuotationModel : function(component,event,helper)
{
    $A.get("e.force:closeQuickAction").fire();
},
    
    clicksafext : function(component,event,helper){
        
        var value = component.find("safext").get("v.value");
        if(value == 'Group'){
            component.set("v.safextType","Safextension Group");
            var listSafext = [
                { Name: 'Safextension 1', Rate: 0, MinimumFrt: 0},
                { Name: 'Safextension 2', Rate: 0, MinimumFrt: 0}
            ];
            component.set("v.safextension",listSafext);
        }
        
        else if(value == 'Zone'){
            component.set("v.safextType","Safextension Zone");
            var listSafext2 = [
                { Name: 'Safextension Jammu And Kashmir And North East', Rate: 0, MinimumFrt: 0},
                { Name: 'Safextension Rest of India', Rate: 0, MinimumFrt: 0}
            ];
            component.set("v.safextension",listSafext2);
        }
    },
        
        openSurchargeModal : function(component,event,helper){
            component.set("v.stateSurchSurface", 0);
            component.set("v.stateSurchAir", 0);
            component.set("v.stateSurch", "");
            component.set("v.stateSurchDescription", "");
            component.set("v.showCustomStateSur",true);
        },
            stateSurcharge : function(component,event,helper){
                var value = component.find("statesurcharge").get("v.value");
                if(value == 'Yes'){
                    component.set("v.showSurchargebutton",true);
                }
                else{
                    component.set("v.showSurchargebutton",false);
                }
            },
                
                addStateSurcharge : function(component,event,helper){
                    helper.addStateSurcharge(component,event,helper, component.get("v.stateSurchIndex"))
                },
                    
                    specialdeststate : function(component,event,helper){
                        var emptylist = [];
                        component.set("v.lstCity",emptylist);
                        var sstate = component.find("specialState").get("v.value");
                        console.log('before call state >> '+sstate);
                        if(component.get("v.Dependency") == null)
                        {
                            console.log('component.get("v.Dependency") >> '+component.get("v.Dependency"));
                            var action = component.get("c.getDependentPicklist");
                            /*action.setParams({
                                "objApiName" : "lead__c",
                                "contrfieldApiName" : "state__c",
                                "depfieldApiName" : "city__c"
                            });*/
                            action.setCallback(this,function(resp){
                                var state = resp.getState();
                                if(state == 'SUCCESS'){
                                    var StoreResponse = resp.getReturnValue(); 
                                    component.set("v.Dependency",StoreResponse);
                                }
                                var StoreResponse = component.get("v.Dependency");
                                var listOfkeys = [];
                                var ControllerField = [];
                                for (var singlekey in StoreResponse.keys) {
                                    listOfkeys.push(singlekey);
                                }                        
                                console.log('StoreResponse >> ',StoreResponse);
                                var ListOfDependentFields = StoreResponse[sstate];
                                console.log('ListOfDependentFields >> ',ListOfDependentFields);
                                component.set("v.lstCity",ListOfDependentFields);   
                            });
                            $A.enqueueAction(action);
                        } else
                        {
                            var StoreResponse = component.get("v.Dependency");
                            var listOfkeys = [];
                            var ControllerField = [];
                            for (var singlekey in StoreResponse.keys) {
                                listOfkeys.push(singlekey);
                            }                        
                            var ListOfDependentFields = StoreResponse[sstate];
                            component.set("v.lstCity",ListOfDependentFields);   
                        }
                        
                    },
                        
                        calculateYield : function(component,event,helper){
                            console.log('Inside calculte yield');
                            //console.log("v.lstCommandment---"+JSON.stringify(component.get("v.lstCommandment")));
                            
                            var minCharObj;
                            var valueSurchObj;
                            var waybillChargeObj;
                            var fuelSurchObj;
                            var podCharge;
                            
                            var cmdList = component.get("v.lstCommandment");
                            for(var i=0; i<cmdList.length; i++)
                            {
                                if(cmdList[i].Name.toUpperCase() == "MIN CHARGEABLE WEIGHT")
                                {
                                    minCharObj = cmdList[i];
                                }
                                if(cmdList[i].Name.toUpperCase() == "VALUE SURCHARGE")
                                {
                                    valueSurchObj = cmdList[i];
                                }
                                if(cmdList[i].Name.toUpperCase() == "WAYBILL CHARGE")
                                {
                                    waybillChargeObj = cmdList[i];
                                }
                                if(cmdList[i].Name.toUpperCase() == "FUEL SURCHARGE (%AGE)")
                                {
                                    fuelSurchObj = cmdList[i];
                                }
                                if(cmdList[i].Name.toUpperCase() == "POD CHARGE")
                                {
                                    podCharge = cmdList[i];
                                }
                            }
                            //console.log("minCharObj---"+JSON.stringify(minCharObj)+"---"+JSON.stringify(valueSurchObj)+
                            //"---"+JSON.stringify(waybillChargeObj)+"---"+JSON.stringify(fuelSurchObj)+"---"+JSON.stringify(podCharge));
                            var SurfaceMinCh ;
                            var AirMinCh ;
                            //if(document.getElementById("SMin Chargeable Weight") != null){
                            //console.log("-----1--1--"+component.find("SMIN CHARGEABLE WEIGHT"));
                            //SurfaceMinCh = Number(document.getElementById(helper.getDocElementId(component,event,helper,"SMin Chargeable Weight")).value);
                            SurfaceMinCh = minCharObj.SurfacePrice; //;Number(component.find(helper.getDocElementId(component,event,helper,"SMin Chargeable Weight")).get("v.value")); 
                            //}
                            console.log('SurfaceMinCh '+SurfaceMinCh);
                            //if(document.getElementById("AMin Chargeable Weight") != null){
                            //AirMinCh = Number(document.getElementById(helper.getDocElementId(component,event,helper,"AMin Chargeable Weight")).value);
                            AirMinCh = minCharObj.AirPrice; //Number(component.find(helper.getDocElementId(component,event,helper,"AMin Chargeable Weight")).get("v.value"));
                            //}
                            console.log('AirMinCh '+AirMinCh);
                            // var AirMinCh = Number(document.getElementById("AMin Chargeable Weight").value);
                            var surfaceavgwt;
                            var airavgwt;
                            var zoneprices = component.get("v.lstWrapper");
                            var specialdest = component.get("v.specialValues");
                            var id = component.get("v.recordId");
                            console.log('id '+id);
                            var action = component.get("c.getOpportunityDetail");            
                            action.setParams({
                                "qid" : id
                            });       
                            console.log('after calculte yield');
                            action.setCallback(this,function(resp){
                                var state = resp.getState();
                                console.log('state '+ state);
                                if(state == 'SUCCESS'){                            
                                    var response = resp.getReturnValue();
                                    var commandmentSumSurface = 0;
                                    var commandmentSumAir = 0;  
                                    //alert('--------'+JSON.stringify(response));
                                    var avgwt = response.Opportunity__r.Avg_wt_of_consignment_Kg__c;
                                    var valuegoodspkg = response.Opportunity__r.Value_of_Goods_Kg__c;
                                    //Calculation of X
                                    if(avgwt >= SurfaceMinCh){
                                        
                                        surfaceavgwt = avgwt;
                                        
                                    }
                                    else{
                                        surfaceavgwt = SurfaceMinCh;
                                        
                                    }
                                    console.log("!@--1");
                                    //Calculation of X
                                    if(avgwt >= AirMinCh){
                                        airavgwt = avgwt;
                                    }
                                    else{
                                        airavgwt = AirMinCh;
                                    }
                                    console.log("!@--2");
                                    //console.log("!@1---"+helper.getDocElementId(component,event,helper,"SWaybill Charge"));
                                    //console.log("!@2---"+helper.getDocElementId(component,event,helper,"AWaybill Charge"));
                                    var waybillChargeSurface = waybillChargeObj.SurfacePrice ;//Number(component.find(helper.getDocElementId(component,event,helper,"SWaybill Charge")).get("v.value"));
                                    var waybillChargeAir = waybillChargeObj.AirPrice ;//Number(document.getElementById(helper.getDocElementId(component,event,helper,"AWaybill Charge")).get("v.value")); 
                                    var podchargeSurface = podCharge.SurfacePrice;
                                    var podChargeAir = podCharge.AirPrice;
                                    console.log("!@--3");
                                    console.log("!@--31"+waybillChargeSurface+' '+waybillChargeAir);
                                    console.log("!@--31"+podchargeSurface+' '+podChargeAir);							
                                    for(var i=0;i<zoneprices.length;i++){
                                        var valueSurchargeSur;
                                        //var docElementId = component.get("v.disableEdit") ?  : ;
                                        //console.log("!@--32"+helper.getDocElementId(component,event,helper,"SValue Surcharge")+"%age");
                                        //console.log("!@--33"+helper.getDocElementId(component,event,helper,"SValue Surcharge")+"Min.");
                                        var  valueSurchargeSurPercentage = valueSurchObj.surfacePercentage; //document.getElementById(helper.getDocElementId(component,event,helper,"SValue Surcharge")+"%age").value;
                                        var  valueSurchargeSurMin = valueSurchObj.surfaceMin; //document.getElementById(helper.getDocElementId(component,event,helper,"SValue Surcharge")+"Min.").value;
                                        var valueSurfaceInvoice = valueSurchObj.surfaceInvoice;
                                        //var percentageValOfGoodsSur = (valueSurchargeSurPercentage * valuegoodspkg )/100
                                        if(valueSurchargeSurMin != null && valueSurfaceInvoice > 0){ //added by Shubham
                                            valueSurchargeSur = ( valuegoodspkg > valueSurfaceInvoice ? (Math.ceil(valuegoodspkg/valueSurfaceInvoice) * valueSurchargeSurMin): valueSurchargeSurMin) ;
                                        }
                                        else if(valueSurchargeSurPercentage != null){
                                            valueSurchargeSur = (valueSurchargeSurPercentage * valuegoodspkg )/100;
                                        }
                                        console.log('<< valueSurchargeSur ++ '+valueSurchargeSur);
                                        //Calculation of 1.3
                                        //var ValueSurCalSur =  (valuegoodspkg * surfaceavgwt * valueSurchargeSur) / 100;
                                        //console.log("!@--4--- ValueSurCalSur 1.3 "+ValueSurCalSur);
                                        //Cal of 1.1 and 1.2
                                        console.log("!@--4/"+surfaceavgwt+'--'+zoneprices[i].SurfacePrice+'--'+waybillChargeSurface);
                                        zoneprices[i].YieldSurface = (surfaceavgwt * zoneprices[i].SurfacePrice) + waybillChargeSurface+ podchargeSurface;
                                        console.log('<< zoneprices[i].YieldSurface >> '+zoneprices[i].YieldSurface);
                                        console.log("!@--41");
                                        //Cal of 1.4
                                        zoneprices[i].YieldSurface +=  valueSurchargeSur;
                                        //zoneprices[i].YieldSurface +=  ValueSurCalSur;
                                        console.log("!@--42  1.4 "+zoneprices[i].YieldSurface);
                                        var fuelSurDrop = component.find("fuelsurDropdown").get("v.value");
                                        console.log("!@--43");
                                        //var FuelSurchargeSur = document.getElementById(helper.getDocElementId(component,event,helper,"SFuel Surcharge (%age)")).value;
                                        var FuelSurchargeSur = fuelSurchObj.SurfacePrice; //component.find(helper.getDocElementId(component,event,helper,"SFuel Surcharge (%age)")).get("v.value");
                                        
                                        console.log("!@--5");
                                        //Cal of 1.5
                                        var fuelSurCalSur;
                                        if(fuelSurDrop == 'Total'){
                                            fuelSurCalSur = (zoneprices[i].YieldSurface * FuelSurchargeSur) / 100;  
                                            
                                        }
                                        else if(fuelSurDrop == 'Basic'){
                                            fuelSurCalSur = ((surfaceavgwt * zoneprices[i].SurfacePrice) * FuelSurchargeSur) / 100;
                                            
                                        }
                                        console.log('cal of 1.5 ===  '+fuelSurCalSur);
                                        console.log("!@--6");
                                        //Cal of 1.6
                                        zoneprices[i].YieldSurface += fuelSurCalSur;
                                        console.log('1.6++++ '+zoneprices[i].YieldSurface);
                                        //Cal of 1.7
                                        zoneprices[i].YieldSurface = zoneprices[i].YieldSurface / surfaceavgwt;
                                        console.log("!@--7");
                                        console.log('1.7++++ '+zoneprices[i].YieldSurface);
                                        //For AIR
                                        var valueSurchargeAir;
                                        var  valueSurchargeAirPercentage = valueSurchObj.airPercentage;//document.getElementById(helper.getDocElementId(component,event,helper,"AValue Surcharge")+"%age").value;
                                        var  valueSurchargeAirMin = valueSurchObj.airMin;//document.getElementById(helper.getDocElementId(component,event,helper,"AValue Surcharge")+"Min.").value;
                                        var valueairInvoice = valueSurchObj.airInvoice;
                                        //var percentageValOfGoodsAir = (valueSurchargeAirPercentage * valuegoodspkg )/100;
                                        if(valueSurchargeAirMin != null && valueairInvoice > 0){//Added by Shubham
                                            valueSurchargeAir = (valuegoodspkg > valueairInvoice  ? (Math.ceil(valuegoodspkg / valueairInvoice)* valueSurchargeAirMin) : valueSurchargeAirMin) ;
                                        }else if(valueSurchargeAirPercentage != null){
                                            valueSurchargeAir = (valueSurchargeAirPercentage * valuegoodspkg )/100;
                                        }
                                        console.log(' air cal valueSurchargeAir '+valueSurchargeAir);
                                        // var ValueSurCalAir =  ((valuegoodspkg * airavgwt) * valueSurchargeAir) / 100;
                                        //console.log('air cal 1.3 '+ValueSurCalAir);
                                        
                                        zoneprices[i].YieldAir = (airavgwt * zoneprices[i].AirPrice) + waybillChargeAir +podChargeAir;
                                        console.log('air cal 1.1 amd 1.2 '+zoneprices[i].YieldAir );
                                        
                                        zoneprices[i].YieldAir +=  valueSurchargeAir;
                                        console.log('air cal 1.4 '+zoneprices[i].YieldAir );
                                        console.log("!@--8");
                                        var FuelSurchargeAir = fuelSurchObj.AirPrice ;//component.find(helper.getDocElementId(component,event,helper,"AFuel Surcharge (%age)")).get("v.value");                                
                                        var fuelSurCalAir;
                                        if(fuelSurDrop == 'Total'){
                                            fuelSurCalAir = (zoneprices[i].YieldAir * FuelSurchargeAir) / 100;                                    
                                        }
                                        else if(fuelSurDrop == 'Basic'){
                                            fuelSurCalAir = ((airavgwt * zoneprices[i].AirPrice) * FuelSurchargeAir) / 100;                                
                                        }
                                        console.log('air cal 1.5 '+fuelSurCalAir );
                                        console.log("!@--9");
                                        zoneprices[i].YieldAir += fuelSurCalAir;
                                        console.log('air cal 1.6 '+zoneprices[i].YieldAir );
                                        zoneprices[i].YieldAir = zoneprices[i].YieldAir / airavgwt;
                                        console.log('air cal 1.7'+zoneprices[i].YieldAir );
                                    }
                                    
                                    //Special Destination
                                    if(specialdest.length > 0){
                                        console.log("!@--10");
                                        for(var i=0;i<specialdest.length;i++){
                                            console.log("!@--11");
                                            var valueSurchargeSur;// = document.getElementById("SValue Surcharge").value;
                                            var  valueSurchargeSurPercentage = valueSurchObj.surfacePercentage ;//document.getElementById(helper.getDocElementId(component,event,helper,"SValue Surcharge")+"%age").value;
                                            var  valueSurchargeSurMin = valueSurchObj.surfaceMin ;//document.getElementById(helper.getDocElementId(component,event,helper,"SValue Surcharge")+"Min.").value;
                                            var valueSurfaceInvoice = valueSurchObj.surfaceInvoice;
                                            //var percentageValOfGoodsSur = (valueSurchargeSurPercentage * valuegoodspkg )/100;                                
                                            if(valueSurfaceInvoice != null && valueSurfaceInvoice > 0){
                                                valueSurchargeSur = ( valuegoodspkg > valueSurfaceInvoice ? (Math.ceil(valuegoodspkg/valueSurfaceInvoice) * valueSurchargeSurMin) : valueSurchargeSurMin) ;
                                            }
                                            else if(valueSurchargeSurPercentage != null){
                                                valueSurchargeSur = (valueSurchargeSurPercentage * valuegoodspkg )/100;
                                            }
                                            
                                            
                                            //var ValueSurCalSur =  ((valuegoodspkg * surfaceavgwt) * valueSurchargeSur) / 100; //1.3
                                            specialdest[i].YieldSurface = (surfaceavgwt * specialdest[i].SurfacePrice) + waybillChargeSurface +podchargeSurface; //1.1 and 1.2
                                            specialdest[i].YieldSurface +=  valueSurchargeSur; //1.4                                                          
                                            console.log("!@--12");
                                            var fuelSurDrop = component.find("fuelsurDropdown").get("v.value");                                                         
                                            var FuelSurchargeSur = fuelSurchObj.SurfacePrice;//document.getElementById(helper.getDocElementId(component,event,helper,"SFuel Surcharge (%age)")).value;
                                            var fuelSurCalSur;
                                            if(fuelSurDrop == 'Total'){ //1.5
                                                fuelSurCalSur = (specialdest[i].YieldSurface * FuelSurchargeSur) / 100;                                    
                                            }
                                            else if(fuelSurDrop == 'Basic'){
                                                fuelSurCalSur = ((surfaceavgwt * specialdest[i].SurfacePrice) * FuelSurchargeSur) / 100;                                
                                            }
                                            console.log("!@--13");
                                            specialdest[i].YieldSurface += fuelSurCalSur; //1.6
                                            specialdest[i].YieldSurface = specialdest[i].YieldSurface / surfaceavgwt; //1.7
                                            
                                            //For AIR
                                            var valueSurchargeAir;// = document.getElementById("AValue Surcharge").value;
                                            var  valueSurchargeAirPercentage = valueSurchObj.airPercentage ;//document.getElementById(helper.getDocElementId(component,event,helper,"AValue Surcharge")+"%age").value;
                                            var  valueSurchargeAirMin = valueSurchObj.airMin ;//document.getElementById(helper.getDocElementId(component,event,helper,"AValue Surcharge")+"Min.").value;
                                            //var percentageValOfGoodsAir = (valueSurchargeAirPercentage * valuegoodspkg )/100;
                                            var valueairInvoice = valueSurchObj.airInvoice;                                
                                            //var percentageValOfGoodsAir = (valueSurchargeAirPercentage * valuegoodspkg )/100;
                                            if(valueairInvoice != null && valueairInvoice > 0){
                                                valueSurchargeAir = (valuegoodspkg > valueairInvoice ? (Math.ceil(valuegoodspkg/valueairInvoice )*valueSurchargeAirMin) : valueSurchargeAirMin) ;
                                            }else if(valueSurchargeAirPercentage != null){
                                                valueSurchargeAir = (valueSurchargeAirPercentage * valuegoodspkg )/100;
                                            }								
                                            //var ValueSurCalAir =  ((valuegoodspkg * airavgwt) * valueSurchargeAir) / 100;
                                            
                                            specialdest[i].YieldAir = (airavgwt * specialdest[i].AirPrice) + waybillChargeAir +podChargeAir;
                                            
                                            specialdest[i].YieldAir +=  valueSurchargeAir;
                                            
                                            var FuelSurchargeAir = fuelSurchObj.AirPrice ;//document.getElementById(helper.getDocElementId(component,event,helper,"AFuel Surcharge (%age)")).value;                                
                                            var fuelSurCalAir;
                                            if(fuelSurDrop == 'Total'){
                                                fuelSurCalAir = (specialdest[i].YieldAir * FuelSurchargeAir) / 100;                                    
                                            }
                                            else if(fuelSurDrop == 'Basic'){
                                                fuelSurCalAir = ((airavgwt * specialdest[i].AirPrice) * FuelSurchargeAir) / 100;                                
                                            }
                                            specialdest[i].YieldAir += fuelSurCalAir;
                                            specialdest[i].YieldAir = specialdest[i].YieldAir / airavgwt;
                                            
                                            console.log("!@--14"); 
                                        }
                                    }
                                    
                                    component.set("v.lstWrapper",zoneprices); 
                                    component.set("v.specialValues",specialdest);
                                }
                                else{
                                    alert('else');
                                }
                            });
                            $A.enqueueAction(action);
                            
                        }
})