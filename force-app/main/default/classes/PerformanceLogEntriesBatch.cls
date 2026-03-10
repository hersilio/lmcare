/**
 * @description       :
 * @author            : Ricardo Simões
 * @group             :
 * @last modified on  : 2026-01-12
 * @last modified by  : Ricardo Simões
**/
public with sharing class PerformanceLogEntriesBatch implements Database.Batchable<PerformanceLogEntry__c>, Database.Stateful {

    private List<PerformanceLogEntry__c> entriesToInsert;

    public PerformanceLogEntriesBatch(List<PerformanceLogEntry__c> entriesToInsert) {
        this.entriesToInsert = entriesToInsert;
    }

    public Iterable<PerformanceLogEntry__c> start(Database.BatchableContext bc) {
        return this.entriesToInsert;
    }

    public void execute(Database.BatchableContext bc, List<PerformanceLogEntry__c> scope) {
        if (scope == null || scope.isEmpty()) {
            return;
        }
        
        if (!scope.isEmpty()) {
            Database.insert(scope, false); // Insert the entries directly
        }
    }

    public void finish(Database.BatchableContext bc) {
        // Nothing to do here
    }
}