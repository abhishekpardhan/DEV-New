/**
 * Description		:		journey view component controller
 * Created By       :       Shubham Girdhar
 * Created Date     :       10th jan, 2020
 * Release          :       25th jan, 2020
 * Last Modified on :
 * Jira Ticket      :       https://safexpress.atlassian.net/browse/SD-403
 **/
({
   // Method to load month journey view at the time of loading 
    doInit : function(component, event, helper) {  
            var result = new Date();
            var Max = new Date();
            var MDay = new Date();
            result.setMonth(result.getMonth() - 2);
            Max.setMonth(Max.getMonth() + 3);
            var todayDate = $A.localizationService.formatDate(result, "YYYY-MM");
            var today = $A.localizationService.formatDate(Max, "YYYY-MM");
            var CurrentMonth = $A.localizationService.formatDate(MDay, "YYYY-MM");
            component.set("v.Month", CurrentMonth);
            component.set("v.MaxDate", today);
            component.set("v.MinDate", todayDate);
            var userId = $A.get("$SObjectType.CurrentUser.Id");
    component.set("v.Id", userId);
    helper.LoadTableMonth1(component,event,helper);
    var action = component.get('c.GetExpeseType');
    action.setParams({

    });
    action.setCallback(this, function(respo){
        var respo = respo.getReturnValue();
        component.set('v.ExpenseType', respo);
    });
    $A.enqueueAction(action, false);

   var action5 = component.get('c.getusersNumber'); 
    action5.setParams({
        UserId :$A.get("$SObjectType.CurrentUser.Id") ,
    });
    action5.setCallback(this, function(response){
        var state = response.getState();
      //  alert('State'+ state);
        var respo = response.getReturnValue();
      //  alert(respo);
        if(respo > 0){
            var hideButton = component.find("TeamJourney");  
            $A.util.removeClass(hideButton,"slds-hide"); 
            $A.util.addClass(hideButton, "slds-show"); 
        }
        component.set('v.number', respo);
        console.log(component.get("v.number"));
    });
     //   alert(component.get('v.Users'));
    $A.enqueueAction(action5, false);

    
       
},
    // Method to get list of journeys 
    LoadTable : function(component, event, helper){
      //  var StDate = component.get('v.StartDate');
      //  var EnDate = component.get('v.EndDate');
                var action = component.get('c.GetJourneyList');
                        action.setParams({
                            StartDate : component.get('v.StartDate'),
                            EndDate : component.get('v.EndDate'),
                            CurrentUserId : $A.get("$SObjectType.CurrentUser.Id")
                        });
                        action.setCallback(this, function(response){
                            var responseValue = response.getReturnValue();
                         // console.log('responsevalue', responseValue);
                            component.set('v.JourneyList', responseValue);
                        });
                        $A.enqueueAction(action, false);
                    },
                    // calling helper Method
       LoadTableMonth : function(component, event, helper){
helper.LoadTableMonth1(component,event,helper);
        /* component.set("v.OpenIf", true);             
        var StDate = component.get('v.Month');
        // alert(StDate);
        var array = StDate.split('-');
        // alert (array[0]);
        // alert (array[1]);
        var Yeara = array[0];
        var Montha = array[1];
        // alert (typeof "Yeara1");
        // alert(Montha);
        
                 var action = component.get('c.GetJourneyListMonth');
                        action.setParams({
                            Year : Yeara,
                            Month : Montha,
                            CurrentUserId : $A.get("$SObjectType.CurrentUser.Id")
                        });
                        action.setCallback(this, function(response){
                            var responseValue = response.getReturnValue();
                         // console.log('responsevalue', responseValue);
                            component.set('v.JourneyList', responseValue);
                        });
                        $A.enqueueAction(action, false);
                     
                        var act = component.get('c.GetJourneyCount');
                        // alert('2nd method');
                        act.setParams({
                            Year : Yeara,
                            Month : Montha,
                            CurrentUserId : $A.get("$SObjectType.CurrentUser.Id")
                        });
                        act.setCallback(this, function(response){
                            var responseValue = response.getReturnValue();
                         // console.log('responsevalue', responseValue);
                            component.set('v.TotalJourney', responseValue);
                        });
                        $A.enqueueAction(act, false);

                        
                        var act1 = component.get('c.GetJourneyTotalAmount');
                        // alert('2nd method');
                        act1.setParams({
                            Year : Yeara,
                            Month : Montha,
                            CurrentUserId : $A.get("$SObjectType.CurrentUser.Id")
                        });
                        act1.setCallback(this, function(response){
                            var responseValue = response.getReturnValue();
                         // console.log('responsevalue', responseValue);
                            component.set('v.TotalAmount', responseValue);
                        });
                        $A.enqueueAction(act1, false);

                        var act2 = component.get('c.GetJourneyTotalEvent');
                        // alert('2nd method');
                        act2.setParams({
                            Year : Yeara,
                            Month : Montha,
                            CurrentUserId : $A.get("$SObjectType.CurrentUser.Id")
                        });
                        act2.setCallback(this, function(response){
                            var responseValue = response.getReturnValue();
                         // console.log('responsevalue', responseValue);
                            component.set('v.TotalEvent', responseValue);
                        });
                        $A.enqueueAction(act2, false);
                    
                    var act3 = component.get('c.GetJourneyTotalDistance');
                        // alert('2nd method');
                        act3.setParams({
                            Year : Yeara,
                            Month : Montha,
                            CurrentUserId : $A.get("$SObjectType.CurrentUser.Id")
                        });
                        act3.setCallback(this, function(response){
                            var responseValue = response.getReturnValue();
                         // console.log('responsevalue', responseValue);
                            component.set('v.TotalDistance', responseValue);
                        });
                        $A.enqueueAction(act3, false); */
                    },
       /*  handleSectionToggle: function (component, event, helper) {
            var openSections = event.getParam('openSections');
          //   alert(Id);
            var actiona = component.get('c.GetEventList');
            actiona.setParams({            
                JourneyId : openSections 
            });
            actiona.setCallback(this, function(response){
                var responseValuea = response.getReturnValue();
               console.log('responsevalue', responseValuea);
                component.set('v.EventList', responseValuea);
            });
            $A.enqueueAction(actiona);
        } 
        
        { */
            // Method to toggle vindow on click of a row
        handleSectionToggle: function (component, event) {
            var openSections = event.getParam('openSections');
            var id = JSON.stringify(openSections);
            // alert (id);
            component.set('v.JorId', id);
            // alert(component.get('v.jorId'));
          //  alert (openSections);
            var action = component.get('c.GetEventList');
            action.setParams({            
                "JourneyId" : JSON.stringify(openSections)
    
            });
            action.setCallback(this, function(response){
               
                var state = response.getState(); 
                //alert(state);
                if(state === 'SUCCESS' || state === 'DRAFT'){
                    var responseValue = response.getReturnValue();
                    console.log('responseValue', responseValue);
                    component.set('v.EventList', responseValue);
                }
                else if (state === 'INCOMPLETE'){         
                }
                    else if (state === 'ERROR'){
                        var errors = response.getError();
                        console.log('Error', errors);
                    }
            },'ALL');
            $A.enqueueAction(action);
         var openSections = event.getParam('openSections');
          //  var id = JSON.stringify(openSections);
          //  alert (id);
          //  alert (openSections);
            var action1 = component.get('c.GetExList');
            action1.setParams({            
                "JourneyId" : JSON.stringify(openSections)
    
            });
            action1.setCallback(this, function(response){
               
                var state = response.getState(); 
                //alert(state);
                if(state === 'SUCCESS' || state === 'DRAFT'){
                    var responseValue = response.getReturnValue();
                    console.log('responseValue', responseValue);
                    component.set('v.ExList', responseValue);
                }
                else if (state === 'INCOMPLETE'){         
                }
                    else if (state === 'ERROR'){
                        var errors = response.getError();
                        console.log('Error', errors);
                    }
            },'ALL');
            $A.enqueueAction(action1);
        },
        // Mehod to redirect to the detail page of the record
        doRedirect:function (component, event){
           var id = event.currentTarget.name;
          //  alert(event.currentTarget.name);
          // alert(id);
            var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({
          "recordId": id
        });
        navEvt.fire(); 
       },
       // Method to open record detail page on another window
       openOnNewWindow: function(component, event, helper){
        var id = event.currentTarget.name;
        window.open('https://safeforce1.lightning.force.com/'+id ,'_blank');
       },
       // Method to open map on click of the map icon
        openMap: function(component, event, helper) {
        //    var Identity = event.getSource().get("v.name");
            // alert(Identity);
            var Identity = event.currentTarget.getAttribute("data-value");
   console.log(Identity);
           component.set("v.isOpen", true);
           var action = component.get('c.GetMapData');           
		action.setParams({JorId : Identity});
		action.setCallback(this, function(response) {
        var state = response.getState();
        // alert (state);
        if (state === 'SUCCESS') {
            component.set('v.mapMarkers',response.getReturnValue() );
            component.set('v.center', {
                location: {
                    City: 'Denver'
                }
            });

            component.set('v.zoomLevel', 4);
            component.set('v.markersTitle', 'Contact Locations Marker');
            component.set('v.showFooter', true);
        }else if (state === 'ERROR'){
            var errors = response.getError();
               console.log('Error', errors);
           } 
        });
        $A.enqueueAction(action);
     },
       // Method to close map window on click of close button
       closeMap: function(component, event, helper) {
          // for Hide/Close Model,set the "isOpen" attribute to "Fasle"  
          component.set("v.isOpen", false);
       },
       // Method to open form on click of add new button
       openForm: function(component, event, helper){
           component.set("v.openNewExpense", true);
           var Ident = event.getSource().get("v.name");
        //    alert(Ident);
},
       // Method to close New expense form on click of a close button
       closeExpense: function(component){
           component.set("v.openNewExpense", false);
       },
       // Method of save expense on click of save button  
       SaveExpense: function(component, event, helper){
        //    alert('method starts');
        //    alert(component.get('v.CreateExpense'));
        var Type = component.get("v.CreateExpense.Expense_Type__c");
        var Other = component.get("v.CreateExpense.If_Others_Please_specify__c");
        var Name = component.get("v.CreateExpense.Name");
        if(Name == ''){
alert('Name is mandatory.');
        }else if(Type == 'Select Type' || Type == ''){
alert('Please Select an Expense Type.');
        }else if(Type == 'Others' && Other == ''){
alert('Please specify other Expense.');
        }        
        else{
           var Ide = component.get('v.JorId');
           var Ide1 = Ide.replace('[','');
           var Ide2 = Ide1.replace(']','');
           var Ide3 = Ide2.replace('"','');
           var Ide4 = Ide3.replace('"','');
        //    alert(Ide4);
        var action = component.get('c.CreateExpense');
        // alert(action);
        action.setParams({ 
exp : component.get('v.CreateExpense') ,
JourId: Ide4
        });
        action.setCallback(this,function(Response){
var State = Response.getState();
if(State === 'SUCCESS'){
    var responseValue = Response.getReturnValue();
//  alert('Expense Saved Successfully');
 component.set("v.NewExpense",Response.getReturnValue());
 var ExpenseId = component.get("v.NewExpense");
//  component.set("v.openNewExpense", false);
}else if(State === 'ERROR'){
    // alert('error');
    var error = Response.getError();
    console.log(error);

}
        });
        $A.enqueueAction(action);

        var action1 = component.get('c.GetExList');
        action1.setParams({            
            "JourneyId" : Ide4

        });
        action1.setCallback(this, function(response){
           
            var state = response.getState(); 
            //alert(state);
            if(state === 'SUCCESS' || state === 'DRAFT'){
                var responseValue = response.getReturnValue();
                console.log('responseValue', responseValue);
                component.set('v.ExList', responseValue);
            }
            else if (state === 'INCOMPLETE'){         
            }
                else if (state === 'ERROR'){
                    var errors = response.getError();
                    console.log('Error', errors);
                }
        },'ALL');
        $A.enqueueAction(action1);
        helper.LoadTableMonth1(component,event,helper);
        

        /*
        var act1 = component.get('c.GetJourneyTotalAmount');
                        // alert('2nd method');
                        act1.setParams({
                            Year : Yeara,
                            Month : Montha,
                            CurrentUserId : $A.get("$SObjectType.CurrentUser.Id")
                        });
                        act1.setCallback(this, function(response){
                            var responseValue = response.getReturnValue();
                         // console.log('responsevalue', responseValue);
                            component.set('v.TotalAmount', responseValue);
                        });
                        $A.enqueueAction(act1, false);
        
        */
                       // $A.get('e.force:refreshView').fire();    
    }
    component.set("v.openNewExpense", false);
    component.set('v.CreateExpense','' );
    alert('Expense Saved Successfully');    
},
// Method to navigate to sObject
    dothis: function(component, event, helper){
        var Identity = event.currentTarget.getAttribute("data-value");
        // alert (Identity);
        var navEvt = $A.get("e.force:navigateToSObject");
    navEvt.setParams({
      "recordId": Identity,
      "slideDevName": "detail"
    });
    navEvt.fire(); 
   } ,
   // Method to submit for approval month vise
   SubmitforApproval: function(component, event, helper){
    var action = component.get('c.submitForApproval');
    var Identity = component.get('v.JourneyList');
    // alert(Identity);
    action.setParams({            
        "jour" : component.get('v.JourneyList')

    });
    action.setCallback(this, function(response){
       
        var state = response.getState(); 
        // alert(state);
        if(state === 'SUCCESS' || state === 'DRAFT'){
            var responseValue = response.getReturnValue();
            console.log('responseValue', responseValue);
            // component.set('v.EventList', responseValue);
            alert(responseValue);
        }
        else if (state === 'INCOMPLETE'){         
        }
            else if (state === 'ERROR'){
                var errors = response.getError();
                console.log('Error', errors);
            }
    },'ALL');
    $A.enqueueAction(action);
    helper.LoadTableMonth1(component,event,helper);

   },
// Method to submit for approval journey vise
   SubmitforApprovalSingle: function(component, event, helper){
    var action = component.get('c.submitForApprovalSingle');
    var Ident = event.getSource().get("v.name");
    action.setParams({            
        "jorId" : Ident

    });
    action.setCallback(this, function(response){
       
        var state = response.getState(); 
        // alert(state);
        if(state === 'SUCCESS' || state === 'DRAFT'){
            var responseValue = response.getReturnValue();
            console.log('responseValue', responseValue);
            // component.set('v.EventList', responseValue);
            alert(responseValue);
        }
        else if (state === 'INCOMPLETE'){         
        }
            else if (state === 'ERROR'){
                var errors = response.getError();
                console.log('Error', errors);
            }
    },'ALL');
    $A.enqueueAction(action);
    helper.LoadTableMonth1(component,event,helper);

   },
   // method to hide My journey and show teams journey
   hideMyJourneyView : function(component, event, helper){
    var hideJourneyView = component.find("MyJourney");
    var MyJourneyBtn = component.find("MyJourneyBtn");
    var TeamJourney = component.find("TeamJourney");
    var TeamJourneyView = component.find("TeamJourneyView");
    var ProfileViewCard = component.find("NormalHeading");
    var Teamview = component.find("ProfileDeatilHeading");
    $A.util.addClass(hideJourneyView, "slds-hide");
    $A.util.removeClass(TeamJourney, "slds-show");
    $A.util.addClass(TeamJourney, "slds-hide");
    $A.util.addClass(MyJourneyBtn, "slds-show");
    $A.util.removeClass(MyJourneyBtn, "slds-hide");
    $A.util.addClass(TeamJourneyView, "slds-show");
    $A.util.removeClass(TeamJourneyView, "slds-hide");
    $A.util.addClass(ProfileViewCard, "slds-hide");
    $A.util.removeClass(ProfileViewCard, "slds-show");
    $A.util.addClass(Teamview, "slds-show");
    $A.util.removeClass(Teamview, "slds-hide");
    var action = component.get('c.getallusers');
    action.setParams({
        UserId :$A.get("$SObjectType.CurrentUser.Id"),
    });
    action.setCallback(this, function(response){
        var state = response.getState();
      //  alert('State'+ state);
        var respo = response.getReturnValue();
        component.set('v.Users', respo);
        console.log(component.get("v.Users"));
    });
     //   alert(component.get('v.Users'));
    $A.enqueueAction(action, false);

            //Setting Current month for team view
            var result = new Date();
            var Max = new Date();
            var MDay = new Date();
            result.setMonth(result.getMonth() - 2);
            Max.setMonth(Max.getMonth() + 3);
            var todayDate = $A.localizationService.formatDate(result, "YYYY-MM");
            var today = $A.localizationService.formatDate(Max, "YYYY-MM");
            var CurrentMonth = $A.localizationService.formatDate(MDay, "YYYY-MM");
            component.set("v.Month1", CurrentMonth);
            component.set("v.MaxDate1", today);
            component.set("v.MinDate1", todayDate);
},
// method to hide teams journey and show my journey
hideTeamView : function(component, event, helper){
    var hideJourneyView = component.find("MyJourney");
    var MyJourneyBtn = component.find("MyJourneyBtn");
    var TeamJourney = component.find("TeamJourney");
    var TeamJourneyView = component.find("TeamJourneyView");
    var Teamview1 = component.find("ProfileDeatilHeading");
    var ProfileViewCard1 = component.find("NormalHeading");
    $A.util.addClass(hideJourneyView, "slds-show");
    $A.util.removeClass(hideJourneyView, "slds-hide");
    $A.util.removeClass(TeamJourney, "slds-hide");
    $A.util.addClass(TeamJourney, "slds-show");
    $A.util.addClass(MyJourneyBtn, "slds-hide");
    $A.util.removeClass(MyJourneyBtn, "slds-show");
    $A.util.addClass(TeamJourneyView, "slds-hide");
    $A.util.removeClass(TeamJourneyView, "slds-show");
    $A.util.removeClass(Teamview1, "slds-show");
    $A.util.addClass(Teamview1, "slds-hide");
    $A.util.removeClass(ProfileViewCard1, "slds-hide");
    $A.util.addClass(ProfileViewCard1, "slds-show");
},
// method to save selected user id in team journey view
selectUser : function(component, event, helper) {
    var user = component.find("User").get("v.value");
  //  alert(user);
        component.set("v.SelectedUser", user);
        helper.LoadTableMonthTeam(component, event, helper);
        /*
        var StDate = component.get('v.Month1');
        var array = StDate.split('-');
        var Yeara = array[0];
        var Montha = array[1];
        alert(Yeara);
        alert(Montha);
        var action = component.get('c.GetJourneyListMonthTeam');
                        action.setParams({
                            Year : Yeara,
                            Month : Montha,
                          //  CurrentUserId : $A.get("$SObjectType.CurrentUser.Id")
                           CurrentUserId : component.get('v.SelectedUser')  
                        });
                        action.setCallback(this, function(response){
                            var state = response.getState();
                            alert('State: '+ state);
                            var responseValue = response.getReturnValue();
                         // console.log('responsevalue', responseValue);
                            component.set('v.JourneyListTeam', responseValue);
                        });
                        $A.enqueueAction(action, false);
                        */
    },
    LoadTableMonthTeam: function(component, event, helper){
        helper.LoadTableMonthTeam(component, event, helper);
    },
    openRejection: function(component, event, helper){
        var Reco = event.getSource().get("v.name") ; 
        // alert(Reco);
        component.set("v.Rejection", true);
        component.set("v.RejectedJourney", Reco);
    },
    closeRejectionReason: function(component, event, helper){
        component.set("v.Rejection", false);
    },
    
    JourneyApprovalByManager: function(component, event, helper){
        try{
      //  alert('Step 1');
        var sub = component.get("v.SelectedUser");
        var Rec = $A.get("$SObjectType.CurrentUser.Id");
        var Reco = event.getSource().get("v.name") ; 
     var actionable = component.get('c.approveJourney');
      //      alert(actionable);
     actionable.setParams({            
        Submitter : sub,
        Receiver : Rec,
        record : Reco 
    });
    actionable.setCallback(this, function(response){
       var state = response.getState(); 
       //  alert(state);
        if(state === 'SUCCESS' || state === 'DRAFT'){
            var responseValue = response.getReturnValue();
            console.log('responseValue', responseValue);
            // component.set('v.EventList', responseValue);
            alert(responseValue);
        }
        else if (state === 'INCOMPLETE'){         
        }
            else if (state === 'ERROR'){
                var errors = response.getError();
                console.log('Error', errors);
            }
    },'ALL');
    $A.enqueueAction(actionable);
        } catch(e) {
 alert(e.getMessage());
}
    },
    JourneyrejectedByManager: function(component, event, helper){
      //  alert('Step 1');
        var sub = component.get("v.SelectedUser");
        var Rec = $A.get("$SObjectType.CurrentUser.Id");
        var Reco = component.get("v.RejectedJourney"); 
     //   alert(Reco);
         var actionable = component.get('c.rejectJourney');
      //      alert(actionable);
     actionable.setParams({            
        Submitter : sub,
        Receiver : Rec,
        record : Reco,
        Comment :  component.get("v.comment")
    });
    actionable.setCallback(this, function(response){
       var state = response.getState(); 
       //  alert(state);
        if(state === 'SUCCESS' || state === 'DRAFT'){
            var responseValue = response.getReturnValue();
            console.log('responseValue', responseValue);
            // component.set('v.EventList', responseValue);
            alert(responseValue);
        }
        else if (state === 'INCOMPLETE'){         
        }
            else if (state === 'ERROR'){
                var errors = response.getError();
                console.log('Error', errors);
            }
    },'ALL');
    $A.enqueueAction(actionable);
    
}
 })