public without sharing class LM_InvocableGDriveSave {
	// @InvocableMethod (label='Save File to GDrive')
    // public static void saveFileToGDrive(List<FlowInput> input){
    //     for (FlowInput i : input){
    //         Blob pdfContent = LM_PdfCreator.createPdfBlob(i.mdt.Email_Attachment_Template__c, i.order.Id);
    //         if(Test.isRunningTest()) continue;
    //         System.enqueueJob(new LM_InvocableSendEmail.GDriveCaller(pdfContent, i.mdt, i.order));
    //     }
    // }
    
    // public class FlowInput{
        
    //     @InvocableVariable
    //     public LM_Autocrat_Process_Setting__mdt mdt;
    //     @InvocableVariable
    //     public Order order;
    // }
}