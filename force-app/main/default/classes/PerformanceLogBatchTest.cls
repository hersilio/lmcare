/**
* @description       :
 * @author            : Ricardo Simões
 * @group             :
 * @last modified on  : 2026-01-12
 * @last modified by  : Ricardo Simões
 */
@isTest
private class PerformanceLogBatchTest {

   
    @isTest
    static void testPerformanceLogBatch_ExecutesAndQueuesEntriesBatch() {
        String token = String.valueOf(Crypto.getRandomInteger());
        PerformanceLog__c testLog = new PerformanceLog__c(
            Title__c = 'Test Log',
            Description__c = 'Test Description',
            MethodName__c = 'TestMethod',
            Duration__c = 1000,
            numUsersChecked__c = 5,
            numSlotsRetrieved__c = 10,
            numLogEntries__c = 2,
            TimeStamp__c = System.now(),
            Token__c = token
        );
        
        List<PerformanceLog.PerformanceLogEntry> entries = new List<PerformanceLog.PerformanceLogEntry>();
        PerformanceLog.PerformanceLogEntry e1 = new PerformanceLog.PerformanceLogEntry('First Entry');
        e1.timeStamp = System.now();
        e1.duration = 10;
        entries.add(e1);
        PerformanceLog.PerformanceLogEntry e2 = new PerformanceLog.PerformanceLogEntry('Second Entry');
        e2.timeStamp = System.now().addSeconds(1);
        e2.duration = 20;
        entries.add(e2);
        
        PerformanceLogBatch.PerformanceLogWrapper wrapper = new PerformanceLogBatch.PerformanceLogWrapper();
        wrapper.log = testLog;
        wrapper.entries = entries;
        
        List<PerformanceLogBatch.PerformanceLogWrapper> wrappers = new List<PerformanceLogBatch.PerformanceLogWrapper>{ wrapper };
        
        Test.startTest();
        Id jobId = Database.executeBatch(new PerformanceLogBatch(wrappers), 10);
        Test.stopTest();
        
        List<PerformanceLog__c> insertedLogs = [
            SELECT Id, Title__c, Description__c, MethodName__c, Duration__c, numUsersChecked__c, numSlotsRetrieved__c, numLogEntries__c, Token__c
            FROM PerformanceLog__c
            WHERE Token__c = :token
            LIMIT 10
        ];
        System.assertEquals(1, insertedLogs.size(), 'One PerformanceLog__c should be created');
        PerformanceLog__c inserted = insertedLogs[0];
        System.assertEquals('Test Log', inserted.Title__c);
        System.assertEquals(2, (Integer)inserted.numLogEntries__c);
        
        List<PerformanceLogEntry__c> entriesInserted = [
            SELECT Id, PerformanceLog__c, Description__c, Duration__c, Token__c
            FROM PerformanceLogEntry__c
            WHERE Token__c = :token
            ORDER BY CreatedDate
        ];
        System.assertEquals(2, entriesInserted.size(), 'Two entries should be inserted by PerformanceLogEntriesBatch');
        Set<String> descriptions = new Set<String>();
        for (PerformanceLogEntry__c le : entriesInserted) {
            System.assertEquals(inserted.Id, le.PerformanceLog__c, 'Each entry must reference the inserted log');
            descriptions.add(le.Description__c);
            System.assertNotEquals(null, le.Duration__c, 'Duration should be set');
        }
        System.assertEquals(new Set<String>{'First Entry','Second Entry'}, descriptions);
    }

    @isTest
    static void testPerformanceLogEntriesBatch_DirectInsertScopeGuard() {
        PerformanceLog__c parent = new PerformanceLog__c(
            Title__c = 'Parent Log',
            MethodName__c = 'DirectEntries',
            Duration__c = 1,
            Token__c = String.valueOf(Crypto.getRandomInteger())
        );
        insert parent;
        
        List<PerformanceLogEntry__c> scope = new List<PerformanceLogEntry__c>();
        PerformanceLogEntry__c a = new PerformanceLogEntry__c(
            PerformanceLog__c = parent.Id,
            Description__c = 'A',
            Duration__c = 5,
            Token__c = parent.Token__c
        );
        PerformanceLogEntry__c b = new PerformanceLogEntry__c(
            PerformanceLog__c = parent.Id,
            Description__c = 'B',
            Duration__c = 7,
            Token__c = parent.Token__c
        );
        scope.add(a);
        scope.add(b);
    
        Test.startTest();
        Database.executeBatch(new PerformanceLogEntriesBatch(scope), 50);
        Test.stopTest();
        
        List<PerformanceLogEntry__c> rows = [
            SELECT Id, Description__c, PerformanceLog__c, Token__c
            FROM PerformanceLogEntry__c
            WHERE PerformanceLog__c = :parent.Id
            ORDER BY Description__c
        ];
        System.assertEquals(2, rows.size(), 'Entries batch should insert provided scope');
        System.assertEquals(new List<String>{'A','B'}, new List<String>{rows[0].Description__c, rows[1].Description__c});
    }
}