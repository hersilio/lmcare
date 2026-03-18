/**
 * @description Helper class for ServiceAppointment trigger logic: email/SMS notifications
 *              and slot invalidation. Called by ServiceAppointmentTriggerHandler.
 */
public with sharing class ServiceAppointmentTriggerHelper {
  public static boolean runTrigger = true;
  public enum TARGET_STATUS { SCHEDULED, SCHEDULED_UPDATED, CANCELED }
  
  private static final String TEMPLATE_DEVELOPER_NAME = 'SCH_ServiceAppointmentCreateOGeneric';
  private static final String TEMPLATE_SMS_CREATE_INPERSON = 'SCH_Contact_InPerson_Create';
  private static final String TEMPLATE_SMS_CREATE_ONLINE = 'SCH_Contact_Online_Create';
  private static final String TEMPLATE_SMS_UPDATE_INPERSON = 'SCH_Contact_InPerson_Modify';
  private static final String TEMPLATE_SMS_UPDATE_ONLINE = 'SCH_Contact_Online_Modify';
  private static Map<Id, Map<String, String>> contactInfoCache;
  
  // Invalidates overlapping slots for newly scheduled ServiceAppointments
  // public static void invalidateSlotsAfterInsert(List<ServiceAppointment> newList) {
  //   if (newList == null || newList.isEmpty())
  //     return;
    
  //   List<ServiceAppointment> toInvalidate = new List<ServiceAppointment>();
    
  //   for (ServiceAppointment sa : newList) {
  //     if (!isScheduled(sa.Status))
  //       continue;
  //     if (sa.SchedStartTime != null && sa.SchedEndTime != null && sa.SCH_Service_Resource__c != null) {
  //       toInvalidate.add(sa);
  //     }
  //   }
    
  //   if (!toInvalidate.isEmpty()) {
  //     invalidateOverlappingSlots(toInvalidate);
  //   }
  // }
  
  // Sends email and SMS notifications for newly created ServiceAppointments (InPerson only)
  public static void sendNotificationsAfterInsert(List<ServiceAppointment> newList) {
    if (newList == null || newList.isEmpty())
      return;
    
    Map<Id, EngagementChannelType> channelTypeMap = loadEngagementChannelTypes(newList);
    List<ServiceAppointment> toNotify = new List<ServiceAppointment>();
    preloadContactInfoCache(newList);
    
    for (ServiceAppointment sa : newList) {
      if (!isScheduled(sa.Status))
        continue;
      EngagementChannelType ect = channelTypeMap.get(sa.EngagementChannelTypeId);
      // Create: Presencial → envia | Video → NÃO envia
      if (ect != null && ect.ContactPointType == 'InPerson') {
        toNotify.add(sa);
      }
    }
    
    if (toNotify.isEmpty())
      return;
    
    sendTemplateEmails(toNotify);
    EmailTemplate smsCreateInPersonTmpl = getTemplateByDeveloperName(TEMPLATE_SMS_CREATE_INPERSON);
    
    if (smsCreateInPersonTmpl != null) {
      sendTemplateSMS(toNotify, smsCreateInPersonTmpl);
    }
  }
  
  // Invalidates overlapping slots when dates or resource change on update
  // public static void invalidateSlotsAfterUpdate(List<ServiceAppointment> newList, Map<Id, ServiceAppointment> oldMap) {
  //   if (newList == null || newList.isEmpty())
  //     return;
    
  //   List<ServiceAppointment> toInvalidate = new List<ServiceAppointment>();
    
  //   for (ServiceAppointment sa : newList) {
  //     ServiceAppointment oldSa = oldMap.get(sa.Id);
  //     if (oldSa == null)
  //       continue;
      
  //     Boolean dateChanged = sa.SchedStartTime != oldSa.SchedStartTime || sa.SchedEndTime != oldSa.SchedEndTime;
  //     Boolean resourceChanged = sa.SCH_Service_Resource__c != oldSa.SCH_Service_Resource__c;
      
  //     if (sa.Status != 'Canceled' && (dateChanged || resourceChanged)) {
  //       if (sa.SchedStartTime != null && sa.SchedEndTime != null && sa.SCH_Service_Resource__c != null) {
  //         toInvalidate.add(sa);
  //       }
  //     }
  //   }
    
  //   if (!toInvalidate.isEmpty()) {
  //     invalidateOverlappingSlots(toInvalidate);
  //   }
  // }
  
  // Sends email and SMS notifications for updated ServiceAppointments
  public static void sendNotificationsAfterUpdate(List<ServiceAppointment> newList, Map<Id, ServiceAppointment> oldMap) {
    if (newList == null || newList.isEmpty())
      return;
    
    Map<Id, EngagementChannelType> channelTypeMap = loadEngagementChannelTypes(newList);
    List<ServiceAppointment> toNotify = new List<ServiceAppointment>();
    List<ServiceAppointment> smsCreateOnline = new List<ServiceAppointment>();
    List<ServiceAppointment> smsUpdateInPerson = new List<ServiceAppointment>();
    List<ServiceAppointment> smsUpdateOnline = new List<ServiceAppointment>();
    
    for (ServiceAppointment sa : newList) {
      ServiceAppointment oldSa = oldMap.get(sa.Id);
      if (oldSa == null)
        continue;
      
      Boolean dateChanged = sa.SchedStartTime != oldSa.SchedStartTime || sa.SchedEndTime != oldSa.SchedEndTime;
      Boolean meetChanged = sa.SCH_Google_Meet_URL__c != oldSa.SCH_Google_Meet_URL__c;
      Boolean channelChanged = sa.EngagementChannelTypeId != oldSa.EngagementChannelTypeId;
      EngagementChannelType ect = channelTypeMap.get(sa.EngagementChannelTypeId);
      Boolean isVideo = ect != null && ect.ContactPointType == 'Video';
      Boolean isInPerson = ect != null && ect.ContactPointType == 'InPerson';
      
      // 1 Cancelado: email sempre, SMS nao — só envia quando o estado muda PARA Canceled
      if (sa.Status == 'Canceled' && oldSa.Status != 'Canceled') {
        toNotify.add(sa);
        continue;
      }
      
      // 2 Scheduled
      if (sa.Status == 'Scheduled') {
        if (isVideo) {
          if (meetChanged && sa.SCH_Google_Meet_URL__c != null) {
            toNotify.add(sa);
            smsCreateOnline.add(sa);
          }
          continue;
        }
        if (isInPerson && (dateChanged || channelChanged)) {
          toNotify.add(sa);
          smsUpdateInPerson.add(sa);
        }
        continue;
      }
      
      // 3 Scheduled - Updated: apenas datas
      if (sa.Status == 'Scheduled - Updated' && dateChanged) {
        toNotify.add(sa);
        if (isVideo) smsUpdateOnline.add(sa);
        else if (isInPerson) smsUpdateInPerson.add(sa);
      }
    }
    
    if (!toNotify.isEmpty()) {
      sendTemplateEmails(toNotify);
    }
    
    if (!smsCreateOnline.isEmpty()) {
      EmailTemplate tmpl = getTemplateByDeveloperName(TEMPLATE_SMS_CREATE_ONLINE);
      if (tmpl != null) sendTemplateSMS(smsCreateOnline, tmpl);
    }
    
    if (!smsUpdateInPerson.isEmpty()) {
      EmailTemplate tmpl = getTemplateByDeveloperName(TEMPLATE_SMS_UPDATE_INPERSON);
      if (tmpl != null) sendTemplateSMS(smsUpdateInPerson, tmpl);
    }
    
    if (!smsUpdateOnline.isEmpty()) {
      EmailTemplate tmpl = getTemplateByDeveloperName(TEMPLATE_SMS_UPDATE_ONLINE);
      if (tmpl != null) sendTemplateSMS(smsUpdateOnline, tmpl);
    }
  }
  
  private static Boolean isScheduled(String statusValue) {
    if (String.isBlank(statusValue))
      return false;
    
    return statusValue.trim().toLowerCase() == 'scheduled';
  }
  
  private static Boolean isTargetStatus(String statusValue) {
    if (String.isBlank(statusValue))
      return false;
    
    String normalized = statusValue.trim().toLowerCase();
    return normalized == 'scheduled' || normalized == 'scheduled - updated' || normalized == 'canceled';
  }
  
  private static void sendTemplateEmails(List<ServiceAppointment> serviceAppointments) {
    if (serviceAppointments == null || serviceAppointments.isEmpty())
      return;
    
    preloadContactInfoCache(serviceAppointments);
    Id templateId = getTemplateByDeveloperName(TEMPLATE_DEVELOPER_NAME).Id;
    
    if (templateId == null)
      return;
    
    Id orgWideId = getOrgWideEmailAddressIdByDisplayName('Leroy Merlin');
    System.debug('Contact: ' + [SELECT id FROM Contact WHERE Email != NULL LIMIT 1]);
    Contact c = [SELECT id FROM Contact WHERE Email != NULL LIMIT 1];
    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
    
    for (ServiceAppointment sa : serviceAppointments) {
      if (sa.ParentRecordId == null) {
        ErrorLog.createErrorLogList('ServiceAppointmentTriggerHelper', 'Sem ParentRecordId no ServiceAppointment para envio de email. SA=' + String.valueOf(sa.Id), null, 'sendTemplateEmails', '', 'WARN');
        continue;
      }
      
      String toEmail = getContactInfoCached(sa.ParentRecordId).get('Email');
      
      if (String.isBlank(toEmail)) {
        ErrorLog.createErrorLogList('ServiceAppointmentTriggerHelper', 'Email não encontrado para ParentRecordId=' + sa.ParentRecordId, null, 'sendTemplateEmails', '', 'WARN');
        continue;
      }
      
      Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
      email.setTemplateId(templateId);
      email.setWhatId(sa.Id);
      email.setTargetObjectId(c.id);
      email.setTreatTargetObjectAsRecipient(false);
      email.setToAddresses(new List<String>{ toEmail });
      
      if (orgWideId != null) {
        email.setOrgWideEmailAddressId(orgWideId);
      }
      
      email.setSaveAsActivity(false);
      emails.add(email);
    }
    
    if (emails.isEmpty())
      return;
    
    try {
      Messaging.SendEmailResult[] results = Messaging.sendEmail(emails, false);
      
      for (Integer i = 0; i < results.size(); i++) {
        Messaging.SendEmailResult r = results[i];
        Messaging.SingleEmailMessage m = emails[i];
        String recipientInfo = 'UserId=' + String.valueOf(m.getTargetObjectId());
        String relatedInfo = 'WhatId=' + String.valueOf(m.getWhatId());
        String fromInfo = 'OrgWideEmailAddressId=' + String.valueOf(m.getOrgWideEmailAddressId());
        String message = (r != null && r.isSuccess()) ? 'Email enviado com sucesso.' : 'Falha no envio de email.';
        String errorsStr = '';
        
        if (r != null && !r.isSuccess()) {
          List<String> parts = new List<String>();
          
          for (Messaging.SendEmailError e2 : r.getErrors()) {
            parts.add('(' + e2.getStatusCode() + ') ' + e2.getMessage());
          }
          errorsStr = String.join(parts, '; ');
        }
        ErrorLog.createErrorLogList('ServiceAppointmentTriggerHelper', message + ' ' + recipientInfo + ' | ' + relatedInfo + ' | ' + fromInfo + (String.isBlank(errorsStr) ? '' : ' | Errors=' + errorsStr), null, 'sendTemplateEmails', '', (r != null && r.isSuccess()) ? 'INFO' : 'ERROR');
      }
    } catch (Exception e) {
      ErrorLog.createErrorLogList('ServiceAppointmentTriggerHelper', e.getMessage(), String.valueOf(e.getLineNumber()), 'sendTemplateEmails', e.getStackTraceString(), e.getTypeName());
    }
  }
  
  private static void sendTemplateSMS(List<ServiceAppointment> serviceAppointments, EmailTemplate templateEmail) {
    if (serviceAppointments == null || serviceAppointments.isEmpty())
      return;
    
    if (templateEmail == null)
      return;
    
    preloadContactInfoCache(serviceAppointments);
    Contact c = [SELECT id FROM Contact WHERE Email != NULL LIMIT 1];
    String smsFrom = 'LeroyMerlin';
    
    for (ServiceAppointment sa : serviceAppointments) {
      if (sa == null || sa.ParentRecordId == null)
        continue;
      
      Map<String, String> contactInfo = getContactInfoCached(sa.ParentRecordId);
      String rawPhone = contactInfo != null ? contactInfo.get('Phone') : null;
      String smsTo = String.isBlank(rawPhone) ? null : (rawPhone.startsWith('+') ? rawPhone : '+351' + rawPhone);
      
      if (String.isBlank(smsTo)) {
        ErrorLog.createErrorLogList('ServiceAppointmentTriggerHelper', 'Telefone não encontrado para ParentRecordId=' + String.valueOf(sa.ParentRecordId), null, 'sendTemplateSMS', '', 'WARN');
        continue;
      }
      
      String smsBody;
      try {
        List<Messaging.RenderEmailTemplateBodyResult> rendered = Messaging.renderEmailTemplate(c.Id, sa.Id, new List<String>{ templateEmail.Body });
        smsBody = (rendered != null && !rendered.isEmpty() && rendered[0] != null) ? rendered[0].getMergedBody() : null;
      } catch (Exception e) {
        try {
          List<Messaging.RenderEmailTemplateBodyResult> rendered2 = Messaging.renderEmailTemplate(sa.Id, sa.Id, new List<String>{ templateEmail.Body });
          smsBody = (rendered2 != null && !rendered2.isEmpty() && rendered2[0] != null) ? rendered2[0].getMergedBody() : null;
        } catch (Exception e2) {
          smsBody = null;
          ErrorLog.createErrorLogList('ServiceAppointmentTriggerHelper', 'Falha ao renderizar template de SMS. SA=' + String.valueOf(sa.Id) + ' | ' + e.getMessage(), String.valueOf(e.getLineNumber()), 'sendTemplateSMS', e.getStackTraceString(), e.getTypeName());
        }
      }
      
      if (String.isBlank(smsBody)) {
        ErrorLog.createErrorLogList('ServiceAppointmentTriggerHelper', 'Corpo de SMS vazio após renderização do template. SA=' + String.valueOf(sa.Id), null, 'sendTemplateSMS', '', 'WARN');
        continue;
      }
      
      try {
        System.enqueueJob(new LM_SendSMS(smsFrom, smsTo, smsBody));
      } catch (Exception e3) {
        ErrorLog.createErrorLogList('ServiceAppointmentTriggerHelper', e3.getMessage(), String.valueOf(e3.getLineNumber()), 'sendTemplateSMS', e3.getStackTraceString(), e3.getTypeName());
      }
    }
  }
  
  private static EmailTemplate getTemplateByDeveloperName(String developerName) {
    System.debug('developerName: ' + developerName);
    if (String.isBlank(developerName))
      return null;
    
    List<EmailTemplate> templates = [SELECT Id, DeveloperName, Body FROM EmailTemplate WHERE DeveloperName = :developerName LIMIT 1];
    System.debug('found templates: ' + templates);
    return templates.isEmpty() ? null : templates[0];
  }
  
  private static Id getOrgWideEmailAddressIdByDisplayName(String displayName) {
    if (String.isBlank(displayName))
      return null;
    
    List<OrgWideEmailAddress> owas = [SELECT Id, DisplayName FROM OrgWideEmailAddress WHERE DisplayName = :displayName LIMIT 1];
    if (!owas.isEmpty())
      return owas[0].Id;
    
    for (OrgWideEmailAddress ow : [SELECT Id, DisplayName FROM OrgWideEmailAddress LIMIT 200]) {
      if (ow.DisplayName != null && ow.DisplayName.trim().toLowerCase() == displayName.trim().toLowerCase())
        return ow.Id;
    }
    return null;
  }
  
  private static Map<String, String> getContactInfoCached(Id parentId) {
    if (parentId == null)
    return new Map<String, String>{ 'Email' => null, 'Phone' => null };
    
    if (contactInfoCache != null && contactInfoCache.containsKey(parentId))
      return contactInfoCache.get(parentId);
    
    return getContactInfo(parentId);
  }
  
  private static void preloadContactInfoCache(List<ServiceAppointment> serviceAppointments) {
    if (serviceAppointments == null || serviceAppointments.isEmpty())
      return;
    
    if (contactInfoCache == null)
      contactInfoCache = new Map<Id, Map<String, String>>();
    Set<Id> toLoad = new Set<Id>();
    for (ServiceAppointment sa : serviceAppointments) {
      if (sa != null && sa.ParentRecordId != null && !contactInfoCache.containsKey(sa.ParentRecordId)) {
        toLoad.add(sa.ParentRecordId);
      }
    }
    if (toLoad.isEmpty())
      return;
    
    Set<Id> leadIds = new Set<Id>();
    Set<Id> accountIds = new Set<Id>();
    Set<Id> oppIds = new Set<Id>();
    
    for (Id pid : toLoad) {
      String t = pid.getSObjectType().getDescribe().getName();
      if (t == 'Lead') leadIds.add(pid);
      else if (t == 'Account') accountIds.add(pid);
      else if (t == 'Opportunity') oppIds.add(pid);
    }
    
    if (!leadIds.isEmpty()) {
      for (Lead l : [SELECT Id, Email, MobilePhone, Phone FROM Lead WHERE Id IN :leadIds]) {
        contactInfoCache.put(l.Id, new Map<String, String>{ 'Email' => l.Email, 'Phone' => l.MobilePhone != null ? l.MobilePhone : l.Phone });
      }
    }
    
    if (!accountIds.isEmpty()) {
      for (Account a : [SELECT Id, E_mail_Empresa__c, IsPersonAccount, PersonEmail, Phone FROM Account WHERE Id IN :accountIds]) {
        contactInfoCache.put(a.Id, new Map<String, String>{ 'Email' => a.IsPersonAccount ? a.PersonEmail : a.E_mail_Empresa__c, 'Phone' => a.Phone });
      }
    }
    
    if (!oppIds.isEmpty()) {
      for (Opportunity o : [SELECT Id, AccountId, Account.PersonEmail, Account.E_mail_Empresa__c, Account.Phone, Account.IsPersonAccount FROM Opportunity WHERE Id IN :oppIds]) {
        if (o.AccountId == null || o.Account == null) {
          contactInfoCache.put(o.Id, new Map<String, String>{ 'Email' => null, 'Phone' => null });
          continue;
        }
        contactInfoCache.put(o.Id, new Map<String, String>{ 'Email' => o.Account.IsPersonAccount ? o.Account.PersonEmail : o.Account.E_mail_Empresa__c, 'Phone' => o.Account.Phone });
      }
    }
  }
  
  private static Map<String, String> getContactInfo(Id parentId) {
    Map<String, String> result = new Map<String, String>{ 'Email' => null, 'Phone' => null };
    
    if (parentId == null)
      return result;
    
    String sobjectType = parentId.getSObjectType().getDescribe().getName();
    
    if (sobjectType == 'Lead') {
      Lead l = [SELECT Email, MobilePhone, Phone FROM Lead WHERE Id = :parentId LIMIT 1];
      result.put('Email', l.Email);
      result.put('Phone', l.MobilePhone != null ? l.MobilePhone : l.Phone);
      return result;
    } else if (sobjectType == 'Account') {
      Account a = [SELECT E_mail_Empresa__c, IsPersonAccount, PersonEmail, Phone FROM Account WHERE Id = :parentId LIMIT 1];
      result.put('Email', a.IsPersonAccount ? a.PersonEmail : a.E_mail_Empresa__c);
      result.put('Phone', a.Phone);
      return result;
    } else if (sobjectType == 'Opportunity') {
      Opportunity o = [SELECT Account.PersonEmail, Account.E_mail_Empresa__c, Account.Phone, Account.IsPersonAccount FROM Opportunity WHERE Id = :parentId LIMIT 1];
      if (o.Account == null)
        return result;
      result.put('Email', o.Account.IsPersonAccount ? o.Account.PersonEmail : o.Account.E_mail_Empresa__c);
      result.put('Phone', o.Account.Phone);
      return result;
    }
    
    return result;
  }
  
  private static Boolean hasDateChanged(ServiceAppointment sa, ServiceAppointment oldSa) {
    return sa.SchedStartTime != oldSa.SchedStartTime || sa.SchedEndTime != oldSa.SchedEndTime;
  }
  
  private static Boolean hasGoogleMeetChanged(ServiceAppointment sa, ServiceAppointment oldSa) {
    return sa.SCH_Google_Meet_URL__c != oldSa.SCH_Google_Meet_URL__c;
  }
  
  private static Boolean isVideo(ServiceAppointment sa) {
    return sa.EngagementChannelTypeId != null && sa.EngagementChannelType.ContactPointType == 'Video';
  }
  
  private static Map<Id, EngagementChannelType> loadEngagementChannelTypes(List<ServiceAppointment> serviceAppointments) {
    Map<Id, EngagementChannelType> result = new Map<Id, EngagementChannelType>();
    if (serviceAppointments == null || serviceAppointments.isEmpty())
      return result;
    
    Set<Id> channelTypeIds = new Set<Id>();
    for (ServiceAppointment sa : serviceAppointments) {
      if (sa.EngagementChannelTypeId != null) {
        channelTypeIds.add(sa.EngagementChannelTypeId);
      }
    }
    
    if (channelTypeIds.isEmpty())
      return result;
    
    for (EngagementChannelType ect : [SELECT Id, ContactPointType FROM EngagementChannelType WHERE Id IN :channelTypeIds]) {
      result.put(ect.Id, ect);
    }
    
    return result;
  }
  
  // Marks overlapping AppointmentSlot__c records as unavailable (Available__c = false)
  // private static void invalidateOverlappingSlots(List<ServiceAppointment> appointments) {
  //   updateOverlappingSlotsAvailability(appointments, false);
  // }
  
  // private static void updateOverlappingSlotsAvailability(List<ServiceAppointment> appointments, Boolean available) {
  //   if (appointments == null || appointments.isEmpty())
  //     return;
    
  //   Set<Id> territoryIds = new Set<Id>();
  //   Set<Id> workTypeIds = new Set<Id>();
  //   Set<Id> channelIds = new Set<Id>();
  //   Set<Id> resourceIds = new Set<Id>();
  //   Datetime overallMinStart = null;
  //   Datetime overallMaxEnd = null;
    
  //   for (ServiceAppointment sa : appointments) {
  //     if (sa.ServiceTerritoryId == null || sa.WorkTypeId == null || sa.EngagementChannelTypeId == null || sa.SCH_Service_Resource__c == null || sa.SchedStartTime == null || sa.SchedEndTime == null)
  //       continue;
  //     territoryIds.add(sa.ServiceTerritoryId);
  //     workTypeIds.add(sa.WorkTypeId);
  //     channelIds.add(sa.EngagementChannelTypeId);
  //     resourceIds.add(sa.SCH_Service_Resource__c);
  //     if (overallMinStart == null || sa.SchedStartTime < overallMinStart) overallMinStart = sa.SchedStartTime;
  //     if (overallMaxEnd == null || sa.SchedEndTime > overallMaxEnd) overallMaxEnd = sa.SchedEndTime;
  //   }
    
  //   if (resourceIds.isEmpty())
  //     return;
    
  //   Map<String, Id> summaryMap = querySummaryMap(workTypeIds, territoryIds, channelIds);
  //   if (summaryMap.isEmpty())
  //     return;
    
  //   Set<Id> summaryIds = new Set<Id>(summaryMap.values());
  //   Boolean targetAvailable = !available;
  //   List<AppointmentSlot__c> candidateSlots = [
  //     SELECT Id, StartTime__c, EndTime__c, ServiceResource__c, AppointmentSlotSummary__c, Available__c
  //     FROM AppointmentSlot__c
  //     WHERE AppointmentSlotSummary__c IN :summaryIds
  //       AND ServiceResource__c IN :resourceIds
  //       AND Available__c = :targetAvailable
  //       AND StartTime__c < :overallMaxEnd
  //       AND EndTime__c > :overallMinStart
  //   ];
  //   if (candidateSlots.isEmpty())
  //     return;
    
  //   List<AppointmentSlot__c> slotsToUpdate = new List<AppointmentSlot__c>();
  //   Set<Id> processedSlotIds = new Set<Id>();
    
  //   for (AppointmentSlot__c slot : candidateSlots) {
  //     if (processedSlotIds.contains(slot.Id))
  //       continue;
  //     for (ServiceAppointment sa : appointments) {
  //       String saKey = sa.WorkTypeId + '|' + sa.ServiceTerritoryId + '|' + sa.EngagementChannelTypeId;
  //       Id expectedSummaryId = summaryMap.get(saKey);
  //       if (expectedSummaryId == null || slot.AppointmentSlotSummary__c != expectedSummaryId || slot.ServiceResource__c != sa.SCH_Service_Resource__c)
  //         continue;
  //       if (slot.StartTime__c < sa.SchedEndTime && slot.EndTime__c > sa.SchedStartTime) {
  //         processedSlotIds.add(slot.Id);
  //         slot.Available__c = available;
  //         slotsToUpdate.add(slot);
  //         break;
  //       }
  //     }
  //   }
  //   if (!slotsToUpdate.isEmpty()) {
  //     Database.SaveResult[] results = Database.update(slotsToUpdate, false);
  //     logSlotUpdateErrors(results, slotsToUpdate, 'updateOverlappingSlotsAvailability');
  //   }
  // }
  
  // private static Map<String, Id> querySummaryMap(Set<Id> workTypeIds, Set<Id> territoryIds, Set<Id> channelIds) {
  //   Map<String, Id> summaryMap = new Map<String, Id>();
  //   for (AppointmentSlotSummary__c s : [
  //     SELECT Id, WorkType__c, ServiceTerritory__c, EngagementChannelType__c
  //     FROM AppointmentSlotSummary__c
  //     WHERE WorkType__c IN :workTypeIds AND ServiceTerritory__c IN :territoryIds AND EngagementChannelType__c IN :channelIds
  //   ]) {
  //     summaryMap.put(s.WorkType__c + '|' + s.ServiceTerritory__c + '|' + s.EngagementChannelType__c, s.Id);
  //   }
  //   return summaryMap;
  // }
  
  // private static void logSlotUpdateErrors(Database.SaveResult[] results, List<AppointmentSlot__c> slots, String methodName) {
  //   for (Integer i = 0; i < results.size(); i++) {
  //     if (!results[i].isSuccess()) {
  //       List<String> errParts = new List<String>();
  //       for (Database.Error err : results[i].getErrors()) {
  //         errParts.add(err.getStatusCode() + ': ' + err.getMessage());
  //       }
  //       ErrorLog.createErrorLogList('ServiceAppointmentTriggerHelper', 'Failed to update AppointmentSlot__c Id=' + slots[i].Id + ': ' + String.join(errParts, '; '), null, methodName, '', 'ERROR');
  //     }
  //   }
  // }
  
  public static void setUUID(List<ServiceAppointment> newList){
    for (ServiceAppointment sa : newList) {
      sa.External_UUID__c = String.valueOf(UUID.randomUUID());
    }
  }
  
  public static void sentToADEO(List<ServiceAppointment> newRecs, List<ServiceAppointment> oldRecs){
    Set<Id> idsToSent = new Set<Id>();
    Boolean hasPermission = false;
    if(runTrigger){
      for (Integer i = 0; i < newRecs.size(); i++) {
        if(oldRecs != null){
          if( newRecs[i].Status != oldRecs[i].Status ||
          newRecs[i].SchedStartTime != oldRecs[i].SchedStartTime){
            idsToSent.add(newRecs[i].Id);
          }
        }
        else{
          idsToSent.add(newRecs[i].Id);
        }
      }
      
      User userInfo = [SELECT (select  Id, PermissionSet.name from PermissionSetAssignments) FROM USER WHERE Id =: UserInfo.getUserId() LIMIT 1];
      for(PermissionSetAssignment psa : userInfo.PermissionSetAssignments){
        if(psa.PermissionSet.Name == 'ACL_Sent_Service_Appointments_to_ADEO'){
          hasPermission = true;
          break;
        }
      }
    }
    if(hasPermission){
      ServiceAppointmentCalloutHandler.builtHttpRequest(idsToSent);
    }
  }
}