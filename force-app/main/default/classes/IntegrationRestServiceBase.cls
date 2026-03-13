/**
 * @description       : Base class for REST integrations with logging and common handling
 **/
public abstract without sharing class IntegrationRestServiceBase {

    public class IntegrationException extends Exception {}
    protected abstract List<String> getValidEndpoints();
    protected abstract IntegrationLogHandler.IntegrationLogContext buildLogContext(String requestType, String requestBody);
    protected virtual String resolveRequestType(RestRequest request){
        List<String> parts = new List<String>();
        if(request != null && request.requestURI != null){
            parts = request.requestURI.split('/');
        }

        for(Integer i = parts.size() - 1; i >= 0; i--){
            if(!String.isBlank(parts[i])){
                return parts[i];
            }
        }

        return '';
    }
    protected abstract IntegrationResponse dispatch(String requestBody, String requestType);

    public void processRequest(){
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        String requestType = resolveRequestType(request);
        String body = request.requestBody != null ? request.requestBody.toString() : '';
        IntegrationLogHandler.IntegrationLogContext logContext = buildLogContext(requestType, body);

        if(logContext != null){
            if(logContext.httpMethod == null && request != null){
                logContext.httpMethod = request.httpMethod;
            }
            if(logContext.endpoint == null && request != null){
                logContext.endpoint = request.requestURI;
            }
        }

        try{
            if(!getValidEndpoints().contains(requestType)){
                response.responseBody = Blob.valueOf(JSON.serialize(
                    new ErrorWrapper('Invalid endpoint: ' + requestType, null)
                ));
                response.statusCode = 404;
                logContext.markError(new IntegrationException('Invalid endpoint: ' + requestType), response.statusCode);
            } else {
                IntegrationResponse integrationResponse = dispatch(body, requestType);

                if(integrationResponse != null){
                    response.statusCode = integrationResponse.statusCode;
                    response.responseBody = integrationResponse.responseBody;

                    if(integrationResponse.statusCode >= 200 && integrationResponse.statusCode < 300){
                        if(integrationResponse.records != null && !integrationResponse.records.isEmpty()){
                            SObject firstRecord = integrationResponse.records[0];
                            if(firstRecord != null){
                                logContext.targetRecordId = (String)firstRecord.get('Id');
                                logContext.targetSObject = firstRecord.getSObjectType().getDescribe().getName();
                            }
                        }
                        logContext.markSuccess(logContext.targetRecordId, integrationResponse.statusCode);
                    }
                    else{
                        logContext.markError(
                            new IntegrationException(
                                integrationResponse.errorMessage != null ? integrationResponse.errorMessage : 'Integration returned error'),
                                integrationResponse.statusCode
                            );
                    }
                } else {
                    response.statusCode = 500;
                    response.responseBody = Blob.valueOf(JSON.serialize(
                        new ErrorWrapper('Unexpected null response', 'Handler returned null IntegrationResponse')
                    ));
                    logContext.markError(new IntegrationException('Unexpected null response from handler'), 500);
                }
            }
        } catch (Exception e) {
            response.statusCode = 500;
            response.responseBody = Blob.valueOf(JSON.serialize(new ErrorWrapper(e.getMessage(), e.getStackTraceString())));
            logContext.markError(e, 500);
        } finally {
            if(logContext.endDateTime == null){
                logContext.endDateTime = System.now();

                if(logContext.startDateTime != null){
                    logContext.durationMs = (Integer) (logContext.endDateTime.getTime() - logContext.startDateTime.getTime());
                }
            }

            IntegrationLogHandler.createIntegrationLog(logContext);
        }
    }

    public class IntegrationResponse{
        public Integer statusCode;
        public Blob responseBody;
        public List<SObject> records;
        public String errorMessage;

        public IntegrationResponse(Integer statusCode, Blob responseBody, List<SObject> records, String errorMessage){
            this.statusCode = statusCode;
            this.responseBody = responseBody;
            this.records = records;
            this.errorMessage = errorMessage;
        }
    }

    public class ErrorWrapper{
        public String errorMessage;
        public String detailAction;

        public ErrorWrapper(String errorMessage, String detailAction){
            this.errorMessage = errorMessage;
            this.detailAction = detailAction;
        }
    }

    // THIS WILL BE EXECUTED EVERY DAY TO PREVENT ORG FROM BEING OVERLOADED
    public class IntegrationLogDelete implements Schedulable{
        public void execute(SchedulableContext sc) {
            Database.executeBatch(new IntegrationLogDeleteBatch(), 200);
        }
    }
}