public without sharing class LM_InvocableRemoveGDriveFile {
    @InvocableMethod(label='Remove GDrive File')
    public static void removeGDriveFile(List<FlowInput> input){
        for(FlowInput i:input){
            if (String.isEmpty(i.fileId)) return;
            if (Test.isRunningTest()){
                return;
            }
            System.enqueueJob(new qRemoveGDriveFile(i.fileId));
        }
    }
    
    public class qRemoveGDriveFile implements Queueable, Database.AllowsCallouts {
        
        public String fileId;
        
        public qRemoveGDriveFile(String fId){
            this.fileId = fId;
        }
        
        public void execute(QueueableContext context){
            if(Test.isRunningTest()) return;

            LM_GoogleDriveAPIController.removeFile(this.fileId);
        }
        
    }
    
    public class FlowInput{
        @InvocableVariable
        public String fileId;
    }
}