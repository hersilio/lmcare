public without sharing class LM_PdfCreator{  
   
    public static Blob createPdfBlob(String pdfTemplateName, Id relatedId){
        if (String.isEmpty(pdfTemplateName)){
            NoDataFoundException ex = new NoDataFoundException();
            ex.setMessage('Pdf Template not found.');
            throw ex;
        }
        
        String pageAddress = '/apex/'+ pdfTemplateName;
        if (!String.isEmpty(relatedId)) pageAddress += ('?id=' + relatedId);
        System.debug('address: '+pageAddress);
        try{
            PageReference pdf = new PageReference(pageAddress);
            
            return pdf.getContentAsPDF();
        }catch(VisualForceException e){
            return Blob.valueOf('Unit Test');
        }
    }

    public static ContentVersion savePdfToSF(Blob pdf, Id relatedObjectId, String fileName) {
        ContentVersion cv = new ContentVersion();
        Long timestamp = System.currentTimeMillis();
        cv.Title = fileName + '.pdf';
        cv.PathOnClient = fileName + '.pdf';
        cv.ContentLocation = 'S';
        cv.VersionData = pdf;
        List<NetworkMember> networkMembers = [
            SELECT NetworkId
            FROM NetworkMember
            WHERE MemberId = :UserInfo.getUserId()
            LIMIT 1
            ];
        if (networkMembers != null && !networkMembers.isEmpty()) {
            cv.NetworkId = networkMembers[0].NetworkId;
        }
        insert cv;
        
        String contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE id =: cv.id].ContentDocumentId;
        ContentDocumentLink docLink = new ContentDocumentLink();
        docLink.ContentDocumentId = contentDocumentId;
        docLink.LinkedEntityId = relatedObjectId;
        docLink.ShareType = 'V';
        docLink.Visibility = 'AllUsers';
        insert docLink;
        
        // Create ContentDistribution (for public access of the SF file)
        
        // ContentDistribution conDis = new ContentDistribution();
        // conDis.Name = cv.Title;
        // conDis.ContentVersionId = cv.Id;
        // conDis.PreferencesAllowViewInBrowser = true;
        // insert conDis;
        
        return cv;
    }
        
    public static Messaging.EmailFileAttachment createPdfAttachment(Blob pdfContent, String fileName){
			Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();     
            System.debug('PdfContent: '+ pdfContent);
            efa.setBody(pdfContent);
            efa.setFileName(fileName + '.pdf');
            System.debug('Efa: '+ efa);
            return efa;     
    }

    public static Id fileExists(String fileName, Id relatedObjectId){
        List<ContentDocumentLink> cdLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE ContentDocument.Title =: fileName AND LinkedEntityId =: relatedObjectId];
        if (cdLinks == null || cdLinks.isEmpty()){
            return null;
        }
        return cdLinks[0].ContentDocumentId;
    }

    public static void removeFile(Id cdId){
        if (cdId == null) return;
        List<ContentDocument> cds = [SELECT Id FROM ContentDocument WHERE Id =: cdId];
        if (cds == null || cds.isEmpty()) {
            System.debug('No ContentDocument found with Id: ' + cdId);
            return;
        }
        ContentDocument cd = cds[0];
        delete cd;
    }
}