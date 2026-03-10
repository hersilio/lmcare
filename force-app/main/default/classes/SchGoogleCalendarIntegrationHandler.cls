/**
 * @description This class interfaces bewteen Google Calendar and Salesforce Scheduler to retrieve unavailable time slots for service resources.
 * 
 * @author Felipe Gil
 * @company TRH
 * @created 2025-08-05
 * @version 0.3
 * @see GoogleCalendarAPIController
 */

public with sharing class SchGoogleCalendarIntegrationHandler implements LxScheduler.ServiceResourceScheduleHandler{

    public static List<LxScheduler.ServiceResourceSchedule> getUnavailableTimeSlots(lxscheduler.ServiceAppointmentRequestInfo requestInfo){

        List<lxscheduler.ServiceResourceSchedule> resourceUnavailability = new List<lxscheduler.ServiceResourceSchedule>();
        
        PerformanceLog log = new PerformanceLog('GoogleCalendar API Log');
        log.description = 'Measure latency in processing Google Calendar API callouts.';
        log.methodName = 'SchGoogleCalendarIntegrationHandler.getUnavailableTimeSlots';
        log.addLogEntry('Method start. Processing users to get free busy info.');
        
        Datetime timeMin = requestInfo.getStartDate();
        Datetime timeMax = requestInfo.getEndDate(); 
        
        List<String> userEmails = new List<String>();
        for (lxScheduler.ServiceResourceInfo sr : requestInfo.getServiceResources()) {
            userEmails.add(sr.getEmail());
        }

        log.addLogEntry('Finished processing users to get free busy info. Getting free busy info now.');

        List<GoogleCalendarAPIController.FreeBusyResponseWrapper> freeBusyResponses = GoogleCalendarAPIController.batchGetFreeBusyInfo(userEmails, timeMin, timeMax);
        
        log.addLogEntry('Finished getting free busy info. Extracting unavailable time slots now.');

        
        if (freeBusyResponses == null || freeBusyResponses.isEmpty()) {
            System.debug('No free/busy information found for the provided users.');
            return resourceUnavailability;
        }

        // Combine all calendars from the free busy responses
        // Each response contains a map of calendars keyed by user email
        Map<String, GoogleCalendarAPIController.CalendarInfo> allCalendars = new Map<String, GoogleCalendarAPIController.CalendarInfo>();
        for (GoogleCalendarAPIController.FreeBusyResponseWrapper resp : freeBusyResponses) {
            if (resp != null && resp.calendars != null) {
                allCalendars.putAll(resp.calendars);
            }
        }

        for (lxScheduler.ServiceResourceInfo sr : requestInfo.getServiceResources()) {
            String userEmail = sr.getEmail();
            if (!allCalendars.containsKey(userEmail)) {
                continue;
            }
            GoogleCalendarAPIController.CalendarInfo calendar = allCalendars.get(userEmail);
            if (calendar.busy == null || calendar.busy.isEmpty()) {
                continue;
            }
            Set<lxscheduler.UnavailableTimeslot> unavailabilityIntervals = extractUnavailableTimeslots(calendar);
            resourceUnavailability.add(new lxscheduler.ServiceResourceSchedule(sr.getServiceResourceId(), unavailabilityIntervals));
        }
        
        log.addLogEntry('Finished extracting unavailable time slots. Method end.');
        log.numUsersChecked = userEmails.size();
        log.numSlotsRetrieved = resourceUnavailability.size();

        log.printLogEntries();
        
        LM_AppointmentSlotExecutionContext.addLog(log);
        
        return resourceUnavailability;
    }

    /* Extracts unavailable timeslots from a Google Calendar response.
     * 
     * @param calendar The Google Calendar response containing busy times.
     * @return A set of UnavailableTimeslot objects representing the unavailable time slots.
     */
    private static Set<lxscheduler.UnavailableTimeslot> extractUnavailableTimeslots(GoogleCalendarAPIController.CalendarInfo calendar) {
        Set<lxscheduler.UnavailableTimeslot> unavailabilityIntervals = new Set<lxscheduler.UnavailableTimeslot>();
        for (GoogleCalendarAPIController.BusyTime busy : calendar.busy) {
            if (busy.startGcal == null || busy.endGcal == null) {
                continue;
            }
            Datetime startTime = Datetime.valueOfGmt(busy.startGcal.replace('T', ' ')); 
            Datetime endTime = Datetime.valueOfGmt(busy.endGcal.replace('T', ' '));
            lxscheduler.UnavailableTimeslot timeSlot = new lxscheduler.UnavailableTimeslot(startTime, endTime);
            unavailabilityIntervals.add(timeSlot);
        }
        return unavailabilityIntervals;
    }

}