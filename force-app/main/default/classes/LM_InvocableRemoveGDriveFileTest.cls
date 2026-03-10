@IsTest
public with sharing class LM_InvocableRemoveGDriveFileTest {
    @TestSetup
    static void makeData(){
        System.runAs(new User(Id=UserInfo.getUserId())){
            Profile profile = [SELECT Id FROM Profile WHERE Name = 'LEROY MERLIN - Geral'];

            UserRole role = new UserRole(
            Name = 'LM Teste - Operacional999',
            DeveloperName = 'LM_Teste_0_Operacional9999'
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

        LM_GDrive_File_Link__c link = new LM_GDrive_File_Link__c(
            fileId__c = '12345',
            Order__c = testOrder.Id
        );
        insert link;
    }   
    public class GDriveResponseController implements HttpCalloutMock{

        public HttpResponse respond(HttpRequest req){
            HttpResponse res = new HttpResponse();
            res.setBody('{"files":[{"id":"1111"}]}');
            res.setStatusCode(201);
            return res;
        }
    }
    
    @IsTest
    public static void testRemoveGDriveFile(){
        
        EmailTemplate testEmailTemplate = [SELECT Id FROM EmailTemplate LIMIT 1];
        User testUser = [SELECT Id, Store_API_Name__c FROM User WHERE UserName = 'testuser@example.com.LMTestUserDev'];

        LM_Autocrat_Process_Setting__mdt testMetadata = [SELECT Id, Email_Template_API_Name__c, Email_Attachment_Template__c, Attachment_Name__c FROM LM_Autocrat_Process_Setting__mdt WHERE DeveloperName = 'Aluguer_Ferramentas'];
        Order testOrder = [SELECT Id, AccountId, OrderNumber, EffectiveDate, Status, Description,Name, Pricebook2Id, Record_Type_API_Name__c FROM Order Where Name = '12345'];

        

        System.runAs(testUser){
            Test.startTest();
            
            Test.setMock(HttpCalloutMock.class, new GDriveResponseController());

            LM_GDrive_File_Link__c file = [SELECT Id, fileId__c FROM LM_GDrive_File_Link__c WHERE fileId__c = '12345'];
            LM_InvocableRemoveGDriveFile.FlowInput input = new LM_InvocableRemoveGDriveFile.FlowInput();
            input.fileId = '12345';
            LM_InvocableRemoveGDriveFile.removeGDriveFile(new List<LM_InvocableRemoveGDriveFile.FlowInput>{input});
            
            Test.stopTest();
        }
        System.assert(true, 'No exceptions were thrown');
    }

    @isTest
    public static void testQRemoveGDriveFile(){
        Test.startTest();
        String fileId = '12345';
        System.enqueueJob(new LM_InvocableRemoveGDriveFile.qRemoveGDriveFile(fileId));
        Test.stopTest();
    }


}