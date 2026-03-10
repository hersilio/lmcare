/**
 * @description       :
 * @author            : Hersilio Belini de Oliveira
 * @group             :
 * @last modified on  : 2025-09-14
 * @last modified by  : Hersilio Belini de Oliveira
**/
@IsTest
public class AppointmentSlotExpirySchedulerTest {

    private static final String JOB_NAME = 'Appointment Slot Expiry';

    @IsTest
    static void scheduler_runsBatch_and_reschedules_nextExecution() {

        OperatingHours opHours = new OperatingHours(Name='Test OH', TimeZone='America/New_York');
        insert opHours;

        ServiceTerritory territory = new ServiceTerritory(
            Name='Test Territory',
            OperatingHoursId = opHours.Id,
            IsActive=true
        );
        insert territory;

        ServiceResource sr = new ServiceResource(
            Name='Test Resource',
            IsActive=true,
            RelatedRecordId=UserInfo.getUserId()
        );
        insert sr;

        WorkType wt = new WorkType(Name='WT - Test', EstimatedDuration=30);
        insert wt;

        EngagementChannelType channel = new EngagementChannelType(
            Name='Channel Test',
            ContactPointType='Phone',
            UsageType='Salesforce Scheduler',
            IsActive=true
        );
        insert channel;

        AppointmentSlotSummary__c summary = new AppointmentSlotSummary__c(
            ServiceTerritory__c = territory.Id,
            WorkType__c = wt.Id,
            EngagementChannelType__c = channel.Id,
            UniqueKey__c = '12345'
        );

        insert summary;

        AppointmentSlot__c past = new AppointmentSlot__c(
            Available__c = true,
            StartTime__c = System.now().addMinutes(-15),
            EndTime__c = System.now(),
            StartDate__c = Date.today(),
            ServiceResource__c = sr.Id,
            AppointmentSlotSummary__c = summary.Id,
            UniqueKey__c = String.valueOf(DateTime.now().addMinutes(-15))
        );
        AppointmentSlot__c future = new AppointmentSlot__c(
            Available__c = true,
            StartTime__c = System.now(),
            EndTime__c = System.now().addMinutes(15),
            StartDate__c = Date.today(),
            ServiceResource__c = sr.Id,
            AppointmentSlotSummary__c = summary.Id,
            UniqueKey__c = String.valueOf(DateTime.now())
        );

        insert new List<AppointmentSlot__c>{ past, future };

        Test.startTest();
        Database.executeBatch(new AppointmentSlotExpiryBatch(), 50);
        Test.stopTest();

        past   = [SELECT Available__c FROM AppointmentSlot__c WHERE Id = :past.Id];
        future = [SELECT Available__c FROM AppointmentSlot__c WHERE Id = :future.Id];

        System.assertEquals(false, past.Available__c,
            'Slot com StartTime__c no passado deve ficar indisponível.');
        System.assertEquals(true, future.Available__c,
            'Slot futuro deve permanecer disponível.');
    }

    @IsTest
    static void scheduler_acceptsDifferentIntervals() {
        String cron = '0 0 0 1 1 ? 2099';

        Test.startTest();
        System.schedule('TEST - ' + JOB_NAME, cron, new AppointmentSlotExpiryScheduler(5));
        Test.stopTest();

        List<CronTrigger> waiting = [
            SELECT Id, State, CronJobDetail.Name
            FROM CronTrigger
            WHERE State = 'WAITING'
              AND CronJobDetail.Name LIKE :JOB_NAME + '%'
            LIMIT 5
        ];
        System.assert(waiting.size() >= 1,
            'Deve existir pelo menos um CronTrigger em WAITING após o reschedule.');
    }
}