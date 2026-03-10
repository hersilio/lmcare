@isTest
public with sharing class InvocableSaveToSFTest {
    @testSetup
    static void makeData() {
        // Create Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        // Create Order
        Id pbId = Test.getStandardPricebookId();
        RecordType recType = [SELECT Id FROM RecordType WHERE DeveloperName = 'LM_Aluguer_Ferramentas'];
        Order ord = new Order(
            AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Status = 'Rascunho',
            Description = 'Test Order',
            Name = '12345',
            Pricebook2Id = pbId,
            RecordTypeId = recType.Id
        );
        insert ord;
    }

    @isTest
    static void testSavePDFToRecord() {
        // Query test data
        Order order = [SELECT Id, OrderNumber, Record_Type_API_Name__c FROM Order WHERE Name = '12345' LIMIT 1];
        LM_Autocrat_Process_Setting__mdt mdt = [SELECT Id, Attachment_Name__c, Email_Attachment_Template__c, Order_Record_Type__c FROM LM_Autocrat_Process_Setting__mdt WHERE Order_Record_Type__c = :order.Record_Type_API_Name__c LIMIT 1];
        // Prepare FlowInput
        LM_InvocableSaveToSF.FlowInput input = new LM_InvocableSaveToSF.FlowInput();
        input.mdt = mdt;
        input.order = order;
        // Call the method
        Test.startTest();
        LM_InvocableSaveToSF.savePDFToRecord(new List<LM_InvocableSaveToSF.FlowInput>{input});
        Test.stopTest();
        // Assert ContentVersion/ContentDocumentLink was created
        String fileName = order.OrderNumber + ' - ' + mdt.Attachment_Name__c + '.pdf';
        List<ContentDocumentLink> links = [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :order.Id];
        System.assert(!links.isEmpty(), 'ContentDocumentLink should be created');
        ContentVersion cv = [SELECT Id, Title FROM ContentVersion WHERE Title = :fileName LIMIT 1];
        System.assertNotEquals(null, cv, 'ContentVersion should be created');
    }

    @isTest
    static void testSavePDFToRecord_removesExistingFile() {
        // Query test data
        Order order = [SELECT Id, OrderNumber, Record_Type_API_Name__c FROM Order WHERE Name = '12345' LIMIT 1];
        LM_Autocrat_Process_Setting__mdt mdt = [SELECT Id, Attachment_Name__c, Email_Attachment_Template__c, Order_Record_Type__c FROM LM_Autocrat_Process_Setting__mdt WHERE Order_Record_Type__c = :order.Record_Type_API_Name__c LIMIT 1];
        // Save a file first
        Blob testPdfBlob = Blob.valueOf('Test PDF Content');
        String fileName = order.OrderNumber + ' - ' + mdt.Attachment_Name__c;
        ContentVersion cv = LM_PdfCreator.savePdfToSF(testPdfBlob, order.Id, fileName);
        System.debug('ContentVersion created: ' + cv.Id + ' | ' + cv.Title);

        // Prepare FlowInput
        LM_InvocableSaveToSF.FlowInput input = new LM_InvocableSaveToSF.FlowInput();
        input.mdt = mdt;
        input.order = order;
        // Call the method
        Test.startTest();
        LM_InvocableSaveToSF.savePDFToRecord(new List<LM_InvocableSaveToSF.FlowInput>{input});
        Test.stopTest();
        // Assert only one ContentDocumentLink exists for the new document
        String fullFileName = fileName + '.pdf';
        ContentVersion latestCv = [SELECT ContentDocumentId FROM ContentVersion WHERE Title = :fullFileName ORDER BY CreatedDate DESC LIMIT 1];
        List<ContentDocumentLink> links = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :order.Id AND ContentDocumentId = :latestCv.ContentDocumentId];
        System.assertEquals(1, links.size(), 'Should only be one ContentDocumentLink for the new document after replacement');
    }
}