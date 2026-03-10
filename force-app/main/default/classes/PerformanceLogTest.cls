@IsTest
private class PerformanceLogTest {
    @IsTest
    static void testAddEntriesAndSerialization() {
        // Create log and add entries (no save path validation here)
        PerformanceLog log = new PerformanceLog('Unit Test Log');
        log.description = 'Desc';
        log.methodName = 'someMethod';

        System.assertEquals(0, log.getNumEntries(), 'Should start with 0 entries');

        // First entry should have duration 0
        log.addLogEntry('Step 1');
        System.assertEquals(1, log.getNumEntries(), 'Should have 1 entry');
        System.assertEquals(1, log.logEntryList.size(), 'Internal list should have 1 entry');
        System.assertEquals(0, log.logEntryList[0].duration, 'First entry duration should be 0');

        sleep(50);
        // Second entry duration should be non-negative and reference time difference
        log.addLogEntry('Step 2');
        System.assertEquals(2, log.getNumEntries(), 'Should have 2 entries');
        System.assertEquals(2, log.logEntryList.size(), 'Internal list should have 2 entries');
        System.assertNotEquals(null, log.logEntryList[1].duration, 'Second entry duration should be populated');
        System.assert(log.logEntryList[1].duration >= 0, 'Second entry duration should be >= 0');

        // toString should return JSON and honor pretty flag
        String compact = log.toString(false);
        String pretty = log.toString();
        System.assertNotEquals(null, compact, 'Compact JSON should not be null');
        System.assertNotEquals(null, pretty, 'Pretty JSON should not be null');
        System.assert(pretty.contains('\n') || pretty.contains('  '), 'Pretty JSON should be formatted');
    }

    @IsTest
    static void testCommitLog_SynchronousInsert() {
        // Ensure metadata enables synchronous save for this title

        // Provide an active, synchronous metadata setting so save() will commit synchronously
        PerformanceLogSetting__mdt syncMdt = (PerformanceLogSetting__mdt)JSON.deserializeStrict(
            '{"DeveloperName":"Sync_Save_Log","MasterLabel":"Sync Save Log","IsActive__c":true,"IsSaveAsync__c":false,"LatencyThresholdForLogging__c":0}',
            PerformanceLogSetting__mdt.class
        );
        PerformanceLog log = new PerformanceLog('Sync Save Log', syncMdt);
        log.description = 'Sync path';
        log.methodName = 'commitLog';

        log.addLogEntry('Start');
        sleep(50);
        log.addLogEntry('Middle');
        sleep(50);
        log.addLogEntry('End');

        Test.startTest();
        log.save(); // should commit synchronously due to isAsync=false
        Test.stopTest();

        // Validate parent log record
        PerformanceLog__c[] logs = [
            SELECT Id, Title__c, Description__c, MethodName__c, Duration__c, numUsersChecked__c, numSlotsRetrieved__c, numLogEntries__c
            FROM PerformanceLog__c
            WHERE Title__c = 'Sync Save Log'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals(1, logs.size(), 'One PerformanceLog__c should have been inserted');
        PerformanceLog__c pl = logs[0];
        System.assertEquals('Sync path', pl.Description__c, 'Description should match');
        System.assertEquals('commitLog', pl.MethodName__c, 'Method name should match');
        System.assertEquals(3, pl.numLogEntries__c, 'numLogEntries should match the number of entries');

        // Validate child entries
        List<PerformanceLogEntry__c> entries = [
            SELECT Id, PerformanceLog__c, Description__c, TimeStamp__c, Duration__c
            FROM PerformanceLogEntry__c
            WHERE PerformanceLog__c = :pl.Id
            ORDER BY CreatedDate ASC
        ];
        System.assertEquals(3, entries.size(), 'Three entry rows should have been inserted');
        System.assertEquals('Start', entries[0].Description__c, 'First entry description should match');
        System.assertEquals('Middle', entries[1].Description__c, 'Second entry description should match');
        System.assertEquals('End', entries[2].Description__c, 'Third entry description should match');
        System.assertEquals(0, entries[0].Duration__c, 'First entry duration should be 0');
        System.assert(entries[1].Duration__c >= 0, 'Second entry duration should be non-negative');
        System.assert(entries[2].Duration__c >= 0, 'Third entry duration should be non-negative');
    }

    @IsTest
    static void testQueueable_SaveAsync() {
        // Ensure metadata enables async save for this title

        // Provide an active, async metadata setting so save() enqueues the queueable
        PerformanceLogSetting__mdt asyncMdt = (PerformanceLogSetting__mdt)JSON.deserializeStrict(
            '{"DeveloperName":"Async_Save_Log","MasterLabel":"Async Save Log","IsActive__c":true,"IsSaveAsync__c":true,"LatencyThresholdForLogging__c":0}',
            PerformanceLogSetting__mdt.class
        );
        PerformanceLog log = new PerformanceLog('Async Save Log', asyncMdt);
        log.description = 'Async path';
        log.methodName = 'queueable';
        log.addLogEntry('Only Step');

        Test.startTest();
        // save async enqueues Queueable that calls commitLog
        log.save();
        Test.stopTest(); // processes the queueable

        // Verify the log and one entry got inserted
        PerformanceLog__c[] logs = [
            SELECT Id, Title__c, numLogEntries__c
            FROM PerformanceLog__c
            WHERE Title__c = 'Async Save Log'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals(1, logs.size(), 'One PerformanceLog__c should be inserted asynchronously');
        System.assertEquals(1, logs[0].numLogEntries__c, 'numLogEntries should be 1');

        List<PerformanceLogEntry__c> entries = [
            SELECT Id, PerformanceLog__c, Description__c, Duration__c
            FROM PerformanceLogEntry__c
            WHERE PerformanceLog__c = :logs[0].Id
        ];
        System.assertEquals(1, entries.size(), 'One entry should be inserted asynchronously');
        System.assertEquals('Only Step', entries[0].Description__c, 'Description should match');
        System.assertEquals(0, entries[0].Duration__c, 'First entry duration should be 0');
    }

    @IsTest
    static void testSave_NoOp_WhenInactive() {
        // Metadata present but inactive

        // Provide an inactive metadata setting so save() no-ops
        PerformanceLogSetting__mdt inactiveMdt = (PerformanceLogSetting__mdt)JSON.deserializeStrict(
            '{"DeveloperName":"Inactive_Log","MasterLabel":"Inactive Log","IsActive__c":false,"IsSaveAsync__c":false,"LatencyThresholdForLogging__c":0}',
            PerformanceLogSetting__mdt.class
        );
        PerformanceLog log = new PerformanceLog('Inactive Log', inactiveMdt);
        log.description = 'should not save';
        log.methodName = 'noop';
        log.addLogEntry('step');

        Test.startTest();
        log.save(); // should early return due to isActive=false
        Test.stopTest();

        PerformanceLog__c[] logs = [
            SELECT Id FROM PerformanceLog__c WHERE Title__c = 'Inactive Log'
        ];
        System.assertEquals(0, logs.size(), 'No logs should be inserted when inactive');
    }

    @IsTest
    static void testSave_NoOp_WhenUnderThreshold() {
        // Set a high threshold so duration <= threshold, causing no save

        // Provide active metadata with high threshold so total duration <= threshold triggers no-op
        PerformanceLogSetting__mdt thresholdMdt = (PerformanceLogSetting__mdt)JSON.deserializeStrict(
            '{"DeveloperName":"Threshold_Log","MasterLabel":"Threshold Log","IsActive__c":true,"IsSaveAsync__c":false,"LatencyThresholdForLogging__c":999999}',
            PerformanceLogSetting__mdt.class
        );
        PerformanceLog log = new PerformanceLog('Threshold Log', thresholdMdt);
        log.description = 'under threshold';
        log.methodName = 'threshold';
        log.addLogEntry('step 1');
        // No artificial delay; total duration should be small

        Test.startTest();
        log.save(); // should early return due to threshold
        Test.stopTest();

        PerformanceLog__c[] logs = [
            SELECT Id FROM PerformanceLog__c WHERE Title__c = 'Threshold Log'
        ];
        System.assertEquals(0, logs.size(), 'No logs should be inserted when duration is under threshold');
    }

    @IsTest
    static void testPrintLogEntries_Coverage() {
        // Just exercise the debug path for coverage
        // Provide any active metadata to avoid constructor querying null MDT in orgs
        PerformanceLogSetting__mdt printMdt = (PerformanceLogSetting__mdt)JSON.deserializeStrict(
            '{"DeveloperName":"Test_Print_Path","MasterLabel":"Test Print Path","IsActive__c":true,"IsSaveAsync__c":false,"LatencyThresholdForLogging__c":0}',
            PerformanceLogSetting__mdt.class
        );
        PerformanceLog log = new PerformanceLog('Test Print Path', printMdt);
        log.addLogEntry('A');
        log.addLogEntry('B');
        // Method has no return; ensure no exceptions thrown
        log.printLogEntries();
    }

    private static void sleep(Long duration){
        System.debug('Sleeping for ' + duration + ' ms');
        Long startTime = Datetime.now().getTime();
        while (Datetime.now().getTime() - startTime < duration){
            // Busy wait
        }
    }
}