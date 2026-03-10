//@isTest
public class SendEmailTest {
    /*
    @isTest
    static void testSendEmailWithAttachment() {

            // Get Folder for test email template
            Folder f = [SELECT Id FROM Folder WHERE DeveloperName = 'Leroy_Merlin'];

            EmailTemplate testEmailTemplate;
            System.runAs(new User(Id = UserInfo.getUserId())){

                // Create a test email template
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

            // Create a test attachment Blob
            Blob testAttachmentBlob = Blob.valueOf('Test Attachment Content');

            // Create a test Account
            Account acc = new Account(
                Name = 'Test Account'
            );
            insert acc;

            // Create a test Contact
            Contact con = new Contact(
                AccountId = acc.Id,
                FirstName = 'Test',
                LastName = 'Contact',
                Email = 'test@test.com'
            );
            insert con;

            Id pbId = Test.getStandardPricebookId();
            RecordType recType = [SELECT Id, DeveloperName FROM RecordType WHERE DeveloperName = 'LM_Aluguer_Ferramentas'];

            Order testOrder = new Order(
                AccountId = acc.Id,
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

            // Call the method being tested
            Test.startTest();
            Messaging.SendEmailResult[] results = LM_SendEmail.SendEmail(
                testEmailTemplate,
                new List<String>{'receiver@example.com'},
                new List<String>{'cc@example.com'},
                new List<String>{'bcc@example.com'},
                con.Id,
                true, //treatTargetAsRecepient
                testOrder,
                new List<Blob>{testAttachmentBlob}
            );
            System.assertEquals(1, Limits.getEmailInvocations(), 'Emails should be sent');
            System.assertNotEquals(results, null);
            Test.stopTest();
    }
    */
}