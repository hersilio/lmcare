/**
 * @description       : This class handles the callout to Google Calendar API to fetch Hangout links for Service Appointments.
 * @author            : Joana Rodrigues
 * @company           : TRH
 * @last modified on  : 18/03/2025
 * @last modified by  : Felipe Gil
 * @version           : 2.0
 * @changelog         : Removed future method and cleaned up class
**/

public without sharing class SCH_callOut {
    @InvocableMethod(label='Get SA Hangout Link' description='Get hangout link for online Service Appointments')
    public static void SCH_callOut(List<ServiceAppointment> appointments) {
        for (ServiceAppointment sa : appointments){
            SCH_Meeting(sa);
        }
    }

    public static void SCH_Meeting(ServiceAppointment sa) {
        System.debug('Meeting Callout ML Env');
        String numeroAppointment = sa.AppointmentNumber;
        Datetime dataInicio = sa.SchedStartTime;
        Datetime dataFim = sa.SchedEndTime;

        Timezone tz = UserInfo.getTimeZone();
        Long milliseconds = tz.getOffset(dataInicio);
        Long mins = milliseconds / 60000;
        Long hours = mins / 60;
        Long remainingMins = mins - (hours * 60);

        String sign = hours >= 0 ? '+' : '-';
        Long absHours = Math.abs(hours);
        Long absMinutes = Math.abs(remainingMins);

        // Manually pad the hours and minutes with leading zeros if necessary
        String formattedHours = (absHours < 10 ? '0' : '') + String.valueOf(absHours);
        String formattedMinutes = (absMinutes < 10 ? '0' : '') + String.valueOf(absMinutes);

        String totalTime = sign + formattedHours + ':' + formattedMinutes;
        String dataInicioString = dataInicio.format('yyyy-MM-dd\'T\'HH:mm:ss') + totalTime;
        String dataFimString = dataFim.format('yyyy-MM-dd\'T\'HH:mm:ss') + totalTime;

        String params = '';

        if (numeroAppointment != null && numeroAppointment != '') {
            params += 'q=' + EncodingUtil.urlEncode(numeroAppointment, 'UTF-8');
        }
        if (dataInicioString != null) {
            params += '&timeMin=' + EncodingUtil.urlEncode(dataInicioString, 'UTF-8');
        }
        if (dataFimString != null) {
            params += '&timeMax=' + EncodingUtil.urlEncode(dataFimString, 'UTF-8');
        }
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        HttpResponse response;

        // Construct the API call endpoint dynamically using the user's ID or email
        String userEmail = sa.Owner.Email != null ? sa.Owner.Email : 'default@example.com';
        System.debug('user email: ' + userEmail);
        request.setEndpoint('callout:SCH_google_calendar_legacy/calendar/v3/calendars/' + userEmail + '/events?' + params);
        request.setHeader('Content-Type', 'application/json; charset=utf-8');
        request.setMethod('GET');
        request.setTimeout(20000);
        String hangoutLink = '';

        try {
            response = http.send(request);
            System.debug('Response: ' + response);
            if (response.getStatusCode() == 200 ) {
                Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                List<Object> items = (List<Object>) results.get('items');
                if (!items.isEmpty()) {
                    Map<String, Object> items0 = (Map<String, Object>) items.get(0);
                    hangoutLink = (String) items0.get('hangoutLink');
                }
            }
            if (!String.isBlank(hangoutLink)){
                sa.SCH_Google_Meet_URL__c = hangoutLink;
                sa.GoogleMeetSchError__c = '';
            }else{
                sa.GoogleMeetSchError__c = 'Error Code: ' + response.getStatusCode();
                sa.GoogleMeetSchError__c += '\nError: ' + response.getBody();
            }
            update sa;
        } catch (Exception ex) {
            String errorMessage = ex.getMessage();
            System.debug(errorMessage);
            sa.GoogleMeetSchError__c = errorMessage;
            update sa;
        }
    }
}