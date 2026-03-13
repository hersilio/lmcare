/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Creates initial test data in Development Environment for LMCare
*
* This class will create:
* Test Accounts (Clients, both Person Accounts and Enterprise Accounts), Suppliers, Installers,
* Transporters, RE Partners 
* 
* Test Products, Test Inventory, Test Stores, etc
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Felipe Gil   <felipe.gil@techremotehub.com>
* @maintainedBy   Felipe Gil   <felipe.gil@techremotehub.com>
* @version        1.0
* @created        2024-09-10
* @modified       YYYY-MM-DD
* @systemLayer    Utility 
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
* vX.X            user@email.com
* YYYY-MM-DD      Explanation of the change.  Multiple lines can be used to explain the change, but
*                 each line should be indented till left aligned with the previous description text.
*
* vX.X            user@email.com
* YYYY-MM-DD      Each change to this file should be documented by incrementing the version number,
*                 and adding a new entry to this @changes list. Note that there is a single blank
*                 line between each @changes entry.
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/

public without sharing class LM_SandboxInitializer {

    Map<String,Schema.RecordTypeInfo> accountRecordTypes = Account.getSObjectType().getDescribe().getRecordTypeInfosByDeveloperName();
    List<String> productFamilies = new List<String>();

    public LM_SandboxInitializer() {
        //Populate product families values;
        for( Schema.PicklistEntry pickListVal : Product2.Family__c.getDescribe().getPicklistValues()){
            productFamilies.add(pickListVal.getLabel());
        }

        if (Test.isRunningTest()){
            return;
        }

        createTestPersonAccounts(10);
        createTestEnterpriseAccounts(10);
        createTestInstallers();
        createTestSuppliers();
        createTestREPartners();
        createTestProducts();
        createTestInventory();
        createTestStores();
    }

	public void createTestPersonAccounts(Integer numClients){
        //Input error handling
        if (numClients<=0){
            throw new IllegalArgumentException('numClients must be a positive Integer.');
        }
        //Account creation
        List<Account> accountsToCreate = new List<Account>();
        Boolean allOrNothing = true; 
        for (Integer i = 0; i < numClients; i++) {
            Account a = new Account();
            a.FirstName = 'Test';
            a.LastName = 'Account' + String.valueOf(i);
            a.E_Mail_Empresa__c = 'testemail'+String.valueOf(i)+'@email.com';
            a.Phone = ('999999999'+String.valueOf(i)).right(9);
            a.NIF__c = ('9999999999'+String.valueOf(i)).right(9);
            a.RecordTypeId = accountRecordTypes.get('PersonAccount').getRecordTypeId();
            accountsToCreate.add(a);
        }

        try{
            Database.insert(accountsToCreate, allOrNothing);
        }catch(DmlException error){
            throw error;
        }
	} 
    public void createTestEnterpriseAccounts(Integer numEnterpriseAccs){
	} 

	public void createTestInstallers(){
	} 

	public void createTestSuppliers(){
	} 

	public void createTestREPartners(){
	} 

	public void createTestProducts(){

	} 

	public void createTestInventory(){
	} 

	public void createTestStores(){
	} 

	
}