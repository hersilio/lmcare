trigger SCH_ContentDocumentLinkTrigger on ContentDocumentLink (
    before insert,
    before update,
    after insert
) {
    SCH_ContentDocumentLinkTriggerHandler handler = new SCH_ContentDocumentLinkTriggerHandler();

    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        }
    } else if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            handler.afterInsert(Trigger.new);
        }
    }
}