public with sharing class SCH_InvocableSendSMS{

    @InvocableMethod (label='Send SMS (Scheduler)')
    public static void SCH_InvocableSendSMS(List<FlowInput> input) {
        for (FlowInput i: input){
            if (String.isEmpty(i.SMSTo) || i.et == null) {
                System.debug('Failed sending an SMS to ' + i.SMSTo + ' because the SMS To is empty or the Email Template is null');
                continue;
            }

            String SMSFrom = 'LeroyMerlin'; //Pode ser mudado ou até um parâmetro. Por enquanto está fixo
            String SMSTo = i.SMSTo.length() == 9 ? '+351' + i.SMSTo : i.SMSTo; //Precisa incluir o código do país. Ex: +351999999999
            Id parentRecordId = null;
            if (i.sa.parentRecordId.getSobjectType() == Schema.Lead.getSObjectType()) parentRecordId = i.sa.ParentRecordId;
            String SMSBody = Messaging.renderEmailTemplate(parentRecordId, i.sa.Id, new List<String>{i.et.Body})[0].getMergedBody();
            System.enqueueJob(new LM_SendSMS(SMSFrom, SMSTo, SMSBody));
        }
    }

    public class FlowInput{
        @InvocableVariable(label = 'Service Appointment')
        public ServiceAppointment sa;
        @InvocableVariable(label = 'Email Template' description = 'The Email Template to be used for the SMS. Must use Service Appointment fields')
        public EmailTemplate et;
        @InvocableVariable(label = 'SMS To' description = 'Format: +000999999999')
        public String SMSTo; //Precisa incluir o código do país. Ex: +351999999999
    }
}