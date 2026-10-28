({
    doinit : function(component, event, helper) {		
        var action = component.get("c.getDepartment");
        action.setCallback(this,function(res){
            var state = res.getState();
            if(state == 'SUCCESS'){
                component.set("v.lstDepartment",res.getReturnValue());
            }
        });
        $A.enqueueAction(action);
        component.set("v.totalRecords",0);
        component.set("v.totalRecords2",0);
        component.set("v.startPage",0);
        component.set("v.endPage",0);
        component.set("v.startPage2",0);
        component.set("v.endPage2",0);
    },
    keypressed : function(component, event, helper) {
        
        component.set("v.Spinner",true);
        //to check if it is existing or new customer.
        var table = component.find("search").get("v.value");
        //To get the input word entered for search.        
        var input = component.get("v.inputkeyword");
        //To get the user Id where accountteam exists.
        var user = component.find("username").get("v.value");
        
        //For existing customers table search results
        if(table == 'Existing Customers'){    	
            if(input.length > 3){
                var rec = [];
                var action = component.get("c.getAccountTeamSearch");
                action.setParams({
                    'key' : input,
                    'uname': user
                });
                action.setCallback(this, function(a){
                    if(a.getReturnValue() != null){
               			rec = a.getReturnValue();                        
                        if(rec.length > 0){
                    
                    component.set("v.lstAccounts",rec);
                    helper.FetchAccounts(component);
                    component.set("v.noResultExist",false);
                }
                else{
                    
                    component.set("v.PaginationListExis");
                    component.set("v.noResultExist",true);
                }
                    }
                    else{
                        component.set("v.PaginationListExis");
                    	component.set("v.noResultExist",true);
                    }
                });
                $A.enqueueAction(action);
                
                
                
            }
            if(input.length == 0){
                var acc = component.get("v.lstAccounts2");
                component.set("v.lstAccounts",acc);
                helper.FetchAccounts(component);
                component.set("v.noResultExist",false);
            }
            component.set("v.Spinner",false);
        }
        else if(table == 'New Customers'){    	
            if(input.length > 3){
                var action = component.get("c.getallsearch");
                action.setParams({
                    'key' : input,
                    'uname': user
                });
                action.setCallback(this, function(a){
                    if(a.getReturnValue() != null){
                        
                        component.set("v.lstAll",a.getReturnValue());
                        helper.FetchAccounts2(component);
                        component.set("v.noResultNew",false);
                    }
                    else{
                        component.set("v.PaginationList");
                    	component.set("v.noResultNew",true);
                    }
                });
                $A.enqueueAction(action);
            }
            if(input.length == 0){
                var acc = component.get("v.lstAll2");
                component.set("v.lstAll",acc);
                helper.FetchAccounts2(component);
                component.set("v.noResultNew",false);
            }
            component.set("v.Spinner",false);
        }
        
    },
    next: function (component, event, helper) {
        helper.next(component, event);
    },
    previous: function (component, event, helper) {
        helper.previous(component, event);
    },
    next2: function (component, event, helper) {
        helper.next2(component, event);
    },
    previous2: function (component, event, helper) {
        helper.previous2(component, event);
    },
    checknrel: function (component, event, helper) {
        var map = component.get("v.map");
        var relList = component.get("v.rellist");
        var value = event.getSource().get("v.value");
        var text = event.getSource().get("v.text");        
        if(value == true){            
            relList.push(text);
        }
        else{
            var index = relList.indexOf(text);            
            if(index > -1){
                relList.splice(index,1);
            }            
        }
        
        if(map == null){
            
            var map = {};
            map["rel"] = relList;
            
            component.set("v.map",map);
        }
        else{
            map["rel"] = relList;
            
            component.set("v.map",map);
        }        
    },
    checkncol: function (component, event, helper) {
        
        var map = component.get("v.map");
        var ncollist = component.get("v.newcollist");
        var value = event.getSource().get("v.value");
        var text = event.getSource().get("v.text");
        if(value == true){
            ncollist.push(text);
        }
        else{
            var index = ncollist.indexOf(text);
            if(index > -1){
                ncollist.splice(index,1);
            }
        }
        
        if(map == null){
            
            var map = {};
            map["col"] = ncollist;
            
            component.set("v.map",map);
        }
        else{
            map["col"] = ncollist;
            
            component.set("v.map",map);
            
        }
        
    },
    checknsub: function (component, event, helper) {
        
        var map = component.get("v.map");
        var nsublist = component.get("v.newsublist");
        var value = event.getSource().get("v.value");
        var text = event.getSource().get("v.text");
        if(value == true){
            nsublist.push(text);
        }
        else{
            var index = nsublist.indexOf(text);
            if(index > -1){
                nsublist.splice(index,1);
            }
        }
        
        if(map == null){
            
            var map = {};
            map["sub"] = nsublist;
            
            component.set("v.map",map);
        }
        else{
            map["sub"] = nsublist;
            
            component.set("v.map",map);
            
        }
        
    },
    
    checknn1: function (component, event, helper) {
        
        var map = component.get("v.map");
        var nn1list = component.get("v.newnational1");
        var value = event.getSource().get("v.value");
        var text = event.getSource().get("v.text");
        if(value == true){
            nn1list.push(text);
        }
        else{
            var index = nn1list.indexOf(text);
            if(index > -1){
                nn1list.splice(index,1);
            }
        }
        
        if(map == null){
            
            var map = {};
            map["n1"] = nn1list;
            
            component.set("v.map",map);
        }
        else{
            map["n1"] = nn1list;
            
            component.set("v.map",map);
            
        }
        
    },
    
    checknn2: function (component, event, helper) {
        
        var map = component.get("v.map");
        var nn2list = component.get("v.newnational2");
        var value = event.getSource().get("v.value");
        var text = event.getSource().get("v.text");
        if(value == true){
            nn2list.push(text);
        }
        else{
            var index = nn2list.indexOf(text);
            if(index > -1){
                nn2list.splice(index,1);
            }
        }
        
        if(map == null){
            
            var map = {};
            map["n2"] = nn2list;
            
            component.set("v.map",map);
        }
        else{
            map["n2"] = nn2list;
            
            component.set("v.map",map);
            
        }
        
    },
    
    checknn3: function (component, event, helper) {
        
        var map = component.get("v.map");
        var nn3list = component.get("v.newnational3");
        var value = event.getSource().get("v.value");
        var text = event.getSource().get("v.text");
        if(value == true){
            nn3list.push(text);
        }
        else{
            var index = nn3list.indexOf(text);
            if(index > -1){
                nn3list.splice(index,1);
            }
        }
        
        if(map == null){
            
            var map = {};
            map["n3"] = nn3list;
            
            component.set("v.map",map);
        }
        else{
            map["n3"] = nn3list;
            
            component.set("v.map",map);
            
        }
        
    },
    checknn4: function (component, event, helper) {
        
        var map = component.get("v.map");
        var nn4list = component.get("v.newnational4");
        var value = event.getSource().get("v.value");
        var text = event.getSource().get("v.text");
        if(value == true){
            nn4list.push(text);
        }
        else{
            var index = nn4list.indexOf(text);
            if(index > -1){
                nn4list.splice(index,1);
            }
        }
        
        if(map == null){
            
            var map = {};
            map["n4"] = nn4list;
            
            component.set("v.map",map);
        }
        else{
            map["n4"] = nn4list;
            
            component.set("v.map",map);
            
        }
        
    },
    checkncrs: function (component, event, helper) {

        var map = component.get("v.map");
        var crslist = component.get("v.newcrs");
        var value = event.getSource().get("v.value");
        var text = event.getSource().get("v.text");
        if(value == true){
            crslist.push(text);
        }
        else{
            var index = crslist.indexOf(text);
            if(index > -1){
                crslist.splice(index,1);
            }
        }
        
        if(map == null){
            
            var map = {};
            map["crs"] = crslist;
            
            component.set("v.map",map);
        }
        else{
            map["crs"] = crslist;
            
            component.set("v.map",map);
            
        }        
        
    },
    checkerel: function (component, event, helper) {
        var btn = event.getSource();
        btn.set("v.disabled",false);
        var cnt = 0;       
        var relexe = component.get("v.relexis");
        var text = event.getSource().get("v.text");
        
        var index = relexe.indexOf(text);
        if(index > -1){
            
        }
        else{
            relexe.push(text);            
        }
    },
    checkecol: function (component, event, helper) {
        
        var relexe = component.get("v.relexis");
        var text = event.getSource().get("v.text");
        var cnt = 0;
        var index = relexe.indexOf(text);
        if(index > -1 ){
            
        }
        else{
            relexe.push(text);
            
        }
        
    },
    checkesub: function (component, event, helper) {
        var relexe = component.get("v.relexis");
        var text = event.getSource().get("v.text");
        var cnt = 0;
        var index = relexe.indexOf(text);
        if(index > -1 ){
            
        }
        else{
            relexe.push(text);
            
        }
        
    },
    checken1: function (component, event, helper) {
        var relexe = component.get("v.relexis");
        var text = event.getSource().get("v.text");
        var cnt = 0;
        var index = relexe.indexOf(text);
        if(index > -1 ){
            
        }
        else{
            relexe.push(text);
            
        }
    },
    checken2: function (component, event, helper) {
        var relexe = component.get("v.relexis");
        var text = event.getSource().get("v.text");
        var cnt = 0;
        var index = relexe.indexOf(text);
        if(index > -1 ){
            
        }
        else{
            relexe.push(text);
            
        }

        
    },
    checken3: function (component, event, helper) {
        var relexe = component.get("v.relexis");
        var text = event.getSource().get("v.text");
        var cnt = 0;
        var index = relexe.indexOf(text);
        if(index > -1 ){
            
        }
        else{
            relexe.push(text);
            
        }        
        
    },
    checken4: function (component, event, helper) {
        var relexe = component.get("v.relexis");
        var text = event.getSource().get("v.text");
        var cnt = 0;
        var index = relexe.indexOf(text);
        if(index > -1 ){
            
        }
        else{
            relexe.push(text);
            
        }
        
    },
    checkecrs: function (component, event, helper) {
        var relexe = component.get("v.relexis");
        var text = event.getSource().get("v.text");
        var cnt = 0;
        var index = relexe.indexOf(text);
        if(index > -1 ){
            
        }
        else{
            relexe.push(text);
            
        }
        
    },
    
    assign: function (component, event, helper) {
        var relexe = component.get("v.relexis");
        var list = component.get("v.lstAccounts");
        var newlist = [];
        //Creating list for accountteams to be updated.
        if(relexe.length > 0){
        for(var i=0; i<list.length;i++){            
            for(var j=0; j<relexe.length;j++){
                if(list[i].Id == relexe[j]){
                    newlist.push(list[i]);
                }
            }
        }
        }
        // For removing existing customers
        var user = component.find("username").get("v.value");
        if(newlist.length > 0){			
            var action = component.get("c.removeATeam");
            action.setParams({
                'lstAT' : newlist,
                'uname': user
            });
            action.setCallback(this,function(a){
                var state = a.getState();
                if (state === "SUCCESS") {
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "type" : "Success",
                        "message": "Record Updated"
                    });
                    toastEvent.fire();
                    var emptylist2 = [];
                    component.set("v.relexis",emptylist2);
        			var list = component.get("v.lstAccounts");
                    //For refreshing the Data after Assignment
                    var user = component.find("username").get("v.value");
                    var action = component.get("c.getAccounts");
                    action.setParams({
                        "uname" : user
                    });
                    action.setCallback(this, function(a){
                        if(a.getReturnValue() != null){
                            component.set("v.lstAccounts",a.getReturnValue());
                            component.set("v.lstAccounts2",a.getReturnValue());
                            helper.FetchAccounts(component);
                        }
                        
                    });
                    $A.enqueueAction(action);
                    
                }
                else{
                    alert("error");
                }
            });
            $A.enqueueAction(action);
        }
        /*----removing ends------*/
        
        var list2 = component.get("v.rellist");
        var leng1 = component.get("v.map");
        var user = component.find("username").get("v.value");
        if(leng1 != null){
            var action2 = component.get("c.CreateATeam");
            action2.setParams({
                'lstId' : list2,
                'mp' : leng1,
                'uname' : user
            });
            action2.setCallback(this,function(a){
                var state = a.getState();
                if (state === "SUCCESS") {
                    
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "Success!",
                        "type" : "Success",
                        "message": "Record Updated"
                    });
                    toastEvent.fire();
                    var emptylist = [];                    
                    component.set("v.map",null);
        			component.set("v.rellist",emptylist);
                    component.set("v.newcollist",emptylist);
                    component.set("v.newsublist",emptylist);
                    component.set("v.newnational1",emptylist);
                    component.set("v.newnational2",emptylist);
                    component.set("v.newnational3",emptylist);
                    component.set("v.newnational4",emptylist);
                    component.set("v.newcrs",emptylist);
                    //For refreshing the Data after Assignment
                    var user = component.find("username").get("v.value");
                    var action = component.get("c.getAccounts");
                    action.setParams({
                        "uname" : user
                    });
                    action.setCallback(this, function(a){
                        if(a.getReturnValue() != null){
                            component.set("v.lstAccounts",a.getReturnValue());
                            component.set("v.lstAccounts2",a.getReturnValue());
                            helper.FetchAccounts(component);
                        }
                        
                    });
                    $A.enqueueAction(action);
                    component.find("user").set("v.value","");
                    component.set("v.PaginationList");
                }
                else{
                    alert("error");
                }
            });
            $A.enqueueAction(action2);
        }
        
    },
    department: function (component, event, helper) {
        
        component.set("v.PaginationList");
        component.set("v.PaginationListExis");
        var value = component.find("dept").get("v.value");
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
        
    },
    userselect: function (component, event, helper) {
        /*var adid;
        var users = component.get("v.lstusers");
        var uid = component.find("username").get("v.value");
        for(var i=0;i<users.length;i++){
            
            if(users[i].Id == uid){
                adid = users[i].AD_Id__c;
                break;
            }
            
        }
        component.set("v.ad",adid);*/
        component.set("v.PaginationList");
        component.set("v.PaginationListExis");
        component.set("v.spinner2",true);        
        var user = component.find("username").get("v.value");        
        var action = component.get("c.getAccounts");
        action.setParams({
            "uname" : user
        });
        action.setCallback(this, function(a){
            if(a.getReturnValue() != null){
                component.set("v.lstAccounts",a.getReturnValue());
                component.set("v.lstAccounts2",a.getReturnValue());
                helper.FetchAccounts(component);
            }
            else{
                component.set("v.PaginationListExis");
            }
        });
        $A.enqueueAction(action);
    },
    showSpinner: function(component, event, helper) {
        // make Spinner attribute true for display loading spinner 
        component.set("v.Spinner", true); 
    },
    
    // this function automatic call by aura:doneWaiting event 
    hideSpinner : function(component,event,helper){
        // make Spinner attribute to false for hide loading spinner    
        component.set("v.Spinner", false);
    },
})