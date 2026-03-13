/**
 * @description       : Description
 * @author            : miguel.lopes
 * @group             :
 * @create date on    : 2026-01-22 14:48:03
 * @last modified by  : miguel.lopes
 **/
public with sharing class TransactionTriggerHandler {
    public static Boolean skipTriggerExecution = false;
    
    public static void orderItemTriggerhandler(List<OrderItem> orderItems){
        if(!TransactionTriggerHandler.skipTriggerExecution){
            System.debug('ORDER ITEM TRIGGER FIRED');
            Set<Id> oppIds = new Set<Id>();
            List<OrderItem> targetOrderItems = orderItems;
            Set<Id> ordersIds = new Set<Id>();
            for (OrderItem oi : targetOrderItems) {
                ordersIds.add(oi.OrderId);
            }
            List<Order> parentOrders = [SELECT Id, OpportunityId FROM Order WHERE Id IN : ordersIds];
            for (Order parentOrder : parentOrders) {
                oppIds.add(parentOrder.OpportunityId);
            }
            PyxisAPIServiceHandler.setTotalAmountOpp(oppIds);
            System.debug('ORDER ITEM TRIGGER FINISHED');
        }
    }
    
    public static void orderTriggerHandler(List<Order> orders){
        if(!TransactionTriggerHandler.skipTriggerExecution){
            System.debug('ORDER TRIGGER FIRED');
            Set<Id> oppIds = new Set<Id>();
            List<Order> targetOrders = orders;
            for (Order parentOrder : targetOrders) {
                if(parentOrder.OpportunityId != null){
                    oppIds.add(parentOrder.OpportunityId);
                }
            }
            PyxisAPIServiceHandler.setTotalAmountOpp(oppIds);
            System.debug('ORDER TRIGGER FINISHED');
        }
    }
    
    public static void opportunityTriggerhandler(Set<Id> opportunityIds){
        System.debug('DELETE - OPPPORTUNITIES TRIGGER');
        TransactionTriggerHandler.skipTriggerExecution = true;
        PyxisAPIServiceHandler.deleteOppOrders(opportunityIds);
        TransactionTriggerHandler.skipTriggerExecution = false;
        System.debug('DELETE - OPPPORTUNITIES TRIGGER - FINISHED');

    }
}