/**
 * @description       :
 * @author            : Hersilio Belini de Oliveira
 * @group             :
 * @last modified on  : 2025-09-15
 * @last modified by  : Hersilio Belini de Oliveira
**/
public class AppointmentSlotExpiryScheduler implements Schedulable {

    private static final String JOB_NAME = 'Appointment Slot Expiry';
    private Integer minutesInteval;

    public AppointmentSlotExpiryScheduler(){
    }

    public AppointmentSlotExpiryScheduler(Integer minutesInteval){
        this.minutesInteval = minutesInteval;
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new AppointmentSlotExpiryBatch(), 200);

        rescheduleJob(sc);
    }

    public void rescheduleJob(SchedulableContext sc) {
        if (sc != null) {
            System.abortJob(sc.getTriggerId());
        }

        Datetime nextRunTime = System.now().addMinutes(minutesInteval);
        String cronExpression =
            '' + nextRunTime.second() + ' ' +
            nextRunTime.minute() + ' ' +
            nextRunTime.hour() + ' ' +
            nextRunTime.day() + ' ' +
            nextRunTime.month() + ' ? ' +
            nextRunTime.year();

        System.schedule(
            JOB_NAME + ' - ' + System.now().format(),
            cronExpression,
            new AppointmentSlotExpiryScheduler(minutesInteval)
        );
    }
}