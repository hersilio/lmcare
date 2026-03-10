public without sharing class LM_Invocable_Send_Token {
   
    @InvocableMethod(label='Send SMS')
    public static void sendToken(List<FlowInput> input){
        for (FlowInput i: input){
            Order order = i.order;
            LM_Autocrat_Process_Setting__mdt mdt = i.metadata;   
            EmailTemplate et = i.emailTemplate;
            
            Account acc = [SELECT Id, Phone from Account WHERE Id =: order.AccountId];
            
            String SMSFrom = mdt.SMS_From__c;
            String SMSTo = acc.Phone.contains('+351') ? acc.Phone : '+351' + acc.Phone;
            String SMSBody = Messaging.renderEmailTemplate(null, order.Id, new List<String>{et.Body})[0].getMergedBody();
            
            if (Test.isRunningTest()){
                return;
            }
            System.enqueueJob(new LM_SendSMS(SMSFrom, SMSTo, SMSBody));   
        }
    }

    public class FlowInput{

        @InvocableVariable
        public Order order;
        @InvocableVariable
        public LM_Autocrat_Process_Setting__mdt metadata;
        @InvocableVariable
        public EmailTemplate emailTemplate;

    }
}