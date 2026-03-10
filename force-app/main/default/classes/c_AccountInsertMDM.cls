/**
 * @description       :
 * @author            : Daniel Flores
 * @group             :
 * @last modified on  : 02-10-2024
 * @last modified by  : Francisco Ribeiro
 **/
public with sharing class c_AccountInsertMDM {
	/*
	@future(callout=true)
	public static void AccountUpdateMDM(List<Id> accountsForUpdate) {
		String getAuthLeroyToken = (Test.isRunningTest() ? '12345' : getToken());
        
		List<Account> accounts = getAccountsByIds(accountsForUpdate);
		MDM_EndPoint__mdt Endpoint = [
			SELECT EndPoint__c, ApiKey__c, isSandBox__c
			FROM MDM_EndPoint__mdt
			WHERE isSandBox__c = TRUE AND Label = 'Webservice MDM'
		];
		for (Account account : accounts) {

			MDM_Client NewAccount = new MDM_Client();
			MDM_Client.EmailAddress emailAddress = new MDM_Client.EmailAddress();

			NewAccount.active = true;

			System.debug(account);
			if (account.RecordTypeId == GetProfissionalRecordTypeId()) {
				NewAccount.professionalOrganization = new MDM_Client.professionalOrganization();
				NewAccount.professionalOrganization.registeredName = account.Name;
				NewAccount.professionalOrganization.administrativeCodes = new MDM_Client.administrativeCode();
				NewAccount.professionalOrganization.administrativeCodes.nif = account.NIF__c;
			} else {
				NewAccount.inhabitant = new MDM_Client.inhabitant();
				NewAccount.inhabitant.firstName = account.FirstName;
				NewAccount.inhabitant.lastName = account.LastName;
				NewAccount.inhabitant.administrativeIdentifiers = new MDM_Client.administrativeIdentifier();
				NewAccount.inhabitant.administrativeIdentifiers.nif = account.NIF__c;
			}

			if(account.Numero_de_Conta__c != null){
				NewAccount.clientNumber = Integer.valueOf(
					account.Numero_de_Conta__c
				);
			}

			NewAccount.members = new List<MDM_Client.Member>();
			MDM_Client.Member member = new MDM_Client.Member();

			string fname = '';
			if (account.Name.split(' ').size() > 0) {
				for (Integer i = 0; i < account.Name.split(' ').size(); i++) {
					fname = fname + account.Name.split(' ')[i] +  ' ';
				}
			}
			member.LastName = account.Name.split(' ').size() > 0 ? account.Name.split(' ')[account.Name.split(' ').size() - 1] : account.Name;
			member.firstName = fname;
			member.isLegalRepresentative = true;
			
			member.emailAddresses = new List<MDM_Client.EmailAddress>();
			emailAddress.isContactPriority = true;
			emailAddress.type = 'PERSONAL';

			emailAddress.email = account.E_mail_Empresa__c == null ? account.PersonEmail: account.E_mail_Empresa__c;
			
			member.emailAddresses.add(emailAddress);

			if (emailAddress.email != null) {	
				NewAccount.emailAddresses =  new List<MDM_Client.EmailAddress>();
				NewAccount.emailAddresses.add(emailAddress);
			}
			
			member.phones = new List<MDM_Client.Phone>();
			NewAccount.phones = new List<MDM_Client.Phone>();

			if ((account.Phone != null && account.Phone != '') || (account.PersonMobilePhone != null && account.PersonMobilePhone != '') ) {
				MDM_Client.Phone phone = new MDM_Client.Phone();
				phone.numberSF = account.Phone == null || account.Phone == '' ? account.PersonMobilePhone: account.Phone;
				phone.isContactPriority = true;
				phone.type = 'MOBILE';
				member.phones.add(phone);
				if (account.RecordTypeId != GetProfissionalRecordTypeId()) {
					NewAccount.phones.add(phone);
				}
			}
			
			if (account.RecordTypeId == GetProfissionalRecordTypeId()) {
				NewAccount.members.add(member);
			}


			if (account.ShippingAddress != null || account.BillingAddress != null ) {
				NewAccount.addresses = new List<MDM_Client.Address>();
				MDM_Client.Address addrInvoice = new MDM_Client.Address();
				MDM_Client.Address addrDelivery = new MDM_Client.Address();

				if (account.ShippingAddress != null) {
					addrDelivery.usages = new List<String>();
					addrDelivery.usages.add('DELIVERY');
					addrDelivery.postalCode = account.ShippingPostalCode;
					addrDelivery.city = account.ShippingCity;
					addrDelivery.countryCode = account.ShippingCountryCode;
					addrDelivery.streetNameNumber = account.ShippingStreet;
				}
				if (account.BillingAddress != null) {
					addrInvoice.usages = new List<String>();
					addrInvoice.usages.add('INVOICE');
					addrInvoice.postalCode = account.BillingPostalCode;
					addrInvoice.city = account.BillingCity;
					addrInvoice.countryCode = account.BillingCountryCode;
					addrInvoice.streetNameNumber = account.BillingStreet;
				}

				if (addrInvoice != null) {
					NewAccount.addresses.add(addrInvoice);
				}else if (addrDelivery != null) {
					NewAccount.addresses.add(addrDelivery);
				}
			}

			String jsonBody = JSON.serialize(NewAccount);
			jsonBody = jsonBody.replace('numberSF', 'number');
			System.debug(jsonBody);

			HttpRequest req = new HttpRequest();
			req.setEndpoint(
				Endpoint.EndPoint__c + 'clients'
			);
			req.setMethod('POST');
			req.setHeader('x-Gateway-APIKey', Endpoint.ApiKey__c);
			req.setHeader('Authorization', getAuthLeroyToken);
			req.setbody(jsonBody);
			Http http = new Http();
			HTTPResponse response = http.send(req);
			System.debug(response.getBody());

			if (
				response.getStatusCode() == 200 ||
				response.getStatusCode() == 201
			) {
				System.debug('Yupi');

				// Deserialize the JSON response into an object
				Map<String, Object> parsedResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

				// Accessing the clientNumber attribute
				Map<String, Object> data = (Map<String, Object>) parsedResponse.get('data');
				String clientNumber = String.valueOf(data.get('clientNumber'));
				Account acc = new Account(Id = account.Id);
				acc.Numero_de_Conta__c =clientNumber;
				acc.isSynced__c = true;
        		acc.isSyncedTime__c = System.now();
				update acc;
			} else {
				System.debug('Capote');
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
	public class Point {
		@AuraEnabled
		public String access_token;
	}
}