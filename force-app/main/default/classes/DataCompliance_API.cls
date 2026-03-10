/**
 * @description       : API to Anonymize user data Info
 * @author            : miguel.lopes
 * @group             : Data Compliance Integration
 * @last modified on  : 02-18-2025
 * @last modified by  : miguel.lopes
**/
@RestResource(urlMapping='/anonymize.user/*') // To define the API End Point
global with sharing class DataCompliance_API {

    /**
     * END Point: /services/apexrest/anonymize.user/mdmId
     * BODY:
     *  {
     *   "mdmId": "" // Por agora não enviamos nada no body
     *  }
     */
    @HttpPost
    global static void anonymizeUser(String mdmId) {
        RestRequest request = RestContext.request;
        RestResponse response = RestContext.response;
        String[] uriParts = request.requestURI.split('/');
        String lastSegment = uriParts[uriParts.size() - 1]; // Get the last segment of the URI

        try {

            if(lastSegment == 'anonymize.user'){
                response.statusCode = 400; // 400 Bad Request
                response.responseBody = Blob.valueOf(JSON.serialize(
                    DataCompliance_API_Handler.setResBody(new List<Map<String,String>>() , 'Bad Request  - MISSING MDM_ID IN ENDPOINT',  String.valueOf(request.requestURI), lastSegment, false, response.statusCode))
                );
                return;
            }

            List<Map<String,String>> records = DataCompliance_API_Handler.anonymizeInfo(lastSegment);
            List<Map<String,String>> leads = DataCompliance_API_Handler.updateLeadRecord(lastSegment);
            records.addAll(leads);
            Boolean openActivity = !records.isEmpty() && records[0].get('openActivity') != null ? true : false;

            if (records.isEmpty() && leads.isEmpty()) {
                response.statusCode = 200;
                response.responseBody = Blob.valueOf(JSON.serialize(
                    DataCompliance_API_Handler.setResBody(records, 'Valid Request - MDM_ID DOESN´T EXIST IN SALESFORCE', String.valueOf(request.requestURI), lastSegment, openActivity, response.statusCode))
                );
                return;
            }

            response.statusCode = openActivity == true? 400 : 200;
            String statusMessage = openActivity == true? 'Valid Request - MDM_ID NOT UPDATED' : 'Valid Request - MDM_ID UPDATED';
            response.responseBody = Blob.valueOf(JSON.serialize(
                DataCompliance_API_Handler.setResBody(records, statusMessage, String.valueOf(request.requestURI), lastSegment, openActivity, response.statusCode))
            );
        } catch (Exception e) {
            response.statusCode = 500;
            response.responseBody = Blob.valueOf(JSON.serialize(
                DataCompliance_API_Handler.setResBody(new List<Map<String,String>>(), '"error": "' + String.escapeSingleQuotes(e.getMessage()) + '"', String.valueOf(request.requestURI), lastSegment, false, response.statusCode)
            ));
        }
    }
}