/**
 * @description       :
 * @author            : Hersilio Belini de Oliveira
 * @group             :
 * @last modified on  : 2026-01-05
 * @last modified by  : Hersilio Belini de Oliveira
 **/
@isTest
public with sharing class TaskRuleEngineTest {
    
    @isTest
    static void testEvaluateInvocable_WithRequests() {
        SObject record = new Opportunity(Name = 'TESTE2', RecordTypeId = '012UE0000015WY9YAM', StageName = 'Pedido de Orçamento', CloseDate = Date.today().addMonths(1));
        insert record;
        
        TaskRuleEngine.TaskRuleRequest request = new TaskRuleEngine.TaskRuleRequest();
        request.Record = record;
        request.TriggerType = 'Opportunity';
        request.TriggerEvent = 'OnCreate';
        
        List<TaskRuleEngine.TaskRuleRequest> requests = new List<TaskRuleEngine.TaskRuleRequest>{ request };
        
        Test.startTest();
        TaskRuleEngine.evaluateInvocable(requests);
        Test.stopTest();
        
        List<Task> tasks = [SELECT Id, Subject, WhatId FROM Task WHERE WhatId = :record.Id];
        System.assertEquals(tasks.isEmpty(), false, 'Tasks should be created');
    }
}