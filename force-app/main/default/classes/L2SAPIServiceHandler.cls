/**
 * @description       : L2S Lead creation handler
 * @author            :
 * @group             :
 * @last modified on  : 2026-03-19
 * @last modified by  : Catarina Lopes
 **/
public with sharing class L2SAPIServiceHandler {

    public static L2SIntegrationResult handleRequest(String payloadBody, String requestType){
        if(String.isBlank(payloadBody)){
            return errorResult(400, 'Missing request body', 'Provide a JSON payload.');
        }

        L2SRequestWrapper request;
        try{
            request = (L2SRequestWrapper) JSON.deserialize(payloadBody, L2SRequestWrapper.class);
        } catch (Exception e) {
            return errorResult(400, 'Invalid JSON payload', e.getMessage());
        }

        List<String> missingFields = new List<String>();
        if(request == null){
            missingFields.add('body');
        } else {
            if(String.isBlank(request.mdmId)){
                missingFields.add('mdmId');
            }
            if(String.isBlank(request.leadSource)){
                missingFields.add('leadSource');
            }
            if(String.isBlank(request.team)){
                missingFields.add('team');
            }
            if(String.isBlank(request.status)){
                missingFields.add('status');
            }
            if(String.isBlank(request.projectId)){
                missingFields.add('projectId');
            }
            if(String.isBlank(request.projectTag)){
                missingFields.add('projectTag');
            }
        }

        if(!missingFields.isEmpty()){
            return errorResult(400, 'Missing required fields: ' + String.join(missingFields, ', '), null);
        }
        Lead lead = new Lead();
        List<Lead> existingLeads = [Select Id, Description, ProjectId__c, Canal_de_Interacao__c, Equipa__c, Loja_de_Angariacao__c, Status FROM Lead WHERE ProjectId__c = :request.projectId LIMIT 1];
        System.debug('existingLeads: ' + existingLeads);
        if (!existingLeads.isEmpty()) {
            lead = existingLeads[0];
        }
        lead.Numero_de_Conta_na_lead__c = request.mdmId;
        lead.LeadSource = request.leadSource;

        List<LeadStatusMapping__mdt> leadMappings = [SELECT Id, DeveloperName, MappedStatus__c FROM LeadStatusMapping__mdt];
        for (LeadStatusMapping__mdt mapping : leadMappings) {
            if (request.status == mapping.DeveloperName) {
                lead.Status = mapping.MappedStatus__c;
            }
            if (lead.Status == 'Unqualified') {
                lead.Motivo_de_Perda__c = 'Outros';
            }
        }

        System.debug('has service appointment: ' + hasServiceAppointment(lead));
        if(!hasServiceAppointment(lead)){
            if (String.isNotBlank(request.team)) {
                lead.Equipa__c = request.team;
                lead.Canal_de_Interacao__c = 'VAD';
            } else {
                lead.Equipa__c = 'VAD';
                lead.Canal_de_Interacao__c = 'VAD';
            }
        }

        lead.ProjectId__c = request.projectId;

        List<ProjectTagMapping__mdt> projectTags = [SELECT Id,
                                                            DeveloperName,
                                                            PortugueseTranslation__c
                                                    FROM ProjectTagMapping__mdt
                                                    WITH SECURITY_ENFORCED];

        for (ProjectTagMapping__mdt projectTag : projectTags) {
            if (projectTag.DeveloperName == request.projectTag) {
                lead.ProjectTag__c = projectTag.PortugueseTranslation__c;
            }
        }


        List<MDM_Client> clients;

        if (Test.isRunningTest()){
            MDM_Client c;
            if (request.mdmId == 'DASH_LASTNAME') {
                c = getMockClientWithDashLastName();
            } else if (request.mdmId == 'BLANK_LASTNAME') {
                c = getMockClientWithBlankLastName();
            } else if (request.mdmId == 'WITH_MEMBERS') {
                c = getMockClientWithMembers();
            } else {
                c = getMockClientDefault();
            }
            clients = new List<MDM_Client>{c};
        }else{
            clients = c_PesquisaConta.getAccountsMdm(new List<String>{request.mdmId}, 'Nº de Cliente');
        }
        
        if (clients == null || clients.isEmpty()) {
            return errorResult(404, 'No client found with the given MDM ID.', null);
        }

        MDM_Client client = clients[0];

        if(String.isBlank(client.inhabitant.lastName) || client.inhabitant.lastName == '-'){
            lead.FirstName = client.inhabitant.FirstName;
            lead.LastName = '.';
            lead.NIF__c = String.isEmpty(client.professionalOrganization.administrativeCodes.nif) ? '': client.professionalOrganization.administrativeCodes.nif;

            for (MDM_Client.Member member : client.members){
                if (member.isLegalRepresentative){
                    for (MDM_Client.EmailAddress emailAddress : member.emailAddresses){
                        if (emailAddress.isContactPriority){
                            lead.Email = emailAddress.email;
                        }
                        break;
                    }
                    for (MDM_Client.Phone phone : member.phones){
                        if (phone.isContactPriority){
                            lead.MobilePhone = phone.numberSF != null ? phone.numberSF : '';
                            lead.Phone = phone.numberSF != null ? phone.numberSF : '';
                        }
                        break;
                    }
                    break;
                }
            }

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
        }

        if (hasServiceAppointment(lead) && String.isBlank(lead.Loja_de_Angariacao__c)) {
            List<ServiceAppointment> sa = [SELECT Id, ServiceTerritory.Name FROM ServiceAppointment WHERE Lead__c = :lead.Id];
            lead.Loja_de_Angariacao__c = sa[0].ServiceTerritory.Name;
        } else if(String.isBlank(request.storeId) && !hasServiceAppointment(lead) && String.isBlank(lead.Loja_de_Angariacao__c)){
            Integer clientStore = Integer.valueOf(client.declaredStoreAttachement);
            String formattedClientStore = String.valueOf(clientStore).leftPad(3, '0');
            List<ServiceTerritory> territories = [
                SELECT Id, Name, StoreID__c
                FROM ServiceTerritory
                WHERE StoreID__c = :formattedClientStore
                LIMIT 1
            ];
            if(!territories.isEmpty()){
                lead.Loja_de_Angariacao__c = territories[0].Name;
            }
        } else if (!hasServiceAppointment(lead)) {
            List<ServiceTerritory> territories = [
                SELECT Id, Name, StoreID__c
                FROM ServiceTerritory
                WHERE StoreID__c = :request.storeId
                LIMIT 1
            ];
            if(!territories.isEmpty()){
                lead.Loja_de_Angariacao__c = territories[0].Name;
            }else{
                lead.Loja_de_Angariacao__c = null;
            }
        }

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
        if(!String.isBlank(String.valueOf(request.qualification))){
            for (QualificationWrapper qualification : request.qualification) {
                System.debug('++++ Evaluating qualification with subtype == '+qualification.subtype);
                Boolean successfullyMapped = false;
                System.debug('++++ successfullyMapped == '+successfullyMapped);
                for (QualificationMapping__mdt mapping : qualificationMappings) {
                    if (qualification.subtype.contains(mapping.SubtypeContains__c)) {
                        successfullyMapped = true;
                        System.debug('++++ successfullyMapped is now == '+successfullyMapped);
                        switch on mapping.DeveloperName {
                            when 'Qualification1' {
                                qualification1MappedField = mapping.MapsToField__c;
                                qualification1Parcel+= 'Qualificação 1 \n';
                                for (QualificationQuestions question : qualification.questions) {
                                 qualification1Parcel += question.label+'\n';

                                   for (QualificationAnswer answer : question.answers){
                                       qualification1Parcel += '- '+answer.label+'\n';
                                   }
                                   qualification1Parcel += '\n';
                                }
                            }
                            when 'Qualification2' {
                                qualification2MappedField = mapping.MapsToField__c;
                                qualification2Parcel+= 'Qualificação 2 \n';
                                for (QualificationQuestions question : qualification.questions) {
                                    qualification2Parcel += question.label+'\n';
                                    for (QualificationAnswer answer : question.answers){
                                        qualification2Parcel += '- '+answer.label+'\n';
                                    }
                                    qualification2Parcel += '\n';
                                }
                            }
                        }
                    }
                }
                qualificationValidationList.add(successfullyMapped);
                System.debug('++++ qualificationValidationList is now == '+qualificationValidationList);
            }
            for (Boolean correctlyMapped : qualificationValidationList) {
                if (!correctlyMapped) {
                    return errorResult(500, 'Qualification subtypes are improperly formatted.', null);
                }
            }
            if (String.isNotBlank(qualification1MappedField) && qualification1MappedField == qualification2MappedField) {
                lead.put(qualification1MappedField, qualification1Parcel+qualification2Parcel);
            } else if (String.isNotBlank(qualification1MappedField) || String.isNotBlank(qualification2MappedField)){
                if (String.isNotBlank(qualification1Parcel)) {
                lead.put(qualification1MappedField, qualification1Parcel);
                }
                if(String.isNotBlank(qualification2Parcel)){
                    lead.put(qualification2MappedField, qualification2Parcel);
                }
            }
        }

        Database.DMLOptions dmlOptions = new Database.DMLOptions();
        dmlOptions.assignmentRuleHeader.useDefaultRule = true;
        lead.setOptions(dmlOptions);


        upsert lead;

        L2SResponseWrapper response = new L2SResponseWrapper(request.mdmId, lead.Id);

        return new L2SIntegrationResult(201, response, new List<SObject>{ lead }, null);
    }

    private static L2SIntegrationResult errorResult(Integer statusCode, String message, String detailAction){
        L2SErrorWrapper error = new L2SErrorWrapper(message, detailAction);
        return new L2SIntegrationResult(statusCode, error, null, message);
    }
    
    private static Boolean hasServiceAppointment(Lead lead){
        return lead.Equipa__c == 'Loja' && lead.Canal_de_Interacao__c == 'Scheduler Online';
    }

    public class L2SRequestWrapper{
        public String mdmId;
        public String leadSource;
        public String team;
        public String status;
        public String storeId;
        public String projectId;
        public String projectTag;
        public QualificationWrapper[] qualification;
    }


    public class QualificationWrapper {
        public String subtype;
        public QualificationQuestions[] questions;
    }
    public class QualificationAnswer {
        public String label;
    }

    public class QualificationQuestions {
        public String label;
        public QualificationAnswer[] answers;
    }


    public class L2SResponseWrapper{
        public String mdmId;
        public String leadId;

        public L2SResponseWrapper(String mdmId, String leadId){
            this.mdmId = mdmId;
            this.leadId = leadId;
        }
    }

    public class L2SErrorWrapper{
        public String errorMessage;
        public String detailAction;

        public L2SErrorWrapper(String errorMessage, String detailAction){
            this.errorMessage = errorMessage;
            this.detailAction = detailAction;
        }
    }

    public class L2SIntegrationResult{
        public Integer statusCode;
        public Object responseBody;
        public List<SObject> recordsCreate;
        public String errorMessage;

        public L2SIntegrationResult(Integer statusCode, Object responseBody, List<SObject> recordsCreate, String errorMessage){
            this.statusCode = statusCode;
            this.responseBody = responseBody;
            this.recordsCreate = recordsCreate;
            this.errorMessage = errorMessage;
        }
    }

    private static MDM_Client getMockClientDefault() {
        String clientString = '{"active":true,"addresses":[{"city":"MAIA","complementaryDeliveryAddress":"MORADIA COSTA DO SOL","countryCode":"PT","isContactPriority":true,"isQualitative":true,"postalCode":"4475","usages":[]}],"clientNumber":2462,"createdAt":"2022-07-06T14:25:01.124Z","creationStoreCode":"1","declaredStoreAttachement":"1","emailAddresses":[{"email":"teste@teste.com"}],"inhabitant":{"administrativeIdentifiers":{"nif":"123456789"},"civility":"MS","firstName":"MAIA","lastName":"COSTA DO SOL"},"phones":[{"isContactPriority":false,"numberSF":"+351910974671","type":"LANDLINE"},{"isContactPriority":true,"number":"+351910974671"}],"universalClientNumber":"LMPT2462","updatedAt":"' + System.now().addDays(20).format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') + '","professionalOrganization":{"administrativeCodes":{"nif":"999888777"}},"members":[]},"_meta":{}}';
        return (MDM_Client)JSON.deserialize(clientString, MDM_Client.class);
    }

    private static MDM_Client getMockClientWithDashLastName() {
        String clientString = '{"active":true,"addresses":[{"city":"MAIA","complementaryDeliveryAddress":"MORADIA TEST","countryCode":"PT","isContactPriority":true,"isQualitative":true,"postalCode":"4475","usages":[]}],"clientNumber":2462,"createdAt":"2022-07-06T14:25:01.124Z","creationStoreCode":"1","declaredStoreAttachement":"1","emailAddresses":[{"email":"dash@teste.com"}],"inhabitant":{"administrativeIdentifiers":{"nif":"987654321"},"civility":"MS","firstName":"DASH","lastName":"-"},"phones":[{"isContactPriority":false,"numberSF":"+351910974671","type":"LANDLINE"},{"isContactPriority":true,"number":"+351910974671"}],"universalClientNumber":"LMPT2462","updatedAt":"' + System.now().addDays(20).format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') + '","professionalOrganization":{"administrativeCodes":{"nif":"987654321"}},"members":[]},"_meta":{}}';
        return (MDM_Client)JSON.deserialize(clientString, MDM_Client.class);
    }

    private static MDM_Client getMockClientWithBlankLastName() {
        String clientString = '{"active":true,"addresses":[{"city":"MAIA","complementaryDeliveryAddress":"MORADIA TEST","countryCode":"PT","isContactPriority":true,"isQualitative":true,"postalCode":"4475","usages":[]}],"clientNumber":2462,"createdAt":"2022-07-06T14:25:01.124Z","creationStoreCode":"1","declaredStoreAttachement":"1","emailAddresses":[{"email":"blank@teste.com"}],"inhabitant":{"administrativeIdentifiers":{"nif":"111222333"},"civility":"MS","firstName":"BLANK","lastName":""},"phones":[{"isContactPriority":false,"numberSF":"+351910974671","type":"LANDLINE"},{"isContactPriority":true,"number":"+351910974671"}],"universalClientNumber":"LMPT2462","updatedAt":"' + System.now().addDays(20).format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') + '","professionalOrganization":{"administrativeCodes":{"nif":"111222333"}},"members":[]},"_meta":{}}';
        return (MDM_Client)JSON.deserialize(clientString, MDM_Client.class);
    }

    private static MDM_Client getMockClientWithMembers() {
        String clientString = '{"active":true,"addresses":[{"city":"MAIA","complementaryDeliveryAddress":"MORADIA TEST","countryCode":"PT","isContactPriority":true,"isQualitative":true,"postalCode":"4475","usages":[]}],"clientNumber":2462,"createdAt":"2022-07-06T14:25:01.124Z","creationStoreCode":"1","declaredStoreAttachement":"1","emailAddresses":[{"email":"member@teste.com"}],"inhabitant":{"administrativeIdentifiers":{"nif":"444555666"},"civility":"MS","firstName":"MEMBER","lastName":"-"},"phones":[{"isContactPriority":false,"numberSF":"+351910974671","type":"LANDLINE"},{"isContactPriority":true,"number":"+351910974671"}],"universalClientNumber":"LMPT2462","updatedAt":"' + System.now().addDays(20).format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') + '","professionalOrganization":{"administrativeCodes":{"nif":"444555666"}},"members":[{"isLegalRepresentative":true,"emailAddresses":[{"email":"legal@teste.com","isContactPriority":true}],"phones":[{"numberSF":"+351911111111","isContactPriority":true}]}]},"_meta":{}}';
        return (MDM_Client)JSON.deserialize(clientString, MDM_Client.class);
    }
}