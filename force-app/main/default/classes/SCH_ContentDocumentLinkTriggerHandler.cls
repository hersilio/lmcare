public with sharing class SCH_ContentDocumentLinkTriggerHandler {
  public void beforeInsert(List<ContentDocumentLink> newList) {
    applyOrderFileVisibility(newList);
  }

  public void afterInsert(List<ContentDocumentLink> newList) {
    linkEmailAttachmentsToRelatedRecord(newList);
  }

  private void applyOrderFileVisibility(List<ContentDocumentLink> records) {
    for (ContentDocumentLink cdl : records) {
      Id linkedId = cdl.LinkedEntityId;
      if (linkedId == null) {
        continue;
      }

      if (linkedId.getSObjectType() == Order.SObjectType) {
        cdl.Visibility = 'AllUsers';

        if (cdl.ShareType == null || cdl.ShareType == 'I') {
          cdl.ShareType = 'V';
        }
      }
    }
  }

  private void linkEmailAttachmentsToRelatedRecord(
    List<ContentDocumentLink> newList
  ) {
    Set<Id> emailMessageIds = new Set<Id>();
    Map<Id, Set<Id>> emailIdToDocIds = new Map<Id, Set<Id>>();

    for (ContentDocumentLink cdl : newList) {
      if (cdl.LinkedEntityId == null)
        continue;
      if (cdl.LinkedEntityId.getSObjectType() != EmailMessage.SObjectType)
        continue;

      emailMessageIds.add(cdl.LinkedEntityId);
      if (!emailIdToDocIds.containsKey(cdl.LinkedEntityId)) {
        emailIdToDocIds.put(cdl.LinkedEntityId, new Set<Id>());
      }
      emailIdToDocIds.get(cdl.LinkedEntityId).add(cdl.ContentDocumentId);
    }

    if (emailMessageIds.isEmpty())
      return;

    Map<Id, Id> emailIdToRelatedToId = new Map<Id, Id>();
    Set<Id> allDocIds = new Set<Id>();
    for (EmailMessage em : [
      SELECT Id, RelatedToId
      FROM EmailMessage
      WHERE Id IN :emailMessageIds AND RelatedToId != NULL
    ]) {
      emailIdToRelatedToId.put(em.Id, em.RelatedToId);
      allDocIds.addAll(emailIdToDocIds.get(em.Id));
    }

    if (emailIdToRelatedToId.isEmpty())
      return;

    Set<Id> relatedToIds = new Set<Id>(emailIdToRelatedToId.values());

    Set<String> existingLinks = new Set<String>();
    for (ContentDocumentLink existing : [
      SELECT ContentDocumentId, LinkedEntityId
      FROM ContentDocumentLink
      WHERE LinkedEntityId IN :relatedToIds AND ContentDocumentId IN :allDocIds
    ]) {
      existingLinks.add(
        String.valueOf(existing.ContentDocumentId) +
          '_' +
          String.valueOf(existing.LinkedEntityId)
      );
    }

    List<ContentDocumentLink> toInsert = new List<ContentDocumentLink>();
    for (Id emailId : emailIdToRelatedToId.keySet()) {
      Id relatedToId = emailIdToRelatedToId.get(emailId);
      for (Id docId : emailIdToDocIds.get(emailId)) {
        String key = String.valueOf(docId) + '_' + String.valueOf(relatedToId);
        if (!existingLinks.contains(key)) {
          toInsert.add(
            new ContentDocumentLink(
              ContentDocumentId = docId,
              LinkedEntityId = relatedToId,
              ShareType = 'V',
              Visibility = 'AllUsers'
            )
          );
          existingLinks.add(key);
        }
      }
    }

    if (!toInsert.isEmpty()) {
      try {
        insert toInsert;
      } catch (DmlException e) {
        ErrorLog.createErrorLogList(SCH_ContentDocumentLinkTriggerHandler.class.getName(), e.getMessage(), String.valueOf(e.getLineNumber()), 'linkEmailAttachmentsToRelatedRecord', e.getStackTraceString(), e.getTypeName());
      }
    }
  }
}