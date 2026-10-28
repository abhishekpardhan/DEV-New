({
    departmentHelper : function(component){
        
    },
    FetchAccounts : function(component) {
        var pageSize = component.get("v.pageSize");
        component.set("v.totalRecords2", component.get("v.lstAccounts").length);
        component.set("v.startPage",0);            
            component.set("v.endPage",pageSize-1);
        var accountsExis = component.get("v.lstAccounts");
        	var PaginationListExis = [];
            for(var i=0; i< pageSize; i++){
                if(component.get("v.lstAccounts").length> i)
                    PaginationListExis.push(accountsExis[i]);    
            }
            component.set('v.PaginationListExis', PaginationListExis);
        
            component.set('v.PaginationListExis2', PaginationListExis);
        	component.set("v.spinner2",false);
    },
    FetchAccounts2 : function(component) {
            var pageSize = component.get("v.pageSize");
        
            // get size of all the records and then hold into an attribute "totalRecords"
            component.set("v.totalRecords", component.get("v.lstAll").length);
            
            // set start as 0
            component.set("v.startPage2",0);
            var accounts = component.get("v.lstAll");
            component.set("v.endPage2",pageSize-1);
            var PaginationList = [];
            for(var i=0; i< pageSize; i++){
                if(component.get("v.lstAll").length> i)
                    PaginationList.push(accounts[i]);    
            }
            component.set('v.PaginationList', PaginationList);
        
            component.set('v.PaginationList2', PaginationList);
        
        	
    },
    
    /*
     * Method will be called when use clicks on next button and performs the 
     * calculation to show the next set of records
     */
    next : function(component, event){
        var sObjectList = component.get("v.lstAll");
        var end = component.get("v.endPage2");
        var start = component.get("v.startPage2");
        var pageSize = component.get("v.pageSize");
        var Paginationlist = [];
        var counter = 0;
        for(var i=end+1; i<end+pageSize+1; i++){
            if(sObjectList.length > i){
                Paginationlist.push(sObjectList[i]);
            }
            counter ++ ;
        }
        start = start + counter;
        end = end + counter;
        component.set("v.startPage2",start);
        component.set("v.endPage2",end);
        component.set('v.PaginationList', Paginationlist);
    },
    next2 : function(component, event){
        var sObjectList = component.get("v.lstAccounts");
        var end = component.get("v.endPage");
        var start = component.get("v.startPage");
        var pageSize = component.get("v.pageSize");
        var Paginationlist = [];
        var counter = 0;
        for(var i=end+1; i<end+pageSize+1; i++){
            if(sObjectList.length > i){
                Paginationlist.push(sObjectList[i]);
            }
            counter ++ ;
        }
        start = start + counter;
        end = end + counter;
        component.set("v.startPage",start);
        component.set("v.endPage",end);
        component.set('v.PaginationListExis', Paginationlist);
    },
    /*
     * Method will be called when use clicks on previous button and performs the 
     * calculation to show the previous set of records
     */
    previous : function(component, event){
        var sObjectList = component.get("v.lstAll");
        var end = component.get("v.endPage2");
        var start = component.get("v.startPage2");
        var pageSize = component.get("v.pageSize");
        var Paginationlist = [];
        var counter = 0;
        for(var i= start-pageSize; i < start ; i++){
            if(i > -1){
                Paginationlist.push(sObjectList[i]);
                counter ++;
            }else{
                start++;
            }
        }
        start = start - counter;
        end = end - counter;
        component.set("v.startPage2",start);
        component.set("v.endPage2",end);
        component.set('v.PaginationList', Paginationlist);
    },
    previous2 : function(component, event){
        var sObjectList = component.get("v.lstAccounts");
        var end = component.get("v.endPage");
        var start = component.get("v.startPage");
        var pageSize = component.get("v.pageSize");
        var Paginationlist = [];
        var counter = 0;
        for(var i= start-pageSize; i < start ; i++){
            if(i > -1){
                Paginationlist.push(sObjectList[i]);
                counter ++;
            }else{
                start++;
            }
        }
        start = start - counter;
        end = end - counter;
        component.set("v.startPage",start);
        component.set("v.endPage",end);
        component.set('v.PaginationListExis', Paginationlist);
    },
})