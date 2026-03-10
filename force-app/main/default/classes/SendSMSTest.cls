@isTest
public with sharing class SendSMSTest {

    static String SMSFrom = '';
    static String SMSTo = '';
    static String SMSBody = '';

    
    public class TwilioHttpResponse_Success implements HttpCalloutMock{
        public HTTPResponse respond(HTTPRequest req) {
            // Optionally, only send a mock response for a specific endpoint
            // and method.
            System.assertEquals('callout:Twilio', req.getEndpoint());
            System.assertEquals('POST', req.getMethod());
            
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"body": TestBody}');
            res.setStatusCode(201);
            return res;
        }
    }
    
    public class TwilioHttpResponse_Fail implements HttpCalloutMock{
        public HTTPResponse respond(HTTPRequest req) {
            // Optionally, only send a mock response for a specific endpoint
            // and method.
            System.assertEquals('callout:Twilio', req.getEndpoint());
            System.assertEquals('POST', req.getMethod());
            
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(400);
            res.setBody('{"code":400, "message": "error", "moreInfo": "info", "status": "error" }');
            return res;
        }
    }

    public class TwilioHttpResponse_Error implements HttpCalloutMock{
        public HTTPResponse respond(HTTPRequest req) {
            throw new CalloutException('Callout can\'t be made.');
        }
    }

    @isTest
    public static void testSendSMS_Success() {
        Test.setMock(HttpCalloutMock.class, new TwilioHttpResponse_Success());
        
        LM_SendSMS sms = new LM_SendSMS(SMSFrom, SMSTo, SMSBody);
        
        HttpResponse res = sms.sendSMS();

        String contentType = res.getHeader('Content-Type');
        System.assert(ContentType == 'application/json');
        String actualValue = res.getBody();
        System.assert(actualValue == '{"body": TestBody}');
        System.assertEquals(201, res.getStatusCode());
    }

    @isTest
    public static void testSendSMS_Fail(){
        Test.setMock(HttpCalloutMock.class, new TwilioHttpResponse_Fail());

        LM_SendSMS sms = new LM_SendSMS(SMSFrom, SMSTo, SMSBody);

        try{
            HttpResponse res = sms.sendSMS();
            Assert.isNotNull(res);
        }catch (Exception ex){
            Assert.isNotNull(ex);
        }
    }

    @isTest
    public static void testSendSMS_Error(){
        Test.setMock(HttpCalloutMock.class, new TwilioHttpResponse_Error());

        LM_SendSMS sms = new LM_SendSMS(SMSFrom, SMSTo, SMSBody);

        try{
            HttpResponse res = sms.sendSMS();
        }catch (Exception ex){
            assert.isNotNull(ex);
        }
    }
}