/**
 * @description       :
 * @author            : Daniel Flores
 * @group             :
 * @last modified on  : 03-12-2024
 * @last modified by  : João Rosa
 **/
public with sharing class CompareSFAccountsWithMDM {
	@AuraEnabled
	public static void CompareAccounts(Id IdConta) {
		System.debug(IdConta);
		Account account = getParameters(IdConta);
		if (account.Numero_de_Conta__c != null) {
			String getAuthLeroyToken = C_pesquisaConta.getToken();
			Boolean isSandbox = [SELECT IsSandbox, Id FROM Organization].IsSandbox;
			
			MDM_EndPoint__mdt Endpoint = [
				SELECT EndPoint__c, ApiKey__c, isSandBox__c
				FROM MDM_EndPoint__mdt
				WHERE isSandBox__c = :isSandbox AND Label = 'Webservice MDM'
			];
			HttpRequest req = new HttpRequest();
			req.setEndpoint(
				Endpoint.EndPoint__c + '/clients/' + account.Numero_de_Conta__c
			);
			req.setMethod('GET');
			req.setHeader('x-Gateway-APIKey', Endpoint.ApiKey__c);
			req.setHeader('Authorization', getAuthLeroyToken);
			Http http = new Http();
			HTTPResponse res = http.send(req);

			if (res.getStatusCode() == 200) {
				String jsonStr = JSON.serialize(res.getBody());
				jsonStr = jsonStr.replace('"number\\":', '"numberSF":');
				jsonStr = jsonStr.replace('\\', '');
				jsonStr = jsonStr.removeEnd('"');
				jsonStr = jsonStr.removeStart('"');
				if(jsonStr.contains('"clientNumber":""')){
					jsonStr = jsonStr.replace('"clientNumber":""', '"clientNumber":"0"');
				}

				MDM_Response response = (MDM_Response) JSON.deserialize(
					jsonStr,
					MDM_Response.class
				);
				System.debug(response.data);
				MDM_Client MdmAccount = response.data;
				if (response.data != null) {
					if (MdmAccount.updatedAt > account.LastModifiedDate) {
						System.debug('A data de MDM é mais recente');
						updateAccountSf(MdmAccount, IdConta);
					} /* else {
						System.debug('A data de Salesforce é mais recente');
						updateAccountMDM(IdConta);
					} */
				}
			}
		}/* else {
			InsertAccountMDM(IdConta);
		}*/
		
	}
	@AuraEnabled
	public static Account getParameters(Id IdConta) {
		// Construct a SOQL query to retrieve the desired fields from the Account object
		String query = 'SELECT Id, IsDeleted, MasterRecordId, Name, LastName, FirstName, Salutation, MiddleName, Suffix, Type, RecordTypeId, ParentId, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingStateCode, BillingCountryCode, BillingLatitude, BillingLongitude, BillingGeocodeAccuracy, BillingAddress, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, ShippingStateCode, ShippingCountryCode, ShippingLatitude, ShippingLongitude, ShippingGeocodeAccuracy, ShippingAddress, Phone, AccountNumber, Website, PhotoUrl, Industry, NumberOfEmployees, Description, OwnerId, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, SystemModstamp, LastActivityDate, LastViewedDate, LastReferencedDate, PersonContactId, IsPersonAccount, PersonMailingStreet, PersonMailingCity, PersonMailingState, PersonMailingPostalCode, PersonMailingCountry, PersonMailingStateCode, PersonMailingCountryCode, PersonMailingLatitude, PersonMailingLongitude, PersonMailingGeocodeAccuracy, PersonMailingAddress, PersonMobilePhone, PersonHomePhone, PersonOtherPhone, PersonAssistantPhone, PersonEmail, PersonTitle, PersonDepartment, PersonBirthdate, PersonLastCURequestDate, PersonLastCUUpdateDate, PersonEmailBouncedReason, PersonEmailBouncedDate, PersonIndividualId, Jigsaw, JigsawCompanyId, AccountSource, SicDesc, OperatingHoursId, Cliente_com_Credito__c, NIF__c, Numero_de_Conta__c, Setor_de_Atividade__c, Tem_cartao_Leroy_Merlin__c, Volume_de_Faturacao__c, Sub_Empresa__c, E_mail_Empresa__c, OPTIN_EMAIL__c, OPTIN_SMS__c, OPTIN_CHAMADAS__c, Importado__c, EnderecoCompleto__c, Certification_No__c, Country_key__c, Is_LM_Installer__c, Preffered_Contact__c, Record_Type_API_Name__c, Decisor__pc, Funcao__pc, Pessoa_Autorizada__pc  FROM ACCOUNT  WHERE Id = :IdConta Limit 1';

		// Use Database.query to execute the SOQL query and retrieve the Account records
		Account account = Database.query(query);

		return account;
	}
	@AuraEnabled
	public static void updateAccountSf(
		MDM_Client clientMDM,
		Id AccountIdToUpdate
	) {
		List<Account> accountToUpdate = ListAccountsWithSameId(
			AccountIdToUpdate
		);

		List<Account> ListAccountForUpdate = new List<Account>();

		for (Account acc : accountToUpdate) {
			System.debug(clientMDM);
			acc.Numero_de_Conta__c = String.valueOf(clientMDM.clientNumber);
			acc.FirstName = clientMDM.inhabitant.firstName;
			acc.LastName = clientMDM.inhabitant.lastName;
			acc.NIF__c = clientMDM.inhabitant.administrativeIdentifiers.nif;
			for (MDM_Client.Address address : clientMDM.addresses) {
				acc.BillingPostalCode = address.postalCode;
				acc.BillingCity = address.city;
				acc.BillingCountryCode = address.countryCode;
				acc.ShippingCity = address.complementaryDeliveryAddress;
			}
			for (
				MDM_Client.EmailAddress emailaddress : clientMDM.emailAddresses
			) {
				acc.PersonEmail = emailaddress.email;
			}
			for (MDM_Client.Phone phone : clientMDM.phones) {
				if (phone.isContactPriority == true) {
					String phoness = phone.numberSF;
					System.debug(phoness);
					System.debug(acc.Country_key__c);
					phoness = phoness.replace(acc.Country_key__c, '');
					System.debug(phoness);
					acc.Phone = phoness;
				}
			}
			acc.UpdateTime__c = String.valueof(System.now());

			System.debug('phone: ' + acc.Phone);
			System.debug('country: ' + acc.BillingCountry);
			ListAccountForUpdate.add(acc);
		}

		update ListAccountForUpdate;
	}

	/* 
	@AuraEnabled
	public static void updateAccountMDM(Id AccountIdToUpdate) {

		List<Id> ids = new List<Id>();
		ids.add(AccountIdToUpdate);
		c_AccountUpdateMDM.AccountUpdateMDM(ids);

		List<Account> accountToUpdate = ListAccountsWithSameId(
			AccountIdToUpdate
		);
		String getAuthLeroyToken = C_pesquisaConta.getToken();
		MDM_EndPoint__mdt Endpoint = [
			SELECT EndPoint__c, ApiKey__c, isSandBox__c
			FROM MDM_EndPoint__mdt
			WHERE isSandBox__c = TRUE AND Label = 'Webservice MDM'
		];
		MDM_Client NewAccount = new MDM_Client();
		NewAccount.emailAddresses = new List<MDM_Client.EmailAddress>();
		NewAccount.phones = new List<MDM_Client.Phone>();
		MDM_Client.Phone phone = new MDM_Client.Phone();
		MDM_Client.EmailAddress EmailAddress = new MDM_Client.EmailAddress();
		for (Account account : accountToUpdate) {
			if (
				account.RecordTypeId ==
				c_AccountUpdateMDM.GetProfissionalRecordTypeId()
			) {
				NewAccount.professionalOrganization = new MDM_Client.professionalOrganization();
				NewAccount.professionalOrganization.name = account.Name;
				NewAccount.professionalOrganization.administrativeCodes = new MDM_Client.administrativeCode();
				NewAccount.professionalOrganization.administrativeCodes.nif = account.NIF__c;
			} else {
				NewAccount.inhabitant = new MDM_Client.inhabitant();
				NewAccount.inhabitant.firstName = account.FirstName;
				NewAccount.inhabitant.lastName = account.LastName;
				NewAccount.inhabitant.administrativeIdentifiers = new MDM_Client.administrativeIdentifier();
				NewAccount.inhabitant.administrativeIdentifiers.nif = account.NIF__c;
				EmailAddress.email = account.PersonEmail;
				NewAccount.emailAddresses.add(EmailAddress);
			}
			phone.numberSF = account.Country_key__c + account.Phone;
			NewAccount.clientNumber = Integer.valueOf(
				account.Numero_de_Conta__c
			);
			NewAccount.addresses = new List<MDM_Client.Address>();
			MDM_Client.Address address = new MDM_Client.Address();
			address.postalCode = account.BillingPostalCode;
			address.city = account.BillingCity;
			address.countryCode = account.BillingCountryCode;
			address.province = account.BillingState;
			NewAccount.addresses.add(address);

			String jsonBody = JSON.serialize(NewAccount);
			HttpRequest req = new HttpRequest();
			req.setEndpoint(
				Endpoint.EndPoint__c + '/clients/' + account.Numero_de_Conta__c
			);
			req.setMethod('PUT');
			req.setHeader('x-Gateway-APIKey', Endpoint.ApiKey__c);
			req.setHeader('Authorization', getAuthLeroyToken);
			req.setbody(jsonBody);
			Http http = new Http();
			HTTPResponse response = http.send(req);
		}
	}			
	**/

	@AuraEnabled
	public static List<Account> ListAccountsWithSameId(Id AccountId) {
		List<Account> accountToUpdate = [
			SELECT
				Id,
				IsDeleted,
				MasterRecordId,
				Name,
				LastName,
				FirstName,
				Salutation,
				MiddleName,
				Suffix,
				Type,
				RecordTypeId,
				ParentId,
				BillingStreet,
				BillingCity,
				BillingState,
				BillingPostalCode,
				BillingCountry,
				BillingStateCode,
				BillingCountryCode,
				BillingLatitude,
				BillingLongitude,
				BillingGeocodeAccuracy,
				BillingAddress,
				ShippingStreet,
				ShippingCity,
				ShippingState,
				ShippingPostalCode,
				ShippingCountry,
				ShippingStateCode,
				ShippingCountryCode,
				ShippingLatitude,
				ShippingLongitude,
				ShippingGeocodeAccuracy,
				ShippingAddress,
				Phone,
				AccountNumber,
				Website,
				PhotoUrl,
				Industry,
				NumberOfEmployees,
				Description,
				OwnerId,
				CreatedDate,
				CreatedById,
				LastModifiedDate,
				LastModifiedById,
				SystemModstamp,
				LastActivityDate,
				LastViewedDate,
				LastReferencedDate,
				PersonContactId,
				IsPersonAccount,
				PersonMailingStreet,
				PersonMailingCity,
				PersonMailingState,
				PersonMailingPostalCode,
				PersonMailingCountry,
				PersonMailingStateCode,
				PersonMailingCountryCode,
				PersonMailingLatitude,
				PersonMailingLongitude,
				PersonMailingGeocodeAccuracy,
				PersonMailingAddress,
				PersonMobilePhone,
				PersonHomePhone,
				PersonOtherPhone,
				PersonAssistantPhone,
				PersonEmail,
				PersonTitle,
				PersonDepartment,
				PersonBirthdate,
				PersonLastCURequestDate,
				PersonLastCUUpdateDate,
				PersonEmailBouncedReason,
				PersonEmailBouncedDate,
				PersonIndividualId,
				Jigsaw,
				JigsawCompanyId,
				AccountSource,
				SicDesc,
				OperatingHoursId,
				Cliente_com_Credito__c,
				NIF__c,
				Numero_de_Conta__c,
				Setor_de_Atividade__c,
				Tem_cartao_Leroy_Merlin__c,
				Volume_de_Faturacao__c,
				Sub_Empresa__c,
				E_mail_Empresa__c,
				OPTIN_EMAIL__c,
				OPTIN_SMS__c,
				OPTIN_CHAMADAS__c,
				Importado__c,
				EnderecoCompleto__c,
				Certification_No__c,
				Country_key__c,
				Is_LM_Installer__c,
				Preffered_Contact__c,
				Record_Type_API_Name__c,
				Decisor__pc,
				Funcao__pc,
				Pessoa_Autorizada__pc
			FROM Account
			WHERE Id = :AccountId
		];
		return accountToUpdate;
	}

	/*
	@AuraEnabled
	public static void InsertAccountMDM(Id AccountIdToUpdate) {
		List<Account> accountToUpdate = ListAccountsWithSameId(
			AccountIdToUpdate
		);
		String getAuthLeroyToken = C_pesquisaConta.getToken();
		List<Account> listAccountForUpdate = new List<Account>();
		MDM_EndPoint__mdt Endpoint = [
			SELECT EndPoint__c, ApiKey__c, isSandBox__c
			FROM MDM_EndPoint__mdt
			WHERE isSandBox__c = TRUE AND Label = 'Webservice MDM'
		];
		MDM_Client NewAccount = new MDM_Client();
		for (Account account : accountToUpdate) {
			if (
				account.RecordTypeId ==
				c_AccountUpdateMDM.GetProfissionalRecordTypeId()
			) {
				NewAccount.professionalOrganization = new MDM_Client.professionalOrganization();
				NewAccount.professionalOrganization.name = account.Name;
				NewAccount.professionalOrganization.registeredName = account.Name;
				//NewAccount.professionalOrganization.administrativeCodes = new MDM_Client.administrativeCode();
				//NewAccount.professionalOrganization.administrativeCodes.nif = account.NIF__c;
			} else {
				NewAccount.inhabitant = new MDM_Client.inhabitant();
				NewAccount.inhabitant.firstName = account.FirstName;
				NewAccount.inhabitant.lastName = account.LastName;
				//NewAccount.inhabitant.administrativeIdentifiers = new MDM_Client.administrativeIdentifier();
				//NewAccount.inhabitant.administrativeIdentifiers.nif = account.NIF__c;
			}
			NewAccount.emailAddresses = new List<MDM_Client.EmailAddress>();
			MDM_Client.EmailAddress emailaddress = new MDM_Client.EmailAddress();
			emailaddress.email = account.RecordTypeId ==
				c_AccountUpdateMDM.GetProfissionalRecordTypeId()
				? account.E_mail_Empresa__c
				: account.PersonEmail;

			NewAccount.addresses = new List<MDM_Client.Address>();
			MDM_Client.Address address = new MDM_Client.Address();
			address.postalCode = account.BillingPostalCode;
			address.city = account.BillingCity;
			address.countryCode = account.BillingCountryCode;
			address.province = account.BillingState;
			NewAccount.addresses.add(address);
			if(account.Phone !=null){
				NewAccount.phones = new List<MDM_Client.Phone>();
				MDM_Client.Phone phone = new MDM_Client.Phone();
				String phoness = account.Country_key__c + account.Phone;
				phone.numberSF = phoness;
				NewAccount.phones.add(phone);
			}
			

			NewAccount.emailAddresses.add(emailaddress);
			String jsonBody = JSON.serialize(NewAccount);
			jsonBody = jsonBody.replace('"numberSF":', '"number":');
			System.debug(jsonBody);
			HttpRequest req = new HttpRequest();
			req.setEndpoint(Endpoint.EndPoint__c + '/clients');
			req.setMethod('POST');
			req.setHeader('x-Gateway-APIKey', Endpoint.ApiKey__c);
			req.setHeader('Authorization', getAuthLeroyToken);
			req.setbody(jsonBody);
			Http http = new Http();
			HTTPResponse response = http.send(req);
			System.debug(response);
			if (response.getStatusCode() == 201) {
				MDM_Response res = (MDM_Response) JSON.deserialize(
					response.getBody(),
					MDM_Response.class
				);
				if (res.data != null) {
					account.Numero_de_Conta__c = String.valueOf(
						res.data.clientNumber
					);
					listAccountForUpdate.add(account);
				}
				System.debug(res);
			} else {
				System.debug('res status' + response);
			}
		}
		update listAccountForUpdate;
		
	} */

	public class MDM_Response {
		@AuraEnabled
		public String status;
		@AuraEnabled
		public MDM_Client data;
	}
}