/*
EXAMPLE IMPLEMENTATION OF A TEST CLASS FOR THE SERVICE RESOURCE SCHEDULE HANDLER

@isTest
private class ServiceResourceScheduleHandlerImplTest {
   static testMethod void getUnavailableTimeslotsTest() {
   
      //Initializing the test execution with mock values. Change it according to the implementation.
      //In case of non-test execution, the lxscheduler.ServiceAppointmentRequestInfo instance will automatically initialize.
      
      //Mock values for lxscheduler.ServiceResourceInfo
      String userId = '005D2000000I1N6IAK';
      String userName = 'someuser@example.com';
      String email = 'someuser@example.com';
      String serviceResourceId = '0HnD20000004C9bKAE';
      List<String> territoryIds = new List<String>();
      String resourceType = 'T';
      lxscheduler.ServiceResourceInfo serviceResInfo = new lxscheduler.ServiceResourceInfo(userId, userName, email, 
                                                       serviceResourceId, territoryIds, resourceType);
      
      //Mock values for lxscheduler.ServiceAppointmentRequestInfo 
      DateTime startDate = System.now();
      DateTime endDate = System.now();
      List<lxscheduler.ServiceResourceInfo> serviceResources = new List<lxscheduler.ServiceResourceInfo>();
      serviceResources.add(serviceResInfo);
      String schedulingPolicyId = '0VrD20000004C9S';
      String workTypeGroupId = '0VSD20000004C93OAE';
      String accountId = '001D2000002pkXwIAI';
      String primaryResourceId = '0HnD20000004C9bKAE';
      String workTypeId = '08qD20000004C9XIAU';
      String correlationId = 'SOME_ID';
      
      lxscheduler.ServiceAppointmentRequestInfo mockRequestInfo = new lxscheduler.ServiceAppointmentRequestInfo(
      startDate, endDate, serviceResources, schedulingPolicyId,
      workTypeGroupId, accountId, primaryResourceId, workTypeId, 
      correlationId
      );

      ServiceResourceScheduleHandlerImpl.getUnavailableTimeslots(mockRequestInfo);
   }
}
*/





@isTest
public class SchGoogleCalendarIntegrationHandlerTest {
    
    private class MockNoEventsResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String responseBody = 
            'HTTP/1.1 200\r\n' +
            'Content-Type: multipart/mixed; boundary=batch_foobarbaz\r\n\r\n' + 
            '--batch_foobarbaz\r\n' +

            'Content-Type: application/http\r\n' + 
            'Content-ID: 1\r\n\r\n' + 
            'HTTP/1.1 200 OK\r\n' + 
            'Content-Type application/json\r\n' + 
            'ETag: "etag/freebusy"\r\n\r\n' + 
            '{' +               
                '"calendars": {' +
                    '"testuser@example.com": {' +
                        '"errors": [' +
                            '{' +
                            '"domain": "string",' +
                            '"reason": "string"' +
                            '}' +
                        '],' +
                        '"busy": []' +
                    '}' +
                '}' +
            '}'+
            '--batch_foobarbaz--';

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody(responseBody); // No busy times
            return res;
        }
    }

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String responseBody = 
            'HTTP/1.1 200\r\n' +
            'Content-Type: multipart/mixed; boundary=batch_foobarbaz\r\n\r\n' + 
            '--batch_foobarbaz\r\n' +

            'Content-Type: application/http\r\n' + 
            'Content-ID: 1\r\n\r\n' + 
            'HTTP/1.1 200 OK\r\n' + 
            'Content-Type application/json\r\n' + 
            'ETag: "etag/freebusy"\r\n\r\n' + 
            '{' +               
                '"calendars": {' +
                    '"testuser@example.com": {' +
                        '"errors": [' +
                            '{' +
                            '"domain": "string",' +
                            '"reason": "string"' +
                            '}' +
                        '],' +
                        '"busy": [' +
                            '{' +
                            '"start": "2025-06-27T10:00:00",' +
                            '"end": "2025-06-27T11:00:00"' +
                            '}' +
                        ']' +
                    '}' +
                '}' +
            '}'+
            '--batch_foobarbaz--';

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'multipart/mixed; boundary=batch_foobarbaz');
            res.setStatusCode(200);
            res.setBody(responseBody);
            return res;
        }
    }

    @isTest static void getUnavailableTimeSlotsTest() {
        // Mock values for lxscheduler.ServiceResourceInfo
        String userId = '005D2000000I1N6IAK';
        String userName = 'someuser@example.com';
        String email = 'testuser@example.com';
        String serviceResourceId = '0HnD20000004C9bKAE';
        List<String> territoryIds = new List<String>();
        String resourceType = 'T';
        lxscheduler.ServiceResourceInfo serviceResInfo = new lxscheduler.ServiceResourceInfo(userId, userName, email, serviceResourceId, territoryIds, resourceType);
        
        // Mock values for lxscheduler.ServiceAppointmentRequestInfo 
        DateTime startDate = DateTime.newInstance(2025, 6, 27, 0, 0, 0);
        DateTime endDate = DateTime.newInstance(2025, 6, 28, 0, 0, 0);
        List<lxscheduler.ServiceResourceInfo> serviceResources = new List<lxscheduler.ServiceResourceInfo>();
        serviceResources.add(serviceResInfo);
        String schedulingPolicyId = '0VrD20000004C9S';
        String workTypeGroupId = '0VSD20000004C93OAE';
        String accountId = '001D2000002pkXwIAI';
        String primaryResourceId = '0HnD20000004C9bKAE';
        String workTypeId = '08qD20000004C9XIAU';
        String correlationId = 'SOME_ID';
        lxscheduler.ServiceAppointmentRequestInfo mockRequestInfo = new lxscheduler.ServiceAppointmentRequestInfo(
            startDate, endDate, serviceResources, schedulingPolicyId,
            workTypeGroupId, accountId, primaryResourceId, workTypeId,
            correlationId
            );

        System.debug(mockRequestInfo);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        List<lxscheduler.ServiceResourceSchedule> result = SchGoogleCalendarIntegrationHandler.getUnavailableTimeSlots(mockRequestInfo);
        Test.stopTest();

        System.assertEquals(1, result.size());

        lxscheduler.ServiceResourceSchedule sched = result[0];
        System.assertEquals(serviceResourceId, sched.serviceResourceId);

        Set<lxscheduler.UnavailableTimeslot> slots = sched.unavailableTimeSlots;
        System.assertEquals(1, slots.size(), 'Slots: ' + slots);
        lxscheduler.UnavailableTimeslot slot = slots.iterator().next();
        System.assertEquals(DateTime.valueOfGmt('2025-06-27 10:00:00'), slot.timeMin);
        System.assertEquals(DateTime.valueOfGmt('2025-06-27 11:00:00'), slot.timeMax);
    }



    @isTest static void testNoEmailResource() {
        // Resource with no email
        String userId = '005D2000000I1N6IAK';
        String userName = 'someuser@example.com';
        String email = null;
        String serviceResourceId = '0HnD20000004C9bKAE';
        List<String> territoryIds = new List<String>();
        String resourceType = 'T';
        lxscheduler.ServiceResourceInfo serviceResInfo = new lxscheduler.ServiceResourceInfo(userId, userName, email, serviceResourceId, territoryIds, resourceType);
        
        DateTime startDate = DateTime.newInstance(2025, 6, 27, 0, 0, 0);
        DateTime endDate = DateTime.newInstance(2025, 6, 28, 0, 0, 0);

        List<lxscheduler.ServiceResourceInfo> serviceResources = new List<lxscheduler.ServiceResourceInfo>{serviceResInfo};
        String schedulingPolicyId = '0VrD20000004C9S';
        String workTypeGroupId = '0VSD20000004C93OAE';
        String accountId = '001D2000002pkXwIAI';
        String primaryResourceId = '0HnD20000004C9bKAE';
        String workTypeId = '08qD20000004C9XIAU';
        String correlationId = 'SOME_ID';
        lxscheduler.ServiceAppointmentRequestInfo mockRequestInfo = new lxscheduler.ServiceAppointmentRequestInfo(
            startDate, endDate, serviceResources, schedulingPolicyId,
            workTypeGroupId, accountId, primaryResourceId, workTypeId, correlationId
            );

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        List<lxscheduler.ServiceResourceSchedule> result = SchGoogleCalendarIntegrationHandler.getUnavailableTimeSlots(mockRequestInfo);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should return 0 schedules for resource with no email');
    }

    @isTest static void testNoEvents() {
        Test.setMock(HttpCalloutMock.class, new MockNoEventsResponse());
        String userId = '005D2000000I1N6IAK';
        String userName = 'someuser@example.com';
        String email = 'testuser@example.com';
        String serviceResourceId = '0HnD20000004C9bKAE';
        List<String> territoryIds = new List<String>();
        String resourceType = 'T';
        lxscheduler.ServiceResourceInfo serviceResInfo = new lxscheduler.ServiceResourceInfo(userId, userName, email, serviceResourceId, territoryIds, resourceType);
        DateTime startDate = DateTime.newInstance(2025, 6, 27, 0, 0, 0);
        DateTime endDate = DateTime.newInstance(2025, 6, 28, 0, 0, 0);
        List<lxscheduler.ServiceResourceInfo> serviceResources = new List<lxscheduler.ServiceResourceInfo>{serviceResInfo};
        String schedulingPolicyId = '0VrD20000004C9S';
        String workTypeGroupId = '0VSD20000004C93OAE';
        String accountId = '001D2000002pkXwIAI';
        String primaryResourceId = '0HnD20000004C9bKAE';
        String workTypeId = '08qD20000004C9XIAU';
        String correlationId = 'SOME_ID';
        lxscheduler.ServiceAppointmentRequestInfo mockRequestInfo = new lxscheduler.ServiceAppointmentRequestInfo(
            startDate, endDate, serviceResources, schedulingPolicyId,
            workTypeGroupId, accountId, primaryResourceId, workTypeId, correlationId
        );
        List<lxscheduler.ServiceResourceSchedule> result = SchGoogleCalendarIntegrationHandler.getUnavailableTimeSlots(mockRequestInfo);
        System.assertEquals(0, result.size(), 'Should return 0 schedules if no events');
    }
}