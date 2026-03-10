@IsTest
private class PerformanceLogCleanupSchedulerTest {

    // Helper to create a PerformanceLog__c record with at least one child entry
    private static PerformanceLog__c createPerfLogWithEntry(Datetime createdDate, String title) {
        PerformanceLog__c log = new PerformanceLog__c(
            Title__c = title,
            Description__c = 'test',
            MethodName__c = 'method',
            Duration__c = 1,
            numLogEntries__c = 1
        );
        insert log;

        PerformanceLogEntry__c entry = new PerformanceLogEntry__c(
            PerformanceLog__c = log.Id,
            Description__c = 'entry',
            TimeStamp__c = System.now(),
            Duration__c = 0
        );
        insert entry;

        // Backdate the parent record if needed by updating CreatedDate via Test utility (not allowed directly).
        // Instead, we control deletability using CreatedDate filter in batch query (older than 30 days).
        // We cannot set CreatedDate directly; so to simulate, we will create "old" logs via a separate SObject if needed.
        // However, since the batch filters by CreatedDate, we create "old" ones by inserting and then using Test.setCreatedDate.
        // Test.setCreatedDate is available for certain sObjects; for custom objects it's supported.
        Test.setCreatedDate(log.Id, createdDate);
        return log;
    }

    @IsTest
    static void testBatchDeletesOnlyOlderThan30Days() {
        // Create two logs: one older than 30 days, one recent
        DateTime now = System.now();
        DateTime oldCreated = now.addDays(-31);
        DateTime recentCreated = now.addDays(-5);

        PerformanceLog__c oldLog = createPerfLogWithEntry(oldCreated, 'Old Log');
        PerformanceLog__c recentLog = createPerfLogWithEntry(recentCreated, 'Recent Log');

        Test.startTest();
        // Invoke as schedulable (which will chain to batch)
        Id JobId = System.schedule('PerfLogCleanupJob', '0 0 0 15 3 ? 2099', new PerformanceLogCleanupScheduler());
        // Also directly run the batch to ensure coverage of start/execute/finish
        Database.executeBatch(new PerformanceLogCleanupScheduler(), 200);
        Test.stopTest();

        // Old log should be deleted, recent should remain
        Map<Id, PerformanceLog__c> remaining = new Map<Id, PerformanceLog__c>([
            SELECT Id FROM PerformanceLog__c WHERE Id IN :new Set<Id>{oldLog.Id, recentLog.Id}
        ]);
        System.assert(!remaining.containsKey(oldLog.Id), 'Old log should have been deleted by cleanup');
        System.assert(remaining.containsKey(recentLog.Id), 'Recent log should remain');

        // Child entries for old log should also be deleted via cascade if MD configured, but we assert count for recent
        Integer recentEntries = [
            SELECT COUNT() FROM PerformanceLogEntry__c WHERE PerformanceLog__c = :recentLog.Id
        ];
        System.assertEquals(1, recentEntries, 'Recent log entry should remain intact');
        
        //Check if JobId is not null
        System.assert(JobId != null, 'JobId should not be null');
    }

    @IsTest
    static void testStartAndExecuteWithEmptyScope() {
        // No records meet criteria (create only recent)
        createPerfLogWithEntry(System.now().addDays(-1), 'Only Recent');

        Test.startTest();
        // Run batch; it should find nothing older than 30 days and execute with empty scopes
        Database.executeBatch(new PerformanceLogCleanupScheduler(), 200);
        Test.stopTest();

        // Ensure nothing was deleted
        Integer logsCount = [SELECT COUNT() FROM PerformanceLog__c];
        System.assert(logsCount > 0, 'No logs should have been deleted when none older than 30 days');
    }
}