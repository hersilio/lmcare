/**
 * @description       :
 * @author            : Daniel Flores
 * @group             :
 * @last modified on  : 02-10-2024
 * @last modified by  : Francisco Ribeiro
 **/

public with sharing class c_AccountUpdateMDM {
	/*
	@future(callout=true)
	public static void AccountUpdateMDM(List<Id> accountsForUpdate) {
		String getAuthLeroyToken = getToken();
		List<Account> accounts = getAccountsByIds(accountsForUpdate);
		MDM_EndPoint__mdt Endpoint = [
			SELECT EndPoint__c, ApiKey__c, isSandBox__c
			FROM MDM_EndPoint__mdt
			WHERE isSandBox__c = TRUE AND Label = 'Webservice MDM'
		];

		HttpRequest reqGet = new HttpRequest();
		reqGet.setMethod('GET');
		reqGet.setHeader('x-Gateway-APIKey', Endpoint.ApiKey__c);
		reqGet.setHeader('Authorization', getAuthLeroyToken);

		for (Account accnt : accounts) {
			if (accnt.Numero_de_Conta__c != null) {
				reqGet.setEndpoint(
					Endpoint.EndPoint__c +
					'/clients?filter=[{"clientNumber":{"$eq":"' +
					accnt.Numero_de_Conta__c +
					'"}}]'
				);

				Http http = new Http();
				HTTPResponse resGet = new HTTPResponse();

				if (!Test.isRunningTest()) {
					resGet = http.send(reqGet);
				} else {
					resGet.setStatusCode(200);
					resGet.setBody(
						'{"status":"success","data":[{"active":true,"addresses":[{"city":"LISBON","countryCode":"PT","isContactPriority":true,"postalCode":"1234-123","usages":[]}],"clientNumber":10022137,"createdAt":"2022-03-21T12:32:28.670Z","creationStoreCode":"1","declaredStoreAttachement":"1","emailAddresses":[{"email":"testfida@gmail.com","isContactPriority":true,"type":"PERSONAL"}],"inhabitant":{"administrativeIdentifiers":{"nif":"123456789"},"civility":"MR","firstName":"TESTFIDA","gender":"MALE","lastName":"TESTFIDA"},"phones":[{"isContactPriority":true,"number":"123456789","type":"MOBILE"}],"universalClientNumber":"LMPT10022137","updatedAt":"2024-02-02T18:42:25.965Z","members":[]}],"_meta":{}}'
					);
				}

				String jsonStr = JSON.serialize(resGet.getBody());

				System.debug(resGet.getBody());
				jsonStr = jsonStr.replace('"number\\":', '"numberSF":');
				jsonStr = jsonStr.replace('\\', '');
				jsonStr = jsonStr.removeEnd('"');
				jsonStr = jsonStr.removeStart('"');
				if (jsonStr.contains('"clientNumber":""')) {
					jsonStr = jsonStr.replace('"clientNumber":""', '"clientNumber":"0"');
				}
				// Deserialize the JSON string into collections of primitive data type
				MDM_Response response = (MDM_Response) JSON.deserialize(
					jsonStr,
					MDM_Response.class
				);
				System.debug(response);

				MDM_Client NewAccount = response.data[0];
				NewAccount.updatedAt = null;
				NewAccount.createdAt = null;
				
				MDM_Client.EmailAddress emailAddress = new MDM_Client.EmailAddress();

				if (accnt.RecordTypeId == GetProfissionalRecordTypeId()) {
					System.debug('is professional organization');
					NewAccount.professionalOrganization.name = accnt.Name;
					NewAccount.professionalOrganization.registeredName = accnt.Name;
					NewAccount.professionalOrganization.administrativeCodes.nif = accnt.NIF__c;
				} else {
					NewAccount.inhabitant.firstName = accnt.FirstName;
					NewAccount.inhabitant.lastName = accnt.LastName;
					NewAccount.inhabitant.administrativeIdentifiers.nif = accnt.NIF__c;
				}

				emailAddress.email = accnt.E_mail_Empresa__c == null ? accnt.PersonEmail: accnt.E_mail_Empresa__c;
				emailAddress.isContactPriority = true;

				Boolean isMissingMembers = false;
				if (accnt.RecordTypeId == GetProfissionalRecordTypeId()) {
					isMissingMembers = NewAccount.members == null ? true : NewAccount.members.isEmpty()? true : false;
				}

				string fname = '';
				if (accnt.Name.split(' ').size() > 0) {
					for (Integer i = 0; i < accnt.Name.split(' ').size(); i++) {
						fname = fname + accnt.Name.split(' ')[i] +  ' ';
					}
				}

				if(!isMissingMembers && accnt.RecordTypeId == GetProfissionalRecordTypeId()){
					
					System.debug('Has members');
					NewAccount.members[0].LastName = accnt.Name.split(' ').size() > 0 ? accnt.Name.split(' ')[accnt.Name.split(' ').size() - 1] : accnt.Name;
					NewAccount.members[0].firstName = fname;

					MDM_Client.Phone phone = new MDM_Client.Phone();
					phone.numberSF = accnt.Phone == null || accnt.Phone == '' ? accnt.PersonMobilePhone: accnt.Phone;
					phone.isContactPriority = true;
					if (NewAccount.members[0].phones != null && ( phone.numberSF != null && phone.numberSF != '')) {
						if (!NewAccount.members[0].phones.isEmpty()) {
							NewAccount.members[0].phones[0] = phone;
						}else {
							NewAccount.members[0].phones.add(phone);
						}
					}else if (phone.numberSF != null && phone.numberSF != '') {
						List<MDM_Client.Phone> phoneslst = new List<MDM_Client.Phone>();
						phone.type = 'MOBILE';
						phoneslst.add(phone);
						NewAccount.members[0].phones = phoneslst;
					}

					if (NewAccount.members[0].emailAddresses != null) {
						if (!NewAccount.members[0].emailAddresses.isEmpty()) {
							NewAccount.members[0].emailAddresses[0] = emailAddress;
						}else {
							NewAccount.members[0].emailAddresses.add(emailAddress);
						}
					}else if (emailAddress.email != null && emailAddress.email != '') {
						List<MDM_Client.EmailAddress> emailsList = new List<MDM_Client.EmailAddress>();
						emailAddress.type = 'PERSONAL';
						emailsList.add(emailAddress);
						NewAccount.members[0].emailAddresses = emailsList;
					}
					System.debug(NewAccount.members[0]);
				}else if (accnt.RecordTypeId == GetProfissionalRecordTypeId()){

					System.debug('is missing member');

					NewAccount.members = new List<MDM_Client.Member>();
					MDM_Client.Member member = new MDM_Client.Member();

					member.LastName = accnt.Name.split(' ').size() > 0 ? accnt.Name.split(' ')[accnt.Name.split(' ').size() - 1] : accnt.Name;
					member.firstName = fname;
					member.isLegalRepresentative = true;
					
					member.emailAddresses = new List<MDM_Client.EmailAddress>();
					emailAddress.isContactPriority = true;
					emailAddress.type = 'PERSONAL';

					emailAddress.email = accnt.E_mail_Empresa__c == null ? accnt.PersonEmail: accnt.E_mail_Empresa__c;
					
					member.emailAddresses.add(emailAddress);
					member.phones = new List<MDM_Client.Phone>();

					if ((accnt.Phone != null && accnt.Phone != '') || (accnt.PersonMobilePhone != null && accnt.PersonMobilePhone != '') ) {
						MDM_Client.Phone phone = new MDM_Client.Phone();
						phone.numberSF = accnt.Phone == null || accnt.Phone == '' ? accnt.PersonMobilePhone: accnt.Phone;
						phone.isContactPriority = true;
						phone.type = 'MOBILE';
						member.phones.add(phone);
					}
					NewAccount.members.add(member);
				}

				String phoness;
				if ((accnt.Phone != null && accnt.Phone != '') || (accnt.PersonMobilePhone != null && accnt.PersonMobilePhone != '') ) {
					phoness = accnt.PersonMobilePhone == null || accnt.PersonMobilePhone == '' ? accnt.Phone: accnt.PersonMobilePhone;
				}
				
				if (phoness != null) {
					if (NewAccount.phones != null && !NewAccount.phones.isEmpty()) {	
						NewAccount.phones[0].isContactPriority = true;
						NewAccount.phones[0].numberSF = phoness;
					}else {
						NewAccount.phones = new List<MDM_Client.Phone>();
						MDM_Client.Phone ph = new MDM_Client.Phone();
						ph.numberSF = phoness;
						ph.isContactPriority = true;
						NewAccount.phones.add(ph);
					}
				}

				if (emailAddress.email != null) {	
					NewAccount.emailAddresses =  new List<MDM_Client.EmailAddress>();
					NewAccount.emailAddresses.add(emailAddress);
				}
				
				NewAccount.clientNumber = Integer.valueOf(
					accnt.Numero_de_Conta__c
				);

				if (accnt.ShippingAddress != null || accnt.BillingAddress != null ) {

					Boolean isSameDelivery = false;
					MDM_Client.Address addrInvoice = null;
					MDM_Client.Address addrDelivery = null;
					Boolean hasInvoice = false;
					Boolean hasDelivery = false;

					List<MDM_Client.Address> newAddresses = new List<MDM_Client.Address>();

					if (accnt.ShippingAddress == accnt.BillingAddress &&  accnt.BillingAddress != null && accnt.ShippingAddress != null) {
						System.debug('equal adresses');
						addrDelivery = new MDM_Client.Address();
						addrDelivery.usages = new List<String>();
						addrDelivery.usages.add('DELIVERY');
						addrDelivery.usages.add('INVOICE');
						addrDelivery.postalCode = accnt.ShippingPostalCode;
						addrDelivery.city = accnt.ShippingCity;
						addrDelivery.countryCode = accnt.ShippingCountryCode;
						addrDelivery.streetNameNumber = accnt.ShippingStreet;
						hasInvoice = true;
						hasDelivery = true;
						newAddresses.add(addrDelivery);
					}

					if (!hasDelivery && !hasInvoice) {
						System.debug('adresses are diferent');

						System.debug(accnt.ShippingAddress);
						System.debug(accnt.BillingAddress);
						if (accnt.ShippingAddress != null) {
							addrDelivery = new MDM_Client.Address();
							addrDelivery.usages = new List<String>();
							addrDelivery.usages.add('DELIVERY');
							addrDelivery.postalCode = accnt.ShippingPostalCode;
							addrDelivery.city = accnt.ShippingCity;
							addrDelivery.countryCode = accnt.ShippingCountryCode;
							addrDelivery.streetNameNumber = accnt.ShippingStreet;
							hasDelivery = true;
							newAddresses.add(addrDelivery);
						}
						if (accnt.BillingAddress != null) {
							addrInvoice = new MDM_Client.Address();
							addrInvoice.usages = new List<String>();
							addrInvoice.usages.add('INVOICE');
							addrInvoice.postalCode = accnt.BillingPostalCode;
							addrInvoice.city = accnt.BillingCity;
							addrInvoice.countryCode = accnt.BillingCountryCode;
							addrInvoice.streetNameNumber = accnt.BillingStreet;
							hasInvoice = true;
							newAddresses.add(addrInvoice);
						}
					}

					for (MDM_Client.Address addr : NewAccount.addresses) {
						Boolean hasFoundInvoice = false;
						Boolean hasFoundDelivery = false;
						if (addr.usages != null && !addr.usages.isEmpty()) {
							for (String usage : addr.usages) {
								if (usage == 'INVOICE') {
									hasFoundInvoice = true;
								}
								if (usage == 'DELIVERY') {
									hasFoundDelivery = true;
								}
							}
							if (hasFoundDelivery && hasFoundInvoice && !hasDelivery && !hasInvoice) {
								newAddresses.add(addr);
							}
							if (hasFoundDelivery && !hasDelivery) {
								newAddresses.add(addr);
							}else if (hasFoundInvoice && !hasInvoice) {
								newAddresses.add(addr);
							}
						}else {
							newAddresses.add(addr);
						}	
					}

					NewAccount.addresses = newAddresses;
				}

				String jsonBody = JSON.serialize(NewAccount);

				jsonBody = jsonBody.replace('numberSF', 'number');				
				jsonBody = jsonBody.replace('"RecordTypeId":null,', '');
				jsonBody = jsonBody.replace('"Id":null,', ''); 
				jsonBody = jsonBody.replace('"createdAt":"' + NewAccount.createdAt+'"', '');
				jsonBody = jsonBody.replace('"updatedAt":"' + NewAccount.updatedAt+'"', '');
				System.debug(jsonBody);

				HttpRequest req = new HttpRequest();
				req.setEndpoint(
					Endpoint.EndPoint__c +
						'/clients/' +
						accnt.Numero_de_Conta__c
				);
				req.setMethod('PUT');
				req.setHeader('x-Gateway-APIKey', Endpoint.ApiKey__c);
				req.setHeader('Authorization', getAuthLeroyToken);
				req.setTimeout(20000);

				req.setbody(jsonBody);
				Http http2 = new Http();
				HTTPResponse responseUpdate = http2.send(req);
				System.debug(responseUpdate.getBody());

				if (
					responseUpdate.getStatusCode() == 200 ||
					responseUpdate.getStatusCode() == 201
				) {
					System.debug('Yupi');
				} else {

					//!passar para string o atributo no member
					System.debug('Capote');
				}
			} else {
				List<Id> accIds = new List<Id>();
				accIds.add(accnt.Id);
				c_AccountInsertMDM.AccountUpdateMDM(accIds);
			}
		}
	}
	*/

	@AuraEnabled(cacheable=true)
	public static String getToken() {
		MDM_EndPoint__mdt LeroyToken = [
			SELECT
				ClientId__c,
				ClientSecret__c,
				DeveloperName,
				isSandBox__c,
				EndPoint__c
			FROM MDM_EndPoint__mdt
			WHERE DeveloperName = 'GetTokenLeroy'
		];

		HttpRequest req = new HttpRequest();
		req.setMethod('POST');
		req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
		String auth = EncodingUtil.base64Encode(
			Blob.valueOf(
				LeroyToken.ClientId__c + ':' + LeroyToken.ClientSecret__c
			)
		);
		req.setEndpoint(
			LeroyToken.EndPoint__c + '?grant_type=client_credentials'
		);
		req.setHeader('Authorization', 'Basic ' + auth);
		Http http = new Http();
		HTTPResponse response = http.send(req);
		if (Test.isRunningTest()) {
			response.setBody(
				'{"access_token":"eyJhbGciOiJSUzUxMiIsImtpZCI6Ikp3a3MiLCJwaS5hdG0iOiIxIn0.eyJzY29wZSI6W10sImNsaWVudF9pZCI6IjBBMzM1MWY5ZTdkM2E2NzY2YzIwZTRkZGQ4ZGEzODI3MzYiLCJpc3MiOiJodHRwczovL2lkcGIyZS1wcnAuYWRlby5jb20iLCJpYXQiOjE3MDMxNzIxNDEsImV4cCI6MTcwMzE4NjU0MX0.Rg9KWPlRwp3IfZG_pPe2rYl9dJ2Bct6Uh5iywk8H3pH1QQ67YjYBk8RRPKNL98yE7x6VeEuDZ__FCFZYzvD8T6nqDzbdtsFGSILy0icJ-lpFleisiFoPQmtXrNsdvKIMDRXTfknR9TU_CNarvOmBl-j93rQfq4ICpX7CVcTPsWufY0z1f-ws-Hija3n5u4K1zWmMtDjVWvhxo0RhsTZlcB0u3MjGBTnORB9TOTwpFcFJf2qLuRZhMkEpw9s3YbzedI_4M396pgUEFzh6f9xyfz2xUB2cSsjmqdiRkQQbMPO8Ygu5FDo1Ddyuxd2I6qMK6hfjvABluW7STuQLza0vBw","token_type":"Bearer","expires_in":14399}'
			);
		}

		if (
			response.getStatusCode() == 200 ||
			response.getStatusCode() == 201
		) {
			Point ResToken = (Point) JSON.deserialize(
				response.getBody(),
				Point.class
			);
			String Token = ResToken.access_token;
			return Token;
		}
		return null;
	}
	@AuraEnabled(cacheable=true)
	public static List<Account> getAccountsByIds(List<Id> accountIds) {
		// Construct a SOQL query to retrieve the desired fields from the Account object
		String query = 'SELECT Id, IsDeleted, MasterRecordId, Name, LastName, FirstName, Salutation, MiddleName, Suffix, Type, RecordTypeId, ParentId, BillingStreet, BillingCity, BillingPostalCode, BillingCountry, BillingCountryCode, BillingLatitude, BillingLongitude, BillingGeocodeAccuracy, BillingAddress, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, ShippingStateCode, ShippingCountryCode, ShippingLatitude, ShippingLongitude, ShippingGeocodeAccuracy, ShippingAddress, Phone, AccountNumber, Website, PhotoUrl, Industry, NumberOfEmployees, Description, OwnerId, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, LastActivityDate, LastViewedDate, LastReferencedDate, PersonContactId, IsPersonAccount, PersonMailingStreet, PersonMailingCity, PersonMailingState, PersonMailingPostalCode, PersonMailingCountry, PersonMailingStateCode, PersonMailingCountryCode, PersonMailingLatitude, PersonMailingLongitude, PersonMailingGeocodeAccuracy, PersonMailingAddress, PersonMobilePhone, PersonHomePhone, PersonOtherPhone, PersonAssistantPhone, PersonEmail, PersonTitle, PersonDepartment, PersonBirthdate, PersonLastCURequestDate, PersonLastCUUpdateDate, PersonEmailBouncedReason, PersonEmailBouncedDate, PersonIndividualId, Jigsaw, JigsawCompanyId, AccountSource, SicDesc, OperatingHoursId, Cliente_com_Credito__c, NIF__c, Numero_de_Conta__c, Setor_de_Atividade__c, Tem_cartao_Leroy_Merlin__c, Volume_de_Faturacao__c, Sub_Empresa__c, E_mail_Empresa__c, OPTIN_EMAIL__c, OPTIN_SMS__c, OPTIN_CHAMADAS__c, Importado__c, EnderecoCompleto__c, Certification_No__c, Country_key__c, Is_LM_Installer__c, Preffered_Contact__c, Record_Type_API_Name__c, Decisor__pc, Funcao__pc, Pessoa_Autorizada__pc  FROM ACCOUNT  WHERE Id IN :accountIds';

		// Use Database.query to execute the SOQL query and retrieve the Account records
		List<Account> accounts = Database.query(query);

		return accounts;
	}
	@AuraEnabled(cacheable=true)
	public static String GetProfissionalRecordTypeId() {
		return [
			SELECT Id
			FROM RecordType
			WHERE DeveloperName = 'Conta_Empresa'
		]
		.Id;
	}

	public class MDM_Response {
		@AuraEnabled
		public String status;
		@AuraEnabled
		public List<MDM_Client> data;
	
		/* @AuraEnabled
		 public Meta _meta; */
	}

	public class Point {
		@AuraEnabled
		public String access_token;
	}
}