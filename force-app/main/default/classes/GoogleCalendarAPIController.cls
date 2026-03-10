/**
 * @description Handles the callout to Google Calendar API to fetch events or free/busy information for users.
 * @author Felipe Gil
 * @company TRH
 * @version 0.4
 * @created 2025-08-01
 */

public without sharing class GoogleCalendarAPIController {

    /**
     * PROBABLY OBSOLETE
     * Fetches events from Google Calendar for a specific user within a given time range.
     *
     * @param userEmail The email of the user whose calendar events are to be fetched.
     * @param timeMin The start time in ISO 8601 format (e.g., '2023-10-01T00:00:00Z'). Defaults to the current time if not provided.
     * @param timeMax The end time in ISO 8601 format (e.g., '2023-10-31T23:59:59Z').
     * @param maxResults The maximum number of results to return. Defaults to 250 if not provided.
     * @return A list of GoogleCalendarEventWrapper objects containing event details.
     */
    public static List<GoogleCalendarEventWrapper> getEventsFromUser(String userEmail, String timeMin, String timeMax, Integer maxResults) {

        if (String.isBlank(userEmail)) {
            throw new CalloutException('User email cannot be null or empty.');
        }
        maxResults = maxResults < 0 ? 250 : maxResults > 2500 ? 2500 : maxResults; // Ensure maxResults is within the valid range

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        HttpResponse response;

        String baseUrl = 'callout:SCH_google_calendar_legacy/calendar/v3/calendars/';
        String endpoint = baseUrl + EncodingUtil.urlEncode(userEmail, 'UTF-8') +
            '/events?singleEvents=true' +
            '&orderBy=startTime' +
            '&timeMin=' + EncodingUtil.urlEncode(timeMin, 'UTF-8') +
            '&timeMax=' + EncodingUtil.urlEncode(timeMax, 'UTF-8') +
            '&maxResults=' + String.valueOf(maxResults);
        request.setEndpoint(endpoint);
        request.setHeader('Content-Type', 'application/json; charset=utf-8');
        request.setMethod('GET');
        request.setTimeout(20000);

        List<GoogleCalendarEventWrapper> events = new List<GoogleCalendarEventWrapper>();

        try {
            response = http.send(request);

            if (response.getStatusCode() != 200) {
                System.debug('Error Code: ' + response.getStatusCode());
                System.debug('Error: ' + response.getBody());
                throw new CalloutException('Failed to fetch events from Google Calendar API. Status Code: ' + response.getStatusCode() + ', Response: ' + response.getBody());
            }

            Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            List<Object> items = (List<Object>) results.get('items');
            if (items == null || items.isEmpty()) {
                System.debug('No events found for user: ' + userEmail);
                System.debug('Response: ' + response.getBody());
                return events;
            }

            events = unwrapGoogleCalendarEvents(JSON.serialize(items));
            // System.debug('Response: ' + response.getBody());
            // System.debug('Events: ' + JSON.serializePretty(events));
            System.debug('Number of events fetched: ' + events.size());
            for (GoogleCalendarEventWrapper event : events) {
                System.debug('Event ID: ' + event.id.abbreviate(10) + ', Summary: ' + event.summary + ', Start: ' + event.startGcal.dateTimeGcal + ', End: ' + event.endGcal.dateTimeGcal);
            }
            
            return events;
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
            return new List<GoogleCalendarEventWrapper>();
        }
    }

    //Commented in case we need to roll back.
    /**
     * @description Fetches free busy data for multiple users within a specified time range. Bulkifies and simplifies the callout to Google Calendar API, in contrast with the method `getEventsFromUser`.
     * @param userEmails List of user emails to fetch free busy data for.
     * @param timeMin Start time in ISO 8601 format (e.g., '2023-10-01T00:00:00Z').
     * @param timeMax End time in ISO 8601 format (e.g., '2023-10-31T23:59:59Z').
     * @return A list of FreeBusyResponseWrapper objects containing free busy data for each user. Requests are made in chunks of up to 50 
     *         users to avoid exceeding Google Calendar API limits.
     */
    public static List<FreeBusyResponseWrapper> getFreeBusyInfo(List<String> userEmails, DateTime timeMin, DateTime timeMax) {
        if (userEmails == null || userEmails.isEmpty()) {
            throw new CalloutException('User emails cannot be null or empty.');
        }
        // if (String.isBlank(timeMin) || String.isBlank(timeMax)) {
        //     throw new CalloutException('Time range cannot be null or empty.');
        // }

        String baseUrl = 'callout:SCH_google_calendar_legacy/calendar/v3/';
        String endpoint = baseUrl + 'freeBusy/';

        // Split userEmails into chunks of up to 50
        Integer chunkSize = 50;
        List<FreeBusyResponseWrapper> allResponses = new List<FreeBusyResponseWrapper>();
        for (Integer i = 0; i < userEmails.size(); i += chunkSize) {

            // Create a chunk of user emails
            List<String> chunk = new List<String>();
            Integer lastChunkIdx = Math.min(i + chunkSize, userEmails.size());
            for (Integer j = i; j < lastChunkIdx; j++) chunk.add(userEmails[j]);

            // Construct the request body for this chunk
            FreeBusyRequestWrapper requestBody = new FreeBusyRequestWrapper();
            requestBody.timeMin = timeMin;
            requestBody.timeMax = timeMax;
            requestBody.timeZone = 'UTC';
            requestBody.groupExpansionMax = chunkSize;
            requestBody.calendarExpansionMax = chunkSize;
            requestBody.items = new List<FreeBusyItem>();
            for (String email : chunk) {
            FreeBusyItem item = new FreeBusyItem();
            item.id = email;
            requestBody.items.add(item);
            }

            String requestBodySerialized = JSON.serialize(requestBody);

            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setHeader('Content-Type', 'application/json; charset=utf-8');
            request.setMethod('POST');
            request.setEndpoint(endpoint);
            request.setBody(requestBodySerialized);

            HttpResponse response;
            
            try {
            response = http.send(request);
            } catch (Exception e) {
            System.debug('Exception during HTTP callout: ' + e.getMessage());
            throw new CalloutException('Failed to fetch free busy data from Google Calendar API. Exception: ' + e.getMessage());
            }

            if (response.getStatusCode() != 200) {
            System.debug('#### Request Body: ' + request.getBody());
            System.debug('Error Code: ' + response.getStatusCode());
            System.debug('Error: ' + response.getBody());
            throw new CalloutException('Failed to fetch free busy data from Google Calendar API. Status Code: ' + response.getStatusCode() + ', Response: ' + response.getBody());
            }

            String jsonString = response.getBody();
            System.debug('Response Body: ' + jsonString);

            if (jsonString == null || String.isBlank(jsonString)) {
            System.debug('No free busy data found for the provided user emails.');
            throw new CalloutException('No free busy data found for the provided user emails.');
            }

            FreeBusyResponseWrapper freeBusyResponse = unwrapFreeBusyResponse(jsonString);
            allResponses.add(freeBusyResponse);
        }

        return allResponses;
    }

    /**
     * @description Fetches free busy data for multiple users within a specified time range. Bulkifies and simplifies the callout to Google Calendar API, in contrast with the method `getEventsFromUser`.
     * @param userEmails List of user emails to fetch free busy data for.
     * @param timeMin Start time in ISO 8601 format (e.g., '2023-10-01T00:00:00Z').
     * @param timeMax End time in ISO 8601 format (e.g., '2023-10-31T23:59:59Z').
     * @return A list of FreeBusyResponseWrapper objects containing free busy data for each user. Requests are made in chunks of up to 50 
     *         users to avoid exceeding Google Calendar API limits.
     */
    public static List<FreeBusyResponseWrapper> batchGetFreeBusyInfo(List<String> userEmails, Datetime timeMin, Datetime timeMax) {
        if (userEmails == null || userEmails.isEmpty()) {
            throw new CalloutException('User emails cannot be null or empty.');
        }
        //Verify if Datime is null or blank
        if (timeMin == null || timeMax == null ) {
            throw new CalloutException('Time range cannot be null or empty.');
        }

        // Split into 50-user chunks like before
        Integer chunkSize = 50;
        List<List<String>> chunks = new List<List<String>>();
        for (Integer i = 0; i < userEmails.size(); i += chunkSize) {
            Integer endIdx = Math.min(i + chunkSize, userEmails.size());
            List<String> subChunk = new List<String>();
            for (Integer j = i; j < endIdx; j++) {
                subChunk.add(userEmails[j]);
            }
            chunks.add(subChunk);
        }

        // Build multipart/mixed batch request body
        String boundary = 'batch_' + String.valueOf(Crypto.getRandomInteger());
        List<String> multipartBody = new List<String>();

        Integer counter = 1;
        for (List<String> chunk : chunks) {
            FreeBusyRequestWrapper reqBody = new FreeBusyRequestWrapper();
            reqBody.timeMin = timeMin;
            reqBody.timeMax = timeMax;
            reqBody.timeZone = 'UTC';
            reqBody.groupExpansionMax = chunkSize;
            reqBody.calendarExpansionMax = chunkSize;
            reqBody.items = new List<FreeBusyItem>();

            for (String email : chunk) {
                FreeBusyItem item = new FreeBusyItem();
                item.id = email;
                reqBody.items.add(item);
            }

            String serialized = JSON.serialize(reqBody);

            multipartBody.add(
                '--' + boundary + '\r\n' +
                'Content-Type: application/http\r\n' +
                'Content-ID: ' + counter + '\r\n\r\n' +
                'POST /calendar/v3/freeBusy HTTP/1.1\r\n' +
                'Content-Type: application/json; charset=UTF-8\r\n\r\n' +
                serialized + '\r\n'
            );

            counter++;
        }

        multipartBody.add('--' + boundary + '--');

        // Prepare the single HTTP batch request
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:SCH_google_calendar_legacy/batch/calendar/v3');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'multipart/mixed; boundary=' + boundary);
        request.setBody(String.join(multipartBody, ''));

        Http http = new Http();
        HttpResponse response = http.send(request);

        System.debug(response.getStatusCode());

        if (response.getStatusCode() != 200) {
            throw new CalloutException('Batch call failed. Status Code: ' + response.getStatusCode() +
                                       ', Response: ' + response.getBody());
        }

        // Parse the multipart response
        String responseBoundary = response.getHeader('Content-Type').replace('multipart/mixed; boundary=', '');
        List<FreeBusyResponseWrapper> allResponses = parseBatchResponse(response.getBody(), responseBoundary);

        // Check if any part has an unauthorized response. If yes, refresh token, resend request and parse response.
        for (FreeBusyResponseWrapper part : allResponses) {
            if (part.statusCode == 401){
                refreshTokenWithDummyCall(userEmails[0]);
                http.send(request);
                responseBoundary = response.getHeader('Content-Type').replace('multipart/mixed; boundary=', '');
                allResponses = parseBatchResponse(response.getBody(), responseBoundary);
                break;
            }
        }
        return allResponses;
    }

    /* Refreshes the access token by making a dummy call to the Google Calendar API.
     * @param userEmail The email of the user whose token needs to be refreshed.
     *                  This is not used in the actual refresh, but is required to make the dummy call.
     *
     * @return void
     */
    private static void refreshTokenWithDummyCall(String email){
        DateTime t0 = DateTime.now();
        Datetime t1 = DateTime.now().addMinutes(1);
        List<String> u = new List<String>{email};
        getFreeBusyInfo(u, t0, t1); //Make a dummy call to get refreshed token
    }

    /**
     * Parses a multipart/mixed batch response from Google Calendar API and returns a list of FreeBusyResponseWrapper.
     * @param responseBody The raw response body from the batch call.
     * @param boundary The boundary string used in the multipart response.
     * @return List of FreeBusyResponseWrapper, one per batch segment.
    */
    private static List<FreeBusyResponseWrapper> parseBatchResponse(String responseBody, String boundary) {
        List<FreeBusyResponseWrapper> results = new List<FreeBusyResponseWrapper>();
        if (responsebody == null || boundary == null || String.isBlank(responseBody) || String.isBlank(boundary)) {
            System.debug('Empty response body or boundary. Cannot parse batch response.');
            return results;
        }
        String escapedBoundary = Pattern.quote('--' + boundary);
        List<String> parts = responseBody.split(escapedBoundary);

        for (String part : parts) {
            if (String.isBlank(part)) continue;

            // Look for the start of a JSON object (first '{') and end (last '}')
            Integer jsonStart = part.indexOf('{');
            Integer jsonEnd = part.lastIndexOf('}');
            if (jsonStart == -1 || jsonEnd == -1 || jsonEnd <= jsonStart) continue;

            String jsonBody = part.substring(jsonStart, jsonEnd + 1);
            // System.debug('jsonBody: ' + jsonBody);

            try {
                FreeBusyResponseWrapper wrapper = unwrapFreeBusyResponse(jsonBody);
                Matcher matcher = Pattern.compile('HTTP/1\\.1 (\\d{3})').matcher(part);
                Integer statusCode = null;
                if (matcher.find()) 
                    statusCode = Integer.valueOf(matcher.group(1));
                    wrapper.statusCode = statusCode;
                results.add(wrapper);
            } catch (Exception e) {
                System.debug('Failed to parse batch part: ' + e.getMessage());
            }
        }
        return results;
    }

        /**
     * Replaces invalid JSON keys (protected keywords like 'date', 'end', etc.) with valid ones for storage as Apex objects.
     * This is necessary to avoid reserved keyword issues in Apex.
     *
     * @param jsonString The JSON string with protected keys.
     * @return The JSON string with unprotected keys.
     */
    private static String mapReservedJsonKeysForDeserialization(String jsonString){ 
        jsonString = jsonString.replaceAll('"date"', '"dateGcal"'); 
        jsonString = jsonString.replaceAll('"dateTime"', '"dateTimeGcal"'); 
        jsonString = jsonString.replaceAll('"start"', '"startGcal"'); 
        jsonString = jsonString.replaceAll('"end"', '"endGcal"'); 
        jsonString = jsonString.replaceAll('"private"', '"privateGcal"'); 

        return jsonString;
    }

    /**
     * Unwraps the JSON string into a list of GoogleCalendarEventWrapper objects.
     *
     * @param jsonString The JSON string to be deserialized.
     * @return A list of GoogleCalendarEventWrapper objects.
     */
    private static List<GoogleCalendarEventWrapper> unwrapGoogleCalendarEvents(String jsonString){
        jsonString = mapReservedJsonKeysForDeserialization(jsonString);
        List<GoogleCalendarEventWrapper> events = (List<GoogleCalendarEventWrapper>) JSON.deserialize(jsonString, List<GoogleCalendarEventWrapper>.class);
        return events;
    }

    /**
     * Unwraps the JSON string into a list of FreeBusyResponseWrapper objects.
     *
     * @param jsonString The JSON string to be deserialized.
     * @return A list of FreeBusyResponseWrapper objects.
     */
    private static FreeBusyResponseWrapper unwrapFreeBusyResponse(String jsonString) {
        jsonString = mapReservedJsonKeysForDeserialization(jsonString);
        FreeBusyResponseWrapper freeBusyResponse = (FreeBusyResponseWrapper) JSON.deserialize(jsonString, FreeBusyResponseWrapper.class);
        return freeBusyResponse;
    }

    //-------------------------------------------------
    public class FreeBusyRequestWrapper {
        // public String timeMin;
        // public String timeMax;
        public Datetime timeMin;
        public Datetime timeMax;
        public String timeZone;
        public Integer groupExpansionMax;
        public Integer calendarExpansionMax;
        public List<FreeBusyItem> items;
    }
    public class FreeBusyItem {
        public String id;
    }

    //-------------------------------------------------
    public class FreeBusyResponseWrapper {
        public Integer statusCode;
        public String kind;
        public String timeMin;
        public String timeMax;
        public Map<String, GroupInfo> groups;
        public Map<String, CalendarInfo> calendars;
    }
    public class GroupInfo {
        public List<ErrorInfo> errors;
        public List<String> calendars;
    }
    public class CalendarInfo {
        public List<ErrorInfo> errors;
        public List<BusyTime> busy;
    }
    public class ErrorInfo {
        public String domain;
        public String reason;
    }
    public class BusyTime {
        public String startGcal; // Renamed from 'start' to avoid reserved keyword issues
        public String endGcal; // Renamed from 'end' to avoid reserved keyword issues
    }

    //-------------------------------------------------
    public class GoogleCalendarEventWrapper {
        public String kind ;
        public String etag ;
        public String id ;
        public String status ;
        public String htmlLink ;
        public String created ;
        public String updated ;
        public String summary ;
        public String description ;
        public String location ;
        public String colorId ;
        public UserRef creator ;
        public UserRef organizer ;
        public DateTimeRange startGcal; // Renamed from 'start' to avoid reserved keyword issues
        public DateTimeRange endGcal ; // Renamed from 'end' to avoid reserved keyword issues
        public Boolean endTimeUnspecified ;
        public List<String> recurrence ;
        public String recurringEventId ;
        public DateTimeRange originalStartTime ;
        public String transparency ;
        public String visibility ;
        public String iCalUID ;
        public Integer sequence ;
        public List<Attendee> attendees ;
        public Boolean attendeesOmitted ;
        public ExtendedProperties extendedProperties ;
        public String hangoutLink ;
        public ConferenceData conferenceData ;
        public Gadget gadget ;
        public Boolean anyoneCanAddSelf ;
        public Boolean guestsCanInviteOthers ;
        public Boolean guestsCanModify ;
        public Boolean guestsCanSeeOtherGuests ;
        public Boolean privateCopy ;
        public Boolean locked ;
        public Reminders reminders ;
        public Source source ;
        public WorkingLocationProperties workingLocationProperties ;
        public OutOfOfficeProperties outOfOfficeProperties ;
        public FocusTimeProperties focusTimeProperties ;
        public List<Attachment> attachments ;
        public BirthdayProperties birthdayProperties ;
        public String eventType ;
    }
    // Combined Creator and Organizer into UserRef
    public class UserRef {
        public String id ;
        public String email ;
        public String displayName ;
        public Boolean self ;
    }
    // Combined Start, End, and OriginalStartTime into DateTimeRange
    public class DateTimeRange {
        public Date dateGcal; // Renamed from 'date' to avoid reserved keyword issues
        public DateTime dateTimeGcal; // Renamed from 'dateTime' to avoid reserved keyword issues
        public String timeZone;
    }
    public class Attendee {
        public String id ;
        public String email ;
        public String displayName ;
        public Boolean organizer ;
        public Boolean self ;
        public Boolean resource ;
        public Boolean optional ;
        public String responseStatus ;
        public String comment ;
        public Integer additionalGuests ;
    }
    public class ExtendedProperties {
        public Map<String, String> privateGcal ; // Renamed from 'private' to avoid reserved keyword issues
        public Map<String, String> shared ;
    }
    public class ConferenceData {
        public CreateRequest createRequest ;
        public List<EntryPoint> entryPoints ;
        public ConferenceSolution conferenceSolution ;
        public String conferenceId ;
        public String signature ;
        public String notes ;
    }
    public class CreateRequest {
        public String requestId ;
        public ConferenceSolutionKey conferenceSolutionKey ;
        public Status status ;
    }
    public class ConferenceSolutionKey {
        public String type ;
    }
    public class Status {
        public String statusCode ;
    }
    public class EntryPoint {
        public String entryPointType ;
        public String uri ;
        public String label ;
        public String pin ;
        public String accessCode ;
        public String meetingCode ;
        public String passcode ;
        public String password ;
    }
    public class ConferenceSolution {
        public Key key ;
        public String name ;
        public String iconUri ;
    }
    public class Key {
        public String type ;
    }
    public class Gadget {
        public String type ;
        public String title ;
        public String link ;
        public String iconLink ;
        public Integer width ;
        public Integer height ;
        public String display ;
        public Map<String, String> preferences ;
    }
    public class Reminders {
        public Boolean useDefault ;
        public List<OverrideReminder> overrides ; // Renamed from 'Override' to avoid reserved keyword issues
    }
    public class OverrideReminder { // Renamed from 'Override' to avoid reserved keyword issues
        public String method ;
        public Integer minutes ;
    }
    public class Source {
        public String url ;
        public String title ;
    }
    public class WorkingLocationProperties {
        public String type ;
        public Object homeOffice ;
        public CustomLocation customLocation ;
        public OfficeLocation officeLocation ;
    }
    public class CustomLocation {
        public String label ;
    }
    public class OfficeLocation {
        public String buildingId ;
        public String floorId ;
        public String floorSectionId ;
        public String deskId ;
        public String label ;
    }
    public class OutOfOfficeProperties {
        public String autoDeclineMode ;
        public String declineMessage ;
    }
    public class FocusTimeProperties {
        public String autoDeclineMode ;
        public String declineMessage ;
        public String chatStatus ;
    }
    public class Attachment {
        public String fileUrl ;
        public String title ;
        public String mimeType ;
        public String iconLink ;
        public String fileId ;
    }
    public class BirthdayProperties {
        public String contact ;
        public String type ;
        public String customTypeName ;
    }
}

/* Example of the FreeBusy JSON structure
    https://developers.google.com/calendar/v3/reference/freeBusy?hl=en

    Request Body:

    {
        "timeMin": datetime,
        "timeMax": datetime,
        "timeZone": string,
        "groupExpansionMax": integer,
        "calendarExpansionMax": integer,
        "items": [
            {
            "id": string
            }
        ]
    }

    Response Body:

    {
        "kind": "calendar#freeBusy",
        "timeMin": datetime,
        "timeMax": datetime,
        "groups": {
            (key): {
            "errors": [
                {
                "domain": string,
                "reason": string
                }
            ],
            "calendars": [
                string
            ]
            }
        },
        "calendars": {
            (key): {
            "errors": [
                {
                "domain": string,
                "reason": string
                }
            ],
            "busy": [+
                {
                "start": datetime,
                "end": datetime
                }
            ]
            }
        }
    }
*/

/* Example of the Google Calendar Event JSON structure
    https://developers.google.com/workspace/calendar/api/v3/reference/events?hl=en
        {
        "kind": "calendar#event",
        "etag": etag,
        "id": string,
        "status": string,
        "htmlLink": string,
        "created": datetime,
        "updated": datetime,
        "summary": string,
        "description": string,
        "location": string,
        "colorId": string,
        "creator": {
            "id": string,
            "email": string,
            "displayName": string,
            "self": boolean
        },
        "organizer": {
            "id": string,
            "email": string,
            "displayName": string,
            "self": boolean
        },
        "start": {
            "date": date,
            "dateTime": datetime,
            "timeZone": string
        },
        "end": {
            "date": date,
            "dateTime": datetime,
            "timeZone": string
        },
        "endTimeUnspecified": boolean,
        "recurrence": [
            string
        ],
        "recurringEventId": string,
        "originalStartTime": {
            "date": date,
            "dateTime": datetime,
            "timeZone": string
        },
        "transparency": string,
        "visibility": string,
        "iCalUID": string,
        "sequence": integer,
        "attendees": [
            {
            "id": string,
            "email": string,
            "displayName": string,
            "organizer": boolean,
            "self": boolean,
            "resource": boolean,
            "optional": boolean,
            "responseStatus": string,
            "comment": string,
            "additionalGuests": integer
            }
        ],
        "attendeesOmitted": boolean,
        "extendedProperties": {
            "private": {
            (key): string
            },
            "shared": {
            (key): string
            }
        },
        "hangoutLink": string,
        "conferenceData": {
            "createRequest": {
            "requestId": string,
            "conferenceSolutionKey": {
                "type": string
            },
            "status": {
                "statusCode": string
            }
            },
            "entryPoints": [
            {
                "entryPointType": string,
                "uri": string,
                "label": string,
                "pin": string,
                "accessCode": string,
                "meetingCode": string,
                "passcode": string,
                "password": string
            }
            ],
            "conferenceSolution": {
            "key": {
                "type": string
            },
            "name": string,
            "iconUri": string
            },
            "conferenceId": string,
            "signature": string,
            "notes": string,
        },
        "gadget": {
            "type": string,
            "title": string,
            "link": string,
            "iconLink": string,
            "width": integer,
            "height": integer,
            "display": string,
            "preferences": {
            (key): string
            }
        },
        "anyoneCanAddSelf": boolean,
        "guestsCanInviteOthers": boolean,
        "guestsCanModify": boolean,
        "guestsCanSeeOtherGuests": boolean,
        "privateCopy": boolean,
        "locked": boolean,
        "reminders": {
            "useDefault": boolean,
            "overrides": [
            {
                "method": string,
                "minutes": integer
            }
            ]
        },
        "source": {
            "url": string,
            "title": string
        },
        "workingLocationProperties": {
            "type": string,
            "homeOffice": (value),
            "customLocation": {
            "label": string
            },
            "officeLocation": {
            "buildingId": string,
            "floorId": string,
            "floorSectionId": string,
            "deskId": string,
            "label": string
            }
        },
        "outOfOfficeProperties": {
            "autoDeclineMode": string,
            "declineMessage": string
        },
        "focusTimeProperties": {
            "autoDeclineMode": string,
            "declineMessage": string,
            "chatStatus": string
        },
        "attachments": [
            {
            "fileUrl": string,
            "title": string,
            "mimeType": string,
            "iconLink": string,
            "fileId": string
            }
        ],
        "birthdayProperties": {
            "contact": string,
            "type": string,
            "customTypeName": string
        },
        "eventType": string
        }
     */