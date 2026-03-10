@isTest
public with sharing class SCH_ContentDocumentLinkTriggerTest {
  @IsTest
  static void testOrderFileVisibility() {
    Account acc = new Account(Name = 'Test Account');
    insert acc;

    Order o = new Order(Name = 'Test Order', AccountId = acc.Id, Status = 'Em Tratamento', EffectiveDate = Date.today());
    insert o;

    ContentVersion cv = new ContentVersion(Title = 'Test File', PathOnClient = 'test.txt', VersionData = Blob.valueOf('dummy'));
    insert cv;
    cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

    ContentDocumentLink cdl = new ContentDocumentLink(ContentDocumentId = cv.ContentDocumentId, LinkedEntityId = o.Id, ShareType = 'I', Visibility = 'InternalUsers');
    insert cdl;

    ContentDocumentLink inserted = [SELECT Id, ShareType, Visibility, LinkedEntityId FROM ContentDocumentLink WHERE Id = :cdl.Id];

    System.assertEquals('V', inserted.ShareType, 'ShareType should be V');
    System.assertEquals('AllUsers', inserted.Visibility, 'Visibility should be AllUsers');
    System.assertEquals(o.Id, inserted.LinkedEntityId, 'Should still be linked to the same Order');
  }

  @IsTest
  static void testEmailAttachmentLinkedToRelatedRecord() {
    Account acc = new Account(Name = 'Test Account CDL');
    insert acc;

    EmailMessage em = new EmailMessage(FromAddress = 'agent@test.com', ToAddress = 'client@test.com', Subject = 'Test Email', TextBody = 'Test', RelatedToId = acc.Id, Status = '3');
    insert em;

    ContentVersion cv = new ContentVersion(Title = 'Attachment', PathOnClient = 'attachment.txt', VersionData = Blob.valueOf('content'));
    insert cv;
    cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

    Test.startTest();
    ContentDocumentLink cdl = new ContentDocumentLink(ContentDocumentId = cv.ContentDocumentId, LinkedEntityId = em.Id, ShareType = 'V', Visibility = 'AllUsers');
    insert cdl;
    Test.stopTest();

    List<ContentDocumentLink> accLinks = [SELECT Id FROM ContentDocumentLink WHERE ContentDocumentId = :cv.ContentDocumentId AND LinkedEntityId = :acc.Id];
    System.assertEquals(1, accLinks.size(), 'Attachment should be linked to the related Account');
  }

  @IsTest
  static void testEmailAttachmentNoRelatedRecord() {
    EmailMessage em = new EmailMessage(FromAddress = 'agent@test.com', ToAddress = 'client@test.com', Subject = 'No Related', TextBody = 'Test', Status = '3');
    insert em;

    ContentVersion cv = new ContentVersion(Title = 'File', PathOnClient = 'file.txt', VersionData = Blob.valueOf('data'));
    insert cv;
    cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

    Test.startTest();
    ContentDocumentLink cdl = new ContentDocumentLink(ContentDocumentId = cv.ContentDocumentId, LinkedEntityId = em.Id, ShareType = 'V', Visibility = 'AllUsers');
    insert cdl;
    Test.stopTest();

    Boolean hasExtraBusinessRecordLink = false;
    for (ContentDocumentLink link : [SELECT LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId = :cv.ContentDocumentId AND LinkedEntityId != :em.Id]) {
      Schema.SObjectType objType = link.LinkedEntityId.getSObjectType();
      if (objType != Task.SObjectType && objType != User.SObjectType) {
        hasExtraBusinessRecordLink = true;
      }
    }
    System.assert(!hasExtraBusinessRecordLink, 'No extra business record links should be created when email has no RelatedToId');
  }

  @IsTest
  static void testOrderFileVisibilityBulk() {
    Account acc = new Account(Name = 'Test Account');
    insert acc;

    Order o1 = new Order(Name = 'Test Order 1', AccountId = acc.Id, Status = 'Em Tratamento', EffectiveDate = Date.today());
    Order o2 = new Order(Name = 'Test Order 2', AccountId = acc.Id, Status = 'Em Tratamento', EffectiveDate = Date.today());
    List<Order> orders = new List<Order>{ o1, o2 };
    insert orders;

    List<ContentVersion> contentVersions = new List<ContentVersion>();
    for (Integer i = 0; i < 2; i++) {
      contentVersions.add(new ContentVersion(Title = 'Test File ' + i, PathOnClient = 'test' + i + '.txt', VersionData = Blob.valueOf('dummy')));
    }
    insert contentVersions;

    Set<Id> cvIds = new Set<Id>();
    for (ContentVersion cv : contentVersions) {
      cvIds.add(cv.Id);
    }
    List<ContentVersion> cvsWithDocId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :cvIds];
    Map<Id, Id> cvToDocIdMap = new Map<Id, Id>();
    for (ContentVersion cv : cvsWithDocId) {
      cvToDocIdMap.put(cv.Id, cv.ContentDocumentId);
    }

    List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
    for (Integer i = 0; i < 2; i++) {
      cdlList.add(new ContentDocumentLink(ContentDocumentId = cvToDocIdMap.get(contentVersions[i].Id), LinkedEntityId = orders[i].Id, ShareType = 'I', Visibility = 'InternalUsers'));
    }
    insert cdlList;

    for (ContentDocumentLink cdl : cdlList) {
      ContentDocumentLink inserted = [SELECT Id, ShareType, Visibility, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId = :cdl.ContentDocumentId AND LinkedEntityId = :cdl.LinkedEntityId];
      System.assertEquals('V', inserted.ShareType, 'ShareType should be V');
      System.assertEquals('AllUsers', inserted.Visibility, 'Visibility should be AllUsers');
    }
  }
}