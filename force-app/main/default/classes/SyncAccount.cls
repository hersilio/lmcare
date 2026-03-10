/**
 * @description       :
 * @author            : Francisco Ribeiro
 * @group             :
 * @last modified on  : 02-10-2024
 * @last modified by  : Francisco Ribeiro
 **/
public class SyncAccount {
  @AuraEnabled(cacheable=false)
  public static Account getAccount(Id recordID) {
    try {
        Account account = [
            SELECT Id, Numero_de_Conta__c, LastModifiedDate
            FROM Account
            WHERE ID = :recordID
            LIMIT 1
          ];
          return account;
    } catch(Exception e) {
        System.debug(e.getMessage());
        return null;
    }
  }

  /*
  @AuraEnabled(cacheable=false)
  public static boolean createMdmAccount(Id recordID) {
    try {
      List<Id> ids = new List<Id>();
      ids.add(recordID);
      c_AccountInsertMDM.AccountUpdateMDM(ids);
      return true;
    } catch (Exception e) {
      System.debug(e.getMessage());
      return false;
    }
  }*/

  @AuraEnabled(cacheable=false)
  public static boolean updateAccount(Id recordID) {
    try {
      Account account = new Account(
        Id = recordID,
        isSynced__c = true,
        isSyncedTime__c = System.now(),
        UpdateTime__c = String.valueOf(System.now())
      );
      update account;
      return true;
    } catch (Exception e) {
      System.debug(e.getMessage());
      return false;
    }
  }
}