({
    refreshList : function(component, event) {
        var searchBy = component.find("searchBy").get("v.value");
        var searcHere = component.find("searcHere").get("v.value");
        var PortfolioType = component.find("PortfolioType").get("v.value");
        var User = component.find("username").get("v.value");
        
        if(PortfolioType == 'Relationship/ National' )
        {
            var action = component.get("c.getNewPortfolios");
            action.setParams({
                "searchby" : searchBy,
                    "usrId" : User,
                        "searchStr" : searcHere,
                            "str_PortfolioType" : PortfolioType
                                });
            action.setCallback(this,function(res){
                var state = res.getState();
                if(state == 'SUCCESS'){
                    component.set("v.WrapperList",res.getReturnValue());
                    console.log(res.getReturnValue());
                }
            });
            $A.enqueueAction(action);
            var action1 = component.get("c.getAssignedUsrPorfolios");
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
            $A.enqueueAction(action1);
        }
        else if(PortfolioType == 'Submission/ Collection')
        {
            var action = component.get("c.getExSubmissionCollectionMapping");
            action.setParams({
                "searchby" : searchBy,
                    "usrId" : User,
                        "searchStr" : searcHere,
                            "str_PortfolioType" : PortfolioType
                                });
            action.setCallback(this,function(res){
                var state = res.getState();
                if(state == 'SUCCESS'){
                    component.set("v.SubWrapperList",res.getReturnValue());
                    console.log(res.getReturnValue());
                }
            });
            $A.enqueueAction(action); 
            
            var action1 = component.get("c.getAssignedSCPortfolios");
            action1.setParams({
                "searchby" : searchBy,
                "usrId" : User,
                "searchStr" : searcHere,
                "str_PortfolioType" : PortfolioType
            });
            action1.setCallback(this,function(res)
            {
                var state = res.getState()
                    if(state == 'SUCCESS'){
                        component.set("v.SubWrapperListExisting",res.getReturnValue());
                        console.log(res.getReturnValue());
                    }
            });
            $A.enqueueAction(action1);
        }
    },

    addAssignedRecords : function(component, event) {
        var selectedUserId = component.find("username").get("v.value");
        this.selectedUserAssignment(component, selectedUserId);
        this.getAssignedPortFolio(component, selectedUserId);
        this.getAssignedUserPortfolios(component, selectedUserId);
    },

    selectedUserAssignment : function(component, selectedUserId) {
        let listOfUsers = component.get("v.lstusers");

        listOfUsers.forEach(eachUser => {
            if(eachUser.Id === selectedUserId) {
                component.set("v.Userdetail", eachUser);
            }
        });
    },

    getAssignedPortFolio : function(component, selectedUserId) {
        
        var page = component.get("v.pageSubCol");
        var pageSize = component.get("v.pageSizeSubCol");
        
        component.set("v.startIdxSubCol", (page-1)*pageSize);
		component.set("v.endIdxSubCol", page*pageSize);
        
        var mapSubmission = component.get("v.mapSubmission");
        var mapCollection = component.get("v.mapCollection");
        
        console.log(mapSubmission);
        console.log(mapCollection);
        
        var action = component.get("c.getAssignedSCPortfolios");
        action.setParams({
            "usrId" : selectedUserId,
            "pageSize" : component.get("v.pageSizeSubCol"),
            "startIdx" : component.get("v.startIdxSubCol"), 
            "endIdx" : component.get("v.endIdxSubCol")
        });
        component.set("v.noResultExistRelExi",false);
        action.setCallback(this,function(res){
            var state = res.getState()
                if(state == 'SUCCESS'){
                    //console.log(res.getReturnValue());
                    if(res.getReturnValue() != null){
                        console.log(res.getReturnValue());
                    	var result = res.getReturnValue();
                 		console.log(result.data);
                    
                    	result.data.forEach((rec) => {
                            if(rec.lstwrap_SCSFX != null){
                            	rec.lstwrap_SCSFX.forEach(rec1 =>{
                            		if(rec1.Billing_level == 'SFX' && rec1.lstwrap_SCMapping != null){
                            			rec1.lstwrap_SCMapping.forEach(rec2 =>{
                            				if(mapSubmission[rec2.BillingById+":"+rec1.SFX +":"+rec.MSA] != null){
                            					rec2.isSubSelfAssigned = mapSubmission[rec2.BillingById+":"+rec1.SFX +":"+rec.MSA];
                        					}
                                            if(mapCollection[rec2.BillingById+":"+rec1.SFX +":"+rec.MSA] != null){
												rec2.isCollSelfAssigned = mapCollection[rec2.BillingById+":"+rec1.SFX +":"+rec.MSA];                            					
                        					}
                        				})
                        			}else if(rec1.Billing_level == 'Rate Card' && rec1.lstwrap_SCBranches != null){
                                        rec1.lstwrap_SCBranches.forEach(rec2 =>{
                                            if(rec2.lstWrapSCMapping != null){
                                            	rec2.lstWrapSCMapping.forEach(rec3 =>{
                                                    if(mapSubmission[rec3.BillingById+":"+rec2.RateCard+':'+rec1.SFX +":"+rec.MSA] != null){
                                                        rec3.isSubSelfAssigned = mapSubmission[rec3.BillingById+":"+rec2.RateCard+':'+rec1.SFX +":"+rec.MSA];
                                                    }
                                                    if(mapCollection[rec3.BillingById+":"+rec2.RateCard+':'+rec1.SFX +":"+rec.MSA] != null){
                                                        rec3.isCollSelfAssigned = mapCollection[rec3.BillingById+":"+rec2.RateCard+':'+rec1.SFX +":"+rec.MSA];                            					
                                                    }
                                        		})
                                        	}
                                        })
                        			}
                        		})
                        	}
                    	});
						component.set("v.SubWrapperListExisting", result.data);
                        component.set("v.totalRecordsSubCol", result.totalRecords);
                        component.set("v.totalPagesSubCol", result.totalPages);
        				component.set("v.startIdxSubCol", result.startIdx);
        				component.set("v.endIdxSubCol", result.endIdx);
						
						if(page <= 1){
            				component.set("v.isPrevSubCol", true);
                        }else{
                            component.set("v.isPrevSubCol", false);
                        }
        
        				if(page < result.totalPages){
            				component.set("v.isNextSubCol", false);
                        }else{
                            component.set("v.isNextSubCol", true);
                        }
                    }else{
                        component.set("v.SubWrapperListExisting",res.getReturnValue()); //No need to show if there is no allocation for this user for existing customer.
                        component.set("v.noResultExistRelExi",false);
                    }
                }
        });
        $A.enqueueAction(action);
    },

    getAssignedUserPortfolios : function(component, selectedUserId) {
        console.log('Enterrr');
        
        var page = component.get("v.page");
        var pageSize = component.get("v.pageSize");
        
        component.set("v.startIdx", (page-1)*pageSize);
		component.set("v.endIdx", page*pageSize);
        
        var CCDmap = component.get("v.mapCCD");
        var NAMmap = component.get("v.mapNAM");
        var QRMmap = component.get("v.mapQRM");
        var RMmap = component.get("v.mapRM");
        var CRSmap = component.get("v.mapCRS");
        var Relationshipmap = component.get("v.mapRelationship");
        
        //console.log(CCDmap);
        //console.log(NAMmap);
        //console.log(QRMmap);
        //console.log(RMmap);
        //console.log(CRSmap);
        //console.log(Relationshipmap);
        
        var action = component.get("c.getAssignedUsrPorfolios");
        action.setParams({
            "usrId" : selectedUserId,
            "pageSize" : component.get("v.pageSize"),
            "startIdx" : component.get("v.startIdx"), 
            "endIdx" : component.get("v.endIdx")
        });
        component.set("v.noResultExistSubExi",false);
        action.setCallback(this,function(res){
            var state = res.getState()
            	if(state == 'SUCCESS'){
                    console.log(res.getReturnValue());
                    if(res.getReturnValue() != null){
                        var result = res.getReturnValue();
                        console.log(result);
                        
                        result.data.forEach((rec) => {
                            if(CCDmap[rec.MSA+':'+rec.MSA] != null){
                            	rec.CCD = CCDmap[rec.MSA+':'+rec.MSA];
                        	}
                         	if(NAMmap[rec.MSA] != null){
                            	rec.NAM = NAMmap[rec.MSA];
                        	}
                        	if(QRMmap[rec.MSA] != null){
                            	rec.QRM = QRMmap[rec.MSA];
                        	}
                        	if(RMmap[rec.MSA] != null){
                            	rec.RM = RMmap[rec.MSA];
                        	}
                        	if(CRSmap[rec.MSA] != null){
                            	rec.CRS = CRSmap[rec.MSA];
                        	}
                        	if(rec.lstSFXRCBranches != null){
                                rec.lstSFXRCBranches.forEach(rec1 =>{
                                    if(rec1.lstRT_BranchesPortfolios != null){
                                        rec1.lstRT_BranchesPortfolios.forEach(rec2 => {
                                            if(Relationshipmap[rec2.RTBranchesCode+':@'+ rec2.assignedBranchId + ':' + rec1.SFX+':'+rec.MSA] != null){
                                                rec2.Relationship = Relationshipmap[rec2.RTBranchesCode+':@'+ rec2.assignedBranchId + ':' + rec1.SFX+':'+rec.MSA];
                                            }
                                        })
                            		}
                                })
                       		}
                        })
                        
                        component.set("v.WrapperListExisting", result.data);
                        component.set("v.totalRecords", result.totalRecords);
                        component.set("v.totalPages", result.totalPages);
        				component.set("v.startIdx", result.startIdx);
        				component.set("v.endIdx", result.endIdx);
        
        				if(page <= 1){
            				component.set("v.isPrev", true);
                        }else{
                            component.set("v.isPrev", false);
                        }
        
        				if(page < result.totalPages){
            				component.set("v.isNext", false);
                        }else{
                            component.set("v.isNext", true);
                        }
        
                    }else{
                        component.set("v.noResultExistSubExi",true);
                    }
                }
        });
        $A.enqueueAction(action);
    },

    getDepartmentPicklist : function(component) {
        var action = component.get("c.getDepartment");
        action.setCallback(this,function(res){
            var state = res.getState();
            if(state == 'SUCCESS'){
                console.log(res.getReturnValue());
                component.set("v.lstDepartment",res.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },

    getSearchByResult : function(component) {
        var action = component.get("c.getSearchBy");
        action.setCallback(this,function(res) {
            var state = res.getState();
            if(state == 'SUCCESS') {
                component.set("v.SearchBy",res.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },

    getPortfolioTypePicklist : function(component) {
        var action = component.get("c.getPortfolioType");
        action.setCallback(this,function(res){
            var state = res.getState();
            if(state == 'SUCCESS'){
                component.set("v.PortfolioType",res.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },
        
	clearVariables : function(component, event){
    	// set data to null
        component.set("v.WrapperList", null);
        component.set("v.WrapperListExisting", null);
        component.set("v.SubWrapperList", null);
        component.set("v.SubWrapperListExisting", null);
        
        // make empty all maps
        component.set("v.mapCCD",{});
        component.set("v.mapNAM",{});
        component.set("v.mapQRM",{});
        component.set("v.mapRM",{});
        component.set("v.mapCRS",{});
        component.set("v.mapRelationship",{});
        component.set("v.mapSubmission",{});
        component.set("v.mapCollection",{});
        
        component.set("v.pageSize", 10);
        component.set("v.page", 1);
        component.set("v.totalPages", 0);
        component.set("v.startIdx", 0);
        component.set("v.endIdx", 0);
        component.set("v.totalRecords", 0);
        component.set("v.pageSizeSubCol", 10);
        component.set("v.pageSubCol", 1);
        component.set("v.totalPagesSubCol", 0);
        component.set("v.startIdxSubCol", 0);
        component.set("v.endIdxSubCol", 0);
        component.set("v.totalRecordsSubCol", 0);
	}
})