@isTest
public with sharing class InvocableSendTokenTest {
    
    @TestSetup
    static void makeData(){
        Account testAccount = new Account(
            Name = 'Test Account',
            Phone = '+351123456789'
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
    }

    @isTest
    public static void testSendToken(){
        LM_Autocrat_Process_Setting__mdt testMetadata = [SELECT Id, SMS_From__c, Token_Template_Name__c FROM LM_Autocrat_Process_Setting__mdt WHERE DeveloperName = 'Aluguer_Ferramentas'];
        Order testOrder = [SELECT Id, AccountId, OrderNumber, EffectiveDate, Status, Description,Name, Pricebook2Id, Record_Type_API_Name__c FROM Order Where Name = '12345'];
        EmailTemplate testEmailTemplate = [SELECT Id, Body FROM EmailTemplate LIMIT 1];

        LM_Invocable_Send_Token.FlowInput testInput = new LM_Invocable_Send_Token.FlowInput();
        testInput.order = testOrder;
        testInput.metadata = testMetadata;
        testInput.emailTemplate = testEmailTemplate;
        List<LM_Invocable_Send_Token.FlowInput> testInputs = new List<LM_Invocable_Send_Token.FlowInput>{ testInput };

     
        Test.startTest();
        LM_Invocable_Send_Token.sendToken(testInputs);
        Test.stopTest();
    }

    // @isTest
    // public static void testAsyncEmail(){
    //     EmailTemplate testEmailTemplate = [SELECT Id FROM EmailTemplate LIMIT 1];
    //     LM_Autocrat_Process_Setting__mdt testMetadata = [SELECT Id, SMS_From__c, Token_Template_Name__c FROM LM_Autocrat_Process_Setting__mdt WHERE DeveloperName = 'Aluguer_Ferramentas'];
    //     Order testOrder = [SELECT Id, AccountId, OrderNumber, EffectiveDate, Status, Description,Name, Pricebook2Id, Record_Type_API_Name__c FROM Order Where Name = '12345'];
        
    //     try{
            
    //         Test.startTest();

    //         AsyncOptions asyncOptions = new AsyncOptions();
    //         asyncOptions.MaximumQueueableStackDepth = 1;
            
    //         System.enqueueJob(new LM_Invocable_Send_Token.LM_Async_Email(
    //             new List<String>{'receiver@test.com'},
    //             new List<String>{'cc@test.com'},
    //             new List<String>{'bcc@test.com'},
    //             testOrder,
    //             testEmailTemplate,
    //             testMetadata), asyncOptions);
                
    //         Test.stopTest();
    //         System.assert(true, 'No exceptions were thrown');
    //     }catch(Exception e){
    //         System.assert(false, 'An exception was thrown: ' + e.getMessage());
    //     }
    // }


}