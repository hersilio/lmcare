/**
 * @description       :
 * @author            : Hersilio Belini de Oliveira
 * @group             :
 * @last modified on  : 2025-07-29
 * @last modified by  : Hersilio Belini de Oliveira
**/
public class AppointmentSlotBatchable implements Database.Batchable<Map<String, String>>, Database.AllowsCallouts, Database.Stateful {

    private Map<String, AppointmentSlotSummary__c> appSlotSummaryMap;
    private List<Map<String, String>> resourceToExecute;
    private String jobId;
    private Integer maxDays;
    private List<PerformanceLog> allLogs = new List<PerformanceLog>();

    public AppointmentSlotBatchable(List<Map<String, String>> resourceToExecute, Map<String, AppointmentSlotSummary__c> summaryMap, String jobId, Integer maxDays) {
        this.appSlotSummaryMap = summaryMap;
        this.resourceToExecute = resourceToExecute;
        this.jobId = jobId;
        this.maxDays = maxDays;
    }

    public Iterable<Map<String, String>> start(Database.BatchableContext context) {
        return this.resourceToExecute;
    }

    public void execute(Database.BatchableContext context, List<Map<String, String>> scope) {
        AppointmentSlotService.createNextAppointmentSlots(scope, appSlotSummaryMap, jobId);
        List<PerformanceLog> logsFromExecution = LM_AppointmentSlotExecutionContext.flushLogs();
        allLogs.addAll(logsFromExecution);

    }

public void finish(Database.BatchableContext context) {
        AppointmentSlotUnavailableBatchable.setMaxDays(maxDays);
        Database.executeBatch(new AppointmentSlotUnavailableBatchable(jobId), 200);
        try {
            List<PerformanceLogBatch.PerformanceLogWrapper> logWrapperList = new List<PerformanceLogBatch.PerformanceLogWrapper>();
        
            for(PerformanceLog log : allLogs){
                if(log.isAsync){

                    PerformanceLogBatch.PerformanceLogWrapper logWrapper = new PerformanceLogBatch.PerformanceLogWrapper();
                    
                    logWrapper.log = PerformanceLog.generateLogFromPerformanceLog(log);
                    
                    for( PerformanceLog.PerformanceLogEntry entry : log.logEntryList){
                        entry.Token = logWrapper.log.Token__c;
                        logWrapper.entries.add(entry);
                    }
                    
                    logWrapper.log.numLogEntries__c = log.logEntryList.size();
                    logWrapperList.add(logWrapper);
                }
            }
            if (!logWrapperList.isEmpty()) {
                System.debug('Executing PerformanceLogBatch with ' + logWrapperList.size() + ' logs and ' + allLogs.size() + ' total entries.');
                Database.executeBatch(new PerformanceLogBatch(logWrapperList), 200);
            }
        } catch (Exception e){
            ErrorLog.createErrorLogList('AppointmentSlotBatchable', e.getMessage(), e.getLineNumber().toString(), 'AppointmentSlotBatchable.finish', e.getStackTraceString(), e.getTypeName());
        }
    }
}