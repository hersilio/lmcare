/**
 * @description       : 
 * @author            : Francisco Ribeiro
 * @group             : 
 * @last modified on  : 02-10-2024
 * @last modified by  : Francisco Ribeiro
**/
@isTest
public class test_c_AccountInsertMDM {
	@testSetup
	static void setup() {
		List<Account> accounts = new List<Account>();
		Account SFAccount = new Account();
		SFAccount.FirstName = 'Floress';
		SFAccount.LastName = 'Floress';
		SFAccount.BillingCity = 'SFAccount';
		SFAccount.BillingCountryCode = 'PT';
		SFAccount.BillingPostalCode = '1234-123';
		SFAccount.NIF__c = '123456789';
		SFAccount.PersonEmail = 'Floress@gmail.com';
		SFAccount.Phone = '123456789';
		SFAccounT.Numero_de_Conta__c = '2462';
		
		accounts.add(SFAccount);

		Account SFAccountsecond = new Account();
		SFAccountsecond.FirstName = 'Danielllll';
		SFAccountsecond.LastName = 'Floresss';
		SFAccountsecond.NIF__c = '123456782';
		SFAccountsecond.Numero_de_Conta__c = '867030';
		accounts.add(SFAccountsecond);

		Account SFAccountThird = new Account();
		SFAccountThird.FirstName = 'Floress';
		SFAccountThird.LastName = 'Floress';
		SFAccountThird.NIF__c = '123456783';
		SFAccountThird.PersonEmail = 'Floress@gmail.com';
		accounts.add(SFAccountThird);

		insert accounts;
	}
	
	@isTest
	static void test_getToken() {
		Test.startTest();
		Test.setMock(
			HttpCalloutMock.class,
			new c_PesquisaContaHttpCalloutMock('token')
		);
		c_AccountInsertMDM.getToken();
		Test.stopTest();
	}

	@isTest
	static void test_GetProfissionalRecordTypeId() {
		Test.startTest();
		c_AccountInsertMDM.GetProfissionalRecordTypeId();
		Test.stopTest();
	}
	@isTest
	static void test_getAccountsByIds() {
		List<Id> IdsList = new List<Id>();
		List<Account> ListAccount = [SELECT Id FROM Account];
		for (Account acc : ListAccount) {
			IdsList.add(acc.Id);
		}
		Test.startTest();
		c_AccountInsertMDM.getAccountsByIds(IdsList);
		Test.stopTest();
	}
}