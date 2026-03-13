/**
 * @description       : Centralized Integration Log handler
 * @author            : bruno.silva (refactor by Codex)
 * @group             :
 * @create date on    : 2025-11-20
 * @last modified by  : Hersilio Belini de Oliveira
 **/
public without sharing class IntegrationLogHandler {

    public class IntegrationException extends Exception {}

    /**
     * Base context for integration logging. Extend this class per integration to prefill defaults.
     */
    public abstract class IntegrationLogContext {
        public String requestBody;
        public String integrationKey;
        public Integer httpStatusCode;
        public Datetime endDateTime;
        public Datetime startDateTime;
        public String direction = 'Inbound';
        public Integer durationMs;
        public String status;
        public String externalId;
        public String errorMessage;
        public String targetSObject;
        public String targetRecordId;
        public String targetSystem = 'Salesforce';
        public String sourceSystem = 'Salesforce';
        public String httpMethod;
        public String endpoint;

        protected IntegrationLogContext(){
            this.startDateTime = System.now();
        }

        /**
         * Marks the context as successful and calculates duration.
         */
        public void markSuccess(String targetRecordId, Integer httpStatusCode){
            this.targetRecordId = targetRecordId;
            this.httpStatusCode = httpStatusCode;
            this.status = 'Success';
            closeTiming();
        }

        /**
         * Marks the context as error with exception message and calculates duration.
         */
        public void markError(Exception e, Integer httpStatusCode){
            this.errorMessage = e != null ? e.getMessage() : 'Unknown error';
            this.httpStatusCode = httpStatusCode;
            this.status = 'Error';
            closeTiming();
        }

        private void closeTiming(){
            this.endDateTime = System.now();
            if(this.startDateTime != null){
                this.durationMs = (Integer) (this.endDateTime.getTime() - this.startDateTime.getTime());
            }
        }

        public IntegrationLog__c toSObject(){
            Datetime lastDay = Datetime.newInstanceGmt(9999, 12, 31, 23, 59, 59);
            IntegrationLog__c logRecord = new IntegrationLog__c();
            logRecord.RequestBody__c = requestBody != null ? requestBody : '';
            logRecord.IntegrationKey__c = integrationKey != null ? integrationKey : 'Not specified';
            logRecord.HttpStatusCode__c = httpStatusCode != null ? httpStatusCode : 0;
            logRecord.EndDateTime__c = endDateTime != null ? endDateTime : lastDay;
            logRecord.StartDateTime__c = startDateTime != null ? startDateTime : lastDay;
            logRecord.Direction__c = direction != null ? direction : 'Inbound';
            logRecord.DurationMs__c = durationMs != null ? durationMs : 0;
            logRecord.Status__c = status != null ? status : 'Unknown';
            logRecord.ExternalId__c = externalId != null ? externalId : '';
            logRecord.ErrorMessage__c = errorMessage != null ? errorMessage : '';
            logRecord.TargetSObject__c = targetSObject != null ? targetSObject : '';
            logRecord.TargetRecordId__c = targetRecordId;
            logRecord.TargetSystem__c = targetSystem != null ? targetSystem : 'Salesforce';
            logRecord.SourceSystem__c = sourceSystem != null ? sourceSystem : 'Salesforce';
            logRecord.HttpMethod__c = httpMethod != null ? httpMethod : '';
            logRecord.Endpoint__c = endpoint != null ? endpoint : '';
            return logRecord;
        }
    }

    /**
     * Log a single context (success or error already marked).
     */
    public static void createIntegrationLog(IntegrationLogContext context){
        if(context == null){
            return;
        }
        insert new List<IntegrationLog__c>{ context.toSObject() };
    }

    public static void createIntegrationLog(List<IntegrationLogWrapper> logWrapper) {
        List<IntegrationLog__c> integrationLogs = new List<IntegrationLog__c>();
        for(IntegrationLogWrapper log : logWrapper){
            IntegrationLog__c newLog = new IntegrationLog__c();

            Datetime lastDay = Datetime.newInstanceGmt(9999, 12, 31, 23, 59, 59);

            newLog.RequestBody__c = log.requestBody != null ? log.requestBody : '';
            newLog.IntegrationKey__c = log.integrationKey != null ? log.integrationKey : 'Not specified';
            newLog.HttpStatusCode__c = log.httpStatusCode != null ? log.httpStatusCode : 0;
            newLog.EndDateTime__c = log.endDateTime != null ? log.endDateTime : lastDay;
            newLog.StartDateTime__c = log.startDateTime != null ? log.startDateTime : lastDay;
            newLog.Direction__c = log.direction != null ? log.direction : 'Inbound';
            newLog.DurationMs__c = log.durationMs != null ? log.durationMs : 0;
            newLog.Status__c = log.status != null ? log.status : 'Unknown';
            newLog.ExternalId__c = log.externalId != null ? log.externalId : '';
            newLog.ErrorMessage__c = log.errorMessage != null ? log.errorMessage : '';
            newLog.TargetSObject__c = log.targetSObject != null ? log.targetSObject : '';
            newLog.TargetRecordId__c = log.targetRecordId;
            newLog.TargetSystem__c = log.targetSystem != null ? log.targetSystem : 'Salesforce';
            newLog.SourceSystem__c = log.sourceSystem != null ? log.sourceSystem : 'Salesforce';
            newLog.HttpMethod__c = log.httpMethod != null ? log.httpMethod : '';
            newLog.Endpoint__c = log.endpoint != null ? log.endpoint : '';

            integrationLogs.add(newLog);
        }

        if(!integrationLogs.isEmpty()){
            insert integrationLogs;
        }
    }

    public class IntegrationLogWrapper{
        public String requestBody;
        public String integrationKey;
        public Integer httpStatusCode;
        public Datetime endDateTime;
        public Datetime startDateTime;
        public String direction;
        public Integer durationMs;
        public String status;
        public String externalId;
        public String errorMessage;
        public String targetSObject;
        public String targetRecordId;
        public String targetSystem;
        public String sourceSystem;
        public String httpMethod;
        public String endpoint;
    }
}