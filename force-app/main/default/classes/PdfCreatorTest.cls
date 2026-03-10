@isTest
public with sharing class PdfCreatorTest {
    
    @isTest
    static void testCreatePdfBlobWithTemplate() {
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

        // Set the PDF template name
        String pdfTemplateName = 'LM_DCI';

        // Call the method being tested
        Blob pdfBlob = LM_PdfCreator.createPdfBlob(pdfTemplateName, testOrder.Id);

        // Perform assertions
        System.assertNotEquals(null, pdfBlob, 'PDF Blob should not be null');
    }

    @isTest
    static void testCreatePdfBlobWithNoTemplate() {
        // Set the PDF template name to null
        String pdfTemplateName = null;

        // Call the method being tested and expect an exception
        try {
            Blob pdfBlob = LM_PdfCreator.createPdfBlob(pdfTemplateName, null);
            // If no exception is thrown, the test should fail
            System.assert(false, 'Expected an exception but none was thrown');
        } catch (NoDataFoundException ex) {
            System.assertEquals('Pdf Template not found.', ex.getMessage(), 'Incorrect exception message');
        }
    }

    @isTest
    static void testCreatePdfAttachment() {
        // Create a test PDF Blob
        Blob testPdfBlob = Blob.valueOf('Test PDF Content');

        // Call the method being tested
        Messaging.EmailFileAttachment attachment = LM_PdfCreator.createPdfAttachment(testPdfBlob,'Termos e Condicoes');

        // Perform assertions
        System.assertEquals('Termos e Condicoes.pdf', attachment.getFileName(), 'Incorrect attachment file name');
        System.assertEquals(testPdfBlob, attachment.getBody(), 'Incorrect attachment body');
    }

    @isTest
    static void testSavePdfToSF() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        Blob testPdfBlob = Blob.valueOf('Test PDF Content');
        String fileName = 'TestFile';
        Network net = [SELECT Id FROM Network LIMIT 1];

        Test.startTest();
        ContentVersion cv = LM_PdfCreator.savePdfToSF(testPdfBlob, testAccount.Id, fileName);
        Test.stopTest();

        System.assertNotEquals(null, cv.Id, 'ContentVersion should be inserted');
        List<ContentDocumentLink> links = [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :testAccount.Id];
        System.assertEquals(1, links.size(), 'Should be one ContentDocumentLink for the Account');
        System.assert(cv.Title.contains(fileName), 'ContentVersion Title should contain fileName');
        System.assertEquals(testPdfBlob, cv.VersionData, 'ContentVersion VersionData should match the PDF blob');
    }

    @isTest
    static void testFileExists_whenFileExists() {
        // Setup
        Account testAccount = new Account(Name = 'Test Account Exists');
        insert testAccount;
        Blob testPdfBlob = Blob.valueOf('Test PDF Content Exists');
        String fileName = 'TestFileExists.pdf';
        Network net = [SELECT Id FROM Network LIMIT 1];
        // Save a file
        ContentVersion cv = LM_PdfCreator.savePdfToSF(testPdfBlob, testAccount.Id, 'TestFileExists');
        // Test
        Id foundId = LM_PdfCreator.fileExists(fileName, testAccount.Id);
        System.assertNotEquals(null, foundId, 'fileExists should return ContentDocumentId when file exists');
    }

    @isTest
    static void testFileExists_whenFileDoesNotExist() {
        // Setup
        Account testAccount = new Account(Name = 'Test Account Not Exists');
        insert testAccount;
        String fileName = 'NonExistentFile.pdf';
        // Test
        Id foundId = LM_PdfCreator.fileExists(fileName, testAccount.Id);
        System.assertEquals(null, foundId, 'fileExists should return null when file does not exist');
    }

    @isTest
    static void testRemoveFile_whenFileExists() {
        // Setup
        Account testAccount = new Account(Name = 'Test Account Remove');
        insert testAccount;
        Blob testPdfBlob = Blob.valueOf('Test PDF Content Remove');
        String fileName = 'TestFileRemove';
        Network net = [SELECT Id FROM Network LIMIT 1];
        ContentVersion cv = LM_PdfCreator.savePdfToSF(testPdfBlob, testAccount.Id, fileName);
        Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        // Test
        Test.startTest();
        LM_PdfCreator.removeFile(docId);
        Test.stopTest();
        // Assert file is deleted
        List<ContentDocument> docs = [SELECT Id FROM ContentDocument WHERE Id = :docId];
        System.assertEquals(0, docs.size(), 'ContentDocument should be deleted');
    }

    @isTest
    static void testRemoveFile_whenFileDoesNotExist() {
        // Try to remove a non-existent file
        Test.startTest();
        LM_PdfCreator.removeFile('069000000000000AAA'); // Random/non-existent Id
        Test.stopTest();
        // No exception should be thrown
        System.assert(true, 'No exception thrown when removing non-existent file');
    }

}