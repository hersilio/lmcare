//Class responsible for sending the email to the contact/email list.

public without sharing class LM_SendEmail{
    
    //Send Email Method.
    public static List<Messaging.SendEmailResult> SendEmail(EmailTemplate emailTemplate, List<String> receivers, List<String> CC, List<String> BCC, String targetObjectId, Boolean targetAsRecipient, Order order, List<Blob> emailAttachments) {
        OrgWideEmailAddress[] owea;
        Messaging.SendEmailResult[] results;
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        LM_Autocrat_Process_Setting__mdt mdt = [SELECT Id, Order_Record_Type__c, Static_Attachment_Name__c, Attachment_Name__c, Email_de_Envio__c FROM LM_Autocrat_Process_Setting__mdt WHERE Order_Record_Type__c =: order.Record_Type_API_Name__c];
        owea = [SELECT Id, Address, Purpose FROM OrgWideEmailAddress WHERE Address =: mdt.Email_de_Envio__c];
        
        if (owea == null){
            System.debug(owea);
            owea = [SELECT Id, Address, Purpose FROM OrgWideEmailAddress WHERE Purpose = 'DefaultNoreply' OR Purpose = 'UserSelectionAndDefaultNoReply' LIMIT 1];
        }
        
        System.debug(owea);
                
        if (owea.isEmpty()){
            System.debug('Org Wide Email Address not found.');
        }
        
        //render Email Template     
        mail.setHtmlBody(emailTemplate.HtmlValue);
        mail.setSubject(emailTemplate.Subject);
        
        //System.debug(emailTemplate.HtmlValue);
        //System.debug(emailTemplate.Subject);
        
        System.debug(owea.get(0).Id);
        
        mail.setTreatBodiesAsTemplate(True);
		mail.setOrgWideEmailAddressId(owea.get(0).Id);
        mail.setToAddresses(receivers);
        if (!CC.isEmpty()) mail.setCcAddresses(CC);
        if (!BCC.isEmpty()) mail.setBccAddresses(BCC);
        //if (!String.isBlank(order.Id))
        mail.setWhatId(order.Id);
        
        if (!String.isBlank(targetObjectId)) mail.setTargetObjectId(targetObjectId);      
        if (emailAttachments != null && !emailAttachments.isEmpty()){
            List<Messaging.EmailFileAttachment> efas = new List<Messaging.EmailFileAttachment>();
            Messaging.EmailFileAttachment efa = LM_PdfCreator.createPdfAttachment(emailAttachments[0], mdt.Attachment_Name__c);
            efas.add(efa);
            if (emailAttachments.size() > 1){
                Messaging.EmailFileAttachment efa2 = LM_PdfCreator.createPdfAttachment(emailAttachments[1], mdt.Static_Attachment_Name__c);
            	efas.add(efa2);
            }
            mail.setFileAttachments(efas);
        }
        
        if(!targetAsRecipient) mail.setTreatTargetObjectAsRecipient(false);   
        
        mail.setSaveAsActivity(true);
        mail.setUseSignature(false);
        List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
        system.debug(mail);
        allmsg.add(mail);

        results = Messaging.sendEmail(allmsg, false);
        System.Debug('Email results: '+ results);
        return results;
	        
        
    }
}