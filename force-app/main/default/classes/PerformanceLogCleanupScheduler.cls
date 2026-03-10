public with sharing class PerformanceLogCleanupScheduler implements Schedulable, Database.Batchable<SObject>{

    Integer numRecordsDeleted = 0;

    // Schedulable

    public void execute(SchedulableContext sc){
        Database.executeBatch(new PerformanceLogCleanupScheduler(), 200);
    }

    // Batchable

    public Database.QueryLocator start(Database.BatchableContext bc){
        Integer numDays = 30;
        return Database.getQueryLocator([SELECT Id FROM PerformanceLog__c WHERE CreatedDate < :System.now().addDays(-numDays)]);
    }

    public void execute(Database.BatchableContext bc, List<sObject> scope){
        numRecordsDeleted = scope.size();
        delete scope;
    }

   public void finish(Database.BatchableContext bc){
        System.debug('Deleted ' + numRecordsDeleted + ' PerformanceLogs.');
   }
}