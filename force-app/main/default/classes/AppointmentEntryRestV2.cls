/**
 * @description       : REST API to create Service Appointments from external systems
 * @author            : Hersilio Belini de Oliveira
 * @group             :
 * @last modified on  : 2025-09-03
 * @last modified by  : Felipe Mendonça
**/

// 1 - appointments/v2/invalido - Erro
// 2 - appointments/v2/appointment/ - Cria appointment
// 3 - appointments/v2/appointment/appointmentId - Retorna o appointment (PATCH)
// 4 - appointments/v2/appointment/appointmentId - Retorna o appointment (CANCEL)
// 5 - appointments/v2/appointment/invalido - Erro
// 6 - appointments/v2/client/invalido - Erro
// 7 - appointments/v2/client/clientNumber - Retorna lista de agendamentos do cliente.

@RestResource(urlMapping = '/appointments/v2/*')
global without sharing class AppointmentEntryRestV2 {

    public static RestResponse res;
    public static ClientAppointmentsResponseDTO clientAppointmentsResponseDTO;

    private static void createAppointment(AppointmentDTOV2 appointment){
        try {
            // Validate input data
            if (appointment == null || appointment.customer == null) {
                sendErrorResponse(res, 400, 'Missing appointment data.');
                return;
            }

            // Extract MDM Id from extended fields
            String mdmId = appointment.customer.mdmId;
            if (mdmId == null) {
                sendErrorResponse(res, 400, 'MDM ID is missing in the request.');
                return;
            }

            List<MDM_Client> clients;

            if (Test.isRunningTest()){
                String clientString = '{"active":true, "addresses":[{"city":"MAIA","complementaryDeliveryAddress":"MORADIA COSTA DO SOL","countryCode":"PT","isContactPriority":true,"isQualitative":true,"postalCode":"4475","usages":[]}],"clientNumber":2462,"createdAt":"2022-07-06T14:25:01.124Z","creationStoreCode":"1","declaredStoreAttachement":"1","emailAddresses":[{"email":"teste@teste.com"}],"inhabitant":{"administrativeIdentifiers":{},"civility":"MS","firstName":"MAIA","lastName":"COSTA DO SOL"},"phones":[{"isContactPriority":false,"numberSF":"+351910974671","type":"LANDLINE"},{"isContactPriority":true,"number":"+351910974671"}],"universalClientNumber":"LMPT2462","updatedAt":"' + System.now().addDays(20).format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') + '"},"_meta":{}}';
                MDM_Client c = (MDM_Client)JSON.deserialize(clientString, MDM_Client.class);
                clients = new List<MDM_Client>{c};
            }else{
                clients = c_PesquisaConta.getAccountsMdm(new List<String>{mdmId}, 'Nº de Cliente');
            }
            
            if (clients == null || clients.isEmpty()) {
                sendErrorResponse(res, 404, 'No client found with the given MDM ID.');
                return;
            }

            MDM_Client client = clients[0];
            System.debug(client);

            // Validate assigned resources
            if (appointment.resources == null || appointment.resources.isEmpty()) {
                sendErrorResponse(res, 400, 'Assigned resources are missing in the request.');
                return;
            }

            ServiceAppointment sa = createLeadAndSetServiceAppointment(client, appointment);

            // Check for available appointment slots
            if (!hasAppointmentSlots(sa)) {
                sendErrorResponse(res, 409, 'Appointment slot not available.');
                return;
            }
            // Calculate Duration
            Decimal durationInHours = (sa.SchedEndTime.getTime() - sa.schedStartTime.getTime())/1000/60/60;
            sa.duration = durationInHours;
            System.debug(sa);
            insert sa; // Insert ServiceAppointment record
            createAssignedResource(sa, appointment.resources[0].serviceResourceId);
            createSADetails(sa);

            sendSuccessResponse(res, 201, sa);

        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            sendErrorResponse(res, 500, 'Internal Server Error: ' + e.getMessage());
        }
    }

    private static void patchAppointment(Id appointmentId, AppointmentDTOV2 appointmentDTO){
        try {
            // QUESTION: Devemos receber o ID na URI ou no Request Body?
            List<ServiceAppointment> appointments = [SELECT Id FROM ServiceAppointment where Id = :appointmentId];
            if (appointments == null || appointments.isEmpty()){
                sendErrorResponse(res, 400, 'Appointment not found');
                return;
            }
            ServiceAppointment sa = appointments[0];
            
            //Add Validation for Startime and Endtime changes - Bruno Silva - 03/09/2025
            if ((appointmentDTO.appointment.schedStartTime == null || appointmentDTO.appointment.schedEndTime == null) && (appointmentDTO.appointment.schedStartTime >= appointmentDTO.appointment.schedEndTime)){
                sendErrorResponse(res, 400, 'Appointment start time must be provided and be before end time.');
                return;
            }

            sa.SchedStartTime = appointmentDTO.appointment.schedStartTime;
            sa.SchedEndTime = appointmentDTO.appointment.schedEndTime;

            sa.Description = appointmentDTO.appointment.description != null ? appointmentDTO.appointment.description : ''; //Always provide a description to avoid null value
            update sa;

            sendSuccessResponse(res, 200, sa);
        } catch (Exception e) {
            res.statusCode = 500;
            res.responseBody = Blob.valueOf('Error'); // TODO: error message
        }
    }

    private static void cancelAppointment(Id appointmentId, AppointmentDTOV2 appointmentDTO){
        try {
            // QUESTION: Devemos receber o ID na URI ou no Request Body?
            List<ServiceAppointment> appointments = [SELECT Id FROM ServiceAppointment where Id = :appointmentId];
            if (appointments == null || appointments.isEmpty()){
                sendErrorResponse(res, 400, 'Appointment not found');
                return;
            }
            ServiceAppointment sa = appointments[0];
            sa.Status = 'Canceled';
            // sa.description = appointmentDTO.cancellation.reason; // TODO: aonde guardar a cancellation.
            update sa;

            sendSuccessResponse(res, 200, sa);
        } catch (Exception e) {
            res.statusCode = 500;
            res.responseBody = Blob.valueOf('Error cancelling appointment.'); // TODO: improving error message
        }
    }
    
    private static void searchClientAppointments(String clientMdmId){
        try{
            List<ServiceAppointment> appointments = new List<ServiceAppointment>();
            
            // We need to do 3 queries because of a few reasons:
            // 1 - The appointments can be associated with Leads, Accounts and Opportunities, 
            // and the mdmId is not Unique between records.
            // 2 - It is forbidden to OR the subqueries in a single query. 
            // Ex.: [... WHERE ParentRecordId IN (SUBQUERY 1) OR ParentRecordId IN (SUBQUERY 2)]
            List<ServiceAppointment> appointmentsLead = 
                [SELECT Id, AppointmentNumber, CreatedDate, WorkType.Name, SchedStartTime, SchedEndTime, 
                Status, DurationType, DurationInMinutes, ServiceTerritory.Name, SCH_Google_Meet_URL__c, 
                HasMeetUrl__c, Description, ParentRecordId, ParentRecord.Name FROM ServiceAppointment 
                WHERE ParentRecordId IN 
                (SELECT Id FROM Lead WHERE Numero_de_Conta_na_lead__c = :clientMdmId)];

            List<ServiceAppointment> appointmentsAccs = 
                [SELECT Id, AppointmentNumber, CreatedDate, WorkType.Name, SchedStartTime, SchedEndTime, 
                Status, DurationType, DurationInMinutes, ServiceTerritory.Name, SCH_Google_Meet_URL__c, 
                HasMeetUrl__c, Description, ParentRecordId, ParentRecord.Name FROM ServiceAppointment 
                WHERE ParentRecordId IN 
                (SELECT Id FROM Account WHERE Numero_de_Conta__c = :clientMdmId)];

            List<ServiceAppointment> appointmentsOpps = 
                [SELECT Id, AppointmentNumber, CreatedDate, WorkType.Name, SchedStartTime, SchedEndTime, 
                Status, DurationType, DurationInMinutes, ServiceTerritory.Name, SCH_Google_Meet_URL__c, 
                HasMeetUrl__c, Description, ParentRecordId, ParentRecord.Name FROM ServiceAppointment 
                WHERE ParentRecordId IN 
                (SELECT Id FROM Opportunity WHERE Account.Numero_de_Conta__c = :clientMdmId)];

            appointments.addAll(appointmentsLead);
            appointments.addAll(appointmentsAccs);
            appointments.addAll(appointmentsOpps);

            if (appointments == null || appointments.isEmpty()){
                sendErrorResponse(res, 404, 'No appointments found for the client.');
                return;
            }
            
            sendSuccessResponse(res, 200, appointments);

        }catch(Exception e){
            sendErrorResponse(res, 500, 'Something went wrong. Error: ' + e.getMessage());
        }
    }

    @HttpPost
    global static void makePost() {
        res = RestContext.response;

        String process = RestContext.request.requestURI.split('/')[3]; // Current process that is being requested by the user.

        RestRequest request = RestContext.request;
        String jsonString = request.requestBody.toString();
   
        AppointmentDTOV2 appointmentDTO = (AppointmentDTOV2) JSON.deserialize(jsonString, AppointmentDTOV2.class);
        Id appointmentId = request.requestURI.split('/')[4];
        
        switch on process{
            when 'appointment'{
                if (appointmentDTO.operation.equalsIgnoreCase('CREATE')){
                    createAppointment(appointmentDTO);
                }
                else if (appointmentDTO.operation.equalsIgnoreCase('PATCH')){
                    patchAppointment(appointmentId, appointmentDTO);
                }
                else if (appointmentDTO.operation.equalsIgnoreCase('CANCEL')){
                    cancelAppointment(appointmentId, appointmentDTO);
                }
                else{
                    sendErrorResponse(res, 400, 'Invalid operation.');
                }
            }
            when 'client'{
                String clientId = request.requestURI.split('/')[4];
                if (String.isEmpty(clientId)){
                    sendErrorResponse(res, 400, 'Client ID is required.');
                }
                searchClientAppointments(clientId);
            }
            when else{
                sendErrorResponse(res, 400, 'Invalid process.');
            }
        }
    }

    public static void createSADetails(ServiceAppointment sa) {
        SCH_Service_Appointment_Details__c saDetails = new SCH_Service_Appointment_Details__c();
        saDetails.SCH_ServiceAppointment__c = sa.Id;
        saDetails.SCH_OrigemMarcacao__c = 'Web';
        insert saDetails;
    }

    private static Boolean isClienteEmpresa(MDM_Client client){
        System.debug(client.inhabitant.lastName);
        return String.isBlank(client.inhabitant.lastName) || client.inhabitant.lastName == '-'; //Clientes empresa não têm lastName. Mesmo critério usado em c_PesquisaConta.upsertAccountSF
    }

    private static ServiceAppointment createLeadAndSetServiceAppointment(MDM_Client client, AppointmentDTOV2 appointmentDTO) {
        ServiceAppointment sa = new ServiceAppointment();
        sa = (ServiceAppointment) JSON.deserialize(JSON.serialize(appointmentDTO.appointment), ServiceAppointment.class);
        sa.IsAnonymousBooking = true;
        sa.OwnerId = getUserFromServiceResource(appointmentDTO.resources[0].serviceResourceId);
        sa.SCH_Service_Resource__c = appointmentDTO.resources[0].serviceResourceId;

        // Insert Lead from client data
        Lead lead = new Lead();
        System.debug('Cliente: '+ client );
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
            System.debug('Lead Cliente Profissional: ' + lead);

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
            System.debug('Lead Cliente Particular: ' + lead);
        }

        List<ServiceTerritory> serviceTerritoryList = [SELECT Id, Name, ParentTerritory.Name FROM ServiceTerritory WHERE Id =: appointmentDTO.appointment.serviceTerritoryId];
        String lojaDeAngariacao = '';
        if(!serviceTerritoryList.isEmpty()){
            String parentTerritoryName = serviceTerritoryList[0].ParentTerritory.Name;
            lojaDeAngariacao = String.isBlank(parentTerritoryName) ? serviceTerritoryList[0].Name : parentTerritoryName;
        }
        lead.Canal_de_Interacao__c = 'Scheduler Online';
        lead.Loja_de_Angariacao__c = lojaDeAngariacao;

        insert lead;

        // Associate SA with Lead
        sa.ParentRecordId = lead.Id;
        return sa;
    }

    private static Id getUserFromServiceResource(Id serviceResourceId){
        List<ServiceResource> serviceResources = [SELECT Id, RelatedRecordId FROM ServiceResource WHERE Id =: serviceResourceId];
        if (serviceResources.size() == 0) return UserInfo.getUserId();
        return serviceResources[0].RelatedRecordId;
    }

    private static Boolean hasAppointmentSlots(ServiceAppointment sa) {
        Integer reservedTime = sa.WorkType.BlockTimeAfterAppointment == null ? 15 : Integer.valueOf(sa.WorkType.BlockTimeAfterAppointment);
        DateTime adjustedEndTime = sa.SchedEndTime.addMinutes(reservedTime);
        DateTime adjustedStartTime = sa.SchedStartTime.addMinutes(-reservedTime);
        List<ServiceAppointment> existingAppointments = 
            [SELECT Id, SchedStartTime, SchedEndTime FROM ServiceAppointment WHERE 
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

    private static void createAssignedResource(ServiceAppointment sa, String serviceResourceId) {
            // Create AssignedResource record to link ServiceAppointment with the scheduler resource
            AssignedResource ar = new AssignedResource();
            ar.ServiceAppointmentId = sa.Id;
            ar.ServiceResourceId = serviceResourceId;
            ar.isPrimaryResource = true;
            ar.isRequiredResource = true;
            insert ar; // Insert AssignedResource record to establish the link
    }

    private static void sendSuccessResponse(RestResponse res, Integer statusCode, ServiceAppointment sa){
            AppointmentResponseDTO responseDTO;
            ResultDTO resultDTO;

            resultDTO = (ResultDTO)JSON.deserialize(JSON.serialize(sa), ResultDTO.class);
            resultDTO.assignedResourceIds = new List<String>{sa.SCH_Service_Resource__c};
            responseDTO.result = resultDTO;

            res.statusCode = 201;
            res.responseBody = Blob.valueOf(JSON.serialize(responseDTO));
    }

    private static void sendSuccessResponse(RestResponse res, Integer statusCode, List<ServiceAppointment> appointments){
        ClientAppointmentsResponseDTO responseDTO = new ClientAppointmentsResponseDTO();
        responseDTO.totalSize = appointments.size();
        responseDTO.records = appointments;

        res.statusCode = statusCode;
        res.responseBody = Blob.valueOf(JSON.serialize(responseDTO));
    }

    private static void sendErrorResponse(RestResponse res, Integer statusCode, String message) {
        res.statusCode = statusCode;
        res.responseBody = Blob.valueOf(JSON.serialize(new ErrorResponse(statusCode, message)));
    }

    private class AppointmentResponseDTO {
        public ResultDTO result { get; set; }
    }

    private class ResultDTO {
        public List<String> assignedResourceIds { get; set; }
        public String parentRecordId { get; set; }
        public String serviceAppointmentId { get; set; }
        public String appointmentNumber { get; set; }
        public String status { get; set; }
        public DateTime schedStartTime { get; set; }
        public DateTime schedEndTime { get; set; }
    }

    private class ClientAppointmentsResponseDTO{
        public Integer totalSize { get; set; }
        public List<ServiceAppointment> records { get; set; }
    }

    private class ErrorResponse {
        public ErrorDTO error { get; set; }
        public final Map<Integer, String> errorMap = new Map<Integer, String>{
            400 => 'Invalid Request',
            401 => 'Unauthenticated',
            404 => 'Not Found',
            409 => 'Conflict Found',
            500 => 'Internal Error'
        };

        public ErrorResponse(Integer code, String message) {
            error.code = errorMap.get(code);
            error.message = message;
        }
    }

    private class ErrorDTO {
        public String code { get; set; }
        public String message { get; set; }
        public String requestId { get; set; }
    }
}