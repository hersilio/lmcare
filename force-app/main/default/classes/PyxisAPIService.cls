/**
 * @description       : Pyxis Webservice/API Class
 * @author            : miguel.lopes
 * @group             :
 * @create date on    : 2025-10-14 17:47:20
 * @last modified by  : Hersilio Belini de Oliveira
 **/
// @RestResource(urlMapping='/pyxis/order')
@RestResource(urlMapping='/pyxis/*')
global with sharing class PyxisAPIService extends IntegrationRestServiceBase {

    public static List <String> VALID_ENDPOINT = new List <String>{ 'quotes', 'product-orders', 'sale-notes' };

    @HttpPost
    global static void setNewRequest(){
        new PyxisAPIService().processRequest();
    }

    protected override List<String> getValidEndpoints(){
        return VALID_ENDPOINT;
    }

    protected override IntegrationLogHandler.IntegrationLogContext buildLogContext(String requestType, String requestBody){
        PyxisIntegrationLogContext ctx = new PyxisIntegrationLogContext(requestType);
        ctx.requestBody = requestBody;
        return ctx;
    }

    protected override IntegrationRestServiceBase.IntegrationResponse dispatch(String requestBody, String requestType){
        PyxisAPIServiceHandler.PyxisResponderWrapper payloadResponse = PyxisAPIServiceHandler.handleRequestPyxis(requestBody, requestType);

        if(payloadResponse == null){
            return null;
        }

        Blob body = Blob.valueOf(JSON.serialize(payloadResponse));
        String errorMessage = payloadResponse.error != null ? payloadResponse.error.errorMessage : null;

        return new IntegrationRestServiceBase.IntegrationResponse(payloadResponse.statusCode, body, payloadResponse.recordsCreate, errorMessage);
    }

    public class PyxisIntegrationLogContext extends IntegrationLogHandler.IntegrationLogContext{
        public PyxisIntegrationLogContext(String requestType){
            super();
            this.integrationKey = requestType;
            this.sourceSystem = 'Pyxis';
            this.direction = 'Inbound';
        }
    }
}