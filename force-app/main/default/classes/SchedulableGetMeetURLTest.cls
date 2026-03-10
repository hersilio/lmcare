@isTest
private class SchedulableGetMeetURLTest {
    
    @testSetup
    static void setup() {
        // Create test data
        List<ServiceAppointment> appointments = new List<ServiceAppointment>();
        EngagementChannelType videoEngagementType = new EngagementChannelType(
            Name = 'Video',
            ContactPointType = 'Video'
        );
        insert videoEngagementType;

        Lead leadTest = new Lead(LastName = 'Silva', Loja_de_Angariacao__c='Oeiras',Status='New', MobilePhone='965306985', OwnerId = UserInfo.getUserId());
        Insert leadTest;


        ServiceAppointment sa = new ServiceAppointment(
            OwnerId = UserInfo.getUserId(),
            SchedStartTime = DateTime.now().addDays(1),
            SchedEndTime = DateTime.now().addDays(1).addHours(1),
            EngagementChannelTypeId = videoEngagementType.Id,
            Status = 'Scheduled',
            parentRecordId = leadTest.Id
        );

        insert sa;
    }

    @isTest
    static void testExecute() {
        Test.startTest();
        SchedulableGetMeetURL schedulable = new SchedulableGetMeetURL();
        String cronExp = Datetime.now().addMinutes(1).format('s m H d M \'?\' yyyy');
        String jobId = System.schedule('TestJob', cronExp, schedulable);
        Test.stopTest();
        
        // Verify the job was scheduled
        List<AsyncApexJob> ct = [SELECT Id, CronTriggerId, JobType FROM AsyncApexJob WHERE CronTriggerId = :jobId];
        System.assert(ct.isEmpty() == false);
    }

    @isTest
    static void testBatchable() {
        Test.startTest();
        SchedulableGetMeetURL schedulable = new SchedulableGetMeetURL();
        Database.executeBatch(schedulable, 1);
        Test.stopTest();
        
        // Verify the batch job executed
        Integer count = [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'BatchApex' AND Status = 'Completed'];
        System.assert(count > 0);
    }
}