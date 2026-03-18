/**
 * @description       : Description
 * @author            : miguel.lopes
 * @group             :
 * @create date on    : 2026-02-02 11:36:16
 * @last modified by  : miguel.lopes
 **/
public with sharing class ServiceAppointmentCalloutHandler {

    private static Map <String, String> STATUS_MAP = new Map<String, String>{ // SCHEDULED, CANCELED, DONE, NO_SHOW
        'None' => '',
        'Scheduled' => 'SCHEDULED', // Need to set SO_SHOW
        'Canceled' => 'CANCELED',
        'Completed' => 'DONE',
        'Dispatched' => 'SCHEDULED',
        'In Progress' => 'SCHEDULED',
        'Cannot Complete' => 'CANCELED',
        'Scheduled - Updated' => 'SCHEDULED'
    };
    
    public static void builtHttpRequest(Set<Id> appointmentIds) {
        try {
            ACL_ADEO_API_Callout_Expecifications__mdt saSetting = [ SELECT base_query__c, field_names__c, where_query__c 
                                                                FROM ACL_ADEO_API_Callout_Expecifications__mdt 
                                                                WHERE object_type__c = 'ServiceAppointment' 
                                                                LIMIT 1];
            Map<String, String> fieldMap = bodyPayload(saSetting.field_names__c);
            List<ServiceAppointment> serviceApps = Database.query(saSetting.base_query__c + ' ' + saSetting.where_query__c + ' AND Id IN : appointmentIds');

            if(serviceApps.isEmpty()){System.debug('NO APPOINTMENTS TO SEND TO ADEO');return;}

            Map<String, Object> payloadMaps = new Map<String, Object>();
            for(ServiceAppointment sa : serviceApps){
                SObject lead = sa.getSObject('Lead__r');
                Map<String, String> saWrapper = new Map<String, String>();
                for(String key : fieldMap.keySet()){
                    // LEAD FIELD
                    if(fieldMap.get(key).startsWith('Lead__r.')){
                        String leadField = fieldMap.get(key).replace('Lead__r.', '');
                        saWrapper.put(key, String.valueOf(lead.get(leadField)));
                        continue;
                    }
                    // DATE FIELD
                    if(key == 'date'){
                        Datetime schedStart = (Datetime) sa.get('SchedStartTime');
                        saWrapper.put(key,schedStart.format('yyyy-MM-dd\'T\'HH:mm:ss'));
                        continue;
                    }
                    // STATUS FIELD - TO MATCH ADEO EXPECTED VALUE
                    if(key == 'status'){
                        saWrapper.put(key, STATUS_MAP.get(String.valueOf(sa.get('Status'))));
                        continue;
                    }
                    // DEFAULT VALUE'S
                    if(fieldMap.get(key).startsWith('"')){
                        saWrapper.put(key, fieldMap.get(key).remove('"'));
                        continue;
                    }
                    // SERVICE APPOINTMENT FIELD
                    saWrapper.put(key, String.valueOf(sa.get(fieldMap.get(key))));
                }
                payloadMaps.put(sa.Id, saWrapper);
            }
            if(!payloadMaps.isEmpty()){
                System.enqueueJob(new ServiceAppointmentCalloutDispatchAsync(payloadMaps));
            }
        } catch (Exception e) {
            System.debug('ERROR IN SERVICE APPOINTMENT CALLOUT HANDLER: ' + e.getMessage());
        }
    }

    /**
     * @description : SETS THE BODY PAYLOAD MAP BASED ON THE FIELD NAMES FROM METADATA
     * param        : fields - STRING IN THE FORMAT 'key1:field1; key2:field2; key3:"defaultValue"; ...'
     * return       : Map<String, String> - The payload map structer
     **/
    public static Map<String, String> bodyPayload(String fields){
        List<String> fieldList = fields.split('; ');
        Map<String, String> saWrapper = new Map<String, String>();
        for(String field : fieldList){
            String fieldName = field.split(':')[0];
            String fieldValue = field.split(':')[1];
            saWrapper.put(fieldName, fieldValue);
        }
        return saWrapper;
    }
}