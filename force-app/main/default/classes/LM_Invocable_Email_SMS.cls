// ESTA CLASSE ESTÁ OBSOLETA
public class LM_Invocable_Email_SMS {
    /*
    // Method that is called inside flow.

    @InvocableMethod(label='LM Send Email & SMS')
    public static void Async_Flow(List<FlowInput> input){
        for (FlowInput i: input){
            Order order = i.order;
            LM_Autocrat_Process_Setting__mdt mdt = i.metadata;
            Boolean targetAsRecipient = i.targetAsRecipient;
            
            EmailTemplate emailTemplate = [SELECT Id, DeveloperName, Body FROM EmailTemplate WHERE DeveloperName =: mdt.Email_Template_API_Name__c LIMIT 1];    
            
            List<String> receivers = new List<String>();
            List<String> CC = new List<String>();
            List<String> BCC = new List<String>();
            
            //Call subclass to send Email.
            if (Test.isRunningTest()){
                return;
            }
            System.enqueueJob(new LM_Async_Email(receivers, CC, BCC, targetAsRecipient, order, emailTemplate, mdt));
        }
    }
    
    public class LM_Async_Email implements Queueable, Database.AllowsCallouts{
        
        List<String> receivers;
        List<String> CC;
        List<String> BCC;

        Order order;
        EmailTemplate emailTemplate;
        LM_Autocrat_Process_Setting__mdt mdt;
        Boolean targetAsRecipient;
        
        public LM_Async_Email(List<String> receivers, List<String> CC, List<String> BCC,Boolean targetAsRecipient, Order order, EmailTemplate et, LM_Autocrat_Process_Setting__mdt mdt){
            
            this.receivers = receivers;
            this.CC = CC;
            this.BCC = BCC;
            this.order = order;
            this.emailTemplate = et;
            this.mdt = mdt;
            this.targetAsRecipient = targetAsRecipient;
        }
        
        public void execute(QueueableContext context){
            Blob pdfContent = LM_PdfCreator.createPdfBlob(mdt.Email_Attachment_Template__c, order.Id);
            System.debug('pdfContent: ' + pdfContent);
            Contact targetObjectId = [SELECT Id, AccountId FROM Contact WHERE AccountId =: order.AccountId];
            LM_SendEmail.SendEmail(emailTemplate, receivers, CC, BCC, targetObjectId.Id, targetAsRecipient, order, pdfContent);
            //String cvId = LM_PdfCreator.savePdf(pdfContent, whatId);
            if (Test.isRunningTest()){
                return;
            }
            //Call SubClass that creates Google Drive file and link.
            System.enqueueJob(new GDriveCaller(pdfContent, mdt, order));
        }
    }
    
    public class GDriveCaller implements Queueable, Database.AllowsCallouts{
        
        public Blob pdfContent;
        public LM_Autocrat_Process_Setting__mdt mdt;
        public Order order;
        
        public GDriveCaller(Blob pdfContent, LM_Autocrat_Process_Setting__mdt mdt, Order order){
            this.pdfContent = pdfContent;
            this.mdt = mdt;
            this.order = order;
        }      
        
        public void execute(QueueableContext context){
            String fileType = 'pdf';
            String fileName = order.OrderNumber + ' - ' + mdt.Attachment_Name__c +'.'+ fileType;        
            String folderId = LM_GDriveUrlController.getFolderIdFromCurrentUser(order.Record_Type_API_Name__c);
            String fileId = LM_GoogleDriveAPIController.uploadFile(pdfContent, fileName, fileType, folderId);
            String gDriveLink = LM_GoogleDriveAPIController.getLinkFromFile(fileId);
            LM_GDriveUrlController.createUrl(fileName, gDriveLink, order.Id, fileId);
            //String SMSFrom = mdt.SMS_From__c;
            //String SMSTo = order.AccountId.Phone;
            
            //EmailTemplate SMSTemplate = [SELECT Id, DeveloperName, Body FROM EmailTemplate WHERE DeveloperName = 'Send_Token_Template' LIMIT 1];
            
            //String SMSBody = Messaging.renderEmailTemplate(null, order.Id, new List<String>{SMSTemplate.Body})[0].getMergedBody();
            //if (!String.isEmpty(gDriveLink)) SMSBody += '\n' + gDriveLink;
            
            //System.enqueueJob(new LM_SendSMS(SMSFrom, SMSTo, SMSBody));
        }
    }
    
    public class FlowInput{
        @invocableVariable
        public Order order;
        @invocableVariable
        public LM_Autocrat_Process_Setting__mdt metadata;
        @invocableVariable
        public Boolean targetAsRecipient;
    }
	*/

}