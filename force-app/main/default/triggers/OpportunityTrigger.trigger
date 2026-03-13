/**
 * @description       : Description
 * @author            : miguel.lopes
 * @group             :
 * @create date on    : 2026-01-20 13:19:00
 * @last modified by  : miguel.lopes
 **/
trigger OpportunityTrigger on Opportunity (before delete) {
    if(Trigger.isBefore && Trigger.isDelete) {
        TransactionTriggerHandler.opportunityTriggerhandler(Trigger.oldMap.keySet());
    }
}