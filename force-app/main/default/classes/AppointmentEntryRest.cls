/**
 * @description       : REST API to create Service Appointments from external systems
 * @author            : Hersilio Belini de Oliveira
 * @group             :
 * @last modified on  : 2026-03-06
 * @last modified by  : Catarina Lopes
 **/
@RestResource(urlMapping = '/appointments/*')
global with sharing class AppointmentEntryRest {

    /**
    * @description Handles POST requests to create Service Appointments
    **/
    @HttpPost
    global static void makePost() {
        RestResponse res = RestContext.response;
        ResponseDTO returnDTO = new ResponseDTO();
        resultDTO resultDTO = new resultDTO();
        // Request input
        RestRequest request = RestContext.request;
        String body = request.requestBody.toString();
        System.debug('body --> \n' + body);

        try {

            // Deserialize the appointment data
            System.debug('+++++ Appointment DTO = '+String.valueOf(AppointmentDTO.class));
            AppointmentDTO appointment = (AppointmentDTO) JSON.deserialize(body, AppointmentDTO.class);

            // Validate input data
            if (appointment == null || appointment.lead == null || appointment.lead.extendedFields == null) {
                sendErrorResponse(res, 400, 'Missing required lead or extended fields information in the request.', body);
                return;
            }

            // Validate assigned resources
            // System.debug('appointment.assignedResources: ' + appointment.assignedResources);
            if (appointment.assignedResources == null || appointment.assignedResources.isEmpty()) {
                sendErrorResponse(res, 400, 'Assigned resources are missing in the request.', body);
                return;
            }

            ServiceAppointment sa = createServiceAppointmentLead(appointment);

            if (sa.Description == 'Malformed Qualification Subtypes') {
                sendErrorResponse(res, 500, 'Qualification subtypes are improperly formatted.', body);
                return;
            }

            // Check for available appointment slots
            if (!hasAppointmentSlots(sa)) {
                sendErrorResponse(res, 409, 'Appointment slot not available.', body);
                return;
            }

            // Calculate Duration
            Decimal durationInHours = (sa.SchedEndTime.getTime() - sa.schedStartTime.getTime())/1000/60/60;
            sa.duration = durationInHours;
            // System.debug(sa);
            insert sa;
            createAssignedResource(sa, appointment.assignedResources[0].serviceResourceId);
            createSADetails(sa);

            resultDTO.serviceAppointmentId = sa.Id;
            resultDTO.parentRecordId = sa.ParentRecordId;
            returnDTO.result = resultDTO;

            res.statusCode = 201;
            res.responseBody = Blob.valueOf(JSON.serialize(returnDTO));

            logSuccess(body, sa);

        } catch (Exception e) {
            // System.debug('Error: ' + e.getMessage());
            logError(500, e.getMessage(), body);
            sendErrorResponse(res, 500, 'Internal Server Error: ' + e.getMessage(), body);
        }
    }

    /**
    * @description Logs successful integration request to IntegrationLog__c
    * @param body The request body
    * @param sa The created ServiceAppointment
    **/
    private static void logSuccess(String body, ServiceAppointment sa) {
        IntegrationLogHandler.IntegrationLogWrapper logWrapper = new IntegrationLogHandler.IntegrationLogWrapper();
        logWrapper.requestBody = body;
        logWrapper.integrationKey = 'AppointmentEntry';
        logWrapper.httpStatusCode = 201;
        logWrapper.startDateTime = System.now();
        logWrapper.endDateTime = System.now();
        logWrapper.direction = 'Inbound';
        logWrapper.status = 'Success';
        logWrapper.targetSObject = 'ServiceAppointment';
        logWrapper.targetRecordId = sa.Id;
        logWrapper.sourceSystem = 'L2Service';
        logWrapper.targetSystem = 'Salesforce';
        logWrapper.httpMethod = 'POST';
        logWrapper.endpoint = '/appointments/*';
        IntegrationLogHandler.createIntegrationLog(new List<IntegrationLogHandler.IntegrationLogWrapper>{ logWrapper });
    }

    /**
    * @description Logs error integration request to IntegrationLog__c
    * @param statusCode The HTTP status code
    * @param message The error message
    * @param body The request body
    **/
    private static void logError(Integer statusCode, String message, String body) {
        IntegrationLogHandler.IntegrationLogWrapper logWrapper = new IntegrationLogHandler.IntegrationLogWrapper();
        logWrapper.requestBody = body;
        logWrapper.integrationKey = 'AppointmentEntry';
        logWrapper.httpStatusCode = statusCode;
        logWrapper.startDateTime = System.now();
        logWrapper.endDateTime = System.now();
        logWrapper.direction = 'Inbound';
        logWrapper.status = 'Error';
        logWrapper.errorMessage = message;
        logWrapper.sourceSystem = 'L2Service';
        logWrapper.targetSystem = 'Salesforce';
        logWrapper.httpMethod = 'POST';
        logWrapper.endpoint = '/appointments/*';
        IntegrationLogHandler.createIntegrationLog(new List<IntegrationLogHandler.IntegrationLogWrapper>{ logWrapper });
    }

    /**
    * @description Retrieves MDM client by MDM ID
    * @param mdmId The MDM client identifier
    * @return The MDM client record
    **/
    public static MDM_Client getClientByMdmId(String mdmId) {
        List<MDM_Client> clients;

        if (Test.isRunningTest()){
            String clientString = '{"active":true, "addresses":[{"city":"MAIA","complementaryDeliveryAddress":"MORADIA COSTA DO SOL","countryCode":"PT","isContactPriority":true,"isQualitative":true,"postalCode":"4475","usages":[]}],"clientNumber":2462,"createdAt":"2022-07-06T14:25:01.124Z","creationStoreCode":"1","declaredStoreAttachement":"1","emailAddresses":[{"email":"teste@teste.com"}],"inhabitant":{"administrativeIdentifiers":{},"civility":"MS","firstName":"MAIA","lastName":"COSTA DO SOL"},"phones":[{"isContactPriority":false,"numberSF":"+351910974671","type":"LANDLINE"},{"isContactPriority":true,"number":"+351910974671"}],"universalClientNumber":"LMPT2462","updatedAt":"' + System.now().addDays(20).format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') + '"},"_meta":{}}';
            MDM_Client c = (MDM_Client)JSON.deserialize(clientString, MDM_Client.class);
            clients = new List<MDM_Client>{c};
        }else{
            clients = c_PesquisaConta.getAccountsMdm(new List<String>{mdmId}, 'Nº de Cliente');
        }

        // TODO rever estrutura de erro
        // if (clients == null || clients.isEmpty()) {
        //     sendErrorResponse(res, 404, 'No client found with the given MDM ID.');
        //     return;
        // }

        MDM_Client client = clients[0];
        // System.debug('++++ client = '+client);

        return client;
    }

    /**
    * @description Creates Service Appointment Details record
    * @param sa The Service Appointment
    **/
    public static void createSADetails(ServiceAppointment sa) {
        SCH_Service_Appointment_Details__c saDetails = new SCH_Service_Appointment_Details__c();
        saDetails.SCH_ServiceAppointment__c = sa.Id;
        saDetails.SCH_OrigemMarcacao__c = 'Web';
        insert saDetails;
    }

    /**
    * @description Checks if client is a company (professional client)
    * @param client The MDM client to check
    * @return True if client is a company
    **/
    private static Boolean isClienteEmpresa(MDM_Client client){
        System.debug(client.inhabitant.lastName);
        return String.isBlank(client.inhabitant.lastName) || client.inhabitant.lastName == '-'; //Clientes empresa não têm lastName. Mesmo critério usado em c_PesquisaConta.upsertAccountSF
    }

    /**
    * @description Creates a Service Appointment from appointment DTO and related Lead
    * @param appointment The appointment DTO containing all appointment data
    * @return The created ServiceAppointment (not yet inserted)
    **/
    private static ServiceAppointment createServiceAppointmentLead(AppointmentDTO appointment) {

        String mdmId;
        String leadSource;
        String projectId;
        String storeId;
        String formattedStore;
        String canalIntegracao;
        String ownerId;

        System.debug('++++ Appointment = '+appointment);
        System.debug('++++ appointment.lead.extendedFields = '+appointment.lead.extendedFields);

        ServiceAppointment sa = new ServiceAppointment();
        sa.ServiceTerritoryId = appointment.serviceAppointment.serviceTerritoryId;
        sa.SchedStartTime = appointment.serviceAppointment.schedStartTime;
        sa.SchedEndTime = appointment.serviceAppointment.schedEndTime;
        sa.WorkTypeId = appointment.serviceAppointment.workTypeId;
        sa.EngagementChannelTypeId = appointment.serviceAppointment.engagementChannelTypeId;
        sa.Description = appointment.serviceAppointment.description;
        sa.SCH_Service_Resource__c = appointment.assignedResources[0].serviceResourceId;

        ownerId = getUserFromServiceResource(appointment.assignedResources[0].serviceResourceId);
        sa.OwnerId = ownerId;

        System.debug('+++++ appointment.serviceAppointment.extendedFields = '+appointment.serviceAppointment.extendedFields);
        if (appointment.serviceAppointment.extendedFields != null) {
            for (AppointmentDTO.ExtendedFieldDTO field : appointment.serviceAppointment.extendedFields) {
                if (field.name.equalsIgnoreCase('IsAnonymousBooking')) {
                    sa.IsAnonymousBooking = Boolean.valueOf(field.value);
                }
            }
        }

        // Upsert Lead from client data
        Lead lead = new Lead();

        System.debug('+++++ appointment.lead.extendedFields = '+appointment.lead.extendedFields);

        for (AppointmentDTO.ExtendedFieldDTO field : appointment.lead.extendedFields) {
            System.debug('++++ field = '+field);
            System.debug('++++ field.name = '+field.name);
            System.debug('++++ field.value = '+field.value);
            if (field.name.equalsIgnoreCase('Numero_de_Conta_na_lead__c')) {
                mdmId = field.value;
                System.debug('+++++ MDM id = '+mdmId);
            }

            if (field.name.equalsIgnoreCase('LeadSource')) {
                leadSource = field.value;
                System.debug('+++++ leadSource = '+leadSource);
            }

            if (field.name.equalsIgnoreCase('ProjectId__c')) {
                projectId = field.value;
                System.debug('+++++ projectId = '+projectId);

            }

            if (field.name.equalsIgnoreCase('Canal_de_Interacao__c')) {
                canalIntegracao = field.value;
                System.debug('+++++ canalIntegracao = '+canalIntegracao);
            }

            if (field.name.equalsIgnoreCase('Loja_de_Angariacao__c')) {
                storeId = field.value;
                System.debug('+++++ storeId = '+storeId);
            }

        }

        if (String.isNotBlank(projectId)) {
            System.debug('++++ Project Id is not Blank!');
            List<Lead> existingLeads = [Select Id, Loja_de_Angariacao__c, Country, Canal_de_Interacao__c, Description, ProjectId__c FROM Lead WHERE ProjectId__c = :projectId LIMIT 1];
            if (!existingLeads.isEmpty()) {
                lead = existingLeads[0];
            }
        } else {
            System.debug('++++ Project Id is Blank! Proceeding with new lead!');
        }

        lead.OwnerId = ownerId;


        if (appointment.qualifications != null && !appointment.qualifications.isEmpty()) {
            L2SAPIServiceHandler.QualificationWrapper[] qualifications = appointment.qualifications;
            System.debug('++++ Qualifications = '+qualifications);
            String qualification1Parcel = '';
            String qualification2Parcel = '';
            String qualification1MappedField = '';
            String qualification2MappedField = '';
            List<Boolean> qualificationValidationList = new List<Boolean>();
            List<QualificationMapping__mdt> qualificationMappings = [SELECT Id, 
                                                                            DeveloperName,
                                                                            SubtypeContains__c,
                                                                            MapsToField__c
                                                                    FROM QualificationMapping__mdt
                                                                    WITH SECURITY_ENFORCED];


            for (L2SAPIServiceHandler.QualificationWrapper qualification : qualifications) {
                System.debug('++++ Evaluating qualification with subtype == '+qualification.subtype);
                Boolean successfullyMapped = false;
                for (QualificationMapping__mdt mapping : qualificationMappings) {
                    if (qualification.subtype.contains(mapping.SubtypeContains__c)) {
                        successfullyMapped = true;
                        switch on mapping.DeveloperName {
                            when 'Qualification1' {
                                qualification1MappedField = mapping.MapsToField__c;
                                qualification1Parcel+= 'Qualificação 1 \n';
                                for (L2SAPIServiceHandler.QualificationQuestions question : qualification.questions) {
                                qualification1Parcel += question.label+'\n';

                                for (L2SAPIServiceHandler.QualificationAnswer answer : question.answers){
                                    qualification1Parcel += '- '+answer.label+'\n';
                                }
                                qualification1Parcel += '\n';
                                }
                            }
                            when 'Qualification2' {
                                qualification2MappedField = mapping.MapsToField__c;
                                qualification2Parcel+= 'Qualificação 2 \n';
                                for (L2SAPIServiceHandler.QualificationQuestions question : qualification.questions) {
                                    qualification2Parcel += question.label+'\n';
                                    for (L2SAPIServiceHandler.QualificationAnswer answer : question.answers){
                                        qualification2Parcel += '- '+answer.label+'\n';
                                    }
                                    qualification2Parcel += '\n';
                                }
                            }
                        }
                    }
                }
                System.debug('++++ successfullyMapped == '+successfullyMapped);
                qualificationValidationList.add(successfullyMapped);
            }

            System.debug('++++ qualificationValidationList == '+qualificationValidationList);
            for (Boolean correctlyMapped : qualificationValidationList) {
                if (!correctlyMapped) {
                    sa.put('Description','Malformed Qualification Subtypes');
                    return sa;
                }
            }

            if (String.isNotBlank(qualification1MappedField) && qualification1MappedField == qualification2MappedField) {
                sa.put(qualification1MappedField, qualification1Parcel+qualification2Parcel);
                lead.put(qualification1MappedField, qualification1Parcel+qualification2Parcel);
            } else if (String.isNotBlank(qualification1MappedField) || String.isNotBlank(qualification2MappedField)) {
                if (String.isNotBlank(qualification1Parcel)) {
                    lead.put(qualification1MappedField, qualification1Parcel);
                    sa.put(qualification1MappedField, qualification1Parcel);
                }
                if(String.isNotBlank(qualification2Parcel)){
                    lead.put(qualification2MappedField, qualification2Parcel);
                    sa.put(qualification2MappedField, qualification2Parcel);
                }
            }
        }

        MDM_Client client = getClientByMdmId(mdmId);
        System.debug('+++++++++ Cliente: ' + client );

        lead.Numero_de_Conta_na_lead__c = String.valueOf(client.clientNumber);


        if(isClienteEmpresa(client)){
            lead.FirstName = client.inhabitant.FirstName;
            lead.LastName = '.';
            lead.NIF__c = String.isEmpty(client.professionalOrganization.administrativeCodes.nif) ? '': client.professionalOrganization.administrativeCodes.nif;

            for (MDM_Client.Member member : client.members){
                if (member.isLegalRepresentative){
                    for (MDM_Client.EmailAddress emailAddress : member.emailAddresses){
                        if (emailAddress.isContactPriority)
                            lead.Email = emailAddress.email;
                            sa.Email = lead.email;
                        break;
                    }
                    for (MDM_Client.Phone phone : member.phones){
                        if (phone.isContactPriority)
                            lead.MobilePhone = phone.numberSF != null ? phone.numberSF : '';
                            lead.Phone = phone.numberSF != null ? phone.numberSF : '';
                            sa.Phone = lead.Phone;
                        break;
                    }
                    break;
                }
            }

            System.debug('++++++++ Lead Cliente Profissional: ' + lead);

        } else {
            lead.FirstName = client.inhabitant.firstName;
            lead.LastName = client.inhabitant.lastName;
            lead.Email = client.emailAddresses.isEmpty() ? 'emailnotfound@email.com' : client.emailAddresses[0].email;
            lead.NIF__c = String.isEmpty(client.inhabitant.administrativeIdentifiers.nif) ? '': client.inhabitant.administrativeIdentifiers.nif;
            if (client.phones.isEmpty()){
                lead.MobilePhone = '';
                lead.Phone = '';
            }else{
                lead.MobilePhone = client.phones[0].numberSF != null ? client.phones[0].numberSF : '';
                lead.Phone = client.phones[0].numberSF != null ? client.phones[0].numberSF : '';
            }
            sa.Email = lead.email;
            sa.Phone = lead.Phone;
            System.debug('+++++++ Lead Cliente Particular: ' + lead);
        }


        Integer clientStore = Integer.valueOf(client.declaredStoreAttachement);
        String formattedClientStore;

        List<ServiceTerritory> serviceTerritoryList = New List<ServiceTerritory>();

        serviceTerritoryList = [SELECT Id, Name, ParentTerritory.Name FROM ServiceTerritory WHERE Id =: sa.ServiceTerritoryId];

        if(!serviceTerritoryList.isEmpty()){
            formattedStore = serviceTerritoryList[0].Name;
        }
        System.debug('Canal de integração storeId: ' + canalIntegracao);
        if (String.isBlank(canalIntegracao)){
            System.debug('111111');
            lead.Canal_de_Interacao__c = 'Scheduler Online';
            lead.Equipa__c = 'Loja';
        } else {
            System.debug('2222222');
            lead.Canal_de_Interacao__c = canalIntegracao;
            lead.Equipa__c = 'Loja';
        }

        lead.Loja_de_Angariacao__c = formattedStore;

        if(projectId != null){
            lead.ProjectId__c = projectId;
        }

        lead.LeadSource = String.isNotBlank(leadSource) ? leadSource : 'Webform';

        Database.DMLOptions dmlOptions = new Database.DMLOptions();
        dmlOptions.assignmentRuleHeader.useDefaultRule = false;
        lead.setOptions(dmlOptions);


        upsert lead;

        // Associate SA with Lead
        sa.ParentRecordId = lead.Id;
        System.debug('lead.id: ' + lead.Id);
        return sa;
    }

    /**
    * @description Gets the User ID associated with a Service Resource
    * @param serviceResourceId The Service Resource ID
    * @return The Related User ID, or current user if not found
    **/
    private static Id getUserFromServiceResource(Id serviceResourceId){
        List<ServiceResource> serviceResources = [SELECT Id, RelatedRecordId FROM ServiceResource WHERE Id =: serviceResourceId];
        if (serviceResources.size() == 0) return UserInfo.getUserId();
        return serviceResources[0].RelatedRecordId;
    }

    /**
    * @description Checks if appointment slot is available for the given Service Appointment
    * @param sa The Service Appointment to check
    * @return True if slot is available, False if there is a conflict
    **/
    private static Boolean hasAppointmentSlots(ServiceAppointment sa) {
        System.debug('++++ Entered hasAppointmentSlots');
        System.debug('++++ ServiceAppointment sa = '+sa);
        Integer reservedTime = sa.WorkType.BlockTimeAfterAppointment == null ? 15 : Integer.valueOf(sa.WorkType.BlockTimeAfterAppointment);
        DateTime adjustedEndTime = sa.SchedEndTime.addMinutes(reservedTime);
        DateTime adjustedStartTime = sa.SchedStartTime.addMinutes(-reservedTime);
        List<ServiceAppointment> existingAppointments = [SELECT Id, SchedStartTime, SchedEndTime FROM ServiceAppointment WHERE
                                                         SchedStartTime < :adjustedEndTime AND
                                                         SchedEndTime > :adjustedStartTime AND
                                                         EngagementChannelTypeId = :sa.EngagementChannelTypeId AND
                                                         ServiceTerritoryId = :sa.ServiceTerritoryId AND
                                                         SCH_Service_Resource__c = :sa.SCH_Service_Resource__c AND
                                                         Status != 'Canceled'];

        for (ServiceAppointment existing : existingAppointments) {
            if (existing.SchedStartTime < adjustedEndTime && existing.SchedEndTime > adjustedStartTime) {
                return false; // Conflict found
            }
        }
        return true;
    }

    /**
    * @description Creates an AssignedResource linking Service Appointment to Service Resource
    * @param sa The Service Appointment
    * @param serviceResourceId The Service Resource ID
    **/
    public static void createAssignedResource(ServiceAppointment sa, String serviceResourceId) {
            // Create AssignedResource record to link ServiceAppointment with the scheduler resource
            AssignedResource ar = new AssignedResource();
            ar.ServiceAppointmentId = sa.Id;
            ar.ServiceResourceId = serviceResourceId;
            ar.isPrimaryResource = true;
            ar.isRequiredResource = true;
            insert ar; // Insert AssignedResource record to establish the link
    }

    /**
    * @description Sends error response and logs the error
    * @param res The REST response
    * @param statusCode The HTTP status code
    * @param message The error message
    * @param body The request body for logging
    **/
    private static void sendErrorResponse(RestResponse res, Integer statusCode, String message, String body) {
        res.statusCode = statusCode;
        res.responseBody = Blob.valueOf(JSON.serialize(new ErrorResponse(message)));
        logError(statusCode, message, body);
    }

    /**
    * @description Response wrapper for the REST API
    **/
    public class ResponseDTO {
        public resultDTO result { get; set; }
    }

    /**
    * @description Result data containing Service Appointment details
    **/
    public class resultDTO {
        public List<String> assignedResourceIds { get; set; }
        public String parentRecordId { get; set; }
        public String serviceAppointmentId { get; set; }
    }

    /**
    * @description Error response wrapper
    **/
    public class ErrorResponse {
        public String error { get; set; }
        public ErrorResponse(String message) {
            error = message;
        }
    }
}
