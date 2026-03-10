@isTest
public with sharing class InvocableGDriveSaveTest {
    
//     @TestSetup
//     static void makeData(){
//         // Get the Person Account record type ID (You may need to adjust this)
//         Id personAccountRecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Person Account' LIMIT 1].Id;
        
//         // Create a new Person Account record
//         Account testPersonAccount = new Account(
//             RecordTypeId = personAccountRecordTypeId, // Set the Person Account record type
//             FirstName = 'John',         
//             LastName = 'Doe',          
//             E_Mail_Empresa__c = 'johndoe@example.com', 
//             PersonBirthdate = Date.newInstance(1990, 1, 1), 
//             Phone = '999999999'
//         );
        
//         // Insert the Person Account record
//         insert testPersonAccount;
        
//         Id pbId = Test.getStandardPricebookId();
//         RecordType recType = [SELECT Id FROM RecordType WHERE DeveloperName = 'LM_Aluguer_Ferramentas'];
        
//         Order testOrder = new Order(
//             AccountId = testPersonAccount.Id,
//             EffectiveDate = Date.today(),
//             Status = 'Rascunho',
//             Description = 'Test Order',
//             Name = '12345',
//             Pricebook2Id = pbId,
//             RecordTypeId = recType.Id
//         );
//         insert testOrder;
//     }

//     @isTest
//     public static void testSaveFileToGDrive() {
//         LM_InvocableGDriveSave.FlowInput input = new LM_InvocableGDriveSave.FlowInput();
//         LM_Autocrat_Process_Setting__mdt mdt = [SELECT Id, SMS_From__c, Attachment_Name__c, Email_Attachment_Template__c, Token_Template_Name__c FROM LM_Autocrat_Process_Setting__mdt WHERE DeveloperName = 'Aluguer_Ferramentas'];

//         input.mdt = mdt;
//         input.order = [SELECT Id, AccountId, OrderNumber, EffectiveDate, Status, Description,Name, Pricebook2Id, Record_Type_API_Name__c FROM Order Where Name = '12345'];

//         LM_InvocableGDriveSave.saveFileToGDrive(new List<LM_InvocableGDriveSave.FlowInput>{input});
//         System.assert(true, 'No exceptions were thrown');
//     }
}