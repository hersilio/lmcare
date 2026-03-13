@isTest
public class SCH_Send_Appointment_SMSTest {
    
    @testSetup
    static void setup() {

        Account a = new Account(
            Name = 'TestAccount'
        );
        insert a;

        Contact c = new Contact(
            LastName = 'TestContact',
            AccountId = a.Id,
            Phone = '999999999'
        );
        insert c;

        Lead l = new Lead(
            LastName = 'TestLead',
            Company = 'TestCompany',
            status = 'QUALIFIED',
            Phone = '999999999'
        );
        insert l;
        
        ServiceAppointment sa1 = new ServiceAppointment(
            Subject = 'Test Appointment Contact',
            Status = 'Scheduled',
            ParentRecordId = a.Id
        );
        insert sa1;

        ServiceAppointment sa2 = new ServiceAppointment(
            Subject = 'Test Appointment Lead',
            Status = 'Scheduled',
            ParentRecordId = a.Id
        );
        insert sa2;

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
    static void testSCH_Send_Appointment_SMS_Contact() {
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment WHERE Subject = 'Test Appointment Contact'];
        EmailTemplate et = [SELECT Id, Body FROM EmailTemplate WHERE DeveloperName = 'Test_Template' LIMIT 1];
        Contact c = [SELECT Id, LastName, Phone FROM Contact WHERE LastName = 'TestContact'];
        
        SCH_Send_Appointment_SMS.FlowInput input = new SCH_Send_Appointment_SMS.FlowInput();
        input.sa = sa;
        input.et = et;
        input.receiver = c;
        List<SCH_Send_Appointment_SMS.FlowInput> inputs = new List<SCH_Send_Appointment_SMS.FlowInput>{input};
        
        Test.setMock(HttpCalloutMock.class, new SendSMSTest.TwilioHttpResponse_Success());
        Test.startTest();
        
        SCH_Send_Appointment_SMS.sendSMS(inputs);
        
        Integer jobCount = [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'Queueable'];
        System.assertEquals(1, jobCount);
        
        Test.stopTest();
    }

    @isTest
    static void testSCH_Send_Appointment_SMS_Lead() {
        ServiceAppointment sa = [SELECT Id FROM ServiceAppointment WHERE Subject = 'Test Appointment Lead'];
        EmailTemplate et = [SELECT Id, Body FROM EmailTemplate WHERE DeveloperName = 'Test_Template' LIMIT 1];
        Lead l = [SELECT Id, LastName, Phone FROM Lead WHERE LastName = 'TestLead'];
        
        SCH_Send_Appointment_SMS.FlowInput input = new SCH_Send_Appointment_SMS.FlowInput();
        input.sa = sa;
        input.et = et;
        input.receiver = l;
        List<SCH_Send_Appointment_SMS.FlowInput> inputs = new List<SCH_Send_Appointment_SMS.FlowInput>{input};
        
        Test.setMock(HttpCalloutMock.class, new SendSMSTest.TwilioHttpResponse_Success());
        Test.startTest();
        
        SCH_Send_Appointment_SMS.sendSMS(inputs);
        
        Integer jobCount = [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'Queueable'];
        System.assertEquals(1, jobCount);
        
        Test.stopTest();
    }
}