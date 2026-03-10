public with sharing class LM_OrderCustomController {
	public Id recordId {get; set;}

    public LM_OrderCustomController(ApexPages.StandardController controller) {
        
    }
    
    public List<OrderItem> getOrderItems(){
        recordId = ApexPages.currentPage().getParameters().get('id');
        List<OrderItem> orderItems = [SELECT Id, Quantity, PricebookEntry.Name, Type__c, OrderId, TotalPrice, UnitPrice FROM OrderItem WHERE OrderId =:recordId ];   
        return orderItems;
    }

    public List<LM_ArtigoCD__c> getArtigosRecolha(){
        recordId = ApexPages.currentPage().getParameters().get('id');
        List<LM_ArtigoCD__c> artigosRecolha = [SELECT Id, Name, Designacao__c, Peso_Unitario__c, PVP__c, Quantidade__c, Peso_Total__c, Valor__c, Tipo__c FROM LM_ArtigoCD__c WHERE Order__c =:recordId AND Tipo__c = 'A Recolher'];   
        return artigosRecolha;
    }

    public List<LM_ArtigoCD__c> getArtigosEntrega(){
        recordId = ApexPages.currentPage().getParameters().get('id');
        List<LM_ArtigoCD__c> artigosEntrega = [SELECT Id, Name, Designacao__c, Peso_Unitario__c, PVP__c, Quantidade__c, Peso_Total__c, Valor__c, Tipo__c FROM LM_ArtigoCD__c WHERE Order__c =:recordId AND Tipo__c = 'A Entregar' ];   
        return artigosEntrega;
    }
	 
}