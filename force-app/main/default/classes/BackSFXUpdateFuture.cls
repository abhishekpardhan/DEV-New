/*********************************************************************************************
**Author: Safexpress.com
**Description: Queueable class to invoke pullSFXData one by one to upsert the SFX records in Salesforce
**JIRA Ticket: SAC-108
**Test Class:  
**History: 
**Modified Date: 01/09/2023                
**Created By: Megha Kumar
*************************************************************************************************** */

public class BackSFXUpdateFuture implements Queueable,Database.AllowsCallouts {
    //Private String s;
    public List<String> sfxList ;
    /*public BackSFXUpdateFuture(String sfx){
        this.s = sfx;
    }*/
    public BackSFXUpdateFuture(List<String> sfxList){
        this.sfxList = sfxList;
    }
    public void execute(QueueableContext context) { 
        String sfxCode = this.sfxList[0];
        clsPullPropelISFX.pullSFXData(sfxCode);
        
        List<String> sfxListRemaining = this.sfxList;
        System.debug('sfxListRemaining prev -->'+sfxListRemaining);
        sfxListRemaining.remove(0); 
        System.debug('sfxListRemaining remaining -->'+sfxListRemaining);
        if(sfxListRemaining.size() > 0){
            ID nextJobId = System.enqueueJob(new BackSFXUpdateFuture(sfxListRemaining));
        }
        
    }
}