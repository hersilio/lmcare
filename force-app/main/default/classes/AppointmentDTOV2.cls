/* Example JSON

CREATE:
{
    "operation": "CREATE",
    "appointment": {
        "workTypeId": "08qAe0000003PzZIAU",
        "serviceTerritoryId": "0HhAe0000001ENVKA2",
        "schedStartTime": "2025-10-28T09:00:00Z",
        "schedEndTime": "2025-10-28T10:00:00Z",
        "engagementChannelTypeId": "0eFAe000000034LMAQ",
        "description": "Agendamento via Portal"
    },
    "customer": {
        "mdmId": "70150193", // Para usar cliente existente:
        "type": "B2C",
        "lead": {// Para criar novo lead (opcional)
            "firstName": "Maria",
            "lastName": "Silva",
            "phones": [{"number": "+351999999999","primary": true}],
            "emails": [{"address": "maria@email.com","primary": true}]
        }
    },
    "resources": [
        {
            "serviceResourceId": "0HnAe0000004OzpKAE",
            "role": "Primary",
            "primary": true
        }
    ],
    "meta": {
        "locale": "pt-PT"
    }
}

UPDATE:
{
  "operation": "UPDATE",
  "appointment": {
    "id": "08pXXXXXXXXXXXXXXX",
    "schedStartTime": "2025-10-29T10:00:00Z",
    "schedEndTime": "2025-10-29T11:00:00Z",
    "description": "Reagendamento solicitado pelo cliente"
  },
  "resources": [
    { "serviceResourceId": "0HnAe0000005XYzKAE", "role": "Primary", "primary": true }
  ],
  "meta": { "locale": "pt-PT" }
}


CANCEL:
{
  "operation": "CANCEL",
  "appointment": { "id": "08pXXXXXXXXXXXXXXX" },
  "cancellation": {
    "reason": "Cliente solicitou cancelamento",
    "notes": "Contato via portal",
    "notifyCustomer": true
  },
  "meta": { "locale": "pt-PT" }
}
*/

public with sharing class AppointmentDTOV2 {
    // Root payload
    public String operation { get; set; }
    public AppointmentDTO appointment { get; set; }
    public CancellationDTO cancellation { get; set; }
    public CustomerDTO customer { get; set; }
    public List<ResourceDTO> resources { get; set; }
    public MetaDTO meta { get; set; }

    // appointment section
    public class AppointmentDTO {
        public String id { get; set; }
        public String workTypeId { get; set; }
        public String serviceTerritoryId { get; set; }
        public Datetime schedStartTime { get; set; }
        public Datetime schedEndTime { get; set; }
        public String engagementChannelTypeId { get; set; }
        public String description { get; set; }
    }

    public class CancellationDTO {
        public String reason { get; set; }
        public String notes { get; set; }
        public Boolean notifyCustomer { get; set; }
    }

    // customer section
    public class CustomerDTO {
        public String mdmId { get; set; }
        public String type { get; set; } // e.g. B2C / B2B
        public LeadDTO lead { get; set; } // optional, when creating a new lead
    }

    // lead minimal structure per example
    public class LeadDTO {
        public String firstName { get; set; }
        public String lastName { get; set; }
        public List<PhoneDTO> phones { get; set; }
        public List<EmailDTO> emails { get; set; }
    }

    public class PhoneDTO {
        public String phoneNumber { get; set; }
        public Boolean primary { get; set; }
    }

    public class EmailDTO {
        public String address { get; set; }
        public Boolean primary { get; set; }
    }

    // resources section
    public class ResourceDTO {
        public String serviceResourceId { get; set; }
        public String role { get; set; } // e.g. Primary
        public Boolean primary { get; set; }
        // compatibility with existing v1 shape
        public Boolean isRequiredResource { get; set; }
        public Boolean isPrimaryResource { get; set; }
    }

    // meta section
    public class MetaDTO {
        public String locale { get; set; }
    }
}