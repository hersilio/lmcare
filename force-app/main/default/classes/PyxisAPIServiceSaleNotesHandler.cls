/**
 * @description       : Pyxis Request Sales Note Handler
 * @author            : miguel.lopes
 * @group             :
 * @create date on    : 2025-10-29 16:03:09
 * @last modified by  : miguel.lopes
 **/
public with sharing class PyxisAPIServiceSaleNotesHandler {
    
    private static Map<String, Object> FIELDS_MAPPING_SALES_NOTES = PyxisAPIServiceHandler.getfieldsMapping('Sales_Notes');
    
    public static PyxisAPIServiceHandler.PyxisResponderWrapper createSalesNotesRequest(String payloadBody){
        SavePoint savepoint = Database.setSavepoint();
        try {
            SaleNotesRequestWrapper fullResponseBody = new SalesNotesRequestValidator().parse(payloadBody);
            String externalId = fullResponseBody.externalId;
            String mdmId = PyxisAPIServiceHandler.getMdmIdCustomer(payloadBody);
            Account account = PyxisAPIServiceHandler.getAccountFromMdmId(mdmId);
            String store = fullResponseBody.saleNoteOrders[0].store;
            Map<String, Object> requestInfo = new Map<String, Object>{
                'mdmId' => mdmId,
                'store' => store,
                'account' => (Account)account,
                'externalId' => externalId,
                'oppState' => 'New'
            };
            Map<String, Opportunity> checkIfSalesNoteExists = checkIfSalesNoteExists(fullResponseBody, mdmId);
            if(checkIfSalesNoteExists.isEmpty()){
                checkIfSalesNoteExists.put('NEW_OPP', PyxisAPIServiceHandler.checkOppSameDay(requestInfo));
            }            
            List<SObject> salesNotesInserted = createSalesNotes(fullResponseBody.saleNoteOrders, checkIfSalesNoteExists, account, mdmId);

            PyxisAPIServiceHandler.PyxisResponderWrapper payloadResponse = new PyxisAPIServiceHandler.PyxisResponderWrapper(salesNotesInserted, 201);
            return payloadResponse;
            
        } catch (ApiParseUtil.InvalidPayloadException e) {
            Database.rollback(savepoint);
            PyxisAPIServiceHandler.ErrorRequestWrapper error  = new PyxisAPIServiceHandler.ErrorRequestWrapper(e.getMessage(), e.getStackTraceString());
            PyxisAPIServiceHandler.PyxisResponderWrapper payloadResponse = new PyxisAPIServiceHandler.PyxisResponderWrapper(error, 400);
            return payloadResponse;
        }
        catch (Exception e) {
            Database.rollback(savepoint);
            PyxisAPIServiceHandler.ErrorRequestWrapper error  = new PyxisAPIServiceHandler.ErrorRequestWrapper(e.getMessage(), e.getStackTraceString());
            PyxisAPIServiceHandler.PyxisResponderWrapper payloadResponse = new PyxisAPIServiceHandler.PyxisResponderWrapper(error, 500);
            return payloadResponse;
        }
    }
    
    /**
     * @description : Create Sales Notes Records
     * param        : salesNotesList: List of Sales Notes from Payload
     * param        : opportunityId: Opportunity Id related to the Sales Notes
     * param        : account: Account Record related to the Request
     * return       : list<SObject> with the Created Sales Notes Records
     **/
    private static List<SObject> createSalesNotes(List<SaleNoteWrapper> salesNotesList, Map<String, Opportunity> salesNoteOppMap, Account account, String mdmId){
        String recordTypeApiName = [SELECT RecordTypeAPIName__c FROM Pyxis_Integration_Mapping__mdt WHERE Object_API_Name__c =: 'Sales_Notes' LIMIT 1].RecordTypeAPIName__c;
        List<Order> newSalesNotes = new List<Order>();
        String storeName;
        for ( SaleNoteWrapper salesNotesRequest : salesNotesList) {
            Order newSalesNote = new Order();
            String uniqueOrderKey = salesNotesRequest.store + '_' + mdmId + '_' + salesNotesRequest.salesNoteNumber;
            storeName = salesNotesRequest.store;
                        
            for (String key : FIELDS_MAPPING_SALES_NOTES.keySet()) {
                String fieldApiName = String.valueOf(key);
                Object fieldValue = salesNotesRequest.getValue(String.valueOf(FIELDS_MAPPING_SALES_NOTES.get(key)));
                newSalesNote.put(fieldApiName, fieldValue);
            }
            newSalesNote.put('OpportunityId', salesNoteOppMap.containsKey(uniqueOrderKey) ? salesNoteOppMap.get(uniqueOrderKey).Id : salesNoteOppMap.get('NEW_OPP').Id);
            newSalesNote.put('RecordTypeId', PyxisAPIServiceHandler.getRecordTypeIdByApiName('Order', recordTypeApiName));
            newSalesNote.put('AccountId', account.Id);
            newSalesNote.put('Pyxis_Unique_Id__c', uniqueOrderKey);
            
            // MANDATORY FIELDS
            newSalesNote.put('EffectiveDate', System.today());
            newSalesNote.put('Status', 'Em Tratamento');
            newSalesNote.put('Pricebook2Id', PyxisAPIServiceHandler.PRICE_BOOK_INFO.pricebookId);
            newSalesNotes.add(newSalesNote);
        }
        upsert newSalesNotes Pyxis_Unique_Id__c;
        // PyxisAPIServiceAssyncJobs.PyxisAssyncJobsWrapper jobParams = new PyxisAPIServiceAssyncJobs.PyxisAssyncJobsWrapper(newSalesNotes, salesNoteOppMap.values(), null);
        // System.enqueueJob(new PyxisAPIServiceAssyncJobs('SALE_NOTE', jobParams));
        TransactionTriggerHandler.skipTriggerExecution = true;
        PyxisAPIServiceHandler.setStoreId(newSalesNotes);
        PyxisAPIServiceHandler.setUser(newSalesNotes, new Map <String, String>{ 
            'CreatedByUser__c' => 'LDAPcreatedByUser__c',
            'InternalMessageCreatedBy__c' => 'InternalMessageCreatedBy_LDAP__c'
        });
        TransactionTriggerHandler.skipTriggerExecution = false;
        
        // CHECK FOR ORDER ITEMS TO CREATE
        Map<Order, List<OrderItemsWrapper>> salesItemsToAdd = new Map<Order, List<OrderItemsWrapper>>();
        for (Order salesItem : newSalesNotes) {
            SaleNoteWrapper relatedSales = salesNotesList[newSalesNotes.indexOf(salesItem)];
            
            if(relatedSales.orderItems.isEmpty()){break;}
            
            if(!salesItemsToAdd.containsKey(salesItem)){
                salesItemsToAdd.put(salesItem, new List<OrderItemsWrapper>());
            }
            for(OrderItemsWrapper salesItemWrapper : relatedSales.orderItems){
                salesItemsToAdd.get(salesItem).add(salesItemWrapper);
            }
        }
        createSalesItem(salesItemsToAdd, salesNoteOppMap, mdmId);
        return newSalesNotes;
    }
    
    public static void createSalesItem(Map<Order, List<OrderItemsWrapper>> salesNoteItems, Map<String, Opportunity> salesNoteOppMap, String mdmId){
        Map<String, Object> FIELDS_MAPPING_SALES_ITEMS = PyxisAPIServiceHandler.getfieldsMapping('Sales_Note_Item');
        List<OrderItem> newLineItems = new List<OrderItem>();
        List<PyxisAPIServiceHandler.OrderCode49Wrapper> checkCode49 = new List<PyxisAPIServiceHandler.OrderCode49Wrapper>();
        Map<Id, List<String>> salesItemsStages = new Map<Id, List<String>>();
        
        for(Order sales : salesNoteItems.keySet()){
            List<OrderItemsWrapper> salesItemWrapper = salesNoteItems.get(sales);
            List<String> salesItemStages = new List<String>();
            
            for(OrderItemsWrapper salesItem : salesItemWrapper){
                salesItemStages.add(salesItem.itemStatus);
                OrderItem newSalesItem = new OrderItem();
                
                String uniqueKey = sales.Loja_Pyxis__c + '_' + salesItem.productReferenceEan + '_' + sales.SalesNoteNumber__c + '_' + salesItem.lineNumber;
                String uniqueOrderKey = sales.Loja_Pyxis__c + '_' + mdmId + '_' + sales.SalesNoteNumber__c;
                
                checkCode49.add(new PyxisAPIServiceHandler.OrderCode49Wrapper(
                    false, // No sourque quote for Sale Notes
                    salesItem.productReferenceEan,
                    null, // No sourque quote for Sale Notes
                    salesNoteOppMap.containsKey('NEW_OPP') ? salesNoteOppMap.get('NEW_OPP') : salesNoteOppMap.get(uniqueOrderKey),
                    salesItemStages
                ));
                
                for(String key : FIELDS_MAPPING_SALES_ITEMS.keySet()){
                    String fieldApiName = String.valueOf(key);
                    Object fieldValue = salesItem.getValue(String.valueOf(FIELDS_MAPPING_SALES_ITEMS.get(key)));
                    newSalesItem.put(fieldApiName, fieldValue);
                }
                // SYSTEM FIELDS
                newSalesItem.put('OrderId', sales.Id);
                newSalesItem.put('Pyxis_Unique_Id__c', uniqueKey);
                newSalesItem.put('PricebookEntryId', PyxisAPIServiceHandler.PRICE_BOOK_INFO.pricebookEntry);
                newLineItems.add(newSalesItem);
            }
            salesItemsStages.put(sales.Id, salesItemStages);
        }
        upsert newLineItems Pyxis_Unique_Id__c;
        // PyxisAPIServiceAssyncJobs.PyxisAssyncJobsWrapper jobParams = new PyxisAPIServiceAssyncJobs.PyxisAssyncJobsWrapper(newLineItems, salesNoteOppMap.values(), checkCode49);
        // System.enqueueJob(new PyxisAPIServiceAssyncJobs('SALE_NOTE_ITEMS', jobParams));
        TransactionTriggerHandler.skipTriggerExecution = true;
        PyxisAPIServiceHandler.checkCode49(checkCode49); // CHECK IF CODE 49
        PyxisAPIServiceHandler.checkOrderAllValidated(salesNoteOppMap.values()); // CHECK IF ALL ORDER VALID
        PyxisAPIServiceHandler.setUser(newLineItems, new Map <String, String>{ 
            'CreatedByUser__c' => 'LDAPcreatedByUser__c', 
            'LastModifiedByUser__c' => 'LDAPlastModifiedByUser__c'
        });
        TransactionTriggerHandler.skipTriggerExecution = false;
    }

    public static Map<String, Opportunity> checkIfSalesNoteExists(SaleNotesRequestWrapper fullResponseBody, String mdmId){
        List<String> salesNoteUniquekey = new List<String>();
        Map<String, Opportunity> salesNoteToId = new Map<String, Opportunity>();
        for(SaleNoteWrapper salesNote : fullResponseBody.saleNoteOrders){
            String uniqueKey = salesNote.store + '_' + mdmId + '_' + salesNote.salesNoteNumber;
            salesNoteUniquekey.add(uniqueKey);
        }
        List<Order> existingSalesNotes = [SELECT Id, Pyxis_Unique_Id__c FROM Order WHERE Pyxis_Unique_Id__c IN : salesNoteUniquekey];
        Set<String> existingSalesNotesKeys = new Set<String>();
        if(!existingSalesNotes.isEmpty()){
            for(Order existingSalesNote : existingSalesNotes){
                existingSalesNotesKeys.add(existingSalesNote.Pyxis_Unique_Id__c);
            }
        }
        List<Opportunity> oppsWithSalesNotes = [ SELECT Id, Loja_de_Angariacao__c, (SELECT Id, Pyxis_Unique_Id__c FROM Orders) 
                                                 FROM Opportunity WHERE Id IN 
                                                 (SELECT OpportunityId FROM Order WHERE Pyxis_Unique_Id__c IN : existingSalesNotesKeys)];
        for(Opportunity opp : oppsWithSalesNotes){
            for (Order salesNote : opp.Orders){
                salesNoteToId.put(salesNote.Pyxis_Unique_Id__c, opp);
            }
        }
        return salesNoteToId;
    }
    
    //**************************************************************************************************************
    //************************************************* VALIDATION LAYRE *******************************************
    //**************************************************************************************************************
    
    private class SalesNotesRequestValidator{
        public SaleNotesRequestWrapper parse(String payloadBody){
            SaleNotesRequestWrapperString rawWrapper = (SaleNotesRequestWrapperString) JSON.deserialize(payloadBody, SaleNotesRequestWrapperString.class);
            if(rawWrapper == null){
                throw new ApiParseUtil.InvalidPayloadException('Payload vazio ou inválido.');
            }
            List<SaleNoteWrapper> typedSalesNotes = new List<SaleNoteWrapper>();
            if(rawWrapper.saleNoteOrders != null ){
                for(SaleNoteWrapperString salesNoteString : rawWrapper.saleNoteOrders){
                    List<OrderItemsWrapper> typedSalesItems = new List<OrderItemsWrapper>();
                    if(salesNoteString.orderItems != null){
                        for(SalesItemsWrapperString salesItemString :  salesNoteString.orderItems){
                            typedSalesItems.add(new OrderItemsWrapper(
                            salesItemString.lineNumber,
                            ApiParseUtil.checkIfNull(salesItemString.productReferenceEan, 'orderItems.productReferenceEan'),
                            salesItemString.productName,
                            ApiParseUtil.parseDecimal(salesItemString.stockQuantity, 'orderItems.stockQuantity'),
                            salesItemString.itemType,
                            salesItemString.itemStatus,
                            ApiParseUtil.parseDecimal(salesItemString.pdo, 'orderItems.pdo'),
                            ApiParseUtil.parseDecimal(salesItemString.unitPrice, 'orderItems.unitPrice'),
                            ApiParseUtil.parseDecimal(salesItemString.discountPercent, 'orderItems.discountPercent'),
                            ApiParseUtil.parseDecimal(salesItemString.totalWithVat, 'orderItems.totalWithVat'),
                            salesItemString.lineComplementDescription,
                            salesItemString.createdByUser,
                            salesItemString.lastModifiedByUser,
                            salesItemString.codeSection,
                            salesItemString.codeSubsection,
                            salesItemString.codeType,
                            salesItemString.codeSubtype,
                            salesItemString.nomenclature,
                            salesItemString.supplier,
                            salesItemString.sourceTransactionType
                            ));
                        }
                    }
                    typedSalesNotes.add(new SaleNoteWrapper(
                    salesNoteString.salesNoteNumber,
                    salesNoteString.store,
                    ApiParseUtil.parseDatetime(salesNoteString.salesDate, 'salesNoteOrders.salesDate'),
                    ApiParseUtil.parseDecimal(salesNoteString.totalWithVat, 'salesNoteOrders.totalWithVat'),
                    salesNoteString.createdByUser,
                    salesNoteString.creationChannel,
                    salesNoteString.salesNoteStatus,
                    ApiParseUtil.parseDatetime(salesNoteString.internalMessageCreatedDate, 'salesNoteOrders.internalMessageCreatedDate'),
                    salesNoteString.internalMessageCreatedBy,
                    salesNoteString.internalMessageText,
                    typedSalesItems
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
            return new SaleNotesRequestWrapper(rawWrapper.externalId, customerWrapper,typedSalesNotes);
        }
    }
    
    private class SaleNotesRequestWrapperString{
        private String externalId;
        private PyxisAPIServiceHandler.CustomerWrapper customer;
        private List<SaleNoteWrapperString> saleNoteOrders;
    }
    
    private class SaleNoteWrapperString{
        private String salesNoteNumber;
        private String store;
        private String salesDate;
        private String totalWithVat;
        private String createdByUser;
        private String creationChannel;
        private String salesNoteStatus;
        private String internalMessageCreatedDate;
        private String internalMessageCreatedBy;
        private String internalMessageText;
        private List<SalesItemsWrapperString> orderItems;
    }
    
    private class SalesItemsWrapperString{
        private Integer lineNumber;
        private String productReferenceEan;
        private String productName;
        private String stockQuantity;
        private String itemType;
        private String itemStatus;
        private String pdo;
        private String unitPrice;
        private String discountPercent;
        private String totalWithVat;
        private String lineComplementDescription;
        private String createdByUser;
        private String lastModifiedByUser;
        private String codeSection;
        private String codeSubsection;
        private String codeType;
        private String codeSubtype;
        private String nomenclature;
        private String supplier;
        private String sourceTransactionType;
    }
    
    //**************************************************************************************************************
    //************************************************* SALES NOTES WRAPPER **********************************************
    //**************************************************************************************************************
    
    private class SaleNotesRequestWrapper{
        private String externalId;
        private PyxisAPIServiceHandler.CustomerWrapper customer;
        private List<SaleNoteWrapper> saleNoteOrders;
        
        public SaleNotesRequestWrapper(String externalId, PyxisAPIServiceHandler.CustomerWrapper customer, List<SaleNoteWrapper> saleNoteOrders){
            this.externalId = externalId;
            this.customer = customer;
            this.saleNoteOrders = saleNoteOrders;
        }
    }
    
    private class SaleNoteWrapper{
        private String salesNoteNumber;
        private String store;
        private Datetime salesDate;
        private Decimal totalWithVat;
        private String createdByUser;
        private String creationChannel;
        private String salesNoteStatus;
        private Datetime internalMessageCreatedDate;
        private String internalMessageCreatedBy;
        private String internalMessageText;
        private List<OrderItemsWrapper> orderItems;
        
        public SaleNoteWrapper( String salesNoteNumber, String store, Datetime salesDate, Decimal totalWithVat, String createdByUser,
        String creationChannel, String salesNoteStatus, Datetime internalMessageCreatedDate, String internalMessageCreatedBy,
        String internalMessageText, List<OrderItemsWrapper> orderItems){
            this.salesNoteNumber = salesNoteNumber;
            this.store = store;
            this.salesDate = salesDate;
            this.totalWithVat = totalWithVat;
            this.createdByUser = createdByUser;
            this.creationChannel = creationChannel;
            this.salesNoteStatus = salesNoteStatus;
            this.internalMessageCreatedDate = internalMessageCreatedDate;
            this.internalMessageCreatedBy = internalMessageCreatedBy;
            this.internalMessageText = internalMessageText;
            this.orderItems = orderItems;
        }
        
        private Object getValue(String fieldName) {
            switch on fieldName {
                when 'salesNoteNumber'                 { return salesNoteNumber; }
                when 'store'                           { return store; }
                when 'salesDate'                       { return salesDate; }
                when 'totalWithVat'                    { return totalWithVat; }
                when 'createdByUser'                   { return createdByUser; }
                when 'creationChannel'                 { return creationChannel; }
                when 'salesNoteStatus'                 { return salesNoteStatus; }
                when 'internalMessageCreatedDate'      { return internalMessageCreatedDate; }
                when 'internalMessageCreatedBy'        { return internalMessageCreatedBy; }
                when 'internalMessageText'             { return internalMessageText; }
                when 'orderItems'                      { return orderItems; }
                when else                              { return null; }
            }
        }
    }
    
    private class OrderItemsWrapper{
        private Integer lineNumber;
        private String productReferenceEan;
        private String productName;
        private Decimal stockQuantity;
        private Decimal pdo;
        private String itemType;
        private String itemStatus;
        private Decimal unitPrice;
        private Decimal discountPercent;
        private Decimal totalWithVat;
        private String lineComplementDescription;
        private String createdByUser;
        private String lastModifiedByUser;
        private String codeSection;
        private String codeSubsection;
        private String codeType;
        private String codeSubtype;
        private String nomenclature;
        private String supplier;
        private String sourceTransactionType;
        
        public OrderItemsWrapper(Integer lineNumber, String productReferenceEan, String productName, Decimal stockQuantity, String itemType, String itemStatus,
        Decimal pdo, Decimal unitPrice, Decimal discountPercent, Decimal totalWithVat, String lineComplementDescription,
        String createdByUser, String lastModifiedByUser, String codeSection, String codeSubsection,
        String codeType, String codeSubtype, String nomenclature, String supplier, String sourceTransactionType){
            this.lineNumber = lineNumber;
            this.productReferenceEan = productReferenceEan;
            this.productName = productName;
            this.stockQuantity = stockQuantity;
            this.itemType = itemType;
            this.itemStatus = itemStatus;
            this.pdo = pdo;
            this.unitPrice = unitPrice;
            this.discountPercent = discountPercent;
            this.totalWithVat = totalWithVat;
            this.lineComplementDescription = lineComplementDescription;
            this.createdByUser = createdByUser;
            this.lastModifiedByUser = lastModifiedByUser;
            this.codeSection = codeSection;
            this.codeSubsection = codeSubsection;
            this.codeType = codeType;
            this.codeSubtype = codeSubtype;
            this.nomenclature = nomenclature;
            this.supplier = supplier;
            this.sourceTransactionType = sourceTransactionType;
        }
        
        private Object getValue(String fieldName) {
            switch on fieldName {
                when 'lineNumber'                    { return lineNumber; }
                when 'productReferenceEan'          { return productReferenceEan; }
                when 'productName'                  { return productName; }
                when 'stockQuantity'                { return stockQuantity; }
                when 'pdo'                          { return pdo; }
                when 'itemType'                     { return itemType; }
                when 'itemStatus'                   { return itemStatus; }
                when 'unitPrice'                    { return unitPrice; }
                when 'discountPercent'              { return discountPercent; }
                when 'totalWithVat'                 { return totalWithVat; }
                when 'lineComplementDescription'    { return lineComplementDescription; }
                when 'createdByUser'                { return createdByUser; }
                when 'lastModifiedByUser'           { return lastModifiedByUser; }
                when 'codeSection'                  { return codeSection; }
                when 'codeSubsection'               { return codeSubsection; }
                when 'codeType'                     { return codeType; }
                when 'codeSubtype'                  { return codeSubtype; }
                when 'nomenclature'                 { return nomenclature; }
                when 'supplier'                     { return supplier; }
                when 'sourceTransactionType'        { return sourceTransactionType; }
                when else                           { return null; }
            }
        }
    }
}