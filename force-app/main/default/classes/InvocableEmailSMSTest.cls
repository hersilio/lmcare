@isTest
public class InvocableEmailSMSTest {
    /*

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
        System.runAs(new User(Id=UserInfo.getUserId())){
            Profile profile = [SELECT Id FROM Profile WHERE Name = 'LEROY MERLIN - Geral'];

            UserRole role = new UserRole(
            Name = 'LM Teste - Operacional',
            DeveloperName = 'LM_Teste_0_Operacional'
            );
            
            insert role;

            User testUser = new User(
                ProfileId = profile.Id,
                UserName = 'testuser@example.com.LMTestUserDev',
                LastName = 'mytestuser',
                UserRoleId = role.Id,
                Email = 'testuser@example.com',
                Alias = 'tuser',
                TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US'
            );

            insert testUser;
        }   

        Account testAccount = new Account(
            Name = 'Test Account'
            );
        insert testAccount;

        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = testAccount.Id,
            Email = 'testcontact@test.com'
        );
        insert testContact;

        Id pbId = Test.getStandardPricebookId();
        RecordType recType = [SELECT Id FROM RecordType WHERE DeveloperName = 'LM_Aluguer_Ferramentas'];

        Order testOrder = new Order(
            AccountId = testAccount.Id,
            EffectiveDate = Date.today(),
            Status = 'Rascunho',
            Description = 'Test Order',
            Name = '12345',
            Pricebook2Id = pbId,
            RecordTypeId = recType.Id
        );
        insert testOrder;

        LM_Store__c store = new LM_Store__c(
            Store_API_Name__c = 'LM_Teste',
            GDrive_Folder__c = 'Teste'
        );
        
        insert store;
    }

    @isTest
    public static void testGDriveCaller() {
        EmailTemplate testEmailTemplate = [SELECT Id FROM EmailTemplate LIMIT 1];
        User testUser = [SELECT Id, Store_API_Name__c FROM User WHERE UserName = 'testuser@example.com.LMTestUserDev'];

        LM_Autocrat_Process_Setting__mdt testMetadata = [SELECT Id, Email_Template_API_Name__c, Email_Attachment_Template__c, Attachment_Name__c FROM LM_Autocrat_Process_Setting__mdt WHERE DeveloperName = 'Aluguer_Ferramentas'];
        Order testOrder = [SELECT Id, AccountId, OrderNumber, EffectiveDate, Status, Description,Name, Pricebook2Id, Record_Type_API_Name__c FROM Order Where Name = '12345'];

        try{

            System.runAs(testUser){
                Test.startTest();
                
                Test.setMock(HttpCalloutMock.class, new GDriveResponseController());

                AsyncOptions asyncOptions = new AsyncOptions();
                asyncOptions.MaximumQueueableStackDepth = 1;
                System.enqueueJob(new LM_Invocable_Email_SMS.GDriveCaller(Blob.valueOf('testBlob'), testMetadata, testOrder), asyncOptions);
                
                Test.stopTest();
            }
            System.assert(true, 'No exceptions were thrown');
        }catch(Exception e){
            System.assert(false, 'An exception was thrown: ' + e.getMessage());
        }
    }

    @isTest
    public static void testAsyncEmail(){
        
        EmailTemplate testEmailTemplate = [SELECT Id, DeveloperName FROM EmailTemplate LIMIT 1];
        LM_Autocrat_Process_Setting__mdt testMetadata = [SELECT Id, Email_Template_API_Name__c, Email_Attachment_Template__c FROM LM_Autocrat_Process_Setting__mdt WHERE DeveloperName = 'Aluguer_Ferramentas'];
        Order testOrder = [SELECT Id, AccountId, OrderNumber, EffectiveDate, Status, Description,Name, Pricebook2Id, Record_Type_API_Name__c FROM Order Where Name = '12345'];
        
        try{
            
            Test.startTest();

            AsyncOptions asyncOptions = new AsyncOptions();
            asyncOptions.MaximumQueueableStackDepth = 1;
            
            System.enqueueJob(new LM_Invocable_Email_SMS.LM_Async_Email(
                new List<String>{'receiver@test.com'},
                new List<String>{'cc@test.com'},
                new List<String>{'bcc@test.com'},
                testOrder,
                testEmailTemplate,
                testMetadata), asyncOptions);
                
            Test.stopTest();
            System.assert(true, 'No exceptions were thrown');
        }catch(Exception e){
            System.assert(false, 'An exception was thrown: ' + e.getMessage());
        }

    }

    @isTest
    public static void AsyncFlowTest(){
        LM_Autocrat_Process_Setting__mdt testMetadata = [SELECT Id, Email_Template_API_Name__c, Email_Attachment_Template__c FROM LM_Autocrat_Process_Setting__mdt WHERE DeveloperName = 'Aluguer_Ferramentas'];
        Order testOrder = [SELECT Id, AccountId, OrderNumber, EffectiveDate, Status, Description,Name, Pricebook2Id, Record_Type_API_Name__c FROM Order Where Name = '12345'];

        LM_Invocable_Email_SMS.FlowInput testInput = new LM_Invocable_Email_SMS.FlowInput();
        testInput.order = testOrder;
        testInput.metadata = testMetadata;

        List<LM_Invocable_Email_SMS.FlowInput> testInputs = new List<LM_Invocable_Email_SMS.FlowInput>{ testInput };

        try{
            Test.startTest();
            LM_Invocable_Email_SMS.Async_Flow(testInputs);
            Test.stopTest();
            System.assert(true, 'No exceptions were thrown');
        }catch(Exception e){
            System.assert(false, 'An exception was thrown: ' + e.getMessage());
        }
    }
	*/
}