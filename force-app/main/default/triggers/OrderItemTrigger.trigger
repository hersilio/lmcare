/**
 * @description       : Description
 * @author            : miguel.lopes
 * @group             :
 * @create date on    : 2026-01-19 14:14:03
 * @last modified by  : miguel.lopes
 **/
trigger OrderItemTrigger on OrderItem (after insert, after update, after delete, after undelete) {
    
    if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete || Trigger.isDelete)) {
        List<OrderItem> targetOrderItems = Trigger.isInsert ? Trigger.new : Trigger.isUpdate ? Trigger.new : Trigger.old;
        TransactionTriggerHandler.orderItemTriggerhandler(targetOrderItems);
    }
}