/**
 * @description       :
 * @author            : Daniel Flores
 * @group             :
 * @last modified on  : 02-24-2025
 * @last modified by  : miguel.lopes
 **/
public class AccountTriggerHandler extends TriggerHandler {
  public AccountTriggerLogic accountTriggerLogic { get; set; }
  public Map<Id, Account> newAccountMap { get; set; }
  public Map<Id, Account> oldAccountMap { get; set; } 

  public AccountTriggerHandler() {
    this.newAccountMap = (Map<Id, Account>) Trigger.newMap;
    this.oldAccountMap = (Map<Id, Account>) Trigger.oldMap;
    accountTriggerLogic = new AccountTriggerLogic(this);
  }

  public override void afterInsert() {
    //accountTriggerLogic.insertAccountMDM(newAccountMap);   
  }

  public override void beforeUpdate() {
    Boolean byPass = FeatureManagement.checkPermission('By_Pass_Validations');
    if(!byPass){
      accountTriggerLogic.checkSync(newAccountMap,oldAccountMap);
    }
  }

  public override void afterUpdate() {
    //accountTriggerLogic.mergeSharepointFolders(oldAccountMap);
    //accountTriggerLogic.mergeSharepointFolders(newAccountMap,oldAccountMap);
  }
}