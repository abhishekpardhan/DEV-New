({
    openCase : function(c,e,h,CaseNumber,CaseId) {
        let workspaceAPI = c.find("workspace");
        workspaceAPI.openTab({
            url: '#/sObject/' + CaseId + '/view',
            focus: true
        });
        workspaceAPI.getFocusedTabInfo().then(function (response) {
                let focusedTabId = response.tabId;
                console.log(focusedTabId);
                workspaceAPI.closeTab({
                    tabId: focusedTabId
                });
                return;
            })
            .catch(function (error) {
                console.log(error);
            });
            let toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Success!",
                "type": "success",
                "message": "Case has been created successfully with Case Number "+CaseNumber
            });
            toastEvent.fire();
    }
})