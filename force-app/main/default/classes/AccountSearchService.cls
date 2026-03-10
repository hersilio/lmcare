/**
 * @description       : This class is used to search for accounts based on search string and type inside a Flow.
 * @methods           : searchAccounts
 * @author            : Felipe Gil
 * @group             : TRH
 * @last modified on  : 20-02-2025
 * @last modified by  : Felipe Gil
 * 
 * Changes Log:
 * Ver       Date            Author              Modification
 * 1.0       20-02-2025      Felipe Gil          Initial Version
 * 1.1       21-02-2025      Felipe Gil          Added method getClientsSF to avoid hardcoded query in c_PesquisaConta class
 **/

public with sharing class AccountSearchService {
    @InvocableMethod(label='Search Accounts' description='Search for accounts based on search string and type')
    public static List<List<AccountSearchResult>> searchAccounts(List<SearchRequest> requests) {
        List<List<AccountSearchResult>> results = new List<List<AccountSearchResult>>();
        for (SearchRequest request : requests) {
            List<String> searchStrings = request.searchStrings;
            String searchType = request.searchType;
            List<AccountSearchResult> accountList = new List<AccountSearchResult>();

            // Search in Salesforce
            List<Account> clients = getClientsSF(searchStrings, searchType);
            List<String> mdmIds = new List<String>();
            if (clients != null && !clients.isEmpty()) {
                for (Account acc : clients) {
                    if (mdmIds.contains(acc.Numero_de_Conta__c))
                        continue;
                    accountList.add(new AccountSearchResult(acc.Name, acc.NIF__c, acc.Phone, acc.E_mail_Empresa__c, acc.Numero_de_Conta__c, true, false, acc.Id));
                    mdmIds.add(acc.Numero_de_Conta__c);
                }
            }

            // Search in MDM
            // Note: The input parameters of the getAccountsMdm method should not be changed. 
            // c_pesquisaConta.getAccountsMdm expects the search string to be split into two parts

            List<MDM_Client> mdmClients = c_PesquisaConta.getAccountsMdm(searchStrings, searchType);
            if (mdmClients != null && !mdmClients.isEmpty()) {
                for (MDM_Client client : mdmClients) {
                    
                    String name = isPersonAccount(client) ? 
                                  client.inhabitant.firstName + ' ' +
                                  client.inhabitant.lastName :
                                  client.professionalOrganization.registeredName;
                    String nif = client.inhabitant.administrativeIdentifiers == null ?
                                 client.professionalOrganization.administrativeCodes.nif : 
                                 client.inhabitant.administrativeIdentifiers.nif;
                    String phone = !client.phones.isEmpty() ? 
                                   client.phones[0].numberSF : 
                                   null;
                    String email = !client.emailAddresses.isEmpty() ? 
                                   client.emailAddresses[0].email :
                                   null;
                    String mdmId = String.valueOf(client.clientNumber);

                    if (mdmIds.contains(mdmId)){
                        updateAccFoundInBoth(mdmId, accountList);
                        continue;
                    }
                    
                    System.debug('Client Name: ' + name + ' - NIF: ' + nif + ' - Phone: ' + phone + ' - Email: ' + email);

                    accountList.add(new AccountSearchResult(name, nif, phone, email, mdmId, false, true, null));
                    mdmIds.add(mdmId);
                }
            }
            results.add(accountList.isEmpty() ? null : accountList);
        }
        return results;
    }

    public static Boolean isPersonAccount(MDM_Client client) {
        return client.inhabitant.lastName != null && client.inhabitant.lastName != '' && client.inhabitant.lastName != '-';
    }

    public static void updateAccFoundInBoth(String mdmId, List<AccountSearchResult> accountList){
        for(AccountSearchResult acc : accountList){
            if(acc.clientNumber == mdmId){
                acc.isInSF = true;
                acc.isInMDM = true;
                return;
            }
        }
    }

    // This method was created because in method getAcccountsSF in c_PesquisaConta class, the query is hardcoded and 
    // we cannot filter by Record Type. Otherwise, we would be using c_PesquisaConta.getAccountsSF().
    public static List<Account> getClientsSF(List<String> searchStrings, String searchType) {
        List<Account> accounts = new List<Account>();
        // Retrieve RecordTypeIds for 'Conta_Empresa' and 'PersonAccount'
        Map<String, Schema.RecordTypeInfo> recordTypeInfoMap = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName();
        Id contaEmpresaRecordTypeId = recordTypeInfoMap.get('Conta_Empresa').getRecordTypeId();
        Id personAccountRecordTypeId = recordTypeInfoMap.get('PersonAccount').getRecordTypeId();
        
        String searchString = searchStrings[0]; // Right now only 1 search field is required as search by name is deactivated.
        searchString = searchString.trim();
        
        // String joinedSearchString = String.join(searchStrings, ' ');
        // joinedSearchString = joinedSearchStrings.trim();

        // if (searchType == 'Primeiro Nome') {
            
        //     List<List<SObject>> searchResults = [FIND :('*' + joinedSearchString + '*') IN NAME FIELDS 
        //         RETURNING Account(Id, Name, FirstName, LastName, NIF__c, Phone, E_mail_Empresa__c, Numero_de_Conta__c, RecordTypeId 
        //             WHERE RecordTypeId IN (:contaEmpresaRecordTypeId, :personAccountRecordTypeId) AND Numero_de_Conta__c != null)
        //     ];
        //     accounts = searchResults.isEmpty() ? new List<Account>() : (List<Account>)searchResults[0];
        // } else 
        if (searchType == 'NIF') {
            accounts = [SELECT Id, Name, NIF__c, Phone, E_mail_Empresa__c, Numero_de_Conta__c, RecordTypeId 
                        FROM Account 
                        WHERE RecordTypeId IN (:contaEmpresaRecordTypeId, :personAccountRecordTypeId) AND Numero_de_Conta__c != null 
                        AND NIF__c = :searchString];
        } else if (searchType == 'Telemóvel') {
            searchString = '%' + searchString + '%';
            accounts = [SELECT Id, Name, NIF__c, Phone, E_mail_Empresa__c, Numero_de_Conta__c, RecordTypeId 
                        FROM Account 
                        WHERE RecordTypeId IN (:contaEmpresaRecordTypeId, :personAccountRecordTypeId) AND Numero_de_Conta__c != null 
                        AND Phone LIKE :searchString];
        } else if (searchType == 'Email') {
            searchString = '%' + searchString + '%';
            accounts = [SELECT Id, Name, NIF__c, Phone, E_mail_Empresa__c, Numero_de_Conta__c, RecordTypeId 
                        FROM Account 
                        WHERE RecordTypeId IN (:contaEmpresaRecordTypeId, :personAccountRecordTypeId) AND Numero_de_Conta__c != null 
                        AND E_mail_Empresa__c LIKE :searchString];
        } else if (searchType == 'Nº de Cliente') {
            accounts = [SELECT Id, Name, NIF__c, Phone, E_mail_Empresa__c, Numero_de_Conta__c, RecordTypeId 
                        FROM Account 
                        WHERE RecordTypeId IN (:contaEmpresaRecordTypeId, :personAccountRecordTypeId) AND Numero_de_Conta__c != null 
                        AND Numero_de_Conta__c = :searchString];
        }
        System.debug('Accounts found in SF: ' + accounts);
        return accounts;
    }
        
    public class SearchRequest {
        @InvocableVariable
        public List<String> searchStrings;
        @InvocableVariable
        public String searchType;
    }
}