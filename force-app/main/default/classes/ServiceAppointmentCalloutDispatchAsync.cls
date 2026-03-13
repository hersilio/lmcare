/**
 * @description       : Description
 * @author            : miguel.lopes
 * @group             :
 * @create date on    : 2026-02-05 13:19:42
 * @last modified by  : miguel.lopes
 **/
public with sharing class ServiceAppointmentCalloutDispatchAsync implements Queueable, Database.AllowsCallouts {
    
    public Map<String, Object> payloadMap;
    
    public ServiceAppointmentCalloutDispatchAsync(Map<String, Object> payloadMap){
        this.payloadMap = payloadMap;
    }
    
    public void execute(QueueableContext context){
        List<String> idsToUpdate = new List<String>();
        List<ServiceAppointmentResult> results = new List<ServiceAppointmentResult>();
        for(String payloadKey : payloadMap.keySet()){
            HttpRequest req = new HttpRequest();
            String payloadString = JSON.serialize(payloadMap.get(payloadKey));
            req.setMethod('POST');
            req.setEndpoint('callout:ACL_ADEO_SA');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('User-Agent', 'insomnia/12.0.0');
            req.setBody(payloadString);

            Http http = new Http();
            HttpResponse res;
            try {   
                res = http.send(req);

                if (res.getStatusCode() == 200) {
                    ServiceAppointmentResult result = new ServiceAppointmentResult(res.getStatusCode(), res.getBody(), null, null, payloadString);
                    results.add(result);
                    idsToUpdate.add(payloadKey);
                }
                else{
                    throw new IntegrationRestServiceBase.IntegrationException(res.getStatusCode() + ' - BODY: ' + res.getBody());
                }
            }
            catch (IntegrationRestServiceBase.IntegrationException e) {
                ServiceAppointmentResult result = new ServiceAppointmentResult(res.getStatusCode(), res.getBody(), null, e.getMessage(), payloadString);
                results.add(result);
            }
            catch (Exception e) {
                ServiceAppointmentResult result = new ServiceAppointmentResult(res.getStatusCode(), res.getBody(), null, e.getMessage(), payloadString);
                results.add(result);
            }
        }
        ServiceAppointmentResultWrapper finalResultWrapper = new ServiceAppointmentResultWrapper(results);
        setCustomLogContext(finalResultWrapper);
        updateServiceAppointment(idsToUpdate);
    }
    
    /**
     * @description : TO UPADATE RECORDS THAT GOT SENT TO ADEO
     * param        : saToUpdate: List of Service Appointments Ids
     **/
    public static void updateServiceAppointment(List<String> saToUpdate){
        ServiceAppointmentTriggerHelper.runTrigger = false;
        List<ServiceAppointment> servAppoints = [SELECT Sent_to_ADEO__c FROM ServiceAppointment WHERE Id IN : saToUpdate];
        for (ServiceAppointment serApp : servAppoints) {
            serApp.Sent_to_ADEO__c = true;
        }
        update servAppoints;
        ServiceAppointmentTriggerHelper.runTrigger = true;
    }
    
    //------------------------------------------------------------------------------------------------------------------------------------
    // ***************************************************** DISPATCH & LOG METHODS ************************************************
    //------------------------------------------------------------------------------------------------------------------------------------
    
    public static void setCustomLogContext(ServiceAppointmentResultWrapper finalResultWrapper){
        
        if(finalResultWrapper == null || finalResultWrapper.results == null){return;}

        List<IntegrationLogHandler.IntegrationLogWrapper> logs = new List<IntegrationLogHandler.IntegrationLogWrapper>();
        
        for(ServiceAppointmentResult singleResult : finalResultWrapper.results) {
            
            IntegrationLogHandler.IntegrationLogWrapper log = new IntegrationLogHandler.IntegrationLogWrapper();
            
            log.integrationKey = 'ServiceAppointment';
            log.requestBody = 'RESPONSE_BODY: ' + JSON.serialize(singleResult.responseBody) + '\n\nPAYLOAD: ' + singleResult.payloadSent;
            log.httpMethod = 'POST';
            log.endpoint = 'adeo.cloud/appointment';
            log.direction = 'Outbound';
            log.sourceSystem = 'Salesforce';
            log.targetSystem = 'ADEO';
            log.startDateTime = System.now();
            log.endDateTime = System.now();
            log.durationMs = 0;
            log.httpStatusCode = singleResult.statusCode;
            
            if(singleResult.statusCode >= 200 && singleResult.statusCode < 300){
                log.status = 'Success';
            }
            else{
                log.status = 'Error';
                log.errorMessage = singleResult.errorMessage;
            }
            logs.add(log);
        }
        
        if(!logs.isEmpty()){
            IntegrationLogHandler.createIntegrationLog(logs);
        }
    }
        
    public class ServiceAppointmentResult{
        public Integer statusCode;
        public Object responseBody;
        public List<SObject> recordsCreate;
        public String errorMessage;
        public String payloadSent;
        
        public ServiceAppointmentResult(Integer statusCode, Object responseBody, List<SObject> recordsCreate, String errorMessage, String payloadSent){
            this.statusCode = statusCode;
            this.responseBody = responseBody;
            this.recordsCreate = recordsCreate;
            this.errorMessage = errorMessage;
            this.payloadSent = payloadSent;
        }
    }
    
    public class ServiceAppointmentResultWrapper{
        public List<ServiceAppointmentResult> results;
        public ServiceAppointmentResultWrapper(List<ServiceAppointmentResult> results){
            this.results = results;
        }
    }
}