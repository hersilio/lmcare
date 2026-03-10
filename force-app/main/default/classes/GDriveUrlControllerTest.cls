@isTest
public class GDriveUrlControllerTest {

    public class GDriveResponseController implements HttpCalloutMock{

        public HttpResponse respond(HttpRequest req){
            HttpResponse res = new HttpResponse();
            res.setBody('{"files":[{"id":"1111"}]}');
            res.setStatusCode(201);
            return res;
        }
    }

    @TestSetup
    static void makeData(){
        
        LM_Store__c store = new LM_Store__c(
            Store_API_Name__c = 'LM_Teste',
            GDrive_Folder__c = 'Teste'
            );
        
        insert store;

        Account testAccount = new Account(
            Name = 'Test Account'
            );
        insert testAccount;

        Id pbId = Test.getStandardPricebookId();
        RecordType recType = [SELECT Id FROM RecordType WHERE DeveloperName = 'LM_Aluguer_Ferramentas'];

        Order order = new Order(
            AccountId = testAccount.Id,
            EffectiveDate = Date.today(),
            Status = 'Rascunho',
            Description = 'Test Order',
            Name = '123456',
            Pricebook2Id = pbId,
            RecordTypeId = recType.Id,
            Store__c = store.Id
        );
        insert order;

    }

    @isTest
    static void testGetOrderFolderId() {
        String orderRecordType = 'LM_Aluguer_Ferramentas';
        Order order = [SELECT Id FROM Order WHERE Name = '123456' LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new GDriveResponseController());
        Test.startTest();
        // Call the method being tested
        String result = LM_GDriveUrlController.getGDriveFolderId(order.Id, orderRecordType);

        Test.StopTest();
        // Perform assertions
        System.assertEquals('1111', result);
    }

    @isTest
    static void testCreateUrl(){
        
        //Create Account
        Account acc = new Account(
            Name = 'Test Account'
        );
        insert acc;

        //Create Order
        Order o = new Order(
            AccountId = acc.Id,
            Status = 'Rascunho',
            Name = '123456',
            EffectiveDate = Date.Today()
        );
        insert o;

        String filename = 'myfile.pdf';
        String fileUrl = 'http://myurl.com';
        String orderId = o.Id;
        String fileId = '123456789';

        LM_GDrive_File_Link__c link = LM_GDriveUrlController.createUrl(filename, fileUrl, orderId, fileId); 
        System.assertEquals(link.File_Name__c, 'myfile.pdf');
    }
}