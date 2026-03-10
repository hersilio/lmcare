/**
 * @description       :
 * @author            : Hersilio Belini de Oliveira
 * @group             :
 * @last modified on  : 2025-09-12
 * @last modified by  : Hersilio Belini de Oliveira
**/
global class AppointmentSlotExpiryBatch implements Database.Batchable<SObject> {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Available__c
            FROM AppointmentSlot__c
            WHERE Available__c = TRUE
              AND StartTime__c < :Datetime.now()
        ]);
    }

    global void execute(Database.BatchableContext bc, List<AppointmentSlot__c> scope) {
        for (AppointmentSlot__c slot : scope) {
            slot.Available__c = false;
        }
        if (!scope.isEmpty()) {
            Database.update(scope, false);
        }
    }

    global void finish(Database.BatchableContext bc) {
    }
}