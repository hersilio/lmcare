/**
 * @description       : Appointment Slot Queueable
 * @author            : Hersilio Belini de Oliveira
 * @last modified on  : 2025-09-01
 * @last modified by  : Hersilio Belini de Oliveira
**/
public class AppointmentSlotQueueable implements Queueable, Database.AllowsCallouts {

    private List<Map<String, String>> allResourceToExecute;
    private Map<String, AppointmentSlotSummary__c> appSlotSummaryMap;
    private Integer offset;
    private Integer batchSize;

    /**
    * @description Constructor
    * @author Hersilio Belini de Oliveira | 2025-05-12
    * @param resourceId
    * @param workTypeId
    * @param startDay
    * @param endDay
    **/
    public AppointmentSlotQueueable(List<Map<String, String>> allResourceToExecute, Map<String, AppointmentSlotSummary__c> appSlotSummaryMap) {
        this.allResourceToExecute = allResourceToExecute;
        this.appSlotSummaryMap = appSlotSummaryMap;
    }

    /**
    * @description Execute Queue
    * @author Hersilio Belini de Oliveira | 2025-05-12
    * @param context
    **/
    public void execute(QueueableContext context) {

        // Integer endIndex = Math.min(this.offset + batchSize, this.allResourceToExecute.size());

        // List<Map<String, String>> slice = new List<Map<String, String>>();
        // for (Integer i = this.offset; i < endIndex; i++) {
        //     slice.add(this.allResourceToExecute[i]);
        // }

        // System.debug('Slice of resources to process: ' + slice.size() + ' from index ' + this.offset + ' to ' + endIndex);

        // AppointmentSlotService.createNextAppointmentSlots(this.allResourceToExecute, this.appSlotSummaryMap);

        // if (endIndex < this.allResourceToExecute.size()) {
        //     System.enqueueJob(new AppointmentSlotQueueable(this.allResourceToExecute, this.appSlotSummaryMap, endIndex, batchSize));
        // }
    }
}