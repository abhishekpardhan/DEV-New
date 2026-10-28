({
    //This doinit method is only in use to get the UI filter values.
    doinit : function(component, event, helper) {
        component.find("PortfolioType").set("v.value",'Relationship/ National');
        
        //Getting Department Picklist Values.
        helper.getDepartmentPicklist(component);
        //Getting values according to the Search By string.
        helper.getSearchByResult(component);
        //Getting Portfolio Picklist Values.
        helper.getPortfolioTypePicklist(component);
    },

    department: function (component, event, helper) {        
        component.set("v.PaginationList");
        component.set("v.PaginationListExis");
        var value = component.find("dept").get("v.value");
        // alert(value);
        var action = component.get("c.getUsers");
        action.setParams({
            "dept" : value
        });
        action.setCallback(this,function(a){                                
            component.set("v.lstusers",a.getReturnValue());
        });
        $A.enqueueAction(action);

        if(value == "Client Relation Support (CRS)"){
            component.set("v.department",true);            
        }
        else{
            component.set("v.department",false);
        }
        component.set("v.WrapperList", null);
        component.set("v.WrapperListExisting", null);
        component.set("v.SubWrapperList", null);
        component.set("v.SubWrapperListExisting", null);
    },

    //This method will work while a user got selected from the User picklist on UI.
    userselect : function (component, event, helper) {
        component.find("searchBy").set("v.value", 'None');
        component.set("v.SearchBtn", true);
        component.find("searcHere").set("v.value", "");
        
        helper.clearVariables(component, event);
        
        // fetch existing records for Relationship/National and Submission/Collection
        helper.addAssignedRecords(component, event);
    },
                
    SearchBy : function(component, event, helper){
        component.find("searcHere").set("v.value","");
    },

    SearchHere: function(component, event, helper){
        if(component.find("searcHere").get("v.value") == ''){
            component.set("v.SearchBtn", true);
        }else{
            component.set("v.SearchBtn", false);    
        }
    },
                        
    portfolioType: function(component, event, helper){
        var portfolioType = component.find("PortfolioType").get("v.value");
        
        helper.clearVariables(component, event);
        
        var User = component.find("username").get("v.value");
        
        if(portfolioType == 'Relationship/ National'){
            component.set("v.Relationship", true);
            component.set("v.Submission", false);
            helper.getAssignedUserPortfolios(component, User);
        }
        else if(portfolioType == 'Submission/ Collection'){
            component.set("v.Relationship", false);
            component.set("v.Submission", true); 
            helper.getAssignedPortFolio(component, User);
        }
    },

    Search: function(component, event, helper){
        component.set("v.mapCCD",{});
        component.set("v.mapNAM",{});
        component.set("v.mapQRM",{});
        component.set("v.mapRM",{});
        component.set("v.mapCRS",{});
        component.set("v.mapRelationship",{});
        component.set("v.mapSubmission",{});
        component.set("v.mapCollection",{});
        
        var searchBy = component.find("searchBy").get("v.value");
        var searcHere = component.find("searcHere").get("v.value");
        var PortfolioType = component.find("PortfolioType").get("v.value");
        var User = component.find("username").get("v.value");
        var searchHereSize = searcHere.split(",");
        
        if(searchHereSize.length > 10){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                type: 'error',
                    message: 'You cannot search more then 10 records at a time!',
                        duration: 1000
                            });
            toastEvent.fire();
        }else{
            console.log('---- 97 Propeli_Portfolio_ManagementController.js PortfolioType: ' + PortfolioType);
            if(PortfolioType == 'Relationship/ National' ){
                var action = component.get("c.getNewPortfolios");
                action.setParams({
                    "searchby" : searchBy,
                        "usrId" : User,
                            "searchStr" : searcHere,
                                "str_PortfolioType" : PortfolioType
                                    });
                action.setCallback(this,function(res){
                    var state = res.getState()
                        if(state == 'SUCCESS'){
                            if(res.getReturnValue() != null){
                                component.set("v.WrapperList",res.getReturnValue());
                                console.log(res.getReturnValue());
                            }
                        }
                });
                $A.enqueueAction(action);
                helper.getAssignedUserPortfolios(component, User);
                
                /*var action1 = component.get("c.getAssignedUsrPorfolios");
                action1.setParams({
                    "searchby" : searchBy,
                        "usrId" : User,
                            "searchStr" : searcHere,
                                "str_PortfolioType" : PortfolioType
                                    });
                action1.setCallback(this,function(res){
                    var state = res.getState()
                        if(state == 'SUCCESS'){
                            component.set("v.WrapperListExisting",res.getReturnValue());
                            console.log(res.getReturnValue());
                        }
                });
                $A.enqueueAction(action1);*/
            }
            else if(PortfolioType == 'Submission/ Collection'){
                console.log("test Submission Collection");
                var action = component.get("c.getExSubmissionCollectionMapping");
                action.setParams({
                    "searchby" : searchBy,
                        "usrId" : User,
                            "searchStr" : searcHere,
                                "str_PortfolioType" : PortfolioType
                                    });
                action.setCallback(this,function(res){
                    var state = res.getState()
                        if(state == 'SUCCESS'){
                            if(res.getReturnValue() != null){
                                component.set("v.SubWrapperList",res.getReturnValue()); //It will work to show the new customers MSA, SFX, RateCard etc..
                                console.log(res.getReturnValue());
                            }
                        }
                });
                $A.enqueueAction(action);
                helper.getAssignedPortFolio(component, User);
                
                /*var action1 = component.get("c.getAssignedSCPortfolios");
                action1.setParams({
                    "searchby" : searchBy,
                        "usrId" : User,
                            "searchStr" : searcHere,
                                "str_PortfolioType" : PortfolioType
                                    });
                action1.setCallback(this,function(res){
                    var state = res.getState();
                    if(state == 'SUCCESS'){
                        component.set("v.SubWrapperListExisting",res.getReturnValue());
                        console.log(res.getReturnValue());
                    }
                });
                $A.enqueueAction(action1);*/
            }
        }
    },

    checkCode : function(component, event){
        var btn = event.getSource();
        var Ident = event.getSource().get("v.name"); 
        var labelClass = event.getSource().get("v.labelClass");
        
        var event = event.getSource().getLocalId();
        console.log(component.get("v.mapCCD"));
        
        if(event == 'CCD'){
            var CCDmap = component.get("v.mapCCD");
            CCDmap[Ident] = btn.get("v.value");
            component.set("v.mapCCD",CCDmap);
        }else if(event == 'NAM'){
            var NAMmap = component.get("v.mapNAM");
            NAMmap[Ident] = btn.get("v.value");
            component.set("v.mapNAM",NAMmap);
        }
        else if(event == 'QRM'){
            var QRMmap = component.get("v.mapQRM");
            QRMmap[Ident] = btn.get("v.value");
            component.set("v.mapQRM",QRMmap);
        }else if(event == 'RM'){
            var RMmap = component.get("v.mapRM");
            RMmap[Ident] = btn.get("v.value");
            component.set("v.mapRM",RMmap);
        }else if(event == 'CRS'){
            var CRSmap = component.get("v.mapCRS");
            CRSmap[Ident] = btn.get("v.value");
            component.set("v.mapCRS",CRSmap);
        }else if(event == 'Relationship'){
            var Relationshipmap = component.get("v.mapRelationship");
            Relationshipmap[Ident] = btn.get("v.value");
            component.set("v.mapRelationship",Relationshipmap);
        }else if(event == 'Submission'){
            var Submissionmap = component.get("v.mapSubmission");
            console.log('Submissionmap',Submissionmap);
            Submissionmap[Ident] = btn.get("v.value");
            component.set("v.mapSubmission",Submissionmap);
            let currentValue = btn.get("v.value");
             console.log('currentValue',currentValue);
        	
            const labelClassArray = labelClass.split("::");
 
            let SubmissionBranchOld = labelClassArray[0];
            let sfxOld = labelClassArray[1];
            let msaOld = labelClassArray[2];
             
            
            let SubWrapperList = component.get("v.SubWrapperList");
            console.log(JSON.stringify(SubWrapperList));
            SubWrapperList.forEach((value, key)=>{                 
                value.lstwrap_SCSFX.forEach((value1, key1)=>{
                	let msa =  value1.MSA;
                	let sfx =  value1.SFX;
                	 
                    
                    if(value1.Billing_level ==="SFX"){                
                        value1.lstwrap_SCMapping.forEach((value2, key2)=>{
                			 console.log('value2.isSubSelfAssigned',value2.isSubSelfAssigned);
                            let SubmissionBranch = value2.SubmissionBranch; 
                			 
                			if(SubmissionBranch === SubmissionBranchOld && msa === msaOld && sfx === sfxOld ){                				 
                				let submitKey = value2.BillingById+":"+sfx+":"+msa;
                				Submissionmap[submitKey] = currentValue;
                				value2.isSubSelfAssigned = currentValue;
                				console.log('value2.isSubSelfAssigned',value2.isSubSelfAssigned);
            				}
                                            			
                        })
                    }
                	
            	})
                
            })
                           
            component.set("v.SubWrapperList", SubWrapperList);           
            
        }
                
        else if(event == 'Collection'){
            var Collectionmap = component.get("v.mapCollection");
                console.log('Collectionmap',Collectionmap);
            Collectionmap[Ident] = btn.get("v.value");
             
            component.set("v.mapCollection",Collectionmap);
            let currentValue = btn.get("v.value");             
        	console.log('currentValue',currentValue);
            const labelClassArray = labelClass.split("::");
 
            let CollectionBranchOld = labelClassArray[0];
            let sfxOld = labelClassArray[1];
            let msaOld = labelClassArray[2];
            console.log('CollectionBranchOld',CollectionBranchOld);
            console.log('sfxOld',sfxOld);
            console.log('msaOld',msaOld);
            let ColWrapperList = component.get("v.SubWrapperList");
            console.log(JSON.stringify(ColWrapperList));
            ColWrapperList.forEach((value, key)=>{                 
                value.lstwrap_SCSFX.forEach((value1, key1)=>{
                	let msa =  value1.MSA;
                	let sfx =  value1.SFX;
                	 
                    console.log('msa',msa);
                    if(value1.Billing_level ==="SFX"){                
                        value1.lstwrap_SCMapping.forEach((value2, key2)=>{
                			 console.log('value2.isCollSelfAssigned',key2);
                            let CollectionBranch = value2.CollectionBranch; 
                			 
                			if(CollectionBranch ===CollectionBranchOld && msa===msaOld && sfx === sfxOld){                				 
                				let submitKey = value2.BillingById+":"+sfx+":"+msa;
                				Collectionmap[submitKey] = currentValue;
                				value2.isCollSelfAssigned = currentValue;
                console.log('value2.isCollSelfAssigned',value2.isCollSelfAssigned);
            				}
                                            			
                        })
                    }
                	
            	})
                
            })
             
            component.set("v.SubWrapperList", ColWrapperList);
        }
    },

    handleAssign : function(component, event, helper){
        var searchBy = component.find("searchBy").get("v.value");
        var searcHere = component.find("searcHere").get("v.value");
        var PortfolioType = component.find("PortfolioType").get("v.value");
        var User = component.find("username").get("v.value");
        
        console.log(component.get("v.mapCollection"));
        console.log(component.get("v.mapSubmission"));
        
        if(PortfolioType == 'Submission/ Collection'){
            var action1 = component.get("c.upsertSCAccountBDM");
            action1.setParams({
                "usrId" : component.find("username").get("v.value"),
                    "mapCollection" : component.get("v.mapCollection"),
                        "mapSubmission" : component.get("v.mapSubmission")           
                            });
            action1.setCallback(this,function(res){
                var state = res.getState()
                    if(state == 'SUCCESS'){
                        if(res.getReturnValue()  ==  "Success"){
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                type: 'Success',
                                    message: 'Success! record are updated successfully.',
                                        duration: 1000
                                            });
                            toastEvent.fire();
                        }
                    }
            });
            $A.enqueueAction(action1);
            //**************************************************************
            /*var action20 = component.get("c.getAssignedSCPortfolios");
            action20.setParams({
                "searchby" : searchBy,
                    "usrId" : User,
                        "searchStr" : searcHere,
                            "str_PortfolioType" : PortfolioType
                                });
            action20.setCallback(this,function(res){
                var state = res.getState();
                if(state == 'SUCCESS'){
                    component.set("v.SubWrapperListExisting",res.getReturnValue());
                    console.log(res.getReturnValue());
                }
            });
            $A.enqueueAction(action20);*/
            component.set("v.mapSubmission",{});
            component.set("v.mapCollection",{});
            
            helper.getAssignedPortFolio(component, User);
            
            var action21 = component.get("c.getExSubmissionCollectionMapping");
            action21.setParams({
                "searchby" : searchBy,
                    "usrId" : User,
                        "searchStr" : searcHere,
                            "str_PortfolioType" : PortfolioType
                                });
            action21.setCallback(this,function(res){
                var state = res.getState();
                if(state == 'SUCCESS'){
                    component.set("v.SubWrapperList",res.getReturnValue());
                    console.log(res.getReturnValue());
                }
            });
            $A.enqueueAction(action21); 
        }else{
            var action = component.get("c.upsertRNAccountBDM");
            console.log('relation'+JSON.stringify(component.get("v.mapRelationship")));
            action.setParams({
                "usrId" : component.find("username").get("v.value"),
                    "mapRelationship" : component.get("v.mapRelationship"),
                        "mapCCD" : component.get("v.mapCCD"),
                            "mapNAM" : component.get("v.mapNAM"),
                                "mapQRM" : component.get("v.mapQRM"),
                                    "mapRM" : component.get("v.mapRM"),
                                        "mapCRS" : component.get("v.mapCRS")
                                            });
            action.setCallback(this,function(res){
                var state = res.getState()
                    //    alert(state);
                    if(state == 'SUCCESS'){
                        //     alert(res.getReturnValue());
                        if(res.getReturnValue()  ==  "Success"){
                            //        alert ('in the loop');
                            var toastEvent = $A.get("e.force:showToast");
                            toastEvent.setParams({
                                // mode: 'sticky',
                                type: 'Success',
                                    message: 'Success! record are updated successfully.', 
                                        duration: 1000
                                            });
                            toastEvent.fire();
                        }
                        console.log(res.getReturnValue());
                    }
            });
            $A.enqueueAction(action);
            var action3 = component.get("c.getNewPortfolios");
            action3.setParams({
                "searchby" : searchBy,
                    "usrId" : User,
                        "searchStr" : searcHere,
                            "str_PortfolioType" : PortfolioType
                                });
            action3.setCallback(this,function(res){
                var state = res.getState();
                if(state == 'SUCCESS'){
                    component.set("v.WrapperList",res.getReturnValue());
                    console.log(res.getReturnValue());
                }
            });
            $A.enqueueAction(action3);
            
            component.set("v.mapCCD",{});
            component.set("v.mapNAM",{});
            component.set("v.mapQRM",{});
            component.set("v.mapRM",{});
            component.set("v.mapCRS",{});
            component.set("v.mapRelationship",{});
            
            helper.getAssignedUserPortfolios(component, User);
            // console.log('in the code');
            /*var action1 = component.get("c.getAssignedUsrPorfolios");
            //      console.log(action1);
            action1.setParams({
                "searchby" : searchBy,
                    "usrId" : User,
                        "searchStr" : searcHere,
                            "str_PortfolioType" : PortfolioType
                                });
            action1.setCallback(this,function(res){
                var state = res.getState()
                    if(state == 'SUCCESS'){
                        component.set("v.WrapperListExisting",res.getReturnValue());
                        console.log(res.getReturnValue());
                    }
            });
            $A.enqueueAction(action1);*/
        }
    },

        // function automatic called by aura:waiting event  
        showSpinner: function(component, event, helper) {
            // make Spinner attribute true for displaying loading spinner 
            component.set("v.spinner", true); 
        },
                                            
    // function automatic called by aura:doneWaiting event 
    hideSpinner : function(component,event,helper){
        // make Spinner attribute to false for hiding loading spinner    
        component.set("v.spinner", false);
    },
    
    prevClick : function(component,event,helper){
       	var searchBy = component.find("searchBy").get("v.value");
        var User = component.find("username").get("v.value");
        
        var PortfolioType = component.find("PortfolioType").get("v.value");
        if(PortfolioType == 'Submission/ Collection'){
            var page = component.get("v.pageSubCol");
            if(page > 1){
                component.set("v.pageSubCol", (page-1));
                helper.getAssignedPortFolio(component, User);
            }
            //helper.getAssignedPortFolio(component, User, false, true, offset);
        	
        }else{
            var page = component.get("v.page");
            if(page > 1){
                component.set("v.page", (page-1));
                helper.getAssignedUserPortfolios(component, User);
            }
        }
        
    },
    
    nextClick : function(component,event,helper){
        var searchBy = component.find("searchBy").get("v.value");
        var User = component.find("username").get("v.value");
        
        var PortfolioType = component.find("PortfolioType").get("v.value");
        
        if(PortfolioType == 'Submission/ Collection'){
            var page = component.get("v.pageSubCol");
            var totalPages = component.get("v.totalPagesSubCol");
            if(page < totalPages){
                component.set("v.pageSubCol", (page+1));
                helper.getAssignedPortFolio(component, User);
            }
            //helper.getAssignedPortFolio(component, User);
        }else{
            
            var page = component.get("v.page");
            var totalPages = component.get("v.totalPages");
            if(page < totalPages){
                component.set("v.page", (page+1));
                helper.getAssignedUserPortfolios(component, User);
            }
        }
    },
    
    moveFirst : function(component,event,helper){
        var searchBy = component.find("searchBy").get("v.value");
        var User = component.find("username").get("v.value");
        
        var PortfolioType = component.find("PortfolioType").get("v.value");
        if(PortfolioType == 'Submission/ Collection'){
            //component.set("v.offsetSub", 10);
            //component.set("v.pageNumSub", 1);
            component.set("v.pageSubCol", 1);
            helper.getAssignedPortFolio(component, User);
        	
        }else{
            component.set("v.page", 1);
            helper.getAssignedUserPortfolios(component, User);
        }
    },
    
    moveLast : function(component,event,helper){
        var searchBy = component.find("searchBy").get("v.value");
        var User = component.find("username").get("v.value");
        
        var PortfolioType = component.find("PortfolioType").get("v.value");
        
        if(PortfolioType == 'Submission/ Collection'){
            
            var totalPages = component.get("v.totalPagesSubCol");
            
            component.set("v.pageSubCol", totalPages);
            
            helper.getAssignedPortFolio(component, User);
        }else{
            
            var totalPages = component.get("v.totalPages");
            
            component.set("v.page", totalPages);
            
            helper.getAssignedUserPortfolios(component, User);
        }
    }
})