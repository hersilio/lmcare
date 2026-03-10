/**
 * @description       :
 * @author            : Hersilio Belini de Oliveira
 * @group             :
 * @last modified on  : 2025-06-25
 * @last modified by  : Hersilio Belini de Oliveira
**/
@IsTest
private class AppointmentEntryRestTest {

    private static Id workTypeId;
    private static Id serviceTerritoryId;
    private static Id engagementTypeId;
    private static Id serviceResourceId;

    @TestSetup
    static void setupTestData() {
        // Create OperatingHours
        OperatingHours operatingHours = new OperatingHours(
            Name = 'Test Operating Hours',
            TimeZone = 'America/New_York'
        );
        insert operatingHours;

        // Create WorkType
        WorkType workType = new WorkType(Name = 'Test WorkType');
        workType.EstimatedDuration = 120;
        insert workType;
        workTypeId = workType.Id;

        // Create ServiceTerritory
        ServiceTerritory serviceTerritory = new ServiceTerritory(Name = 'Test Territory');
        serviceTerritory.OperatingHoursId = operatingHours.Id;
        insert serviceTerritory;
        serviceTerritoryId = serviceTerritory.Id;

        // Create EngagementChannelType
        EngagementChannelType engagementChannelType = new EngagementChannelType(Name = 'Test Engagement Type');
        engagementChannelType.ContactPointType = 'Video';
        insert engagementChannelType;
        engagementTypeId = engagementChannelType.Id;

        // Create a Service Resource with necessary fields and relation to the territory
        ServiceResource serviceResource = new ServiceResource(
            Name = 'Test Resource',
            IsActive = true,
            relatedRecordId = UserInfo.getUserId()
        );

        insert serviceResource;
    }

    private static AppointmentDTO createSampleAppointmentDTO(String mdmId) {
        AppointmentDTO appointment = new AppointmentDTO();

        appointment.serviceAppointment = new AppointmentDTO.ServiceAppointmentDTO();
        appointment.serviceAppointment.workTypeId = workTypeId;
        appointment.serviceAppointment.serviceTerritoryId = serviceTerritoryId;
        appointment.serviceAppointment.engagementChannelTypeId = engagementTypeId;
        appointment.serviceAppointment.schedStartTime = DateTime.newInstance(2024, 11, 7, 9, 15, 0);
        appointment.serviceAppointment.schedEndTime = DateTime.newInstance(2024, 11, 7, 12, 15, 0);
        appointment.serviceAppointment.state ='Porto';
        appointment.serviceAppointment.street ='street 1';
        appointment.serviceAppointment.city ='Porto';
        appointment.serviceAppointment.country ='Portugal';
        appointment.serviceAppointment.postalCode ='4000-001';
        appointment.serviceAppointment.description = 'Test Description';

        appointment.lead = new AppointmentDTO.LeadDTO();
        appointment.lead.firstName = 'John';
        appointment.lead.lastName = 'Doe';
        appointment.lead.phone = '999999999';
        appointment.lead.email = 'johndoe@example.com';

        AppointmentDTO.ExtendedFieldDTO field1 = new AppointmentDTO.ExtendedFieldDTO();
        field1.name = 'Loja_de_Angariacao__c';
        field1.value = 'Alfragide';

        AppointmentDTO.ExtendedFieldDTO field2 = new AppointmentDTO.ExtendedFieldDTO();
        field2.name = 'Numero_de_Conta_na_lead__c';
        field2.value = mdmId;

        appointment.lead.extendedFields = new List<AppointmentDTO.ExtendedFieldDTO>{field1, field2};
        AppointmentDTO.AssignedResourceDTO sr = new AppointmentDTO.AssignedResourceDTO();
        sr.serviceResourceId = [SELECT Id FROM ServiceResource LIMIT 1].Id;
        sr.isRequiredResource = true;
        sr.isPrimaryResource = true;
        appointment.assignedResources = new List<AppointmentDTO.AssignedResourceDTO>();
        appointment.assignedResources.add(sr);

        System.debug(appointment.assignedResources);
        return appointment;
    }

    @IsTest
    static void testMakePost_Success() {

        AppointmentDTO appointment = createSampleAppointmentDTO('2462');
        String jsonBody = JSON.serialize(appointment);

        RestContext.request = new RestRequest();
        RestContext.request.requestUri = '/services/apexrest/appointments';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(jsonBody);
        RestContext.response = new RestResponse();

        Test.startTest();
        lxscheduler.SchedulerResources.setAppointmentCandidatesMock('availableSlots');
        lxscheduler.SchedulerResources.setAppointmentSlotsMock('expectedResponse');
        AppointmentEntryRest.makePost();
        Test.stopTest();

        System.assertEquals(201, RestContext.response.statusCode, 'Expected status code does not match.');
    }

    @IsTest
    static void testMakePost_MissingFields() {
        AppointmentDTO appointment = createSampleAppointmentDTO('00000001');
        appointment.lead = null;

        String jsonBody = JSON.serialize(appointment);

        RestContext.request = new RestRequest();
        RestContext.request.requestUri = '/services/apexrest/appointments';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(jsonBody);
        RestContext.response = new RestResponse();

        Test.startTest();
        lxscheduler.SchedulerResources.setAppointmentCandidatesMock('availableSlots');
        AppointmentEntryRest.makePost();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode, 'Expected status code does not match for missing fields.');
        String responseError = RestContext.response.responseBody.toString();
    }

    @IsTest
    static void testCreateAssignedResource() {

        lead lead = new Lead();
        lead.firstName = 'John';
        lead.lastName = 'Doe';
        lead.phone = '999999999';
        lead.email = 'johndoe@example.com';

        insert lead;   // Create a mock ServiceAppointment

        ServiceAppointment sa = new ServiceAppointment(
            OwnerId = UserInfo.getUserId(),
            SchedStartTime = DateTime.now(),
            SchedEndTime = DateTime.now().addHours(2),
            ServiceTerritoryId = serviceTerritoryId,
            WorkTypeId = workTypeId,
            ParentRecordId = lead.Id
        );
        System.debug(sa);
        insert sa;

                // Create a Service Resource with necessary fields and relation to the territory
        ServiceResource serviceResource =  [select id from serviceResource];

        Test.startTest();
        AppointmentEntryRest.createAssignedResource(sa, serviceResource.Id);
        Test.stopTest();
    }
}