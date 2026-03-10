@isTest
public class SCH_InvocableSendSMSTest {
    
    @testSetup
    static void setup() {

        Account a = new Account(
            Name = 'TestAccount'
        );
        insert a;
        
        ServiceAppointment sa = new ServiceAppointment(
            Subject = 'Test Appointment',
            Status = 'Scheduled',
            ParentRecordID = a.Id
        );
        insert sa;

        Folder f = [SELECT Id FROM Folder WHERE DeveloperName = 'Leroy_Merlin'];

        System.runAs(new User(Id = UserInfo.getUserId())){
            EmailTemplate et = new EmailTemplate(
                Name = 'Test Template',
                FolderId = f.Id,
                DeveloperName = 'Test_Template',
                TemplateType = 'text',
                Subject = 'Test Subject',
                HtmlValue = '<html><body>Test Email Body</body></html>',
                Body = 'Test Email Body'
            );
            insert et;
        }
    }
    @isTest
    static void testSCH_InvocableSendSMS() {
        ServiceAppointment sa = [SELECT Id, ParentRecordId FROM ServiceAppointment LIMIT 1];
        EmailTemplate et = [SELECT Id, Body FROM EmailTemplate WHERE DeveloperName = 'Test_Template' LIMIT 1];
        
        SCH_InvocableSendSMS.FlowInput input = new SCH_InvocableSendSMS.FlowInput();
        input.sa = sa;
        input.et = et;
        input.SMSTo = '+351999999999';
        
        List<SCH_InvocableSendSMS.FlowInput> inputs = new List<SCH_InvocableSendSMS.FlowInput>{input};
        
        Test.setMock(HttpCalloutMock.class, new SendSMSTest.TwilioHttpResponse_Success());
        Test.startTest();
        
        SCH_InvocableSendSMS.SCH_InvocableSendSMS(inputs);
        
        Integer jobCount = [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'Queueable'];
        System.assertEquals(1, jobCount);
        
        Test.stopTest();
    }
    
    // @isTest
    // static void testSCH_InvocableSendSMS_withTestRunning() {
    //     ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];
    //     EmailTemplate et = [SELECT Id, Body FROM EmailTemplate WHERE DeveloperName = 'Test_Template' LIMIT 1];
        
    //     SCH_InvocableSendSMS.FlowInput input = new SCH_InvocableSendSMS.FlowInput();
    //     input.sa = sa;
    //     input.et = et;
    //     input.SMSTo = '+351999999999';
        
    //     List<SCH_InvocableSendSMS.FlowInput> inputs = new List<SCH_InvocableSendSMS.FlowInput>{input};
        
    //     Test.startTest();
        
    //     SCH_InvocableSendSMS.SCH_InvocableSendSMS(inputs);
        
    //     Integer jobCount = [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'Future'];
    //     System.assertEquals(0, jobCount);
        
    //     Test.stopTest();
    // }
}