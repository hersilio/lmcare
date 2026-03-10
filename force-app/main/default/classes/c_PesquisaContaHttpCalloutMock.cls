/**
 * @description       :
 * @author            : Daniel Flores
 * @group             :
 * @last modified on  : 02-10-2024
 * @last modified by  : Francisco Ribeiro
 **/
@isTest
public class c_PesquisaContaHttpCalloutMock implements HttpCalloutMock {
	String body = '';
	Integer status;
	String futureTime;

	public c_PesquisaContaHttpCalloutMock(String type) {
		futureTime = System.now().addDays(20).format('yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'');

		if (type == 'withAccount') {
			body = '{"status":"success","data":{"active":true,"addresses":[{"city":"MAIA","complementaryDeliveryAddress":"MORADIA COSTA DO SOL","countryCode":"PT","isContactPriority":true,"isQualitative":true,"postalCode":"4475","usages":[]}],"clientNumber":2462,"createdAt":"2022-07-06T14:25:01.124Z","creationStoreCode":"1","declaredStoreAttachement":"1","emailAddresses":[],"inhabitant":{"administrativeIdentifiers":{},"civility":"MS","firstName":"MAIA","lastName":"COSTA DO SOL"},"phones":[{"isContactPriority":false,"number":"+351910974671","type":"LANDLINE"},{"isContactPriority":true,"number":"+351910974671"}],"universalClientNumber":"LMPT2462","updatedAt":"' + futureTime + '"},"_meta":{}}}';
			status = 200;
		} else if (type == 'withAccount1') {
			body = '{"status":"success","data":{"active":true,"addresses":[{"city":"MAIA","complementaryDeliveryAddress":"MORADIA COSTA DO SOL","countryCode":"PT","isContactPriority":true,"isQualitative":true,"postalCode":"4475","usages":["INVOICE"]}],"clientNumber":2462,"createdAt":"2022-07-06T14:25:01.124Z","creationStoreCode":"1","declaredStoreAttachement":"1","emailAddresses":[],"inhabitant":{"administrativeIdentifiers":{},"civility":"MS","firstName":"MAIA","lastName":"COSTA DO SOL"},"phones":[{"isContactPriority":false,"number":"+351910974671","type":"LANDLINE"},{"isContactPriority":true,"number":"+351910974671"}],"universalClientNumber":"LMPT2462","updatedAt":"' + futureTime + '"},"_meta":{}}}';
			status = 200;
		} else if (type == 'withAccount2') {
			body = '{"status":"success","data":{"active":true,"addresses":[{"city":"MAIA","complementaryDeliveryAddress":"MORADIA COSTA DO SOL","countryCode":"PT","isContactPriority":true,"isQualitative":true,"postalCode":"4475","usages":["DELIVERY"]}],"clientNumber":2462,"createdAt":"2022-07-06T14:25:01.124Z","creationStoreCode":"1","declaredStoreAttachement":"1","emailAddresses":[],"inhabitant":{"administrativeIdentifiers":{},"civility":"MS","firstName":"MAIA","lastName":"COSTA DO SOL"},"phones":[{"isContactPriority":false,"number":"+351910974671","type":"LANDLINE"},{"isContactPriority":true,"number":"+351910974671"}],"universalClientNumber":"LMPT2462","updatedAt":"' + futureTime + '"},"_meta":{}}}';
			status = 200;
		}else if (type == 'noAccount') {
			status = 200;
			body = '{"status":"success","data": null,"_meta":{"currentPage":1,"estimatedTotalPages":1,"matches":{"clientNumber":[252,980849]},"size":2}}';
		} else if (type == 'SF201') {
			body = '{"status":"success","data":[{"active":true,"addresses":[{"city":"Porto","complementaryDeliveryAddress":"[object Object]","complementaryLocalizationAddress":"Bloco D Entrada 3, C Esq","countryCode":"PT","isContactPriority":true,"isQualitative":true,"postalCode":"4300-122","province":"[object Object]","streetNameNumber":"Rua Cerco Do Porto","usages":[]}],"clientNumber":252,"createdAt":"2022-07-06T14:56:17.604Z","creationStoreCode":"1","declaredStoreAttachement":"1","emailAddresses":[],"inhabitant":{"administrativeIdentifiers":{},"civility":"MR","firstName":"Anibal","gender":"MALE","lastName":"Morgado"},"phones":[{"isContactPriority":false,"number":"+351910974671","type":"MOBILE"},{"isContactPriority":true,"number":"+351910974671","type":"LANDLINE"}],"universalClientNumber":"LMPT252","updatedAt":"' + futureTime + '"},{"active":true,"addresses":[{"city":"CASCAIS","complementaryDeliveryAddress":"PRACETA FIALHO DE ALMEIDA, 60","countryCode":"PT","isContactPriority":true,"isQualitative":true,"postalCode":"2750-664","streetNameNumber":"COBRE","usages":[]}],"clientNumber":980849,"createdAt":"2022-07-06T14:22:41.474Z","creationStoreCode":"5","declaredStoreAttachement":"5","emailAddresses":[{"email":"ANIBAL.MORGADO@GMAIL.COM","isContactPriority":true,"type":"PERSONAL"}],"inhabitant":{"administrativeIdentifiers":{},"civility":"MR","civilStatus":"IN_RELATIONSHIP","dateOfBirth":"1943-12-22","firstName":"ANIBAL","gender":"MALE","professionalClassification":"EMPLOYEE","lastName":"MORGADO"},"phones":[{"isContactPriority":true,"number":"+351910974671","type":"MOBILE"}],"universalClientNumber":"LMPT980849","updatedAt":"' + futureTime + '"}],"_meta":{"currentPage":1,"estimatedTotalPages":1,"matches":{"clientNumber":[252,980849]},"size":2}}';
			status = 201;
		} else if (type == 'SF200') {
			body = '{"status":"success","data":[{"active":true,"addresses":[{"city":"Porto","complementaryDeliveryAddress":"[object Object]","complementaryLocalizationAddress":"Bloco D Entrada 3, C Esq","countryCode":"PT","isContactPriority":true,"isQualitative":true,"postalCode":"4300-122","province":"[object Object]","streetNameNumber":"Rua Cerco Do Porto","usages":[]}],"clientNumber":252,"createdAt":"2022-07-06T14:56:17.604Z","creationStoreCode":"1","declaredStoreAttachement":"1","emailAddresses":[],"inhabitant":{"administrativeIdentifiers":{},"civility":"MR","firstName":"Anibal","gender":"MALE","lastName":"Morgado"},"phones":[{"isContactPriority":false,"number":"+351910974671","type":"MOBILE"},{"isContactPriority":true,"number":"+351910974671","type":"LANDLINE"}],"universalClientNumber":"LMPT252","updatedAt":"' + futureTime + '"},{"active":true,"addresses":[{"city":"CASCAIS","complementaryDeliveryAddress":"PRACETA FIALHO DE ALMEIDA, 60","countryCode":"PT","isContactPriority":true,"isQualitative":true,"postalCode":"2750-664","streetNameNumber":"COBRE","usages":[]}],"clientNumber":980849,"createdAt":"2022-07-06T14:22:41.474Z","creationStoreCode":"5","declaredStoreAttachement":"5","emailAddresses":[{"email":"ANIBAL.MORGADO@GMAIL.COM","isContactPriority":true,"type":"PERSONAL"}],"inhabitant":{"administrativeIdentifiers":{},"civility":"MR","civilStatus":"IN_RELATIONSHIP","dateOfBirth":"1943-12-22","firstName":"ANIBAL","gender":"MALE","professionalClassification":"EMPLOYEE","lastName":"MORGADO"},"phones":[{"isContactPriority":true,"number":"+351910974671","type":"MOBILE"}],"universalClientNumber":"LMPT980849","updatedAt":"' + futureTime + '"}],"_meta":{"currentPage":1,"estimatedTotalPages":1,"matches":{"clientNumber":[252,980849]},"size":2}}';
			status = 200;
		} else if (type == 'token') {
			body = '{"access_token":"eyJhbGciOiJSUzUxMiIsImtpZCI6Ikp3a3MiLCJwaS5hdG0iOiIxIn0.eyJzY29wZSI6W10sImNsaWVudF9pZCI6IjBBMzM1MWY5ZTdkM2E2NzY2YzIwZTRkZGQ4ZGEzODI3MzYiLCJpc3MiOiJodHRwczovL2lkcGIyZS1wcnAuYWRlby5jb20iLCJpYXQiOjE3MDMxNzIxNDEsImV4cCI6MTcwMzE4NjU0MX0.Rg9KWPlRwp3IfZG_pPe2rYl9dJ2Bct6Uh5iywk8H3pH1QQ67YjYBk8RRPKNL98yE7x6VeEuDZ__FCFZYzvD8T6nqDzbdtsFGSILy0icJ-lpFleisiFoPQmtXrNsdvKIMDRXTfknR9TU_CNarvOmBl-j93rQfq4ICpX7CVcTPsWufY0z1f-ws-Hija3n5u4K1zWmMtDjVWvhxo0RhsTZlcB0u3MjGBTnORB9TOTwpFcFJf2qLuRZhMkEpw9s3YbzedI_4M396pgUEFzh6f9xyfz2xUB2cSsjmqdiRkQQbMPO8Ygu5FDo1Ddyuxd2I6qMK6hfjvABluW7STuQLza0vBw","token_type":"Bearer","expires_in":14399}';
			status = 200;
		} else if (type == 'errortoken') {
			body = '{"access_token":"eyJhbGciOiJSUzUxMiIsImtpZCI6Ikp3a3MiLCJwaS5hdG0iOiIxIn0.eyJzY29wZSI6W10sImNsaWVudF9pZCI6IjBBMzM1MWY5ZTdkM2E2NzY2YzIwZTRkZGQ4ZGEzODI3MzYiLCJpc3MiOiJodHRwczovL2lkcGIyZS1wcnAuYWRlby5jb20iLCJpYXQiOjE3MDMxNzIxNDEsImV4cCI6MTcwMzE4NjU0MX0.Rg9KWPlRwp3IfZG_pPe2rYl9dJ2Bct6Uh5iywk8H3pH1QQ67YjYBk8RRPKNL98yE7x6VeEuDZ__FCFZYzvD8T6nqDzbdtsFGSILy0icJ-lpFleisiFoPQmtXrNsdvKIMDRXTfknR9TU_CNarvOmBl-j93rQfq4ICpX7CVcTPsWufY0z1f-ws-Hija3n5u4K1zWmMtDjVWvhxo0RhsTZlcB0u3MjGBTnORB9TOTwpFcFJf2qLuRZhMkEpw9s3YbzedI_4M396pgUEFzh6f9xyfz2xUB2cSsjmqdiRkQQbMPO8Ygu5FDo1Ddyuxd2I6qMK6hfjvABluW7STuQLza0vBw","token_type":"Bearer","expires_in":14399}';
			status = 400;
		} else if (type == 'OneAccount') {
			body = '{"status":"success","data":{"active":true,"addresses":[{"city":"MAIA","countryCode":"PT","isContactPriority":true,"postalCode":"4475","usages":[]}],"clientNumber":2462,"createdAt":"2022-07-06T14:25:01.124Z","emailAddresses":[],"inhabitant":{"administrativeIdentifiers":{},"civility":"MR","firstName":"MAIA","lastName":"COSTA DO SOL"},"phones":[],"universalClientNumber":"LMPT2462","updatedAt":"' + futureTime + '"},"_meta":{}}';
			status = 201;
		}
	}

	public HTTPResponse respond(HTTPRequest request) {
		// Create a fake response
		HttpResponse response = new HttpResponse();
		response.setBody(body);
		response.setStatusCode(status);
		return response;
	}
}