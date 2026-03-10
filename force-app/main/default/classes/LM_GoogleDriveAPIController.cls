public without sharing class LM_GoogleDriveAPIController  {
    
    public class ResponseWrapper {
            @InvocableVariable(label='Response' description='Response' required=true)
            public String response;
            @InvocableVariable(label='Success Flag' description='Success Flag' required=true)
            public boolean isSuccess; 
        }
    
    @auraEnabled
    public static String uploadFile(Blob file, String filename, String filetype, String folderId){
        
        String boundary = '----------';
        String delimiter = '\r\n--' + boundary + '\r\n';
        String close_delim = '\r\n--' + boundary + '--'; 
        System.debug('===================fileData=======================' + file);  
        String bodyEncoded = EncodingUtil.base64Encode(file); 
        String body = delimiter + 'Content-Type: application/json \r\n\r\n' + '{ "name" : "' + filename + '",' + ' "mimeType" : "application/' + filetype + '"'+ (String.isEmpty(folderId)?'':',"parents" :["'+folderId+'"]')+'}' + delimiter + 'Content-Type: application/' + filetype + '\r\n' + 'Content-Transfer-Encoding: base64\r\n' + '\r\n' + bodyEncoded + close_delim;        
        system.debug('==================body======================' + body);  
        
        HttpRequest req = new HttpRequest();
        req.setHeader('Content-Type','multipart/related; boundary=' + boundary);
        req.setMethod('POST'); 
        req.setEndpoint('callout:GoogleDriveUpload'); 
        req.setBody(body); 
        Http h = new Http(); 
        ResponseWrapper rw = new ResponseWrapper();
        
        System.debug(req.getBody());
        try {
            HttpResponse resp = h.send(req);
            if(resp.getStatusCode() <= 299) {
                rw.isSuccess = True;
                System.debug('responseBody: ' + resp.getBody() + 'responseStatus: ' + resp.getStatus());
                Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(resp.getBody()) ;  
                system.debug('responseMap: ' + responseMap);
                rw.response = (String)responseMap.get('id');
            }
            else{
                rw.isSuccess = False;
                System.debug( resp.getBody()+'===='+resp.getStatus()  );
                rw.response = 'Error : '+ resp.getBody();
            }
        }
        catch(Exception ex) {
            rw.isSuccess = False;
            rw.response = 'Error : '+ ex.getMessage();
        }
        
        return rw.response; 
    }
    
    public static String removeFile(String fileId){
        HttpRequest req = new HttpRequest();
        req.setEndpoint('Callout:GoogleDriveGet/'+fileId+'?supportsAllDrives=true');
        req.setMethod('DELETE');
        Http h = new Http();
        
        try{
            HttpResponse resp = h.send(req);
            return 'Success';
        }catch(Exception ex){
            System.debug(ex.getMessage());
            throw ex;
        }
        
    }
    
    @auraEnabled
    public static String getLinkFromFile(String fileId){
        HttpRequest req = new HttpRequest();
        req.setEndpoint('Callout:GoogleDriveGet/'+fileId+'?fields=id,name,webContentLink,size,parents&supportsAllDrives=true&includeItemsFromAllDrives=true');
        req.setMethod('GET');
        Http h = new Http();
        
        try{
            HttpResponse resp = h.send(req);
            if (resp.getStatusCode() < 299){
                system.debug('responseBody: ' + resp.getBody());
                Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(resp.getBody());
                System.Debug('webContentLink: ' + (String)responseMap.get('webContentLink'));
                return (String)responseMap.get('webContentLink');
            }
        }catch(Exception ex){
            System.debug(ex.getMessage());
            throw ex;
        }
        return 'Error';
    }
    
    @AuraEnabled
    public static String getGDriveParentId(String parentFolder){
        HttpRequest req = new HttpRequest();
        req.setEndpoint('Callout:GoogleDriveGet'+'?q='+EncodingUtil.urlEncode('mimeType = \'application/vnd.google-apps.folder\' and name = \''+ parentFolder + '\'', 'utf-8')+'&supportsAllDrives=true'+'&includeItemsFromAllDrives=true');
        req.setMethod('GET');
        Http h = new Http();
        
        try{
            HttpResponse resp = h.send(req);
            if (resp.getStatusCode() < 299){
                Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(resp.getBody());
                List<Object> files = (List<Object>)responseMap.get('files');
                Map<String, Object> folder = (Map<String, Object>)files[0];
                System.Debug('files: ' + responseMap.get('files'));
                System.Debug('parentFolder Id: ' + folder.get('id'));
                //return (String)responseMap.get('files');
                return (String)folder.get('id');
            }
            system.debug('responseBody: ' + resp.getBody());
        }catch(Exception ex){
            System.debug(ex.getMessage());
            throw ex;
        }
        return '';
    }
    
    @AuraEnabled
    public static String getGDriveFolderId(String folderName, String parentFolder){
        parentFolder = getGDriveParentId(parentFolder);
        HttpRequest req = new HttpRequest();
        
        // query looks like: q='application/vnd.google-apps.folder' amd name = 'folderName' and 'parentId' in parents
        req.setEndpoint('Callout:GoogleDriveGet'+'?q='+EncodingUtil.urlEncode('mimeType = \'application/vnd.google-apps.folder\' and name = \''+ folderName + '\' and \'' + parentFolder + '\' in parents', 'utf-8') + '&supportsAllDrives=true'+'&includeItemsFromAllDrives=true');
        req.setMethod('GET');

        Http h = new Http();
        
        try{
            HttpResponse resp = h.send(req);
            if (resp.getStatusCode() < 299){
                Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(resp.getBody());
                List<Object> files = (List<Object>)responseMap.get('files');
                Map<String, Object> folder = (Map<String, Object>)files[0];
                System.Debug('files: ' + responseMap.get('files'));
                System.Debug('childFolder Id: ' + folder.get('id'));
                //return (String)responseMap.get('files');
                return (String)folder.get('id');
            }
            system.debug('responseBody: ' + resp.getBody());
        }catch(Exception ex){
            System.debug(ex.getMessage());
            throw ex;
        }
        return '';
    }

    // TODO IF NECESSARY
    // @AuraEnabled
    // public static String createFolder(){
    //     try {
    //         HttpRequest req = new HttpRequest();
    //         req.setEndpoint('Callout:GoogleDriveGet');
    //         req.setMethod('POST');
    //         req.setHeader('Content-Type', 'application/json');
    //         String body = '{"name": "New Folder", "mimeType": "application/vnd.google-apps.folder"}';
    //         req.setBody(body);
    //         Http h = new Http();
    //         HttpResponse resp = h.send(req);
            
    //         if (resp.getStatusCode() < 299) {
    //             Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(resp.getBody());
    //             return (String)responseMap.get('id');
    //         } else {
    //             System.debug('Error creating folder: ' + resp.getBody());
    //             return null;
    //         }
    //     } catch (Exception ex) {
    //         System.debug(ex.getMessage());
    //         throw ex;
    //     }
    // }
}