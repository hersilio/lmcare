/**
 * @description       :
 * @author            : Daniel Flores
 * @group             : Trigger for the object Account. Only used for after update
 * @last modified on  : 28-03-2024
 * @last modified by  : Francisco Ribeiro
 **/
trigger AccountTrigger on Account(before update, after update, after insert) {
  new AccountTriggerHandler().run();
}