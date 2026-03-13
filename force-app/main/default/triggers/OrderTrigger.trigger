/**
 * @description       : Description
 * @author            : miguel.lopes
 * @group             :
 * @create date on    : 2026-01-19 18:22:07
 * @last modified by  : miguel.lopes
 **/
trigger OrderTrigger on Order (after update, after delete, after undelete) {
    
    if(Trigger.isAfter && (Trigger.isUpdate || Trigger.isUndelete || Trigger.isDelete)) {
        List<Order> targetOrders = Trigger.isInsert ? Trigger.new : Trigger.isUpdate ? Trigger.new : Trigger.old;
        TransactionTriggerHandler.orderTriggerhandler(targetOrders);
    }
}