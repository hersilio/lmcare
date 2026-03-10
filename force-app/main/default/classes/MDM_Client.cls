/**
 * @description       :
 * @author            : Daniel Flores
 * @group             :
 * @last modified on  : 30-08-2024
 * @last modified by  : João Rosa
 **/
public class MDM_Client {
	@AuraEnabled
	public Boolean active { get; set; }
	@AuraEnabled
	public List<Address> addresses { get; set; }
	@AuraEnabled
	public Datetime createdAt { get; set; }
	@AuraEnabled
	public String creationStoreCode { get; set; }
	@AuraEnabled
	public String declaredStoreAttachement { get; set; }
	@AuraEnabled
	public Integer clientNumber { get; set; }
	@AuraEnabled
	public inhabitant inhabitant { get; set; }
	@AuraEnabled
	public String universalClientNumber { get; set; }
	@AuraEnabled
	public Datetime updatedAt { get; set; }
	@AuraEnabled
	public List<Phone> phones { get; set; }
	@AuraEnabled
	public List<Member> members { get; set; }
	@AuraEnabled
	public String Id { get; set; }
	@AuraEnabled
	public String RecordTypeId { get; set; }
	@AuraEnabled
	public professionalOrganization professionalOrganization { get; set; }
	@AuraEnabled
	public String clientType { get; set; }
	@AuraEnabled
	public List<EmailAddress> emailAddresses { get; set; }

	public class Address {
		@AuraEnabled
		public List<String> usages { get; set; }
		@AuraEnabled
		public String city { get; set; }
		@AuraEnabled
		public String streetNameNumber { get; set; }
		@AuraEnabled
		public String complementaryDeliveryAddress { get; set; }
		@AuraEnabled
		public String complementaryLocalizationAddress { get; set; }
		@AuraEnabled
		public String countryCode { get; set; }
		@AuraEnabled
		public Boolean isContactPriority { get; set; }
		@AuraEnabled
		public String postalCode { get; set; }
		@AuraEnabled
		public String province { get; set; }
	}

	public class inhabitant {
		@AuraEnabled
		public String civility { get; set; }
		@AuraEnabled
		public String civilStatus { get; set; }
		@AuraEnabled
		public String firstName { get; set; }
		@AuraEnabled
		public String gender { get; set; }
		@AuraEnabled
		public String professionalClassification { get; set; }
		@AuraEnabled
		public String lastName { get; set; }
		@AuraEnabled
		public administrativeIdentifier administrativeIdentifiers { get; set; }
	}

	public class professionalOrganization {
		@AuraEnabled
		public String registeredName { get; set; }
		@AuraEnabled
		public String name { get; set; }
		@AuraEnabled
		public String legalForm { get; set; }
		@AuraEnabled
		public Date EstablishedAt { get; set; }
		@AuraEnabled
		public String businessPurposes { get; set; }
		@AuraEnabled
		public String logo { get; set; }
		@AuraEnabled
		public Integer shareCapital { get; set; }
		@AuraEnabled
		public Integer turnover { get; set; }
		@AuraEnabled
		public String activitySector { get; set; }
		@AuraEnabled
		public administrativeCode administrativeCodes { get; set; }
	}

	public class administrativeIdentifier {
		@AuraEnabled
		public String nif { get; set; }
	}
	public class administrativeCode {
		@AuraEnabled
		public String nif { get; set; }
	}

	public class Phone {

		//! quando coverter para json dar replace do numberSf para number
		@AuraEnabled
		public Boolean isContactPriority { get; set; }
		@AuraEnabled
		public String type { get; set; }
		@AuraEnabled
		public String numberSF { get; set; }
	}

	public class Member {
		@AuraEnabled
		public Integer clientNumber { get; set; }
		@AuraEnabled
		public String firstName { get; set; }
		@AuraEnabled
		public String lastName { get; set; }
		@AuraEnabled
		public String civility { get; set; }
		@AuraEnabled
		public Boolean isLegalRepresentative { get; set; }
		@AuraEnabled
		public List<EmailAddress> emailAddresses { get; set; }
		@AuraEnabled
		public List<Phone> phones { get; set; }
		@AuraEnabled
		public Boolean active { get; set; }
	}

	public class EmailAddress {
		@AuraEnabled
		public String email { get; set; }
		@AuraEnabled
		public Boolean isContactPriority { get; set; }
		@AuraEnabled
		public String type { get; set; }
	}

	public class Activity {
		@AuraEnabled
		public Integer code { get; set; }
		@AuraEnabled
		public String description { get; set; }
		@AuraEnabled
		public Boolean isMainActivity { get; set; }
		@AuraEnabled
		public String label { get; set; }
		@AuraEnabled
		public Date activityStartDate { get; set; }
	}
}