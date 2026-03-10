/**
 * @description       :
 * @author            : Hersilio Belini de Oliveira
 * @group             :
 * @last modified on  : 2025-09-01
 * @last modified by  : Hersilio Belini de Oliveira
**/
@isTest
public with sharing class AppointmentSlotServiceTest {
    @TestSetup
    static void makeData(){

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

        // Necessário para vincular o resource ao território
        ServiceTerritoryMember member = new ServiceTerritoryMember(
            ServiceTerritoryId = territory.Id,
            ServiceResourceId = sr.Id,
            EffectiveStartDate = Date.today().addDays(-1)
        );
        insert member;

        WorkType wt = new WorkType(Name='WT - Test', EstimatedDuration=30);
        insert wt;

        WorkTypeGroup wtg = new WorkTypeGroup(Name='WT - Test', GroupType='Default');
        insert wtg;

        WorkTypeGroupMember wtgm = new WorkTypeGroupMember(WorkTypeGroupId = wtg.Id, WorkTypeId = wt.Id);
        insert wtgm;

        EngagementChannelType ect = new EngagementChannelType(
            Name='Channel Test',
            ContactPointType='Phone',
            UsageType='Salesforce Scheduler',
            IsActive=true
        );
        insert ect;

        EngagementChannelWorkType ecwt = new EngagementChannelWorkType(
            WorkTypeId = wt.Id,
            EngagementChannelTypeId = ect.Id
        );
        insert ecwt;

        Shift shift = new Shift(
            ServiceResourceId = sr.Id,
            ServiceTerritoryId = territory.Id,
            WorkTypeGroupId = wtg.Id,
            RecurrenceEndDate = Date.today().addDays(60),
            StartTime = DateTime.now().addDays(1),
            EndTime = DateTime.now().addDays(10)
        );
        insert shift;
    }

    @isTest
    static void AppointmentSlotSchedulerTest() {
        ServiceTerritory territory = [SELECT Id FROM ServiceTerritory LIMIT 1];
        EngagementChannelType ect = [SELECT Id FROM EngagementChannelType LIMIT 1];

        Test.startTest();
        AppointmentSlotScheduler scheduler = new AppointmentSlotScheduler(5, 30);
        scheduler.execute(null);
        AppointmentSlotScheduler.scheduleJob(null, 'Appointment Slot Scheduler Hourly Test', 5, 30);
        Test.stopTest();

        // Verify that the job was scheduled
        List<CronTrigger> jobs = [SELECT Id, CronJobDetail.Name FROM CronTrigger WHERE CronJobDetail.Name = 'Appointment Slot Scheduler Hourly Test'];
        System.assertEquals(1, jobs.size(), 'The job should be scheduled.');
    }
}