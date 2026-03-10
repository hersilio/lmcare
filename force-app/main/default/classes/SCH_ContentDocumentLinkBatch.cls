global with sharing class SCH_ContentDocumentLinkBatch
    implements Database.Batchable<SObject>, Database.Stateful {

    global Integer totalUpdated = 0;

    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id
            FROM Order
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Order> scope) {

        Set<Id> orderIds = new Set<Id>();
        for (Order o : scope) {
            orderIds.add(o.Id);
        }

        if (orderIds.isEmpty()) return;

        List<ContentDocumentLink> links = [
            SELECT Id, Visibility, ShareType, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :orderIds
            AND Visibility != 'AllUsers'
        ];

        if (links.isEmpty()) return;

        List<ContentDocumentLink> updates = new List<ContentDocumentLink>();

        for (ContentDocumentLink cdl : links) {
            Boolean changed = false;

            if (cdl.Visibility != 'AllUsers') {
                cdl.Visibility = 'AllUsers';
                changed = true;
            }

            if (cdl.ShareType == null || cdl.ShareType == 'I') {
                cdl.ShareType = 'V';
                changed = true;
            }

            if (changed) {
                updates.add(cdl);
            }
        }

        if (!updates.isEmpty()) {
            update updates;
            totalUpdated += updates.size();
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('SCH_FixOrderContentDocumentVisibilityBatch finished.');
        System.debug('Total ContentDocumentLinks updated: ' + totalUpdated);
    }
}