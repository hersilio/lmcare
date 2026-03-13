public class SCH_Send_Appointment_SMS {
	
    @InvocableMethod(label='SCH Send SMS' description='Takes a Service Appointment, an Email Template and a Receiver (Contact or Lead) to send an SMS.')
    static public void sendSMS(List<FlowInput> inputs){
        for (FlowInput input: inputs){
            String senderName = 'LeroyMerlin';
            String SMSFrom = senderName;
            
            String SMSTo;
            if (input.receiver.getSObjectType() == Contact.sObjectType){
                 Contact receiver = (Contact)input.receiver;
                 SMSTo = '+351'+receiver.Phone;
            }
            else if (input.receiver.getSObjectType() == Lead.sObjectType){
                Lead receiver = (Lead)input.receiver;
                SMSTo = '+351'+receiver.Phone;
            }
            
            String SMSBody = Messaging.renderEmailTemplate(input.receiver.Id, input.sa.Id, new List<String>{input.et.Body})[0].getMergedBody();
            System.enqueueJob(new LM_SendSMS(SMSFrom, SMSTo, SMSBody));
        }
    }
    
    public class FlowInput{
		@InvocableVariable (Label='Service Appointment')
        public ServiceAppointment sa;
        
        @InvocableVariable (Label='Email Template')
		public EmailTemplate et;

        @InvocableVariable (Label='Receiver')
        public SObject receiver;
    }
}