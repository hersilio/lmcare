/**
 * @description       : Service Appointment Trigger Class
 * @author            : miguel.lopes
 * @group             :
 * @create date on    : 2026-02-04 16:16:40
 * @last modified by  : miguel.lopes
 **/
trigger ServiceAppointmentTrigger on ServiceAppointment (after insert, after update, before insert, before update ) {

    if(Trigger.isBefore){
        if(Trigger.isInsert){
            ServiceAppointmentTriggerHandler.handleBeforeInsert(Trigger.new);
        }
    }

    if(Trigger.isAfter){
        if(Trigger.isInsert){
            ServiceAppointmentTriggerHandler.handleAfterInsert(Trigger.new, Trigger.newMap);

        }
        if(Trigger.isUpdate){
            ServiceAppointmentTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}