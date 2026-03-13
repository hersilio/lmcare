/* Example JSON

{
    "serviceAppointment": {
        "serviceTerritoryId": "0HhAe0000001ENVKA2",
        "schedStartTime": "2026-02-28T20:45:00Z",
        "schedEndTime": "2026-02-28T21:45:00Z",
        "workTypeId": "08qAe0000008YfdIAE",
        "engagementChannelTypeId": "0eFAe000000034LMAQ",
        "extendedFields": [
            {
                "name": "IsAnonymousBooking",
                "value": "true"
            }
        ],
        "description": "- O que gostaria de instalar ou substituir na sua casa de banho?: Banheira, Sanita, Bidé\n- Qual o estilo que prefere para a sua casa de banho?: Natura\n- Gostaria de nos confiar a instalação da sua casa de banho?: Já tenho um instalador\n- Qual o orçamento que pretende investir no seu projeto?: Entre 3000-4000€\n- Idealmente, quando espera que o seu projeto esteja concluído?: Em menos de 2 meses\n"
    },
    "lead": {
        "firstName": "LINETTE",
        "lastName": "WEBER",
        "email": "cfuatlmpt1772096557653906@yopmail.com",
        "extendedFields": [
            {
                "name": "Loja_de_Angariacao__c",
                "value": "0HhAe0000001ENVKA2"
            },
            {
                "name": "Canal_de_Interacao__c",
                "value": "Scheduler Online"
            },
            {
                "name": "Numero_de_Conta_na_lead__c",
                "value": "70203863"
            },
            {
                "name": "LeadSource",
                "value": "L2S"
            },
            {
                "name": "ProjectId__c",
                "value": "e8a8b710-3cad-40c2-87bd-b735f345a146"
            }
        ]
    },
    "assignedResources": [
        {
            "serviceResourceId": "0HnAe0000009HJNKA2",
            "isRequiredResource": true,
            "isPrimaryResource": true
        }
    ],
    "qualifications": [
        {
            "subtype": "L2S_BATHROOM_QUALIF_LVL_1",
            "questions": [
                {
                    "label": "O que gostaria de instalar ou substituir na sua casa de banho?",
                    "answers": [
                        {
                            "label": "Banheira"
                        },
                        {
                            "label": "Sanita"
                        },
                        {
                            "label": "Bidé"
                        }
                    ]
                },
                {
                    "label": "Qual o estilo que prefere para a sua casa de banho?",
                    "answers": [
                        {
                            "label": "Natura"
                        }
                    ]
                },
                {
                    "label": "Gostaria de nos confiar a instalação da sua casa de banho?",
                    "answers": [
                        {
                            "label": "Já tenho um instalador"
                        }
                    ]
                },
                {
                    "label": "Qual o orçamento que pretende investir no seu projeto?",
                    "answers": [
                        {
                            "label": "Entre 3000-4000€"
                        }
                    ]
                },
                {
                    "label": "Idealmente, quando espera que o seu projeto esteja concluído?",
                    "answers": [
                        {
                            "label": "Em menos de 2 meses"
                        }
                    ]
                }
            ]
        }
    ]
}

*/


public with sharing class AppointmentDTO {
    public ServiceAppointmentDTO serviceAppointment;
    public LeadDTO lead;
    public list<AssignedResourceDTO> assignedResources;
    public List<L2SAPIServiceHandler.QualificationWrapper> qualifications;

    public class ServiceAppointmentDTO {
        public String workTypeId;
        public String serviceTerritoryId;
        public String engagementChannelTypeId;
        public Datetime schedStartTime;
        public Datetime schedEndTime;
        public String additionalInformation;
        public String parentRecordId;
        public String street;
        public String city;
        public String state;
        public String postalCode;
        public String country;
        public String appointmentType;
        public String appointmentMode;
        public String attendeeLimit;
        public List<ExtendedFieldDTO> extendedFields;
        public String description;
    }

    public class LeadDTO {
        public String firstName;
        public String lastName;
        public String phone;
        public String email;
        public String company;
        public List<ExtendedFieldDTO> extendedFields;
    }

    public class ExtendedFieldDTO {
        public String name;
        public String value;
    }

    public class AssignedResourceDTO{
        public String serviceResourceId;
        public Boolean isRequiredResource;
        public Boolean isPrimaryResource;
    }
}