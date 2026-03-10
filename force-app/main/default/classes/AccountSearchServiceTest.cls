@isTest
public class AccountSearchServiceTest {
    @TestSetup
    static void setup() {
        // Create test data for Salesforce accounts
        Map<String, Schema.RecordTypeInfo> recordTypeInfoMap = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();
        Id contaEmpresaRecordTypeId = recordTypeInfoMap.get('Conta_Empresa').getRecordTypeId();
        Id personAccountRecordTypeId = recordTypeInfoMap.get('PersonAccount').getRecordTypeId();
        
        Account acc1 = new Account(Name = 'Test Account 1', NIF__c = '111111111', Phone = '111111111', E_mail_Empresa__c = 'test1@example.com', Numero_de_Conta__c = '1001', RecordTypeId = contaEmpresaRecordTypeId);
        Account acc2 = new Account(Name = 'Account 2', NIF__c = '222222222', Phone = '222222222', E_mail_Empresa__c = 'test2@example.com', Numero_de_Conta__c = '1002', RecordTypeId = contaEmpresaRecordTypeId);
        Account acc3 = new Account(FirstName = 'Test', LastName = 'Account 3', NIF__c = '555555555', Phone = '555555555', E_mail_Empresa__c = 'test3@example.com', Numero_de_Conta__c = '10022137', RecordTypeId = personAccountRecordTypeId);
        
        List<Account> accs = new List<Account>();
        accs.add(acc1);
        accs.add(acc2);
        accs.add(acc3);
        insert accs;

        // Mock the MDM response

        // NOTE: This is not currently working because in line 179 of class c_PesquisaConta,
        // the mock response is hardcoded to be this particular client:
        // '{"status":"success","data":[{"active":true,"addresses":[{"city":"LISBON","countryCode":"PT","isContactPriority":true,"postalCode":"1234-123","usages":["INVOICE"]}],"clientNumber":10022137,"createdAt":"2022-03-21T12:32:28.670Z","creationStoreCode":"1","declaredStoreAttachement":"1","emailAddresses":[{"email":"testfida@gmail.com","isContactPriority":true,"type":"PERSONAL"}],"inhabitant":{"administrativeIdentifiers":{"nif":"123456789"},"civility":"MR","firstName":"TESTFIDA","gender":"MALE","lastName":"TESTFIDA"},"phones":[{"isContactPriority":true,"number":"123456789","type":"MOBILE"}],"universalClientNumber":"LMPT10022137","updatedAt":"2024-02-02T18:42:25.965Z","members":[]}],"_meta":{}}'
        // This means every time a callout is made to the MDM endpoint in a test scenario, the response will always be the same.

        // SCH_HttpMockClass mock = new SCH_HttpMockClass();
        // SCH_HttpMockClass.SimpleMockResponse m1 = new SCH_HttpMockClass.SimpleMockResponse('GET', '{"status":"success","data":[{"active":true,"addresses":[{"city":"LISBON","countryCode":"PT","isContactPriority":true,"postalCode":"1234-123","usages":["INVOICE"]}],"clientNumber":1003,"inhabitant":{"firstName":"Test","lastName":"Account 3","administrativeIdentifiers":{"nif":"555555555"}},"phones":[{"numberSF":"555555555"}],"emailAddresses":[{"email":"test3@example.com"}]}]}');
        // m1.statusCode = 200;
        // mock.addResponse('callout:MDM_Endpoint/clients?filter=[{"emailAddresses.email":{"$eq":"test3@example.com"}}]', m1);

        // Test.setMock(HttpCalloutMock.class, mock);
    }

    // @isTest
    // static void testSearchAccountsByName() {

    //     List<AccountSearchService.SearchRequest> requests = new List<AccountSearchService.SearchRequest>();
    //     AccountSearchService.SearchRequest request = new AccountSearchService.SearchRequest();
    //     request.searchString = 'Test';
    //     request.searchType = 'Primeiro Nome';
    //     requests.add(request);

    //     // SOSL always returns an empty list in test context, so we need to set fixed search results.
    //     // The expected accounts are those created in the @TestSetup method.
    //     List<Account> expectedAccounts = [SELECT Id, Name, NIF__c, Phone, E_mail_Empresa__c, Numero_de_Conta__c FROM Account WHERE Name LIKE '%Test%' OR FirstName LIKE '%Test%' OR LastName LIKE '%Test%'];
        
    //     List<Id> searchResultsIds = new List<Id>();
    //     for (Account acc : expectedAccounts) {
    //         searchResultsIds.add(acc.Id);
    //     }   
    //     Test.startTest();
    //     Test.setFixedSearchResults(searchResultsIds);
    //     List<List<AccountSearchResult>> results = AccountSearchService.searchAccounts(requests);
    //     Test.stopTest();               

    //     System.assertEquals(1, results.size());
    //     System.assertEquals(2, results[0].size()); // Refer to comment in line 22.
    // }

    @isTest
    static void testSearchAccountsByNIF() {
        List<AccountSearchService.SearchRequest> requests = new List<AccountSearchService.SearchRequest>();
        AccountSearchService.SearchRequest request = new AccountSearchService.SearchRequest();
        request.searchStrings =  new List<String>{'111111111'};
        request.searchType = 'NIF';
        requests.add(request);

        Test.startTest();
        List<List<AccountSearchResult>> results = AccountSearchService.searchAccounts(requests);
        Test.stopTest();               

        System.assertEquals(1, results.size());
        System.assertEquals(2, results[0].size()); // Refer to comment in line 22.
        System.assertEquals('111111111', results[0][0].nif);
    }

    @isTest
    static void testSearchAccountsByPhone() {
        List<AccountSearchService.SearchRequest> requests = new List<AccountSearchService.SearchRequest>();
        AccountSearchService.SearchRequest request = new AccountSearchService.SearchRequest();
        request.searchStrings =  new List<String>{'555555555'};
        request.searchType = 'Telemóvel';
        requests.add(request);

        Test.startTest();
        List<List<AccountSearchResult>> results = AccountSearchService.searchAccounts(requests);
        Test.stopTest();               

        System.assertEquals(1, results.size());
        System.assertEquals(1, results[0].size()); // Refer to comment in line 22.
        System.assertEquals('555555555', results[0][0].phone);
    }

    @isTest
    static void testSearchAccountsByEmail() {
        List<AccountSearchService.SearchRequest> requests = new List<AccountSearchService.SearchRequest>();
        AccountSearchService.SearchRequest request = new AccountSearchService.SearchRequest();
        request.searchStrings = new List<String>{'test1@example.com'};
        request.searchType = 'Email';
        requests.add(request);

        Test.startTest();
        List<List<AccountSearchResult>> results = AccountSearchService.searchAccounts(requests);
        Test.stopTest();               

        System.assertEquals(1, results.size());
        System.assertEquals(2, results[0].size()); // Refer to comment in line 22.
        System.assertEquals('test1@example.com', results[0][0].email);
    }

    @isTest
    static void testSearchAccountsByClientNumber() {
        List<AccountSearchService.SearchRequest> requests = new List<AccountSearchService.SearchRequest>();
        AccountSearchService.SearchRequest request = new AccountSearchService.SearchRequest();
        request.searchStrings =  new List<String>{'1001'};
        request.searchType = 'Nº de Cliente';
        requests.add(request);

        Test.startTest();
        List<List<AccountSearchResult>> results = AccountSearchService.searchAccounts(requests);
        Test.stopTest();               

        System.assertEquals(1, results.size());
        System.assertEquals(2, results[0].size()); // Refer to comment in line 22.
        System.assertEquals('1001', results[0][0].clientNumber);
    }

    @isTest
    static void testAccountSearchResultEmptyConstructor() {
        AccountSearchResult result = new AccountSearchResult();
    }
    // Note: Exceptions cannot be tested here because the response to the callout is hardcoded in c_PesquisaConta for test scenarios (see line 179).
}