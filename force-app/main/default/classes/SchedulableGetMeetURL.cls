global with sharing class SchedulableGetMeetURL implements Schedulable, Database.Batchable<SObject>, Database.AllowsCallouts {

    global void execute (schedulableContext sc) {
        SchedulableGetMeetURL schedulable = new SchedulableGetMeetURL(); 
        Database.executeBatch(schedulable, 1);
        System.abortJob(sc.getTriggerId());
    }

    global Database.QueryLocator start (Database.BatchableContext bc){
        return Database.getQueryLocator([SELECT Id, Owner.Email, AppointmentNumber, SchedStartTime, SchedEndTime, SCH_Google_Meet_URL__c, GoogleMeetSchError__c FROM ServiceAppointment WHERE SCH_Google_Meet_URL__c = null AND EngagementChannelType.ContactPointType = 'Video' AND SchedStartTime >= :DateTime.now() AND Status <> 'Cancelled' AND Status <> 'Completed']);
    }

    global void execute(Database.BatchableContext bc, List<ServiceAppointment> scope){
        for(ServiceAppointment sa : scope){
            SCH_callOut.SCH_Meeting(sa);
        }
    }

    global void finish (Database.BatchableContext bc){
        
        SchedulableGetMeetURL schedulable = new SchedulableGetMeetURL();
        String jobName = 'SchedulableGetMeetURL' + Datetime.now().getTime();
        String cronExp = DateTime.now().addMinutes(10).format('s m H d M \'?\' yyyy');

        if(!Test.isRunningTest()) System.schedule(jobName, cronExp, schedulable);
    }
}