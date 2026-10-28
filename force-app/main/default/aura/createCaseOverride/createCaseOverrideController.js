({
    init: function (component) {

        let flow = component.find("flowId");
        let myPageRef = component.get("v.pageReference");
        console.log(JSON.stringify(myPageRef));
        // If Called From Contact Page
        if (myPageRef && myPageRef.state && myPageRef.state.recordId) {
            let recordId = myPageRef.state.recordId;
            var inputVariables = [{
                name: "contactId",
                type: "String",
                value: recordId
            }];
            flow.startFlow($A.get("$Label.c.Support_Case_Flow_Name"), inputVariables);
        } else {
            // If Open from New Case List Page
            flow.startFlow($A.get("$Label.c.Support_Case_Flow_Name"));
        }

    },
    handleStatusChange: function (c, e,h) {
        let caseId;
        let caseNumber;
        if (e.getParam("status") === "FINISHED") {
            // Get the output variables and iterate over them
            let outputVariables = e.getParam("outputVariables");
            let outputVar;
            for (var i = 0; i < outputVariables.length; i++) {
                outputVar = outputVariables[i];
                console.log('Output variable name from flow : ' , outputVar); 
                console.log('Output variable name from flow : ' + outputVar.name);
                console.log('Output variable value from flow : ' + outputVar.value);
                // If Case is Created From flow 
                if (outputVar.name === 'createdCaseId' && outputVar.value ) {
                    caseId = outputVar.value;
                }
                if (outputVar.name === 'caseNumber' && outputVar.value ) {
                    caseNumber = outputVar.value;
                }

            }
            if(caseId && caseNumber){ 
                h.openCase(c,e,h,caseNumber,caseId);
            }
        }
    }
});