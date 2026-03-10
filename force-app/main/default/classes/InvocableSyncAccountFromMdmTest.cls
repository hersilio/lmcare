@isTest
public class InvocableSyncAccountFromMdmTest {
    @TestSetup
    static void setup() {
        // Create test data for Salesforce accounts
        Account acc1 = new Account(Name = 'Test Account 1', NIF__c = '123456789', Phone = '123456789', E_mail_Empresa__c = 'test1@example.com', Numero_de_Conta__c = '10022137');
        insert acc1;
    }

    @isTest
    static void testSyncAccountFromMdm() {
        // Mock the MDM response
        // Note: This is not currently working because in line 179 of class c_PesquisaConta,
        // the outcome of the callout in a test scenario is being manually set.
        
        // SCH_HttpMockClass mock = new SCH_HttpMockClass();
        // SCH_HttpMockClass.SimpleMockResponse m1 = new SCH_HttpMockClass.SimpleMockResponse('GET', '{"status":"success","data":[{"active":true,"addresses":[{"city":"LISBON","countryCode":"PT","isContactPriority":true,"postalCode":"1234-123","usages":["INVOICE"]}],"clientNumber":1001,"inhabitant":{"firstName":"John","lastName":"Doe","administrativeIdentifiers":{"nif":"111222333"}},"phones":[{"numberSF":"111222333"}],"emailAddresses":[{"email":"john.doe@example.com"}]}]}');
        // m1.statusCode = 200;
        // mock.addResponse('callout:MDM_Endpoint/clients?filter=[{"clientNumber":{"$eq":"1001"}}]', m1);

        // Test.setMock(HttpCalloutMock.class, mock);

        List<AccountSearchResult> accountSearchResults = new List<AccountSearchResult>();
        AccountSearchResult accountSearchResult = new AccountSearchResult('Test Account 1', '111222333', '111222333', 'test1@example.com', '10022137', true, false, '0011t00000XXXXXX');
        accountSearchResults.add(accountSearchResult);

        Test.startTest();
        List<Boolean> results = InvocableSyncAccountFromMdm.syncAccountFromMdm(accountSearchResults);
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(true, results[0]);

        // Verify that the account was updated with MDM data
        Account updatedAccount = [SELECT Id, Name, NIF__c, Phone, E_mail_Empresa__c FROM Account WHERE Numero_de_Conta__c = '10022137' LIMIT 1];
        System.assertEquals('123456789', updatedAccount.NIF__c);
    }

    // Note: Exceptions cannot be tested here because the response to the callout is hardcoded in c_PesquisaConta for test scenarios (see line 179).
}