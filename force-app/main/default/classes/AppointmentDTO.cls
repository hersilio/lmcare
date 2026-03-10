/* Example JSON

{
  "serviceAppointment" : {
    "serviceTerritoryId" : "0HhAe0000001ENVKA2",
    "schedStartTime" : "2024-11-11T10:15:00.000Z",
    "schedEndTime" : "2024-11-11T13:15:00.000Z",
    "workTypeId" : "08qAe0000003PzZIAU",
    "additionalInformation" : null,
    "engagementChannelTypeId" : "0eFAe000000034LMAQ",
    "extendedFields" : [ {
      "name" : "IsAnonymousBooking",
      "value" : "false"
    } ],
    "description" : "Dentro de quanto tempo pretende iniciar a instalação da sua nova cozinha?: O mais brevemente possível/nQual o orçamento disponível para a sua nova cozinha (incluindo mobiliário e equipamentos)?: 2.000 € - 3.000 €/nQual é o estilo que pretende para a sua cozinha?: Moderno/nQuem irá instalar a sua cozinha?: Ainda não sei/n"
  },
  "lead" : {
    "firstName" : "firstName",
    "lastName" : "lastName",
    "phone" : "999999999",
    "email" : "70150193@email.com",
    "company" : null,
    "extendedFields" : [ {
      "name" : "Loja_de_Angariacao__c",
      "value" : "Alfragide"
    }, {
      "name" : "Canal_de_Interacao__c",
      "value" : "Scheduler Online"
    }, {
      "name" : "Numero_de_Conta_na_lead__c",
      "value" : "70150193"
    } ]
  },
  "assignedResources" : [ {
    "serviceResourceId" : "0HnAe0000004OzpKAE",
    "isRequiredResource" : true,
    "isPrimaryResource" : true
  } ]
}

*/


public with sharing class AppointmentDTO {
    public ServiceAppointmentDTO serviceAppointment { get; set; }
    public LeadDTO lead { get; set; }
    public list<AssignedResourceDTO> assignedResources {get;set;}

    public class ServiceAppointmentDTO {
        public String workTypeId { get; set; }
        public String serviceTerritoryId { get; set; }
        public String engagementChannelTypeId { get; set; }
        public Datetime schedStartTime { get; set; }
        public Datetime schedEndTime { get; set; }
        public String parentRecordId { get; set; }
        public String street { get; set; }
        public String city { get; set; }
        public String state { get; set; }
        public String postalCode { get; set; }
        public String country { get; set; }
        public String appointmentType { get; set; }
        public String appointmentMode { get; set; }
        public String attendeeLimit { get; set; }
        public String description {get; set; }
    }

    public class LeadDTO {
        public String firstName { get; set; }
        public String lastName { get; set; }
        public String phone { get; set; }
        public String email { get; set; }
        public String company { get; set; }
        public List<ExtendedFieldDTO> extendedFields { get; set; }
    }

    public class ExtendedFieldDTO {
        public String name { get; set; }
        public String value { get; set; }
    }

    public class AssignedResourceDTO{
      public String serviceResourceId {get;set;}
      public Boolean isRequiredResource {get;set;}
      public Boolean isPrimaryResource {get;set;}
    }
  }