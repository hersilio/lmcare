/**
 * @description       : To Handle all the Data Complience methods
 * @author            : miguel.lopes
 * @group             :
 * @last modified on  : 02-18-2025
 * @last modified by  : miguel.lopes
**/
public with sharing class DataCompliance_API_Handler {

    public static Map <String, String> FIELDS =  new Map <String, String>{
        'account' => 'Id, Numero_de_Conta__c, IsPersonAccount, Name, FirstName, LastName, NIF__c, PersonEmail, Record_Type_API_Name__c',
        'contact' => 'Name, MailingAddress, Email, Phone, MobilePhone',
        'opportunity' => 'Name',
        'lead' => 'Name',
        'serviceAppointment' => 'Phone, Email'
    };

    public static Map <String, String> FIELD_FILTER =  new Map <String, String>{
        'account' => 'Numero_de_Conta__c',
        'contact' => 'AccountId',
        'opportunity' => 'AccountId',
        'lead' => 'Numero_de_Conta_na_lead__c',
        'serviceAppointment' => 'ParentRecordId'
    };

    public static Map<String, String> CLAUSE = new Map<String,String>{
        'account'=> 'AND IsPersonAccount = TRUE',
        'contact' => '',
        'opportunity' => '',
        'lead' => '',
        'serviceAppointment' => ''
    };

    // public static Set<String> BUSINESS_ACCOUNT_SKIPPED_FIELDS = new Set<String>{'FirstName', 'LastName'};
    // public static Set<String> PERSON_ACCOUNT_SKIPPED_FIELDS = new Set<String>{'Name'};
    public static Set<String> RANDOMIZED_FIELDS = new Set<String>{'Phone', 'Name', 'LastName'};

    public static list <String> saStatus = new List <String>{'Scheduled', 'Dispatched', 'In Progress', 'Cannot Complete', 'Scheduled - Updated'};
    public static list <String> oppStatus = new List <String>{'Pedido de Proposta', 'Proposta Enviada', 'Em decisão', 'Retificação', 'Aguarda Fecho'};

    public static Map<String,Object> setResBody(List<Map<String,String>> records, String message, String uri, String mdmId, Boolean openActivity, Integer statusCode){
        if(openActivity){
            Map<String,Object> responseBody = new Map<String,Object>{
                'openActivity' => 'true',
                'timeStamp' => String.valueOf(System.now()),
                'recordsUpdated' => 0,
                'endPoint' => uri,
                'mdmId' => mdmId,
                'status' => 'Not Updated - CLIENT WITH OPEN ACTIVITY'
            };
            createLog(responseBody, statusCode, message);
            return responseBody;
        }
        Map<String,Object> responseBody = new Map<String,Object>{
                'records' => records,
                'timeStamp' => String.valueOf(System.now()),
                'recordsUpdated' => records.size(),
                'endPoint' => uri,
                'mdmId' => mdmId,
                'status' => message
            };
        createLog(responseBody, statusCode, message);
        return responseBody;
    }

    public static List<Map<String,String>> anonymizeInfo(String mdmId) {
        try {
            // Clientes com atividades (Opportunities & Serive Appointments) abertas não devem ser ainda ononimizados
            if(String.valueOf(hasOpenActivity('account', mdmId)) == 'True'){
                return new List<Map<String,String>>{
                    new Map<String,String>{
                        'openActivity' => 'true'
                    }
                };
            }

            String queryString =  setquery('account', mdmId); // To query all Accounts with this mdmID: PS - MDM_Id is is unique
            System.debug('queryString: ' + queryString);
            List<SObject> records = Database.query(queryString);

            if(records.isEmpty()){ return new List<Map<String, String>>(); }

            String accountId = String.valueOf(records[0].get('Id'));

            List<Map<String, String>> mergedList = new List<Map<String, String>>();

            //Check if Account as open Opportunity and Service Appointment
            List<Map<String,String>> accounts = updateAccountRecord(records);
            List<Map<String,String>> contacts = updateContactRecord(accountId);
            List<Map<String,String>> opps = updateOpportunityRecord(accountId);

            mergedList.addAll(accounts);
            mergedList.addAll(contacts);
            mergedList.addAll(opps);

            return mergedList;

        } catch (Exception e) {
            throw e;
        }
    }


    /**
     * Set query to be build dynamical
     */
    public static String setquery(String objectType, String id){
        return  'SELECT ' + FIELDS.get(objectType) + ' FROM ' + objectType +
                ' WHERE ' + FIELD_FILTER.get(objectType) + ' = \'' + String.escapeSingleQuotes(String.valueOf(id)) + '\' ' + CLAUSE.get(objectType);
    }

    public static Boolean hasOpenActivity(String objectType, String id){
        // if objectType =  accout  >   query (Opportunity and Service Appointment)
        //               =  lead    >   query (Service Appointment)
        Boolean openActivity = false;

        if(objectType == 'account'){  
            List <ServiceAppointment> sas = [SELECT Id FROM ServiceAppointment WHERE Account.Numero_de_Conta__c =: id AND Status IN : saStatus];
            List <Opportunity> opps = [SELECT Id FROM Opportunity WHERE Account.Numero_de_Conta__c =:id AND StageName  IN : oppStatus];
            if(sas.isEmpty() && opps.isEmpty()){return null;}
            openActivity = !opps.isEmpty() || !sas.isEmpty() ? true : false;
        }
        if(objectType == 'lead'){
            List<Lead> leads = [SELECT Id FROM Lead WHERE Numero_de_Conta_na_lead__c =: id];
            List <ServiceAppointment> sas = [SELECT Id FROM ServiceAppointment WHERE Status IN : saStatus AND ParentRecordId IN : leads];
            if(leads.isEmpty() || sas.isEmpty()){return null;}
            openActivity =  !sas.isEmpty() ? true : false;
        }
        return openActivity;
    }

    /**
     * To update the Account record
     */
    public static List<Map<String,String>> updateAccountRecord(List<SObject> records){ // melhor usar Account dir
        List<SObject> recordsToUpdate = new List <SObject>();
        List<Map<String,String>> toReturn = addRecordToPayload(records);
        List<Map<String,String>> sa = updateServiceAppointment(records);
        toReturn.addAll(sa);

        Data_Compliance_Objects__mdt accountFields = [SELECT fields__c FROM Data_Compliance_Objects__mdt WHERE objectType__c = 'account' LIMIT 1];
        Map<String, Object> fieldMapping = (Map<String, Object>)JSON.deserializeUntyped(accountFields.fields__c);

        for (SObject rec : records) {
            Boolean isPersonAccount = (Boolean) rec.get('IsPersonAccount');
            if(!isPersonAccount){break;} // If is not person Account, we should split the logic to update the Account record

            for (String fieldName : fieldMapping.keySet()) {
                // if(!isPersonAccount && BUSINESS_ACCOUNT_SKIPPED_FIELDS.contains(fieldName) || // Company Account future feature
                //     (isPersonAccount && PERSON_ACCOUNT_SKIPPED_FIELDS.contains(fieldName))){
                //     continue;
                // }
                Object fieldValue = fieldMapping.get(fieldName);
                rec.put(fieldName, RANDOMIZED_FIELDS.contains(fieldName)
                        ? fieldValue + ' ' + String.valueOf(Crypto.getRandomLong())
                        : fieldValue);
            }
            recordsToUpdate.add(rec);
        }
        if(!recordsToUpdate.isEmpty()){
            update recordsToUpdate;
        }
        return toReturn;
    }

    /**
     * To update the Contact records
     */
    public static List<Map<String,String>> updateContactRecord(String accountId){
        String query = setquery('contact', accountId);
        List<SObject> toUpdate = new List<SObject>();
        List <SObject> contacts = Database.query(query);

        if(contacts.isEmpty()){ return new List<Map<String,String>>();}
        List<Map<String,String>> toReturn = addRecordToPayload(contacts);

        Data_Compliance_Objects__mdt accountFields = [SELECT fields__c FROM Data_Compliance_Objects__mdt WHERE objectType__c = 'contact' LIMIT 1];
        Map<String, Object> fieldMapping = (Map<String, Object>)JSON.deserializeUntyped(accountFields.fields__c);
        for (SObject rec : contacts) {
            for (String fieldName : fieldMapping.keySet()) {
                if(fieldName == 'Phone'){
                    rec.put(fieldName, fieldMapping.get(fieldName)+' '+String.valueOf(Crypto.getRandomLong()));
                }else{
                    rec.put(fieldName, fieldMapping.get(fieldName));
                }
            }
            toUpdate.add(rec);
        }
        if(!toUpdate.isEmpty()){
            update toUpdate;
        }
        return toReturn;
    }

    /**
     * To update the Opportunity records
     */
    public static List<Map<String,String>> updateOpportunityRecord(String accountId){
        String query = setquery('opportunity', accountId);
        List<SObject> toUpdate = new List<SObject>();
        List<SObject> opps = Database.query(query);

        if(opps.isEmpty()){ return new List<Map<String,String>>();}

        List<Map<String,String>> toReturn = addRecordToPayload(opps);

        Data_Compliance_Objects__mdt accountFields = [SELECT fields__c FROM Data_Compliance_Objects__mdt WHERE objectType__c = 'opp' LIMIT 1];
        Map<String, Object> fieldMapping = (Map<String, Object>)JSON.deserializeUntyped(accountFields.fields__c);
        for (SObject rec : opps) {
            for (String fieldName : fieldMapping.keySet()) {
                rec.put(fieldName, fieldMapping.get(fieldName));
            }
            toUpdate.add(rec);
        }
        if(!toUpdate.isEmpty()){
            update toUpdate;
        }
        return toReturn;
    }

    /**
     * To update the Lead record
     */
    public static List<Map<String,String>> updateLeadRecord(String mdmId){
        if(String.valueOf(hasOpenActivity('lead', mdmId)) == 'True'){
            return new List<Map<String,String>>{
                new Map<String,String>{
                    'openActivity' => 'true'
                }
            };
        }

        String query = setquery('lead', mdmId);
        List<SObject> leads = Database.query(query);
        List<Map<String,String>> sa = updateServiceAppointment(leads);
        List<SObject> toUpdate = new List<SObject>();
        List<Map<String,String>> toReturn = addRecordToPayload(leads);
        toReturn.addAll(sa);

        Data_Compliance_Objects__mdt accountFields = [SELECT fields__c FROM Data_Compliance_Objects__mdt WHERE objectType__c = 'lead' LIMIT 1];
        Map<String, Object> fieldMapping = (Map<String, Object>)JSON.deserializeUntyped(accountFields.fields__c);
        for (SObject rec : leads) {
            for (String fieldName : fieldMapping.keySet()) {
                if(fieldName == 'Phone' || fieldName == 'Email'){
                    rec.put(fieldName, fieldMapping.get(fieldName)+'-'+String.valueOf(Crypto.getRandomLong()));
                }else {
                    rec.put(fieldName, fieldMapping.get(fieldName));  
                }              
            }
            toUpdate.add(rec);
        }
        if(!toUpdate.isEmpty()){
            // DataComplianceBatchUpdate batchJob = new DataComplianceBatchUpdate(toUpdate);
            // Id jobId = Database.executeBatch(batchJob, 200); // Adjust batch size as needed
            update toUpdate;
        }
        return toReturn;
    }

    /**
     * ATENTION TO CONFIRM THIS DEV - NEED OF Data in sandbox
     * Service Appointment parent record - Lookup(Account, Opportunity, Lead)
     */
    public static List<Map<String,String>> updateServiceAppointment(List<SObject> parentIds){
        List<SObject> serviceApp = [SELECT Phone, Email FROM serviceAppointment WHERE ParentRecordId IN : parentIds];
        List<SObject> toUpdate = new List<SObject>();
        List<Map<String,String>> toReturn = addRecordToPayload(serviceApp);

        Data_Compliance_Objects__mdt accountFields = [SELECT fields__c FROM Data_Compliance_Objects__mdt WHERE objectType__c = 'sa' LIMIT 1];
        Map<String, Object> fieldMapping = (Map<String, Object>)JSON.deserializeUntyped(accountFields.fields__c);
        for(SObject rec : serviceApp){
            for (String fieldName : fieldMapping.keySet()) {
                rec.put(fieldName, fieldMapping.get(fieldName));
            }
            toUpdate.add(rec);
        }
        update toUpdate;
        return toReturn;
    }

    public static List<Map<String,String>> addRecordToPayload(List<SObject> records){
        List<Map<String,String>> toReturn = new List<Map<String,String>>(); // usar melhor um wrapper - mas da quase na mesma
        for (SObject rec : records) {
            toReturn.add(new Map<String,String>{
                'recId' => rec.Id,
                'recObjectType' => String.valueOf(rec.getSObjectType())
            });
        }
        return toReturn;
    }

    /**
     * To create Log in SF side for Report purpose
     */
    public static void createLog(Map<String,Object> responseBody, Integer statusCode, String message){ //Assync melhor
        Integer numAccounts = 0;
        Integer numContacts = 0;
        Integer numLead = 0;
        Integer numOpp = 0;
        Integer numSA = 0;
        if(responseBody.get('records') != null){
            List<Map<String,String>> records = (List<Map<String,String>>)responseBody.get('records');
            for (Map<String,String> rec : records) {
                if(rec.get('recObjectType') == 'Account'){ numAccounts++;}
                if(rec.get('recObjectType') == 'Contact'){ numContacts++;}
                if(rec.get('recObjectType') == 'Lead'){numLead++;}
                if(rec.get('recObjectType') == 'Opportunity'){numOpp++;}
                if(rec.get('recObjectType') == 'ServiceAppointment'){numSA++;}
            }
        }
        else{
            responseBody = new Map<String,Object>{
                'MESSAGE' => 'CLIENT WITH OPEN ACTIVITY'
            };
        }

        Anonimyzed_Clients__c newlog = new Anonimyzed_Clients__c(
            json_body__c = String.valueOf(responseBody),
            Date_Time_of_Process__c = String.valueOf(responseBody.get('timeStamp')) == NULL ? String.valueOf(System.now()) : String.valueOf(responseBody.get('timeStamp')),
            accounts__c = numAccounts,
            contacts__c = numContacts,
            leads__c = numLead,
            opps__c = numOpp,
            sa__c = numSA,
            Status__c = String.valueOf(statusCode),
            Status_Message__c = message

        );
        insert newlog;
    }
}