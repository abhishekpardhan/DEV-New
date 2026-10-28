({
	LoadJourneyHelper : function(component, event, helper) {
        var StDate = component.get('v.Month');
        var array = StDate.split('-');
        var Yeara = array[0];
        var Montha = array[1];
        var action = component.get("c.GetJourneyList");
        action.setParams({            
            Year : Yeara,
            Month : Montha,
            CurrentUserId : component.get("v.SelectedUser")

        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log(response.getReturnValue());
            if (state == "SUCCESS") {
                component.set("v.JourneyList", response.getReturnValue());
            }
            else {
                console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);
         var action1 = component.get("c.GetJourneyListTravel");
        action1.setParams({            
            Year : Yeara,
            Month : Montha,
            CurrentUserId : component.get("v.SelectedUser")

        });
        action1.setCallback(this, function(response) {
            var state = response.getState();
            console.log(response.getReturnValue());
            if (state == "SUCCESS") {
                component.set("v.JourneyList1", response.getReturnValue());
            }
            else {
                console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action1);
        var action2 = component.get("c.GetUserProfile");
        action2.setParams({            
            userId: component.get("v.SelectedUser")
        });
        action2.setCallback(this, function(response) {
            var state = response.getState();
            console.log(response.getReturnValue());
            if (state == "SUCCESS") {
                component.set("v.Userdetail", response.getReturnValue());
            }
            else {
                console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action2);

        var act = component.get('c.GetJourneyCountTeam');   
                        // alert('2nd method');
                        act.setParams({
                            Year : Yeara,
                            Month : Montha,
                            CurrentUserId : component.get('v.SelectedUser')
                        });
                        act.setCallback(this, function(response){
                            var responseValue = response.getReturnValue();
                         // console.log('responsevalue', responseValue);
                            component.set('v.TotalJourneyCon', responseValue);
                        });
                        $A.enqueueAction(act, false);

                        
                        var act1 = component.get('c.GetJourneyTotalAmountTeam');
                        // alert('2nd method');
                        act1.setParams({
                            Year : Yeara,
                            Month : Montha,
                            CurrentUserId : component.get('v.SelectedUser')
                        });
                        act1.setCallback(this, function(response){
                            var responseValue = response.getReturnValue();
                         // console.log('responsevalue', responseValue);
                            component.set('v.TotalAmountCon', responseValue);
                        });
                        $A.enqueueAction(act1, false);

        var approvedApmount = component.get('c.GetJourneyTotalApprovedAmountTeam');
                        // alert('2nd method');
                        approvedApmount.setParams({
                            Year : Yeara,
                            Month : Montha,
                            CurrentUserId : component.get('v.SelectedUser')
                        });
                        approvedApmount.setCallback(this, function(response){
                            var responseValue = response.getReturnValue();
                         // console.log('responsevalue', responseValue);
                        // alert(responseValue);
                            component.set('v.ApprovedAmountCon', responseValue);
                        });
                        $A.enqueueAction(approvedApmount, false);
        
        var approvedApmountTra = component.get('c.GetJourneyTotalApprovedAmountTra');
                        // alert('2nd method');
                        approvedApmountTra.setParams({
                            Year : Yeara,
                            Month : Montha,
                            CurrentUserId : component.get('v.SelectedUser')
                        });
                        approvedApmountTra.setCallback(this, function(response){
                            var responseValue = response.getReturnValue();
                         // console.log('responsevalue', responseValue);
                        // alert(responseValue);
                            component.set('v.ApprovedAmountTra', responseValue);
                        });
                        $A.enqueueAction(approvedApmountTra, false);
        
                        var act2 = component.get('c.GetJourneyTotalEventTeam');
                        // alert('2nd method');
                        act2.setParams({
                            Year : Yeara,
                            Month : Montha,
                            CurrentUserId : component.get('v.SelectedUser')
                        });
                        act2.setCallback(this, function(response){
                            var responseValue = response.getReturnValue();
                         // console.log('responsevalue', responseValue);
                            component.set('v.TotalEventCon', responseValue);
                        });
                        $A.enqueueAction(act2, false);
                    
                    var act3 = component.get('c.GetJourneyTotalDistanceTeam');
                        // alert('2nd method');
                        act3.setParams({
                            Year : Yeara,
                            Month : Montha,
                            CurrentUserId : component.get('v.SelectedUser')
                        });
                        act3.setCallback(this, function(response){
                            var responseValue = response.getReturnValue();
                         // console.log('responsevalue', responseValue);
                            component.set('v.TotalDistanceCon', responseValue);
                        });
                        $A.enqueueAction(act3, false);

     // summary for second tab
                        var act4 = component.get('c.GetJourneyCountTra');   
                        // alert('2nd method');
                        act4.setParams({
                            Year : Yeara,
                            Month : Montha,
                            CurrentUserId : component.get('v.SelectedUser')
                        });
                        act4.setCallback(this, function(response){
                            var responseValue = response.getReturnValue();
                         // console.log('responsevalue', responseValue);
                            component.set('v.TotalJourneyTra', responseValue);
                        });
                        $A.enqueueAction(act4, false);

                        
                        var act5 = component.get('c.GetJourneyTotalAmountTra');
                        // alert('2nd method');
                        act5.setParams({
                            Year : Yeara,
                            Month : Montha,
                            CurrentUserId : component.get('v.SelectedUser')
                        });
                        act5.setCallback(this, function(response){
                            var responseValue = response.getReturnValue();
                         // console.log('responsevalue', responseValue);
                            component.set('v.TotalAmountTra', responseValue);
                        });
                        $A.enqueueAction(act5, false);

                        var act6 = component.get('c.GetJourneyTotalEventTra');
                        // alert('2nd method');
                        act6.setParams({
                            Year : Yeara,
                            Month : Montha,
                            CurrentUserId : component.get('v.SelectedUser')
                        });
                        act6.setCallback(this, function(response){
                            var responseValue = response.getReturnValue();
                         // console.log('responsevalue', responseValue);
                            component.set('v.TotalEventTra', responseValue);
                        });
                        $A.enqueueAction(act6, false);
                    
                    var act7 = component.get('c.GetJourneyTotalDistanceTra');
                        // alert('2nd method');
                        act7.setParams({
                            Year : Yeara,
                            Month : Montha,
                            CurrentUserId : component.get('v.SelectedUser')
                        });
                        act7.setCallback(this, function(response){
                            var responseValue = response.getReturnValue();
                         // console.log('responsevalue', responseValue);
                            component.set('v.TotalDistanceTra', responseValue);
                        });
                        $A.enqueueAction(act7, false);

    },
    LoadUserList : function(component, event, helper) {
  //      helper.LoadJourneyHelper(component,event,helper);
        var StDate = component.get('v.Month');
        var array = StDate.split('-');
        var Yeara = array[0];
        var Montha = array[1];
     //   alert(component.get('v.RegionSelected'));
     //       alert(Yeara);
     //       alert(Montha);
  var action = component.get("c.getUser");
        action.setParams({            
         //   "ID" : component.get('v.SelectedId'),
           "Region": component.get('v.RegionSelected'),
            "Year": Yeara,
            "Month": Montha
        });
        action.setCallback(this, function(response){
           
            var state = response.getState(); 
          //  alert(state);
            if(state === 'SUCCESS' || state === 'DRAFT'){
                
                var responseValue = response.getReturnValue();
                var arrayMapKeys = [];
            //    console.log('responseValue', responseValue);
            //    console.log('responce key'+ Object.keys(responseValue));
              //  alert(responseValue);
              //  component.set('v.userMap', responseValue);
              //  console.log(component.get('v.userMap'));
                for(var key in responseValue){
             //       alert(responseValue[key]);
              //      alert(key);
                  arrayMapKeys.push({key: key, value: responseValue[key]});
                  
               }
              //  console.log('zxcvbnm'+ arrayMapKeys );
                component.set('v.userMap', arrayMapKeys);
      //  console.log('asdfghjkl'+ component.get("v.userMap"));
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
})