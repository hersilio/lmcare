/**
 * @description       :
 * @author            : Francisco Ribeiro
 * @group             :
 * @last modified on  : 27-03-2024
 * @last modified by  : Francisco Ribeiro
 **/
@isTest
public class SyncAccountTest {
  @TestSetup
  static void makeData() {
    Account SFAccount = new Account();
    SFAccount.FirstName = 'Floress';
    SFAccount.LastName = 'Floress';
    SFAccount.BillingCity = 'SFAccount';
    SFAccount.BillingCountryCode = 'PT';
    SFAccount.BillingPostalCode = '1234-123';
    SFAccount.NIF__c = '123456789';
    SFAccount.PersonEmail = 'Floress@gmail.com';
    SFAccount.Phone = '123456789';
    SFAccount.Numero_de_Conta__c = '2462';
    insert SFAccount;
  }

  @isTest
  public static void SyncAccountTest() {
    Id accountId = [SELECT ID FROM Account LIMIT 1].ID;
    SyncAccount.getAccount(accountId);
    SyncAccount.updateAccount(accountId);
  }
}