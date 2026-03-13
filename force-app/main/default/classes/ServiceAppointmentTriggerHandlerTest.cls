/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 *
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class ServiceAppointmentTriggerHandlerTest {
    
    @TestSetup
    static void makeData(){
        // Objetos de setup (User + EmailTemplates) isolados em System.runAs()
        // para evitar MIXED_DML_OPERATION com objetos nao-setup
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Profile stdProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1][0];
            User userData = new User(
                LastName = 'TEST_DATA_USER',
                Alias = 'testd',
                Username = 'testdata@leroymerlin.pt',
                Email = 'testdata@leroymerlin.pt',
                ProfileId = stdProfile.Id,
                LDAP__c = '9001074112',
                TimeZoneSidKey = 'GMT',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US');
            insert userData;

            insert new EmailTemplate(
                Name = 'SCH SA Generic',
                DeveloperName = 'SCH_ServiceAppointmentCreateOGeneric',
                Subject = 'Marcacao criada',
                Body = 'O seu agendamento foi confirmado.',
                TemplateType = 'Text',
                IsActive = true,
                FolderId = UserInfo.getUserId());

            insert new EmailTemplate(
                Name = 'SMS InPerson Create',
                DeveloperName = 'SCH_Contact_InPerson_Create',
                Subject = 'SMS',
                Body = 'Marcacao presencial criada.',
                TemplateType = 'Text',
                IsActive = true,
                FolderId = UserInfo.getUserId());

            insert new EmailTemplate(
                Name = 'SMS InPerson Modify',
                DeveloperName = 'SCH_Contact_InPerson_Modify',
                Subject = 'SMS',
                Body = 'Marcacao presencial modificada.',
                TemplateType = 'Text',
                IsActive = true,
                FolderId = UserInfo.getUserId());

            insert new EmailTemplate(
                Name = 'SMS Online Create',
                DeveloperName = 'SCH_Contact_Online_Create',
                Subject = 'SMS',
                Body = 'Marcacao online criada.',
                TemplateType = 'Text',
                IsActive = true,
                FolderId = UserInfo.getUserId());

            insert new EmailTemplate(
                Name = 'SMS Online Modify',
                DeveloperName = 'SCH_Contact_Online_Modify',
                Subject = 'SMS',
                Body = 'Marcacao online modificada.',
                TemplateType = 'Text',
                IsActive = true,
                FolderId = UserInfo.getUserId());
        }

        // Objetos nao-setup
        Lead lead = new Lead(
            LastName = 'TEST',
            FirstName = 'CLASS',
            Numero_de_Conta_na_lead__c = '12345678',
            Loja_de_Angariacao__c = 'Albufeira',
            Email = 'testl2s@gmail.com',
            Phone = '912345678',
            LeadSource = 'L2S',
            MobilePhone = '912345678',
            ProjectId__c = '096a56ef-7157-4cc8-a125-502674f907e1');
        insert lead;

        WorkOrder workOrder = new WorkOrder(Subject = '1234567890');
        insert workOrder;

        // Infraestrutura de agendamento para testes do Helper
        User userData = [SELECT Id FROM User WHERE Username = 'testdata@leroymerlin.pt' LIMIT 1];

        OperatingHours opHours = new OperatingHours(Name = 'Test OH', TimeZone = 'Europe/Lisbon');
        insert opHours;

        ServiceTerritory territory = new ServiceTerritory(
            Name = 'Test Territory',
            OperatingHoursId = opHours.Id,
            IsActive = true);
        insert territory;

        ServiceResource sr = new ServiceResource(
            Name = 'Test Resource',
            IsActive = true,
            RelatedRecordId = userData.Id);
        insert sr;

        WorkType wt = new WorkType(Name = 'Test WorkType', EstimatedDuration = 30);
        insert wt;

        EngagementChannelType ectInPerson = new EngagementChannelType(
            Name = 'InPerson Channel',
            ContactPointType = 'InPerson',
            UsageType = 'Salesforce Scheduler',
            IsActive = true);
        insert ectInPerson;

        EngagementChannelType ectVideo = new EngagementChannelType(
            Name = 'Video Channel',
            ContactPointType = 'Video',
            UsageType = 'Salesforce Scheduler',
            IsActive = true);
        insert ectVideo;

        AppointmentSlotSummary__c summary = new AppointmentSlotSummary__c(
            WorkType__c = wt.Id,
            ServiceTerritory__c = territory.Id,
            EngagementChannelType__c = ectInPerson.Id);
        insert summary;

        AppointmentSlot__c slot = new AppointmentSlot__c(
            AppointmentSlotSummary__c = summary.Id,
            ServiceResource__c = sr.Id,
            Available__c = true,
            StartDate__c = Date.today().addDays(1),
            StartTime__c = System.now().addHours(1),
            EndTime__c = System.now().addHours(2));
        insert slot;

        // Contact com OwnerId do utilizador de teste para garantir visibilidade
        Contact c = new Contact(
            LastName = 'Test Contact',
            Email = 'testcontact@leroymerlin.pt',
            OwnerId = userData.Id);
        insert c;
    }
    
    @isTest
    static void sentServiceAppointADEO_Success() {
        User user = [SELECT id FROM user WHERE username = 'testdata@leroymerlin.pt' LIMIT 1];
        createPermissionSetAssignment(user);
        System.runAs(user){
            Test.setMock(HttpCalloutMock.class, new SuccessMockADEO());
            //MAKE UP DATA
            WorkOrder workOrder = [SELECT id FROM WorkOrder LIMIT 1];
            Lead lead = [SELECT Id FROM Lead LIMIT 1];
            ServiceAppointment sa = new ServiceAppointment(
                Lead__c = lead.Id, 
                Status = 'Scheduled',
                SchedStartTime = System.now(),
                ParentRecordId = workOrder.Id
            );
            //INSERT SA
            Test.startTest();
            insert sa;
            Test.stopTest();
            System.assert(true, 'No exception should occur for success response');
            System.assertNotEquals([SELECT External_UUID__c FROM ServiceAppointment WHERE Id =: sa.Id].External_UUID__c, null, 'External UUID should be set');
            System.assertEquals([SELECT HttpStatusCode__c FROM IntegrationLog__c LIMIT 1].HttpStatusCode__c, 200, 'Integration Log should have status code 200');
        }
    }
    
    @isTest
    static void updateServiceAppointADEO_Success() {
        User user = [SELECT id FROM user WHERE username = 'testdata@leroymerlin.pt' LIMIT 1];
        createPermissionSetAssignment(user);
        System.runAs(user){
            Test.setMock(HttpCalloutMock.class, new SuccessMockADEO());
            //MAKE UP DATA
            WorkOrder workOrder = [SELECT id FROM WorkOrder LIMIT 1];
            Lead lead = [SELECT Id FROM Lead LIMIT 1];
            ServiceAppointment sa = new ServiceAppointment( Lead__c = lead.Id, Status = 'Scheduled', SchedStartTime = System.now(), ParentRecordId = workOrder.Id);
            insert sa;
            //INSERT SA
            Test.startTest();
            sa.Status = 'Canceled';
            update sa;
            Test.stopTest();
            System.assert(true, 'No exception should occur for success response');
            System.assertEquals([SELECT HttpStatusCode__c FROM IntegrationLog__c LIMIT 1].HttpStatusCode__c, 200, 'Integration Log should have status code 200');
        }
    }
    
    @isTest
    static void sentServiceAppointADEO_Error() {
        User user = [SELECT id FROM user WHERE username = 'testdata@leroymerlin.pt' LIMIT 1];
        createPermissionSetAssignment(user);
        System.runAs(user){
            Test.setMock(HttpCalloutMock.class, new ErrorMockADEO());
            //MAKE UP DATA
            WorkOrder workOrder = [SELECT id FROM WorkOrder LIMIT 1];
            Lead lead = [SELECT Id FROM Lead LIMIT 1];
            ServiceAppointment sa = new ServiceAppointment( Lead__c = lead.Id, Status = 'Scheduled',
            SchedStartTime = System.now(), ParentRecordId = workOrder.Id);
            Test.startTest();
            try {
                insert sa;
            } catch (Exception e) {
                System.assertEquals(e.getMessage(),  '400 - BODY: {"message": "ERROR SENDING DATA ADEO",}', 'Callout shuld cause error');
            }
            Test.stopTest();
            System.assert(true, 'No exception should occur for success response');
            System.assertEquals([SELECT HttpStatusCode__c FROM IntegrationLog__c LIMIT 1].HttpStatusCode__c, 400, 'Integration Log should have status code 400');
        }
    }

    private static void createPermissionSetAssignment(User userData){
        PermissionSet permSet = [SELECT Id FROM PermissionSet WHERE Name = 'ACL_Sent_Service_Appointments_to_ADEO' LIMIT 1];
        PermissionSetAssignment psa = new PermissionSetAssignment(
            PermissionSetId = permSet.Id,
            AssigneeId = userData.Id);
        insert psa;
    }
    
    //****************************************************************************************************************************
    // ******************************************** TESTES - ServiceAppointmentTriggerHelper **************************************
    //****************************************************************************************************************************

    // ===== invalidateSlotsAfterInsert =====

    // @isTest
    // static void invalidateSlotsAfterInsert_NullList_NoException() {
    //     Test.startTest();
    //     ServiceAppointmentTriggerHelper.invalidateSlotsAfterInsert(null);
    //     Test.stopTest();
    //     System.assert(true, 'Nao deve lançar exceção para lista nula');
    // }

    // @isTest
    // static void invalidateSlotsAfterInsert_NonScheduled_SlotNaoInvalidado() {
    //     WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
    //     Lead lead = [SELECT Id FROM Lead LIMIT 1];
    //     ServiceTerritory territory = [SELECT Id FROM ServiceTerritory LIMIT 1];
    //     WorkType wt = [SELECT Id FROM WorkType LIMIT 1];
    //     EngagementChannelType ect = [SELECT Id FROM EngagementChannelType WHERE ContactPointType = 'InPerson' LIMIT 1];
    //     ServiceResource sr = [SELECT Id FROM ServiceResource LIMIT 1];

    //     ServiceAppointment sa = new ServiceAppointment(
    //         Lead__c = lead.Id,
    //         Status = 'None',
    //         ParentRecordId = wo.Id,
    //         SchedStartTime = System.now().addHours(1),
    //         SchedEndTime = System.now().addHours(2),
    //         ServiceTerritoryId = territory.Id,
    //         WorkTypeId = wt.Id,
    //         EngagementChannelTypeId = ect.Id,
    //         SCH_Service_Resource__c = sr.Id);

    //     Test.startTest();
    //     ServiceAppointmentTriggerHelper.invalidateSlotsAfterInsert(new List<ServiceAppointment>{ sa });
    //     Test.stopTest();

    //     AppointmentSlot__c slot = [SELECT Available__c FROM AppointmentSlot__c LIMIT 1];
    //     System.assertEquals(true, slot.Available__c, 'Slot nao deve ser invalidado para SA com status diferente de Scheduled');
    // }

    // @isTest
    // static void invalidateSlotsAfterInsert_Scheduled_InvalidaSlot() {
    //     WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
    //     Lead lead = [SELECT Id FROM Lead LIMIT 1];
    //     ServiceTerritory territory = [SELECT Id FROM ServiceTerritory LIMIT 1];
    //     WorkType wt = [SELECT Id FROM WorkType LIMIT 1];
    //     EngagementChannelType ect = [SELECT Id FROM EngagementChannelType WHERE ContactPointType = 'InPerson' LIMIT 1];
    //     ServiceResource sr = [SELECT Id FROM ServiceResource LIMIT 1];
    //     AppointmentSlot__c slot = [SELECT Id, StartTime__c, EndTime__c FROM AppointmentSlot__c LIMIT 1];

    //     ServiceAppointment sa = new ServiceAppointment(
    //         Lead__c = lead.Id,
    //         Status = 'Scheduled',
    //         ParentRecordId = wo.Id,
    //         SchedStartTime = slot.StartTime__c,
    //         SchedEndTime = slot.EndTime__c,
    //         ServiceTerritoryId = territory.Id,
    //         WorkTypeId = wt.Id,
    //         EngagementChannelTypeId = ect.Id,
    //         SCH_Service_Resource__c = sr.Id);

    //     Test.startTest();
    //     ServiceAppointmentTriggerHelper.invalidateSlotsAfterInsert(new List<ServiceAppointment>{ sa });
    //     Test.stopTest();

    //     AppointmentSlot__c updated = [SELECT Available__c FROM AppointmentSlot__c WHERE Id = :slot.Id];
    //     System.assertEquals(false, updated.Available__c, 'Slot deve ser invalidado para SA Scheduled que sobrepos o slot');
    // }

    // ===== invalidateSlotsAfterUpdate =====

    // @isTest
    // static void invalidateSlotsAfterUpdate_StatusCanceled_SlotNaoInvalidado() {
    //     WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
    //     Lead lead = [SELECT Id FROM Lead LIMIT 1];
    //     ServiceTerritory territory = [SELECT Id FROM ServiceTerritory LIMIT 1];
    //     WorkType wt = [SELECT Id FROM WorkType LIMIT 1];
    //     EngagementChannelType ect = [SELECT Id FROM EngagementChannelType WHERE ContactPointType = 'InPerson' LIMIT 1];
    //     ServiceResource sr = [SELECT Id FROM ServiceResource LIMIT 1];

    //     ServiceAppointmentTriggerHelper.runTrigger = false;
    //     // Tempos sem sobreposicao com o slot (now+1h..now+2h) para evitar invalidacao no insert
    //     ServiceAppointment sa = new ServiceAppointment(
    //         Lead__c = lead.Id,
    //         Status = 'Scheduled',
    //         ParentRecordId = wo.Id,
    //         SchedStartTime = System.now(),
    //         SchedEndTime = System.now().addMinutes(30),
    //         ServiceTerritoryId = territory.Id,
    //         WorkTypeId = wt.Id,
    //         EngagementChannelTypeId = ect.Id,
    //         SCH_Service_Resource__c = sr.Id);
    //     insert sa;
    //     ServiceAppointmentTriggerHelper.runTrigger = true;

    //     ServiceAppointment oldSa = sa.clone(true, true, false, false);
    //     sa.Status = 'Canceled';
    //     sa.SchedStartTime = System.now().addHours(3);

    //     Test.startTest();
    //     ServiceAppointmentTriggerHelper.invalidateSlotsAfterUpdate(
    //         new List<ServiceAppointment>{ sa },
    //         new Map<Id, ServiceAppointment>{ sa.Id => oldSa });
    //     Test.stopTest();

    //     AppointmentSlot__c slot = [SELECT Available__c FROM AppointmentSlot__c LIMIT 1];
    //     System.assertEquals(true, slot.Available__c, 'Slot nao deve ser invalidado para SA cancelada');
    // }

    // @isTest
    // static void invalidateSlotsAfterUpdate_SemAlteracao_SlotNaoInvalidado() {
    //     WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
    //     Lead lead = [SELECT Id FROM Lead LIMIT 1];
    //     ServiceTerritory territory = [SELECT Id FROM ServiceTerritory LIMIT 1];
    //     WorkType wt = [SELECT Id FROM WorkType LIMIT 1];
    //     EngagementChannelType ect = [SELECT Id FROM EngagementChannelType WHERE ContactPointType = 'InPerson' LIMIT 1];
    //     ServiceResource sr = [SELECT Id FROM ServiceResource LIMIT 1];

    //     ServiceAppointmentTriggerHelper.runTrigger = false;
    //     // Tempos sem sobreposicao com o slot (now+1h..now+2h) para evitar invalidacao no insert
    //     ServiceAppointment sa = new ServiceAppointment(
    //         Lead__c = lead.Id,
    //         Status = 'Scheduled',
    //         ParentRecordId = wo.Id,
    //         SchedStartTime = System.now(),
    //         SchedEndTime = System.now().addMinutes(30),
    //         ServiceTerritoryId = territory.Id,
    //         WorkTypeId = wt.Id,
    //         EngagementChannelTypeId = ect.Id,
    //         SCH_Service_Resource__c = sr.Id);
    //     insert sa;
    //     ServiceAppointmentTriggerHelper.runTrigger = true;

    //     ServiceAppointment oldSa = sa.clone(true, true, false, false);

    //     Test.startTest();
    //     ServiceAppointmentTriggerHelper.invalidateSlotsAfterUpdate(
    //         new List<ServiceAppointment>{ sa },
    //         new Map<Id, ServiceAppointment>{ sa.Id => oldSa });
    //     Test.stopTest();

    //     AppointmentSlot__c slot = [SELECT Available__c FROM AppointmentSlot__c LIMIT 1];
    //     System.assertEquals(true, slot.Available__c, 'Slot nao deve ser invalidado quando nao ha alteracao de datas ou recurso');
    // }

    // @isTest
    // static void invalidateSlotsAfterUpdate_DataAlterada_InvalidaSlot() {
    //     WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
    //     Lead lead = [SELECT Id FROM Lead LIMIT 1];
    //     ServiceTerritory territory = [SELECT Id FROM ServiceTerritory LIMIT 1];
    //     WorkType wt = [SELECT Id FROM WorkType LIMIT 1];
    //     EngagementChannelType ect = [SELECT Id FROM EngagementChannelType WHERE ContactPointType = 'InPerson' LIMIT 1];
    //     ServiceResource sr = [SELECT Id FROM ServiceResource LIMIT 1];
    //     AppointmentSlot__c slot = [SELECT Id, StartTime__c, EndTime__c FROM AppointmentSlot__c LIMIT 1];

    //     ServiceAppointmentTriggerHelper.runTrigger = false;
    //     ServiceAppointment sa = new ServiceAppointment(
    //         Lead__c = lead.Id,
    //         Status = 'Scheduled',
    //         ParentRecordId = wo.Id,
    //         SchedStartTime = System.now(),
    //         SchedEndTime = System.now().addMinutes(30),
    //         ServiceTerritoryId = territory.Id,
    //         WorkTypeId = wt.Id,
    //         EngagementChannelTypeId = ect.Id,
    //         SCH_Service_Resource__c = sr.Id);
    //     insert sa;
    //     ServiceAppointmentTriggerHelper.runTrigger = true;

    //     ServiceAppointment oldSa = sa.clone(true, true, false, false);
    //     sa.SchedStartTime = slot.StartTime__c;
    //     sa.SchedEndTime = slot.EndTime__c;

    //     Test.startTest();
    //     ServiceAppointmentTriggerHelper.invalidateSlotsAfterUpdate(
    //         new List<ServiceAppointment>{ sa },
    //         new Map<Id, ServiceAppointment>{ sa.Id => oldSa });
    //     Test.stopTest();

    //     AppointmentSlot__c updated = [SELECT Available__c FROM AppointmentSlot__c WHERE Id = :slot.Id];
    //     System.assertEquals(false, updated.Available__c, 'Slot deve ser invalidado quando a data da SA muda para sobreposicao');
    // }

    // ===== sendNotificationsAfterInsert =====

    @isTest
    static void sendNotificationsAfterInsert_NaoAgendada_SemNotificacao() {
        Test.setMock(HttpCalloutMock.class, new ErrorMockADEO());
        // SA com status diferente de Scheduled nao deve invocar sendTemplateEmails via trigger
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        EngagementChannelType ect = [SELECT Id FROM EngagementChannelType WHERE ContactPointType = 'InPerson' LIMIT 1];

        Test.startTest();
        insert new ServiceAppointment(
            Lead__c = lead.Id,
            Status = 'None',
            ParentRecordId = wo.Id,
            SchedStartTime = System.now(),
            SchedEndTime = System.now().addMinutes(30),
            EngagementChannelTypeId = ect.Id);
        Test.stopTest();

        List<ErrorLog__c> logs = [SELECT Id FROM ErrorLog__c WHERE MethodName__c = 'sendTemplateEmails'];
        System.assertEquals(0, logs.size(), 'SA nao agendada nao deve invocar o envio de email');
    }

    @isTest
    static void sendNotificationsAfterInsert_CanalVideo_SemNotificacao() {
        Test.setMock(HttpCalloutMock.class, new ErrorMockADEO());
        // SA Scheduled com canal Video nao deve invocar sendTemplateEmails no insert
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        EngagementChannelType ect = [SELECT Id FROM EngagementChannelType WHERE ContactPointType = 'Video' LIMIT 1];

        Test.startTest();
        insert new ServiceAppointment(
            Lead__c = lead.Id,
            Status = 'Scheduled',
            ParentRecordId = wo.Id,
            SchedStartTime = System.now(),
            SchedEndTime = System.now().addMinutes(30),
            EngagementChannelTypeId = ect.Id);
        Test.stopTest();

        List<ErrorLog__c> logs = [SELECT Id FROM ErrorLog__c WHERE MethodName__c = 'sendTemplateEmails'];
        System.assertEquals(0, logs.size(), 'Canal Video nao deve invocar o envio de email no insert');
    }

    @isTest
    static void sendNotificationsAfterInsert_CanalInPerson_NotificacaoInvocada() {
        // SA Scheduled com canal InPerson deve invocar sendTemplateEmails via trigger no insert
        Test.setMock(HttpCalloutMock.class, new SuccessMockADEO());
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        EngagementChannelType ect = [SELECT Id FROM EngagementChannelType WHERE ContactPointType = 'InPerson' LIMIT 1];

        Test.startTest();
        insert new ServiceAppointment(
            Lead__c = lead.Id,
            Status = 'Scheduled',
            ParentRecordId = wo.Id,
            SchedStartTime = System.now(),
            SchedEndTime = System.now().addMinutes(30),
            EngagementChannelTypeId = ect.Id);
        Test.stopTest();

        List<ErrorLog__c> logs = [SELECT Id FROM ErrorLog__c WHERE MethodName__c = 'sendTemplateEmails'];
        System.assertNotEquals(0, logs.size(), 'Canal InPerson agendado deve invocar sendTemplateEmails via trigger');
    }

    // ===== sendNotificationsAfterUpdate =====

    @isTest
    static void sendNotificationsAfterUpdate_StatusCanceled_EnviaEmail() {
        // Cancelamento de SA deve invocar sendTemplateEmails via trigger
        Test.setMock(HttpCalloutMock.class, new SuccessMockADEO());
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        EngagementChannelType ect = [SELECT Id FROM EngagementChannelType WHERE ContactPointType = 'InPerson' LIMIT 1];

        // Inserir SA nao agendada para nao disparar notificacao no insert
        ServiceAppointment sa = new ServiceAppointment(
            Lead__c = lead.Id,
            Status = 'None',
            ParentRecordId = wo.Id,
            SchedStartTime = System.now(),
            SchedEndTime = System.now().addMinutes(30),
            EngagementChannelTypeId = ect.Id);
        insert sa;

        Test.startTest();
        sa.Status = 'Canceled';
        update sa;
        Test.stopTest();

        List<ErrorLog__c> logs = [SELECT Id FROM ErrorLog__c WHERE MethodName__c = 'sendTemplateEmails'];
        System.assertNotEquals(0, logs.size(), 'Cancelamento deve invocar sendTemplateEmails via trigger');
    }

    @isTest
    static void sendNotificationsAfterUpdate_VideoMeetUrlAlterado_EnviaNotificacao() {
        Test.setMock(HttpCalloutMock.class, new SuccessMockADEO());
        // Alteracao do Meet URL numa SA Video Scheduled deve invocar sendTemplateEmails via trigger
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        EngagementChannelType ect = [SELECT Id FROM EngagementChannelType WHERE ContactPointType = 'Video' LIMIT 1];

        // Inserir SA Video Scheduled (canal Video nao invoca sendTemplateEmails no insert)
        ServiceAppointment sa = new ServiceAppointment(
            Lead__c = lead.Id,
            Status = 'Scheduled',
            ParentRecordId = wo.Id,
            SchedStartTime = System.now(),
            SchedEndTime = System.now().addMinutes(30),
            EngagementChannelTypeId = ect.Id);
        insert sa;

        Test.startTest();
        sa.SCH_Google_Meet_URL__c = 'https://meet.google.com/test-abc-xyz';
        update sa;
        Test.stopTest();

        List<ErrorLog__c> logs = [SELECT Id FROM ErrorLog__c WHERE MethodName__c = 'sendTemplateEmails'];
        System.assertNotEquals(0, logs.size(), 'Alteracao do Meet URL deve invocar sendTemplateEmails via trigger');
    }

    @isTest
    static void sendNotificationsAfterUpdate_InPersonDataAlterada_EnviaNotificacao() {
        Test.setMock(HttpCalloutMock.class, new SuccessMockADEO());
        // Alteracao de data numa SA InPerson Scheduled deve invocar sendTemplateEmails via trigger
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        EngagementChannelType ect = [SELECT Id FROM EngagementChannelType WHERE ContactPointType = 'InPerson' LIMIT 1];

        // Inserir SA nao agendada para nao disparar notificacao no insert
        ServiceAppointment sa = new ServiceAppointment(
            Lead__c = lead.Id,
            Status = 'None',
            ParentRecordId = wo.Id,
            SchedStartTime = System.now(),
            SchedEndTime = System.now().addMinutes(30),
            EngagementChannelTypeId = ect.Id);
        insert sa;

        Test.startTest();
        sa.Status = 'Scheduled';
        sa.SchedStartTime = System.now().addHours(3);
        sa.SchedEndTime = System.now().addHours(4);
        update sa;
        Test.stopTest();

        List<ErrorLog__c> logs = [SELECT Id FROM ErrorLog__c WHERE MethodName__c = 'sendTemplateEmails'];
        System.assertNotEquals(0, logs.size(), 'Alteracao de data em SA InPerson deve invocar sendTemplateEmails via trigger');
    }

    @isTest
    static void sendNotificationsAfterUpdate_ScheduledUpdatedDataAlterada_EnviaNotificacao() {
        Test.setMock(HttpCalloutMock.class, new SuccessMockADEO());
        // Status Scheduled-Updated com alteracao de data deve invocar sendTemplateEmails via trigger
        WorkOrder wo = [SELECT Id FROM WorkOrder LIMIT 1];
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        EngagementChannelType ect = [SELECT Id FROM EngagementChannelType WHERE ContactPointType = 'InPerson' LIMIT 1];

        // Inserir SA nao agendada para nao disparar notificacao no insert
        ServiceAppointment sa = new ServiceAppointment(
            Lead__c = lead.Id,
            Status = 'None',
            ParentRecordId = wo.Id,
            SchedStartTime = System.now(),
            SchedEndTime = System.now().addMinutes(30),
            EngagementChannelTypeId = ect.Id);
        insert sa;

        Test.startTest();
        sa.Status = 'Scheduled - Updated';
        sa.SchedStartTime = System.now().addHours(3);
        sa.SchedEndTime = System.now().addHours(4);
        update sa;
        Test.stopTest();

        List<ErrorLog__c> logs = [SELECT Id FROM ErrorLog__c WHERE MethodName__c = 'sendTemplateEmails'];
        System.assertNotEquals(0, logs.size(), 'Status Scheduled-Updated com data alterada deve invocar sendTemplateEmails via trigger');
    }

    //****************************************************************************************************************************
    // ***************************************************** MOCK CALLOUT CLASSES ************************************************
    //****************************************************************************************************************************
    
    private class SuccessMockADEO implements HttpCalloutMock{
        public HTTPResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(
                '{'+
                '"createdBy": "009009009",'+
                '"appointmentSystem": "SALESFORCE",'+
                '"date": "2026-02-09 14:47:20",'+
                '"status": "Scheduled",'+
                '"projectId": "096a56ef-7157-4cc8-a125-502674f907e1",'+
                '"appointmentId": "08pUE000007aEhzYAE",'+
                '"mdmId": "009009009"'+
                '}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    private class ErrorMockADEO implements HttpCalloutMock{
        public HTTPResponse respond(HTTPRequest req){
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(
                '{'+
                '"message": "ERROR SENDING DATA ADEO",'+
                '}');
            res.setStatusCode(400);
            return res;
        }
    }

    private class TwilioSuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"sid":"SMTEST000000000000000000000000001","status":"queued"}');
            res.setStatusCode(201);
            return res;
        }
    }
}