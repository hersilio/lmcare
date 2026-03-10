/**
 * @description       :
 * @author            : Hersilio Belini de Oliveira
 * @group             :
 * @last modified on  : 2025-07-01
 * @last modified by  : Hersilio Belini de Oliveira
**/
global with sharing class AppointmentSlotUpsertQueueable implements Database.Batchable<AppointmentSlot__c>  {

    List<AppointmentSlot__c> fullList;

    global AppointmentSlotUpsertQueueable(List<AppointmentSlot__c> fullList) {
        this.fullList = fullList;
    }

    global Iterable<AppointmentSlot__c> start(Database.BatchableContext bc) {
        return fullList;
    }

    global void execute(Database.BatchableContext bc, List<AppointmentSlot__c> scope) {
        try {
            upsert scope UniqueKey__c;
            System.debug('Upsert de ' + scope.size() + ' registros.');
        } catch (Exception e) {
            System.debug('Erro no upsert: ' + e.getMessage());
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('Batch finalizado.');
    }
}