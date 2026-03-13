# MinimumValueConfig API

Este metadata pode ser consumido diretamente pela REST API padrão do Salesforce, sem Apex custom.

## Endpoint base

```text
GET /services/data/v66.0/query?q=<SOQL>
```

## Autenticação

Usar um `access_token` OAuth válido no header:

```http
Authorization: Bearer <ACCESS_TOKEN>
Content-Type: application/json
```

## Consulta de todos os registos com todos os campos do tipo

```soql
SELECT DeveloperName,
       MasterLabel,
       CurrencyCode__c,
       IsActive__c,
       MinimumValue__c,
       Notes__c,
       SectionCode__c,
       SectionName__c,
       SubsectionCode__c,
       SubsectionName__c,
       TypeCode__c,
       TypeName__c,
       SubtypeCode__c,
       SubtypeName__c
FROM MinimumValueConfig__mdt
ORDER BY SectionCode__c, SubsectionCode__c, TypeCode__c, SubtypeCode__c
```

Exemplo `curl`:

```bash
curl --request GET \
  --url "https://YOUR_DOMAIN.my.salesforce.com/services/data/v66.0/query?q=SELECT%20DeveloperName%2C%20MasterLabel%2C%20CurrencyCode__c%2C%20IsActive__c%2C%20MinimumValue__c%2C%20Notes__c%2C%20SectionCode__c%2C%20SectionName__c%2C%20SubsectionCode__c%2C%20SubsectionName__c%2C%20TypeCode__c%2C%20TypeName__c%2C%20SubtypeCode__c%2C%20SubtypeName__c%20FROM%20MinimumValueConfig__mdt%20ORDER%20BY%20SectionCode__c%2C%20SubsectionCode__c%2C%20TypeCode__c%2C%20SubtypeCode__c" \
  --header "Authorization: Bearer <ACCESS_TOKEN>" \
  --header "Content-Type: application/json"
```

## Consulta filtrada

Se a equipa de engenharia enviar todos os filtros, a chamada pode filtrar exatamente o registo esperado.

Exemplo para secção `8` e subsecção `60`:

```soql
SELECT DeveloperName,
       MasterLabel,
       CurrencyCode__c,
       IsActive__c,
       MinimumValue__c,
       Notes__c,
       SectionCode__c,
       SectionName__c,
       SubsectionCode__c,
       SubsectionName__c,
       TypeCode__c,
       TypeName__c,
       SubtypeCode__c,
       SubtypeName__c
FROM MinimumValueConfig__mdt
WHERE IsActive__c = true
  AND SectionCode__c = '8'
  AND SubsectionCode__c = '60'
```

Exemplo `curl`:

```bash
curl --request GET \
  --url "https://YOUR_DOMAIN.my.salesforce.com/services/data/v66.0/query?q=SELECT%20DeveloperName%2C%20MasterLabel%2C%20CurrencyCode__c%2C%20IsActive__c%2C%20MinimumValue__c%2C%20Notes__c%2C%20SectionCode__c%2C%20SectionName__c%2C%20SubsectionCode__c%2C%20SubsectionName__c%2C%20TypeCode__c%2C%20TypeName__c%2C%20SubtypeCode__c%2C%20SubtypeName__c%20FROM%20MinimumValueConfig__mdt%20WHERE%20IsActive__c%20%3D%20true%20AND%20SectionCode__c%20%3D%20%278%27%20AND%20SubsectionCode__c%20%3D%20%2760%27" \
  --header "Authorization: Bearer <ACCESS_TOKEN>" \
  --header "Content-Type: application/json"
```

## Exemplo de resposta

```json
{
  "totalSize": 1,
  "done": true,
  "records": [
    {
      "attributes": {
        "type": "MinimumValueConfig__mdt",
        "url": "/services/data/v66.0/sobjects/MinimumValueConfig__mdt/MinimumValueConfig.Section_8_Subsection_60_Roupeiros"
      },
      "DeveloperName": "Section_8_Subsection_60_Roupeiros",
      "MasterLabel": "Secção 8 / Subsecção 60 - Roupeiros",
      "CurrencyCode__c": "EUR",
      "IsActive__c": true,
      "MinimumValue__c": 1300.0,
      "Notes__c": "Aplica-se apenas à subsecção 60 da secção 8 e deve ser avaliada antes da regra geral da secção 8.",
      "SectionCode__c": "8",
      "SectionName__c": "Cozinhas",
      "SubsectionCode__c": "60",
      "SubsectionName__c": "Roupeiros",
      "TypeCode__c": null,
      "TypeName__c": null,
      "SubtypeCode__c": null,
      "SubtypeName__c": null
    }
  ]
}
```

## Exemplo em JavaScript

```javascript
const soql = `
  SELECT DeveloperName,
         MasterLabel,
         CurrencyCode__c,
         IsActive__c,
         MinimumValue__c,
         Notes__c,
         SectionCode__c,
         SectionName__c,
         SubsectionCode__c,
         SubsectionName__c,
         TypeCode__c,
         TypeName__c,
         SubtypeCode__c,
         SubtypeName__c
  FROM MinimumValueConfig__mdt
  WHERE IsActive__c = true
`;

const response = await fetch(
  `https://YOUR_DOMAIN.my.salesforce.com/services/data/v66.0/query?q=${encodeURIComponent(soql)}`,
  {
    method: 'GET',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json'
    }
  }
);

const data = await response.json();
console.log(data.records);
```

## Observação

Como esta solução usa a API padrão de `query`, qualquer consumidor pode montar filtros adicionais com `WHERE` para `SectionCode__c`, `SubsectionCode__c`, `TypeCode__c` e `SubtypeCode__c` sem necessidade de nova API customizada.
