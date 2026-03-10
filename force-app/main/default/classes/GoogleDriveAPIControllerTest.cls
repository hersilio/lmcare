@isTest
public with sharing class GoogleDriveAPIControllerTest {

    static Blob file = Blob.valueOf('mytestfile');
    static String filename = 'test.pdf';
    static String filetype = 'pdf';
    static String folderId = '000000000';

    public class GDriveUploadResponseTest_Success implements HttpCalloutMock{

        public HttpResponse respond(HttpRequest req){
            System.assertEquals('callout:GoogleDriveUpload', req.getEndpoint());
            System.assertEquals('POST', req.getMethod());

            String body = '{"id": "0000000001"}';     
        
            HttpResponse res = new HttpResponse();
            res.setBody(body);
            res.setStatusCode(201);

            return res;
        }
    }

    public class GDriveUploadResponseTest_Fail implements HttpCalloutMock{

        public HttpResponse respond(HttpRequest req){
            System.assertEquals('callout:GoogleDriveUpload', req.getEndpoint());
            System.assertEquals('POST', req.getMethod());

            String body = '{"id": "0000000001"}' ;      
        
            HttpResponse res = new HttpResponse();
            res.setBody(body);
            res.setStatusCode(400);

            return res;
        }
    }

    public class ResponseGetLinkFromFile_Success implements HttpCalloutMock{
        String fileId;

        public HttpResponse respond(HttpRequest req){
            System.assertEquals('Callout:GoogleDriveGet/'+fileId+'?fields=id,name,webContentLink,size,parents&supportsAllDrives=true&includeItemsFromAllDrives=true', req.getEndpoint());
            System.assertEquals('GET', req.getMethod());   
        
            HttpResponse res = new HttpResponse();

            String body = '{"webContentLink": "http://myGDriveLink.com/file.pdf"}';
            res.setBody(body);
            res.setStatusCode(201);

            return res;
        }
    }

    

    public class ResponseGetGDriveFolderId_Success implements HttpCalloutMock{
        String parentFolder;
        String folderName;

        public HttpResponse respond(HttpRequest req){

            System.assertEquals('GET', req.getMethod());   
        
            HttpResponse res = new HttpResponse();

            String body = '{"files":[{"id":"1111"}]}';
            res.setBody(body);
            res.setStatusCode(201);

            return res;
        }
    }

    public class ResponseRemoveFile_Success implements HttpCalloutMock{
        String fileId;

        public HttpResponse respond(HttpRequest req){

            System.assertEquals('DELETE', req.getMethod());   
        
            HttpResponse res = new HttpResponse();

            String body = '{"files":[{"id":"1111"}]}';
            res.setBody(body);
            res.setStatusCode(201);

            return res;
        }
    }

    public class ErrorResponse implements HttpCalloutMock{
        
        public HttpResponse respond(HttpRequest req){
            throw new CalloutException('Callout can\'t be done.');
        }
    }

    //Tests
    @isTest
    static void uploadFileTest_Success(){
        Test.setMock(HttpCalloutMock.class, new GDriveUploadResponseTest_Success());
        String response = LM_GoogleDriveAPIController.uploadFile(file, filename, filetype, folderId);

        System.assertEquals('0000000001', response);
    }

    @isTest
    static void uploadFileTest_Fail(){
        Test.setMock(HttpCalloutMock.class, new GDriveUploadResponseTest_Fail());

        String response = LM_GoogleDriveAPIController.uploadFile(file, filename, filetype, folderId);

        System.assertEquals('Error : {"id": "0000000001"}', response);
    }

    @isTest
    static void getLinkFromFileTest(){

        ResponseGetLinkFromFile_Success mockResponse = new ResponseGetLinkFromFile_Success();
        Test.setMock(HttpCalloutMock.class, mockResponse);
        mockResponse.fileId = '123456789';

        String response = LM_GoogleDriveAPIController.getLinkFromFile('123456789');
        System.assertEquals('http://myGDriveLink.com/file.pdf', response);
    }

    @isTest
    static void getGDriveParentIdTest(){

        ResponseGetGDriveFolderId_Success mockResponse = new ResponseGetGDriveFolderId_Success();
        Test.setMock(HttpCalloutMock.class, mockResponse);
        mockResponse.parentFolder = 'my_folder';

        String response = LM_GoogleDriveAPIController.getGDriveParentId('my_folder');
        System.assertEquals('1111', response);
    }

    @isTest
    static void getGDriveFolderIdTest(){

        ResponseGetGDriveFolderId_Success mockResponse = new ResponseGetGDriveFolderId_Success();
        mockResponse.parentFolder = 'my_parent_folder';
        mockResponse.folderName = 'my_folder';

        Test.setMock(HttpCalloutMock.class, mockResponse);
        String response = LM_GoogleDriveAPIController.getGDriveFolderId('my_folder','my_parent_folder');

        System.assertEquals('1111', response);

    }

    @isTest
    static void errorTestGetFolderId(){
        try{
            Test.setMock(HttpCalloutMock.class, new ErrorResponse());
            LM_GoogleDriveAPIController.getGDriveFolderId('my_folder','my_parent_folder');
        }
        catch(Exception e){
            System.assert(true, 'Exception was not thrown when it was supposed to.');
        }
    }

    @isTest
    static void errorTestGetLinkFromFile(){
        try{
            Test.setMock(HttpCalloutMock.class, new ErrorResponse());
            LM_GoogleDriveAPIController.getLinkFromFile('123456789');
        }
        catch(Exception e){
            System.assert(true, 'Exception was not thrown when it was supposed to.');
        }
    }

    @isTest
    static void errorTestUploadFile(){
        try{
            Test.setMock(HttpCalloutMock.class, new ErrorResponse());
            LM_GoogleDriveAPIController.uploadFile(file, filename, filetype, folderId);
        }
        catch(Exception e){
            System.assert(true, 'Exception was not thrown when it was supposed to.');
        }
    }

    @isTest
    static void removeFileTest(){
        Test.setMock(HttpCalloutMock.class, new ResponseRemoveFile_Success());
        String fileId = '12345';
        String response = LM_GoogleDriveAPIController.removeFile(fileId);
        System.assertEquals('Success', response);
    }
}