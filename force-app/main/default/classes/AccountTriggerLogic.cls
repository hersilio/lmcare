/**
 * @description       :
 * @author            : Daniel Flores
 * @group             :
 * @last modified on  : 05-12-2024
 * @last modified by  : João Rosa
 **/
public class AccountTriggerLogic {
  private AccountTriggerHandler accountHandler;

  public AccountTriggerLogic(AccountTriggerHandler accountHandler) {
    this.accountHandler = accountHandler;
  }

  public void checkSync(Map<Id, Account> newAccountMap,Map<Id, Account> oldAccountMap) {
    System.debug('Aqui check permis');
    for (Account account : newAccountMap.values()) {
      Account acc = oldAccountMap.get(account.Id);

      TempValidation__mdt tempValidation = TempValidation__mdt.getInstance('AccountSync');
      String name = account.Name == null? account.firstName : account.Name;

      Boolean skipValidation = (name.contains('[Não Usar]') && acc.CreatedDate < Date.valueOf('2024-12-04T01:00:00.000+0000') && tempValidation.isActive__c);
        
      if (!skipValidation && (!account.isSynced__c || account.isSyncedTime__c < System.now().addMinutes(-30) || account.isSyncedTime__c == null) && acc.Numero_de_Conta__c != null) {
        account.addError(
          'A Conta não está sincronizada com o ELO, clique no botão Sincronizar para poder editar.'
        );
      }
      
    }
  }

  /*
  public void insertAccountMDM(Map<Id, Account> newAccountMap) {
    List<Id> ListAccountInsert = new List<Id>();
    for (Account acc : newAccountMap.values()) {
      ListAccountInsert.add(acc.Id);
    }

    c_AccountInsertMDM.AccountUpdateMDM(ListAccountInsert);
  }
  */

  /*
  public void mergeSharepointFolders(Map<Id, Account> newAccountMap, Map<Id, Account> oldAccountMap) {
    //List<Account> ListAccountUpdate = new List<Account>();
    Boolean skipUpdate = false;
    List<Id> ListAccountUpdate = new List<Id>();
    for (Account acc : newAccountMap.values()) {
      Account acc2 = oldAccountMap.get(acc.Id);
      if (acc2.Numero_de_Conta__c == null) {
        skipUpdate = true;
      }
      ListAccountUpdate.add(acc.Id);
    }

    if (!skipUpdate) {
      c_AccountUpdateMDM.AccountUpdateMDM(ListAccountUpdate);      
    }
  }
      */
}