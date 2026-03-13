/**
 * @description       : Test class for AppointmentEntryRest REST API (Version 2)
 * @author            : Catarina Lopes
 * @group             :
 * @last modified on  : 2026-02-27
 * @last modified by  : Catarina Lopes
 **/
@IsTest
private class AppointmentEntryRestTestV2 {

    private static Id workTypeId;
    private static Id serviceTerritoryId;
    private static Id engagementTypeId;
    private static Id serviceResourceId;
    private static Id userId;
    private static String projectId = 'e8a8b710-3cad-40c2-87bd-b735f345a146';

    @TestSetup
    static void setupTestData() {
        User testUser = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];
        userId = testUser.Id;

        OperatingHours operatingHours = new OperatingHours(
            Name = 'LM Alfragide - Horario',
            TimeZone = 'Europe/Lisbon'
        );
        insert operatingHours;

        WorkType workType = new WorkType(Name = 'Instalação Casa de Banho');
        workType.EstimatedDuration = 120;
        workType.BlockTimeAfterAppointment = 15;
        workType.DurationType = 'Minutes';
        insert workType;
        workTypeId = workType.Id;

        ServiceTerritory parentTerritory = new ServiceTerritory(
            Name = 'LM Lisboa',
            OperatingHoursId = operatingHours.Id,
            IsActive = true,
            StoreID__c = '100'
        );
        insert parentTerritory;

        ServiceTerritory serviceTerritory = new ServiceTerritory(
            Name = 'LM Alfragide',
            OperatingHoursId = operatingHours.Id,
            IsActive = true,
            StoreID__c = '101',
            ParentTerritoryId = parentTerritory.Id
        );
        insert serviceTerritory;
        serviceTerritoryId = serviceTerritory.Id;

        EngagementChannelType engagementChannelType = new EngagementChannelType(Name = 'Video Chamada');
        engagementChannelType.ContactPointType = 'Video';
        engagementChannelType.IsActive = true;
        engagementChannelType.UsageType = 'External';
        insert engagementChannelType;
        engagementTypeId = engagementChannelType.Id;

        ServiceResource serviceResource = new ServiceResource(
            Name = 'Técnico Teste',
            IsActive = true,
            RelatedRecordId = testUser.Id
        );
        insert serviceResource;
        serviceResourceId = serviceResource.Id;

        insert new List<Lead>{
            new Lead(
                FirstName = 'Cliente',
                LastName = 'Teste',
                Email = 'cliente.teste@leroymerlin.pt',
                ProjectId__c = projectId,
                Canal_de_Interacao__c = 'Scheduler Online',
                Loja_de_Angariacao__c = 'Alfragide',
                LeadSource = 'Webform',
                Status = 'New'
            )
        };
    }

    private static void setupIds() {
        List<WorkType> workTypes = [SELECT Id FROM WorkType WHERE Name = 'Instalação Casa de Banho' LIMIT 1];
        if (!workTypes.isEmpty()) {
            workTypeId = workTypes[0].Id;
        }

        List<ServiceTerritory> territories = [SELECT Id FROM ServiceTerritory WHERE StoreID__c = '101' LIMIT 1];
        if (!territories.isEmpty()) {
            serviceTerritoryId = territories[0].Id;
        }

        List<EngagementChannelType> engagements = [SELECT Id FROM EngagementChannelType WHERE Name = 'Video Chamada' LIMIT 1];
        if (!engagements.isEmpty()) {
            engagementTypeId = engagements[0].Id;
        }

        List<ServiceResource> resources = [SELECT Id FROM ServiceResource WHERE Name = 'Técnico Teste' LIMIT 1];
        if (!resources.isEmpty()) {
            serviceResourceId = resources[0].Id;
        }

        List<User> users = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];
        if (!users.isEmpty()) {
            userId = users[0].Id;
        }
    }

    private static AppointmentDTO createAppointmentDTOWithIds() {
        setupIds();
        
        AppointmentDTO dto = new AppointmentDTO();
        
        dto.serviceAppointment = new AppointmentDTO.ServiceAppointmentDTO();
        dto.serviceAppointment.serviceTerritoryId = serviceTerritoryId;
        dto.serviceAppointment.schedStartTime = DateTime.valueOfGmt('2026-02-28 20:45:00');
        dto.serviceAppointment.schedEndTime = DateTime.valueOfGmt('2026-02-28 21:45:00');
        dto.serviceAppointment.workTypeId = workTypeId;
        dto.serviceAppointment.engagementChannelTypeId = engagementTypeId;
        
        AppointmentDTO.ExtendedFieldDTO isAnonymousField = new AppointmentDTO.ExtendedFieldDTO();
        isAnonymousField.name = 'IsAnonymousBooking';
        isAnonymousField.value = 'true';
        dto.serviceAppointment.extendedFields = new List<AppointmentDTO.ExtendedFieldDTO>{ isAnonymousField };
        
        dto.serviceAppointment.description = 'Test Description';
        
        dto.lead = new AppointmentDTO.LeadDTO();
        dto.lead.firstName = 'Test';
        dto.lead.lastName = 'Lead';
        dto.lead.email = 'test@lead.com';
        
        AppointmentDTO.ExtendedFieldDTO lojaField = new AppointmentDTO.ExtendedFieldDTO();
        lojaField.name = 'Loja_de_Angariacao__c';
        lojaField.value = '101';
        
        AppointmentDTO.ExtendedFieldDTO canalField = new AppointmentDTO.ExtendedFieldDTO();
        canalField.name = 'Canal_de_Interacao__c';
        canalField.value = 'Scheduler Online';
        
        AppointmentDTO.ExtendedFieldDTO numeroContaField = new AppointmentDTO.ExtendedFieldDTO();
        numeroContaField.name = 'Numero_de_Conta_na_lead__c';
        numeroContaField.value = '2462';
        
        AppointmentDTO.ExtendedFieldDTO leadSourceField = new AppointmentDTO.ExtendedFieldDTO();
        leadSourceField.name = 'LeadSource';
        leadSourceField.value = 'L2S';
        
        AppointmentDTO.ExtendedFieldDTO projectIdField = new AppointmentDTO.ExtendedFieldDTO();
        projectIdField.name = 'ProjectId__c';
        projectIdField.value = 'new-project-id-123';
        
        dto.lead.extendedFields = new List<AppointmentDTO.ExtendedFieldDTO>{ 
            lojaField, canalField, numeroContaField, leadSourceField, projectIdField 
        };
        
        AppointmentDTO.AssignedResourceDTO assignedRes = new AppointmentDTO.AssignedResourceDTO();
        assignedRes.serviceResourceId = serviceResourceId;
        assignedRes.isRequiredResource = true;
        assignedRes.isPrimaryResource = true;
        
        dto.assignedResources = new List<AppointmentDTO.AssignedResourceDTO>{ assignedRes };
        
        dto.qualifications = null;
        
        return dto;
    }

    @IsTest
    static void testMakePost_MissingLead() {
        setupIds();
        
        User testUser = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];
        
        System.runAs(testUser) {
            AppointmentDTO appointment = createAppointmentDTOWithIds();
            appointment.lead = null;

            String jsonBody = JSON.serialize(appointment);

            RestContext.request = new RestRequest();
            RestContext.request.requestUri = '/services/apexrest/appointments';
            RestContext.request.httpMethod = 'POST';
            RestContext.request.requestBody = Blob.valueOf(jsonBody);
            RestContext.response = new RestResponse();

            Test.startTest();
            AppointmentEntryRest.makePost();
            Test.stopTest();

            Assert.areEqual(400, RestContext.response.statusCode, 'Expected status code 400 for missing lead');
        }
    }

    @IsTest
    static void testMakePost_MissingExtendedFields() {
        setupIds();
        
        User testUser = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];
        
        System.runAs(testUser) {
            AppointmentDTO appointment = createAppointmentDTOWithIds();
            appointment.lead.extendedFields = null;

            String jsonBody = JSON.serialize(appointment);

            RestContext.request = new RestRequest();
            RestContext.request.requestUri = '/services/apexrest/appointments';
            RestContext.request.httpMethod = 'POST';
            RestContext.request.requestBody = Blob.valueOf(jsonBody);
            RestContext.response = new RestResponse();

            Test.startTest();
            AppointmentEntryRest.makePost();
            Test.stopTest();

            Assert.areEqual(400, RestContext.response.statusCode, 'Expected status code 400 for missing extended fields');
        }
    }

    @IsTest
    static void testMakePost_MissingAssignedResources() {
        setupIds();
        
        User testUser = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];
        
        System.runAs(testUser) {
            AppointmentDTO appointment = createAppointmentDTOWithIds();
            appointment.assignedResources = new List<AppointmentDTO.AssignedResourceDTO>();

            String jsonBody = JSON.serialize(appointment);

            RestContext.request = new RestRequest();
            RestContext.request.requestUri = '/services/apexrest/appointments';
            RestContext.request.httpMethod = 'POST';
            RestContext.request.requestBody = Blob.valueOf(jsonBody);
            RestContext.response = new RestResponse();

            Test.startTest();
            AppointmentEntryRest.makePost();
            Test.stopTest();

            Assert.areEqual(400, RestContext.response.statusCode, 'Expected status code 400 for missing assigned resources');
        }
    }

    @IsTest
    static void testMakePost_MalformedQualificationSubtypes() {
        setupIds();
        
        User testUser = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];
        
        System.runAs(testUser) {
            AppointmentDTO appointment = createAppointmentDTOWithIds();

            L2SAPIServiceHandler.QualificationWrapper qualification = new L2SAPIServiceHandler.QualificationWrapper();
            qualification.subtype = 'INVALID_QUALIFICATION_SUBTYPE';

            appointment.qualifications = new List<L2SAPIServiceHandler.QualificationWrapper>{ qualification };

            String jsonBody = JSON.serialize(appointment);

            RestContext.request = new RestRequest();
            RestContext.request.requestUri = '/services/apexrest/appointments';
            RestContext.request.httpMethod = 'POST';
            RestContext.request.requestBody = Blob.valueOf(jsonBody);
            RestContext.response = new RestResponse();

            Test.startTest();
            AppointmentEntryRest.makePost();
            Test.stopTest();

            Assert.areEqual(500, RestContext.response.statusCode, 'Expected status code 500 for malformed qualification subtypes');
        }
    }

    @IsTest
    static void testCreateSADetails() {
        setupIds();
        
        User testUser = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];
        
        System.runAs(testUser) {
            Lead testLead = new Lead(
                FirstName = 'Test',
                LastName = 'Lead',
                Email = 'test@lead.com'
            );
            insert testLead;

            ServiceAppointment sa = new ServiceAppointment(
                OwnerId = UserInfo.getUserId(),
                SchedStartTime = DateTime.now(),
                SchedEndTime = DateTime.now().addHours(2),
                ServiceTerritoryId = serviceTerritoryId,
                WorkTypeId = workTypeId,
                ParentRecordId = testLead.Id
            );
            insert sa;

            Test.startTest();
            AppointmentEntryRest.createSADetails(sa);
            Test.stopTest();

            List<SCH_Service_Appointment_Details__c> saDetailsList = [SELECT Id, SCH_ServiceAppointment__c, SCH_OrigemMarcacao__c 
                                                                       FROM SCH_Service_Appointment_Details__c 
                                                                       WHERE SCH_ServiceAppointment__c = :sa.Id];
            
            Assert.isFalse(saDetailsList.isEmpty(), 'SADetails should be created');
            Assert.areEqual('Web', saDetailsList[0].SCH_OrigemMarcacao__c, 'Origin should be Web');
        }
    }

    @IsTest
    static void testGetClientByMdmId() {
        User testUser = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];
        
        System.runAs(testUser) {
            Test.startTest();
            MDM_Client client = AppointmentEntryRest.getClientByMdmId('2462');
            Test.stopTest();

            Assert.isNotNull(client, 'Client should not be null');
            Assert.areEqual(2462, client.clientNumber, 'Client number should match');
        }
    }

    @IsTest
    static void testMakePost_Success() {
        setupIds();
        
        User testUser = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];
        
        System.runAs(testUser) {
            AppointmentDTO appointment = createAppointmentDTOWithIds();
            appointment.qualifications = null;

            String jsonBody = JSON.serialize(appointment);

            RestContext.request = new RestRequest();
            RestContext.request.requestUri = '/services/apexrest/appointments';
            RestContext.request.httpMethod = 'POST';
            RestContext.request.requestBody = Blob.valueOf(jsonBody);
            RestContext.response = new RestResponse();

            Test.startTest();
            AppointmentEntryRest.makePost();
            Test.stopTest();

            Assert.areEqual(201, RestContext.response.statusCode, 'Expected status code 201 for successful appointment creation');
            
            String responseBody = RestContext.response.responseBody.toString();
            Assert.isTrue(responseBody.contains('serviceAppointmentId'), 'Response should contain serviceAppointmentId');
        }
    }

    @IsTest
    static void testMakePost_Conflict_NoSlotsAvailable() {
        setupIds();
        
        User testUser = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];
        
        System.runAs(testUser) {
            Lead testLead = new Lead(
                FirstName = 'Conflict',
                LastName = 'Test',
                Email = 'conflict@lead.com'
            );
            insert testLead;
            
            AppointmentDTO appointment = createAppointmentDTOWithIds();
            appointment.qualifications = null;

            ServiceAppointment existingSA = new ServiceAppointment(
                OwnerId = UserInfo.getUserId(),
                SchedStartTime = DateTime.valueOf('2026-02-28 20:00:00'),
                SchedEndTime = DateTime.valueOf('2026-02-28 22:00:00'),
                ServiceTerritoryId = serviceTerritoryId,
                WorkTypeId = workTypeId,
                EngagementChannelTypeId = engagementTypeId,
                SCH_Service_Resource__c = serviceResourceId,
                ParentRecordId = testLead.Id,
                Status = 'Scheduled'
            );
            insert existingSA;

            String jsonBody = JSON.serialize(appointment);

            RestContext.request = new RestRequest();
            RestContext.request.requestUri = '/services/apexrest/appointments';
            RestContext.request.httpMethod = 'POST';
            RestContext.request.requestBody = Blob.valueOf(jsonBody);
            RestContext.response = new RestResponse();

            Test.startTest();
            AppointmentEntryRest.makePost();
            Test.stopTest();

            Assert.areEqual(409, RestContext.response.statusCode, 'Expected status code 409 for appointment slot conflict');
        }
    }

    @IsTest
    static void testMakePost_ExistingLeadByProjectId() {
        setupIds();
        
        User testUser = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];
        
        System.runAs(testUser) {
            String existingProjectId = 'new-project-id-123';
            
            Lead existingLead = new Lead(
                FirstName = 'Updated',
                LastName = 'Lead',
                Email = 'updated@lead.com',
                ProjectId__c = existingProjectId,
                Canal_de_Interacao__c = 'Scheduler Online',
                Loja_de_Angariacao__c = 'Alfragide'
            );
            insert existingLead;

            AppointmentDTO appointment = createAppointmentDTOWithIds();
            appointment.qualifications = null;
            
            for (AppointmentDTO.ExtendedFieldDTO field : appointment.lead.extendedFields) {
                if (field.name == 'ProjectId__c') {
                    field.value = existingProjectId;
                }
            }

            String jsonBody = JSON.serialize(appointment);

            RestContext.request = new RestRequest();
            RestContext.request.requestUri = '/services/apexrest/appointments';
            RestContext.request.httpMethod = 'POST';
            RestContext.request.requestBody = Blob.valueOf(jsonBody);
            RestContext.response = new RestResponse();

            Test.startTest();
            AppointmentEntryRest.makePost();
            Test.stopTest();

            Assert.areEqual(201, RestContext.response.statusCode, 'Expected status code 201 for successful appointment with existing lead');
            
            List<Lead> updatedLeads = [SELECT Id, FirstName FROM Lead WHERE ProjectId__c = :existingProjectId];
            Assert.isFalse(updatedLeads.isEmpty(), 'Lead should be updated');
        }
    }

    @IsTest
    static void testMakePost_EmptyQualificationsList() {
        setupIds();
        
        User testUser = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];
        
        System.runAs(testUser) {
            AppointmentDTO appointment = createAppointmentDTOWithIds();
            appointment.qualifications = new List<L2SAPIServiceHandler.QualificationWrapper>();

            String jsonBody = JSON.serialize(appointment);

            RestContext.request = new RestRequest();
            RestContext.request.requestUri = '/services/apexrest/appointments';
            RestContext.request.httpMethod = 'POST';
            RestContext.request.requestBody = Blob.valueOf(jsonBody);
            RestContext.response = new RestResponse();

            Test.startTest();
            AppointmentEntryRest.makePost();
            Test.stopTest();

            Assert.areEqual(201, RestContext.response.statusCode, 'Expected status code 201 for empty qualifications list');
        }
    }

    @IsTest
    static void testMakePost_BlankCanalIntegracao() {
        setupIds();
        
        User testUser = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];
        
        System.runAs(testUser) {
            AppointmentDTO appointment = createAppointmentDTOWithIds();
            appointment.qualifications = null;
            
            for (AppointmentDTO.ExtendedFieldDTO field : appointment.lead.extendedFields) {
                if (field.name == 'Canal_de_Interacao__c') {
                    field.value = '';
                }
            }

            String jsonBody = JSON.serialize(appointment);

            RestContext.request = new RestRequest();
            RestContext.request.requestUri = '/services/apexrest/appointments';
            RestContext.request.httpMethod = 'POST';
            RestContext.request.requestBody = Blob.valueOf(jsonBody);
            RestContext.response = new RestResponse();

            Test.startTest();
            AppointmentEntryRest.makePost();
            Test.stopTest();

            Assert.areEqual(201, RestContext.response.statusCode, 'Expected status code 201 for blank canal integracao');
        }
    }

    @IsTest
    static void testMakePost_BlankLojaDeAngariacao() {
        setupIds();
        
        User testUser = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];
        
        System.runAs(testUser) {
            AppointmentDTO appointment = createAppointmentDTOWithIds();
            appointment.qualifications = null;
            
            for (AppointmentDTO.ExtendedFieldDTO field : appointment.lead.extendedFields) {
                if (field.name == 'Loja_de_Angariacao__c') {
                    field.value = '';
                }
            }

            String jsonBody = JSON.serialize(appointment);

            RestContext.request = new RestRequest();
            RestContext.request.requestUri = '/services/apexrest/appointments';
            RestContext.request.httpMethod = 'POST';
            RestContext.request.requestBody = Blob.valueOf(jsonBody);
            RestContext.response = new RestResponse();

            Test.startTest();
            AppointmentEntryRest.makePost();
            Test.stopTest();

            Assert.areEqual(201, RestContext.response.statusCode, 'Expected status code 201 for blank loja de angariacao');
        }
    }

    @IsTest
    static void testCreateAssignedResource() {
        setupIds();
        
        User testUser = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];
        
        System.runAs(testUser) {
            Lead testLead = new Lead(
                FirstName = 'Test',
                LastName = 'Lead',
                Email = 'test@lead.com'
            );
            insert testLead;

            ServiceAppointment sa = new ServiceAppointment(
                OwnerId = UserInfo.getUserId(),
                SchedStartTime = DateTime.now(),
                SchedEndTime = DateTime.now().addHours(2),
                ServiceTerritoryId = serviceTerritoryId,
                WorkTypeId = workTypeId,
                ParentRecordId = testLead.Id
            );
            insert sa;

            Test.startTest();
            AppointmentEntryRest.createAssignedResource(sa, serviceResourceId);
            Test.stopTest();

            List<AssignedResource> assignedResources = [SELECT Id, ServiceAppointmentId, ServiceResourceId 
                                                        FROM AssignedResource 
                                                        WHERE ServiceAppointmentId = :sa.Id];
            
            Assert.isFalse(assignedResources.isEmpty(), 'AssignedResource should be created');
            Assert.areEqual(serviceResourceId, assignedResources[0].ServiceResourceId, 'ServiceResourceId should match');
        }
    }

    @IsTest
    static void testMakePost_LeadWithNoExtendedFields() {
        setupIds();
        
        User testUser = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];
        
        System.runAs(testUser) {
            AppointmentDTO appointment = createAppointmentDTOWithIds();
            appointment.lead.extendedFields = null;
            appointment.qualifications = null;

            String jsonBody = JSON.serialize(appointment);

            RestContext.request = new RestRequest();
            RestContext.request.requestUri = '/services/apexrest/appointments';
            RestContext.request.httpMethod = 'POST';
            RestContext.request.requestBody = Blob.valueOf(jsonBody);
            RestContext.response = new RestResponse();

            Test.startTest();
            AppointmentEntryRest.makePost();
            Test.stopTest();

            Assert.areEqual(400, RestContext.response.statusCode, 'Expected status code 400 when lead has no extended fields');
        }
    }

    @IsTest
    static void testMakePost_NullAppointment() {
        setupIds();
        
        User testUser = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];
        
        System.runAs(testUser) {
            String jsonBody = 'null';

            RestContext.request = new RestRequest();
            RestContext.request.requestUri = '/services/apexrest/appointments';
            RestContext.request.httpMethod = 'POST';
            RestContext.request.requestBody = Blob.valueOf(jsonBody);
            RestContext.response = new RestResponse();

            Test.startTest();
            AppointmentEntryRest.makePost();
            Test.stopTest();

            Assert.areEqual(400, RestContext.response.statusCode, 'Expected status code 400 for null appointment');
        }
    }
}