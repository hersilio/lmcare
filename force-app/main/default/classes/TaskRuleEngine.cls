/**
 * @description       :
 * @author            : Hersilio Belini de Oliveira
 * @group             :
 * @last modified on  : 2026-01-06
 * @last modified by  : Hersilio Belini de Oliveira
**/
public with sharing class TaskRuleEngine {
    private static final String KEY_PREFIX = 'TaskRuleKey:';

    public class TaskRuleRequest {
        @InvocableVariable(Required=true)
        public SObject Record;

        @InvocableVariable
        public SObject OldRecord;

        @InvocableVariable(Required=true)
        public String TriggerType;

        @InvocableVariable(Required=true)
        public String TriggerEvent;
    }

    @InvocableMethod(label='Evaluate Task Rules')
    public static void evaluateInvocable(List<TaskRuleRequest> requests) {
        if (requests == null || requests.isEmpty()) {
            return;
        }

        List<SObject> records = new List<SObject>();
        Map<Id, SObject> priorRecords = new Map<Id, SObject>();
        String triggerType;
        String triggerEvent;

        for (TaskRuleRequest request : requests) {
            if (request == null) {
                continue;
            }
            if (triggerEvent == null && !String.isBlank(request.TriggerEvent)) {
                triggerEvent = request.TriggerEvent;
            }
            if (triggerType == null && !String.isBlank(request.TriggerType)) {
                triggerType = request.TriggerType;
            }
            if (request.Record != null) {
                records.add(request.Record);
            }
            if (request.OldRecord != null && request.OldRecord.Id != null) {
                priorRecords.put(request.OldRecord.Id, request.OldRecord);
            }
        }

        evaluate(records, priorRecords, triggerType, triggerEvent);
    }

    public static void evaluate(List<SObject> records, String triggerType, String triggerEvent) {
        evaluate(records, null, triggerType, triggerEvent);
    }

    public static void evaluate(List<SObject> records, Map<Id, SObject> priorRecords, String triggerType, String triggerEvent) {
        if (records == null || records.isEmpty()) {
            return;
        }

        List<TaskRule__mdt> rules = TaskRuleRepository.getActiveRules(triggerType, triggerEvent);
        if (rules.isEmpty()) {
            return;
        }

        Set<Id> recordIds = new Set<Id>();
        for (SObject recordItem : records) {
            if (recordItem != null && recordItem.Id != null) {
                recordIds.add(recordItem.Id);
            }
        }

        Set<String> existingKeys = loadExistingKeys(recordIds);
        List<Task> tasksToInsert = new List<Task>();

        for (SObject recordItem : records) {
            if (recordItem == null || recordItem.Id == null) {
                continue;
            }

            for (TaskRule__mdt rule : rules) {
                SObject priorRecord = priorRecords != null ? priorRecords.get(recordItem.Id) : null;
                if (!appliesToRecord(rule, recordItem, priorRecord)) {
                    continue;
                }

                Date dueDate = TaskDateCalculator.calculate(rule.DueDateBase__c, rule.DueDateOffsetDays__c, recordItem);
                String technicalKey = buildTechnicalKey(rule, recordItem.Id, dueDate);

                if (!rule.AllowMultiple__c && existingKeys.contains(technicalKey)) {
                    continue;
                }

                Task taskItem = new Task();
                taskItem.WhatId = recordItem.Id;
                taskItem.OwnerId = resolveOwnerId(recordItem);
                taskItem.Subject = renderSubject(rule, recordItem);
                taskItem.ActivityDate = dueDate;
                taskItem.Description = technicalKey;

                tasksToInsert.add(taskItem);
                existingKeys.add(technicalKey);
            }
        }

        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }

    private static Boolean appliesToRecord(TaskRule__mdt rule, SObject recordItem, SObject priorRecord) {
        if (rule == null || recordItem == null) {
            return false;
        }

        if (!String.isBlank(rule.Stage__c)) {
            SObject stageSource = recordItem;
            if (rule.TriggerEvent__c == 'OnStageChange' && priorRecord != null) {
                stageSource = priorRecord;
            }
            String stageValue = getFirstFieldValue(stageSource, new List<String>{'StageName', 'Stage__c'});
            if (String.isBlank(stageValue) || stageValue != rule.Stage__c) {
                return false;
            }
        }

        if (rule.DaysInStage__c != null && rule.DaysInStage__c > 0) {
            Date stageChangeDate = TaskDateCalculator.resolveBaseDate('StageChangeDate', recordItem);
            if (stageChangeDate == null) {
                return false;
            }

            Integer daysInStage = stageChangeDate.daysBetween(Date.today());
            if (daysInStage < Integer.valueOf(rule.DaysInStage__c)) {
                return false;
            }
        }

        if (!String.isBlank(rule.DependencyField__c)) {
            if (!hasField(recordItem, rule.DependencyField__c)) {
                return false;
            }

            Object rawValue = recordItem.get(rule.DependencyField__c);
            if (rawValue == null) {
                return false;
            }

            String depValue = String.valueOf(rawValue);
            if (String.isBlank(rule.DependencyValue__c) || depValue != rule.DependencyValue__c) {
                return false;
            }
        }

        return true;
    }

    private static String renderSubject(TaskRule__mdt rule, SObject recordItem) {
        String template = rule != null ? rule.TaskSubjectTemplate__c : null;

        if (String.isBlank(template)) {
            template = rule != null ? rule.DeveloperName : 'Task';
        }

        Pattern tokenPattern = Pattern.compile('\\{([A-Za-z0-9_]+)\\}');
        Matcher matcher = tokenPattern.matcher(template);

        String result = '';
        Integer lastIndex = 0;

        while (matcher.find()) {
            result += template.substring(lastIndex, matcher.start());

            String fieldName = matcher.group(1);
            String replacement = getFieldValueAsString(recordItem, fieldName);

            result += (replacement != null ? replacement : '');

            lastIndex = matcher.end();
        }

        result += template.substring(lastIndex);

        return result;
    }

    private static String getFieldValueAsString(SObject recordItem, String fieldName) {
        if (recordItem == null || String.isBlank(fieldName) || !hasField(recordItem, fieldName)) {
            return null;
        }

        Object value = recordItem.get(fieldName);
        if (value == null) {
            return null;
        }

        if (value instanceof Date) {
            return ((Date) value).format();
        }

        if (value instanceof Datetime) {
            return ((Datetime) value).format();
        }

        return String.valueOf(value);
    }

    private static Id resolveOwnerId(SObject recordItem) {
        if (recordItem != null && hasField(recordItem, 'OwnerId')) {
            Object ownerValue = recordItem.get('OwnerId');
            if (ownerValue instanceof Id) {
                return (Id) ownerValue;
            }
        }

        return UserInfo.getUserId();
    }

    private static Set<String> loadExistingKeys(Set<Id> recordIds) {
        Set<String> keys = new Set<String>();
        if (recordIds == null || recordIds.isEmpty()) {
            return keys;
        }

        List<Task> tasks = [
            SELECT Id, WhatId, Description
            FROM Task
            WHERE WhatId IN :recordIds
        ];

        for (Task taskItem : tasks) {
            String key = extractKey(taskItem.Description);
            if (!String.isBlank(key)) {
                keys.add(key);
            }
        }

        return keys;
    }

    private static String extractKey(String description) {
        if (String.isBlank(description)) {
            return null;
        }

        Integer startIndex = description.indexOf(KEY_PREFIX);
        if (startIndex < 0) {
            return null;
        }

        Integer endIndex = description.indexOf('\n', startIndex);
        if (endIndex < 0) {
            endIndex = description.length();
        }

        return description.substring(startIndex, endIndex).trim();
    }

    private static String buildTechnicalKey(TaskRule__mdt rule, Id recordId, Date dueDate) {
        String ruleKey = rule != null && !String.isBlank(rule.QualifiedApiName)
            ? rule.QualifiedApiName
            : (rule != null ? rule.DeveloperName : 'UnknownRule');
        String dueValue = dueDate == null ? 'NoDueDate' : String.valueOf(dueDate);
        return KEY_PREFIX + ruleKey + ':' + String.valueOf(recordId) + ':' + dueValue;
    }

    private static String getFirstFieldValue(SObject recordItem, List<String> fieldNames) {
        for (String fieldName : fieldNames) {
            if (hasField(recordItem, fieldName)) {
                Object value = recordItem.get(fieldName);
                if (value != null) {
                    return String.valueOf(value);
                }
            }
        }
        return null;
    }

    private static Boolean hasField(SObject recordItem, String fieldName) {
        return recordItem.getSObjectType().getDescribe().fields.getMap().containsKey(fieldName);
    }
}