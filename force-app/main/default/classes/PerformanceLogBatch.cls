/**
 * @description       : Batch class to handle PerformanceLog__c records and delegate entry processing to PerformanceLogEntriesBatch
 * @author            : Ricardo Simões
 * @group             :
 * @last modified on  : 2026-01-12
 * @last modified by  : Ricardo Simões
**/
public with sharing class PerformanceLogBatch implements Database.Batchable<PerformanceLogBatch.PerformanceLogWrapper>, Database.Stateful {

    private List<PerformanceLogBatch.PerformanceLogWrapper> logWrapperList;
    private List<PerformanceLogEntry__c> entriesToInsert = new List<PerformanceLogEntry__c>();
    private Map<String, String> insertedLogsByToken = new Map<String, String>();

    public PerformanceLogBatch(List<PerformanceLogBatch.PerformanceLogWrapper> logWrapperList) {
        this.logWrapperList = logWrapperList;
    }

    public Iterable<PerformanceLogBatch.PerformanceLogWrapper> start(Database.BatchableContext bc) {
        return this.logWrapperList;
    }

    public void execute(Database.BatchableContext bc, List<PerformanceLogBatch.PerformanceLogWrapper> scope) {
        // Insert PerformanceLog__c records
        List<PerformanceLog__c> logsToInsert = new List<PerformanceLog__c>();

        for (PerformanceLogBatch.PerformanceLogWrapper wrapper : scope) {
            PerformanceLog__c log = wrapper.log;
            logsToInsert.add(log);
        }

        insert logsToInsert;
        System.debug('Inserted ' + logsToInsert.size() + ' performance logs.');

        // Map inserted logs back to their wrappers
        for(PerformanceLog__c log : logsToInsert) {
            String Token = log.Token__c;
            insertedLogsByToken.put(Token, log.Id);
        }
    }

    public void finish(Database.BatchableContext bc) {
        try {
            for (Integer i = 0; i < logWrapperList.size(); i++) {
                String PerformanceId = insertedLogsByToken.get(logWrapperList[i].log.Token__c);

                if (logWrapperList[i].entries != null) {
                    for (PerformanceLog.PerformanceLogEntry entry : logWrapperList[i].entries) {
                            PerformanceLogEntry__c logEntryObj = new PerformanceLogEntry__c();
                            logEntryObj.PerformanceLog__c = PerformanceId;
                            logEntryObj.Description__c = entry.description;
                            logEntryObj.TimeStamp__c = entry.timeStamp;
                            logEntryObj.Duration__c = entry.duration;
                            logEntryObj.Token__c = logWrapperList[i].log.Token__c;

                            entriesToInsert.add(logEntryObj);
                    }
                }
            }
           
            if (!entriesToInsert.isEmpty()) {
                System.debug('Inserting ' + entriesToInsert.size() + ' performance log entries.');
                Database.executeBatch(new PerformanceLogEntriesBatch(entriesToInsert), 200);
            }
            
        } catch (Exception e) {
            ErrorLog.createErrorLogList('PerformanceLogBatch.finish', e.getMessage(), e.getLineNumber().toString(), 'PerformanceLogBatch.finish', e.getStackTraceString(), e.getTypeName());
        }
    }
    
    public class PerformanceLogWrapper {
        public PerformanceLog__c log;
        public List<PerformanceLog.PerformanceLogEntry> entries = new List<PerformanceLog.PerformanceLogEntry>();
    }
}