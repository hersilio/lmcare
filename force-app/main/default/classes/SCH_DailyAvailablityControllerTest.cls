@isTest
public class SCH_DailyAvailablityControllerTest {
    @TestSetup
    static void makeData(){
        Integer numSummaries = 5; 
        Integer numSlots = 4;

        OperatingHours operatingHours = new OperatingHours(
            Name = 'Test Operating Hours',
            TimeZone = 'America/New_York'
        );
        insert operatingHours;

        // Create WorkType
        WorkType workType = new WorkType(Name = 'Test WorkType');
        workType.EstimatedDuration = 60;
        insert workType;

        // Create ServiceTerritory
        ServiceTerritory serviceTerritory = new ServiceTerritory(Name = 'Test Territory');
        serviceTerritory.OperatingHoursId = operatingHours.Id;
        insert serviceTerritory;

        // Create EngagementChannelType
        EngagementChannelType engagementChannelType = new EngagementChannelType(Name = 'Test Engagement Type');
        engagementChannelType.ContactPointType = 'Video';
        insert engagementChannelType;

        // Create a Service Resource with necessary fields and relation to the territory
        ServiceResource serviceResource = new ServiceResource(
            Name = 'Test Resource',
            IsActive = true,
            relatedRecordId = UserInfo.getUserId()
        );
        insert serviceResource;

        List<AppointmentSlotSummary__c> summaries = new List<AppointmentSlotSummary__c>();
        for (Integer i = 0; i < numSummaries; i++) {
            AppointmentSlotSummary__c summary = new AppointmentSlotSummary__c(
                WorkType__c = workType.Id,
                ServiceTerritory__c = serviceTerritory.Id,
                EngagementChannelType__c = engagementChannelType.Id,
                UniqueKey__c = workType.Id + '-' + serviceTerritory.Id + '-' + engagementChannelType.Id + String.valueOf(i)
            );
            summaries.add(summary);
        }
        insert summaries;

        WorkTypeGroup workTypeGroup = new WorkTypeGroup(Name = 'Test WorkTypeGroup');
        insert workTypeGroup;

        WorkTypeGroupMember workTypeGroupMember = new WorkTypeGroupMember(
            WorkTypeGroupId = workTypeGroup.Id,
            WorkTypeId = workType.Id
        );
        insert workTypeGroupMember;

        List<AppointmentSlot__c> slots = new List<AppointmentSlot__c>();
        for (AppointmentSlotSummary__c summary : summaries) {
            for (Integer j = 0; j < numSlots; j++) {
                AppointmentSlot__c slot = new AppointmentSlot__c(
                    StartDate__c = Date.today().addDays(j),
                    Available__c = true,
                    AppointmentSlotSummary__c = summary.Id,
                    ServiceResource__c = serviceResource.Id,
                    StartTime__c = DateTime.now().addDays(j),
                    EndTime__c = DateTime.now().addDays(j).addHours(1),
                    UniqueKey__c = summary.Id.toString() + serviceResource.Id.toString() + String.valueOf(j)
                );
                slots.add(slot);
            }
        }
        insert slots;
    }

    @isTest
    static void testGetAvailableDates_AllParamsPresent() {
        String startDate = String.valueOf(Date.today());
        String endDate = String.valueOf(Date.today().addDays(2));
        Id workTypeGroupId = [SELECT Id FROM WorkTypeGroup LIMIT 1].Id;
        Id storeId = [SELECT Id FROM ServiceTerritory LIMIT 1].Id;
        Id engagementChannelTypeId = [SELECT Id FROM EngagementChannelType LIMIT 1].Id;

        Test.startTest();
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/dailyAvailability';
        req.httpMethod = 'GET';
        req.params.put('startDate', startDate);
        req.params.put('endDate', endDate);
        req.params.put('workTypeGroupId', String.valueOf(workTypeGroupId));
        req.params.put('storeId', String.valueOf(storeId));
        req.params.put('engagementChannelTypeId', String.valueOf(engagementChannelTypeId));

        RestContext.request = req;
        RestContext.response = new RestResponse();
        SCH_DailyAvailablityController.getAvailableDates();
        
        Test.stopTest();
        System.assertEquals(200, RestContext.response.statusCode, RestContext.response.responseBody.toString());
    }

    @isTest
    static void testGetAvailableDates_MissingParams() {
        Test.startTest();
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/dailyAvailability';
        // Intentionally missing other required params
        req.httpMethod = 'GET';
        req.params.put('startDate', String.valueOf(Date.today()));
        RestContext.request = req;
        RestContext.response = new RestResponse();

        SCH_DailyAvailablityController.getAvailableDates();
        Test.stopTest();
        System.assertEquals(400, RestContext.response.statusCode, RestContext.response.responseBody.toString());
    }

    @isTest
    static void testGetAvailableDates_InvalidIdFormat() {

        Test.startTest();
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/dailyAvailability/';
        req.httpMethod = 'GET';
        req.params.put('startDate', String.valueOf(Date.today()));
        req.params.put('endDate', String.valueOf(Date.today().addDays(1)));
        req.params.put('workTypeGroupId', 'invalid');
        req.params.put('storeId', 'invalid');
        req.params.put('engagementChannelTypeId', 'invalid');
        RestContext.request = req;
        RestContext.response = new RestResponse();

        SCH_DailyAvailablityController.getAvailableDates();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode, RestContext.response.responseBody.toString());
    }

        @isTest
    static void testGetAvailableDates_InvalidDateFormat() {

        Id workTypeGroupId = [SELECT Id FROM WorkTypeGroup LIMIT 1].Id;
        Id storeId = [SELECT Id FROM ServiceTerritory LIMIT 1].Id;
        Id engagementChannelTypeId = [SELECT Id FROM EngagementChannelType LIMIT 1].Id;

        Test.startTest();
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/dailyAvailability/';
        req.httpMethod = 'GET';
        req.params.put('startDate', 'invalid-date');
        req.params.put('endDate', 'invalid-date');
        req.params.put('workTypeGroupId', workTypeGroupId);
        req.params.put('storeId', storeId);
        req.params.put('engagementChannelTypeId', engagementChannelTypeId);
        RestContext.request = req;
        RestContext.response = new RestResponse();

        SCH_DailyAvailablityController.getAvailableDates();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode, RestContext.response.responseBody.toString());
    }

    @isTest
    static void testGetAvailableDates_NoAvailableDates() {
        // Use valid params but mock service to return empty map

        Id workTypeGroupId = [SELECT Id FROM WorkTypeGroup LIMIT 1].Id;
        Id storeId = [SELECT Id FROM ServiceTerritory LIMIT 1].Id;
        Id engagementChannelTypeId = [SELECT Id FROM EngagementChannelType LIMIT 1].Id;

        Test.startTest();
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/dailyAvailability';
        req.httpMethod = 'GET';
        req.params.put('startDate', String.valueOf(Date.today().addDays(100)));
        req.params.put('endDate', String.valueOf(Date.today().addDays(101)));
        req.params.put('workTypeGroupId', String.valueOf(workTypeGroupId));
        req.params.put('storeId', String.valueOf(storeId));
        req.params.put('engagementChannelTypeId', String.valueOf(engagementChannelTypeId));
        RestContext.request = req;
        RestContext.response = new RestResponse();

        SCH_DailyAvailablityController.getAvailableDates();
        Test.stopTest();

        System.assertEquals(404,  RestContext.response.statusCode, RestContext.response.responseBody.toString());
    }
}