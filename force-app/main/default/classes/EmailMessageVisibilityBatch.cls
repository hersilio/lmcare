/**
 * @description Batch Apex to set EmailMessage.IsExternallyVisible = true
 *              for records where IsExternallyVisible = false and RelatedToId != null.
 *              Only runs if TempValidation__mdt.EmailMessageBatchActivation.IsActive__c = true.
 * @author Ricardo Simões
 * @group Service
 */
public with sharing class EmailMessageVisibilityBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    public Integer totalProcessed = 0;
    
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Verificar flag da Custom Metadata ANTES do start
        String soql = 'SELECT Id, IsExternallyVisible ' +
            'FROM EmailMessage ' +
            'WHERE IsExternallyVisible = false ' +
            'AND RelatedToId != null ';
        return Database.getQueryLocator(soql);
    }
    
    public void execute(Database.BatchableContext bc, List<EmailMessage> scope) {
        if (scope == null || scope.isEmpty()) {
            return;
        }
        
        List<EmailMessage> toUpdate = new List<EmailMessage>();
        for (EmailMessage em : scope) {
            if (em == null) continue;
            em.IsExternallyVisible = true;
            toUpdate.add(em);
        }
        
        if (toUpdate.isEmpty()) {
            return;
        }
        
        totalProcessed += toUpdate.size();
        
        Database.SaveResult[] results = Database.update(toUpdate, false);
        for (Integer i = 0; i < results.size(); i++) {
            Database.SaveResult sr = results[i];
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO,
        'EmailMessageVisibilityBatch Summary - Processed: ' + totalProcessed);
    }
    
    public static Id run(Integer scopeSize) {
        Integer sizeToUse = (scopeSize == null || scopeSize <= 0) ? 200 : scopeSize;
        return Database.executeBatch(new EmailMessageVisibilityBatch(), sizeToUse);
    }
}