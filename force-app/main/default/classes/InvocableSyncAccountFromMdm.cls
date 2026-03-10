/**
 * @description       : This class is used to sync accounts from MDM based on the provided AccountSearchResult inside a Flow.
 * @methods           : syncAccountFromMdm
 * @author            : Felipe Gil
 * @group             : TRH
 * @last modified on  : 20-02-2025
 * @last modified by  : Felipe Gil
 **/

public with sharing class InvocableSyncAccountFromMdm {
    @InvocableMethod(label='Sync Account from MDM' description='Sync the selected AccountSearchResult from MDM')
    public static List<Boolean> syncAccountFromMdm(List<AccountSearchResult> accountSearchResults) {
        List<Boolean> results = new List<Boolean>();

        for (AccountSearchResult accountSearchResult : accountSearchResults) {
            // Fetch the MDM client using the client number
            List<MDM_Client> mdmClients = new List<MDM_Client>();
            mdmClients = c_PesquisaConta.getAccountsMdm(new String[]{accountSearchResult.clientNumber}, 'Nº de Cliente');
            if (mdmClients == null || mdmClients.isEmpty()) {
                results.add(false);
                continue;
            }
            MDM_Client client = mdmClients[0]; // There should be only one client for a given client number

            c_PesquisaConta.upsertAccountSF(client, true);
            results.add(true);
        }
        return results;
    }
}