@isTest
public without sharing class MappingSchedulerEmailTemplateTest {
    
    @isTest (SeeAllData=true)
    public static void TestMappingSchedulerEmailTemplateCount(){
        List<MappingSchedulerEmailTemplate__mdt> mdtList = [SELECT Id FROM MappingSchedulerEmailTemplate__mdt];
        List<String> availableStatus = new List<String>{'Canceled', 'Scheduled', 'Scheduled - Updated'};
        List<String> availableRelatedToTypes = new List<String>{'Account', 'Person Account' , 'Lead' , 'Contact' };
        List<String> availableEngagementTypes = new List<String>{'À Distância', 'Presencial'};
        List<WorkType> workTypes = [SELECT Id FROM WorkType WHERE NOT Name LIKE '%TEST%'];

        // Test Total Size
        Integer expectedTotalSize = availableStatus.size() * availableRelatedToTypes.size() * availableEngagementTypes.size()*workTypes.size();
        System.assertEquals(expectedTotalSize, mdtList.size(), 'MappingSchedulerEmailTemplate__mdt count is not as expected');
    }

    @isTest (SeeAllData=true)
    public static void TestEmailTemplatesValid(){
        List<MappingSchedulerEmailTemplate__mdt> mdtList = [SELECT Id, EmailTemplate__c FROM MappingSchedulerEmailTemplate__mdt];
        Set<String> activeEmailTemplates = new Set<String>();
        Set<String> emailTemplatesInMdt  = new Set<String>();
        for (MappingSchedulerEmailTemplate__mdt mdt : mdtList)
            emailTemplatesInMdt.add(mdt.EmailTemplate__c);
        for (EmailTemplate et : [SELECT Id, DeveloperName FROM EmailTemplate WHERE IsActive = true AND DeveloperName IN :emailTemplatesInMdt])
            activeEmailTemplates.add(et.DeveloperName);

        Set<String> difference = new Set<String>(emailTemplatesInMdt);
        difference.removeAll(activeEmailTemplates);
        System.debug(emailTemplatesInMdt);
        System.debug(activeEmailTemplates);

        System.assertEquals(difference.size(), 0, 'Email Templates in MappingSchedulerEmailTemplate__mdt are not active or don\'t exist.\nDifference:'+ difference);
    }
}