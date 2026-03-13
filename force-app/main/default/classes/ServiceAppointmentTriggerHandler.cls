/**
 * @description       : Description
 * @author            : miguel.lopes
 * @group             :
 * @create date on    : 2026-02-05 18:03:58
 * @last modified by  : miguel.lopes
 **/
public with sharing class ServiceAppointmentTriggerHandler {


        public static void handleAfterInsert(List<ServiceAppointment> newList, Map<Id, ServiceAppointment> newMap)
    {
        // ServiceAppointmentTriggerHelper.invalidateSlotsAfterInsert(newList);
        ServiceAppointmentTriggerHelper.sendNotificationsAfterInsert(newList);
        ServiceAppointmentTriggerHelper.sentToADEO(newMap.keySet());
    }

    public static void handleAfterUpdate(List<ServiceAppointment> newList,Map<Id, ServiceAppointment> oldMap)
    {
        // ServiceAppointmentTriggerHelper.invalidateSlotsAfterUpdate(newList, oldMap);
        ServiceAppointmentTriggerHelper.sendNotificationsAfterUpdate(newList, oldMap);
        ServiceAppointmentTriggerHelper.sentToADEO(oldMap.keySet());
    }

      public static void handleBeforeInsert(List<ServiceAppointment> newList)
    {
        ServiceAppointmentTriggerHelper.setUUID(newList);
    }
}