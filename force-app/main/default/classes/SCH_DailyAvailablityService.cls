/**
 * @description This class handles the retrieval of available dates for appointment slots based on work type and store.
 * 
 * @author Felipe Gil
 * @date [2025-07-30]
 * @version 0.2
 */

public without sharing class SCH_DailyAvailablityService { 

    /* 
    @description This method retrieves the count of available appointment slots per day for a given date range, work type, store, and engagement channel type. It also considers full day holidays as unavailable dates.
    
    @param startDate The start date for the availability check.
    @param endDate The end date for the availability check.
    @param workTypeIds The IDs of the work types to filter available dates.
    @param storeId The ID of the store to filter available dates.
    @param engagementChannelTypeId The ID of the engagement channel type to filter available dates. 
    
    */
    public static Map<Date, Integer> getAppointmentSlotCountPerDay(Date startDate, Date endDate, List<Id> workTypeIds, Id storeId, Id engagementChannelTypeId) {
        List<AggregateResult> slots = [SELECT StartDate__c, COUNT(Id) slotCount FROM AppointmentSlot__c 
        WHERE StartDate__c >= :startDate 
        AND StartDate__c <= :endDate
        AND Available__c = true 
        AND AppointmentSlotSummary__r.WorkType__c IN :workTypeIds 
        AND AppointmentSlotSummary__r.ServiceTerritory__c = :storeId
        AND AppointmentSlotSummary__r.EngagementChannelType__c = :engagementChannelTypeId
        GROUP BY StartDate__c 
        ORDER BY StartDate__c DESC];

        if (slots.isEmpty()) return new Map<Date, Integer>(); 
        
        Map<Date, Integer> availableDatesMap = new Map<Date, Integer>();
        for (AggregateResult slot : slots) {
            Date slotDate = (Date)slot.get('StartDate__c');
            Integer slotCount = (Integer)slot.get('slotCount');
            availableDatesMap.put(slotDate, slotCount);
        }

        List<Holiday> holidays = [SELECT ActivityDate FROM Holiday WHERE ActivityDate >= :startDate AND ActivityDate <= :endDate AND IsAllDay = true];
        
        if (holidays != null && !holidays.isEmpty()){
            for (Holiday holiday : holidays){
                availableDatesMap.remove(holiday.ActivityDate);
            }
        }

        return availableDatesMap;
    }
}