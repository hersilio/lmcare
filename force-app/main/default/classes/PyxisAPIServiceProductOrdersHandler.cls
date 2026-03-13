/**
 * @description       : Pyxis Request Product order Handler
 * @author            : miguel.lopes
 * @group             :
 * @create date on    : 2025-10-29 13:25:51
 * @last modified by  : miguel.lopes
 **/
public with sharing class PyxisAPIServiceProductOrdersHandler {
    
    private static Map<String, Object> FIELDS_MAPPING_PRODUCT_ORDER = PyxisAPIServiceHandler.getfieldsMapping('Product_Order');
    
    public static PyxisAPIServiceHandler.PyxisResponderWrapper createProductOrdersRequest(String payloadBody){
        SavePoint savepoint = Database.setSavepoint();
        try {
            ProductOderRequestWrapper fullResponseBody = new ProductOrdersRequestValidator().parse(payloadBody);
            String externalId = fullResponseBody.externalId;
            String mdmId = PyxisAPIServiceHandler.getMdmIdCustomer(payloadBody);
            String store = fullResponseBody.productOrders[0].store;
            Account account = PyxisAPIServiceHandler.getAccountFromMdmId(mdmId);
            Map<String, Object> requestInfo = new Map<String, Object>{
                'mdmId' => mdmId,
                'store' => store,
                'account' => (Account)account,
                'externalId' => externalId,
                'oppState' => 'New'
            };
            Map<String, Opportunity> sourceOpp = getSourceQuoteOpportunity(fullResponseBody, mdmId);
            if(sourceOpp.isEmpty()){
                Opportunity oppRecord = PyxisAPIServiceHandler.checkOppSameDay(requestInfo);
                sourceOpp.put('NEW_OPP', oppRecord);
            }
            List<SObject> productsOrderInserted = createProductOrder(fullResponseBody.productOrders, sourceOpp, account, mdmId, (Opportunity)sourceOpp.values()[0]);

            PyxisAPIServiceHandler.PyxisResponderWrapper payloadResponse = new PyxisAPIServiceHandler.PyxisResponderWrapper(productsOrderInserted, 201);
            return payloadResponse;
            
        } catch (ApiParseUtil.InvalidPayloadException e) {
            Database.rollback(savepoint);
            PyxisAPIServiceHandler.ErrorRequestWrapper error  = new PyxisAPIServiceHandler.ErrorRequestWrapper(e.getMessage(), e.getStackTraceString());
            PyxisAPIServiceHandler.PyxisResponderWrapper payloadResponse = new PyxisAPIServiceHandler.PyxisResponderWrapper(error, 400);
            return payloadResponse;}
        catch (Exception e) {
            Database.rollback(savepoint);
            PyxisAPIServiceHandler.ErrorRequestWrapper error  = new PyxisAPIServiceHandler.ErrorRequestWrapper(e.getMessage(), e.getStackTraceString());
            PyxisAPIServiceHandler.PyxisResponderWrapper payloadResponse = new PyxisAPIServiceHandler.PyxisResponderWrapper(error, 500);
            return payloadResponse;
        }
    }
    
    /**
     * @description : create Product Order Records
     * param        : productOrdersList: List of Product Orders from Payload
     * param        : opportunityId: Opportunity Id related to the Product Orders
     * param        : account: Account Record related to the Request
     * return       : list<SObject> with the Created Product Orders Records
     **/
    private static List<SObject> createProductOrder(List<ProductOrderWrapper> productOrdersList, Map<String, Opportunity> orderToOpp, Account account, String mdmId, Opportunity opp){
        String recordTypeApiName = [SELECT RecordTypeAPIName__c FROM Pyxis_Integration_Mapping__mdt WHERE Object_API_Name__c =: 'Product_Order' LIMIT 1].RecordTypeAPIName__c;
        List<Order> newProductOrders = new List<Order>();

        Set<String> uniqueKeys = new Set<String>();
        for (ProductOrderWrapper po : productOrdersList) {
            uniqueKeys.add(po.store + '_' + mdmId + '_' + po.orderNumber);
        }
        
        // CHECK FOR EXISTING ORDERS TO AVOID DUPLICATES
        Map<String, Order> existingOrders = new Map<String, Order>();
        for (Order o : [ SELECT Id, Pyxis_Unique_Id__c FROM Order WHERE Pyxis_Unique_Id__c IN :uniqueKeys]) {
            existingOrders.put(o.Pyxis_Unique_Id__c, o);
        }

        for ( ProductOrderWrapper productOrderRequest : productOrdersList) {
            Order newProductOrder = new Order();
            String uniqueOrderKey = productOrderRequest.store + '_' + mdmId + '_' + productOrderRequest.orderNumber;
            
            if (existingOrders.containsKey(uniqueOrderKey)) { 
                newProductOrder.Id = existingOrders.get(uniqueOrderKey).Id;
            }
            
            for (String key : FIELDS_MAPPING_PRODUCT_ORDER.keySet()) {
                String fieldApiName = String.valueOf(key);
                Object fieldValue = productOrderRequest.getValue(String.valueOf(FIELDS_MAPPING_PRODUCT_ORDER.get(key)));
                newProductOrder.put(fieldApiName, fieldValue);
            }
            // SYSTEM FIELDS
            newProductOrder.put('OpportunityId', orderToOpp.containsKey('NEW_OPP') ? orderToOpp.get('NEW_OPP').Id : orderToOpp.get(uniqueOrderKey).Id);
            newProductOrder.put('Status', 'Em Tratamento'); // Define default status for this mandatory field
            newProductOrder.put('Pyxis_Unique_Id__c', uniqueOrderKey);
            newProductOrder.put('AccountId', account.Id);
            newProductOrder.put('EffectiveDate', System.today());
            newProductOrder.put('Pricebook2Id', PyxisAPIServiceHandler.PRICE_BOOK_INFO.pricebookId);
            newProductOrder.put('RecordTypeId', PyxisAPIServiceHandler.getRecordTypeIdByApiName('Order', recordTypeApiName));
            newProductOrders.add(newProductOrder);
        }
        upsert newProductOrders Pyxis_Unique_Id__c;
        // PyxisAPIServiceAssyncJobs.PyxisAssyncJobsWrapper jobParams = new PyxisAPIServiceAssyncJobs.PyxisAssyncJobsWrapper(newProductOrders, orderToOpp.values(), null);
        // System.enqueueJob(new PyxisAPIServiceAssyncJobs('PRODUCT_ORDER', jobParams));
        TransactionTriggerHandler.skipTriggerExecution = true;
        PyxisAPIServiceHandler.setStoreId(newProductOrders);
        PyxisAPIServiceHandler.setUser(newProductOrders, new Map <String, String>{ 
            'CreatedByUser__c' => 'LDAPcreatedByUser__c',
            'InternalMessageCreatedBy__c' => 'InternalMessageCreatedBy_LDAP__c'
        });
        TransactionTriggerHandler.skipTriggerExecution = false;

        // CHECK FOR ORDER ITEMS TO CREATE
        Map<Order, List<OrderItemsWrapper>> orderItemsToAdd = new Map<Order, List<OrderItemsWrapper>>();
        for (Order orderItem : newProductOrders) {
            ProductOrderWrapper relatedOrder = productOrdersList[newProductOrders.indexOf(orderItem)];
            
            if(relatedOrder.orderItems.isEmpty()) break;
            
            if(!orderItemsToAdd.containsKey(orderItem)){
                orderItemsToAdd.put(orderItem, new List<OrderItemsWrapper>());
            }
            for(OrderItemsWrapper orderItemWrapper : relatedOrder.orderItems){
                orderItemsToAdd.get(orderItem).add(orderItemWrapper);
            }
        }
        createOrderItems(orderItemsToAdd, mdmId, orderToOpp);
        return newProductOrders;
    }
    
    public static void createOrderItems(Map<Order, List<OrderItemsWrapper>> orderItems, String mdmId, Map<String, Opportunity> orderToOpp /*, Opportunity opp*/){
        Map<String, Object> FIELDS_MAPPING_ORDER_ITEMS = PyxisAPIServiceHandler.getfieldsMapping('Product_Order_Item');
        List<OrderItem> newLineItems = new List<OrderItem>();
        Set<String> sourceQuoteIds = new Set<String>(); // Update suorceQuote -> Parent Opp to "Aguarda Pagamento"
        Id storeId;
        List<PyxisAPIServiceHandler.OrderCode49Wrapper> checkCode49 = new List<PyxisAPIServiceHandler.OrderCode49Wrapper>();
        
        for(Order order : orderItems.keySet()){
            List<OrderItemsWrapper> orderItemWrapper = orderItems.get(order);
            List<String> orderItemStages = new List<String>();
            
            for(OrderItemsWrapper orderItem : orderItemWrapper){
                sourceQuoteIds.add(orderItem.sourceQuoteNumber);
                orderItemStages.add(orderItem.itemStatus);
                
                //OBJECT VARIABLES
                OrderItem newOrderItem = new OrderItem();
                String uniqueKey = orderItem.sourceStore + '_' + orderItem.productReferenceEan + '_' + order.OrderCode__c + '_' + orderItem.lineNumber;
                String uniqueOrderKey = orderItem.sourceStore+'_'+mdmId+'_'+order.OrderCode__c;
                
                checkCode49.add(new PyxisAPIServiceHandler.OrderCode49Wrapper(
                    orderItem.sourceQuoteNumber != '' ? true : false,
                    orderItem.productReferenceEan,
                    orderItem.sourceQuoteNumber,
                    orderToOpp.containsKey('NEW_OPP') ? orderToOpp.get('NEW_OPP') : orderToOpp.get(uniqueOrderKey),
                    orderItemStages
                ));
                
                if(orderItem.sourceQuoteNumber != ''){
                    String uniqueSourceQuote = orderItem.sourceStore+'_'+mdmId+'_'+orderItem.sourceQuoteNumber;
                    Quote sourceQuote = PyxisAPIServiceHandler.getSourceQuote(uniqueSourceQuote); // make this out of loop
                    newOrderItem.put('SourceQuoteNumber__c', sourceQuote.Id);
                }
                
                for(String key : FIELDS_MAPPING_ORDER_ITEMS.keySet()){
                    String fieldApiName = String.valueOf(key);
                    Object fieldValue = orderItem.getValue(String.valueOf(FIELDS_MAPPING_ORDER_ITEMS.get(key)));
                    newOrderItem.put(fieldApiName, fieldValue);
                }
                
                // SYSTEM FIELDS
                newOrderItem.put('OrderId', order.Id);
                newOrderItem.put('PricebookEntryId', PyxisAPIServiceHandler.PRICE_BOOK_INFO.pricebookEntry);
                newOrderItem.put('Pyxis_Unique_Id__c', uniqueKey);
                newLineItems.add(newOrderItem);
            }
        }

        upsert newLineItems Pyxis_Unique_Id__c;
        // PyxisAPIServiceAssyncJobs.PyxisAssyncJobsWrapper jobParams = new PyxisAPIServiceAssyncJobs.PyxisAssyncJobsWrapper(newLineItems, orderToOpp.values(), checkCode49);
        // System.enqueueJob(new PyxisAPIServiceAssyncJobs('PRODUCT_ORDER_ITEMS', jobParams));
        TransactionTriggerHandler.skipTriggerExecution = true;
        PyxisAPIServiceHandler.checkCode49(checkCode49); // CHECK IF CODE 49
        PyxisAPIServiceHandler.checkOrderAllValidated(orderToOpp.values()); // CHECK IF ALL ORDER VALID
        PyxisAPIServiceHandler.setStoreId(newLineItems);
        PyxisAPIServiceHandler.setUser(newLineItems, new Map <String, String>{ 
            'CreatedByUser__c' => 'LDAPcreatedByUser__c', 
            'LastModifiedByUser__c' => 'LDAPlastModifiedByUser__c'
        });
        TransactionTriggerHandler.skipTriggerExecution = false;
    }

    public static Map<String, Opportunity> getSourceQuoteOpportunity(ProductOderRequestWrapper fullResponseBody, String mdmId){
        Map<String, Opportunity> isTransformation = new Map<String, Opportunity>();
        Set<String> quoteUniqueKeys = new Set<String>();
        Set<String> orderUniqueKeys = new Set<String>();
        Set<String> quoteAndOrderKeys = new Set<String>();
        
        List<ProductOrderWrapper> orders = fullResponseBody.productOrders;
        for (ProductOrderWrapper order : orders) {
            for(OrderItemsWrapper orderItem : (List<OrderItemsWrapper>)order.getValue('orderItems')){
                // if(orderItem.sourceQuoteNumber != ''){
                String quoteUniqueKey = order.store + '_' + mdmId + '_' + orderItem.sourceQuoteNumber; // confirmar se pedido pode ser transformado em lojas diferente
                String orderUniqueKey = order.store + '_' + mdmId + '_' + order.orderNumber;
                quoteUniqueKeys.add(quoteUniqueKey); // This quotes must exist in Salesforce already since they come from transformation
                orderUniqueKeys.add(orderUniqueKey);
                quoteAndOrderKeys.add(quoteUniqueKey+'_'+orderUniqueKey);
                // }
            }
        }
        List<Opportunity> opps = [  SELECT Id, Loja_de_Angariacao__c, (SELECT id, Pyxis_Unique_Id__c FROM Quotes) FROM Opportunity  WHERE Id IN 
                                    (SELECT OpportunityId FROM Quote WHERE Pyxis_Unique_Id__c IN :quoteUniqueKeys) ];
        
        if(!opps.isEmpty()){
            for (Opportunity opp : opps) {
                if(opp.Quotes.isEmpty()){
                }
                for (Quote quote : opp.Quotes) {
                    for(String orderKey : orderUniqueKeys){
                        for(String quoteAndOrderKey : quoteAndOrderKeys){
                            if(quote.Pyxis_Unique_Id__c+'_'+orderKey == quoteAndOrderKey){
                                isTransformation.put(orderKey, opp);
                            }
                        }
                    }
                }
            }
        }
        else{
            List<Order> ordersQuery = [ SELECT id, opportunityId FROM Order WHERE Pyxis_Unique_Id__c IN : orderUniqueKeys];
            Map<String, String> ordersToOppId = new Map<String, String>();
            if(!ordersQuery.isEmpty()){
                for(Order order : ordersQuery){
                    ordersToOppId.put(order.Id, order.opportunityId);
                }
                List<Opportunity> oppsQuery = [ SELECT Id, (SELECT id, Pyxis_Unique_Id__c FROM Orders) FROM Opportunity WHERE Id IN : ordersToOppId.values()];
                for(Opportunity opp : oppsQuery){
                    if(!opp.Orders.isEmpty()){
                        for(Order oppOrder : opp.Orders){
                            isTransformation.put(String.valueOf(oppOrder.Pyxis_Unique_Id__c), opp);
                        }
                    }
                }
            }
        }
        return isTransformation;
    }

    
    //**************************************************************************************************************
    //************************************************* VALIDATION LAYRE *******************************************
    //**************************************************************************************************************
    
    private class ProductOrdersRequestValidator{
        public ProductOderRequestWrapper parse(String payloadBody){
            ProductOderRequestWrapperString rawWrapper = (ProductOderRequestWrapperString) JSON.deserialize(payloadBody, ProductOderRequestWrapperString.class);
            if(rawWrapper == null){
                throw new ApiParseUtil.InvalidPayloadException('Payload vazio ou inválido.');
            }
            List<ProductOrderWrapper> typedProductOrders = new List<ProductOrderWrapper>();
            if(rawWrapper.productOrders != null){
                for(ProductOrderWrapperString productOrderString : rawWrapper.productOrders){
                    List<OrderItemsWrapper> typedOrderItems = new List<OrderItemsWrapper>();
                    if(productOrderString.orderItems != null){
                        for(OrderItemsWrapperString orderItemString : productOrderString.orderItems){
                            typedOrderItems.add(new OrderItemsWrapper(
                                ApiParseUtil.parseInteger(orderItemString.lineNumber, 'orderLineItems.lineNumber'),
                                ApiParseUtil.checkIfNull(orderItemString.productReferenceEan, 'orderLineItems.productReferenceEan'),
                                orderItemString.productName,
                                ApiParseUtil.parseDecimal(orderItemString.stockQuantity, 'orderLineItems.stockQuantity'),
                                orderItemString.itemType,
                                orderItemString.itemStatus,
                                ApiParseUtil.parseDatetime(orderItemString.availableDate, 'orderLineItems.availableDate'),
                                orderItemString.sourceQuoteNumber,
                                ApiParseUtil.parseDecimal(orderItemString.unitPrice, 'orderLineItems.unitPrice'),
                                ApiParseUtil.parseDecimal(orderItemString.discountPercent, 'orderLineItems.discountPercent'),
                                ApiParseUtil.parseInteger(orderItemString.pdo, 'orderLineItems.pdo'),
                                ApiParseUtil.parseDecimal(orderItemString.amountIncludingVAT, 'orderLineItems.amountIncludingVAT'),
                                orderItemString.lineComplementDescription,
                                orderItemString.supplierOrderNumber,
                                orderItemString.address,
                                orderItemString.pickupLocation,
                                orderItemString.createdByUser,
                                orderItemString.lastModifiedByUser,
                                orderItemString.codeSection,
                                orderItemString.codeSubsection,
                                orderItemString.codeType,
                                orderItemString.codeSubtype,
                                orderItemString.nomenclature,
                                orderItemString.sourceChannel,
                                orderItemString.sourceTransaction,
                                orderItemString.sourceStore
                            ));
                        }
                    }
                    typedProductOrders.add(new ProductOrderWrapper(
                        productOrderString.customerName,
                        productOrderString.customerNumber,
                        productOrderString.customerEmail,
                        productOrderString.orderNumber,
                        productOrderString.store,
                        ApiParseUtil.parseDatetime(productOrderString.createdDate, 'order.createdDate'),
                        ApiParseUtil.parseDatetime(productOrderString.availableDate, 'order.availableDate'),
                        ApiParseUtil.parseDecimal(productOrderString.totalWithVat, 'order.totalWithVat'),
                        productOrderString.createdByUser,
                        productOrderString.creationChannel,
                        productOrderString.orderStatus,
                        ApiParseUtil.parseDecimal(productOrderString.depositTotal, 'order.depositTotal'),
                        ApiParseUtil.parseDecimal(productOrderString.depositRemaining, 'order.depositRemaining'),
                        productOrderString.shippedFrom,
                        ApiParseUtil.parseDatetime(productOrderString.deliveryDate, 'order.deliveryDate'),
                        ApiParseUtil.parseDatetime(productOrderString.internalMessageCreatedDate, 'order.internalMessageCreatedDate'),
                        productOrderString.internalMessageCreatedBy,
                        productOrderString.internalMessageText,
                        ApiParseUtil.parseBoolean(productOrderString.eligibleForReducedVat, 'order.eligibleForReducedVat'),
                        typedOrderItems
                    ));
                }
            }
            PyxisAPIServiceHandler.CustomerWrapper customerWrapper;
            if(rawWrapper.customer != null){
                customerWrapper = new PyxisAPIServiceHandler.CustomerWrapper();
                customerWrapper.name = rawWrapper.customer.name;
                customerWrapper.mdmId = rawWrapper.customer.mdmId;
                customerWrapper.email = rawWrapper.customer.email;
            }
            ProductOderRequestWrapper productOderRequestWrapper = new ProductOderRequestWrapper(rawWrapper.externalId, customerWrapper, typedProductOrders);
            return productOderRequestWrapper;
        }
    }
    
    public class ProductOderRequestWrapperString{
        public String externalId;
        public CustomerWrapperString customer;
        public List<ProductOrderWrapperString> productOrders;
    }
    
    public class ProductOrderWrapperString{
        public String customerName;
        public String customerNumber;
        public String customerEmail;
        public String orderNumber;
        public String store;
        public String createdDate;
        public String availableDate;
        public String totalWithVat;
        public String createdByUser;
        public String creationChannel;
        public String orderStatus;
        public String depositTotal;
        public String depositRemaining;
        public String shippedFrom;
        public String deliveryDate;
        public String internalMessageCreatedDate;
        public String internalMessageCreatedBy;
        public String internalMessageText;
        public String eligibleForReducedVat;
        public List<OrderItemsWrapperString> orderItems;
    }
    
    public class OrderItemsWrapperString{
        private String lineNumber;
        private String productReferenceEan;
        private String productName;
        private String stockQuantity;
        private String itemType;
        private String itemStatus;
        private String availableDate;
        private String sourceQuoteNumber;
        private String unitPrice;
        private String discountPercent;
        private String pdo;
        private String amountIncludingVAT;
        private String lineComplementDescription;
        private String supplierOrderNumber;
        private String address;
        private String pickupLocation;
        private String createdByUser;
        private String lastModifiedByUser;
        private String codeSection;
        private String codeSubsection;
        private String codeType;
        private String codeSubtype;
        private String nomenclature;
        private String sourceChannel;
        private String sourceTransaction;
        private String sourceStore;
    }
    
    public class CustomerWrapperString{
        public String name;
        public String mdmId;
        public String email;
    }
    
    //**************************************************************************************************************
    //************************************************* PRODUCT WRAPPER **********************************************
    //**************************************************************************************************************
    
    public class ProductOderRequestWrapper{
        private String externalId;
        private PyxisAPIServiceHandler.CustomerWrapper customer;
        public List<ProductOrderWrapper> productOrders;

        public ProductOderRequestWrapper(String externalId, PyxisAPIServiceHandler.CustomerWrapper customer, List<ProductOrderWrapper> productOrders){
            this.externalId = externalId;
            this.customer = customer;
            this.productOrders = productOrders;
        }
    }
    
    public class ProductOrderWrapper{
        private String customerName;
        private String customerNumber;
        private String customerEmail;
        public String orderNumber;
        public String store;
        private Datetime createdDate;
        private Datetime availableDate;
        private Decimal totalWithVat;
        private String createdByUser;
        private String creationChannel;
        private String orderStatus;
        private Decimal depositTotal;
        private Decimal depositRemaining;
        private String shippedFrom;
        private Datetime deliveryDate;
        private Datetime internalMessageCreatedDate;
        private String internalMessageCreatedBy;
        private String internalMessageText;
        private Boolean eligibleForReducedVat;
        private List<OrderItemsWrapper> orderItems;
        
        public ProductOrderWrapper( String customerName, String customerNumber, String customerEmail, String orderNumber,
        String store, Datetime createdDate, Datetime availableDate, Decimal totalWithVat, String createdByUser,
        String creationChannel, String orderStatus, Decimal depositTotal, Decimal depositRemaining, String shippedFrom,
        Datetime deliveryDate, Datetime internalMessageCreatedDate, String internalMessageCreatedBy, String internalMessageText,
        Boolean eligibleForReducedVat, List<OrderItemsWrapper> orderItems){
            this.customerName = customerName;
            this.customerNumber = customerNumber;
            this.customerEmail = customerEmail;
            this.orderNumber = orderNumber;
            this.store = store;
            this.createdDate = createdDate;
            this.availableDate = availableDate;
            this.totalWithVat = totalWithVat;
            this.createdByUser = createdByUser;
            this.creationChannel = creationChannel;
            this.orderStatus = orderStatus;
            this.depositTotal = depositTotal;
            this.depositRemaining = depositRemaining;
            this.shippedFrom = shippedFrom;
            this.deliveryDate = deliveryDate;
            this.internalMessageCreatedDate = internalMessageCreatedDate;
            this.internalMessageCreatedBy = internalMessageCreatedBy;
            this.internalMessageText = internalMessageText;
            this.eligibleForReducedVat = eligibleForReducedVat;
            this.orderItems = orderItems;
        }
        
        private Object getValue(String fieldName) {
            switch on fieldName {
                when 'customerName'                     { return customerName; }
                when 'customerNumber'                   { return customerNumber; }
                when 'customerEmail'                    { return customerEmail; }
                when 'orderNumber'                      { return orderNumber; }
                when 'store'                            { return store; }
                when 'createdDate'                      { return createdDate; }
                when 'availableDate'                    { return availableDate; }
                when 'totalWithVat'                     { return totalWithVat; }
                when 'createdByUser'                    { return createdByUser; }
                when 'creationChannel'                  { return creationChannel; }
                when 'orderStatus'                      { return orderStatus; }
                when 'depositTotal'                     { return depositTotal; }
                when 'depositRemaining'                 { return depositRemaining; }
                when 'shippedFrom'                      { return shippedFrom; }
                when 'deliveryDate'                     { return deliveryDate; }
                when 'internalMessageCreatedDate'       { return internalMessageCreatedDate; }
                when 'internalMessageCreatedBy'         { return internalMessageCreatedBy; }
                when 'internalMessageText'              { return internalMessageText; }
                when 'eligibleForReducedVat'            { return eligibleForReducedVat; }
                when 'orderItems'                       { return orderItems; }
                when else                               { return null; }
            }
        }
    }
    
    private class OrderItemsWrapper{
        private Integer lineNumber;
        private String productReferenceEan;
        private String productName;
        private Decimal stockQuantity;
        private String itemType;
        private String itemStatus;
        private Datetime availableDate;
        private String sourceQuoteNumber;
        private Decimal unitPrice;
        private Decimal discountPercent;
        private Integer pdo;
        private Decimal amountIncludingVAT;
        private String lineComplementDescription;
        private String supplierOrderNumber;
        private String address;
        private String pickupLocation;
        private String createdByUser;
        private String lastModifiedByUser;
        private String codeSection;
        private String codeSubsection;
        private String codeType;
        private String codeSubtype;
        private String nomenclature;
        private String sourceChannel;
        private String sourceTransaction;
        private String sourceStore;
        
        public OrderItemsWrapper( Integer lineNumber, String productReferenceEan, String productName, Decimal stockQuantity, String itemType, 
                                String itemStatus, Datetime availableDate, String sourceQuoteNumber, Decimal unitPrice, Decimal discountPercent, 
                                Integer pdo, Decimal amountIncludingVAT, String lineComplementDescription, String supplierOrderNumber, String address,String pickupLocation, 
                                String createdByUser, String lastModifiedByUser, String codeSection, String codeSubsection, String codeType, 
                                String codeSubtype, String nomenclature, String sourceChannel, String sourceTransaction, String sourceStore){
            this.lineNumber = lineNumber;
            this.productReferenceEan = productReferenceEan;
            this.productName = productName;
            this.stockQuantity = stockQuantity;
            this.itemType = itemType;
            this.itemStatus = itemStatus;
            this.availableDate = availableDate;
            this.sourceQuoteNumber = sourceQuoteNumber;
            this.unitPrice = unitPrice;
            this.discountPercent = discountPercent;
            this.pdo = pdo;
            this.amountIncludingVAT = amountIncludingVAT;
            this.lineComplementDescription = lineComplementDescription;
            this.supplierOrderNumber = supplierOrderNumber;
            this.address = address;
            this.pickupLocation = pickupLocation;
            this.createdByUser = createdByUser;
            this.lastModifiedByUser = lastModifiedByUser;
            this.codeSection = codeSection;
            this.codeSubsection = codeSubsection;
            this.codeType = codeType;
            this.codeSubtype = codeSubtype;
            this.nomenclature = nomenclature;
            this.sourceChannel = sourceChannel;
            this.sourceTransaction = sourceTransaction;
            this.sourceStore = sourceStore;
        }
        
        private Object getValue(String fieldName) {
            switch on fieldName {
                when 'lineNumber'              { return lineNumber; }
                when 'productReferenceEan'    { return productReferenceEan; }
                when 'productName'            { return productName; }
                when 'stockQuantity'          { return stockQuantity; }
                when 'itemType'               { return itemType; }
                when 'itemStatus'             { return itemStatus; }
                when 'availableDate'          { return availableDate; }
                when 'sourceQuoteNumber'      { return sourceQuoteNumber; }
                when 'unitPrice'              { return unitPrice; }
                when 'discountPercent'        { return discountPercent; }
                when 'pdo'                    { return pdo; }
                when 'amountIncludingVAT'     { return amountIncludingVAT; }
                when 'lineComplementDescription' { return lineComplementDescription; }
                when 'supplierOrderNumber'    { return supplierOrderNumber; }
                when 'address'                { return address; }
                when 'pickupLocation'         { return pickupLocation; }
                when 'createdByUser'          { return createdByUser; }
                when 'lastModifiedByUser'     { return lastModifiedByUser; }
                when 'codeSection'            { return codeSection; }
                when 'codeSubsection'         { return codeSubsection; }
                when 'codeType'               { return codeType; }
                when 'codeSubtype'            { return codeSubtype; }
                when 'nomenclature'           { return nomenclature; }
                when 'sourceChannel'          { return sourceChannel; }
                when 'sourceTransaction'      { return sourceTransaction; }
                when 'sourceStore'            { return sourceStore; }
                when else                     { return null; }
            }
        }
    }
}