/**
 * @description       : 
 * @author            : Hersilio Belini de Oliveira
 * @group             : 
 * @last modified on  : 2025-09-01
 * @last modified by  : Hersilio Belini de Oliveira
**/
public with sharing class UpdateExpiradeSlotScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        // Chama a lógica separada
        // AppointmentSlotService.updateExpiredSlots();
    }

    public static void scheduleHourlyJob(String name) {
        // String cron = '0 0 * * * ?'; // Executa no minuto 0 de toda hora
        // System.schedule(name, cron, new UpdateExpiradeSlotScheduler());
    }
}