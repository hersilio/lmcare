/**
 * @description       :
 * @author            : Daniel Flores
 * @group             :
 * @last modified on  : 02-10-2024
 * @last modified by  : Francisco Ribeiro
 **/
@isTest
public with sharing class test_CompareSFAccountsWithMDM {
	@testSetup
	static void setup() {
		List<Account> accounts = new List<Account>();
		Account SFAccount = new Account();
		SFAccount.FirstName = 'Floress';
		SFAccount.LastName = 'Floress';
		SFAccount.BillingCity = 'SFAccount';
		SFAccount.BillingCountryCode = 'PT';
		SFAccount.BillingPostalCode = '1234-123';
		SFAccount.BillingCountry = 'Portugal';
		SFAccount.NIF__c = '123456789';
		SFAccount.PersonEmail = 'Floress@gmail.com';
		SFAccount.Phone = '912345678';
		SFAccounT.Numero_de_Conta__c = '2462';
		SFAccounT.isSynced__c = true;
        SFAccounT.isSyncedTime__c = System.now();
        SFAccounT.UpdateTime__c = String.valueOf(System.now());
		accounts.add(SFAccount);

		Account SFAccountsecond = new Account();
		SFAccountsecond.FirstName = 'Danielllll';
		SFAccountsecond.LastName = 'Floresss';
		SFAccountsecond.NIF__c = '123456782';
		SFAccountsecond.BillingCountry = 'Portugal';
		SFAccountsecond.Numero_de_Conta__c = '867030';
		SFAccountsecond.Phone = '912345678';
		SFAccountsecond.isSynced__c = true;
        SFAccountsecond.isSyncedTime__c = System.now();
        SFAccountsecond.UpdateTime__c = String.valueOf(System.now());
		accounts.add(SFAccountsecond);

		Account SFAccountThird = new Account();
		SFAccountThird.FirstName = 'Floress';
		SFAccountThird.LastName = 'Floress';
		SFAccountThird.NIF__c = '123456783';
		SFAccountThird.BillingCountry = 'Portugal';
		SFAccountThird.Phone = '912345678';
		SFAccountThird.PersonEmail = 'Floress@gmail.com';
		SFAccountThird.isSynced__c = true;
        SFAccountThird.isSyncedTime__c = System.now();
        SFAccountThird.UpdateTime__c = String.valueOf(System.now());
		accounts.add(SFAccountThird);

		insert accounts;
	}

	@isTest
	static void test_AccountUpdateMDM() {
		Id AccountId = [SELECT Id FROM Account LIMIT 1].Id;
		Test.startTest();
		Test.setMock(
			HttpCalloutMock.class,
			new c_PesquisaContaHttpCalloutMock('withAccount')
		);

		CompareSFAccountsWithMDM.CompareAccounts(AccountId);
		Test.stopTest();
	}

	/*
	@isTest
	static void test_InsertAccountMDM() {
		Id AccountId = [SELECT Id FROM Account LIMIT 1].Id;
		Test.startTest();
		Test.setMock(
			HttpCalloutMock.class,
			new c_PesquisaContaHttpCalloutMock('OneAccount')
		);
		CompareSFAccountsWithMDM.InsertAccountMDM(AccountId);
		Test.stopTest();
	}
	*/

	/*
    @isTest
	static void test_InsertAccountMDM2() {
		Id AccountId = [SELECT Id FROM Account LIMIT 1].Id;
		Test.startTest();
		Test.setMock(
			HttpCalloutMock.class,
			new c_PesquisaContaHttpCalloutMock('OneAccount')
		);
		CompareSFAccountsWithMDM.InsertAccountMDM(AccountId);
		Test.stopTest();
	}
	*/
}