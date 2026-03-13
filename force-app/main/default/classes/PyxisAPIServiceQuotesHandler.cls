/**
 * @description       : Pyxis Request Quotes Handler
 * @author            : miguel.lopes
 * @group             :
 * @create date on    : 2025-10-21 14:29:02
 * @last modified by  : Hersilio Belini de Oliveira
 **/
public with sharing class PyxisAPIServiceQuotesHandler {
    
    private static Map<String, Object> FIELDS_MAPPING_QUOTES = PyxisAPIServiceHandler.getfieldsMapping('Quote');
    
    public static PyxisAPIServiceHandler.PyxisResponderWrapper createQuotesRequest(String payloadBody){
        SavePoint savepoint = Database.setSavepoint();
        try{
            QuotesRequestWrapper fullResponseBody = new QuotesRequestValidator().parse(payloadBody);
            String externalId = fullResponseBody.externalId;
            String mdmId = PyxisAPIServiceHandler.getMdmIdCustomer(payloadBody);
            String store = fullResponseBody.quotes[0].store;
            Account account = PyxisAPIServiceHandler.getAccountFromMdmId(mdmId);
            Map<String, Object> requestInfo = new Map<String, Object>{
                'mdmId' => mdmId,
                'store' => store,
                'account' => (Account)account,
                'externalId' => externalId,
                'oppState' => 'Pedido de Orçamento'
            };
            Map<String, Opportunity> quoteToOppMap = getChildRecordMap(fullResponseBody, mdmId);
            if(quoteToOppMap.isEmpty()){
                Opportunity oppRecord = PyxisAPIServiceHandler.checkOppSameDay(requestInfo);
                quoteToOppMap.put('NEW_OPP', oppRecord);
            }
            List<SObject> quotesInserted = createQuotes(fullResponseBody.quotes, quoteToOppMap, mdmId);
            
            PyxisAPIServiceHandler.PyxisResponderWrapper payloadResponse = new PyxisAPIServiceHandler.PyxisResponderWrapper(quotesInserted, 201);
            return payloadResponse;
        } catch (ApiParseUtil.InvalidPayloadException e) {
            Database.rollback(savepoint);
            PyxisAPIServiceHandler.ErrorRequestWrapper error  = new PyxisAPIServiceHandler.ErrorRequestWrapper(e.getMessage(), e.getStackTraceString());
            PyxisAPIServiceHandler.PyxisResponderWrapper payloadResponse = new PyxisAPIServiceHandler.PyxisResponderWrapper(error, 400);
            return payloadResponse;
        } catch (Exception e) {
            Database.rollback(savepoint);
            PyxisAPIServiceHandler.ErrorRequestWrapper error  = new PyxisAPIServiceHandler.ErrorRequestWrapper(e.getMessage(), e.getStackTraceString());
            PyxisAPIServiceHandler.PyxisResponderWrapper payloadResponse = new PyxisAPIServiceHandler.PyxisResponderWrapper(error, 500);
            return payloadResponse;
        }
    }
    
    /**
     * @description : Create Quotes Records
     * param        : quotesList: List of Quotes from Payload
     * param        : opportunityId: Opportunity Id related to the Quotes
     * return       : List<SObject> with the Created Quotes Records
     **/
    private static List<SObject> createQuotes(List<QuotesWrapper> quotesList, Map<String, Opportunity> quoteToOppMap, String mdmId){
        String recordTypeApiName = [SELECT RecordTypeAPIName__c FROM Pyxis_Integration_Mapping__mdt WHERE Object_API_Name__c =: 'Quote' LIMIT 1].RecordTypeAPIName__c;
        List<Quote> newQuotes = new List<Quote>();
        
        for ( QuotesWrapper quotesRequest : quotesList) {
            Quote newQuote = new Quote();
            String uniqueKey = quotesRequest.store+'_'+mdmId+'_'+quotesRequest.quoteNumber;
            
            for (String key : FIELDS_MAPPING_QUOTES.keySet()) {
                String fieldApiName = String.valueOf(key);
                Object fieldValue = quotesRequest.getValue(String.valueOf(FIELDS_MAPPING_QUOTES.get(key)));
                newQuote.put(fieldApiName, fieldValue);
                
            }
            // SYSTEM FIELDS
            newQuote.put('OpportunityId', quoteToOppMap.get('NEW_OPP') != NULL ? quoteToOppMap.get('NEW_OPP').Id : quoteToOppMap.get(uniqueKey).Id);
            newQuote.put('Pyxis_Unique_Id__c', uniqueKey);
            newQuote.put('Name', quotesRequest.quoteNumber);
            newQuote.put('Pricebook2Id', PyxisAPIServiceHandler.PRICE_BOOK_INFO.pricebookId);
            newQuote.put('RecordTypeId', PyxisAPIServiceHandler.getRecordTypeIdByApiName('Quote', recordTypeApiName));
            newQuotes.add(newQuote);
            
        }
        upsert newQuotes Pyxis_Unique_Id__c;
        // PyxisAPIServiceAssyncJobs.PyxisAssyncJobsWrapper jobParams = new PyxisAPIServiceAssyncJobs.PyxisAssyncJobsWrapper(newQuotes, quoteToOppMap.values(), null);
        // System.enqueueJob(new PyxisAPIServiceAssyncJobs('QUOTES', jobParams));
        PyxisAPIServiceHandler.checkExpiredQuotes(quoteToOppMap.values());
        PyxisAPIServiceHandler.setStoreId(newQuotes);
        PyxisAPIServiceHandler.setUser(newQuotes, new Map <String, String>{ 
            'CreatedByUser__c' => 'LDAPcreatedByUser__c',
            'InternalMessageCreatedBy__c' => 'InternalMessageCreatedBy_LDAP__c'
        });
        
        // CHECK FOR QUOTE LINE ITEMS TO CREATE
        Map<Quote, List<QuoteLineItemsWrapper>> quoteLineItemsToAdd = new Map<Quote, List<QuoteLineItemsWrapper>>();
        for (Quote quoteRecord : newQuotes) {
            QuotesWrapper relatedQuote = quotesList[newQuotes.indexOf(quoteRecord)];
            
            if (relatedQuote.quoteLineItems.isEmpty()) break;
            
            if (!quoteLineItemsToAdd.containsKey(quoteRecord)) {
                quoteLineItemsToAdd.put(quoteRecord, new List<QuoteLineItemsWrapper>());
            }
            for (QuoteLineItemsWrapper lineItem : relatedQuote.quoteLineItems) {
                quoteLineItemsToAdd.get(quoteRecord).add(lineItem);
            }
        }
        createQuoteLineItems(quoteLineItemsToAdd);
        return newQuotes;
    }
    
    public static void createQuoteLineItems(Map<Quote, List<QuoteLineItemsWrapper>> quoteLineItems){
        Map<String, Object> FIELDS_MAPPING_QUOTE_LINE_ITEMS = PyxisAPIServiceHandler.getfieldsMapping('Quote_Line_Item');
        List<QuoteLineItem> newLineItems = new List<QuoteLineItem>();
        
        for (Quote quote : quoteLineItems.keySet()) {
            List<QuoteLineItemsWrapper> lineItemWrappers = quoteLineItems.get(quote);
            
            for (QuoteLineItemsWrapper wrapper : lineItemWrappers) {
                QuoteLineItem newLineItem = new QuoteLineItem();
                
                String uniqueKey = wrapper.transformStore + '_' + wrapper.productReferenceEan + '_' + quote.ExternalQuoteNumber__c + '_' + wrapper.lineNumber;
                
                for (String field : FIELDS_MAPPING_QUOTE_LINE_ITEMS.keySet()) {
                    String fieldApiName = String.valueOf(field);
                    Object fieldValue = wrapper.getValue(String.valueOf(FIELDS_MAPPING_QUOTE_LINE_ITEMS.get(field)));
                    newLineItem.put(fieldApiName, fieldValue);
                }
                // SYSTEM FIELDS
                newLineItem.put('QuoteId', quote.Id);
                newLineItem.put('Pyxis_Unique_Id__c', uniqueKey);
                newLineItem.put('Product2Id', PyxisAPIServiceHandler.PRICE_BOOK_INFO.productId);
                newLineItem.put('PricebookEntryId', PyxisAPIServiceHandler.PRICE_BOOK_INFO.pricebookEntry);
                newLineItems.add(newLineItem);
            }
        }
        upsert newLineItems Pyxis_Unique_Id__c;
        // PyxisAPIServiceAssyncJobs.PyxisAssyncJobsWrapper jobParams = new PyxisAPIServiceAssyncJobs.PyxisAssyncJobsWrapper(newLineItems, null, null);
        // System.enqueueJob(new PyxisAPIServiceAssyncJobs('QUOTE_LINES_ITEMS', jobParams));
        PyxisAPIServiceHandler.setStoreId(newLineItems);
    }
    
    public static Map<String, Opportunity> getChildRecordMap( Object wrapper, String mdmId){
        Set<String> uniqueKeys = new Set<String>();
        PyxisAPIServiceQuotesHandler.QuotesRequestWrapper quotesWrapper = (PyxisAPIServiceQuotesHandler.QuotesRequestWrapper)wrapper;
        List<PyxisAPIServiceQuotesHandler.QuotesWrapper> quotes = quotesWrapper.quotes;
        for (PyxisAPIServiceQuotesHandler.QuotesWrapper quote : quotesWrapper.quotes) {
            uniqueKeys.add(quote.store + '_' + mdmId + '_' + quote.quoteNumber);
        }

        Map<String, Opportunity> childRecsToOppId = new Map<String, Opportunity>();
        List<Quote> existingChildRecords = [SELECT Id, Pyxis_Unique_Id__c FROM Quote WHERE Pyxis_Unique_Id__c IN : uniqueKeys];
        Set<String> existingUniqueKeys = new Set<String>();
        if(!existingChildRecords.isEmpty()){
            for(Quote childRecord : existingChildRecords){
                existingUniqueKeys.add(childRecord.Pyxis_Unique_Id__c);
            }
        }
        List<Opportunity> oppschildRecords = [SELECT Id, (SELECT Id, Pyxis_Unique_Id__c FROM Quotes)
                                              FROM Opportunity 
                                              WHERE Id IN (SELECT OpportunityId FROM Quote WHERE Pyxis_Unique_Id__c IN : existingUniqueKeys)];
        for(Opportunity opp : oppschildRecords){
            if(opp.Quotes != null){
                for( Quote quote : opp.Quotes){
                    childRecsToOppId.put(quote.Pyxis_Unique_Id__c, opp);
                }
            }
        }
        return childRecsToOppId;
    }
    
    //**************************************************************************************************************
    //************************************************* VALIDATION LAYER *******************************************
    //**************************************************************************************************************
    
    private class QuotesRequestValidator{
        public QuotesRequestWrapper parse(String payloadBody){
            QuotesRequestWrapperString rawWrapper = (QuotesRequestWrapperString) JSON.deserialize(payloadBody, QuotesRequestWrapperString.class);
            if(rawWrapper == null){
                throw new ApiParseUtil.InvalidPayloadException('Payload vazio ou inválido.');
            }
            
            List<QuotesWrapper> typedQuotes = new List<QuotesWrapper>();
            if(rawWrapper.quotes != null){
                for(QuotesWrapperString quoteString : rawWrapper.quotes){
                    List<QuoteLineItemsWrapper> typedLineItems = new List<QuoteLineItemsWrapper>();
                    if(quoteString.quoteLineItems != null){
                        for(QuoteLineItemsWrapperString lineItemString : quoteString.quoteLineItems){
                            typedLineItems.add(new QuoteLineItemsWrapper(
                                ApiParseUtil.parseInteger(lineItemString.lineNumber, 'quoteLineItems.lineNumber'),
                            ApiParseUtil.checkIfNull(lineItemString.productReferenceEan, 'quoteLineItems.productReferenceEan'),
                            lineItemString.productName,
                            ApiParseUtil.parseDecimal(lineItemString.stockQuantity, 'quoteLineItems.stockQuantity'),
                            ApiParseUtil.parseDecimal(lineItemString.pdo, 'quoteLineItems.pdo'),
                            lineItemString.itemStatus,
                            ApiParseUtil.parseDecimal(lineItemString.unitPrice, 'quoteLineItems.unitPrice'),
                            ApiParseUtil.parseDecimal(lineItemString.discountPercent, 'quoteLineItems.discountPercent'),
                            ApiParseUtil.parseDecimal(lineItemString.totalAmount, 'quoteLineItems.totalAmount'),
                            lineItemString.section,
                            lineItemString.subsection,
                            lineItemString.type,
                            lineItemString.subtype,
                            lineItemString.nomenclature,
                            lineItemString.supplier,
                            lineItemString.transformChannel,
                            lineItemString.transformTransaction,
                            lineItemString.transformStore
                                ));
                        }
                    }
                    
                    typedQuotes.add(new QuotesWrapper(
                        quoteString.store,
                    ApiParseUtil.parseDatetime(quoteString.createdDate, 'quotes.createdDate'),
                    quoteString.quoteNumber,
                    quoteString.createdByUser,
                    quoteString.creationChannel,
                    quoteString.state,
                    ApiParseUtil.parseDatetime(quoteString.quoteExpirationDate, 'quotes.quoteExpirationDate'),
                    quoteString.quoteStatus,
                    ApiParseUtil.parseDatetime(quoteString.internalMessageCreatedDate, 'quotes.internalMessageCreatedDate'),
                    quoteString.internalMessageCreatedBy,
                    quoteString.internalMessageText,
                    typedLineItems
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
            return new QuotesRequestWrapper(rawWrapper.externalId, customerWrapper, typedQuotes);
        }
    }
    
    // CLONE STRING-BASED WRAPPERS FOR PAYLOAD VALIDATION
    public class QuotesRequestWrapperString{
        public String externalId;
        public CustomerWrapperString customer;
        public List<QuotesWrapperString> quotes;
    }
    
    public class QuotesWrapperString{
        public String store;
        public String createdDate;
        public String quoteNumber;
        public String createdByUser;
        public String creationChannel;
        public String state;
        public String quoteExpirationDate;
        public String quoteStatus;
        public String internalMessageCreatedDate;
        public String internalMessageCreatedBy;
        public String internalMessageText;
        public List<QuoteLineItemsWrapperString> quoteLineItems;
    }
    
    public class QuoteLineItemsWrapperString{
        public String lineNumber;
        public String productReferenceEan;
        public String productName;
        public String stockQuantity;
        public String pdo;
        public String itemStatus;
        public String unitPrice;
        public String discountPercent;
        public String totalAmount;
        public String section;
        public String subsection;
        public String type;
        public String subtype;
        public String nomenclature;
        public String supplier;
        public String transformChannel;
        public String transformTransaction;
        public String transformStore;
    }
    
    public class CustomerWrapperString{
        public String name;
        public String mdmId;
        public String email;
    }
    
    //**************************************************************************************************************
    //************************************************* QUOTES WRAPPER *********************************************
    //**************************************************************************************************************
    
    //QUOTES_REQUEST WRAPPER
    public class QuotesRequestWrapper{
        private String externalId;
        private PyxisAPIServiceHandler.CustomerWrapper customer;
        public List<QuotesWrapper> quotes;
        
        public QuotesRequestWrapper(String externalId, PyxisAPIServiceHandler.CustomerWrapper customer, List<QuotesWrapper> quotes){
            this.externalId = externalId;
            this.customer = customer;
            this.quotes = quotes;
        }
    }
    
    //QUOTES WRAPPER
    public class QuotesWrapper{
        public String store;
        private Datetime createdDate;
        public String quoteNumber;
        private String createdByUser;
        private String creationChannel;
        private String state;
        private Datetime quoteExpirationDate;
        private String quoteStatus;
        private Datetime internalMessageCreatedDate;
        private String internalMessageCreatedBy;
        private String internalMessageText;
        private List<QuoteLineItemsWrapper> quoteLineItems;
        
        public QuotesWrapper(String store, Datetime createdDate, String quoteNumber, String createdByUser, String creationChannel,
        String state, Datetime quoteExpirationDate, String quoteStatus, Datetime internalMessageCreatedDate,
        String internalMessageCreatedBy, String internalMessageText, List<QuoteLineItemsWrapper> quoteLineItems){
            this.store = store;
            this.createdDate = createdDate;
            this.quoteNumber = quoteNumber;
            this.createdByUser = createdByUser;
            this.creationChannel = creationChannel;
            this.state = state;
            this.quoteExpirationDate = quoteExpirationDate;
            this.quoteStatus = quoteStatus;
            this.internalMessageCreatedDate = internalMessageCreatedDate;
            this.internalMessageCreatedBy = internalMessageCreatedBy;
            this.internalMessageText = internalMessageText;
            this.quoteLineItems = quoteLineItems;
        }
        
        public Object getValue(String fieldName) {
            switch on fieldName {
                when 'store'                        { return store; }
                when 'createdDate'                  { return createdDate; }
                when 'quoteNumber'                  { return quoteNumber; }
                when 'createdByUser'                { return createdByUser; }
                when 'creationChannel'              { return creationChannel; }
                when 'state'                        { return state; }
                when 'quoteExpirationDate'          { return quoteExpirationDate; }
                when 'quoteStatus'                  { return quoteStatus; }
                when 'internalMessageCreatedDate'   { return internalMessageCreatedDate; }
                when 'internalMessageCreatedBy'     { return internalMessageCreatedBy; }
                when 'internalMessageText'          { return internalMessageText; }
                when 'quoteLineItems'               { return quoteLineItems; }
                when else                           { return null; }
            }
        }
    }
    
    //QUOTES LINE ITEMS WRAPPER
    public class QuoteLineItemsWrapper{
        private Integer lineNumber;
        private String productReferenceEan;
        private String productName;
        private Decimal stockQuantity;
        private Decimal pdo;
        private String itemStatus;
        private Decimal unitPrice;
        private Decimal discountPercent;
        private Decimal totalAmount;
        private String section;
        private String subsection;
        private String type;
        private String subtype;
        private String nomenclature;
        private String supplier;
        private String transformChannel;
        private String transformTransaction;
        private String transformStore;
        
        public QuoteLineItemsWrapper(Integer lineNumber, String productReferenceEan, String productName, Decimal stockQuantity, Decimal pdo, String itemStatus,
        Decimal unitPrice, Decimal discountPercent, Decimal totalAmount, String section, String subsection,
        String type, String subtype, String nomenclature, String supplier, String transformChannel,
        String transformTransaction, String transformStore){
            this.lineNumber = lineNumber;
            this.productReferenceEan = productReferenceEan;
            this.productName = productName;
            this.stockQuantity = stockQuantity;
            this.pdo = pdo;
            this.itemStatus = itemStatus;
            this.unitPrice = unitPrice;
            this.discountPercent = discountPercent;
            this.totalAmount = totalAmount;
            this.section = section;
            this.subsection = subsection;
            this.type = type;
            this.subtype = subtype;
            this.nomenclature = nomenclature;
            this.supplier = supplier;
            this.transformChannel = transformChannel;
            this.transformTransaction = transformTransaction;
            this.transformStore = transformStore;
        }
        
        public Object getValue(String fieldName) {
            switch on fieldName {
                when 'lineNumber'             { return lineNumber; }
                when 'productReferenceEan'    { return productReferenceEan; }
                when 'productName'            { return productName; }
                when 'stockQuantity'          { return stockQuantity; }
                when 'pdo'                    { return pdo; }
                when 'itemStatus'             { return itemStatus; }
                when 'unitPrice'              { return unitPrice; }
                when 'discountPercent'        { return discountPercent; }
                when 'totalAmount'            { return totalAmount; }
                when 'section'                { return section; }
                when 'subsection'             { return subsection; }
                when 'type'                   { return type; }
                when 'subtype'                { return subtype; }
                when 'nomenclature'           { return nomenclature; }
                when 'supplier'               { return supplier; }
                when 'transformChannel'       { return transformChannel; }
                when 'transformTransaction'   { return transformTransaction; }
                when 'transformStore'         { return transformStore; }
                when else                     { return null; }
            }
        }
    }
}