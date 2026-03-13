/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 *
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class PyxisTransactionsTest {
    
    public static String quotePayload =
        '{'+
        '    "externalId":"260516",'+
        '    "customer":{'+
        '        "name":"TEST ACCOUNT",'+
        '        "number":"123346",'+
        '        "email":"ml@gmail.com"'+
        '   },'+
        '    "quotes":['+
        '        {'+
        '         "store":"004",'+
        '         "createdDate":"2025-10-31T14:30:00Z",'+
        '         "quoteNumber":"267898",'+
        '         "createdByUser":"9001074112",'+
        '         "creationChannel":"Valor",'+
        '         "state":"100",'+
        '         "quoteExpirationDate":"2025-10-31T14:30:00Z",'+
        '         "quoteStatus":"100",'+
        '         "internalMessageCreatedDate":"2025-10-31T14:30:00Z",'+
        '         "internalMessageCreatedBy":"9001074112",'+
        '         "internalMessageText":"FROM Postman API Callout",'+
        '         "quoteLineItems":['+
        '            {'+
        '               "lineNumber":"0",'+
        '               "productReferenceEan":"01t8d0000086DFLAA2",'+
        '               "productName":"2 lâminas 5-50 mm Dexter CLEAN CUT",'+
        '               "stockQuantity":"3",'+
        '               "pdo":"15",'+
        '               "amountIncludingVAT":"50",'+
        '               "itemStatus":"100",'+
        '               "unitPrice":"14",'+
        '               "discountPercent":"20.5",'+
        '               "totalAmount":"10.4",'+
        '               "section":"Valor",'+
        '               "subsection":"Valor",'+
        '               "type":"PF",'+
        '               "subtype":"Valor",'+
        '               "nomenclature":"TEST Nomeclature",'+
        '               "supplier":"10.4",'+
        '               "transformChannel":"TEST Tranform Channel",'+
        '               "transformTransaction":"TEST Transform Transaction",'+
        '               "transformStore":"004"'+
        '            },'+
        '            {'+
        '               "lineNumber":"1",'+
        '               "productReferenceEan":"01t8d0000086DGTAA2",'+
        '               "productName":"10 lixas 93X93MM",'+
        '               "stockQuantity":"3",'+
        '               "pdo":"15",'+
        '               "itemStatus":"100",'+
        '               "unitPrice":"14",'+
        '               "discountPercent":"20.5",'+
        '               "totalAmount":"10.4",'+
        '               "section":"Valor",'+
        '               "subsection":"Valor",'+
        '               "type":"PF",'+
        '               "subtype":"Valor",'+
        '               "nomenclature":"TEST Nomeclature",'+
        '               "supplier":"10.4",'+
        '               "transformChannel":"TEST Tranform Channel",'+
        '               "transformTransaction":"TEST Transform Transaction",'+
        '               "transformStore":"004"'+
        '            }'+
        '         ]'+
        '      }'+
        '   ]'+
        '}';

    public static String quotePayload_v2 =
        '{'+
        '    "externalId":"260516",'+
        '    "customer":{'+
        '        "name":"TEST ACCOUNT",'+
        '        "number":"123346",'+
        '        "email":"ml@gmail.com"'+
        '   },'+
        '    "quotes":['+
        '        {'+
        '         "store":"004",'+
        '         "createdDate":"2025-10-31T14:30:00Z",'+
        '         "quoteNumber":"267898",'+
        '         "createdByUser":"0058d000008aV4JAAU",'+
        '         "creationChannel":"Valor",'+
        '         "state":"140",'+
        '         "quoteExpirationDate":"2025-10-31T14:30:00Z",'+
        '         "quoteStatus":"140",'+
        '         "internalMessageCreatedDate":"2025-10-31T14:30:00Z",'+
        '         "internalMessageCreatedBy":"Postman Tester User",'+
        '         "internalMessageText":"FROM Postman API Callout",'+
        '         "quoteLineItems":['+
        '            {'+
        '               "lineNumber":"0",'+
        '               "productReferenceEan":"01t8d0000086DFLAA2",'+
        '               "productName":"2 lâminas 5-50 mm Dexter CLEAN CUT",'+
        '               "stockQuantity":"3",'+
        '               "pdo":"15",'+
        '               "itemStatus":"140",'+
        '               "unitPrice":"14",'+
        '               "discountPercent":"20.5",'+
        '               "totalAmount":"10.4",'+
        '               "section":"Valor",'+
        '               "subsection":"Valor",'+
        '               "type":"PF",'+
        '               "subtype":"Valor",'+
        '               "nomenclature":"TEST Nomeclature",'+
        '               "supplier":"10.4",'+
        '               "transformChannel":"TEST Tranform Channel",'+
        '               "transformTransaction":"TEST Transform Transaction",'+
        '               "transformStore":"004"'+
        '            },'+
        '            {'+
        '               "lineNumber":"1",'+
        '               "productReferenceEan":"01t8d0000086DGTAA2",'+
        '               "productName":"10 lixas 93X93MM",'+
        '               "stockQuantity":"3",'+
        '               "pdo":"15",'+
        '               "itemStatus":"140",'+
        '               "unitPrice":"14",'+
        '               "discountPercent":"20.5",'+
        '               "totalAmount":"10.4",'+
        '               "section":"Valor",'+
        '               "subsection":"Valor",'+
        '               "type":"PF",'+
        '               "subtype":"Valor",'+
        '               "nomenclature":"TEST Nomeclature",'+
        '               "supplier":"10.4",'+
        '               "transformChannel":"TEST Tranform Channel",'+
        '               "transformTransaction":"TEST Transform Transaction",'+
        '               "transformStore":"004"'+
        '            }'+
        '         ]'+
        '      }'+
        '   ]'+
        '}';

    public static String orderPayloadFromTransformation =
        '{'+
        '    "externalId":"260516",'+
        '    "customer":{'+
        '        "name":"TEST ACCOUNT",'+
        '        "number":"123346",'+
        '        "email":"ml@gmail.com"'+
        '   },'+
        '   "productOrders":[' +
        '      {' +
        '         "customerName":"TEST",' +
        '         "customerNumber":"TEST",' +
        '         "customerEmail":"TEST",' +
        '         "orderNumber":"21122",' +
        '         "store":"004",' +
        '         "createdDate":"2025-11-11T15:45:00.000Z",' +
        '         "availableDate":"2025-11-11T15:45:00.000Z",' +
        '         "totalWithVat":"150",' +
        '         "createdByUser":"9001074112",' +
        '         "creationChannel":"Valor",' +
        '         "orderStatus":"10",' +
        '         "depositTotal":"20.5",' +
        '         "depositRemaining":"20.45",' +
        '         "shippedFrom":"004",' +
        '         "deliveryDate":"2025-11-11T15:45:00.000Z",' +
        '         "internalMessageCreatedDate":"2025-11-03T15:45:00.000Z",' +
        '         "internalMessageCreatedBy":"9001074112",' +
        '         "internalMessageText":"TEST interal Message",' +
        '         "eligibleForReducedVat":false,' +
        '         "orderItems":[' +
        '            {' +
        '               "lineNumber":"0",' +
        '               "productReferenceEan":"01u8d00000FfqqcAAB",' +
        '               "productName":"2 lâminas 5-50 mm Dexter CLEAN CUT",' +
        '               "stockQuantity":"20",' +
        '               "itemType":"Valor",' +
        '               "itemStatus":"10",' +
        '               "availableDate":"2025-11-03T15:45:00.000Z",' +
        '               "sourceQuoteNumber":"267898",' +
        '               "unitPrice":"25.5",' +
        '               "discountPercent":"12.5",' +
        '               "pdo":"12",' +
        '               "amountIncludingVAT":"50",'+
        '               "lineComplementDescription":"TEST Desc",' +
        '               "supplierOrderNumber":"TEST Supplie Ord Num",' +
        '               "address":"Location 1",' +
        '               "pickupLocation":"004",' +
        '               "createdByUser":"9001074112",' +
        '               "lastModifiedByUser":"9001074112",' +
        '               "codeSection":"7",' +
        '               "codeSubsection":"8",' +
        '               "codeType":"8",' +
        '               "codeSubtype":"9",' +
        '               "nomenclature":"TEST",' +
        '               "sourceChannel":"Valor",' +
        '               "sourceTransaction":"Valor",' +
        '               "sourceStore":"004"' +
        '            },' +
        '            {' +
        '               "lineNumber":"1",' +
        '               "productReferenceEan":"01u8d00000FfqrfAAB",' +
        '               "productName":"10 lixas 93X93MM",' +
        '               "stockQuantity":"20",' +
        '               "itemType":"Valor",' +
        '               "itemStatus":"40",' +
        '               "availableDate":"2025-11-03T15:45:00.000Z",' +
        '               "sourceQuoteNumber":"267898",' +
        '               "unitPrice":"555.5",' +
        '               "discountPercent":"12.5",' +
        '               "pdo":"12",' +
        '               "lineComplementDescription":"TEST Desc",' +
        '               "supplierOrderNumber":"TEST Supplie Ord Num",' +
        '               "address":"Location 1",' +
        '               "pickupLocation":"004",' +
        '               "createdByUser":"9001074112",' +
        '               "lastModifiedByUser":"9001074112",' +
        '               "codeSection":"Valor",' +
        '               "codeSubsection":"Valor",' +
        '               "codeType":"Valor",' +
        '               "codeSubtype":"Valor",' +
        '               "nomenclature":"TEST",' +
        '               "sourceChannel":"Valor",' +
        '               "sourceTransaction":"Valor",' +
        '               "sourceStore":"004"' +
        '            }' +
        '         ]' +
        '      }' +
        '   ]' +
        '}';

    public static String orderPayloadFromTransformationError =
        '{'+
        '    "externalId":"260516",'+
        '    "customer":{'+
        '        "name":"TEST ACCOUNT",'+
        '        "number":"123346",'+
        '        "email":"ml@gmail.com"'+
        '   },'+
        '   "productOrders":[' +
        '      {' +
        '         "customerName":"TEST",' +
        '         "customerNumber":"TEST",' +
        '         "customerEmail":"TEST",' +
        '         "orderNumber":"21122989",' +
        '         "store":"004",' +
        '         "createdDate":"2025-11-11T15:45:00.000Z",' +
        '         "availableDate":"2025-11-11T15:45:00.000Z",' +
        '         "totalWithVat":"150",' +
        '         "createdByUser":"9001074112",' +
        '         "creationChannel":"Valor",' +
        '         "orderStatus":"40",' +
        '         "depositTotal":"20.5",' +
        '         "depositRemaining":"20.45",' +
        '         "shippedFrom":"004",' +
        '         "deliveryDate":"2025-11-11T15:45:00.000Z",' +
        '         "internalMessageCreatedDate":"2025-11-03T15:45:00.000Z",' +
        '         "internalMessageCreatedBy":"9001074112",' +
        '         "internalMessageText":"TEST interal Message",' +
        '         "eligibleForReducedVat":false,' +
        '         "orderItems":[' +
        '            {' +
        '               "lineNumber":"0",' +
        '               "productReferenceEan":"01u8d00000FfqqcAAB",' +
        '               "productName":"2 lâminas 5-50 mm Dexter CLEAN CUT",' +
        '               "stockQuantity":"20",' +
        '               "itemType":"Valor",' +
        '               "itemStatus":"40",' +
        '               "availableDate":"2025-11-03T15:45:00.000Z",' +
        '               "sourceQuoteNumber":"267898987678",' +
        '               "unitPrice":"25.5",' +
        '               "discountPercent":"12.5",' +
        '               "pdo":"12",' +
        '               "amountIncludingVAT":"50",'+
        '               "lineComplementDescription":"TEST Desc",' +
        '               "supplierOrderNumber":"TEST Supplie Ord Num",' +
        '               "address":"Location 1",' +
        '               "pickupLocation":"004",' +
        '               "createdByUser":"9001074112",' +
        '               "lastModifiedByUser":"9001074112",' +
        '               "codeSection":"7",' +
        '               "codeSubsection":"8",' +
        '               "codeType":"8",' +
        '               "codeSubtype":"9",' +
        '               "nomenclature":"TEST",' +
        '               "sourceChannel":"Valor",' +
        '               "sourceTransaction":"Valor",' +
        '               "sourceStore":"004"' +
        '            },' +
        '            {' +
        '               "lineNumber":"1",' +
        '               "productReferenceEan":"01u8d00000FfqrfAAB",' +
        '               "productName":"10 lixas 93X93MM",' +
        '               "stockQuantity":"20",' +
        '               "itemType":"Valor",' +
        '               "itemStatus":"40",' +
        '               "availableDate":"2025-11-03T15:45:00.000Z",' +
        '               "sourceQuoteNumber":"267898987678",' +
        '               "unitPrice":"555.5",' +
        '               "discountPercent":"12.5",' +
        '               "pdo":"12",' +
        '               "lineComplementDescription":"TEST Desc",' +
        '               "supplierOrderNumber":"TEST Supplie Ord Num",' +
        '               "address":"Location 1",' +
        '               "pickupLocation":"004",' +
        '               "createdByUser":"9001074112",' +
        '               "lastModifiedByUser":"9001074112",' +
        '               "codeSection":"Valor",' +
        '               "codeSubsection":"Valor",' +
        '               "codeType":"Valor",' +
        '               "codeSubtype":"Valor",' +
        '               "nomenclature":"TEST",' +
        '               "sourceChannel":"Valor",' +
        '               "sourceTransaction":"Valor",' +
        '               "sourceStore":"004"' +
        '            }' +
        '         ]' +
        '      }' +
        '   ]' +
        '}';

    public static String incorrectOrderPayload =
        '{'+
        '    "externalId":"260516",'+
        '    "customer":{'+
        '        "name":"TEST ACCOUNT",'+
        '        "number":"123346",'+
        '        "email":"ml@gmail.com"'+
        '   },'+
        '   "productOrders":[' +
        '      {' +
        '         "customerName":"TEST",' +
        '         "customerNumber":"TEST",' +
        '         "customerEmail":"TEST",' +
        '         "orderNumber":"2112287678",' +
        '         "store":"004",' +
        '         "createdDate":"2025-11-11",' +
        '         "availableDate":"2025-11-11",' +
        '         "totalWithVat":"150",' +
        '         "createdByUser":"9001074112",' +
        '         "creationChannel":"Valor",' +
        '         "orderStatus":"40",' +
        '         "depositTotal":"20.5",' +
        '         "depositRemaining":"20.45",' +
        '         "shippedFrom":"004",' +
        '         "deliveryDate":"test",' +
        '         "internalMessageCreatedDate":"2025-11-03T15:45:00.000Z",' +
        '         "internalMessageCreatedBy":"9001074112",' +
        '         "internalMessageText":"TEST interal Message",' +
        '         "eligibleForReducedVat":false,' +
        '         "orderItems":[' +
        '            {' +
        '               "lineNumber":"0",' +
        '               "productReferenceEan":"01u8d00000FfqqcAAB",' +
        '               "productName":"2 lâminas 5-50 mm Dexter CLEAN CUT",' +
        '               "stockQuantity":"20",' +
        '               "itemType":"Valor",' +
        '               "itemStatus":"40",' +
        '               "availableDate":"2025-11-03T15:45:00.000Z",' +
        '               "sourceQuoteNumber":"267898987678",' +
        '               "unitPrice":"25.5",' +
        '               "discountPercent":"12.5",' +
        '               "pdo":"12",' +
        '               "amountIncludingVAT":"50",'+
        '               "lineComplementDescription":"TEST Desc",' +
        '               "supplierOrderNumber":"TEST Supplie Ord Num",' +
        '               "address":"Location 1",' +
        '               "pickupLocation":"004",' +
        '               "createdByUser":"9001074112",' +
        '               "lastModifiedByUser":"9001074112",' +
        '               "codeSection":"7",' +
        '               "codeSubsection":"8",' +
        '               "codeType":"8",' +
        '               "codeSubtype":"9",' +
        '               "nomenclature":"TEST",' +
        '               "sourceChannel":"Valor",' +
        '               "sourceTransaction":"Valor",' +
        '               "sourceStore":"004"' +
        '            },' +
        '            {' +
        '               "lineNumber":"1",' +
        '               "productReferenceEan":"01u8d00000FfqrfAAB",' +
        '               "productName":"10 lixas 93X93MM",' +
        '               "stockQuantity":"20",' +
        '               "itemType":"Valor",' +
        '               "itemStatus":"40",' +
        '               "availableDate":"2025-11-03T15:45:00.000Z",' +
        '               "sourceQuoteNumber":"267898987678",' +
        '               "unitPrice":"555.5",' +
        '               "discountPercent":"12.5",' +
        '               "pdo":"12",' +
        '               "amountIncludingVAT":"50",'+
        '               "lineComplementDescription":"TEST Desc",' +
        '               "supplierOrderNumber":"TEST Supplie Ord Num",' +
        '               "address":"Location 1",' +
        '               "pickupLocation":"004",' +
        '               "createdByUser":"9001074112",' +
        '               "lastModifiedByUser":"9001074112",' +
        '               "codeSection":"Valor",' +
        '               "codeSubsection":"Valor",' +
        '               "codeType":"Valor",' +
        '               "codeSubtype":"Valor",' +
        '               "nomenclature":"TEST",' +
        '               "sourceChannel":"Valor",' +
        '               "sourceTransaction":"Valor",' +
        '               "sourceStore":"004"' +
        '            }' +
        '         ]' +
        '      }' +
        '   ]' +
        '}';

    public static String orderPayload =
        '{'+
        '    "externalId":"260516",'+
        '    "customer":{'+
        '        "name":"TEST ACCOUNT",'+
        '        "number":"123346",'+
        '        "email":"ml@gmail.com"'+
        '   },'+
        '   "productOrders":[' +
        '      {' +
        '         "customerName":"TEST",' +
        '         "customerNumber":"TEST",' +
        '         "customerEmail":"TEST",' +
        '         "orderNumber":"21122",' +
        '         "store":"004",' +
        '         "createdDate":"2025-11-11T15:45:00.000Z",' +
        '         "availableDate":"2025-11-11T15:45:00.000Z",' +
        '         "totalWithVat":"150",' +
        '         "createdByUser":"9001074112",' +
        '         "creationChannel":"Valor",' +
        '         "orderStatus":"10",' +
        '         "depositTotal":"20.5",' +
        '         "depositRemaining":"20.45",' +
        '         "shippedFrom":"LM_ALBUFEIRA",' +
        '         "deliveryDate":"2025-11-11T15:45:00.000Z",' +
        '         "internalMessageCreatedDate":"2025-11-03T15:45:00.000Z",' +
        '         "internalMessageCreatedBy":"TEST Created By",' +
        '         "internalMessageText":"TEST interal Message",' +
        '         "eligibleForReducedVat":false,' +
        '         "orderItems":[' +
        '            {' +
        '               "lineNumber":"0",' +
        '               "productReferenceEan":"01u8d00000FfqqcAAB",' +
        '               "productName":"2 lâminas 5-50 mm Dexter CLEAN CUT",' +
        '               "stockQuantity":"20",' +
        '               "itemType":"Valor",' +
        '               "itemStatus":"10",' +
        '               "availableDate":"2025-11-03T15:45:00.000Z",' +
        '               "sourceQuoteNumber":"",' +
        '               "unitPrice":"25.5",' +
        '               "discountPercent":"12.5",' +
        '               "pdo":"12",' +
        '               "amountIncludingVAT":"50",'+
        '               "lineComplementDescription":"TEST Desc",' +
        '               "supplierOrderNumber":"TEST Supplie Ord Num",' +
        '               "address":"Location 1",' +
        '               "pickupLocation":"004",' +
        '               "createdByUser":"9001074112",' +
        '               "lastModifiedByUser":"9001074112",' +
        '               "codeSection":"7",' +
        '               "codeSubsection":"8",' +
        '               "codeType":"8",' +
        '               "codeSubtype":"9",' +
        '               "nomenclature":"TEST",' +
        '               "sourceChannel":"Valor",' +
        '               "sourceTransaction":"Valor",' +
        '               "sourceStore":"004"' +
        '            },' +
        '            {' +
        '               "lineNumber":"1",' +
        '               "productReferenceEan":"01u8d00000FfqrfAAB",' +
        '               "productName":"10 lixas 93X93MM",' +
        '               "stockQuantity":"20",' +
        '               "itemType":"Valor",' +
        '               "itemStatus":"10",' +
        '               "availableDate":"2025-11-03T15:45:00.000Z",' +
        '               "sourceQuoteNumber":"",' +
        '               "unitPrice":"555.5",' +
        '               "discountPercent":"12.5",' +
        '               "pdo":"12",' +
        '               "amountIncludingVAT":"50",'+
        '               "lineComplementDescription":"TEST Desc",' +
        '               "supplierOrderNumber":"TEST Supplie Ord Num",' +
        '               "address":"Location 1",' +
        '               "pickupLocation":"006",' +
        '               "createdByUser":"9001074112",' +
        '               "lastModifiedByUser":"9001074112",' +
        '               "codeSection":"Valor",' +
        '               "codeSubsection":"Valor",' +
        '               "codeType":"Valor",' +
        '               "codeSubtype":"Valor",' +
        '               "nomenclature":"TEST",' +
        '               "sourceChannel":"Valor",' +
        '               "sourceTransaction":"Valor",' +
        '               "sourceStore":"004"' +
        '            }' +
        '         ]' +
        '      }' +
        '   ]' +
        '}';
    
    public static String orderPayloadv2 =
        '{'+
        '    "externalId":"260516",'+
        '    "customer":{'+
        '        "name":"TEST ACCOUNT",'+
        '        "number":"123346",'+
        '        "email":"ml@gmail.com"'+
        '   },'+
        '   "productOrders":[' +
        '      {' +
        '         "customerName":"TEST",' +
        '         "customerNumber":"TEST",' +
        '         "customerEmail":"TEST",' +
        '         "orderNumber":"21122",' +
        '         "store":"004",' +
        '         "createdDate":"2025-11-11T15:45:00.000Z",' +
        '         "availableDate":"2025-11-11T15:45:00.000Z",' +
        '         "totalWithVat":"250",' +
        '         "createdByUser":"9001074112",' +
        '         "creationChannel":"Valor",' +
        '         "orderStatus":"40",' +
        '         "depositTotal":"20.5",' +
        '         "depositRemaining":"20.45",' +
        '         "shippedFrom":"LM_ALBUFEIRA",' +
        '         "deliveryDate":"2025-11-11T15:45:00.000Z",' +
        '         "internalMessageCreatedDate":"2025-11-03T15:45:00.000Z",' +
        '         "internalMessageCreatedBy":"TEST Created By",' +
        '         "internalMessageText":"TEST interal Message",' +
        '         "eligibleForReducedVat":false,' +
        '         "orderItems":[' +
        '            {' +
        '               "lineNumber":"0",' +
        '               "productReferenceEan":"01u8d00000FfqqcAAB",' +
        '               "productName":"2 lâminas 5-50 mm Dexter CLEAN CUT",' +
        '               "stockQuantity":"20",' +
        '               "itemType":"Valor",' +
        '               "itemStatus":"40",' +
        '               "availableDate":"2025-11-03T15:45:00.000Z",' +
        '               "sourceQuoteNumber":"",' +
        '               "unitPrice":"25.5",' +
        '               "discountPercent":"12.5",' +
        '               "pdo":"12",' +
        '               "amountIncludingVAT":"50",'+
        '               "lineComplementDescription":"TEST Desc",' +
        '               "supplierOrderNumber":"TEST Supplie Ord Num",' +
        '               "address":"Location 1",' +
        '               "pickupLocation":"004",' +
        '               "createdByUser":"9001074112",' +
        '               "lastModifiedByUser":"9001074112",' +
        '               "codeSection":"7",' +
        '               "codeSubsection":"8",' +
        '               "codeType":"8",' +
        '               "codeSubtype":"9",' +
        '               "nomenclature":"TEST",' +
        '               "sourceChannel":"Valor",' +
        '               "sourceTransaction":"Valor",' +
        '               "sourceStore":"004"' +
        '            },' +
        '            {' +
        '               "lineNumber":"1",' +
        '               "productReferenceEan":"01u8d00000FfqrfAAB",' +
        '               "productName":"10 lixas 93X93MM",' +
        '               "stockQuantity":"20",' +
        '               "itemType":"Valor",' +
        '               "itemStatus":"40",' +
        '               "availableDate":"2025-11-03T15:45:00.000Z",' +
        '               "sourceQuoteNumber":"",' +
        '               "unitPrice":"555.5",' +
        '               "discountPercent":"12.5",' +
        '               "pdo":"12",' +
        '               "amountIncludingVAT":"50",'+
        '               "lineComplementDescription":"TEST Desc",' +
        '               "supplierOrderNumber":"TEST Supplie Ord Num",' +
        '               "address":"Location 1",' +
        '               "pickupLocation":"006",' +
        '               "createdByUser":"9001074112",' +
        '               "lastModifiedByUser":"9001074112",' +
        '               "codeSection":"Valor",' +
        '               "codeSubsection":"Valor",' +
        '               "codeType":"Valor",' +
        '               "codeSubtype":"Valor",' +
        '               "nomenclature":"TEST",' +
        '               "sourceChannel":"Valor",' +
        '               "sourceTransaction":"Valor",' +
        '               "sourceStore":"004"' +
        '            }' +
        '         ]' +
        '      }' +
        '   ]' +
        '}';

    public static String quotePayloadExpired =
        '{'+
        '    "externalId":"260516",'+
        '    "customer":{'+
        '        "name":"TEST ACCOUNT",'+
        '        "number":"123346",'+
        '        "email":"ml@gmail.com"'+
        '   },'+
        '    "quotes":['+
        '        {'+
        '         "store":"004",'+
        '         "createdDate":"2025-10-31T14:30:00Z",'+
        '         "quoteNumber":"267898",'+
        '         "createdByUser":"0058d000008aV4JAAU",'+
        '         "creationChannel":"Valor",'+
        '         "state":"140",'+
        '         "quoteExpirationDate":"2025-10-31T14:30:00Z",'+
        '         "quoteStatus":"140",'+
        '         "internalMessageCreatedDate":"2025-10-31T14:30:00Z",'+
        '         "internalMessageCreatedBy":"Postman Tester User",'+
        '         "internalMessageText":"FROM Postman API Callout",'+
        '         "quoteLineItems":['+
        '            {'+
        '               "lineNumber":"0",'+
        '               "productReferenceEan":"01t8d0000086DFLAA2",'+
        '               "productName":"2 lâminas 5-50 mm Dexter CLEAN CUT",'+
        '               "stockQuantity":"3",'+
        '               "pdo":"15",'+
        '               "itemStatus":"140",'+
        '               "unitPrice":"14",'+
        '               "discountPercent":"20.5",'+
        '               "totalAmount":"10.4",'+
        '               "section":"Valor",'+
        '               "subsection":"Valor",'+
        '               "type":"PF",'+
        '               "subtype":"Valor",'+
        '               "nomenclature":"TEST Nomeclature",'+
        '               "supplier":"10.4",'+
        '               "transformChannel":"TEST Tranform Channel",'+
        '               "transformTransaction":"TEST Transform Transaction",'+
        '               "transformStore":"004"'+
        '            },'+
        '            {'+
        '               "lineNumber":"1",'+
        '               "productReferenceEan":"01t8d0000086DGTAA2",'+
        '               "productName":"10 lixas 93X93MM",'+
        '               "stockQuantity":"3",'+
        '               "pdo":"15",'+
        '               "itemStatus":"140",'+
        '               "unitPrice":"14",'+
        '               "discountPercent":"20.5",'+
        '               "totalAmount":"10.4",'+
        '               "section":"Valor",'+
        '               "subsection":"Valor",'+
        '               "type":"PF",'+
        '               "subtype":"Valor",'+
        '               "nomenclature":"TEST Nomeclature",'+
        '               "supplier":"10.4",'+
        '               "transformChannel":"TEST Tranform Channel",'+
        '               "transformTransaction":"TEST Transform Transaction",'+
        '               "transformStore":"004"'+
        '            }'+
        '         ]'+
        '      }'+
        '   ]'+
        '}';

    public static String salesNoteNotValidMDMId =
        '{' +
        '   "externalId":"260516",' +
        '   "customer":{' +
        '      "name":"JOSE ALMEIDA V2",' +
        '      "number":"98765431",' +
        '      "email":"mlv2@gmail.com"' +
        '   },' +
        '   "saleNoteOrders":[' +
        '      {' +
        '         "salesNoteNumber":"009876",' +
        '         "store":"004",' +
        '         "salesDate":"2025-11-03T15:45:00.000Z",' +
        '         "totalWithVat":"150",' +
        '         "createdByUser":"9001074112",' +
        '         "creationChannel":"Valor",' +
        '         "salesNoteStatus":"10",' +
        '         "internalMessageCreatedDate":"2025-11-03T15:45:00.000Z",' +
        '         "internalMessageCreatedBy":"9001074112",' +
        '         "internalMessageText":"TEST",' +
        '         "orderItems":[' +
        '            {' +
        '               "lineNumber":0,' +
        '               "productReferenceEan":"876567876777",' +
        '               "productName":"10 lixas 93X93MM",' +
        '               "stockQuantity":"23.4",' +
        '               "pdo":"20",' +
        '               "itemType":"PF",' +
        '               "itemStatus":"10",' +
        '               "unitPrice":"12.23",' +
        '               "discountPercent":"12.5",' +
        '               "totalWithVat":"12.5",' +
        '               "lineComplementDescription":"TEST Desc",' +
        '               "createdByUser":"9001074112",' +
        '               "lastModifiedByUser":"9001074112",' +
        '               "codeSection":"Valor",' +
        '               "codeSubsection":"Valor",' +
        '               "codeType":"Valor",' +
        '               "codeSubtype":"Valor",' +
        '               "nomenclature":"TEST",' +
        '               "supplier":"TEST",' +
        '               "sourceTransactionType":"Valor"' +
        '            },' +
        '            {' +
        '               "lineNumber":1,' +
        '               "productReferenceEan":"98765678",' +
        '               "productName":"2 lâminas 5-50 mm Dexter CLEAN CUT",' +
        '               "stockQuantity":"23.4",' +
        '               "pdo":"20",' +
        '               "itemType":"PF",' +
        '               "itemStatus":"10",' +
        '               "unitPrice":"12.23",' +
        '               "discountPercent":"12.5",' +
        '               "totalWithVat":"12.5",' +
        '               "lineComplementDescription":"TEST Desc",' +
        '               "createdByUser":"9001074112",' +
        '               "lastModifiedByUser":"9001074112",' +
        '               "codeSection":"Valor",' +
        '               "codeSubsection":"Valor",' +
        '               "codeType":"Valor",' +
        '               "codeSubtype":"Valor",' +
        '               "nomenclature":"TEST",' +
        '               "supplier":"TEST",' +
        '               "sourceTransactionType":"Valor"' +
        '            }' +
        '         ]' +
        '      }' +
        '   ]' +
        '}';

    public static String salesNoteCode49 =
        '{' +
        '   "externalId":"260516",' +
        '   "customer":{' +
        '      "name":"JOSE ALMEIDA",' +
        '      "number":"123346",' +
        '      "email":"ml@gmail.com"' +
        '   },' +
        '   "saleNoteOrders":[' +
        '      {' +
        '         "salesNoteNumber":"009877",' +
        '         "store":"004",' +
        '         "salesDate":"2025-11-03T15:45:00.000Z",' +
        '         "totalWithVat":"150",' +
        '         "createdByUser":"0058d000008aV4JAAU",' +
        '         "creationChannel":"Valor",' +
        '         "salesNoteStatus":"10",' +
        '         "internalMessageCreatedDate":"2025-11-03T15:45:00.000Z",' +
        '         "internalMessageCreatedBy":"TEST",' +
        '         "internalMessageText":"TEST",' +
        '         "orderItems":[' +
        '            {' +
        '               "lineNumber":0,' +
        '               "productReferenceEan":"49........",' +
        '               "productName":"10 lixas 93X93MM",' +
        '               "stockQuantity":"23.4",' +
        '               "pdo":"20",' +
        '               "itemType":"PF",' +
        '               "itemStatus":"10",' +
        '               "unitPrice":"12.23",' +
        '               "discountPercent":"12.5",' +
        '               "totalWithVat":"12.5",' +
        '               "lineComplementDescription":"TEST Desc",' +
        '               "createdByUser":"0058d000008aV4JAAU",' +
        '               "lastModifiedByUser":"0058d000008aV4JAAU",' +
        '               "codeSection":"Valor",' +
        '               "codeSubsection":"Valor",' +
        '               "codeType":"Valor",' +
        '               "codeSubtype":"Valor",' +
        '               "nomenclature":"TEST",' +
        '               "supplier":"TEST",' +
        '               "sourceTransactionType":"Valor"' +
        '            }' +
        '         ]' +
        '      }' +
        '   ]' +
        '}';

    public static String salesNoteCode49_v2 =
        '{' +
        '   "externalId":"260516",' +
        '   "customer":{' +
        '      "name":"JOSE ALMEIDA",' +
        '      "number":"123346",' +
        '      "email":"ml@gmail.com"' +
        '   },' +
        '   "saleNoteOrders":[' +
        '      {' +
        '         "salesNoteNumber":"009877",' +
        '         "store":"004",' +
        '         "salesDate":"2025-11-03T15:45:00.000Z",' +
        '         "totalWithVat":"250",' +
        '         "createdByUser":"0058d000008aV4JAAU",' +
        '         "creationChannel":"Valor",' +
        '         "salesNoteStatus":"40",' +
        '         "internalMessageCreatedDate":"2025-11-03T15:45:00.000Z",' +
        '         "internalMessageCreatedBy":"TEST",' +
        '         "internalMessageText":"TEST",' +
        '         "orderItems":[' +
        '            {' +
        '               "lineNumber":0,' +
        '               "productReferenceEan":"49........",' +
        '               "productName":"10 lixas 93X93MM",' +
        '               "stockQuantity":"23.4",' +
        '               "pdo":"20",' +
        '               "itemType":"PF",' +
        '               "itemStatus":"40",' +
        '               "unitPrice":"12.23",' +
        '               "discountPercent":"12.5",' +
        '               "totalWithVat":"12.5",' +
        '               "lineComplementDescription":"TEST Desc",' +
        '               "createdByUser":"0058d000008aV4JAAU",' +
        '               "lastModifiedByUser":"0058d000008aV4JAAU",' +
        '               "codeSection":"Valor",' +
        '               "codeSubsection":"Valor",' +
        '               "codeType":"Valor",' +
        '               "codeSubtype":"Valor",' +
        '               "nomenclature":"TEST",' +
        '               "supplier":"TEST",' +
        '               "sourceTransactionType":"Valor"' +
        '            }' +
        '         ]' +
        '      }' +
        '   ]' +
        '}';

    public static String salesNoteCode49012693 =
        '{' +
        '   "externalId":"260516",' +
        '   "customer":{' +
        '      "name":"JOSE ALMEIDA",' +
        '      "number":"123346",' +
        '      "email":"ml@gmail.com"' +
        '   },' +
        '   "saleNoteOrders":[' +
        '      {' +
        '         "salesNoteNumber":"009877",' +
        '         "store":"004",' +
        '         "salesDate":"2025-11-03T15:45:00.000Z",' +
        '         "totalWithVat":"150",' +
        '         "createdByUser":"0058d000008aV4JAAU",' +
        '         "creationChannel":"Valor",' +
        '         "salesNoteStatus":"10",' +
        '         "internalMessageCreatedDate":"2025-11-03T15:45:00.000Z",' +
        '         "internalMessageCreatedBy":"TEST",' +
        '         "internalMessageText":"TEST",' +
        '         "orderItems":[' +
        '            {' +
        '               "lineNumber":0,' +
        '               "productReferenceEan":"49012693",' +
        '               "productName":"10 lixas 93X93MM",' +
        '               "stockQuantity":"23.4",' +
        '               "pdo":"20",' +
        '               "itemType":"PF",' +
        '               "itemStatus":"10",' +
        '               "unitPrice":"12.23",' +
        '               "discountPercent":"12.5",' +
        '               "totalWithVat":"12.5",' +
        '               "lineComplementDescription":"TEST Desc",' +
        '               "createdByUser":"0058d000008aV4JAAU",' +
        '               "lastModifiedByUser":"0058d000008aV4JAAU",' +
        '               "codeSection":"Valor",' +
        '               "codeSubsection":"Valor",' +
        '               "codeType":"Valor",' +
        '               "codeSubtype":"Valor",' +
        '               "nomenclature":"TEST",' +
        '               "supplier":"TEST",' +
        '               "sourceTransactionType":"Valor"' +
        '            }' +
        '         ]' +
        '      }' +
        '   ]' +
        '}';

    public static String orderPayloadFromTransformationCode49012693 =
            '{'+
            '    "externalId":"260516",'+
            '    "customer":{'+
            '        "name":"TEST ACCOUNT",'+
            '        "number":"123346",'+
            '        "email":"ml@gmail.com"'+
            '   },'+
            '   "productOrders":[' +
            '      {' +
            '         "customerName":"TEST",' +
            '         "customerNumber":"TEST",' +
            '         "customerEmail":"TEST",' +
            '         "orderNumber":"21122",' +
            '         "store":"004",' +
            '         "createdDate":"2025-11-11T15:45:00.000Z",' +
            '         "availableDate":"2025-11-11T15:45:00.000Z",' +
            '         "totalWithVat":"150",' +
            '         "createdByUser":"9001074112",' +
            '         "creationChannel":"Valor",' +
            '         "orderStatus":"10",' +
            '         "depositTotal":"20.5",' +
            '         "depositRemaining":"20.45",' +
            '         "shippedFrom":"LM_ALBUFEIRA",' +
            '         "deliveryDate":"2025-11-11T15:45:00.000Z",' +
            '         "internalMessageCreatedDate":"2025-11-03T15:45:00.000Z",' +
            '         "internalMessageCreatedBy":"TEST Created By",' +
            '         "internalMessageText":"TEST interal Message",' +
            '         "eligibleForReducedVat":false,' +
            '         "orderItems":[' +
            '            {' +
            '               "lineNumber":"0",' +
            '               "productReferenceEan":"49012693",' +
            '               "productName":"2 lâminas 5-50 mm Dexter CLEAN CUT",' +
            '               "stockQuantity":"20",' +
            '               "itemType":"Valor",' +
            '               "itemStatus":"10",' +
            '               "availableDate":"2025-11-03T15:45:00.000Z",' +
            '               "sourceQuoteNumber":"267898",' +
            '               "unitPrice":"25.5",' +
            '               "discountPercent":"12.5",' +
            '               "pdo":"12",' +
            '               "amountIncludingVAT":"50",'+
            '               "lineComplementDescription":"TEST Desc",' +
            '               "supplierOrderNumber":"TEST Supplie Ord Num",' +
            '               "address":"Location 1",' +
            '               "pickupLocation":"004",' +
            '               "createdByUser":"9001074112",' +
            '               "lastModifiedByUser":"9001074112",' +
            '               "codeSection":"7",' +
            '               "codeSubsection":"8",' +
            '               "codeType":"8",' +
            '               "codeSubtype":"9",' +
            '               "nomenclature":"TEST",' +
            '               "sourceChannel":"Valor",' +
            '               "sourceTransaction":"Valor",' +
            '               "sourceStore":"004"' +
            '            },' +
            '            {' +
            '               "lineNumber":"1",' +
            '               "productReferenceEan":"49012693",' +
            '               "productName":"10 lixas 93X93MM",' +
            '               "stockQuantity":"20",' +
            '               "itemType":"Valor",' +
            '               "itemStatus":"10",' +
            '               "availableDate":"2025-11-03T15:45:00.000Z",' +
            '               "sourceQuoteNumber":"267898",' +
            '               "unitPrice":"555.5",' +
            '               "discountPercent":"12.5",' +
            '               "pdo":"12",' +
            '               "amountIncludingVAT":"50",'+
            '               "lineComplementDescription":"TEST Desc",' +
            '               "supplierOrderNumber":"TEST Supplie Ord Num",' +
            '               "address":"Location 1",' +
            '               "pickupLocation":"006",' +
            '               "createdByUser":"9001074112",' +
            '               "lastModifiedByUser":"9001074112",' +
            '               "codeSection":"Valor",' +
            '               "codeSubsection":"Valor",' +
            '               "codeType":"Valor",' +
            '               "codeSubtype":"Valor",' +
            '               "nomenclature":"TEST",' +
            '               "sourceChannel":"Valor",' +
            '               "sourceTransaction":"Valor",' +
            '               "sourceStore":"004"' +
            '            }' +
            '         ]' +
            '      }' +
            '   ]' +
            '}';

    public static String oderTotalAmounts =
        '{' +
        '   "externalId":"260516",' +
        '   "customer":{' +
        '      "name":"JOSE ALMEIDA",' +
        '      "number":"123346",' +
        '      "email":"ml@gmail.com"' +
        '   },' +
        '   "productOrders":[' +
        '      {' +
        '         "customerName":"TEST",' +
        '         "customerNumber":"TEST",' +
        '         "customerEmail":"TEST",' +
        '         "orderNumber":"2112290913",' +
        '         "store":"004",' +
        '         "createdDate":"2025-11-11T15:45:00.000Z",' +
        '         "availableDate":"2025-11-11T15:45:00.000Z",' +
        '         "totalWithVat":"250",' +
        '         "createdByUser":"9001074112",' +
        '         "creationChannel":"Valor",' +
        '         "orderStatus":"40",' +
        '         "depositTotal":"20.5",' +
        '         "depositRemaining":"20.45",' +
        '         "shippedFrom":"LM_ALBUFEIRA",' +
        '         "deliveryDate":"2025-11-11T15:45:00.000Z",' +
        '         "internalMessageCreatedDate":"2025-11-03T15:45:00.000Z",' +
        '         "internalMessageCreatedBy":"TEST Created By",' +
        '         "internalMessageText":"TEST interal Message",' +
        '         "eligibleForReducedVat":false,' +
        '         "orderItems":[' +
        '            {' +
        '               "lineNumber":"0",' +
        '               "productReferenceEan":"7654567899765",' +
        '               "productName":"2 lâminas 5-50 mm Dexter CLEAN CUT",' +
        '               "stockQuantity":"20",' +
        '               "itemType":"Valor",' +
        '               "itemStatus":"40",' +
        '               "availableDate":"2025-11-03T15:45:00.000Z",' +
        '               "sourceQuoteNumber":"",' +
        '               "unitPrice":"200",' +
        '               "discountPercent":"10",' +
        '               "pdo":"1",' +
        '               "amountIncludingVAT":"50",'+
        '               "lineComplementDescription":"TEST Desc",' +
        '               "supplierOrderNumber":"TEST Supplie Ord Num",' +
        '               "address":"Location 1",' +
        '               "pickupLocation":"004",' +
        '               "createdByUser":"9001074112",' +
        '               "lastModifiedByUser":"9001074112",' +
        '               "codeSection":"7-LAMINAS",' +
        '               "codeSubsection":"8",' +
        '               "codeType":"8",' +
        '               "codeSubtype":"9",' +
        '               "nomenclature":"TEST",' +
        '               "sourceChannel":"Valor",' +
        '               "sourceTransaction":"Valor",' +
        '               "sourceStore":"004"' +
        '            },' +
        '            {' +
        '               "lineNumber":"1",' +
        '               "productReferenceEan":"49098789098",' +
        '               "productName":"VISITA DE ORÇAMENTO",' +
        '               "stockQuantity":"1",' +
        '               "itemType":"Valor",' +
        '               "itemStatus":"40",' +
        '               "availableDate":"2025-11-03T15:45:00.000Z",' +
        '               "sourceQuoteNumber":"",' +
        '               "unitPrice":"50",' +
        '               "discountPercent":"",' +
        '               "pdo":"1",' +
        '               "amountIncludingVAT":"50",'+
        '               "lineComplementDescription":"TEST Desc",' +
        '               "supplierOrderNumber":"TEST Supplie Ord Num",' +
        '               "address":"Location 1",' +
        '               "pickupLocation":"006",' +
        '               "createdByUser":"9001074112",' +
        '               "lastModifiedByUser":"9001074112",' +
        '               "codeSection":"Valor",' +
        '               "codeSubsection":"Valor",' +
        '               "codeType":"Valor",' +
        '               "codeSubtype":"Valor",' +
        '               "nomenclature":"TEST",' +
        '               "sourceChannel":"Valor",' +
        '               "sourceTransaction":"Valor",' +
        '               "sourceStore":"004"' +
        '            }' +
        '         ]' +
        '      }' +
        '   ]' +
        '}';

    public static String orderValidated =
        '{' +
        '   "externalId":"260516",' +
        '   "customer":{' +
        '      "name":"JOSE ALMEIDA",' +
        '      "number":"123346",' +
        '      "email":"ml@gmail.com"' +
        '   },' +
        '   "productOrders":[' +
        '      {' +
        '         "customerName":"TEST",' +
        '         "customerNumber":"TEST",' +
        '         "customerEmail":"TEST",' +
        '         "orderNumber":"21122",' +
        '         "store":"004",' +
        '         "createdDate":"2025-11-11T15:45:00.000Z",' +
        '         "availableDate":"2025-11-11T15:45:00.000Z",' +
        '         "totalWithVat":"1500",' +
        '         "createdByUser":"0058d000008aV4JAAU",' +
        '         "creationChannel":"Valor",' +
        '         "orderStatus":"20",' +
        '         "depositTotal":"20.5",' +
        '         "depositRemaining":"20.45",' +
        '         "shippedFrom":"LM_ALBUFEIRA",' +
        '         "deliveryDate":"2025-11-11T15:45:00.000Z",' +
        '         "internalMessageCreatedDate":"2025-11-03T15:45:00.000Z",' +
        '         "internalMessageCreatedBy":"TEST Created By",' +
        '         "internalMessageText":"TEST interal Message",' +
        '         "eligibleForReducedVat":false,' +
        '         "orderItems":[' +
        '            {' +
        '               "lineNumber":"0",' +
        '               "productReferenceEan":"01u8d00000FfqqcAAB",' +
        '               "productName":"2 lâminas 5-50 mm Dexter CLEAN CUT",' +
        '               "stockQuantity":"20",' +
        '               "itemType":"Valor",' +
        '               "itemStatus":"20",' +
        '               "availableDate":"2025-11-03T15:45:00.000Z",' +
        '               "sourceQuoteNumber":"",' +
        '               "unitPrice":"25.5",' +
        '               "discountPercent":"12.5",' +
        '               "pdo":"12",' +
        '               "amountIncludingVAT":"50",'+
        '               "lineComplementDescription":"TEST Desc",' +
        '               "supplierOrderNumber":"TEST Supplie Ord Num",' +
        '               "address":"Location 1",' +
        '               "pickupLocation":true,' +
        '               "createdByUser":"0058d000008aV4JAAU",' +
        '               "lastModifiedByUser":"0058d000008aV4JAAU",' +
        '               "codeSection":"Valor",' +
        '               "codeSubsection":"Valor",' +
        '               "codeType":"Valor",' +
        '               "codeSubtype":"Valor",' +
        '               "nomenclature":"TEST",' +
        '               "sourceChannel":"Valor",' +
        '               "sourceTransaction":"Valor",' +
        '               "sourceStore":"004"' +
        '            },' +
        '            {' +
        '               "lineNumber":"1",' +
        '               "productReferenceEan":"01u8d00000FfqrfAAB",' +
        '               "productName":"10 lixas 93X93MM",' +
        '               "stockQuantity":"20",' +
        '               "itemType":"Valor",' +
        '               "itemStatus":"20",' +
        '               "availableDate":"2025-11-03T15:45:00.000Z",' +
        '               "sourceQuoteNumber":"",' +
        '               "unitPrice":"25.5",' +
        '               "discountPercent":"12.5",' +
        '               "pdo":"12",' +
        '               "amountIncludingVAT":"50",'+
        '               "lineComplementDescription":"TEST Desc",' +
        '               "supplierOrderNumber":"TEST Supplie Ord Num",' +
        '               "address":"Location 1",' +
        '               "pickupLocation":true,' +
        '               "createdByUser":"0058d000008aV4JAAU",' +
        '               "lastModifiedByUser":"0058d000008aV4JAAU",' +
        '               "codeSection":"Valor",' +
        '               "codeSubsection":"Valor",' +
        '               "codeType":"Valor",' +
        '               "codeSubtype":"Valor",' +
        '               "nomenclature":"TEST",' +
        '               "sourceChannel":"Valor",' +
        '               "sourceTransaction":"Valor",' +
        '               "sourceStore":"004"' +
        '            }' +
        '         ]' +
        '      }' +
        '   ]' +
        '}';

    public static String orderExpired =
        '{' +
        '   "externalId":"260516",' +
        '   "customer":{' +
        '      "name":"JOSE ALMEIDA",' +
        '      "number":"123346",' +
        '      "email":"ml@gmail.com"' +
        '   },' +
        '   "productOrders":[' +
        '      {' +
        '         "customerName":"TEST",' +
        '         "customerNumber":"TEST",' +
        '         "customerEmail":"TEST",' +
        '         "orderNumber":"21122",' +
        '         "store":"004",' +
        '         "createdDate":"2025-11-11T15:45:00.000Z",' +
        '         "availableDate":"2025-11-11T15:45:00.000Z",' +
        '         "totalWithVat":"1500",' +
        '         "createdByUser":"0058d000008aV4JAAU",' +
        '         "creationChannel":"Valor",' +
        '         "orderStatus":"90",' +
        '         "depositTotal":"20.5",' +
        '         "depositRemaining":"20.45",' +
        '         "shippedFrom":"LM_ALBUFEIRA",' +
        '         "deliveryDate":"2025-11-11T15:45:00.000Z",' +
        '         "internalMessageCreatedDate":"2025-11-03T15:45:00.000Z",' +
        '         "internalMessageCreatedBy":"TEST Created By",' +
        '         "internalMessageText":"TEST interal Message",' +
        '         "eligibleForReducedVat":false,' +
        '         "orderItems":[' +
        '            {' +
        '               "lineNumber":"0",' +
        '               "productReferenceEan":"01u8d00000FfqqcAAB",' +
        '               "productName":"2 lâminas 5-50 mm Dexter CLEAN CUT",' +
        '               "stockQuantity":"20",' +
        '               "itemType":"Valor",' +
        '               "itemStatus":"90",' +
        '               "availableDate":"2025-11-03T15:45:00.000Z",' +
        '               "sourceQuoteNumber":"",' +
        '               "unitPrice":"25.5",' +
        '               "discountPercent":"12.5",' +
        '               "pdo":"12",' +
        '               "amountIncludingVAT":"50",'+
        '               "lineComplementDescription":"TEST Desc",' +
        '               "supplierOrderNumber":"TEST Supplie Ord Num",' +
        '               "address":"Location 1",' +
        '               "pickupLocation":true,' +
        '               "createdByUser":"0058d000008aV4JAAU",' +
        '               "lastModifiedByUser":"0058d000008aV4JAAU",' +
        '               "codeSection":"Valor",' +
        '               "codeSubsection":"Valor",' +
        '               "codeType":"Valor",' +
        '               "codeSubtype":"Valor",' +
        '               "nomenclature":"TEST",' +
        '               "sourceChannel":"Valor",' +
        '               "sourceTransaction":"Valor",' +
        '               "sourceStore":"004"' +
        '            },' +
        '            {' +
        '               "lineNumber":"1",' +
        '               "productReferenceEan":"01u8d00000FfqrfAAB",' +
        '               "productName":"10 lixas 93X93MM",' +
        '               "stockQuantity":"20",' +
        '               "itemType":"Valor",' +
        '               "itemStatus":"90",' +
        '               "availableDate":"2025-11-03T15:45:00.000Z",' +
        '               "sourceQuoteNumber":"",' +
        '               "unitPrice":"25.5",' +
        '               "discountPercent":"12.5",' +
        '               "pdo":"12",' +
        '               "amountIncludingVAT":"50",'+
        '               "lineComplementDescription":"TEST Desc",' +
        '               "supplierOrderNumber":"TEST Supplie Ord Num",' +
        '               "address":"Location 1",' +
        '               "pickupLocation":true,' +
        '               "createdByUser":"0058d000008aV4JAAU",' +
        '               "lastModifiedByUser":"0058d000008aV4JAAU",' +
        '               "codeSection":"Valor",' +
        '               "codeSubsection":"Valor",' +
        '               "codeType":"Valor",' +
        '               "codeSubtype":"Valor",' +
        '               "nomenclature":"TEST",' +
        '               "sourceChannel":"Valor",' +
        '               "sourceTransaction":"Valor",' +
        '               "sourceStore":"004"' +
        '            }' +
        '         ]' +
        '      }' +
        '   ]' +
        '}';

    @testSetup
    static void makeData(){
        Id stdPbId = Test.getStandardPricebookId();
        // TEST user data
        User userData = new User(Lastname = 'TEST_DATA', Alias = 'testd', Username = 'testdata@leroymerlin.pt', Email = 'testdata@leroymerlin.pt', ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id, LDAP__c = '9001074112', TimeZoneSidKey = 'GMT', LocaleSidKey = 'en_US', EmailEncodingKey = 'UTF-8', LanguageLocaleKey = 'en_US');
        insert userData;
        Pricebook2 stdPb = new Pricebook2(Id = stdPbId, IsActive = true);
        update stdPb;
        PyxisTargetDate__c setting = new PyxisTargetDate__c( Next_Day__c = false, Default_User_Name__c = 'Integration User');
        insert setting;
        LM_Store__c storeRec = new LM_Store__c( Name = 'ALBUFEIRA', Store_Code__c = '004-ALBUFEIRA');
        insert storeRec;
        Account acc = new Account( Name = 'TEST ACCOUNT', Numero_de_Conta__c = '123346', E_mail_Empresa__c = 'test@leroymerlin.pt');
        insert acc;
        Account accDefault = new Account(Name = 'DEFAULT PIXIS ACCOUNT', Numero_de_Conta__c = '000000');
        insert accDefault;
        Product2 prod1 = new Product2(Name = 'Pyxis', ProductCode = '01t8d0000086DFLAA2', IsActive = true);
        insert prod1;
        PricebookEntry standardPbe = new PricebookEntry( Pricebook2Id = stdPbId, Product2Id = prod1.Id, UnitPrice = 14, IsActive = true, UseStandardPrice = false);
        insert standardPbe;
    }

    @isTest
    static void testProcessQuotePayload_ValidPayload(){
        User user = [SELECT Id FROM User WHERE LDAP__c = '9001074112' LIMIT 1];
        LM_Store__c storeRec = [SELECT Id FROM LM_Store__c LIMIT 1];
        Test.startTest();
        PyxisAPIServiceHandler.PyxisResponderWrapper response = PyxisAPIServiceHandler.handleRequestPyxis(quotePayload, 'quotes');
        Test.stopTest();
        System.assertEquals(response.statusCode, 201, 'Status code should be 201');
        Quote quote = [SELECT InternalMessageCreatedBy__c, CreatedByUser__c, Store_Lookup__c FROM Quote LIMIT 1];
        QuoteLineItem quoteLineItem = [SELECT TransformStore_Lookup__c FROM QuoteLineItem LIMIT 1];
        // CHECK ASSERTS
        System.assertEquals(false, [SELECT id FROM Quote].isEmpty(), 'Quote should be created');
        System.assertEquals(false, [SELECT id FROM QuoteLineItem].isEmpty(), 'Quote items should be created');
        System.assertEquals(false, [SELECT id FROM Opportunity].isEmpty(), 'Opportunity should be created');
        System.assertEquals([SELECT StageName FROM Opportunity].StageName, 'Pedido de Orçamento', 'Opportunity Stage should be Pedido de Orçamento');
        // ASSERT USER SET
        System.assertEquals(quote.CreatedByUser__c, user.Id, 'Quote CreatedById should be Integration User');
        System.assertEquals(quote.InternalMessageCreatedBy__c, user.Id, 'Quote InternalMessageCreatedBy should be Integration User');
        //ASSERT STORE
        System.assertEquals(quote.Store_Lookup__c, storeRec.Id, 'Quote Store should be set');
        System.assertEquals(quoteLineItem.TransformStore_Lookup__c, storeRec.Id, 'Quote Line Item Transform Store should be set');
    }

    @isTest
    static void testProcessQuotePayload_ExpirationQuote(){
        Test.startTest();
        PyxisAPIServiceHandler.PyxisResponderWrapper response = PyxisAPIServiceHandler.handleRequestPyxis(quotePayloadExpired, 'quotes');
        Test.stopTest();
        // CHECK ASSERTS
        System.assertEquals(response.statusCode, 201, 'Status code should not be 201');
        System.assertEquals(false, [SELECT id FROM Quote].isEmpty(), 'Quote should be created');
        System.assertEquals(false, [SELECT id FROM QuoteLineItem].isEmpty(), 'Quote items should be created');
        System.assertEquals(false, [SELECT id FROM Opportunity].isEmpty(), 'Opportunity should be created');
        System.assertEquals([SELECT StageName FROM Opportunity].StageName, 'Identificar Motivo de Perda', 'Opportunity Stage should be Identificar Motivo de Perda');
    }

    @isTest
    static void testProcessOrderPayload_FromTransformation(){
        User user = [SELECT Id FROM User WHERE LDAP__c = '9001074112' LIMIT 1];
        LM_Store__c storeRec = [SELECT Id FROM LM_Store__c LIMIT 1];
        Test.startTest();
        PyxisAPIServiceHandler.PyxisResponderWrapper responseQuote = PyxisAPIServiceHandler.handleRequestPyxis(quotePayload, 'quotes');
        PyxisAPIServiceHandler.PyxisResponderWrapper responseOrder = PyxisAPIServiceHandler.handleRequestPyxis(orderPayloadFromTransformation, 'product-orders');
        Test.stopTest();
        // QUERY RECORDS
        System.assertEquals(responseOrder.statusCode, 201, 'Status code should not be 201');
        Quote quote = [SELECT ExternalQuoteNumber__c FROM Quote LIMIT 1];
        List<Order> order = [SELECT id, CreatedByUser__c, InternalMessageCreatedBy__c, ShippedFrom__c, Store__c FROM Order];
        List<OrderItem> orderItem = [SELECT SourceQuoteNumber__r.ExternalQuoteNumber__c, CreatedByUser__c, LastModifiedByUser__c, Store_Lookup__c, Pickup_Lookup__c FROM OrderItem WHERE SourceQuoteNumber__c =: quote.Id];
        // CHECK ASSERTS
        System.assertEquals(false, order.isEmpty(), 'Order should be created');
        System.assertEquals(false, orderItem.isEmpty(), 'Order items should be created');
        System.assertEquals(orderItem[0].SourceQuoteNumber__r.ExternalQuoteNumber__c, quote.ExternalQuoteNumber__c, 'External Quote Number should be set');
        System.assertEquals(false, [SELECT id FROM Opportunity].isEmpty(), 'Opportunity should be created');
        System.assertEquals([SELECT StageName FROM Opportunity].StageName, 'Aguarda Pagamento', 'Opportunity Stage should be Aguarda Pagamento');
        // ASSERT USER SET - ORDER
        System.assertEquals(order[0].CreatedByUser__c, user.Id, 'Order CreatedById should be Integration User');
        System.assertEquals(order[0].InternalMessageCreatedBy__c, user.Id, 'Order InternalMessageCreatedBy should be Integration User');
        // ASSERT USER SET - ORDER ITEM
        System.assertEquals(orderItem[0].CreatedByUser__c, user.Id, 'OrderItem CreatedById should be Integration User');
        System.assertEquals(orderItem[0].LastModifiedByUser__c, user.Id, 'OrderItem InternalMessageCreatedBy should be Integration User');
        //ASSERT STORE
        System.assertEquals(order[0].ShippedFrom__c, storeRec.Id, 'Order Shipped From should be set');
        System.assertEquals(order[0].Store__c, storeRec.Id, 'Order Store should be set');
        System.assertEquals(orderItem[0].Store_Lookup__c, storeRec.Id, 'Order Store should be set');
        System.assertEquals(orderItem[0].Pickup_Lookup__c, storeRec.Id, 'Order Pickup should be set');
    }

    @isTest
    static void testProcessOrderPayload_NotFromTransformation(){
        Test.startTest();
        PyxisAPIServiceHandler.PyxisResponderWrapper response = PyxisAPIServiceHandler.handleRequestPyxis(orderPayload, 'product-orders');
        Test.stopTest();
        // CHECK ASSERTS
        System.assertEquals(response.statusCode, 201, 'Status code should not be 201');
        System.assertEquals(false, [SELECT id FROM Order].isEmpty(), 'Order should be created');
        System.assertEquals(false, [SELECT id FROM OrderItem].isEmpty(), 'Order items should be created');
        System.assertEquals(false, [SELECT id FROM Opportunity].isEmpty(), 'Opportunity should be created');
        System.assertEquals([SELECT StageName FROM Opportunity].StageName, 'Aguarda Pagamento', 'Opportunity Stage should be Aguarda Pagamento');
    }

    @isTest
    static void testMDMId_NotValid(){
        User user = [SELECT Id FROM User WHERE LDAP__c = '9001074112' LIMIT 1];
        LM_Store__c storeRec = [SELECT Id FROM LM_Store__c LIMIT 1];
        Test.startTest();
        PyxisAPIServiceHandler.PyxisResponderWrapper response = PyxisAPIServiceHandler.handleRequestPyxis(salesNoteNotValidMDMId, 'sale-notes');
        Test.stopTest();
        System.assertEquals(response.statusCode, 201, 'Status code should not be 201');
        // QUERY RECORDS
        Order order = [SELECT id, CreatedByUser__c, InternalMessageCreatedBy__c, Store__c FROM Order LIMIT 1];
        OrderItem orderItem = [SELECT CreatedByUser__c, LastModifiedByUser__c FROM OrderItem LIMIT 1];
        // CHECK ASSERTS
        System.assertEquals(false, [SELECT id FROM Order].isEmpty(), 'Sales Note should be created');
        System.assertEquals(false, [SELECT id FROM OrderItem].isEmpty(), 'Sales Note items should be created');
        System.assertEquals(false, [SELECT id FROM Opportunity].isEmpty(), 'Opportunity should be created');
        System.assertEquals([SELECT StageName FROM Opportunity].StageName, 'Aguarda Pagamento', 'Opportunity Stage should be Aguarda Pagamento');
        System.assertEquals([SELECT Account.Name FROM Opportunity LIMIT 1].Account.Name, 'DEFAULT PIXIS ACCOUNT', 'Opportunity Account should be DEFAULT PIXIS ACCOUNT');
        // ASSERT USER SET - ORDER
        System.assertEquals(order.CreatedByUser__c, user.Id, 'Order CreatedById should be Integration User');
        System.assertEquals(order.InternalMessageCreatedBy__c, user.Id, 'Order InternalMessageCreatedBy should be Integration User');
        // ASSERT USER SET - ORDER ITEM
        System.assertEquals(orderItem.CreatedByUser__c, user.Id, 'OrderItem CreatedById should be Integration User');
        System.assertEquals(orderItem.LastModifiedByUser__c, user.Id, 'OrderItem InternalMessageCreatedBy should be Integration User');
        // ASSERT STORE
        System.assertEquals(order.Store__c, storeRec.Id, 'Order Store should be set');
    }

    @isTest
    static void testOderCodes_codes49(){
        Test.startTest();   
        PyxisAPIServiceHandler.PyxisResponderWrapper response = PyxisAPIServiceHandler.handleRequestPyxis(salesNoteCode49, 'sale-notes');
        Test.stopTest();
        // CHECK ASSERTS
        System.assertEquals(response.statusCode, 201, 'Status code should not be 201');
        System.assertEquals(false, [SELECT id FROM Opportunity].isEmpty(), 'Opportunity should be created');
        System.assertEquals([SELECT StageName FROM Opportunity].StageName, 'Retificação de Medidas', 'Opportunity Stage should be Retificação de Medidas');
    }

    @isTest
    static void testOderCodes_49012693_or_49013807_NotTranformation(){
        Test.startTest();   
        PyxisAPIServiceHandler.PyxisResponderWrapper response = PyxisAPIServiceHandler.handleRequestPyxis(salesNoteCode49012693, 'sale-notes');
        Test.stopTest();
        // CHECK ASSERTS
        System.assertEquals(response.statusCode, 201, 'Status code should not be 201');
        System.assertEquals(false, [SELECT id FROM Opportunity].isEmpty(), 'Opportunity should be created');
        System.assertEquals([SELECT StageName FROM Opportunity].StageName, 'Aguarda Pagamento', 'Opportunity Stage should be Aguarda Pagamento');
    }

    @isTest
    static void testOderCodes_49012693_or_49013807_Tranformation(){
        Test.startTest();
        PyxisAPIServiceHandler.PyxisResponderWrapper responseQuote = PyxisAPIServiceHandler.handleRequestPyxis(quotePayload, 'quotes');   
        PyxisAPIServiceHandler.PyxisResponderWrapper response = PyxisAPIServiceHandler.handleRequestPyxis(orderPayloadFromTransformationCode49012693, 'product-orders');
        Test.stopTest();
        // CHECK ASSERTS
        System.assertEquals(response.statusCode, 201, 'Status code should not be 201');
        System.assertEquals(false, [SELECT id FROM Opportunity].isEmpty(), 'Opportunity should be created');
        System.assertEquals([SELECT StageName FROM Opportunity].StageName, 'Aguarda Pagamento', 'Opportunity Stage should be Aguarda Pagamento');
    }

    @isTest
    static void testDeleteOppOrders(){
        Test.startTest();
        PyxisAPIServiceHandler.PyxisResponderWrapper response = PyxisAPIServiceHandler.handleRequestPyxis(salesNoteCode49, 'sale-notes');
        Test.stopTest();
        // CHECK ASSERTS
        System.debug('Response: ' + response);
        System.assertEquals(response.statusCode, 201, 'Status code should not be 201');
        List<Opportunity> opp = [SELECT id FROM Opportunity LIMIT 1];
        System.assertEquals(false, [SELECT id FROM Order WHERE OpportunityId = :opp[0].Id].isEmpty(), 'Sales Note should be created');
        System.assertEquals(false, opp.isEmpty(), 'Opportunity should be created');
        //DELETE OPP
        delete opp[0];
        System.assertEquals(true, [SELECT id FROM Order WHERE OpportunityId = :opp[0].Id].isEmpty(), 'Orders should be deleted');
    }

    @isTest
    static void testSetTotalAmountOpp(){
        Test.startTest();
        PyxisAPIServiceHandler.PyxisResponderWrapper response = PyxisAPIServiceHandler.handleRequestPyxis(oderTotalAmounts, 'product-orders');
        Test.stopTest();
        System.assertEquals(response.statusCode, 201, 'Status code should not be 201');
        Opportunity opp = [ SELECT  Total_Amount_Orders__c, Total_Amount_Service_49__c, 
                                    Total_Amount_Not_49__c, Total_Discount__c, 
                                    Main_Section_Name__c, Pyxis_Sales_Type__c 
                            FROM Opportunity LIMIT 1];
        System.assertEquals(opp.Total_Amount_Orders__c, 250.00, 'Total Amount Orders should be 250€');
        System.assertEquals(opp.Total_Amount_Service_49__c, 50.00, 'Total Service Amount should be 50€');
        System.assertEquals(opp.Total_Amount_Not_49__c, 50.00, 'Total Product Amount should be 50€');
        System.assertEquals(opp.Total_Discount__c, 20.00, 'Total Discount Amount should be 20€');
        System.assertEquals(opp.Main_Section_Name__c, '7-LAMINAS', 'Main Section should be 7-LAMINAS');
        System.assertEquals(opp.Pyxis_Sales_Type__c, 'Product_and_Service', 'Sales Type should be Produto e Serviço');
    }

    @isTest
    static void testCheckOrderValidated(){
        Test.startTest();
        PyxisAPIServiceHandler.PyxisResponderWrapper response = PyxisAPIServiceHandler.handleRequestPyxis(orderValidated, 'product-orders');
        Test.stopTest();
        System.assertEquals(response.statusCode, 201, 'Status code should not be 201');
        System.assertEquals(false, [SELECT id FROM Opportunity].isEmpty(), 'Opportunity should be created');
        System.assertEquals([SELECT StageName FROM Opportunity].StageName, 'Operação Em Curso', 'Opportunity Stage should be Operação Em Curso');
    }

    @isTest
    static void testCheckOrderExpired(){
        Test.startTest();
        PyxisAPIServiceHandler.PyxisResponderWrapper response = PyxisAPIServiceHandler.handleRequestPyxis(orderExpired, 'product-orders');
        Test.stopTest();
        System.assertEquals(response.statusCode, 201, 'Status code should not be 201');
        System.assertEquals(false, [SELECT id FROM Opportunity].isEmpty(), 'Opportunity should be created');
        System.assertEquals([SELECT StageName FROM Opportunity].StageName, 'Identificar Motivo de Perda', 'Opportunity Stage should be Identificar Motivo de Perda');
    }

    @isTest
    static void testUpdateQuote(){
        Test.startTest();
        PyxisAPIServiceHandler.PyxisResponderWrapper response = PyxisAPIServiceHandler.handleRequestPyxis(quotePayload, 'quotes');
        PyxisAPIServiceHandler.PyxisResponderWrapper response2 = PyxisAPIServiceHandler.handleRequestPyxis(quotePayload_v2, 'quotes');
        Test.stopTest();
        // CHECK ASSERTS
        System.assertEquals(response.statusCode, 201, 'Status code should not be 201');
        System.assertEquals(response2.statusCode, 201, 'Status code should not be 201');
        System.assertEquals([SELECT Id FROM Opportunity].size(), 1, 'Only one Opportunity should be created');
        System.assertEquals([SELECT Id FROM Quote].size(), 1, 'Only one Quote should be created');
    }

    @isTest
    static void testOrderUpdated(){
        Test.startTest();
        PyxisAPIServiceHandler.PyxisResponderWrapper response = PyxisAPIServiceHandler.handleRequestPyxis(orderPayload, 'product-orders');
        PyxisAPIServiceHandler.PyxisResponderWrapper response2 = PyxisAPIServiceHandler.handleRequestPyxis(orderPayloadv2, 'product-orders');
        Test.stopTest();
        // CHECK ASSERTS
        System.assertEquals(response.statusCode, 201, 'Status code should not be 201');
        System.assertEquals(response2.statusCode, 201, 'Status code should not be 201');
        System.assertEquals([SELECT Id FROM Opportunity].size(), 1, 'Only one Opportunity should be created');
        System.assertEquals([SELECT Id FROM Order].size(), 1, 'Only one Order should be created');
    }

    @isTest
    static void testSalesNoteUpdated (){
        Test.startTest();   
        PyxisAPIServiceHandler.PyxisResponderWrapper response = PyxisAPIServiceHandler.handleRequestPyxis(salesNoteCode49, 'sale-notes');
        PyxisAPIServiceHandler.PyxisResponderWrapper response2 = PyxisAPIServiceHandler.handleRequestPyxis(salesNoteCode49_v2, 'sale-notes');
        Test.stopTest();
        // CHECK ASSERTS
        System.assertEquals(response.statusCode, 201, 'Status code should not be 201');
        System.assertEquals(response2.statusCode, 201, 'Status code should not be 201');
        System.assertEquals([SELECT Id FROM Opportunity].size(), 1, 'Only one Opportunity should be created');
        System.assertEquals([SELECT Id FROM Order].size(), 1, 'Only one Order should be created');
    }

    @isTest
    static void testErroPayload(){
        Test.startTest();
        PyxisAPIServiceHandler.PyxisResponderWrapper responseOrder = PyxisAPIServiceHandler.handleRequestPyxis(orderPayloadFromTransformationError, 'product-orders');
        Test.stopTest();
        System.assertEquals(responseOrder.statusCode, 500, 'Status code should be 500');
        System.assertEquals([SELECT Id FROM Order].size(), 0, 'No Order should be created');
        System.assertNotEquals(null, responseOrder.error.errorMessage, 'Error message should not be null');
    }

    @isTest
    static void incorrectPayload(){
        Test.startTest();
        PyxisAPIServiceHandler.PyxisResponderWrapper responseOrder = PyxisAPIServiceHandler.handleRequestPyxis(incorrectOrderPayload, 'product-orders');
        Test.stopTest();
        System.assertEquals(responseOrder.statusCode, 400, 'Status code should be 400');
        System.assertEquals([SELECT Id FROM Order].size(), 0, 'No Order should be created');
        System.assertNotEquals(null, responseOrder.error.errorMessage, 'Error message should not be null');
    }
}