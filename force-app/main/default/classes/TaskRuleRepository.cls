/**
 * @description       :
 * @author            : Hersilio Belini de Oliveira
 * @group             :
 * @last modified on  : 2026-01-06
 * @last modified by  : Hersilio Belini de Oliveira
**/
public with sharing class TaskRuleRepository {
    private static Map<String, List<TaskRule__mdt>> cacheByKey = new Map<String, List<TaskRule__mdt>>();

    public static List<TaskRule__mdt> getActiveRules(String triggerType, String triggerEvent) {
        if (String.isBlank(triggerType) || String.isBlank(triggerEvent)) {
            if (String.isBlank(triggerType)) {
                return new List<TaskRule__mdt>();
            }
        }

        String normalizedEvent = String.isBlank(triggerEvent) ? 'ALL' : triggerEvent;
        String cacheKey = triggerType + '|' + normalizedEvent;
        if (!cacheByKey.containsKey(cacheKey)) {
            String baseQuery =
                'SELECT Id, DeveloperName, QualifiedApiName, Active__c, TriggerType__c, TriggerEvent__c, ' +
                'Stage__c, DaysInStage__c, TaskSubjectTemplate__c, DueDateBase__c, DueDateOffsetDays__c, ' +
                'AllowMultiple__c, DependencyField__c, DependencyValue__c ' +
                'FROM TaskRule__mdt ' +
                'WHERE Active__c = true AND TriggerType__c = :triggerType';
            if (!String.isBlank(triggerEvent)) {
                baseQuery += ' AND TriggerEvent__c = :triggerEvent';
            }
            cacheByKey.put(cacheKey, Database.query(baseQuery));
        }

        return cacheByKey.get(cacheKey);
    }
}