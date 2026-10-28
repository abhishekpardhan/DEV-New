/** ---------------------------------------------------------
    Author:        Azad Singh
    Description:   Case Trigger
    History
    Date            Author             Comments
    ----------------------------------------------------------
    24/06/2020     Azad Singh          Initial Release
    -----------------------------------------------------------
*/

trigger CaseTrigger on Case (before insert, before update, after insert, after update) {
   new CaseTriggerHandler().run();  
}