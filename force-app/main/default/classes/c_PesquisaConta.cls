/**
 * @description       :
 * @author            : Daniel Flores
 * @group             :
 * @last modified on  : 29-01-2025
 * @last modified by  : Celso Sousa
 **/
public without sharing class c_PesquisaConta {

  /*
  @AuraEnabled
  public static String insertAccMDM(List<Id> accountsForUpdate){
    try {
      c_AccountInsertMDM.AccountUpdateMDM(accountsForUpdate);
      return 'done';
    } catch (Exception e) {
      return e.getMessage();
    }
  }*/

  @AuraEnabled
  public static List<Account> getAccountsSF(String[] Pesquisa,String TipoPesquisa){
    try {
      // string query = 'SELECT Id,E_mail_Empresa__c,LastModifiedDate, Name, FirstName, LastName, NIF__c, PersonEmail, Phone,PersonHomePhone,PersonMobilePhone,Numero_de_Conta__c FROM Account WHERE ';
      // System.debug(Pesquisa);
      // List<Account> returner = new List<Account>();
      // if (TipoPesquisa == 'ID') {
      //   query = query + 'ID = \'' + Pesquisa[0] + '\'';

      // } else if (TipoPesquisa == 'NIF'){
      //   query = query + 'NIF__c = \''+Pesquisa[0]+'\'';

      // } else if (TipoPesquisa == 'Nome da Empresa'){
      //   string name = '%' + Pesquisa[0] + '%';
      //   query = query + 'Name LIKE \'' + name + '\'';

      // }else if (TipoPesquisa == 'Primeiro Nome') {
      //   return AccountSearchService.getClientsSF(pesquisa, TipoPesquisa);
      // }else if (TipoPesquisa == 'Email') {
      //   query = query + 'PersonEmail = \'' + Pesquisa[0] + '\' OR E_mail_Empresa__c = \'' + Pesquisa[0] + '\'';
      
      // } else if (TipoPesquisa == 'Telemóvel') {
      //   query = query + 'Phone = \'' + Pesquisa[0] +'\'';
      
      // } else if (TipoPesquisa == 'Nº de Cliente') {
      //   query = query + 'Numero_de_Conta__c = \'' + Pesquisa[0] + '\'';
      // }

      // System.debug('query:' + query);
      // returner = (List<Account>)Database.query(query);
      List<Account> returner = AccountSearchService.getClientsSF(pesquisa, TipoPesquisa);
      // System.debug(returner);
      return returner;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }


  @AuraEnabled
  public static List<MDM_Client> getAccountsMdm(
    String[] Pesquisa,
    String TipoPesquisa
  ) {
    Integer pageSize = 100;
    String getAuthLeroyToken = getToken();

    Boolean isSandbox = [SELECT IsSandbox, Id FROM Organization].IsSandbox;
    MDM_EndPoint__mdt Endpoint = [
      SELECT EndPoint__c, ApiKey__c, isSandBox__c
      FROM MDM_EndPoint__mdt
      WHERE isSandBox__c = :isSandbox AND Label = 'Webservice MDM'
    ];

    HttpRequest req = new HttpRequest();
    req.setMethod('GET');
    req.setHeader('x-Gateway-APIKey', Endpoint.ApiKey__c);
    req.setHeader('Authorization', getAuthLeroyToken);

    //Monta os filtros dependendo do Tipo de pesquisa
    if (TipoPesquisa == 'NIF') {
      // FUNCIONAL
      req.setEndpoint(
        Endpoint.EndPoint__c +
          '/clients?filter=[{"administrativeCodes":{"$eq":"' +
          Pesquisa[0] + '"}},{"operator":"$or"},' + '{"administrativeIdentifiers":{"$eq":"'+Pesquisa[0] + '"}},{"operator":"$or"},{"nif":{"$eq":"'+Pesquisa[0] + '"}}]'
      );
    // } else if (TipoPesquisa == 'Nome da Empresa') {
    //   // FUNCIONAL
    //   Pesquisa[0] = Pesquisa[0].replace(' ', '%20');
    //   req.setEndpoint(
    //     Endpoint.EndPoint__c +
    //       '/clients?filter=[{"registeredName":{"$like":"' +
    //       Pesquisa[0] +
    //       '"}}]'
    //   );
    // } else if (TipoPesquisa == 'Primeiro Nome') {
    //   String endpointtxt;
    //   String AccName;
    //   String firstName = pesquisa[0] != null ? pesquisa[0] : '';
    //   String lastName = pesquisa[1] != null ? pesquisa[1] : '';
    //   firstName = firstName.replace(' ','%20');
    //   lastName = lastName.replace(' ','%20');

    //   if (String.isBlank(lastName)){
    //     AccName = firstName;
    //     endpointtxt =  Endpoint.EndPoint__c + 
    //                    '/clients?filter=[' +
    //                    '{"firstName":{"$like":"' + firstName + '*"}},' +
    //                    '{"operator":"$or"},'+
    //                    '{"registeredName":{"$like":"' + AccName + '"}}]'+
    //                    '&count=' + String.valueOf(pageSize);
    //   }else{
    //     AccName = firstName;
    //     endpointtxt =  Endpoint.EndPoint__c + 
    //                    '/clients?filter=[[' +
    //                    '{"firstName":{"$like":"' + firstName + '*"}},' +
    //                    '{"lastName":{"$like":"' + lastName + '*"}}],' + 
    //                    '{"operator":"$or"},'+
    //                    '{"registeredName":{"$like":"*' + AccName + '*"}}]'+
    //                    '&count=' + String.valueOf(pageSize);
    //     }
    //     req.setEndpoint(endpointtxt);
    }else if (TipoPesquisa == 'Email') {
      // FUNCIONAL
      req.setEndpoint(
        Endpoint.EndPoint__c +
          '/clients?filter=[{"emailAddresses":{"$like":"' +
          Pesquisa[0] +
          '*"}}]'
      );
    } else if (TipoPesquisa == 'Telemóvel') {
      // FUNCIONAL
      req.setEndpoint(
        Endpoint.EndPoint__c +
          '/clients?filter=[{"phones":{"$eq":"' +
          Pesquisa[0] +
          '"}}]'
      );
    } else if (TipoPesquisa == 'Nº de Cliente') {
      // FUNCIONAL
      req.setEndpoint(
        Endpoint.EndPoint__c +
          '/clients?filter=[{"clientNumber":{"$eq":"' +
          Pesquisa[0] +
          '"}}]'
      );
    }

    System.debug(req.getEndpoint());
	//String reqBody = EncodingUtil.urlEncode(req.getendpoint(), 'UTF-8');
    String reqBody = req.getEndpoint().replace(' ', '%20');
    req.setEndpoint(reqBody);
    System.debug(req.getEndpoint());
      
    Http http = new Http();
    HTTPResponse res = new HTTPResponse();
    if (!Test.isRunningTest()) {
      res = http.send(req);
    } else {
      res.setStatusCode(200);
      res.setBody(
        '{"status":"success","data":[{"active":true,"addresses":[{"city":"LISBON","countryCode":"PT","isContactPriority":true,"postalCode":"1234-123","usages":["INVOICE"]}],"clientNumber":10022137,"createdAt":"2022-03-21T12:32:28.670Z","creationStoreCode":"1","declaredStoreAttachement":"1","emailAddresses":[{"email":"testfida@gmail.com","isContactPriority":true,"type":"PERSONAL"}],"inhabitant":{"administrativeIdentifiers":{"nif":"123456789"},"civility":"MR","firstName":"TESTFIDA","gender":"MALE","lastName":"TESTFIDA"},"phones":[{"isContactPriority":true,"number":"123456789","type":"MOBILE"}],"universalClientNumber":"LMPT10022137","updatedAt":"2024-02-02T18:42:25.965Z","members":[]}],"_meta":{}}'
      );
    }

    if (res.getStatusCode() == 200) {
      System.debug(res.getBody());
      String jsonStr = JSON.serialize(res.getBody());
      jsonStr = jsonStr.replace('"number\\":', '"numberSF":');
      jsonStr = jsonStr.replace('\\', '');
      jsonStr = jsonStr.removeEnd('"');
      jsonStr = jsonStr.removeStart('"');
      if (jsonStr.contains('"clientNumber":""')) {
        jsonStr = jsonStr.replace('"clientNumber":""', '"clientNumber":"0"');
      }

      System.debug(jsonStr);
      // Deserialize the JSON string into collections of primitive data type
      MDM_Response response = (MDM_Response) JSON.deserialize(
        jsonStr,
        MDM_Response.class
      );

      if (response.data != null) {
        response.data = buildMDMClient(response.data);

        System.debug(response.data);
        return response.data;
      }
    }
    return null;
  }

  public static List<MDM_Client> buildMDMClient(List<MDM_Client> clientsMDM) {
    for (MDM_Client clientMDM : clientsMDM) {
      if (clientMDM.inhabitant == null) {
        clientMDM.inhabitant = new MDM_Client.inhabitant();
        clientMDM.inhabitant.lastName = '';
        if (clientMDM.professionalOrganization.name != null) {
          clientMDM.inhabitant.firstName = clientMDM.professionalOrganization.name;
        } else if (clientMDM.professionalOrganization.registeredName != null) {
          clientMDM.inhabitant.firstName = clientMDM.professionalOrganization.registeredName;
        }
      }

      for (MDM_Client.Phone phone : clientMDM.phones) {
        if (phone.isContactPriority == true) {
          String numeroTelefonico = phone.numberSF;
        }
      }
    }

    return clientsMDM;
  }

  @AuraEnabled
  public static Account getAccountSF(String clientNumber) {
    List<Account> account = [
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
      WHERE Numero_de_Conta__c = :clientNumber
      LIMIT 1
    ];

    if (!account.isEmpty()) {
      return account[0];
    }

    return null;
  }

  @auraEnabled
  public static List<String> upsertAccountSF(Object data, boolean isSync) {
    List<String> results = new List<String>();
    boolean isTypeEmpresa = false;

    try {
      MDM_Client clientMDM = (MDM_Client) JSON.deserialize(
        JSON.serialize(data),
        MDM_Client.class
      );

      System.debug(clientMDM);
      Account acc = new Account();
      if (isSync) {
        acc.isSynced__c = true;
        acc.isSyncedTime__c = System.now();
        acc.UpdateTime__c = String.valueof(System.now());
      } else {
        acc.isSynced__c = false;
      }

      if (
        clientMDM.inhabitant.lastName == null ||
        clientMDM.inhabitant.lastName == '' || clientMDM.inhabitant.lastName == '-'
      ) {
        //CONTA EMPRESARIAL
        isTypeEmpresa = true;

        if (
          clientMDM.professionalOrganization.administrativeCodes.nif != null
        ) {
          // System.debug('TAMANHO DO NIF: '+ clientMDM.professionalOrganization.administrativeCodes.nif.length());
          if (
            clientMDM.professionalOrganization.administrativeCodes.nif.length() ==
            9
          ) {
            System.debug(
              'NIF' + clientMDM.professionalOrganization.administrativeCodes.nif
            );
            acc.NIF__c = clientMDM.professionalOrganization.administrativeCodes.nif;
          }
        }

        if (clientMDM.professionalOrganization.registeredName != null) {
          acc.Name = clientMDM.professionalOrganization.registeredName;
        }

        acc.RecordTypeId = GetProfissionalRecordTypeId();
      } else {
        //Conta Pessoal

        acc.FirstName = clientMDM.inhabitant.firstName;
        acc.LastName = clientMDM.inhabitant.lastName;
        if (clientMDM.inhabitant.administrativeIdentifiers.nif != null) {
          if (
            clientMDM.inhabitant.administrativeIdentifiers.nif.length() == 9
          ) {
            System.debug(clientMDM.inhabitant.administrativeIdentifiers.nif);
            acc.NIF__c = clientMDM.inhabitant.administrativeIdentifiers.nif;
          } else {
            acc.Nif__c = '999999999';
          }
        }

        acc.RecordTypeId = GetPersonRecordTypeId();
      }

      acc.Numero_de_Conta__c = String.valueOf(clientMDM.clientNumber);

      if(isTypeEmpresa && !clientMDM.members.isEmpty()){
        for (MDM_Client.Member member : clientMDM.members) {
          if (member.isLegalRepresentative == true) {
            for (MDM_Client.EmailAddress emailAdress : member.emailAddresses) {
              if (emailAdress.isContactPriority == true) {
                if (c_PesquisaConta.isValidEmail(emailAdress.email)) {
                  acc.E_mail_Empresa__c = emailAdress.email;
                }
              }
            }

            for (MDM_Client.Phone phone : member.phones) {
              if (phone.isContactPriority == true) {
                String numeroTelefonico = phone.numberSF;
      
                // if (numeroTelefonico.length() == 9) {
                //   acc.Phone = numeroTelefonico;
                // }
                // if (numeroTelefonico.length() == 13 && numeroTelefonico.contains('+')) {
                //   numeroTelefonico = numeroTelefonico.Substring(4);
                  acc.Phone = numeroTelefonico;
                // }
              }
            }
          } 
        }
      }else{
        if (clientMDM.emailAddresses != null) {
          for (MDM_Client.EmailAddress emailAdress : clientMDM.emailAddresses) {
            if (emailAdress.isContactPriority == true) {
              if (c_PesquisaConta.isValidEmail(emailAdress.email)) { 
                acc.PersonEmail = emailAdress.email;
                acc.E_mail_Empresa__c = emailAdress.email;
              }
            }
          }
        }
  
        for (MDM_Client.Phone phone : clientMDM.phones) {
          if (phone.isContactPriority == true) {
            String numeroTelefonico = phone.numberSF;
            
            if (numeroTelefonico != null && numeroTelefonico.length() == 9) {
              acc.Phone = numeroTelefonico;
            }

            if (numeroTelefonico != null && numeroTelefonico.length() == 13 && numeroTelefonico.contains('+')) {
              //numeroTelefonico = numeroTelefonico.Substring(4);
              acc.Phone = numeroTelefonico;
            }
            else if (numeroTelefonico != null && numeroTelefonico.length() == 9) {
              acc.Phone = numeroTelefonico;
            }
          }
        }
      }
      
      if (clientMDM.addresses != null) {
        Boolean noUsageInvoiceFound = true;

        for (MDM_Client.Address addr : clientMDM.addresses) {

          //checks if there is any usage associated to date adress
          if (addr.usages != null && !addr.usages.isEmpty()) {
            for (String usage : addr.usages) {
              //checks the address usage an fills the shipping address
              if (usage == 'DELIVERY') {
                acc.ShippingPostalCode = addr.postalCode;
                acc.ShippingCity = addr.city;
                acc.ShippingCountryCode = addr.countryCode;
                acc.ShippingStreet = addr.streetNameNumber + (String.isNotBlank(addr.complementaryDeliveryAddress) ? (' ' + addr.complementaryDeliveryAddress) : '')+ (String.isNotBlank(addr.complementaryLocalizationAddress) ? (' ' + addr.complementaryLocalizationAddress) : '');
              }
              //checks the address usage an fills the billing address
              if (usage == 'INVOICE') {
                noUsageInvoiceFound = false;
                acc.BillingPostalCode = addr.postalCode;
                acc.BillingCity = addr.city;
                acc.BillingCountryCode = addr.countryCode;
                acc.BillingStreet = addr.streetNameNumber + (String.isNotBlank(addr.complementaryDeliveryAddress) ? (' ' + addr.complementaryDeliveryAddress) : '')+ (String.isNotBlank(addr.complementaryLocalizationAddress) ? (' ' + addr.complementaryLocalizationAddress) : '');
              }
            }
          }else {
            //if no usage of type invoice is found on this address assumes that is the default address
            if (noUsageInvoiceFound) {
              noUsageInvoiceFound = false;
              acc.BillingPostalCode = addr.postalCode;
              acc.BillingCity = addr.city;
              acc.BillingCountryCode = addr.countryCode;
              acc.BillingStreet = addr.streetNameNumber + (String.isNotBlank(addr.complementaryDeliveryAddress) ? (' ' + addr.complementaryDeliveryAddress) : '')+ (String.isNotBlank(addr.complementaryLocalizationAddress) ? (' ' + addr.complementaryLocalizationAddress) : '');
            }
          }
        }
      }

      System.debug(acc);
      acc.isSynced__c = true;
      acc.isSyncedTime__c = System.now();
      acc.UpdateTime__c = String.valueOf(System.now());
      upsert acc Numero_de_Conta__c;

      //! RETURN IMPACT
      results.add('true');
      results.add(acc.Id);

      return results;
    } catch (Exception e) {
      results.add('false');
      return results;
    }
  }

  /*
  @AuraEnabled
  public static MDM_Client updateAccountMDM(String clientNumber) {
    try {
      List<Account> listAccounts = new List<Account>();
      listAccounts.add(getAccountSF(clientNumber));

      if (listAccounts != null) {
        System.debug(listAccounts);
        MDM_Client SFAccountToMDM = new MDM_Client();
        System.debug(SFAccountToMDM);

        SFAccountToMDM.Id = listAccounts[0].Id;
        SFAccountToMDM.RecordTypeId = listAccounts[0].RecordTypeId;
        SFAccountToMDM.clientNumber = Integer.valueOf(
          listAccounts[0].Numero_de_Conta__c
        );

        SFAccountToMDM.emailAddresses = new List<MDM_Client.emailAddress>();
        MDM_Client.EmailAddress emailAddress = new MDM_Client.EmailAddress();

        if (listAccounts[0].RecordTypeId == GetProfissionalRecordTypeId()) {
          SFAccountToMDM.professionalOrganization = new MDM_Client.professionalOrganization();
          SFAccountToMDM.professionalOrganization.registeredName = listAccounts[0]
            .Name;

          if (listAccounts[0].NIF__c != null) {
            SFAccountToMDM.professionalOrganization.administrativeCodes = new MDM_Client.administrativeCode();
            SFAccountToMDM.professionalOrganization.administrativeCodes.nif = listAccounts[0]
              .NIF__c;
          }
          if (listAccounts[0].E_mail_Empresa__c != null) {
            emailAddress.email = listAccounts[0].E_mail_Empresa__c;
          }

        } else {
          SFAccountToMDM.inhabitant = new MDM_Client.inhabitant();
          SFAccountToMDM.inhabitant.firstName = listAccounts[0].FirstName;
          SFAccountToMDM.inhabitant.lastName = listAccounts[0].LastName;

          if (listAccounts[0].NIF__c != null) {
            SFAccountToMDM.inhabitant.administrativeIdentifiers = new MDM_Client.administrativeIdentifier();
            SFAccountToMDM.inhabitant.administrativeIdentifiers.nif = listAccounts[0]
              .NIF__c;
          }

          emailAddress.email = listAccounts[0].PersonEmail; 
        }
        
        SFAccountToMDM.emailAddresses.add(emailAddress);

        SFAccountToMDM.phones = new List<MDM_Client.Phone>();
        if (listAccounts[0].Phone != null) {
          MDM_Client.Phone phone = new MDM_Client.Phone();
          phone.isContactPriority = true;
          phone.numberSF = listAccounts[0].Phone;
          SFAccountToMDM.phones.add(phone);
        }

        SFAccountToMDM.addresses = new List<MDM_Client.Address>();
        MDM_Client.Address address = new MDM_Client.Address();
        address.postalCode = listAccounts[0].BillingPostalCode;
        address.city = listAccounts[0].BillingCity;
        address.countryCode = listAccounts[0].BillingCountryCode;
        SFAccountToMDM.addresses.add(address);

        String jsonBody = JSON.serialize(SFAccountToMDM);
        jsonBody = jsonBody.replace('"numberSF":', '"number":');

        System.debug(jsonBody);

        Boolean isSandbox = [SELECT IsSandbox, Id FROM Organization].IsSandbox;
        MDM_EndPoint__mdt Endpoint = [
          SELECT EndPoint__c, ApiKey__c, isSandBox__c
          FROM MDM_EndPoint__mdt
          WHERE isSandBox__c = :isSandbox AND Label = 'Webservice MDM'
        ];
        String getAuthLeroyToken = getToken();

        HttpRequest req = new HttpRequest();
        req.setEndpoint(
          Endpoint.EndPoint__c + '/clients/' + listAccounts[0].Numero_de_Conta__c
        );
        req.setMethod('PUT');
        req.setHeader('x-Gateway-APIKey', Endpoint.ApiKey__c);
        req.setHeader('Authorization', getAuthLeroyToken);
        req.setbody(jsonBody);
        Http http = new Http();
        HTTPResponse response = new HTTPResponse();

        if (!Test.isRunningTest()) {
          response = http.send(req);
        } else {
          response.setStatusCode(200);
          response.setBody(
            '{"status":"success","data":{"active":true,"addresses":[{"city":"LISBON","countryCode":"PT","isContactPriority":true,"postalCode":"1234-123","usages":[]}],"clientNumber":10022137,"createdAt":"2022-03-21T12:32:28.670Z","creationStoreCode":"1","declaredStoreAttachement":"1","emailAddresses":[{"email":"testfida@gmail.com","isContactPriority":true,"type":"PERSONAL"}],"inhabitant":{"administrativeIdentifiers":{"nif":"123456789"},"civility":"MR","firstName":"TESTFIDA","gender":"MALE","lastName":"TESTFIDA"},"phones":[{"isContactPriority":true,"number":"123456789","type":"MOBILE"}],"universalClientNumber":"LMPT10022137","updatedAt":"2024-02-02T18:42:25.965Z","members":[]},"_meta":{}}'
          );
        }

        System.debug(response.getBody());

        if (
          response.getStatusCode() == 200 ||
          response.getStatusCode() == 201
        ) {
          String jsonStr = JSON.serialize(response.getBody());
          jsonStr = jsonStr.replace('"number\\":', '"numberSF":');
          jsonStr = jsonStr.replace('\\', '');
          jsonStr = jsonStr.removeEnd('"');
          jsonStr = jsonStr.removeStart('"');

          MDM_Response_PUT responseMDM = (MDM_Response_PUT) JSON.deserialize(
            jsonStr,
            MDM_Response_PUT.class
          );

          if (responseMDM.data != null) {
            responseMDM.data = buildMDMClient(
              new List<MDM_Client>{ responseMDM.data }
            )[0];

            System.debug(responseMDM.data);
            return responseMDM.data;
          }

          return null;
        } else {
          System.debug('Erro');
          return null;
        }
      } else {
        return null;
      }
    } catch (Exception e) {
      System.debug(e.getMessage());
      return null;
    }
  }*/

  public static Boolean isValidEmail(String email) {
    // Define a regular expression pattern for a basic email validation
    String emailRegex = '^[a-zA-Z0-9_+&*-]+(?:\\.[a-zA-Z0-9_+&*-]+)*@(?:[a-zA-Z0-9-]+\\.)+[a-zA-Z]{2,7}$';

    // Compile the regular expression
    Pattern pattern = Pattern.compile(emailRegex);

    // Match the email against the pattern
    Matcher matcher = pattern.matcher(email);

    // Return true if the email matches the pattern, otherwise false
    return matcher.matches();
  }

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
    System.debug(LeroyToken);
    HttpRequest req = new HttpRequest();
    req.setMethod('POST');
    req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
    String auth = EncodingUtil.base64Encode(
      Blob.valueOf(LeroyToken.ClientId__c + ':' + LeroyToken.ClientSecret__c)
    );
    System.debug(auth);
    req.setEndpoint(LeroyToken.EndPoint__c + '?grant_type=client_credentials');
    req.setHeader('Authorization', 'Basic ' + auth);
    Http http = new Http();
    HTTPResponse response = new HTTPResponse();
    if (!Test.isRunningTest()) {
      response = http.send(req);
    } else {
      response.setStatusCode(200);
      response.setBody(
        '{"access_token":"eyJhbGciOiJSUzUxMiIsImtpZCI6Ikp3a3MiLCJwaS5hdG0iOiIxIn0.eyJzY29wZSI6W10sImNsaWVudF9pZCI6IjBBMzM1MWY5ZTdkM2E2NzY2YzIwZTRkZGQ4ZGEzODI3MzYiLCJpc3MiOiJodHRwczovL2lkcGIyZS1wcnAuYWRlby5jb20iLCJpYXQiOjE3MDMxNzIxNDEsImV4cCI6MTcwMzE4NjU0MX0.Rg9KWPlRwp3IfZG_pPe2rYl9dJ2Bct6Uh5iywk8H3pH1QQ67YjYBk8RRPKNL98yE7x6VeEuDZ__FCFZYzvD8T6nqDzbdtsFGSILy0icJ-lpFleisiFoPQmtXrNsdvKIMDRXTfknR9TU_CNarvOmBl-j93rQfq4ICpX7CVcTPsWufY0z1f-ws-Hija3n5u4K1zWmMtDjVWvhxo0RhsTZlcB0u3MjGBTnORB9TOTwpFcFJf2qLuRZhMkEpw9s3YbzedI_4M396pgUEFzh6f9xyfz2xUB2cSsjmqdiRkQQbMPO8Ygu5FDo1Ddyuxd2I6qMK6hfjvABluW7STuQLza0vBw","token_type":"Bearer","expires_in":14399}'
      );
    }
    if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
      Point ResToken = (Point) JSON.deserialize(
        response.getBody(),
        Point.class
      );
      System.debug(ResToken.access_token);
      String Token = ResToken.access_token;
      return Token;
    }
    return null;
  }

  @AuraEnabled(cacheable=true)
  public static String GetPersonRecordTypeId() {
    return [SELECT Id FROM RecordType WHERE DeveloperName = 'PersonAccount'].Id;
  }

  @AuraEnabled(cacheable=true)
  public static String GetProfissionalRecordTypeId() {
    return [SELECT Id FROM RecordType WHERE DeveloperName = 'Conta_Empresa'].Id;
  }

  public class MDM_Response {
    @AuraEnabled
    public String status;
    @AuraEnabled
    public List<MDM_Client> data;

    /* @AuraEnabled
     public Meta _meta; */
  }

  public class MDM_Response_PUT {
    @AuraEnabled
    public String status;
    @AuraEnabled
    public MDM_Client data;

    /* @AuraEnabled
     public Meta _meta; */
  }

  public class Point {
    @AuraEnabled
    public String access_token;
  }
}