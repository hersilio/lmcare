/**
 * @description       : 
 * @author            : Francisco Ribeiro
 * @group             : 
 * @last modified on  : 02-10-2024
 * @last modified by  : Francisco Ribeiro
**/
@isTest
public class MDM_ClientTest {
    @isTest
    public static void MDM_ClientTest() {
        MDM_Client client = new MDM_Client();
        client.active = true;

        client.addresses = new List<MDM_Client.Address>();
        MDM_Client.Address clientAddresses = new MDM_Client.Address();
        clientAddresses.city = 'teste';
        clientAddresses.complementaryDeliveryAddress = 'teste'; 
        clientAddresses.complementaryLocalizationAddress = 'teste'; 
        clientAddresses.countryCode = 'teste'; 
        clientAddresses.isContactPriority = false; 
        clientAddresses.postalCode = 'teste'; 
        clientAddresses.province = 'teste'; 
        client.addresses.add(clientAddresses);

        client.createdAt = System.now();
        client.creationStoreCode = '1';
        client.declaredStoreAttachement = 'teste';
	    client.clientNumber = 12345;

        client.inhabitant = new MDM_Client.inhabitant();
        client.inhabitant.civility = 'teste'; 
        client.inhabitant.civilStatus = 'teste'; 
        client.inhabitant.firstName = 'teste'; 
        client.inhabitant.gender = 'teste'; 
        client.inhabitant.professionalClassification = 'teste'; 
        client.inhabitant.lastName = 'teste'; 

        client.inhabitant.administrativeIdentifiers = new MDM_Client.administrativeIdentifier();
        client.inhabitant.administrativeIdentifiers.nif = 'teste';

	    client.universalClientNumber = '12345';
	    client.updatedAt = System.now();

        client.phones = new List<MDM_Client.Phone>();
        MDM_Client.Phone clientPhone = new MDM_Client.Phone();
        clientPhone.isContactPriority = true;
        clientPhone.type = 'teste';
        clientPhone.numberSF = 'teste';
        client.phones.add(clientPhone);

        client.members = new List<MDM_Client.Member>();
        MDM_Client.Member clientMember = new MDM_Client.Member();
        clientMember.clientNumber = 12345;
        clientMember.firstName = 'teste'; 
        clientMember.lastName = 'teste'; 
        clientMember.civility = 'teste'; 
        clientMember.isLegalRepresentative = true;

        clientMember.emailAddresses = new List<MDM_Client.EmailAddress>();
        MDM_Client.EmailAddress clientMemberEmailAddress = new MDM_Client.EmailAddress();
        clientMemberEmailAddress.email = 'teste'; 
        clientMemberEmailAddress.isContactPriority = true;
        clientMemberEmailAddress.type = 'teste';
        clientMember.emailAddresses.add(clientMemberEmailAddress);

        client.members.add(clientMember);

	    client.Id = 'teste';
	    client.RecordTypeId = 'teste';

        client.professionalOrganization = new MDM_Client.professionalOrganization();
        client.professionalOrganization.registeredName = 'teste'; 
        client.professionalOrganization.name = 'teste'; 
        client.professionalOrganization.legalForm = 'teste'; 
        client.professionalOrganization.EstablishedAt = Date.newInstance(2016, 12, 9); 
        client.professionalOrganization.businessPurposes = 'teste'; 
        client.professionalOrganization.logo = 'teste'; 
        client.professionalOrganization.shareCapital = 12345;
        client.professionalOrganization.turnover = 12345;
        client.professionalOrganization.activitySector = 'teste'; 
        client.professionalOrganization.administrativeCodes = new MDM_Client.administrativeCode();
        client.professionalOrganization.administrativeCodes.nif = 'teste'; 

        client.clientType = 'teste';

        client.emailAddresses = new List<MDM_Client.EmailAddress>();
        MDM_Client.EmailAddress clientEmailAddresses = new MDM_Client.EmailAddress();
        clientEmailAddresses.email = 'teste'; 
        clientEmailAddresses.isContactPriority = true;
        clientEmailAddresses.type = 'teste';
        client.emailAddresses.add(clientEmailAddresses);
    }
}