/**
 * @description       :
 * @author            : Hersilio Belini de Oliveira
 * @group             :
 * @last modified on  : 2025-11-06
 * @last modified by  : Hersilio Belini de Oliveira
**/
public with sharing class IntegrationValueMapper {
    private static Map<String, String> cache;

    private static String key(String objectApi, String fieldApi, String extId) {
        return objectApi + '.' + fieldApi + '|' + extId;
    }

    private static void ensureLoaded() {
        if (cache != null) return;
        cache = new Map<String, String>();

        for (IntegrationValueMap__c m : [
            SELECT ObjectApiName__c, FieldApiName__c, ExternalId__c, TargetValue__c, IsActive__c
            FROM IntegrationValueMap__c
            WHERE IsActive__c = true
        ]) {
            cache.put(key(m.ObjectApiName__c, m.FieldApiName__c, m.ExternalId__c), m.TargetValue__c);
        }
    }

    public static String mapFunc(String objectApi, String fieldApi, String externalId) {
        if (String.isBlank(externalId)) return null;
        ensureLoaded();
        return cache.get(key(objectApi, fieldApi, externalId));
    }
}