public without sharing class LM_GDriveUrlController {

    @auraEnabled
    public static LM_GDrive_File_Link__c createUrl(String filename, String url, String orderId, String fileId){
        LM_GDrive_File_Link__c link = new LM_GDrive_File_Link__c();
        link.File_Name__c = filename;
        link.File_Url__c = url;
        link.Order__c = orderId;
        link.fileId__c = fileId;
        
        insert link;
        return link;
    }
    
    public static String getStoreFolderName(String orderId){
        List<Order> order = [SELECT Id, Store__c FROM Order WHERE Id = :orderId LIMIT 1];
        List<LM_Store__c> store = [SELECT Id, Store_API_Name__c, GDrive_Folder__c from LM_Store__c WHERE Id = :order[0].Store__c LIMIT 1];
        return store[0].GDrive_Folder__c;
    }
    
    public static String getProcessFolderName(String orderRecordType){
        System.Debug('orderRecordType: ' + orderRecordType);
        List<LM_Autocrat_Process_Setting__mdt> mdt = [SELECT Id, Order_Record_Type__c, GDrive_Process_Folder_Name__c FROM LM_Autocrat_Process_Setting__mdt WHERE Order_Record_Type__c =: orderRecordType];
        return mdt[0].GDrive_Process_Folder_Name__c;
    }
    
    //returns Store Folder Name from userId
    @auraEnabled
    public static String getGDriveFolderId(Id orderId, String orderRecordType){
        String storeFolderName = getStoreFolderName(orderId);
        String processFolderName = getProcessFolderName(orderRecordType);
        String result = LM_GoogleDriveAPIController.getGDriveFolderId(processFolderName, storeFolderName);
        if (String.isEmpty(result)) return null;     
        return result;
    }
}