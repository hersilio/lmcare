public without sharing class LM_InvocableSendEmail {
    @InvocableMethod (label='Send Generic Email')
    public static void sendGenericEmail(List<FlowInput> input){
        for (FlowInput i: input){
            LM_Autocrat_Process_Setting__mdt mdt = [SELECT Id, Attachment_Name__c, Email_Attachment_Template__c, Order_Record_Type__c FROM LM_Autocrat_Process_Setting__mdt WHERE Order_Record_Type__c =: i.order.Record_Type_API_Name__c];
            System.enqueueJob(new LM_Async_Email(i, mdt));
        }
    }
    
    public class LM_Async_Email implements Queueable, Database.AllowsCallouts{
        FlowInput input;
        LM_Autocrat_Process_Setting__mdt mdt;
        public LM_Async_Email(FlowInput input, LM_Autocrat_Process_Setting__mdt mdt){
            this.input = input;
            this.mdt = mdt;
            input.CC = input.CC == null ? new List<String>() : input.CC;
            input.BCC = input.BCC == null ? new List<String>() : input.BCC;
        }

        public void execute(QueueableContext context){
            Blob pdfContent = null;
            Blob staticAttachment = null;
            List<Blob> attachments = new List<Blob>();
            if (!String.isEmpty(input.pdfTemplateName)){
                pdfContent = LM_PdfCreator.createPdfBlob(input.pdfTemplateName, input.order.Id);
                attachments.add(pdfContent);
            }
            if (!String.isEmpty(input.staticAttachmentName)){
                staticAttachment = [SELECT Id, Body FROM StaticResource WHERE Name =: input.staticAttachmentName].Body;
                attachments.add(staticAttachment);
            }
            String targetObjectId = '';
            if(input.targetAsRecipient){
                targetObjectId = [SELECT Id, AccountId FROM Contact WHERE AccountId =: input.order.AccountId].Id;
            } else {
                targetObjectId = '';
            }
            LM_SendEmail.SendEmail(input.emailTemplate, input.receivers, input.CC, input.BCC, targetObjectId, input.targetAsRecipient, input.order, attachments);
            if (!input.saveToSF){
                System.debug('Skipping saving PDF to SF as saveToSF is false');
                return;
            }
            if (pdfContent == null){
                System.debug('PDF content is null, skipping saving to SF');
                return;
            }
            // Save PDF to Salesforce
            ContentDocument cd = null;
            String fileName = input.order.OrderNumber + ' - ' + mdt.Attachment_Name__c;
            Id existingFileId = LM_PdfCreator.fileExists(fileName + '.pdf', input.order.Id);

            if (existingFileId != null){
                LM_PdfCreator.removeFile(existingFileId);
            }
            ContentVersion cv = LM_PdfCreator.savePdfToSF(pdfContent, input.order.Id, fileName);
            if (cv == null) System.debug('Failed to save PDF in Order: ' + input.order.Id);
            
            if (Test.isRunningTest()){
                return;
            }
        }
        
    
    }
    
    // public class GDriveCaller implements Queueable, Database.AllowsCallouts{
        
    //     public Blob pdfContent;
    //     public LM_Autocrat_Process_Setting__mdt mdt;
    //     public Order order;
        
    //     public GDriveCaller(Blob pdfContent, LM_Autocrat_Process_Setting__mdt mdt, Order order){
    //         this.pdfContent = pdfContent;
    //         this.mdt = mdt;
    //         this.order = order;
    //     }      
        
    //     public void execute(QueueableContext context){
    //         String fileType = 'pdf';
    //         String fileName = order.OrderNumber + ' - ' + mdt.Attachment_Name__c + '.'+ fileType;        
    //         String folderId = LM_GDriveUrlController.getGDriveFolderId(order.Id, mdt.Order_Record_Type__c);
    //         String fileId = LM_GoogleDriveAPIController.uploadFile(pdfContent, fileName, fileType, folderId);
    //         String gDriveLink = LM_GoogleDriveAPIController.getLinkFromFile(fileId);
    //         LM_GDriveUrlController.createUrl(fileName, gDriveLink, order.Id, fileId);
    //     }
    // }
	
    
    public class FlowInput{
        @InvocableVariable
        public String recipientId;
        @InvocableVariable
        public EmailTemplate emailTemplate;
        @InvocableVariable
        public List<String> receivers;
        @InvocableVariable
        public List<String> CC;
        @InvocableVariable
        public List<String> BCC;
        @InvocableVariable
        public Order order;
        @InvocableVariable
        public Boolean targetAsRecipient;
        @InvocableVariable
        public String pdfTemplateName;
        @InvocableVariable
        public String staticAttachmentName;
        @InvocableVariable
        public Boolean saveToSF;
    }
}