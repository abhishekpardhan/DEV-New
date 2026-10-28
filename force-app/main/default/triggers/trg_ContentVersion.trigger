/**
 * Description      :       Trigger to restrit users from uploading version of a file
 * Release          :       July, 2020
 * JIRA Ticket      :       
 * Created Date     :       July 14,2020
 * Created By       :       Monika Rawat
 **/
trigger trg_ContentVersion on ContentVersion (before insert) {
        if(System.Label.TriggerSwitch.equals('On')){
            if(trigger.isInsert && trigger.isBefore){
                Id SAProfileId = [select id from profile where name = 'System Administrator' limit 1].Id;
               Id IUProfileId = [select id from profile where name = 'Integration User' limit 1].Id;
               Id Profile1 = userinfo.getProfileId();
          for(ContentVersion con : Trigger.new){
                System.debug('@@@@@@@@@@@@@@@@@'+Trigger.new);
                              System.debug('########################'+Trigger.old);
                System.debug('!!!!!!!!!!!!!!!!!!!!!!!'+ con.VersionNumber);
               
              if(Profile1 != SAProfileId && Profile1!= IUProfileId){
                  if(con.ContentDocumentId != Null){
              con.adderror('You cannot upload a new version of a file');
          }else{
          }
          }
          }
          }
          }
          }