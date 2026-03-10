/**
 * @description This class is a Error Log intended to validate and verify the errors on the execution of a method. 
 * This class can be extended for use in other scenarios by adjusting and creating new classes that extend from it.
 * The logs are stored in the database with the Custom Object ErrorLog__c. 
 * 
 * @author Ricardo Simões
 * @company TRH
 * @created 2025-12-17
 * @version 0.1
 */

public without sharing class ErrorLog {

    /**
     * @author Ricardo Simões
     * @created 2025-12-17
     * @description Creates and inserts a list of Error Logs in the database.
     */
    public static void createErrorLogList(String className, String message,String lineNumber,  String methodName, String stackTrace,  String type) {
        try{
            // Create a new ErrorLog__c record
            ErrorLog__c errorLog = new ErrorLog__c();
            errorLog.Class__c = className;
            errorLog.Description__c = message;
            errorLog.LineNumber__c = lineNumber;
            errorLog.MethodName__c = methodName;
            errorLog.StackTrace__c = stackTrace;
            errorLog.Type__c = type;

            insert errorLog;
        } catch (Exception e) {
            System.debug('Error trying to create an ErrorLog: ' + e);
        }
    }

}