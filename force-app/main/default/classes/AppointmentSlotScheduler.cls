/**
 * @description       : Appointment Slot Scheduler
 * @author            : Hersilio Belini de Oliveira
 * @group             :
 * @last modified on  : 2025-09-05
 * @last modified by  : Hersilio Belini de Oliveira
**/
global class AppointmentSlotScheduler implements Schedulable {
    private static Integer CHUNK_DAYS = 30;
    private Integer batchSize;
    private Integer maxDays;

    public AppointmentSlotScheduler(Integer batchSize, Integer maxDays) {
        this.batchSize = batchSize;
        this.maxDays = maxDays;
    }

    global void execute(SchedulableContext sc) {
        try {

            // Remove registros antigos com mais de 30 dias
            AppointmentSlotService.removeOldSAppointmentlots(DateTime.now().addDays(-30));

            launcher();

        } catch (Exception e) {
            System.debug('Erro ao processar: ' + e.getMessage() + ' - ' + e.getStackTraceString());
        }
    }

    public void launcher(){
        List<Map<String, String>> resourceToExecute = new List<Map<String, String>>();
        Map<Id, Id> workTypeGroupMemberMap = AppointmentSlotService.getWorkTypeGroupMember();
        Set<String> resourcesUniqueIds = new Set<String>();
        List<Shift> shifts = [SELECT Id, ServiceTerritory.Name, ServiceTerritoryId, ServiceResourceId, ServiceResource.Name, WorkTypeGroupId, WorkTypeGroup.Name,
                                        TotalAllChannels__c, TotalInPerson__c, TotalOnline__c
                                                        FROM Shift
                                                       WHERE RecurrenceEndDate > TODAY
                                                         AND ServiceResource.IsActive = TRUE
                                                         AND ServiceTerritory.IsActive = TRUE
                                                         AND (TotalAllChannels__c > 0 OR TotalInPerson__c > 0 OR TotalOnline__c > 0)
                                                       ORDER BY ServiceTerritory.Name];

        for( EngagementChannelType channel : [Select Id, Name From EngagementChannelType WHERE IsActive = true]) {
            for (Shift shift : shifts) {

                for (Integer startDays = 0; startDays < maxDays ; startDays += CHUNK_DAYS) {
                    Id workTypeId = workTypeGroupMemberMap.get(shift.WorkTypeGroupId);

                    if(workTypeId == null){
                        continue;
                    }

                    Map<String, String> exec = new Map<String, String>{
                        'ChannelId' => channel.Id,
                        'ResourceId' => shift.ServiceResourceId,
                        'ResourceName' => shift.ServiceResource.Name,
                        'WorkTypeId' => workTypeId,
                        'WorkTypeGroupName' => shift.WorkTypeGroup.Name,
                        'TerritoryId' => shift.ServiceTerritoryId,
                        'TerritoryName' => shift.ServiceTerritory.Name,
                        'StartDay' => String.valueOf(startDays),
                        'EndDay' => String.valueOf(startDays + CHUNK_DAYS)
                    };

                    resourceToExecute.add(exec);
                }
            }
        }

        Map<String, AppointmentSlotSummary__c> appointmentSlotSummaryMap = AppointmentSlotService.getAppointmentSlotSummary(resourceToExecute);
        String jobId = String.valueOf(Crypto.getRandomLong());

        Database.executeBatch(new AppointmentSlotBatchable(resourceToExecute, appointmentSlotSummaryMap, jobId, maxDays), this.batchSize);
    }

    public static void scheduleJob(String cron, String name, Integer batchSize, Integer maxDays) {

        if(cron == null) {
            cron = '0 0 * * * ?'; // Executa no minuto 0 de toda hora
        }

        if(maxDays > 180) {
            maxDays = 180; // Limite máximo de dias
        } else if(maxDays < 30) {
            maxDays = 30; // Limite mínimo de dias
        }

        System.schedule(name, cron, new AppointmentSlotScheduler(batchSize, maxDays));
    }
}