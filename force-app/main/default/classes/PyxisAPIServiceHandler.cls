/**
 * @description       : Description
 * @author            : miguel.lopes
 * @group             :
 * @create date on    : 2025-10-15 10:56:22
 * @last modified by  : miguel.lopes
 **/
public with sharing class PyxisAPIServiceHandler {
    
    private static Id pricebookId = [SELECT id FROM Pricebook2 WHERE IsActive = true LIMIT 1].Id;
    private static Id productId = [SELECT Id FROM Product2 WHERE Name = 'Pyxis' LIMIT 1].Id;
    private static Id pricebookEntry = [SELECT id FROM PricebookEntry WHERE Product2Id =: productId LIMIT 1].Id;
    public static PriceBookInfoWrapper PRICE_BOOK_INFO = new PriceBookInfoWrapper(pricebookId, productId, pricebookEntry);
    
    /**
     * @description : handle request from Pyxis API Service
     * param        : payloadBody: Full Payload Body from Request
     * param        : typeRequest: Type of Request Endpoint
     * return       : PyxisResponderWrapper with the Response Payload
     **/
    public static PyxisAPIServiceHandler.PyxisResponderWrapper handleRequestPyxis(String payloadBody, String typeRequest){
        
        PyxisAPIServiceHandler.PyxisResponderWrapper response;
        switch on typeRequest {
            when 'quotes' {
                response = PyxisAPIServiceQuotesHandler.createQuotesRequest(payloadBody);
            }
            when 'product-orders' {
                response = PyxisAPIServiceProductOrdersHandler.createProductOrdersRequest(payloadBody);
            }
            when 'sale-notes' {
                response = PyxisAPIServiceSaleNotesHandler.createSalesNotesRequest(payloadBody);
            }
        }
        return response;
    }
    
    /**
     * @description : Check if Opportunity with same name was created today
     * param        : requestId: External Id from Pyxis Payload
     * param        : account: Account Record related to the Request
     * return       : Opportunity Record
     **/
    public static Opportunity checkOppSameDay(Map<String, Object> requestInfo){
        List<String> closedOppStage = new List<String>{'Fechada Ganha', 'Fechada Perdida'};
        PyxisTargetDate__c setting = [SELECT Next_Day__c FROM PyxisTargetDate__c LIMIT 1];
        // String externalId = (String)requestInfo.get('externalId');
        Account account = (Account)requestInfo.get('account');
        String oppState = (String)requestInfo.get('oppState');
        String mdmId = (String)requestInfo.get('mdmId');
        String store = (String)requestInfo.get('store');
        
        Pyxis_Integration_Mapping__mdt oppSetting = [SELECT RecordTypeAPIName__c FROM Pyxis_Integration_Mapping__mdt WHERE Object_API_Name__c =: 'Opportunity' LIMIT 1];
        Opportunity oppToReturn;
        String keyName = store + '_' + mdmId + '_' + System.today();
        Date todayDate = Date.today();
        List<Opportunity> existingOpportunities = [SELECT Id, Name, CreatedDate FROM Opportunity WHERE Numero_Pyxis__c =: keyName AND StageName NOT IN : closedOppStage LIMIT 1];
        if(!existingOpportunities.isEmpty() && setting.Next_Day__c == false){
            oppToReturn = existingOpportunities[0];
        }
        else{
            Opportunity newRequest = new Opportunity();
            newRequest.Name = keyName;
            newRequest.Numero_Pyxis__c = keyName;
            newRequest.AccountId = account.Id;
            newRequest.RecordTypeId = getRecordTypeIdByApiName('Opportunity', oppSetting.RecordTypeAPIName__c);
            newRequest.CloseDate = Date.today();
            newRequest.Loja_de_Angariacao__c = setOppSourceStore(store);
            newRequest.StageName = oppState; // TBD based on what comes from API
            insert newRequest;
            oppToReturn = newRequest;
        }
        return oppToReturn;
    }
    
    public static String setOppSourceStore(String storeCode){
        String storeName = [SELECT Name FROM LM_Store__c WHERE Store_Code_Number__c =: storeCode LIMIT 1].Name;
        if(storeName != NULL){
            storeName = storeName.toUpperCase();
            storeName = storeName.substring(0,1).toUpperCase() + storeName.substring(1);
        }
        return storeName;
    }
    
    public static Id getRecordTypeIdByApiName(String objectApiName, String recordTypeApiName){
        Map<String, Schema.RecordTypeInfo> recordTypeInfoMap = Schema.getGlobalDescribe().get(objectApiName).getDescribe().getRecordTypeInfosByDeveloperName();
        if(recordTypeInfoMap.containsKey(recordTypeApiName)){
            return recordTypeInfoMap.get(recordTypeApiName).getRecordTypeId();
        }
        return null;
    }
    
    /**
     * @description : To get the source quote from Order
     * param        : uniqueSourceQuote: sourceQuote from Order
     * return       :
     **/
    public static Quote getSourceQuote(String uniqueSourceQuote){
        Quote sourceQuote = [SELECT id FROM Quote where Pyxis_Unique_Id__c =: uniqueSourceQuote ];
        return sourceQuote;
    }
    /**
     * @description : To set Store Id Lookup from Store Code Number
     * param        : transactionInserted: List of SObjects inserted from Pyxis Payload
     * return       : void
     **/
    public static void setStoreId(List<SObject> transactionInserted){
        String objType = String.valueOf(transactionInserted.getSObjectType());
        List<SObject> transToUpdate = new List<SObject>();
        Map<Id, String> transactionStoresMap = new Map<Id, String>();
        Map<Id, String> pickupMap = new Map<Id, String>();
        Map<Id, String> shippedFromMap = new Map<Id, String>();
        for(SObject transType : transactionInserted){
            if(objType == 'Quote'){
                transactionStoresMap.put((Id)transType.get('Id'), (String)transType.get('Store__c'));
            }
            if(objType == 'QuoteLineItem'){
                transactionStoresMap.put((Id)transType.get('Id'), (String)transType.get('TransformStore__c'));
            }
            if(objType == 'Order'){
                transactionStoresMap.put((Id)transType.get('Id'), (String)transType.get('Loja_Pyxis__c'));
                shippedFromMap.put((Id)transType.get('Id'), (String)transType.get('ShippedFrom_Code__c'));
            }
            if(objType == 'OrderItem'){
                transactionStoresMap.put((Id)transType.get('Id'), (String)transType.get('Store__c'));
                pickupMap.put((Id)transType.get('Id'), (String)transType.get('Pickup__c'));
            }
        }
        
        Set<String> allCodes = new Set<String>();
        allCodes.addAll(transactionStoresMap.values());
        allCodes.addAll(pickupMap.values());
        allCodes.addAll(shippedFromMap.values());
        
        List<LM_Store__c> storeCodes = [SELECT Id, Store_Code_Number__c FROM LM_Store__c WHERE Store_Code_Number__c IN :allCodes];
        
        for(SObject trasInserted : transactionInserted){
            Boolean shouldUpdate = false;
            for(LM_Store__c store : storeCodes){
                if(transactionStoresMap.get(trasInserted.Id) == store.Store_Code_Number__c){
                    if(objType == 'Quote'){trasInserted.put('Store_Lookup__c', store.Id);}
                    if(objType == 'QuoteLineItem'){trasInserted.put('TransformStore_Lookup__c', store.Id);}
                    if(objType == 'Order'){trasInserted.put('Store__c', store.Id);}
                    if(objType == 'OrderItem'){trasInserted.put('Store_Lookup__c', store.Id);}
                    shouldUpdate = true;
                }
                if(pickupMap.get(trasInserted.Id) == store.Store_Code_Number__c){
                    if(objType == 'OrderItem'){
                        trasInserted.put('Pickup_Lookup__c', store.Id);
                        shouldUpdate = true;
                    }
                }
                if(shippedFromMap.get(trasInserted.Id) == store.Store_Code_Number__c){
                    if(objType == 'Order'){
                        trasInserted.put('ShippedFrom__c', store.Id);
                        shouldUpdate = true;
                    }
                }
            }
            if(shouldUpdate){
                transToUpdate.add(trasInserted);
            }
        }
        update transToUpdate;
    }
    
    /**
     * @description : Get MDM Id from Customer Payload
     * param        : fullResponseBody: Full Payload Body
     * return       : mdmId: MDM Id of Customer
     **/
    public static String getMdmIdCustomer(String fullResponseBody){
        Map<String, Object> deserializedPayload = (Map<String, Object>) JSON.deserializeUntyped(fullResponseBody);
        Map<String, Object> customerInfo = (Map<String, Object>) deserializedPayload.get('customer');
        return String.valueOf(customerInfo.get('number'));
    }
    
    /**
     * @description : To rerieve Fields Mapping from Metadata
     * param        : objectApiName: API Name of the Object/Record Type to retrieve the Mapping
     * return       : Map<String, Object> with the Fields Mapping
     **/
    public static Map<String, Object> getfieldsMapping(String objectApiName){
        Map<String, Map<String, Object>> fieldsMapping = new Map<String, Map<String, Object>>();
        
        Pyxis_Integration_Mapping__mdt objectSetting = [SELECT Fields_Mapping__c FROM Pyxis_Integration_Mapping__mdt WHERE Object_API_Name__c =: objectApiName LIMIT 1];
        List<String> mappingLines = objectSetting.Fields_Mapping__c.split('; ');
        
        Map<String, Object> deserializedMapping = new Map<String, Object>();
        for(String mappingLine : mappingLines){
            List<String> keyValue = mappingLine.split(':');
            deserializedMapping.put(keyValue[0], keyValue[1]);
        }
        return deserializedMapping;
    }
    
    public static void deleteOppOrders(Set<Id> opps){
        List<Order> ordersToDelete = [SELECT Id FROM Order WHERE OpportunityId IN :opps];
        if(!ordersToDelete.isEmpty()){
            delete ordersToDelete;
        }
    }
    
    public static void setTotalAmountOpp(Set<Id> oppIds){
        System.debug('SETTING UP TOTAL AMOUNT OPP: ' + oppIds);
        List<Opportunity> orderToOpp = [SELECT  id, 
                                                Total_Amount_Orders__c,
                                                (SELECT TotalWithVat__c,
                                                    (SELECT ProductCode__c, 
                                                        TotalWithVat__c, 
                                                        DiscountPercentage__c, 
                                                        UnitPrice, 
                                                        Quantity, 
                                                        ProductSectionName__c,
                                                        ItsServiceType__c 
                                                    FROM OrderItems) 
                                                FROM Orders)
                                        FROM Opportunity WHERE Id IN :oppIds];
        
        for(Opportunity opp : orderToOpp){
            Decimal totalAmount = 0; Decimal totalAmount49 = 0; Decimal totalAmountNot49 = 0; Decimal totalDiscount = 0;
            Decimal maxSectionAmount = 0; String maxSectionName = ''; Boolean hasCode49 = false; Boolean hasProduct = false;
            if(!opp.Orders.isEmpty()){
                for(Order order : opp.Orders){
                    totalAmount += order.TotalWithVat__c != null ? order.TotalWithVat__c : 0;
                    if(!order.OrderItems.isEmpty()){
                        for(OrderItem orderItem : order.OrderItems){
                            if(orderItem.ProductSectionName__c != null && orderItem.TotalWithVat__c != null){
                                if(orderItem.TotalWithVat__c > maxSectionAmount){
                                    maxSectionAmount = orderItem.TotalWithVat__c;
                                    maxSectionName = orderItem.ProductSectionName__c;
                                }
                            }
                            if(orderItem.DiscountPercentage__c != null && orderItem.UnitPrice != null){
                                totalDiscount += (orderItem.UnitPrice * orderItem.Quantity) * (orderItem.DiscountPercentage__c / 100);
                            }
                            if(orderItem.ProductCode__c.startsWith('49')){
                                totalAmount49 += orderItem.TotalWithVat__c != null ? orderItem.TotalWithVat__c : 0;
                            }
                            if(!orderItem.ProductCode__c.startsWith('49')){
                                totalAmountNot49 += orderItem.TotalWithVat__c != null ? orderItem.TotalWithVat__c : 0;
                                hasProduct = true;
                            }
                            if(orderItem.ItsServiceType__c){
                                hasCode49 = true;
                            }
                        }
                    }
                }
            }
            opp.Total_Amount_Orders__c = totalAmount;
            opp.Total_Amount_Service_49__c = totalAmount49;
            opp.Total_Amount_Not_49__c = totalAmountNot49;
            opp.Total_Discount__c = totalDiscount;
            opp.Main_Section_Name__c = maxSectionName;
            opp.Pyxis_Sales_Type__c = hasCode49 && hasProduct ? 'Product_and_Service' : hasCode49 ? 'Service' : 'Product';
        }
        update orderToOpp;
    }
    
    public static Map<Id, Boolean> checkOppPedingPayment(List<Opportunity> sourceOpps){
        Map<Id, Boolean> oppWithPedingPayment = new Map<Id, Boolean>();
        
        List<Opportunity> opps = [  SELECT  Id, 
                                            (SELECT Id, StatePyxis__c, 
                                            (SELECT ProductCode__c FROM OrderItems) 
                                            FROM Orders)
                                    FROM Opportunity WHERE Id IN :sourceOpps];
        
        for (Opportunity opp : opps) {
            if(!opp.Orders.isEmpty()){
                for(Order order : opp.Orders){
                    Boolean code49 = false;
                    for(OrderItem orderItem : order.OrderItems){
                        if(orderItem.ProductCode__c.startsWith('49')){
                            code49 = true;
                            break;
                        }
                    }
                    if(order.StatePyxis__c == '40' && !code49){
                        oppWithPedingPayment.put(opp.Id, true);
                        break;
                    }
                    else{oppWithPedingPayment.put(opp.Id, false);}
                }
            }
            else{oppWithPedingPayment.put(opp.Id, false);}
        }
        return oppWithPedingPayment;
    }
    
    /**
     * This method can be refactor duplicate in side if, can be one if and have OR's
     */
    public static void checkCode49(List<OrderCode49Wrapper> listSettings) {
        Map<Id, Opportunity> oppsToUpdate = new Map<Id, Opportunity>();
        List<String> quotesId = new List<String>();
        List<Opportunity> opps = new List<Opportunity>();
        for(OrderCode49Wrapper lineItem :  listSettings){opps.add(lineItem.opp);}
        Map<Id, Boolean> hasPedingPaymentMap = checkOppPedingPayment(opps);
        
        for (OrderCode49Wrapper lineItem : listSettings) {
            Boolean hasPedingPayment = hasPedingPaymentMap.get(lineItem.opp.Id);
            
            if((lineItem.code == '49012693' || lineItem.code == '49013807')){
                System.debug('is from 49012693 OR 49013807');
                if(lineItem.isTransformation){
                    System.debug('Is transformation');
                    quotesId.add(lineItem.sourceQuote);
                }
                else{
                    System.debug('Is not transformation');
                    Opportunity opp = lineItem.opp;
                    opp.StageName = 'Aguarda Pagamento';
                    oppsToUpdate.put(opp.Id, opp);
                }
            }
            
            // PEDIDO CONTAINS CODE 49
            else if(lineItem.code.startsWith('49') && !hasPedingPayment){
                System.debug('cointains code 49');
                Opportunity opp = lineItem.opp;
                opp.StageName = 'Retificação de Medidas';
                oppsToUpdate.put(opp.Id, opp);
            }
            
            // PEDIDO NOT CONTAINS CODE 49 AND FROM TRANSFORMATION
            else if(!lineItem.code.startsWith('49') && lineItem.isTransformation) {
                System.debug('Does not contain 49 and from tranformation');
                Opportunity opp = lineItem.opp;
                opp.StageName = 'Aguarda Pagamento';
                oppsToUpdate.put(opp.Id, opp);
            }
            
            // PEDIDO DOES NOT CONTAINS CODE 49 AND IS NOT TRANSFORMATION
            else if(!lineItem.code.startsWith('49') && !lineItem.isTransformation ){
                System.debug('Is not from tranformation and is not code 49 - Aguarda Pagamento');
                Opportunity opp = lineItem.opp;
                opp.StageName = 'Aguarda Pagamento';
                oppsToUpdate.put(opp.Id, opp);
            }
        }
        if(!quotesId.isEmpty()){
            List<Opportunity> queryOpps = [ SELECT Id FROM Opportunity  WHERE Id IN
                                            (SELECT OpportunityId FROM Quote WHERE ExternalQuoteNumber__c IN :quotesId)];
            for (Opportunity opp : queryOpps) {
                opp.StageName = 'Aguarda Pagamento';
                oppsToUpdate.put(opp.Id, opp);
            }
        }
        update oppsToUpdate.values();
    }
    
    public static void checkOrderAllValidated(List<Opportunity> opps){
        List<Opportunity> queryOpps = [SELECT id, (SELECT id, StatePyxis__c FROM Orders) FROM Opportunity WHERE Id IN : opps];
        // set<String> inCourseStatus = new set<String>{'10'};
        
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for(Opportunity queryOpp : queryOpps ){
            List<String> ordersStages = new List<String>();
            
            Boolean hasPending = false; Boolean hasRejected = false; Boolean hasValidated = false;
            
            for (Order order : queryOpp.Orders) {
                if(order.StatePyxis__c == '10'){
                    hasPending = true;
                }
                else if (order.StatePyxis__c == '90') {
                    hasRejected = true;
                }
                else {
                    hasValidated = true; // any other code = validated
                }
            }
            
            if (!hasPending && hasRejected && !hasValidated) {
                queryOpp.StageName = 'Identificar Motivo de Perda';
                oppsToUpdate.add(queryOpp);
            }
            
            else if (!hasPending && hasValidated) {
                queryOpp.StageName = 'Operação Em Curso';
                oppsToUpdate.add(queryOpp);
            }
        }
        update oppsToUpdate;
    }
    
    /**
     * @description : To check expired quotes and update Opportunity Stage accordingly
     * param        : List<Id> oppIds: List of Opportunity Ids to check expired quotes
     * return       : void
     **/
    public static void checkExpiredQuotes(List<Opportunity> opps){
        Set<String> openStates = new Set<String>{'100', '110'};
        List<Opportunity> oppQuerys = [ SELECT Id,  
                                            (SELECT Id, StatePyxis__c FROM Quotes), 
                                            (SELECT Id from Orders) FROM Opportunity 
                                        WHERE Id IN : opps];
        
        Map<Opportunity, Boolean> oppHasOrdersMap = new Map<Opportunity, Boolean>();
        for(Opportunity opp : oppQuerys){
            Boolean hasOrders = !opp.Orders.isEmpty();
            oppHasOrdersMap.put(opp, hasOrders);
        }
        
        Map<Opportunity, List<String>> oppStagesMap = new Map<Opportunity, List<String>>();
        for(Opportunity opp : oppQuerys){
            if(!opp.Quotes.isEmpty()){
                List<String> stages = new List <String>();
                for (Quote quote : opp.Quotes) {
                    stages.add(quote.StatePyxis__c);
                }
                oppStagesMap.put(opp, stages);
            }
        }
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        
        for(Opportunity opp : oppStagesMap.keySet()){
            Set<String> quoteStates = new Set<String>(oppStagesMap.get(opp));
            Set<String> intersection = new Set<String>(quoteStates);
            intersection.retainAll(openStates);
            
            if(!quoteStates.isEmpty() && !oppHasOrdersMap.get(opp) && intersection.isEmpty()){
                opp.StageName = 'Identificar Motivo de Perda';
                oppsToUpdate.add(opp);
            }
        }
        update oppsToUpdate;
    }
    
    /**
     * @description : Get Account from mdmId
     * param        : mdmId from JSON
     * return       : Account
     **/
    public static Account getAccountFromMdmId(String mdmId){
        Account account;
        List<Account> accounts = [SELECT id, Name FROM Account WHERE Numero_de_Conta__c =: mdmId];
        if(accounts.isEmpty()){
            account = [SELECT id, Name FROM Account WHERE name = 'DEFAULT PIXIS ACCOUNT' LIMIT 1 ];
        }
        else{account = accounts[0];}
        return account;
    }
    
    public static void setUser(List <SObject> records, Map<String, String> sourceFields){
        String objType = String.valueOf(records.getSObjectType());
        Map<Id, String> createdByLdapMap = new Map<Id, String>();
        Map<Id, String> lastModifiedByLdapMap = new Map<Id, String>();
        Map<Id, String> internalMessageCreatedByLdapMap = new Map<Id, String>();
        
        for (SObject record : records) {
            if (sourceFields.containsKey('CreatedByUser__c')) {
                String fieldName = sourceFields.get('CreatedByUser__c');
                if (record.get(fieldName) != null) {
                    createdByLdapMap.put(record.Id, String.valueOf(record.get(fieldName)));
                }
            }
            if (sourceFields.containsKey('LastModifiedByUser__c')) {
                String fieldName = sourceFields.get('LastModifiedByUser__c');
                if (record.get(fieldName) != null) {
                    lastModifiedByLdapMap.put(record.Id, String.valueOf(record.get(fieldName)));
                }
            }
            if (sourceFields.containsKey('InternalMessageCreatedBy__c')) {
                String fieldName = sourceFields.get('InternalMessageCreatedBy__c');
                if (record.get(fieldName) != null) {
                    internalMessageCreatedByLdapMap.put(record.Id, String.valueOf(record.get(fieldName)));
                }
            }
        }
        
        Set<String> allLdaps = new Set<String>();
        allLdaps.addAll(createdByLdapMap.values());
        allLdaps.addAll(lastModifiedByLdapMap.values());
        allLdaps.addAll(internalMessageCreatedByLdapMap.values());
        User defaultUser = [SELECT id, Name FROM User WHERE Name = 'Pyxis Integration User' LIMIT 1 ]; // dev: Integration User, uat: Pyxis Integration User
        List<User> users = [SELECT id, LDAP__c FROM User WHERE LDAP__c IN :allLdaps];
        
        Map<String, User> ldapUserMap = new Map<String, User>();
        for (User u : users) {
            ldapUserMap.put(u.LDAP__c, u);
        }
        
        List<SObject> recordsToUpdate = new List<SObject>();
        for(SObject recordToSetUser : records){
            if((objType == 'Order' || objType == 'Quote' || objType == 'OrderItem')){
                String createdLdap = createdByLdapMap.get(recordToSetUser.Id);
                if(ldapUserMap.containsKey(createdLdap)){
                    recordToSetUser.put('CreatedByUser__c', ldapUserMap.get(createdLdap).Id);
                } else {
                    recordToSetUser.put('CreatedByUser__c', defaultUser.Id);
                }
            }
            if(objType == 'OrderItem'){
                String modifiedLdap = lastModifiedByLdapMap.get(recordToSetUser.Id);
                if(ldapUserMap.containsKey(modifiedLdap)){
                    recordToSetUser.put('LastModifiedByUser__c', ldapUserMap.get(modifiedLdap).Id);
                } else {
                    recordToSetUser.put('LastModifiedByUser__c', defaultUser.Id);
                }
            }
            if (objType == 'Quote' || objType == 'Order') {
                String internalLdap = internalMessageCreatedByLdapMap.get(recordToSetUser.Id);
                if (ldapUserMap.containsKey(internalLdap)) {
                    recordToSetUser.put('InternalMessageCreatedBy__c',ldapUserMap.get(internalLdap).Id);
                } else {
                    recordToSetUser.put('InternalMessageCreatedBy__c', defaultUser.Id);
                }
            }
            recordsToUpdate.add(recordToSetUser);
        }
        update recordsToUpdate;
    }
    
    //**************************************************************************************************************
    //************************************************* CLASS WRAPPER **********************************************
    //**************************************************************************************************************
    
    //CUSTOMER REQUEST WRAPPER
    public class CustomerWrapper{
        public String name;
        public String mdmId;
        public String email;
    }
    
    //SUCCESSFULLY PYXIS RESPONDE PAYLOAD RESPONSE
    public class PyxisResponderWrapper{
        public Datetime dateTimeProcess;
        public List<SObject> recordsCreate;
        public Integer statusCode;
        public ErrorRequestWrapper error;
        
        public PyxisResponderWrapper(List<SObject> recordsCreate, Integer statusCode){
            this.dateTimeProcess = System.now();
            this.recordsCreate = recordsCreate;
            this.statusCode = statusCode;
        }
        public PyxisResponderWrapper(ErrorRequestWrapper error, Integer statusCode){
            this.error = error;
            this.statusCode = statusCode;
            this.dateTimeProcess = System.now();
        }
    }
    
    //ERROR MESSAGE PAYLOAD RESPONSE
    public class ErrorRequestWrapper{
        public String errorMessage;
        public String detailAction;
        
        public ErrorRequestWrapper(String errorMessage, String detailAction){
            this.errorMessage = errorMessage;
            this.detailAction = detailAction;
        }
    }
    
    // ORDER CODE 49 WRAPPER
    public class OrderCode49Wrapper {
        public Boolean isTransformation;
        public String code;
        public String sourceQuote;
        public Opportunity opp;
        public List<String> quotesIds;
        
        public OrderCode49Wrapper(Boolean isTransformation, String code, String sourceQuote, Opportunity opp, List<String> quotesIds){
            this.isTransformation = isTransformation;
            this.code = code;
            this.sourceQuote = sourceQuote;
            this.opp = opp;
            this.quotesIds = quotesIds;
        }
    }
    
    // PRICEBOOk, PRODUCT AND PRICEBOOKENTRY WRAPPER
    public class PriceBookInfoWrapper{
        public Id pricebookId;
        public Id pricebookEntry;
        public id productId;
        
        public PriceBookInfoWrapper( Id pricebookId, Id productId, Id pricebookEntry){
            this.pricebookId = pricebookId;
            this.productId = productId;
            this.pricebookEntry = pricebookEntry;
        }
    }
}