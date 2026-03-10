/**
 * @description       : This class is a Wrapper for results retrieved by AccountSearchService.
 * @author            : Felipe Gil
 * @group             : TRH
 * @last modified on  : 20-02-2025
 * @last modified by  : Felipe Gil
 **/

public class AccountSearchResult {
    @AuraEnabled
    @InvocableVariable
    public String name;
    @AuraEnabled
    @InvocableVariable
    public String nif;
    @AuraEnabled
    @InvocableVariable
    public String phone;
    @AuraEnabled
    @InvocableVariable
    public String email;
    @AuraEnabled
    @InvocableVariable
    public String clientNumber;
    @AuraEnabled
    @InvocableVariable
    public Boolean isInSF;
    @AuraEnabled
    @InvocableVariable
    public Boolean isInMDM;
    @AuraEnabled
    @InvocableVariable
    public String sfId;

    public AccountSearchResult(){
        name = '';
        nif = '';
        phone = '';
        email = '';
        clientNumber = '';
        isInSF = false;
        isInMDM = false;
        sfId = '';
    }
    public AccountSearchResult(String name, String nif, String phone, String email, String clientNumber, Boolean isInSF, Boolean isInMDM, String sfId) {
        this.name = name;
        this.nif = nif;
        this.phone = phone;
        this.email = email;
        this.clientNumber = clientNumber;
        this.isInSF = isInSF;
        this.isInMDM = isInMDM;
        this.sfId = sfId;
    }
}