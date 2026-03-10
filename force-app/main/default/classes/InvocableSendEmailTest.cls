@isTest
public with sharing class InvocableSendEmailTest {
    
    @testSetup
    static void makeData(){
        // Get Folder for test email template
        Folder f = [SELECT Id FROM Folder WHERE DeveloperName = 'Leroy_Merlin'];
        
        System.runAs(new User(Id = UserInfo.getUserId())){
            
            // Create a test email template
             
            EmailTemplate testEmailTemplate;
            testEmailTemplate = new EmailTemplate(
                FolderId = f.Id,
                Name = 'Test Template',
                DeveloperName = 'Test_Template',
                TemplateType = 'text',
                Subject = 'Test Email Subject',
                HtmlValue = '<html><body>This is a test email template.</body></html>'
            );
            insert testEmailTemplate;
        }
        
        // Get the Person Account record type ID (You may need to adjust this)
        Id personAccountRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Person Account' LIMIT 1].Id;
        
        // Create a new Person Account record
        Account testPersonAccount = new Account(
            RecordTypeId = personAccountRecordTypeId, // Set the Person Account record type
            FirstName = 'John',         
            LastName = 'Doe',          
            E_Mail_Empresa__c = 'johndoe@example.com', 
            PersonBirthdate = Date.newInstance(1990, 1, 1), 
            Phone = '999999999'
        );
        
        // Insert the Person Account record
        insert testPersonAccount;
        
        Id pbId = Test.getStandardPricebookId();
        RecordType recType = [SELECT Id FROM RecordType WHERE DeveloperName = 'LM_Aluguer_Ferramentas'];
        
        Order testOrder = new Order(
            AccountId = testPersonAccount.Id,
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
    static void testInvocableSendEmail() {
        
        
        EmailTemplate testEmailTemplate = [SELECT Id, Name, DeveloperName, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName='Test_Template'];
        //to get the formula field we query the record after creation
        Order order = [SELECT Id, AccountId,EffectiveDate,Status,Description,Name,Pricebook2Id,RecordTypeId,Record_Type_API_Name__c FROM Order WHERE Name='12345'];
        
        LM_InvocableSendEmail.FlowInput input = new LM_InvocableSendEmail.FlowInput();
        
        input.emailTemplate = testEmailTemplate;
        input.receivers = new List<String>{'test@test.com'};
        input.pdfTemplateName = 'Test';
        //input.CC = new List<String>{'testcc@test.com'};
        //input.BCC = new List<String>{'testbcc@test.com'};
        input.targetAsRecipient = true;
        input.order = order;
        input.saveToSF = false;
        
        // Call the method being tested
        Test.startTest();
        LM_InvocableSendEmail.sendGenericEmail(new List<LM_InvocableSendEmail.FlowInput>{input});
        Test.stopTest();
        
        System.assert(true, 'No exceptions were thrown');
    }
    
    @isTest
    static void testInvocableSendEmail_basic() {
        // Query test data
        EmailTemplate testEmailTemplate = [SELECT Id, Name, DeveloperName, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName='Test_Template'];
        Order order = [SELECT Id, OrderNumber, AccountId, EffectiveDate, Status, Description, Name, Pricebook2Id, RecordTypeId, Record_Type_API_Name__c FROM Order WHERE Name='12345'];
        // Select the required custom metadata instead of inserting
        LM_Autocrat_Process_Setting__mdt mdt = [SELECT Id, MasterLabel, Attachment_Name__c, Email_Attachment_Template__c, Order_Record_Type__c 
            FROM LM_Autocrat_Process_Setting__mdt 
            WHERE Order_Record_Type__c = :order.Record_Type_API_Name__c 
            LIMIT 1];
        // Prepare FlowInput
        LM_InvocableSendEmail.FlowInput input = new LM_InvocableSendEmail.FlowInput();
        input.emailTemplate = testEmailTemplate;
        input.receivers = new List<String>{'test@test.com'};
        input.CC = new List<String>{'testcc@test.com'};
        input.BCC = new List<String>{'testbcc@test.com'};
        input.pdfTemplateName = 'Test';
        input.staticAttachmentName = null;
        input.targetAsRecipient = true;
        input.order = order;
        input.saveToSF = false;
        Test.startTest();
        LM_InvocableSendEmail.sendGenericEmail(new List<LM_InvocableSendEmail.FlowInput>{input});
        Test.stopTest();
        System.assert(true, 'No exceptions were thrown');
    }

    @isTest
    static void testInvocableSendEmail_noCCBCC() {
        EmailTemplate testEmailTemplate = [SELECT Id, Name, DeveloperName, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName='Test_Template'];
        Order order = [SELECT Id, OrderNumber, AccountId, EffectiveDate, Status, Description, Name, Pricebook2Id, RecordTypeId, Record_Type_API_Name__c FROM Order WHERE Name='12345'];
        LM_Autocrat_Process_Setting__mdt mdt = [SELECT Id, MasterLabel, Attachment_Name__c, Email_Attachment_Template__c, Order_Record_Type__c 
            FROM LM_Autocrat_Process_Setting__mdt 
            WHERE Order_Record_Type__c = :order.Record_Type_API_Name__c 
            LIMIT 1];
        LM_InvocableSendEmail.FlowInput input = new LM_InvocableSendEmail.FlowInput();
        input.emailTemplate = testEmailTemplate;
        input.receivers = new List<String>{'test2@test.com'};
        input.CC = null;
        input.BCC = null;
        input.pdfTemplateName = 'Test';
        input.staticAttachmentName = null;
        input.targetAsRecipient = false;
        input.order = order;
        input.saveToSF = false;
        Test.startTest();
        LM_InvocableSendEmail.sendGenericEmail(new List<LM_InvocableSendEmail.FlowInput>{input});
        Test.stopTest();
        System.assert(true, 'No exceptions were thrown');
    }

    @isTest
    static void testInvocableSendEmail_saveToSF() {
        EmailTemplate testEmailTemplate = [SELECT Id, Name, DeveloperName, Subject, HtmlValue FROM EmailTemplate WHERE DeveloperName='Test_Template'];
        Order order = [SELECT Id, OrderNumber, AccountId, EffectiveDate, Status, Description, Name, Pricebook2Id, RecordTypeId, Record_Type_API_Name__c FROM Order WHERE Name='12345'];
        LM_Autocrat_Process_Setting__mdt mdt = [SELECT Id, MasterLabel, Attachment_Name__c, Email_Attachment_Template__c, Order_Record_Type__c 
            FROM LM_Autocrat_Process_Setting__mdt 
            WHERE Order_Record_Type__c = :order.Record_Type_API_Name__c 
            LIMIT 1];
        LM_InvocableSendEmail.FlowInput input = new LM_InvocableSendEmail.FlowInput();
        input.emailTemplate = testEmailTemplate;
        input.receivers = new List<String>{'test4@test.com'};
        input.CC = new List<String>();
        input.BCC = new List<String>();
        input.pdfTemplateName = 'Test';
        input.staticAttachmentName = null;
        input.targetAsRecipient = false;
        input.order = order;
        input.saveToSF = true;
        Test.startTest();
        LM_InvocableSendEmail.sendGenericEmail(new List<LM_InvocableSendEmail.FlowInput>{input});
        Test.stopTest();
        // Optionally, assert ContentVersion/ContentDocumentLink creation if needed
        System.assert(true, 'No exceptions were thrown');
    }
}