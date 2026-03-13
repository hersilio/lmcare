/**
 * @description       : TO DELETE INTEGRATION LOGS DAILY
 * @author            : miguel.lopes
 * @group             :
 * @create date on    : 2026-02-10 10:14:16
 * @last modified by  : miguel.lopes
 **/
public with sharing class IntegrationLogDeleteBatch implements Database.Batchable<sObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Integer total = [SELECT COUNT() FROM IntegrationLog__c];
        Integer maxKeep = 1000;

        if (total <= maxKeep) {
            // Nothing to delete
            return Database.getQueryLocator([SELECT Id FROM IntegrationLog__c WHERE SourceSystem__c = 'Pyxis']);
        }

        Integer toDelete = total - maxKeep;
        String query = 'SELECT Id FROM IntegrationLog__c WHERE SourceSystem__c = \'Pyxis\' ORDER BY CreatedDate ASC LIMIT ' + toDelete;
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<IntegrationLog__c> scope) {
        delete scope;
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Integration log cleanup completed');
    }
}