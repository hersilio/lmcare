/**
 * @description       :
 * @author            : Hersilio Belini de Oliveira
 * @group             :
 * @last modified on  : 2026-01-06
 * @last modified by  : Hersilio Belini de Oliveira
**/
public with sharing class TaskDateCalculator {
    public static Date calculate(String dueDateBase, Decimal offsetDays, SObject record) {
        Integer offset = offsetDays == null ? null : offsetDays.intValue();
        return calculate(dueDateBase, offset, record);
    }

    public static Date calculate(String dueDateBase, Integer offsetDays, SObject record) {
        if (record == null || String.isBlank(dueDateBase)) {
            return null;
        }

        Date baseDate = resolveBaseDate(dueDateBase, record);
        if (baseDate == null) {
            return null;
        }

        Integer offset = offsetDays == null ? 0 : offsetDays;
        return baseDate.addDays(offset);
    }

    public static Date resolveBaseDate(String dueDateBase, SObject record) {
        if (record == null || String.isBlank(dueDateBase)) {
            return null;
        }

        if (dueDateBase == 'CreatedDate') {
            return getDateFromField(record, 'CreatedDate');
        }

        if (dueDateBase == 'StageChangeDate') {
            return getDateFromFirstExistingField(record, new List<String>{
                'LastStageChangeDate'
            });
        }

        if (dueDateBase == 'OrderCreatedDate') {
            return getDateFromFirstExistingField(record, new List<String>{
                'OrderCreatedDate__c',
                'CreatedDate'
            });
        }

        if (dueDateBase == 'OrderClosedDate') {
            return getDateFromFirstExistingField(record, new List<String>{
                'OrderClosedDate__c',
                'ClosedDate__c',
                'EndDate',
                'ActivatedDate'
            });
        }

        return null;
    }

    private static Date getDateFromFirstExistingField(SObject record, List<String> fieldNames) {
        for (String fieldName : fieldNames) {
            if (hasField(record, fieldName)) {
                Date value = getDateFromField(record, fieldName);
                if (value != null) {
                    return value;
                }
            }
        }

        return null;
    }

    private static Date getDateFromField(SObject record, String fieldName) {
        if (!hasField(record, fieldName)) {
            return null;
        }

        Object rawValue = record.get(fieldName);
        if (rawValue == null) {
            return null;
        }

        if (rawValue instanceof Date) {
            return (Date) rawValue;
        }

        if (rawValue instanceof Datetime) {
            return ((Datetime) rawValue).date();
        }

        return null;
    }

    private static Boolean hasField(SObject record, String fieldName) {
        return record.getSObjectType().getDescribe().fields.getMap().containsKey(fieldName);
    }
}