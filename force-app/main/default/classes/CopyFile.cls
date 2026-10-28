/**
 * Description		:		Test class for CopyFile apex class Used to copy file from one record to another
 * Created By       :       Shubham Girdhar
 * Created Date     :       12th Nov, 2019
 * Release          :       15th Nov, 2019
 * Last Modified on :       06/01/2020
 * Last Modified by :     Shubham Girdhar
 * Jira Ticket      :       https://safexpress.atlassian.net/browse/SD-505
 * Coverage			:		100%
 **/
public class CopyFile {
    public static void CopyFileFromRecord1to2 (Id record1, Id record2){
         ContentDocumentLink[] cd = [SELECT ContentDocumentId,Id,IsDeleted,LinkedEntityId,ShareType,SystemModstamp,Visibility FROM ContentDocumentLink WHERE LinkedEntityId =:record1 ORDER BY SystemModstamp DESC LIMIT 1];                        
         ContentVersion[] cv = [select Title,PathOnClient, Description,VersionData, FileType,Owner.Name, VersionNumber,CreatedDate,FileExtension from ContentVersion where ContentDocumentId =: cd[0].ContentDocumentId Limit 1];                        
                        system.debug('11111111111@@@@@@@@');
                        
                        ContentVersion conVer = new ContentVersion();
                        conVer.ContentLocation = 'S'; // S specify this document is in SF, use E for external files
                        conVer.PathOnClient = cv[0].PathOnClient; // The files name, extension is very important here which will help the file in preview.
                        conVer.Title = cv[0].Title; // Display name of the files
                        conVer.VersionData = cv[0].VersionData; // converting your binary string to Blog
                        //    conVer.ContentDocumentId = cd.ContentDocumentId;
                        insert conVer;
                        system.debug('@@@@@@@@@@@'+ conVer);
                        
                        Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;
                        system.debug('333333333333333333333333333333333333333333333333');
                        ContentDocumentLink cDe = new ContentDocumentLink();
                        cDe.ContentDocumentId = conDoc;
                        cDe.LinkedEntityId = record2; // you can use objectId,GroupId etc
                        cDe.ShareType = 'I'; // Inferred permission, checkout description of ContentDocumentLink object for more details
                        cDe.Visibility = 'AllUsers';
                        insert cDe;
                        system.debug('@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@'+ cDe);
        
    } 
}