/**
 * @description  REST service for retrieving daily availability dates.
 * @author Felipe Gil
 * @version 0.1
 * @date [2025-07-31]  
 * @urlMapping   /services/apexrest/dailyAvailability/*
 * @param startDate The start date for the availability check in 'yyyy-MM-dd' format.
 * @param endDate The end date for the availability check in 'yyyy-MM-dd' format.
 * @param workTypeId The ID of the work type to filter available dates.
 * @param storeId The ID of the store to filter available dates.
 * @param engagementChannelTypeId The ID of the engagement channel type to filter available dates.
 * Returns a JSON response with available dates and their corresponding appointment slot counts.
 */


@RestResource(urlMapping='/dailyAvailability/*')
global with sharing class SCH_DailyAvailablityController {

    @HttpGet 
    global static void getAvailableDates() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        String startDateStr = req.params != null && req.params.containsKey('startDate') ? req.params.get('startDate') : null;
        String endDateStr = req.params != null && req.params.containsKey('endDate') ? req.params.get('endDate') : null;

        String workTypeGroupId = req.params != null && req.params.containsKey('workTypeGroupId') ? String.escapeSingleQuotes(req.params.get('workTypeGroupId')) : null;
        String storeId = req.params != null && req.params.containsKey('storeId') ? String.escapeSingleQuotes(req.params.get('storeId')) : null;
        String engagementChannelTypeId = req.params != null && req.params.containsKey('engagementChannelTypeId') ? String.escapeSingleQuotes(req.params.get('engagementChannelTypeId')) : null;    

        // Invalid or missing parameter cases:

        if (String.isBlank(startDateStr) || String.isBlank(endDateStr) || String.isBlank(workTypeGroupId) || String.isBlank(storeId) || String.isBlank(engagementChannelTypeId)) {
            res.statusCode = 400;
            if (req.params == null || req.params.isEmpty()) {
                res.responseBody = Blob.valueOf('{"error":"No parameters provided. Required: startDate, endDate, (format YYYY-MM-DD) workTypeGroupId, storeId, engagementChannelTypeId."}');
            } else {
                List<String> missingParams = new List<String>();
                if (String.isBlank(startDateStr)) missingParams.add('startDate');
                if (String.isBlank(endDateStr)) missingParams.add('endDate');
                if (String.isBlank(workTypeGroupId)) missingParams.add('workTypeGroupId');
                if (String.isBlank(storeId)) missingParams.add('storeId');
                if (String.isBlank(engagementChannelTypeId)) missingParams.add('engagementChannelTypeId');
                res.responseBody = Blob.valueOf('{"error":"Missing required parameter(s): ' + String.join(missingParams, ', ') + '"}');
            }
            return;
        }
        try {
            Date.valueOf(startDateStr);
            Date.valueOf(endDateStr);
        } catch (Exception ex) {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf('{"error":"Invalid date format. Use YYYY-MM-DD."}');
            return;
        }
        try{
            Id workTypeGroupIdParsed = (Id) workTypeGroupId;
            Id storeIdParsed = (Id) storeId;
            Id engagementChannelTypeIdParsed = (Id) engagementChannelTypeId;
        } catch (Exception ex) {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf('{"error":"Invalid parameter format. Ensure workTypeGroupId, storeId, and engagementChannelTypeId are valid Salesforce IDs."}');
            return;
        }
        
        List<Id> workTypeIds = new List<Id>();
        List<WorkTypeGroupMember> workTypeGroupMembers = [SELECT WorkTypeId FROM WorkTypeGroupMember WHERE WorkTypeGroupId = :workTypeGroupId];
        for (WorkTypeGroupMember wtg : workTypeGroupMembers) {
            workTypeIds.add(wtg.WorkTypeId);
        }

        // Check for daily AppointmentSlots
        Map<Date, Integer> appointmentSlotCountPerDay = SCH_DailyAvailablityService.getAppointmentSlotCountPerDay(
            Date.valueOf(startDateStr),
            Date.valueOf(endDateStr),
            workTypeIds,
            storeId,
            engagementChannelTypeId
        );
        // No Slots Available
        if (appointmentSlotCountPerDay.isEmpty()) {
            res.statusCode = 404;
            res.responseBody = Blob.valueOf('{"message":"No available dates found for the specified criteria."}');
            return;
        }
        // Slots Available
        res.statusCode = 200;
        res.responseBody = Blob.valueOf(JSON.serialize(appointmentSlotCountPerDay));
        return;
    }
}