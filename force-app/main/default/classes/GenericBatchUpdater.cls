/**
 * @description       :
 * @author            : Hersilio Belini de Oliveira
 * @group             :
 * @last modified on  : 2025-07-29
 * @last modified by  : Hersilio Belini de Oliveira
**/
public abstract class GenericBatchUpdater implements Database.Batchable<SObject> {

    protected String query;

    public GenericBatchUpdater(String query) {
        this.query = query;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<SObject> toUpdate = new List<SObject>();

        for (SObject record : scope) {
            if (shouldUpdate(record)) {
                updateRecord(record);
                toUpdate.add(record);
            }
        }

        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Batch finalizado com sucesso.');
    }

    public abstract void updateRecord(SObject record);

    public virtual Boolean shouldUpdate(SObject record) {
        return true;
    }
}