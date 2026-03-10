@isTest
public class GoogleCalendarAPIControllerTest {
    // Mock HTTP callout for getEventsFromUser
    @isTest
    static void testGetEventsFromUser_Success() {
        // Setup mock response
        String userEmail = 'testuser@example.com';
        String timeMin = '2025-09-01T00:00:00Z';
        String timeMax = '2025-09-02T00:00:00Z';
        Integer maxResults = 2;
        String mockBody = '{"items": [{"id": "evt1", "summary": "Event 1", "start": {"dateTime": "2025-09-01T10:00:00Z"}, "end": {"dateTime": "2025-09-01T11:00:00Z"}}, {"id": "evt2", "summary": "Event 2", "start": {"dateTime": "2025-09-01T12:00:00Z"}, "end": {"dateTime": "2025-09-01T13:00:00Z"}}]}';
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GoogleCalendarEventsMock(200, mockBody));
        List<GoogleCalendarAPIController.GoogleCalendarEventWrapper> events = GoogleCalendarAPIController.getEventsFromUser(userEmail, timeMin, timeMax, maxResults);
        Test.stopTest();
        System.assertEquals(2, events.size());
        System.assertEquals('evt1', events[0].id);
        System.assertEquals('Event 1', events[0].summary);
    }

    @isTest
    static void testGetEventsFromUser_Error() {
    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new GoogleCalendarEventsMock(401, '{"error": "Unauthorized"}'));
    List<GoogleCalendarAPIController.GoogleCalendarEventWrapper> events = GoogleCalendarAPIController.getEventsFromUser('testuser@example.com', '2025-09-01T00:00:00Z', '2025-09-02T00:00:00Z', 2);
    Test.stopTest();
    System.assertEquals(0, events.size());
    }

    @isTest
    static void testGetFreeBusyInfo_Success() {
    List<String> emails = new List<String>{'user1@example.com'};
    Datetime timeMin = Datetime.newInstanceGmt(2025, 9, 1, 0, 0, 0);
    Datetime timeMax = timeMin.addMinutes(10);
    String mockBody = '{"kind": "calendar#freeBusy", "calendars": {"user1@example.com": {"busy": [{"start": "2025-09-01T10:00:00Z", "end": "2025-09-01T11:00:00Z"}]}}}';
    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new GoogleCalendarEventsMock(200, mockBody));
    List<GoogleCalendarAPIController.FreeBusyResponseWrapper> responses = GoogleCalendarAPIController.getFreeBusyInfo(emails, timeMin, timeMax);
    Test.stopTest();
    System.assertEquals(1, responses.size());
    System.assertEquals('calendar#freeBusy', responses[0].kind);
    System.assert(responses[0].calendars.containsKey('user1@example.com'));
    }

    @isTest
    static void testBatchGetFreeBusyInfo_Success() {
    List<String> emails = new List<String>{'user1@example.com'};
    Datetime timeMin = Datetime.newInstanceGmt(2025, 9, 1, 0, 0, 0);
    Datetime timeMax = timeMin.addMinutes(10);
    String boundary = 'batch_12345';
    String mockBody = '--' + boundary + '\r\nContent-Type: application/http\r\nContent-ID: 1\r\n\r\nHTTP/1.1 200 OK\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n{"kind": "calendar#freeBusy", "calendars": {"user1@example.com": {"busy": [{"start": "2025-09-01T10:00:00Z", "end": "2025-09-01T11:00:00Z"}]}}}}\r\n--' + boundary + '--';
    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new GoogleCalendarBatchMock(200, mockBody, boundary));
    List<GoogleCalendarAPIController.FreeBusyResponseWrapper> responses = GoogleCalendarAPIController.batchGetFreeBusyInfo(emails, timeMin, timeMax);
    Test.stopTest();
    System.assertEquals(1, responses.size());
    System.assertEquals('calendar#freeBusy', responses[0].kind);
    }

    // Mock classes
    private class GoogleCalendarEventsMock implements HttpCalloutMock {
        private Integer code;
        private String body;
        public GoogleCalendarEventsMock(Integer code, String body) {
            this.code = code;
            this.body = body;
        }
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(this.code);
            res.setBody(this.body);
            res.setHeader('Content-Type', 'application/json; charset=utf-8');
            return res;
        }
    }
    private class GoogleCalendarBatchMock implements HttpCalloutMock {
        private Integer code;
        private String body;
        private String boundary;
        public GoogleCalendarBatchMock(Integer code, String body, String boundary) {
            this.code = code;
            this.body = body;
            this.boundary = boundary;
        }
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(this.code);
            res.setBody(this.body);
            res.setHeader('Content-Type', 'multipart/mixed; boundary=' + this.boundary);
            return res;
        }
    }
}