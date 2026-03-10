/**
 * @description This class is a Performance Log intended for evaluating the latency in each step of a method. Specifically, 
 * it is intended for use in the  SchGoogleCalendarIntegrationHandler class.
 * This class can eventually be extended for use in other scenarios by turning it into a virtual class and creating new classes that extend from it.
 * The logs are stored in the database with the Custom Object PerformanceLog__c, which has a master-detail relationship to the object PerformanceLogEntry__c. 
 * The Scheduled Flow {insert flow name} is responsible for deleting older logs. The cutoff date is defined in the Flow and is set to 30 days.
 * 
 * @author Felipe Gil
 * @company TRH
 * @created 2025-11-12
 * @version 0.1
 * @see SchGoogleCalendarIntegrationHandler
 */

public without sharing class PerformanceLog {

    // Generic parameters 
    private Integer numLogEntries;

    public String title;
    public String description;
    public String methodName;
    public DateTime timeStamp;
    public Long duration = 0;

    public Boolean isActive = false;
    public Boolean isAsync = false;
    public Long latencyThresholdForLogging = 0;

    public List<PerformanceLogEntry> logEntryList;

    // Scheduler-specific parameters
    public Integer numUsersChecked;
    public Integer numSlotsRetrieved;

    // Added overload to support callers that only pass a title (e.g., LM_AppointmentSlotExecutionContext)
    public PerformanceLog(String title){
        this(title, null);
    }

    public PerformanceLog(String title, PerformanceLogSetting__mdt mdtSetting){
        this.title = title.left(40);

        if(mdtSetting == null){
            List<PerformanceLogSetting__mdt> mdtList = [SELECT DeveloperName, IsActive__c, IsSaveAsync__c, LatencyThresholdForLogging__c FROM PerformanceLogSetting__mdt WHERE Label = :title LIMIT 1];
            if(mdtList != null && !mdtList.isEmpty()){
                mdtSetting = mdtList[0];
            }
        }

        this.isActive = mdtSetting.isActive__c;
        this.isAsync = mdtSetting.IsSaveAsync__c;
        this.latencyThresholdForLogging = (Long)mdtSetting.LatencyThresholdForLogging__c;

        this.numLogEntries = 0;
        this.timeStamp = Datetime.now();
        this.logEntryList = new List<PerformanceLogEntry>();
    }
    
    public Integer getNumEntries(){
        return numLogEntries;
    }
    
    public void addLogEntry(String description){
        PerformanceLogEntry logEntry = new PerformanceLogEntry(description);
        if (logEntryList.isEmpty()){
            logEntry.duration = 0;
        }else{
            logEntry.duration = logEntry.timeStamp.getTime() - logEntryList[numLogEntries-1].timeStamp.getTime();
        }
        logEntry.idx = numLogEntries;        
        logEntryList.add(logEntry);
        numLogEntries++;
    }

    public String toString(boolean pretty){
        if (pretty){
            return JSON.serializePretty(this);
        }
        return JSON.serialize(this);
    }

    public override String toString(){
        return toString(true);
    }

    public void printLogEntries(){
        for (PerformanceLogEntry log : logEntryList) {
            String formattedString = String.format('Log {0} - {1} - {2} - {3} ms', new List<Object>{log.idx, log.timeStamp, log.description, log.duration});
            System.debug(formattedString);
        }
    }

    public void save(){
        if (!isActive) return;
        
        duration = Datetime.now().getTime() - this.timeStamp.getTime();
        if (duration <= latencyThresholdForLogging) return;

        if (this.isAsync){
            System.enqueueJob(new QueueableLog(this));
        } else {
            commitLog();
        }
    }

    //Save a list of logs at once - Can be Improved, need to test and most likely refactor
    public static void saveList(List<PerformanceLog__c> logs, PerformanceLogSetting__mdt mdtSetting){
        //this.title = title.left(40);
        //Criar 2 listas de logs e de log entries, 1 logs to save, outra para queuable
        List<PerformanceLog__c> logsToSave = new List<PerformanceLog__c>();
        List<PerformanceLog__c> logsToQueue = new List<PerformanceLog__c>();

       if(mdtSetting == null){
            List<PerformanceLogSetting__mdt> mdtList = [SELECT DeveloperName, IsActive__c, IsSaveAsync__c, LatencyThresholdForLogging__c FROM PerformanceLogSetting__mdt LIMIT 1];
            if(mdtList != null && !mdtList.isEmpty()){
                mdtSetting = mdtList[0];
            }
        }

        for(PerformanceLog__c log: logs){
            if(log.Duration__c > mdtSetting.LatencyThresholdForLogging__c){
                if(mdtSetting.IsSaveAsync__c){
                    logsToQueue.add(log);
                }else{
                    logsToSave.add(log);
                }
            }
        }

        if(!logsToSave.isEmpty()){
            insert logsToSave;
        }

        if(!logsToQueue.isEmpty()){
            System.enqueueJob(new QueueableLogList(logsToQueue));
        }

        List<PerformanceLogEntry__c> logEntryObjList = new List<PerformanceLogEntry__c>();

        // 10 Perfomance Logs with 200 entries each

        
        List<PerformanceLogEntry> logEntryList = new List<PerformanceLogEntry>();
        
    }

    public void commitLog(){
        PerformanceLog__c log = new PerformanceLog__c();
        log.Title__c = this.title;
        log.Description__c = this.description;
        log.MethodName__c = this.methodName;
        log.Duration__c = this.duration;
        log.numUsersChecked__c = this.numUsersChecked;
        log.numSlotsRetrieved__c = this.numSlotsRetrieved;
        log.numLogEntries__c = this.numLogEntries;

        insert log;

        List<PerformanceLogEntry__c> logEntryObjList = new List<PerformanceLogEntry__c>();

        for (PerformanceLogEntry logEntry : logEntryList) {
            PerformanceLogEntry__c logEntryObj = new PerformanceLogEntry__c();
            logEntryObj.PerformanceLog__c = log.Id;
            logEntryObj.Description__c = logEntry.description;
            logEntryObj.TimeStamp__c = logEntry.timeStamp;
            logEntryObj.Duration__c = logEntry.duration;

            logEntryObjList.add(logEntryObj);
        }

        insert logEntryObjList;
    }

    
    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
        Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
        randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }

    public static PerformanceLog__c generateLogFromPerformanceLog(PerformanceLog performancelog){
        String Token = generateRandomString(16);

        PerformanceLog__c log = new PerformanceLog__c();

        log.Title__c = performancelog.title;
        log.Description__c = performancelog.description;
        log.MethodName__c = performancelog.methodName;
        log.Duration__c = performancelog.duration;
        log.TimeStamp__c = performancelog.timeStamp;
        log.numUsersChecked__c = performancelog.numUsersChecked;
        log.numSlotsRetrieved__c = performancelog.numSlotsRetrieved;
        log.Token__c = Token;

        return log;
    }

    public class QueueableLog implements Queueable{

        public PerformanceLog log;

        public QueueableLog(PerformanceLog log){
            this.log = log;
        }
        
        public void execute(System.QueueableContext context){
            log.commitLog();
        }
    }

    public class QueueableLogList implements Queueable{

        public List<PerformanceLog__c> logs;

        public QueueableLogList(List<PerformanceLog__c> logs){
            this.logs = logs;
        }

        public void execute(System.QueueableContext context){
            saveList(logs, null);
        }
    }

    public class PerformanceLogEntry{
        public Integer idx;
        public String description;
        public DateTime timeStamp;
        public Long duration;
        public String Token;

        public PerformanceLogEntry(String description){
            this.description = description;
            this.timeStamp = DateTime.now();
        }
    }

    public class PerformanceLogWrapper{
        public PerformanceLog__c log;
        public List<PerformanceLogEntry> entries;
    }
}