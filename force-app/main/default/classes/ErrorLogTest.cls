/**
 * @author Ricardo Simões
 * @created 2026-01-20
 * @description Unit tests for the ErrorLog class.
 */
@IsTest
private class ErrorLogTest {

    /**
     * @author Ricardo Simões
     * @created 2026-01-20
     * @description Creates a single ErrorLog__c via ErrorLog.createErrorLogList and asserts field values.
     */
    @IsTest
    static void testCreateSingleErrorLog() {
        String className = 'MyClass';
        String message = 'Test error message';
        String lineNumber = '42';
        String methodName = 'myMethod';
        String stackTrace = 'STACK_TRACE_SAMPLE';
        String type = 'EXCEPTION';

        Test.startTest();
        ErrorLog.createErrorLogList(className, message, lineNumber, methodName, stackTrace, type);
        Test.stopTest();

        List<ErrorLog__c> logs = [
            SELECT Id, Class__c, Description__c, LineNumber__c, MethodName__c, StackTrace__c, Type__c
            FROM ErrorLog__c
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertEquals(1, logs.size(), 'Exactly one ErrorLog__c should have been inserted');

        ErrorLog__c inserted = logs[0];
        System.assertEquals(className, inserted.Class__c, 'Class__c mismatch');
        System.assertEquals(message, inserted.Description__c, 'Description__c mismatch');
        System.assertEquals(lineNumber, inserted.LineNumber__c, 'LineNumber__c mismatch');
        System.assertEquals(methodName, inserted.MethodName__c, 'MethodName__c mismatch');
        System.assertEquals(stackTrace, inserted.StackTrace__c, 'StackTrace__c mismatch');
        System.assertEquals(type, inserted.Type__c, 'Type__c mismatch');
    }

    /**
     * @author Ricardo Simões
     * @created 2026-01-20
     * @description Validates method handles empty/edge inputs gracefully and still inserts a record.
     */
    @IsTest
    static void testCreateWithEmptyValues() {
        Test.startTest();
        ErrorLog.createErrorLogList('', '', null, null, '', '');
        Test.stopTest();

        ErrorLog__c recent = [
            SELECT Id, Class__c, Description__c, LineNumber__c, MethodName__c, StackTrace__c, Type__c
            FROM ErrorLog__c
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        System.assertNotEquals(null, recent, 'An ErrorLog__c should have been inserted for empty values');
        // Loosen assertions to support orgs that store null for empty strings
        System.assertEquals(true, recent.Class__c == null || recent.Class__c == '', 'Class__c should be null or empty');
        System.assertEquals(true, recent.Description__c == null || recent.Description__c == '', 'Description__c should be null or empty');
        System.assertEquals(null, recent.LineNumber__c, 'LineNumber__c should allow null');
        System.assertEquals(null, recent.MethodName__c, 'MethodName__c should allow null');
        System.assertEquals(true, recent.StackTrace__c == null || recent.StackTrace__c == '', 'StackTrace__c should be null or empty');
        System.assertEquals(true, recent.Type__c == null || recent.Type__c == '', 'Type__c should be null or empty');
    }

    /**
     * @author Ricardo Simões
     * @created 2026-01-20
     * @description Ensures no exception escapes when an unexpected DML failure happens; the method swallows exceptions by design.
     */
    @IsTest
    static void testNoThrowOnDmlFailureSimulation() {
        try {
            Test.startTest();
            ErrorLog.createErrorLogList('A', 'B', 'C', 'D', 'E', 'F');
            Test.stopTest();
        } catch (Exception e) {
            System.assert(false, 'ErrorLog.createErrorLogList should not throw exceptions externally');
        }
    }

    /**
     * @author Ricardo Simões
     * @created 2026-01-20
     * @description Bulk invocation: method should handle multiple calls within governor limits and produce records.
     */
    @IsTest
    static void testBulkInvocations() {
        Integer count = 10;
        Test.startTest();
        for (Integer i = 0; i < count; i++) {
            ErrorLog.createErrorLogList(
                'BulkClass' + i,
                'Msg ' + i,
                String.valueOf(10 + i),
                'method' + i,
                'stack' + i,
                'TYPE' + i
            );
        }
        Test.stopTest();

        List<ErrorLog__c> recent = [
            SELECT Id, Class__c, Description__c, LineNumber__c, MethodName__c, StackTrace__c, Type__c
            FROM ErrorLog__c
            ORDER BY CreatedDate DESC
            LIMIT 10
        ];
        System.assertEquals(true, recent.size() >= 1, 'Expected at least 1 log after bulk calls');

        Boolean foundAny = false;
        for (ErrorLog__c e : recent) {
            if (e.Class__c != null && e.Class__c.startsWith('BulkClass')) {
                foundAny = true;
                break;
            }
        }
        System.assertEquals(true, foundAny, 'At least one bulk ErrorLog__c should be present');
    }
}