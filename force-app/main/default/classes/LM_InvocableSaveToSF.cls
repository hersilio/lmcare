public without sharing class LM_InvocableSaveToSF {
    
    @invocableMethod(label='Save PDF to Salesforce' description='Save the PDF to the current context record')
    public static void savePDFToRecord(List<FlowInput> input){
        for (FlowInput i : input){
            String fileName = i.order.OrderNumber + ' - ' + i.mdt.Attachment_Name__c;
            Id existingFileId = LM_PdfCreator.fileExists(fileName, i.order.Id);
            if (existingFileId != null) {
                LM_PdfCreator.removeFile(existingFileId);
            }

            Blob pdfBlob = LM_PdfCreator.createPdfBlob(i.mdt.Email_Attachment_Template__c, i.order.Id);
            LM_PdfCreator.savePdfToSF(pdfBlob, i.order.Id, fileName);
        }
    }

    public class FlowInput{
        @InvocableVariable (label='Autocrat Process Setting' description='The Autocrat Process Setting metadata record')
        public LM_Autocrat_Process_Setting__mdt mdt;
        @InvocableVariable (label='Order' description='The Order record to which the PDF will be attached')
        public Order order;
    }
}