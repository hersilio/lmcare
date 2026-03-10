/**
 * @description       :
 * @author            : Daniel Flores
 * @group             :
 * @last modified on  : 28-10-2024
 * @last modified by  : João Rosa
 **/
@isTest
public  class test_c_PesquisaConta {
	@testSetup
	static void setup() {
        Test.setMock(HttpCalloutMock.class, new c_PesquisaContaHttpCalloutMock('withAccount'));
		Test.startTest();
        
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
        
        Test.stopTest();
	}

	@isTest
	static void testGetAccountsMdm() {
        Test.setMock(HttpCalloutMock.class, new c_PesquisaContaHttpCalloutMock('withAccount1'));
		Test.startTest();

		c_PesquisaConta.getAccountsMdm(new String[]{'123456789'}, 'Telemóvel');

        Test.stopTest();
	}

	@isTest
	static void testGetAccountsSF() {
		Test.startTest();

		// c_PesquisaConta.getAccountsSF(new String[]{'teste', 'teste'}, 'Nome da Empresa');
		// c_PesquisaConta.getAccountsSF(new String[]{'teste', 'teste'}, 'Primeiro Nome');
		// c_PesquisaConta.getAccountsSF(new String[]{'teste', null}, 'Primeiro Nome');
		// c_PesquisaConta.getAccountsSF(new String[]{null, 'teste'}, 'Primeiro Nome');
		c_PesquisaConta.getAccountsSF(new String[]{'1234566782'}, 'Telemóvel');
		c_PesquisaConta.getAccountsSF(new String[]{'123456789'}, 'NIF');
		c_PesquisaConta.getAccountsSF(new String[]{'1234566789'}, 'Email');
		c_PesquisaConta.getAccountsSF(new String[]{'1234566789'}, 'Nº de Cliente');

        Test.stopTest();
	}

	@isTest
	static void testGetAccountsMDMNoAccounts() {
		Test.setMock(HttpCalloutMock.class, new c_PesquisaContaHttpCalloutMock('noAccount'));
		Test.startTest();
        
		// c_PesquisaConta.getAccountsMdm(new String[]{'teste', 'teste'}, 'Nome da Empresa');
		// c_PesquisaConta.getAccountsMdm(new String[]{'teste', 'teste'}, 'Primeiro Nome');
		c_PesquisaConta.getAccountsMdm(new String[]{'1234566782'}, 'Telemóvel');
		c_PesquisaConta.getAccountsMdm(new String[]{'123456789'}, 'NIF');
		c_PesquisaConta.getAccountsMdm(new String[]{'1234566789'}, 'Email');
		c_PesquisaConta.getAccountsMdm(new String[]{'1234566789'}, 'Nº de Cliente');
        
        Test.stopTest();
	}

	@isTest
	static void testGetAccountSF() {
		String tipo = 'Floress';
		String email = 'Floress';
        
        Test.setMock(HttpCalloutMock.class, new c_PesquisaContaHttpCalloutMock('withAccount2'));
		Test.startTest();
		c_PesquisaConta.getAccountSF('867030');
		Test.stopTest();
	}

	@isTest
	static void testUpsertAccountSF() {
		String tipo = 'Floress';
		String email = 'Floress';
        
        Test.setMock(HttpCalloutMock.class, new c_PesquisaContaHttpCalloutMock('withAccount1'));
		Test.startTest();
		c_PesquisaConta.upsertAccountSF((Object)c_PesquisaConta.getAccountsMdm(new String[]{'123456789'}, 'NIF')[0], false);
		Test.stopTest();
	}

	@isTest
	static void testUpsertAccountSF2() {
		String tipo = 'Floress';
		String email = 'Floress';
        
        Test.setMock(HttpCalloutMock.class, new c_PesquisaContaHttpCalloutMock('withAccount2'));
		Test.startTest();
		c_PesquisaConta.upsertAccountSF((Object)c_PesquisaConta.getAccountsMdm(new String[]{'123456789'}, 'NIF')[0], true);
		Test.stopTest();
	}

	/*
	@isTest
	static void testUpdateAccountMDM() {
		String tipo = 'Floress';
		String email = 'Floress';
        
        Test.setMock(HttpCalloutMock.class, new c_PesquisaContaHttpCalloutMock('withAccount'));
		Test.startTest();
		c_PesquisaConta.updateAccountMDM('867030');
		Test.stopTest();
	}*/

	@isTest
	static void testGetProfissionalRecordTypeId() {
		Test.startTest();
		c_PesquisaConta.GetProfissionalRecordTypeId();
		Test.stopTest();
	}

	@isTest
	static void testGetPersonRecordTypeId() {
		Test.startTest();
		c_PesquisaConta.GetPersonRecordTypeId();
		Test.stopTest();
	}
}