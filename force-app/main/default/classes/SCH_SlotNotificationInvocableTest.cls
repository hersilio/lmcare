/**
 * @description Test class for SCH_SlotNotificationInvocable.
 *              Tests aggregate validation, deduplication logic,
 *              email body generation, and edge cases.
 * @author Ricardo Simoes
 * @last modified on 2026-02-25
 */
@IsTest
private class SCH_SlotNotificationInvocableTest {
    @TestSetup
    static void setup() {
        OperatingHours oh = new OperatingHours(Name = 'Test Hours');
        insert oh;

        ServiceTerritory st = new ServiceTerritory(Name = 'Loja Teste', OperatingHoursId = oh.Id, IsActive = true);
        insert st;

        Territory_Notification_Email__c tne = new Territory_Notification_Email__c(
            ServiceTerritory__c = st.Id, Email__c = 'test@example.com', IsActive__c = true
        );
        insert tne;

        WorkType wt = new WorkType(Name = 'Serviço Teste', EstimatedDuration = 60);
        insert wt;
    }

    @IsTest
    static void testSendNotificationZeroSlots() {
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE Name = 'Loja Teste' LIMIT 1];
        WorkType wt = [SELECT Id FROM WorkType WHERE Name = 'Serviço Teste' LIMIT 1];

        SCH_SlotNotificationInvocable.NotificationRequest req = new SCH_SlotNotificationInvocable.NotificationRequest();
        req.territoryId = st.Id;
        req.workTypeId = wt.Id;

        Test.startTest();
        SCH_SlotNotificationInvocable.sendNotifications(new List<SCH_SlotNotificationInvocable.NotificationRequest>{ req });
        Test.stopTest();

        String key = String.valueOf(st.Id) + '|' + String.valueOf(wt.Id);
        System.assert(SCH_SlotNotificationInvocable.notifiedKeys.contains(key), 'Territory+WorkType should be marked as notified');
    }

    @IsTest
    static void testSendNotificationTwoSlots() {
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE Name = 'Loja Teste' LIMIT 1];
        WorkType wt = [SELECT Id FROM WorkType WHERE Name = 'Serviço Teste' LIMIT 1];

        SCH_SlotNotificationInvocable.NotificationRequest req = new SCH_SlotNotificationInvocable.NotificationRequest();
        req.territoryId = st.Id;
        req.workTypeId = wt.Id;

        Test.startTest();
        SCH_SlotNotificationInvocable.sendNotifications(new List<SCH_SlotNotificationInvocable.NotificationRequest>{ req });
        Test.stopTest();

        String key = String.valueOf(st.Id) + '|' + String.valueOf(wt.Id);
        System.assert(SCH_SlotNotificationInvocable.notifiedKeys.contains(key), 'Territory+WorkType should be marked as notified');
    }

    @IsTest
    static void testDeduplicationSeparateCalls() {
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE Name = 'Loja Teste' LIMIT 1];
        WorkType wt = [SELECT Id FROM WorkType WHERE Name = 'Serviço Teste' LIMIT 1];

        SCH_SlotNotificationInvocable.NotificationRequest req1 = new SCH_SlotNotificationInvocable.NotificationRequest();
        req1.territoryId = st.Id;
        req1.workTypeId = wt.Id;


        SCH_SlotNotificationInvocable.NotificationRequest req2 = new SCH_SlotNotificationInvocable.NotificationRequest();
        req2.territoryId = st.Id;
        req2.workTypeId = wt.Id;


        Test.startTest();
        SCH_SlotNotificationInvocable.sendNotifications(new List<SCH_SlotNotificationInvocable.NotificationRequest>{ req1 });
        SCH_SlotNotificationInvocable.sendNotifications(new List<SCH_SlotNotificationInvocable.NotificationRequest>{ req2 });
        Test.stopTest();

        System.assertEquals(1, SCH_SlotNotificationInvocable.notifiedKeys.size(), 'Only one notification per territory+worktype');
    }

    @IsTest
    static void testBatchDeduplication() {
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE Name = 'Loja Teste' LIMIT 1];
        WorkType wt = [SELECT Id FROM WorkType WHERE Name = 'Serviço Teste' LIMIT 1];

        SCH_SlotNotificationInvocable.NotificationRequest req1 = new SCH_SlotNotificationInvocable.NotificationRequest();
        req1.territoryId = st.Id;
        req1.workTypeId = wt.Id;


        SCH_SlotNotificationInvocable.NotificationRequest req2 = new SCH_SlotNotificationInvocable.NotificationRequest();
        req2.territoryId = st.Id;
        req2.workTypeId = wt.Id;


        Test.startTest();
        SCH_SlotNotificationInvocable.sendNotifications(new List<SCH_SlotNotificationInvocable.NotificationRequest>{ req1, req2 });
        Test.stopTest();

        System.assertEquals(1, SCH_SlotNotificationInvocable.notifiedKeys.size(), 'Duplicate territory+worktype in same batch should be deduplicated');
    }

    @IsTest
    static void testAggregateBlocksNotificationWhenOtherResourcesAvailable() {
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE Name = 'Loja Teste' LIMIT 1];
        WorkType wt = [SELECT Id FROM WorkType WHERE Name = 'Serviço Teste' LIMIT 1];

        EngagementChannelType ect = new EngagementChannelType(Name = 'Test Channel');
        insert ect;

        ServiceResource sr = new ServiceResource(Name = 'Test Resource', RelatedRecordId = UserInfo.getUserId(), ResourceType = 'T', IsActive = true);
        insert sr;

        AppointmentSlotSummary__c summary1 = new AppointmentSlotSummary__c(
            ServiceTerritory__c = st.Id, WorkType__c = wt.Id, EngagementChannelType__c = ect.Id, UniqueKey__c = 'test-summary-1'
        );
        insert summary1;

        // 5 available today slots → aggregate today > 2
        List<AppointmentSlot__c> slots = new List<AppointmentSlot__c>();
        for (Integer i = 0; i < 5; i++) {
            slots.add(new AppointmentSlot__c(
                ServiceResource__c = sr.Id, AppointmentSlotSummary__c = summary1.Id,
                StartTime__c = DateTime.now().addHours(i + 1), EndTime__c = DateTime.now().addHours(i + 2),
                StartDate__c = Date.today(), Available__c = true,                IsToday__c = true, IsTomorrow__c = false, UniqueKey__c = 'slot-block-' + i
            ));
        }
        // 5 slots for tomorrow so both days > 2
        for (Integer i = 0; i < 5; i++) {
            slots.add(new AppointmentSlot__c(
                ServiceResource__c = sr.Id, AppointmentSlotSummary__c = summary1.Id,
                StartTime__c = DateTime.now().addDays(1).addHours(i + 1), EndTime__c = DateTime.now().addDays(1).addHours(i + 2),
                StartDate__c = Date.today().addDays(1), Available__c = true,                IsToday__c = false, IsTomorrow__c = true, UniqueKey__c = 'slot-block-tmr-' + i
            ));
        }
        insert slots;

        // Different summary for same territory+worktype reached 0, but aggregate across all > 2 for both days
        SCH_SlotNotificationInvocable.NotificationRequest req = new SCH_SlotNotificationInvocable.NotificationRequest();
        req.territoryId = st.Id;
        req.workTypeId = wt.Id;


        Test.startTest();
        SCH_SlotNotificationInvocable.sendNotifications(new List<SCH_SlotNotificationInvocable.NotificationRequest>{ req });
        Test.stopTest();

        String key = String.valueOf(st.Id) + '|' + String.valueOf(wt.Id);
        System.assert(!SCH_SlotNotificationInvocable.notifiedKeys.contains(key), 'Should NOT notify when aggregate today and tomorrow both > 2');
    }

    @IsTest
    static void testAggregateSendsWhenTotalIsLow() {
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE Name = 'Loja Teste' LIMIT 1];
        WorkType wt = [SELECT Id FROM WorkType WHERE Name = 'Serviço Teste' LIMIT 1];

        EngagementChannelType ect = new EngagementChannelType(Name = 'Test Channel 2');
        insert ect;

        ServiceResource sr = new ServiceResource(Name = 'Test Resource 2', RelatedRecordId = UserInfo.getUserId(), ResourceType = 'T', IsActive = true);
        insert sr;

        AppointmentSlotSummary__c summary1 = new AppointmentSlotSummary__c(
            ServiceTerritory__c = st.Id, WorkType__c = wt.Id, EngagementChannelType__c = ect.Id, UniqueKey__c = 'test-summary-low'
        );
        insert summary1;

        // Only 2 available slots for today → aggregate today <= 2 → should notify
        List<AppointmentSlot__c> slots = new List<AppointmentSlot__c>();
        for (Integer i = 0; i < 2; i++) {
            slots.add(new AppointmentSlot__c(
                ServiceResource__c = sr.Id, AppointmentSlotSummary__c = summary1.Id,
                StartTime__c = DateTime.now().addHours(i + 1), EndTime__c = DateTime.now().addHours(i + 2),
                StartDate__c = Date.today(), Available__c = true,                IsToday__c = true, IsTomorrow__c = false, UniqueKey__c = 'slot-low-' + i
            ));
        }
        insert slots;

        SCH_SlotNotificationInvocable.NotificationRequest req = new SCH_SlotNotificationInvocable.NotificationRequest();
        req.territoryId = st.Id;
        req.workTypeId = wt.Id;


        Test.startTest();
        SCH_SlotNotificationInvocable.sendNotifications(new List<SCH_SlotNotificationInvocable.NotificationRequest>{ req });
        Test.stopTest();

        String key = String.valueOf(st.Id) + '|' + String.valueOf(wt.Id);
        System.assert(SCH_SlotNotificationInvocable.notifiedKeys.contains(key), 'Should notify when aggregate slots <= 2');
    }

    @IsTest
    static void testNoActiveEmails() {
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE Name = 'Loja Teste' LIMIT 1];
        WorkType wt = [SELECT Id FROM WorkType WHERE Name = 'Serviço Teste' LIMIT 1];

        List<Territory_Notification_Email__c> tnes = [SELECT Id FROM Territory_Notification_Email__c];
        for (Territory_Notification_Email__c tne : tnes) {
            tne.IsActive__c = false;
        }
        update tnes;

        SCH_SlotNotificationInvocable.NotificationRequest req = new SCH_SlotNotificationInvocable.NotificationRequest();
        req.territoryId = st.Id;
        req.workTypeId = wt.Id;


        Test.startTest();
        SCH_SlotNotificationInvocable.sendNotifications(new List<SCH_SlotNotificationInvocable.NotificationRequest>{ req });
        Test.stopTest();

        String key = String.valueOf(st.Id) + '|' + String.valueOf(wt.Id);
        System.assert(!SCH_SlotNotificationInvocable.notifiedKeys.contains(key), 'Should not notify when no active emails exist');
    }

    @IsTest
    static void testBuildEmailBodyBothZero() {
        String body = SCH_SlotNotificationInvocable.buildEmailBody('Loja Almada', 'Instalação', 0, 0);
        System.assert(body.contains('Sem slots disponíveis'), 'Zero slots should show "Sem slots disponíveis"');
        System.assert(body.contains('Loja Almada'), 'Body should contain the territory name');
        System.assert(body.contains('Instalação'), 'Body should contain the work type name');
        System.assert(body.contains('Hoje:'), 'Body should contain Hoje label');
        System.assert(body.contains('Amanhã:'), 'Body should contain Amanhã label');
    }

    @IsTest
    static void testBuildEmailBodyTodayTwoTomorrowThree() {
        String body = SCH_SlotNotificationInvocable.buildEmailBody('Loja Almada', 'Instalação', 2, 3);
        System.assert(body.contains('2 Slots disponíveis'), 'Today with 2 slots should show plural');
        System.assert(body.contains('3 Slots disponíveis'), 'Tomorrow with 3 slots should show plural');
    }

    @IsTest
    static void testBuildEmailBodyOneSingular() {
        String body = SCH_SlotNotificationInvocable.buildEmailBody('Loja Almada', 'Instalação', 1, 1);
        System.assert(body.contains('1 Slot disponível'), 'One slot should use singular form');
    }

    @IsTest
    static void testBuildEmailBodyMixed() {
        String body = SCH_SlotNotificationInvocable.buildEmailBody('Loja Almada', 'Instalação', 0, 5);
        System.assert(body.contains('Sem slots disponíveis'), 'Today with 0 should show "Sem slots disponíveis"');
        System.assert(body.contains('5 Slots disponíveis'), 'Tomorrow with 5 should show plural');
    }

    @IsTest
    static void testFormatSlotCount() {
        System.assertEquals('Sem slots disponíveis', SCH_SlotNotificationInvocable.formatSlotCount(0));
        System.assertEquals('Sem slots disponíveis', SCH_SlotNotificationInvocable.formatSlotCount(null));
        System.assertEquals('1 Slot disponível', SCH_SlotNotificationInvocable.formatSlotCount(1));
        System.assertEquals('2 Slots disponíveis', SCH_SlotNotificationInvocable.formatSlotCount(2));
        System.assertEquals('10 Slots disponíveis', SCH_SlotNotificationInvocable.formatSlotCount(10));
    }

    @IsTest
    static void testDeduplicatesAcrossChannels() {
        // Same resource, same times, TWO channels → 2 summaries with 2 slots each
        // Roll-up SUM would be 4, but distinct physical slots = 2 → should notify
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE Name = 'Loja Teste' LIMIT 1];
        WorkType wt = [SELECT Id FROM WorkType WHERE Name = 'Serviço Teste' LIMIT 1];

        EngagementChannelType ectPresencial = new EngagementChannelType(Name = 'Presencial');
        EngagementChannelType ectDistancia = new EngagementChannelType(Name = 'À Distância');
        insert new List<EngagementChannelType>{ ectPresencial, ectDistancia };

        ServiceResource sr = new ServiceResource(Name = 'Resource Dedup', RelatedRecordId = UserInfo.getUserId(), ResourceType = 'T', IsActive = true);
        insert sr;

        AppointmentSlotSummary__c summaryPresencial = new AppointmentSlotSummary__c(
            ServiceTerritory__c = st.Id, WorkType__c = wt.Id, EngagementChannelType__c = ectPresencial.Id, UniqueKey__c = 'test-dedup-presencial'
        );
        AppointmentSlotSummary__c summaryDistancia = new AppointmentSlotSummary__c(
            ServiceTerritory__c = st.Id, WorkType__c = wt.Id, EngagementChannelType__c = ectDistancia.Id, UniqueKey__c = 'test-dedup-distancia'
        );
        insert new List<AppointmentSlotSummary__c>{ summaryPresencial, summaryDistancia };

        // Same resource, same 2 time slots → duplicated across both summaries
        List<AppointmentSlot__c> slots = new List<AppointmentSlot__c>();
        for (Integer i = 0; i < 2; i++) {
            DateTime slotStart = DateTime.now().addHours(i + 1);
            DateTime slotEnd = DateTime.now().addHours(i + 2);
            slots.add(new AppointmentSlot__c(
                ServiceResource__c = sr.Id, AppointmentSlotSummary__c = summaryPresencial.Id,
                StartTime__c = slotStart, EndTime__c = slotEnd, StartDate__c = Date.today(),
                Available__c = true, IsToday__c = true, IsTomorrow__c = false,
                UniqueKey__c = 'slot-dedup-pres-' + i
            ));
            slots.add(new AppointmentSlot__c(
                ServiceResource__c = sr.Id, AppointmentSlotSummary__c = summaryDistancia.Id,
                StartTime__c = slotStart, EndTime__c = slotEnd, StartDate__c = Date.today(),
                Available__c = true, IsToday__c = true, IsTomorrow__c = false,
                UniqueKey__c = 'slot-dedup-dist-' + i
            ));
        }
        insert slots;

        // Each summary has 2 slots → roll-up SUM = 4 (would be > 2 without dedup)
        // But distinct (resource+time) = 2 → should notify (2 <= 2)
        SCH_SlotNotificationInvocable.NotificationRequest req = new SCH_SlotNotificationInvocable.NotificationRequest();
        req.territoryId = st.Id;
        req.workTypeId = wt.Id;


        Test.startTest();
        SCH_SlotNotificationInvocable.sendNotifications(new List<SCH_SlotNotificationInvocable.NotificationRequest>{ req });
        Test.stopTest();

        String key = String.valueOf(st.Id) + '|' + String.valueOf(wt.Id);
        System.assert(SCH_SlotNotificationInvocable.notifiedKeys.contains(key), 'Should notify: distinct slots = 2 even though roll-up SUM = 4');
    }

    @IsTest
    static void testNoDeduplicationForDifferentResources() {
        // 1 resource × 4 times × 2 channels = 8 roll-up, distinct = 4 → both days > 2 → should NOT notify
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE Name = 'Loja Teste' LIMIT 1];
        WorkType wt = [SELECT Id FROM WorkType WHERE Name = 'Serviço Teste' LIMIT 1];

        EngagementChannelType ect1 = new EngagementChannelType(Name = 'Channel DedupA');
        EngagementChannelType ect2 = new EngagementChannelType(Name = 'Channel DedupB');
        insert new List<EngagementChannelType>{ ect1, ect2 };

        ServiceResource sr1 = new ServiceResource(Name = 'Resource DedupA', RelatedRecordId = UserInfo.getUserId(), ResourceType = 'T', IsActive = true);
        insert sr1;

        AppointmentSlotSummary__c sum1 = new AppointmentSlotSummary__c(
            ServiceTerritory__c = st.Id, WorkType__c = wt.Id, EngagementChannelType__c = ect1.Id, UniqueKey__c = 'test-nodedup-ch1'
        );
        AppointmentSlotSummary__c sum2 = new AppointmentSlotSummary__c(
            ServiceTerritory__c = st.Id, WorkType__c = wt.Id, EngagementChannelType__c = ect2.Id, UniqueKey__c = 'test-nodedup-ch2'
        );
        insert new List<AppointmentSlotSummary__c>{ sum1, sum2 };

        // 4 distinct today slots duplicated in 2 channels
        List<AppointmentSlot__c> slots = new List<AppointmentSlot__c>();
        for (Integer i = 0; i < 4; i++) {
            DateTime slotStart = DateTime.now().addHours(i + 1);
            DateTime slotEnd = DateTime.now().addHours(i + 2);
            slots.add(new AppointmentSlot__c(
                ServiceResource__c = sr1.Id, AppointmentSlotSummary__c = sum1.Id,
                StartTime__c = slotStart, EndTime__c = slotEnd, StartDate__c = Date.today(),
                Available__c = true, IsToday__c = true, IsTomorrow__c = false,
                UniqueKey__c = 'slot-nodedup-ch1-' + i
            ));
            slots.add(new AppointmentSlot__c(
                ServiceResource__c = sr1.Id, AppointmentSlotSummary__c = sum2.Id,
                StartTime__c = slotStart, EndTime__c = slotEnd, StartDate__c = Date.today(),
                Available__c = true, IsToday__c = true, IsTomorrow__c = false,
                UniqueKey__c = 'slot-nodedup-ch2-' + i
            ));
        }
        // 4 distinct tomorrow slots in both channels (distinct=4 > 2)
        for (Integer i = 0; i < 4; i++) {
            DateTime slotStart = DateTime.now().addDays(1).addHours(i + 1);
            DateTime slotEnd = DateTime.now().addDays(1).addHours(i + 2);
            slots.add(new AppointmentSlot__c(
                ServiceResource__c = sr1.Id, AppointmentSlotSummary__c = sum1.Id,
                StartTime__c = slotStart, EndTime__c = slotEnd, StartDate__c = Date.today().addDays(1),
                Available__c = true, IsToday__c = false, IsTomorrow__c = true,
                UniqueKey__c = 'slot-nodedup-ch1-tmr-' + i
            ));
            slots.add(new AppointmentSlot__c(
                ServiceResource__c = sr1.Id, AppointmentSlotSummary__c = sum2.Id,
                StartTime__c = slotStart, EndTime__c = slotEnd, StartDate__c = Date.today().addDays(1),
                Available__c = true, IsToday__c = false, IsTomorrow__c = true,
                UniqueKey__c = 'slot-nodedup-ch2-tmr-' + i
            ));
        }
        insert slots;

        // Distinct today = 4, distinct tomorrow = 4 → both > 2 → should NOT notify
        SCH_SlotNotificationInvocable.NotificationRequest req = new SCH_SlotNotificationInvocable.NotificationRequest();
        req.territoryId = st.Id;
        req.workTypeId = wt.Id;


        Test.startTest();
        SCH_SlotNotificationInvocable.sendNotifications(new List<SCH_SlotNotificationInvocable.NotificationRequest>{ req });
        Test.stopTest();

        String key = String.valueOf(st.Id) + '|' + String.valueOf(wt.Id);
        System.assert(!SCH_SlotNotificationInvocable.notifiedKeys.contains(key), 'Should NOT notify: distinct slots = 4 even though each summary only has 4');
    }

    @IsTest
    static void testTodayOnlyAlert() {
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE Name = 'Loja Teste' LIMIT 1];
        WorkType wt = [SELECT Id FROM WorkType WHERE Name = 'Serviço Teste' LIMIT 1];

        EngagementChannelType ect = new EngagementChannelType(Name = 'Channel Today');
        insert ect;

        ServiceResource sr = new ServiceResource(Name = 'Resource Today', RelatedRecordId = UserInfo.getUserId(), ResourceType = 'T', IsActive = true);
        insert sr;

        AppointmentSlotSummary__c summary1 = new AppointmentSlotSummary__c(
            ServiceTerritory__c = st.Id, WorkType__c = wt.Id, EngagementChannelType__c = ect.Id, UniqueKey__c = 'test-today-only'
        );
        insert summary1;

        List<AppointmentSlot__c> slots = new List<AppointmentSlot__c>();
        // 1 slot today (<=2) → should trigger
        slots.add(new AppointmentSlot__c(
            ServiceResource__c = sr.Id, AppointmentSlotSummary__c = summary1.Id,
            StartTime__c = DateTime.now().addHours(1), EndTime__c = DateTime.now().addHours(2),
            StartDate__c = Date.today(), Available__c = true,            IsToday__c = true, IsTomorrow__c = false, UniqueKey__c = 'slot-today-only-0'
        ));
        // 5 slots tomorrow (>2)
        for (Integer i = 0; i < 5; i++) {
            slots.add(new AppointmentSlot__c(
                ServiceResource__c = sr.Id, AppointmentSlotSummary__c = summary1.Id,
                StartTime__c = DateTime.now().addDays(1).addHours(i + 1), EndTime__c = DateTime.now().addDays(1).addHours(i + 2),
                StartDate__c = Date.today().addDays(1), Available__c = true,                IsToday__c = false, IsTomorrow__c = true, UniqueKey__c = 'slot-today-only-tmr-' + i
            ));
        }
        insert slots;

        SCH_SlotNotificationInvocable.NotificationRequest req = new SCH_SlotNotificationInvocable.NotificationRequest();
        req.territoryId = st.Id;
        req.workTypeId = wt.Id;


        Test.startTest();
        SCH_SlotNotificationInvocable.sendNotifications(new List<SCH_SlotNotificationInvocable.NotificationRequest>{ req });
        Test.stopTest();

        String key = String.valueOf(st.Id) + '|' + String.valueOf(wt.Id);
        System.assert(SCH_SlotNotificationInvocable.notifiedKeys.contains(key), 'Should notify when today <= 2 even if tomorrow > 2');
    }

    @IsTest
    static void testTomorrowOnlyAlert() {
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE Name = 'Loja Teste' LIMIT 1];
        WorkType wt = [SELECT Id FROM WorkType WHERE Name = 'Serviço Teste' LIMIT 1];

        EngagementChannelType ect = new EngagementChannelType(Name = 'Channel Tomorrow');
        insert ect;

        ServiceResource sr = new ServiceResource(Name = 'Resource Tomorrow', RelatedRecordId = UserInfo.getUserId(), ResourceType = 'T', IsActive = true);
        insert sr;

        AppointmentSlotSummary__c summary1 = new AppointmentSlotSummary__c(
            ServiceTerritory__c = st.Id, WorkType__c = wt.Id, EngagementChannelType__c = ect.Id, UniqueKey__c = 'test-tmr-only'
        );
        insert summary1;

        List<AppointmentSlot__c> slots = new List<AppointmentSlot__c>();
        // 5 slots today (>2)
        for (Integer i = 0; i < 5; i++) {
            slots.add(new AppointmentSlot__c(
                ServiceResource__c = sr.Id, AppointmentSlotSummary__c = summary1.Id,
                StartTime__c = DateTime.now().addHours(i + 1), EndTime__c = DateTime.now().addHours(i + 2),
                StartDate__c = Date.today(), Available__c = true,                IsToday__c = true, IsTomorrow__c = false, UniqueKey__c = 'slot-tmr-only-today-' + i
            ));
        }
        // 1 slot tomorrow (<=2) → should trigger
        slots.add(new AppointmentSlot__c(
            ServiceResource__c = sr.Id, AppointmentSlotSummary__c = summary1.Id,
            StartTime__c = DateTime.now().addDays(1).addHours(1), EndTime__c = DateTime.now().addDays(1).addHours(2),
            StartDate__c = Date.today().addDays(1), Available__c = true,            IsToday__c = false, IsTomorrow__c = true, UniqueKey__c = 'slot-tmr-only-0'
        ));
        insert slots;

        SCH_SlotNotificationInvocable.NotificationRequest req = new SCH_SlotNotificationInvocable.NotificationRequest();
        req.territoryId = st.Id;
        req.workTypeId = wt.Id;


        Test.startTest();
        SCH_SlotNotificationInvocable.sendNotifications(new List<SCH_SlotNotificationInvocable.NotificationRequest>{ req });
        Test.stopTest();

        String key = String.valueOf(st.Id) + '|' + String.valueOf(wt.Id);
        System.assert(SCH_SlotNotificationInvocable.notifiedKeys.contains(key), 'Should notify when tomorrow <= 2 even if today > 2');
    }

    @IsTest
    static void testBothDaysAboveThreshold() {
        ServiceTerritory st = [SELECT Id FROM ServiceTerritory WHERE Name = 'Loja Teste' LIMIT 1];
        WorkType wt = [SELECT Id FROM WorkType WHERE Name = 'Serviço Teste' LIMIT 1];

        EngagementChannelType ect = new EngagementChannelType(Name = 'Channel Both');
        insert ect;

        ServiceResource sr = new ServiceResource(Name = 'Resource Both', RelatedRecordId = UserInfo.getUserId(), ResourceType = 'T', IsActive = true);
        insert sr;

        AppointmentSlotSummary__c summary1 = new AppointmentSlotSummary__c(
            ServiceTerritory__c = st.Id, WorkType__c = wt.Id, EngagementChannelType__c = ect.Id, UniqueKey__c = 'test-both-above'
        );
        insert summary1;

        List<AppointmentSlot__c> slots = new List<AppointmentSlot__c>();
        // 4 slots today (>2)
        for (Integer i = 0; i < 4; i++) {
            slots.add(new AppointmentSlot__c(
                ServiceResource__c = sr.Id, AppointmentSlotSummary__c = summary1.Id,
                StartTime__c = DateTime.now().addHours(i + 1), EndTime__c = DateTime.now().addHours(i + 2),
                StartDate__c = Date.today(), Available__c = true,                IsToday__c = true, IsTomorrow__c = false, UniqueKey__c = 'slot-both-today-' + i
            ));
        }
        // 4 slots tomorrow (>2)
        for (Integer i = 0; i < 4; i++) {
            slots.add(new AppointmentSlot__c(
                ServiceResource__c = sr.Id, AppointmentSlotSummary__c = summary1.Id,
                StartTime__c = DateTime.now().addDays(1).addHours(i + 1), EndTime__c = DateTime.now().addDays(1).addHours(i + 2),
                StartDate__c = Date.today().addDays(1), Available__c = true,                IsToday__c = false, IsTomorrow__c = true, UniqueKey__c = 'slot-both-tmr-' + i
            ));
        }
        insert slots;

        SCH_SlotNotificationInvocable.NotificationRequest req = new SCH_SlotNotificationInvocable.NotificationRequest();
        req.territoryId = st.Id;
        req.workTypeId = wt.Id;


        Test.startTest();
        SCH_SlotNotificationInvocable.sendNotifications(new List<SCH_SlotNotificationInvocable.NotificationRequest>{ req });
        Test.stopTest();

        String key = String.valueOf(st.Id) + '|' + String.valueOf(wt.Id);
        System.assert(!SCH_SlotNotificationInvocable.notifiedKeys.contains(key), 'Should NOT notify when both today and tomorrow > 2');
    }

    @IsTest
    static void testNullAndEmptyInput() {
        Test.startTest();
        SCH_SlotNotificationInvocable.sendNotifications(null);
        SCH_SlotNotificationInvocable.sendNotifications(new List<SCH_SlotNotificationInvocable.NotificationRequest>());
        Test.stopTest();

        System.assertEquals(0, SCH_SlotNotificationInvocable.notifiedKeys.size(), 'No keys should be notified for null/empty input');
    }

    @IsTest
    static void testNullIds() {
        SCH_SlotNotificationInvocable.NotificationRequest req1 = new SCH_SlotNotificationInvocable.NotificationRequest();
        req1.territoryId = null;
        req1.workTypeId = null;


        Test.startTest();
        SCH_SlotNotificationInvocable.sendNotifications(new List<SCH_SlotNotificationInvocable.NotificationRequest>{ req1 });
        Test.stopTest();

        System.assertEquals(0, SCH_SlotNotificationInvocable.notifiedKeys.size(), 'Null IDs should be skipped');
    }
}