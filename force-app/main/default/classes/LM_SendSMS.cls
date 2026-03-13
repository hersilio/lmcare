public class LM_SendSMS implements Queueable, Database.AllowsCallouts{
    
    String SMSFrom;
    String SMSTo;
    String SMSBody;
    
    public LM_SendSMS( String SMSFrom, String SMSTo, String SMSBody){
        this.SMSFrom = SMSFrom;
        this.SMSTo = SMSTo;
        this.SMSBody = SMSBody.trim(); // Remove leading/trailing whitespace
        this.SMSBody = GSMUtils.toGSM7(this.SMSBody); // Ensure SMS body is GSM-7 compliant
        if (this.SMSBody.length() > 160){
            System.debug('SMS Body length exceeds 160 characters. This message will be split into multiple parts.');
        }
    }
    
    public HttpResponse sendSMS(){
        System.debug('Sending SMS from ' + this.SMSFrom + ' to ' + this.SMSTo + ': ' + this.SMSBody);
        
        HttpRequest req = new HttpRequest();
        Http http = new Http();
        HTTPResponse res = new HTTPResponse();
        
        req.setEndpoint('callout:Twilio');
        req.setMethod('POST');
        req.setBody('To=' + EncodingUtil.urlEncode(this.SMSTo, 'UTF-8') + '&From=' + EncodingUtil.urlEncode(this.SMSFrom,'UTF-8') + '&Body=' + this.SMSBody);
        try{
            res = http.send(req);
        	System.debug(res.getBody());
        }catch(Exception ex){
            throw ex;
        }
        
        if(res.getStatusCode() == 201){
            return res;
        } else{
            errorWrapper er = (errorWrapper)json.deserialize(res.getBody(), errorWrapper.class);
            throw newMessageException('Error : ' + er.message);
        }	
    }
 
    public class errorWrapper{
       String code;
       String message;
       String moreInfo;
       String status; 
    }
    
    public void execute(QueueableContext context){
        this.sendSMS();
    }    
 
    private AuraHandledException newMessageException(String message) {
        AuraHandledException e = new AuraHandledException(message);
        e.setMessage(message);
        return e;
    }
}