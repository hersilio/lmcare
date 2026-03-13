/**
 * @description       : Appointment Slot Service
 * @author            : Hersilio Belini de Oliveira
 * @group             :
 * @last modified on  : 2025-09-01
 * @last modified by  : Hersilio Belini de Oliveira
**/
public with sharing class AppointmentSlotService {

    /**
    * @description create next appointment slots
    * @author Hersilio Belini de Oliveira | 2025-05-14
    * @param allResourceToExecute
    * @param offset
    * @param endIndex
    **/
    public static void createNextAppointmentSlots(List<Map<String, String>> resourceToExecute, Map<String, AppointmentSlotSummary__c> appSlotSummaryMap, String jobId) {
        Long t0 = System.now().getTime();

        Map<String, AppointmentSlot__c> appSlotMapToInsert = new Map<String, AppointmentSlot__c>();

        System.debug('Creating Appointment Slots for ' + resourceToExecute.size() + ' resources.');

        for (Map<String, String> currentResourceToExecute : resourceToExecute) {

            Id channelId = currentResourceToExecute.get('ChannelId');
            Id resourceId = currentResourceToExecute.get('ResourceId');
            Id workTypeId = currentResourceToExecute.get('WorkTypeId');
            Id territoryId = currentResourceToExecute.get('TerritoryId');
            Integer startDay = Integer.valueOf(currentResourceToExecute.get('StartDay'));
            Integer endDay = Integer.valueOf(currentResourceToExecute.get('EndDay'));

            System.debug('[channelId:' + channelId + '][resourceId:' + resourceId + '][workTypeId:' + workTypeId + '][territoryId:' + territoryId + '][' + startDay + '][' + endDay + '] Creating...');

            try{

                if(channelId == null || resourceId == null || workTypeId == null || territoryId == null){
                    throw new AppointmentSlotServiceException('[' + channelId + '][' + resourceId + '][' + workTypeId + '][' + territoryId + '] channelId, resourceId, workTypeId or territoryId Id is NULL');
                }

                DateTime startTime = System.now().addDays(startDay);
                DateTime endTime = System.now().addDays(endDay);

                lxscheduler.WorkType workType = new lxscheduler.WorkTypeBuilder().setId(workTypeId).build();

                LxScheduler.GetAppointmentSlotsInput input =
                    new LxScheduler.GetAppointmentSlotsInputBuilder()
                        .setWorkType(workType)
                        .setTerritoryIds(new List<String>{ territoryId })
                        .setEngagementChannelTypeIds(new List<String>{ channelId })
                        .setRequiredResourceIds(new List<String>{ String.valueOf(resourceId) })
                        .setStartTime(startTime.format('yyyy-MM-dd\'T\'HH:mm:ssZ'))
                        .setEndTime(endTime.format('yyyy-MM-dd\'T\'HH:mm:ssZ'))
                        .build();

                String result = lxscheduler.SchedulerResources.getAppointmentSlots(input);

                if (Test.isRunningTest()) {
                    result = '[{"territoryId":"' + territoryId + '","startTime":"2030-05-21T14:00:00.000Z","endTime":"2030-05-21T15:00:00.000Z","engagementChannelTypeIds":["' + channelId + '"],"remainingAppointments":1}]';
                }

                if(result != null && result != ''){
                    createAppointmentSlots(appSlotMapToInsert, appSlotSummaryMap, result, resourceId, workTypeId, channelId, jobId);
                }
            } catch(exception ex){
                //Error Log here 
                ErrorLog.createErrorLogList('AppointmentSlotBatchable', ex.getMessage(), ex.getLineNumber().toString(), 'AppointmentSlotBatchable.finish', ex.getStackTraceString(), ex.getTypeName());
                //System.debug('[channelId:' + channelId + '][resourceId:' + resourceId + '][workTypeId:' + workTypeId + '][territoryId:' + territoryId + '][' + startDay + '][' + endDay + ']  ERROR: ' + ex.getMessage() + ' - ' + ex.getStackTraceString());
            }
        }

        System.debug('Appointment Slots to upsert: ' + appSlotMapToInsert.size());

        if(!appSlotMapToInsert.isEmpty()){
            upsert appSlotMapToInsert.values() UniqueKey__c;
        }
    }

    public static Map<Id, Id> getWorkTypeGroupMember(){

        Map<Id, Id> workTypeGroupIdToWorkTypeMap = new Map<Id, Id>();
        for(WorkTypeGroupMember workGroupMember : [SELECT Id, WorkTypeGroup.Id, WorkType.Id FROM WorkTypeGroupMember]){
            workTypeGroupIdToWorkTypeMap.put(workGroupMember.WorkTypeGroup.Id, workGroupMember.WorkType.Id);
        }

        return workTypeGroupIdToWorkTypeMap;
    }

    /**
    * @description Create Appointment Slots Returned by LxScheduler
    * @author Hersilio Belini de Oliveira | 2025-05-08
    * @param jsonInput
    * @param slotsToInsert
    **/
    public static void createAppointmentSlots(Map<String, AppointmentSlot__c> appSlotMapToInsert, Map<String, AppointmentSlotSummary__c> appointmentSlotSummariesMap, String jsonInput, String resourceId, Id workTypeId, Id channelId, String jobId) {
        List<Object> slotList = (List<Object>) JSON.deserializeUntyped(jsonInput);
        Date today = Date.today();
        Date tomorrow = today.addDays(1); 

        for (Object slotObj : slotList) {
            Map<String, Object> slotMap = (Map<String, Object>) slotObj;

            if (!slotMap.containsKey('territoryId') ||
                !slotMap.containsKey('startTime') ||
                !slotMap.containsKey('endTime') ||
                !slotMap.containsKey('engagementChannelTypeIds')) {
                continue;
            }
            List<Object> engagementChannelTypeIds = (List<Object>) slotMap.get('engagementChannelTypeIds');

            if (engagementChannelTypeIds == null || engagementChannelTypeIds.isEmpty()) {
                continue;
            }

            String territoryId = (String) slotMap.get('territoryId');
            String startTime = (String) slotMap.get('startTime');
            String endTime = (String) slotMap.get('endTime');

            AppointmentSlotSummary__c appointSlotSummary = appointmentSlotSummariesMap.get(getUniqueKeySummary(channelId, workTypeId, territoryId));

            if(appointSlotSummary == null){
                throw new AppointmentSlotServiceException(
                    '[' + channelId + '][' + workTypeId + '][' + territoryId + '] Appointment Slot Summary Id NOT FOUND');
            }

            String uniqueKey = getUniqueKeySlotResource(resourceId, territoryId, channelId, workTypeId, startTime, endTime);



            AppointmentSlot__c newSlot = new AppointmentSlot__c();
            newSlot.ServiceResource__c = resourceId;
            newSlot.AppointmentSlotSummary__c = appointSlotSummary.Id;
            newSlot.Available__c = true;
            newSlot.UniqueKey__c = uniqueKey;
            newSlot.StartTime__c = getDateTime(startTime);
            newSlot.EndTime__c = getDateTime(endTime);
            newSlot.StartDate__c = getDate(startTime);
            newSlot.JobId__c = jobId;

            newSlot.IsToday__c = (newSlot.StartDate__c == today);
            newSlot.IsTomorrow__c = (newSlot.StartDate__c == tomorrow);
            
            appSlotMapToInsert.put(uniqueKey, newSlot);
        }
    }

    /**
    * @description create appointment slot summary
    * @author Hersilio Belini de Oliveira | 2025-05-13
    * @param channelId
    * @param workTypeId
    * @param territoryIds
    **/
    public static Map<String, AppointmentSlotSummary__c> getAppointmentSlotSummary(List<Map<String, String>> resourceToExecute) {

        Map<String, AppointmentSlotSummary__c> appSlotSummaryMap = new Map<String, AppointmentSlotSummary__c>();
        for(AppointmentSlotSummary__c appSlotSummary : [SELECT Id, UniqueKey__c, ServiceTerritory__c, WorkType__c, EngagementChannelType__c
                                                          FROM AppointmentSlotSummary__c]) {
            appSlotSummaryMap.put(appSlotSummary.UniqueKey__c, appSlotSummary);
        }

        Map<String, AppointmentSlotSummary__c> appSlotSummaryToInsert = new Map<String, AppointmentSlotSummary__c>();

        for (Map<String, String> currentResourceToExecute : resourceToExecute) {
            Id workTypeId = currentResourceToExecute.get('WorkTypeId');
            Id territoryId = currentResourceToExecute.get('TerritoryId');
            Id channelId = currentResourceToExecute.get('ChannelId');

            String uniqueKey = getUniqueKeySummary(channelId, workTypeId, territoryId);

            if(appSlotSummaryMap.containsKey(uniqueKey)){
                continue;
            }

            AppointmentSlotSummary__c appSlotSummary = new AppointmentSlotSummary__c(
                ServiceTerritory__c = territoryId,
                WorkType__c = workTypeId,
                EngagementChannelType__c = channelId,
                UniqueKey__c = uniqueKey
            );

            appSlotSummaryToInsert.put(uniqueKey, appSlotSummary);
            appSlotSummaryMap.put(uniqueKey, appSlotSummary);
        }

        if(appSlotSummaryToInsert.size() > 0){
            insert appSlotSummaryToInsert.values();
        }

        return appSlotSummaryMap;
    }

    /**
    * @description get unique key summary
    * @author Hersilio Belini de Oliveira | 2025-05-30
    * @param channelId
    * @param workTypeId
    * @param territoryId
    * @return String
    **/
    private static String getUniqueKeySummary(String channelId, String workTypeId, String territoryId) {
        return channelId + '|' + workTypeId + '|' + territoryId;
    }

    /**
    * @description get unique key slot resource
    * @author Hersilio Belini de Oliveira | 2025-06-30
    * @param resourceId
    * @param channelId
    * @param workTypeId
    * @param territoryId
    * @param startTime
    * @param endTime
    * @return String
    **/
    public static String getUniqueKeySlotResource(Id resourceId, Id channelId, Id workTypeId, Id territoryId, String startTime, String endTime) {
        return resourceId + '|' + territoryId + '|' + channelId + '|' + workTypeId + '|' + getDateTime(startTime).format() + '|' + getDateTime(endTime).format();
    }

    /**
    * @description to date time from string
    * @author Hersilio Belini de Oliveira | 2025-06-30
    * @param dateTimeStr
    * @return String
    **/
    private static Datetime getDateTime(String dateTimeStr) {
        if (dateTimeStr == null || String.isEmpty(dateTimeStr)) {
            return null;
        }

        return Datetime.valueOfGmt(dateTimeStr.replace('T', ' ').replace('Z', ''));
    }

    /**
    * @description to date from string
    * @author Hersilio Belini de Oliveira | 2025-06-30
    * @param dateTimeStr
    * @return String
    **/
    private static Date getDate(String dateTimeStr) {
        if (dateTimeStr == null || String.isEmpty(dateTimeStr)) {
            return null;
        }

        return Datetime.valueOfGmt(dateTimeStr.replace('T', ' ').replace('Z', '')).date();
    }

    /**
    * @description Remove Old Appointment Slots
    * @author Hersilio Belini de Oliveira | 2025-05-15
    **/
    public static void removeOldSAppointmentlots(DateTime dataLimite) {

        List<AppointmentSlot__c> slotsAntigos = [SELECT Id FROM AppointmentSlot__c WHERE StartTime__c < :dataLimite LIMIT 10000];

        if (!slotsAntigos.isEmpty()) {
            DELETE slotsAntigos;
        }
    }

    public class AppointmentSlotServiceException extends Exception {
    }
}