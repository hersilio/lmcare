@isTest
public class SCH_callOutTest {

    private class GoogleMeetMockSuccess implements HttpCalloutMock{
        public HttpResponse respond(HttpRequest req){
            HttpResponse res = new HttpResponse();
            res.setBody('{"items":[{"hangoutLink":"https://meet.google.com/etv-rgab-bef"}]}');
            res.setStatusCode(200);
            return res;
        }
    }
    private class GoogleMeetMockFail implements HttpCalloutMock{
        public HttpResponse respond(HttpRequest req){
            HttpResponse res = new HttpResponse();
            res.setBody('{"error":"Error message"}');
            res.setStatusCode(400);
            return res;
        }
    }

    @TestSetup
    private static void setup(){
        Lead leadTest = new Lead(LastName = 'Silva', Loja_de_Angariacao__c='Oeiras',Status='New', MobilePhone='965306985', OwnerId = UserInfo.getUserId());
        insert leadTest;

        DateTime myDateTime = datetime.now();
        DateTime newDateTime = myDateTime.addMinutes(7);
        ServiceAppointment saTest = new ServiceAppointment(ParentRecordId = leadTest.Id, SchedStartTime= myDateTime, SchedEndTime=newDateTime, OwnerId = UserInfo.getUserId());
        insert saTest;
    }

    @isTest
    private static void getMeetingLink(){
        GoogleMeetMockSuccess mock = new GoogleMeetMockSuccess();
        
        ServiceAppointment getSA = [SELECT Id, AppointmentNumber, ParentRecordId, SchedStartTime, SchedEndTime, Owner.Email FROM ServiceAppointment LIMIT 1];
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        SCH_callOut.SCH_callOut(new List<ServiceAppointment>{getSA});
        Test.stopTest();
        
        // Verify the ServiceAppointment was updated with the hangout link
        getSA = [SELECT SCH_Google_Meet_URL__c, GoogleMeetSchError__c FROM ServiceAppointment WHERE Id = :getSA.Id];
        System.assertEquals('https://meet.google.com/etv-rgab-bef', getSA.SCH_Google_Meet_URL__c); 
        System.assertEquals(null, getSA.GoogleMeetSchError__c); // must be null
    }

    @isTest
    private static void getMeetingLinkError(){
        GoogleMeetMockFail mock = new GoogleMeetMockFail();

        ServiceAppointment getSA = [SELECT Id, AppointmentNumber, ParentRecordId, SchedStartTime, SchedEndTime, Owner.Email FROM ServiceAppointment LIMIT 1];
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, mock);
        SCH_callOut.SCH_callOut(new List<ServiceAppointment>{getSA});
        Test.stopTest();
        
        // Verify the ServiceAppointment was updated with the error message
        getSA = [SELECT SCH_Google_Meet_URL__c, GoogleMeetSchError__c FROM ServiceAppointment WHERE Id = :getSA.Id];
        System.assertEquals(null, getSA.SCH_Google_Meet_URL__c); // must be null
        System.assertNotEquals(null, getSA.GoogleMeetSchError__c); // can't be null
    }
}