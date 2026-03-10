@isTest
public with sharing class LM_PicklistToStringTest {
    @isTest
    public static void LM_PicklistToStringTest() {
        List<String> multiPicklistValues = new List<String>();
        multiPicklistValues.add('value1');
        multiPicklistValues.add('value2');
        List<String> valuesReceived = LM_PicklistToString.invocablePicklistToString(multiPicklistValues);

        System.assertEquals(multiPicklistValues,valuesReceived);
    }
}