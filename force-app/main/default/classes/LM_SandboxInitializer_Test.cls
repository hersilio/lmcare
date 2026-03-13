/**
This test class tests the LM_SandboxInitializer class.

*/
@isTest
private class LM_SandboxInitializer_Test {

    @isTest
    static void testCreatePersonAccounts() {
        Test.startTest();
        LM_SandboxInitializer initializer = new LM_SandboxInitializer();
        initializer.createTestPersonAccounts(10);
        Integer numAccountsCreated = [SELECT Id FROM Account WHERE Record_Type_API_Name__c = 'PersonAccount'].size();
        System.assertEquals(10, numAccountsCreated);
        Test.stopTest();
    }
}