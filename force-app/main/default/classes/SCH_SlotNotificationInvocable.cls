/**
 * @description Invocable action for sending slot availability notification emails
 *              with per-territory+worktype deduplication and aggregate validation.
 *              Called from the SCH_SlotSummary_Territory_Notification flow.
 *
 *              Before sending, counts DISTINCT available slots (by ServiceResource +
 *              StartTime) across ALL summaries for the same Territory + WorkType.
 *              This deduplicates across EngagementChannelTypes — the same resource at
 *              the same time in Presencial and À Distância counts as 1 physical slot.
 *              Notifies when: today is 0-2 AND store is within operating hours,
 *              OR tomorrow is 0-2. Today = 0 outside operating hours is not an alert
 *              (store day simply ended), but today = 0 within hours means all slots booked.
 *
 *              Uses a static Set for per-transaction deduplication to prevent
 *              duplicate emails when multiple summaries trigger the flow simultaneously.
 * @author Ricardo Simoes
 * @last modified on 2026-02-26
 */
public with sharing class SCH_SlotNotificationInvocable {
  @TestVisible
  private static Set<String> notifiedKeys = new Set<String>();

  public class NotificationRequest {
    @InvocableVariable(label='Territory Id' required=true)
    public Id territoryId;

    @InvocableVariable(label='Work Type Id' required=true)
    public Id workTypeId;
  }

  @InvocableMethod(
    label='Send Slot Notification Email'
    description='Sends territory slot availability notification emails with aggregate validation and deduplication'
  )
  public static void sendNotifications(List<NotificationRequest> requests) {
    if (requests == null || requests.isEmpty()) {
      return;
    }

    // 1. Collect unique territory+worktype combinations not yet notified
    Set<Id> territoryIds = new Set<Id>();
    Set<Id> workTypeIds = new Set<Id>();
    Map<String, NotificationRequest> requestByKey = new Map<String, NotificationRequest>();

    for (NotificationRequest req : requests) {
      if (req.territoryId == null || req.workTypeId == null) {
        continue;
      }

      String key =
        String.valueOf(req.territoryId) +
        '|' +
        String.valueOf(req.workTypeId);
      if (notifiedKeys.contains(key)) {
        continue;
      }

      if (!requestByKey.containsKey(key)) {
        territoryIds.add(req.territoryId);
        workTypeIds.add(req.workTypeId);
        requestByKey.put(key, req);
      }
    }

    if (requestByKey.isEmpty()) {
      return;
    }

    // 2. Query available slots and deduplicate across channels in Apex.
    //    Same resource at same time may appear in multiple summaries for
    //    different EngagementChannelTypes but represents a single physical slot.
    //    We use a Set keyed by territory|worktype|resource|startTime to deduplicate.
    Map<String, Decimal> aggregateSlotsToday = new Map<String, Decimal>();
    Map<String, Decimal> aggregateSlotsTomorrow = new Map<String, Decimal>();
    Set<String> countedSlots = new Set<String>();

    for (AppointmentSlot__c slot : [
      SELECT
        AppointmentSlotSummary__r.ServiceTerritory__c,
        AppointmentSlotSummary__r.WorkType__c,
        ServiceResource__c,
        StartTime__c,
        IsToday__c,
        IsTomorrow__c
      FROM AppointmentSlot__c
      WHERE
        Available__c = TRUE
        AND (IsToday__c = TRUE
        OR IsTomorrow__c = TRUE)
        AND AppointmentSlotSummary__r.ServiceTerritory__c IN :territoryIds
        AND AppointmentSlotSummary__r.WorkType__c IN :workTypeIds
    ]) {
      String key =
        String.valueOf(slot.AppointmentSlotSummary__r.ServiceTerritory__c) +
        '|' +
        String.valueOf(slot.AppointmentSlotSummary__r.WorkType__c);
      String dedupKey =
        key +
        '|' +
        slot.ServiceResource__c +
        '|' +
        String.valueOf(slot.StartTime__c);

      if (slot.IsToday__c && countedSlots.add(dedupKey + '|T')) {
        Decimal current = aggregateSlotsToday.containsKey(key)
          ? aggregateSlotsToday.get(key)
          : 0;
        aggregateSlotsToday.put(key, current + 1);
      }
      if (slot.IsTomorrow__c && countedSlots.add(dedupKey + '|M')) {
        Decimal current = aggregateSlotsTomorrow.containsKey(key)
          ? aggregateSlotsTomorrow.get(key)
          : 0;
        aggregateSlotsTomorrow.put(key, current + 1);
      }
    }

    // 3. Filter: only notify during operating hours (today <= 2 OR tomorrow <= 2)
    //    No alerts outside operating hours — staff cannot act on them, and batch
    //    jobs running at midnight would otherwise trigger false 0-slot alerts.
    Map<Id, Boolean> withinHoursMap = buildWithinHoursMap(territoryIds);
    Map<String, NotificationRequest> validRequests = new Map<String, NotificationRequest>();
    for (String key : requestByKey.keySet()) {
      NotificationRequest req = requestByKey.get(key);
      if (withinHoursMap.get(req.territoryId) != true) {
        continue; // outside operating hours — skip entirely
      }
      Decimal todayCount = aggregateSlotsToday.containsKey(key)
        ? aggregateSlotsToday.get(key)
        : 0;
      Decimal tomorrowCount = aggregateSlotsTomorrow.containsKey(key)
        ? aggregateSlotsTomorrow.get(key)
        : 0;
      if (todayCount <= 2 || tomorrowCount <= 2) {
        validRequests.put(key, req);
      }
    }

    if (validRequests.isEmpty()) {
      return;
    }

    // 4. Collect territory IDs and workType IDs that passed validation
    Set<Id> validTerritoryIds = new Set<Id>();
    Set<Id> validWorkTypeIds = new Set<Id>();
    for (NotificationRequest req : validRequests.values()) {
      validTerritoryIds.add(req.territoryId);
      validWorkTypeIds.add(req.workTypeId);
    }

    // 4b. Query WorkType names
    Map<Id, String> workTypeNames = new Map<Id, String>();
    for (WorkType wt : [
      SELECT Id, Name
      FROM WorkType
      WHERE Id IN :validWorkTypeIds
    ]) {
      workTypeNames.put(wt.Id, wt.Name);
    }

    // 5. Query active notification emails and territory names
    Map<Id, List<String>> emailsByTerritory = new Map<Id, List<String>>();
    Map<Id, String> territoryNames = new Map<Id, String>();

    for (Territory_Notification_Email__c tne : [
      SELECT ServiceTerritory__c, ServiceTerritory__r.Name, Email__c
      FROM Territory_Notification_Email__c
      WHERE ServiceTerritory__c IN :validTerritoryIds AND IsActive__c = TRUE
    ]) {
      if (!emailsByTerritory.containsKey(tne.ServiceTerritory__c)) {
        emailsByTerritory.put(tne.ServiceTerritory__c, new List<String>());
        territoryNames.put(
          tne.ServiceTerritory__c,
          tne.ServiceTerritory__r.Name
        );
      }
      emailsByTerritory.get(tne.ServiceTerritory__c).add(tne.Email__c);
    }

    if (emailsByTerritory.isEmpty()) {
      return;
    }

    // 6. Query OrgWideEmailAddress
    List<OrgWideEmailAddress> owea = [
      SELECT Id
      FROM OrgWideEmailAddress
      WHERE Address = 'lmcare@leroymerlin.pt'
      LIMIT 1
    ];
    Id oweaId = owea.isEmpty() ? null : owea[0].Id;

    // 7. Build and send emails — one per territory+worktype
    List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

    for (String key : validRequests.keySet()) {
      NotificationRequest req = validRequests.get(key);
      List<String> addresses = emailsByTerritory.get(req.territoryId);
      if (addresses == null || addresses.isEmpty()) {
        continue;
      }

      String territoryName = territoryNames.get(req.territoryId);
      String workTypeName = workTypeNames.get(req.workTypeId);
      Decimal todayCount = aggregateSlotsToday.containsKey(key)
        ? aggregateSlotsToday.get(key)
        : 0;
      Decimal tomorrowCount = aggregateSlotsTomorrow.containsKey(key)
        ? aggregateSlotsTomorrow.get(key)
        : 0;

      Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
      email.setToAddresses(addresses);
      if (oweaId != null) {
        email.setOrgWideEmailAddressId(oweaId);
      }
      email.setSubject(
        'Alerta Slots Disponíveis - ' + territoryName + ' - ' + workTypeName
      );
      email.setHtmlBody(
        buildEmailBody(territoryName, workTypeName, todayCount, tomorrowCount)
      );
      email.setSaveAsActivity(false);
      emails.add(email);

      // Mark as notified for this transaction
      notifiedKeys.add(key);
    }

    if (!emails.isEmpty()) {
      Messaging.SendEmailResult[] results = Messaging.sendEmail(emails, false);
      logEmailErrors(results);
    }
  }

  @TestVisible
  private static String buildEmailBody(
    String territoryName,
    String workTypeName,
    Decimal todayCount,
    Decimal tomorrowCount
  ) {
    String todayText = formatSlotCount(todayCount);
    String tomorrowText = formatSlotCount(tomorrowCount);

    return '<p>Olá,</p><p><br></p>' +
      '<p>Este email serve para informar sobre a disponibilidade de slots da loja <strong>' +
      territoryName +
      '</strong> para o serviço <strong>' +
      workTypeName +
      '</strong>:</p>' +
      '<ul>' +
      '<li>Hoje: <strong>' +
      todayText +
      '</strong></li>' +
      '<li>Amanhã: <strong>' +
      tomorrowText +
      '</strong></li>' +
      '</ul>' +
      '<p><br></p><p>Cumprimentos,<br/>LM CARE Scheduler</p>';
  }

  @TestVisible
  private static String formatSlotCount(Decimal count) {
    if (count == null || count == 0) {
      return 'Sem slots disponíveis';
    }
    Integer c = count.intValue();
    return c == 1 ? '1 Slot disponível' : c + ' Slots disponíveis';
  }

  @TestVisible
  private static Map<Id, Boolean> buildWithinHoursMap(Set<Id> territoryIds) {
    Map<Id, Boolean> result = new Map<Id, Boolean>();
    Map<Id, Id> ohIdByTerritory = new Map<Id, Id>();
    Map<Id, String> tzByOhId = new Map<Id, String>();

    for (ServiceTerritory st : [
      SELECT Id, OperatingHoursId, OperatingHours.TimeZone
      FROM ServiceTerritory
      WHERE Id IN :territoryIds
    ]) {
      result.put(st.Id, true); // default: within hours
      if (st.OperatingHoursId != null) {
        ohIdByTerritory.put(st.Id, st.OperatingHoursId);
        tzByOhId.put(st.OperatingHoursId, st.OperatingHours.TimeZone);
      }
    }

    if (ohIdByTerritory.isEmpty()) {
      return result;
    }

    Map<Id, List<TimeSlot>> tsByOhId = new Map<Id, List<TimeSlot>>();
    for (TimeSlot ts : [
      SELECT OperatingHoursId, DayOfWeek, StartTime, EndTime
      FROM TimeSlot
      WHERE OperatingHoursId IN :tzByOhId.keySet()
    ]) {
      if (!tsByOhId.containsKey(ts.OperatingHoursId)) {
        tsByOhId.put(ts.OperatingHoursId, new List<TimeSlot>());
      }
      tsByOhId.get(ts.OperatingHoursId).add(ts);
    }

    DateTime nowUtc = DateTime.now();
    Date mondayRef = Date.newInstance(2024, 1, 1); // known Monday
    String[] dayNames = new List<String>{
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    };

    for (Id territoryId : ohIdByTerritory.keySet()) {
      Id ohId = ohIdByTerritory.get(territoryId);
      String tzName = tzByOhId.get(ohId);
      if (String.isBlank(tzName)) {
        tzName = 'Europe/Lisbon';
      }

      Integer hour = Integer.valueOf(nowUtc.format('H', tzName));
      Integer minute = Integer.valueOf(nowUtc.format('m', tzName));
      Integer second = Integer.valueOf(nowUtc.format('s', tzName));
      Time localTime = Time.newInstance(hour, minute, second, 0);

      String localDateStr = nowUtc.format('yyyy-MM-dd', tzName);
      Date localDate = Date.valueOf(localDateStr);
      Integer dayOffset = Math.mod(
        Math.mod(mondayRef.daysBetween(localDate), 7) + 7,
        7
      );
      String localDayOfWeek = dayNames[dayOffset];

      List<TimeSlot> slots = tsByOhId.get(ohId);
      if (slots == null || slots.isEmpty()) {
        result.put(territoryId, true); // no slots configured → assume within hours
        continue;
      }

      Boolean withinHours = false;
      for (TimeSlot ts : slots) {
        if (
          ts.DayOfWeek == localDayOfWeek &&
          localTime >= ts.StartTime &&
          localTime < ts.EndTime
        ) {
          withinHours = true;
          break;
        }
      }
      result.put(territoryId, withinHours);
    }

    return result;
  }

  private static void logEmailErrors(Messaging.SendEmailResult[] results) {
    for (Messaging.SendEmailResult result : results) {
      if (!result.isSuccess()) {
        for (Messaging.SendEmailError err : result.getErrors()) {
          ErrorLog.createErrorLogList(
            'SCH_SlotNotificationInvocable',
            err.getMessage(),
            null,
            'sendNotifications',
            '',
            'EMAIL_ERROR'
          );
        }
      }
    }
  }
}