/**
 * Description		:		Test class for PicklistEntryWrapper apex class
 * 
 * Coverage			:		100%
 **/
@isTest
public class PicklistEntryWrapper_Test {

    @isTest static void test1() {
        
        PicklistEntryWrapper wrap = new PicklistEntryWrapper();
        wrap.active = 'Active';
        wrap.defaultValue = 'default';
        wrap.label = 'label';
        wrap.validFor = 'valid';
        wrap.value = 'value';
    }
}