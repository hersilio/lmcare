/**
 * @description       : Description
 * @author            : miguel.lopes
 * @group             :
 * @create date on    : 2025-12-29 10:32:55
 * @last modified by  : miguel.lopes
 **/
public with sharing class PyxisAPIServiceAssyncJobs implements Queueable {
    
    public String transactionType;
    public PyxisAssyncJobsWrapper parameters;

    public PyxisAPIServiceAssyncJobs(String transactionType, PyxisAssyncJobsWrapper parameters){
        this.transactionType = transactionType;
        this.parameters = parameters;
    }
    
    public void execute(QueueableContext context) {
        switch on transactionType {
            when 'QUOTES'  {
                System.debug('Executing QUOTES assync job');
                PyxisAPIServiceHandler.checkExpiredQuotes(parameters.opportunities);
                PyxisAPIServiceHandler.setStoreId(parameters.recordsInserted);
                PyxisAPIServiceHandler.setUser(parameters.recordsInserted, new Map <String, String>{ 
                    'CreatedByUser__c' => 'LDAPcreatedByUser__c',
                    'InternalMessageCreatedBy__c' => 'InternalMessageCreatedBy_LDAP__c'
                });
            }
            when 'QUOTE_LINES_ITEMS'  {
                System.debug('Executing QUOTE_LINES_ITEMS assync job');
                PyxisAPIServiceHandler.setStoreId(parameters.recordsInserted);
            }
            when 'PRODUCT_ORDER'  {
                TransactionTriggerHandler.skipTriggerExecution = true;
                System.debug('Executing PRODUCT_ORDER assync job');
                PyxisAPIServiceHandler.setStoreId(parameters.recordsInserted);
                PyxisAPIServiceHandler.setUser(parameters.recordsInserted, new Map <String, String>{ 
                    'CreatedByUser__c' => 'LDAPcreatedByUser__c',
                    'InternalMessageCreatedBy__c' => 'InternalMessageCreatedBy_LDAP__c'
                });
                TransactionTriggerHandler.skipTriggerExecution = false;
                System.debug('PRODUCT_ORDER assync job - FINISHED');
            }
            when 'PRODUCT_ORDER_ITEMS' {
                TransactionTriggerHandler.skipTriggerExecution = true;
                System.debug('Executing PRODUCT_ORDER_ITEMS assync job');
                PyxisAPIServiceHandler.checkCode49(parameters.checkCode49); // CHECK IF CODE 49
                PyxisAPIServiceHandler.checkOrderAllValidated(parameters.opportunities); // CHECK IF ALL ORDER VALID
                PyxisAPIServiceHandler.setStoreId(parameters.recordsInserted);
                PyxisAPIServiceHandler.setUser(parameters.recordsInserted, new Map <String, String>{ 
                    'CreatedByUser__c' => 'LDAPcreatedByUser__c', 
                    'LastModifiedByUser__c' => 'LDAPlastModifiedByUser__c'
                });
                System.debug('PRODUCT_ORDER_ITEMS assync job - FINISHED');
                TransactionTriggerHandler.skipTriggerExecution = false;
            }
            when 'SALE_NOTE'  {
                TransactionTriggerHandler.skipTriggerExecution = true;
                System.debug('Executing SALE_NOTE assync job');
                PyxisAPIServiceHandler.setStoreId(parameters.recordsInserted);
                PyxisAPIServiceHandler.setUser(parameters.recordsInserted, new Map <String, String>{ 
                    'CreatedByUser__c' => 'LDAPcreatedByUser__c',
                    'InternalMessageCreatedBy__c' => 'InternalMessageCreatedBy_LDAP__c'
                });
                System.debug('SALE_NOTE assync job - FINISHED');
                TransactionTriggerHandler.skipTriggerExecution = false;
            }
            when 'SALE_NOTE_ITEMS' {
                TransactionTriggerHandler.skipTriggerExecution = true;
                System.debug('Executing SALE_NOTE_ITEMS assync job');
                PyxisAPIServiceHandler.checkCode49(parameters.checkCode49); // CHECK IF CODE 49
                PyxisAPIServiceHandler.checkOrderAllValidated(parameters.opportunities); // CHECK IF ALL ORDER VALID
                PyxisAPIServiceHandler.setUser(parameters.recordsInserted, new Map <String, String>{ 
                    'CreatedByUser__c' => 'LDAPcreatedByUser__c', 
                    'LastModifiedByUser__c' => 'LDAPlastModifiedByUser__c'
                });
                System.debug('SALE_NOTE_ITEMS assync job - FINISHED');
                TransactionTriggerHandler.skipTriggerExecution = false;

            }
            when else {
                System.debug('No matching transaction type for assync job: ' + transactionType);
            }
        }
    }

    public class PyxisAssyncJobsWrapper{
        public List<SObject> recordsInserted;
        public List<Opportunity> opportunities;
        public List<PyxisAPIServiceHandler.OrderCode49Wrapper> checkCode49;
        // public Map <SObject, String >

        public PyxisAssyncJobsWrapper(List<SObject> recordsInserted, List<Opportunity> opportunities, List<PyxisAPIServiceHandler.OrderCode49Wrapper> checkCode49){
            this.recordsInserted = recordsInserted;
            this.opportunities = opportunities;
            this.checkCode49 = checkCode49;
        }
    }
}