/**
 * @description       : REST API to create Service Appointments from external systems
 * @author            : Hersilio Belini de Oliveira
 * @group             :
 * @last modified on  : 2025-09-03
 * @last modified by  : Felipe Mendonça
**/
@RestResource(urlMapping = '/appointments/*')
global without sharing class AppointmentEntryRest {

    @HttpPost
    global static void makePost() {
        RestResponse res = RestContext.response;
        ResponseDTO returnDTO = new ResponseDTO();
        resultDTO resultDTO = new resultDTO();

        try {
            // Request input
            RestRequest request = RestContext.request;
            String body = request.requestBody.toString();
            System.debug('body -->' + body);

            // Deserialize the appointment data
            AppointmentDTO appointment = (AppointmentDTO) JSON.deserialize(body, AppointmentDTO.class);

            // Validate input data
            if (appointment == null || appointment.lead == null || appointment.lead.extendedFields == null) {
                sendErrorResponse(res, 400, 'Missing required lead or extended fields information in the request.');
                return;
            }

            // Extract MDM Id from extended fields
            String mdmId;
            for (AppointmentDTO.ExtendedFieldDTO field : appointment.lead.extendedFields) {
                if (field.name.equalsIgnoreCase('Numero_de_Conta_na_lead__c')) {
                    mdmId = field.value;
                }
            }

            if (mdmId == null) {
                sendErrorResponse(res, 400, 'MDM ID is missing in the lead extended fields.');
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
            if (appointment.assignedResources == null || appointment.assignedResources.isEmpty()) {
                sendErrorResponse(res, 400, 'Assigned resources are missing in the request.');
                return;
            }

            ServiceAppointment sa = createServiceAppointmentLead(client, appointment);

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
            createAssignedResource(sa, appointment.assignedResources[0].serviceResourceId);
            createSADetails(sa);

            resultDTO.serviceAppointmentId = sa.Id;
            resultDTO.parentRecordId = sa.ParentRecordId;
            returnDTO.result = resultDTO;

            res.statusCode = 201;
            res.responseBody = Blob.valueOf(JSON.serialize(returnDTO));

        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            sendErrorResponse(res, 500, 'Internal Server Error: ' + e.getMessage());
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

    private static ServiceAppointment createServiceAppointmentLead(MDM_Client client, AppointmentDTO appointment) {
        ServiceAppointment sa = new ServiceAppointment();
        sa = (ServiceAppointment) JSON.deserialize(JSON.serialize(appointment.serviceAppointment), ServiceAppointment.class);
        sa.IsAnonymousBooking = true;
        sa.OwnerId = getUserFromServiceResource(appointment.assignedResources[0].serviceResourceId);
        sa.SCH_Service_Resource__c = appointment.assignedResources[0].serviceResourceId;

        // Upsert Lead from client data
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

        List<ServiceTerritory> serviceTerritoryList = [SELECT Id, Name, ParentTerritory.Name FROM ServiceTerritory WHERE Id =: appointment.serviceAppointment.serviceTerritoryId];
        String lojaDeAngariacao = '';
        if(!serviceTerritoryList.isEmpty()){
            String parentTerritoryName = serviceTerritoryList[0].ParentTerritory.Name;
            lojaDeAngariacao = String.isBlank(parentTerritoryName) ? serviceTerritoryList[0].Name : parentTerritoryName;
        }

        if (String.isBlank(lead.Canal_de_Interacao__c))
            lead.Canal_de_Interacao__c = 'Scheduler Online';
        if (String.isBlank(lead.Loja_de_Angariacao__c))
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

    public static void createAssignedResource(ServiceAppointment sa, String serviceResourceId) {
            // Create AssignedResource record to link ServiceAppointment with the scheduler resource
            AssignedResource ar = new AssignedResource();
            ar.ServiceAppointmentId = sa.Id;
            ar.ServiceResourceId = serviceResourceId;
            ar.isPrimaryResource = true;
            ar.isRequiredResource = true;
            insert ar; // Insert AssignedResource record to establish the link
    }

    private static void sendErrorResponse(RestResponse res, Integer statusCode, String message) {
        res.statusCode = statusCode;
        res.responseBody = Blob.valueOf(JSON.serialize(new ErrorResponse(message)));
    }

    public class ResponseDTO {
        public resultDTO result { get; set; }
    }

    public class resultDTO {
        public List<String> assignedResourceIds { get; set; }
        public String parentRecordId { get; set; }
        public String serviceAppointmentId { get; set; }
    }

    public class ErrorResponse {
        public String error { get; set; }
        public ErrorResponse(String message) {
            error = message;
        }
    }
}