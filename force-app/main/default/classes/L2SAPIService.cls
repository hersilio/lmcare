/**
 * @description       : L2S Lead REST API
 * @author            :
 * @group             :
 * @last modified on  : 2026-01-20
 * @last modified by  : Hersilio Belini de Oliveira
 **/
@RestResource(urlMapping='/leads/v1/*')
global with sharing class L2SAPIService extends IntegrationRestServiceBase {

    public static List<String> VALID_ENDPOINT = new List<String>{ 'lead' };

    @HttpPost
    global static void createLead(){
        new L2SAPIService().processRequest();
    }

    protected override List<String> getValidEndpoints(){
        return VALID_ENDPOINT;
    }

    protected override IntegrationLogHandler.IntegrationLogContext buildLogContext(String requestType, String requestBody){
        L2SIntegrationLogContext ctx = new L2SIntegrationLogContext(requestType);
        ctx.requestBody = requestBody;
        return ctx;
    }

    protected override IntegrationRestServiceBase.IntegrationResponse dispatch(String requestBody, String requestType){
        L2SAPIServiceHandler.L2SIntegrationResult result = L2SAPIServiceHandler.handleRequest(requestBody, requestType);

        if(result == null){
            return null;
        }

        Blob body = Blob.valueOf(JSON.serialize(result.responseBody));
        return new IntegrationRestServiceBase.IntegrationResponse(result.statusCode, body, result.recordsCreate, result.errorMessage);
    }

    public class L2SIntegrationLogContext extends IntegrationLogHandler.IntegrationLogContext{
        public L2SIntegrationLogContext(String requestType){
            super();
            this.integrationKey = requestType;
            this.sourceSystem = 'L2Service';
            this.direction = 'Inbound';
        }
    }
}