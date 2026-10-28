public class ReleaseController {
    @AuraEnabled
    public static list<Release__c> getReleaseList(){
        list<Release__c> releaseList = new list <Release__c> ([SELECT id, Name,Release_Date__c,Summary__c,Document_link__c FROM Release__c ORDER BY Release_Date__c]);
     //   return releaseList;
   
   // List<Object> someList = new List<Object>{1,2,3,4,5};
List<Release__c> reversed = new List<Release__c>();

for(Integer i = releaseList.size() - 1; i >= 0; i--){
    reversed.add(releaseList[i]);
}
        return reversed;
    }
}