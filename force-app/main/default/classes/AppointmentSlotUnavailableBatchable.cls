/**
 * @description       :
 * @author            : Hersilio Belini de Oliveira
 * @group             :
 * @last modified on  : 2025-09-01
 * @last modified by  : Hersilio Belini de Oliveira
**/
public with sharing class AppointmentSlotUnavailableBatchable extends GenericBatchUpdater {
    private static Integer maxDays = 30; // guarantees maxDays is not null
    private String currentJobId;

    public AppointmentSlotUnavailableBatchable(String jobId) {
        super(buildQuery(jobId));
        this.currentJobId = jobId;
    }

    public static String buildQuery(String jobId) {
        DateTime maxStartDate = DateTime.now().addDays(maxDays);
        String formattedDate = maxStartDate.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''); 
        String queryString = 'SELECT Id, Available__c, JobId__c, StartTime__c FROM AppointmentSlot__c ' +
                             'WHERE Available__c = true AND ' +
                             '((JobId__c != \'' + String.escapeSingleQuotes(jobId) + '\' AND StartTime__c < ' + formattedDate + ') ' +
                             'OR StartTime__c < TODAY)';
        return queryString;
    }

    public override void updateRecord(SObject record) {
        AppointmentSlot__c slot = (AppointmentSlot__c)record;
        slot.Available__c = false;
    }

    public override Boolean shouldUpdate(SObject record) {
        AppointmentSlot__c slot = (AppointmentSlot__c)record;
        return slot.Available__c;
    }

    // Hooks de auditoria se GenericBatchUpdater suportar before/after; caso não, usar SOQL auxiliares fora.
    // Contadores auxiliares (sem estado global cross-transaction).
    public static void setMaxDays(Integer days) {
        if (days != null && days > 0) {
            maxDays = days;
        }
    }
}