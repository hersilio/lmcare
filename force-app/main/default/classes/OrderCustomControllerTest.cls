@isTest
public with sharing class OrderCustomControllerTest {
    
    @TestSetup
    static void makeData(){
        // Create a test account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        Id pbId = Test.getStandardPricebookId();

        // Create the first test order
        Order testOrder1 = new Order(
            AccountId = testAccount.Id,
            EffectiveDate = Date.today(),
            Status = 'Rascunho',
            Description = 'Test Order 1',
            Name = '12345',
            Pricebook2Id = pbId
            // Add any other required fields here
        );
        insert testOrder1;
        
        // Create the second test order
        Order testOrder2 = new Order(
            AccountId = testAccount.Id,
            EffectiveDate = Date.today(),
            Status = 'Rascunho',
            Description = 'Test Order 2',
            Name = '54321',
            Pricebook2Id = pbId

            // Add any other required fields here
        );
        insert testOrder2;

        // Create a test product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TP001',
            IsActive = true
            // Add any other required fields here
        );
        insert testProduct;

        // Create a test price book entry
        PricebookEntry testPricebookEntry = new PricebookEntry(
            Pricebook2Id = pbId,
            Product2Id = testProduct.Id,
            UnitPrice = 100,
            IsActive = true
            // Add any other required fields here
        );
        insert testPricebookEntry;

        // Create order items for the first order
        List<OrderItem> orderItemsForOrder1 = new List<OrderItem>{
            new OrderItem(OrderId = testOrder1.Id, PricebookEntryId = testPricebookEntry.Id, Quantity = 2, UnitPrice = 100),
            new OrderItem(OrderId = testOrder1.Id, PricebookEntryId = testPricebookEntry.Id, Quantity = 2, UnitPrice = 100),
            new OrderItem(OrderId = testOrder1.Id, PricebookEntryId = testPricebookEntry.Id, Quantity = 2, UnitPrice = 100)
        };

        // Create order items for the second order
        List<OrderItem> orderItemsForOrder2 = new List<OrderItem>{
            new OrderItem(OrderId = testOrder2.Id, PricebookEntryId = testPricebookEntry.Id, Quantity = 2, UnitPrice = 100),
            new OrderItem(OrderId = testOrder2.Id, PricebookEntryId = testPricebookEntry.Id, Quantity = 2, UnitPrice = 100)
        };

        insert orderItemsForOrder1;
        insert orderItemsForOrder2;
        
        // Create artigos for the first order
        List<LM_ArtigoCD__c> artigos = new List<LM_ArtigoCD__c>{
            new LM_ArtigoCD__c(Order__c = testOrder1.Id, Tipo__c = 'A Recolher'),
            new LM_ArtigoCD__c(Order__c = testOrder1.Id, Tipo__c = 'A Entregar')
        };
        insert artigos;
        
    }

    @isTest
    public static void getOrderItemsTest(){
        
        Order testOrder1 = [SELECT Id FROM Order WHERE Name = '12345'];

        PageReference pageRef = Page.LM_Aluguer_Ferramentas;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', testOrder1.id);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(testOrder1);
        LM_OrderCustomController ext = new LM_OrderCustomController(sc);

        System.assertEquals(3, ext.getOrderItems().size());
    }
    
    @isTest
    public static void getArtigosTest(){
        Order testOrder1 = [SELECT Id FROM Order WHERE Name = '12345'];

        PageReference pageRef = Page.LM_Aluguer_Ferramentas;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', testOrder1.id);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(testOrder1);
        LM_OrderCustomController ext = new LM_OrderCustomController(sc);
        System.assertEquals(1, ext.getArtigosEntrega().size());
        System.assertEquals(1, ext.getArtigosRecolha().size());
    }
}