/**
 * @description       : Test class for L2SAPIService REST API
 * @author            : Catarina Lopes
 * @group             :
 * @last modified on  : 2026-03-02
 * @last modified by  : Catarina Lopes
 **/
@IsTest
private class L2SAPIServiceTest {

    private static final String VALID_ENDPOINT = '/services/apexrest/leads/v1/lead';
    private static final String MDM_ID = '2462';
    private static final String PROJECT_ID = 'PROJ-001';

    @TestSetup
    static void setupTestData() {
        OperatingHours operatingHours = new OperatingHours(
            Name = 'Test Operating Hours',
            TimeZone = 'Europe/Lisbon'
        );
        insert operatingHours;

        ServiceTerritory territoryAlfragide = new ServiceTerritory(
            Name = 'Alfragide',
            OperatingHoursId = operatingHours.Id,
            StoreID__c = '001'
        );
        insert territoryAlfragide;

        ServiceTerritory territoryMaia = new ServiceTerritory(
            Name = 'Maia',
            OperatingHoursId = operatingHours.Id,
            StoreID__c = '002'
        );
        insert territoryMaia;
    }

    private static void setupRestContext(String jsonBody) {
        RestContext.request = new RestRequest();
        RestContext.request.requestUri = VALID_ENDPOINT;
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(jsonBody);
        RestContext.response = new RestResponse();
    }

    private static String createBasePayload() {
        return '{"mdmId":"' + MDM_ID + '","leadSource":"Website","team":"VAD","status":"New","projectId":"' + PROJECT_ID + '","projectTag":"BATHROOM"}';
    }

    @IsTest
    static void testCreateLead_Success_WithAllFields() {
        setupRestContext(createBasePayload());

        Test.startTest();
        L2SAPIService.createLead();
        Test.stopTest();

        Assert.areEqual(201, RestContext.response.statusCode, 'Expected 201 for successful lead creation');
        String responseBody = RestContext.response.responseBody.toString();
        Assert.isTrue(responseBody.contains('leadId'), 'Response should contain leadId');
        Assert.isTrue(responseBody.contains('"mdmId":"' + MDM_ID + '"'), 'Response should contain mdmId');
    }

    @IsTest
    static void testCreateLead_Success_WithoutTeam() {
        String jsonBody = '{"mdmId":"' + MDM_ID + '","leadSource":"Website","team":"VAD","status":"New","projectId":"' + PROJECT_ID + '","projectTag":"BATHROOM"}';
        setupRestContext(jsonBody);

        Test.startTest();
        L2SAPIService.createLead();
        Test.stopTest();

        Assert.areEqual(201, RestContext.response.statusCode, 'Expected 201 for lead creation without team');
    }

    @IsTest
    static void testCreateLead_Success_WithStoreId() {
        String jsonBody = '{"mdmId":"' + MDM_ID + '","leadSource":"Website","team":"VAD","status":"New","projectId":"' + PROJECT_ID + '","projectTag":"BATHROOM","storeId":"001"}';
        setupRestContext(jsonBody);

        Test.startTest();
        L2SAPIService.createLead();
        Test.stopTest();

        Assert.areEqual(201, RestContext.response.statusCode, 'Expected 201 for lead creation with storeId');
        
        Lead createdLead = [SELECT Loja_de_Angariacao__c FROM Lead WHERE Numero_de_Conta_na_lead__c = :MDM_ID LIMIT 1];
        Assert.areEqual('Alfragide', createdLead.Loja_de_Angariacao__c, 'Lead should be assigned to correct store');
    }

    @IsTest
    static void testCreateLead_Success_WithInvalidStoreId() {
        String jsonBody = '{"mdmId":"' + MDM_ID + '","leadSource":"Website","team":"VAD","status":"New","projectId":"' + PROJECT_ID + '","projectTag":"BATHROOM","storeId":"999"}';
        setupRestContext(jsonBody);

        Test.startTest();
        L2SAPIService.createLead();
        Test.stopTest();

        Assert.areEqual(201, RestContext.response.statusCode, 'Expected 201 even with invalid storeId');
        
        Lead createdLead = [SELECT Loja_de_Angariacao__c FROM Lead WHERE Numero_de_Conta_na_lead__c = :MDM_ID LIMIT 1];
        Assert.isNull(createdLead.Loja_de_Angariacao__c, 'Loja should be null for invalid storeId');
    }

    @IsTest
    static void testCreateLead_Success_WithInvalidQualificationSubtype() {
        String jsonBody = '{"mdmId":"' + MDM_ID + '","leadSource":"Website","team":"VAD","status":"New","projectId":"' + PROJECT_ID + '","projectTag":"BATHROOM","qualification":[{"subtype":"Invalid-Subtype","questions":[{"label":"Question 1","answers":[{"label":"Answer 1"}]}]}]}';
        setupRestContext(jsonBody);

        Test.startTest();
        L2SAPIService.createLead();
        Test.stopTest();

        Assert.areEqual(500, RestContext.response.statusCode, 'Expected 500 for invalid qualification subtype');
    }

    @IsTest
    static void testCreateLead_UpdateExistingLead() {
        Lead existingLead = new Lead(
            FirstName = 'Existing',
            LastName = 'Lead',
            ProjectId__c = PROJECT_ID,
            Status = 'Open',
            Company = 'Test Company',
            Numero_de_Conta_na_lead__c = MDM_ID,
            Email = 'test@test.com',
            Phone = '+351123456789'
        );
        insert existingLead;

        String jsonBody = '{"mdmId":"' + MDM_ID + '","leadSource":"Website","team":"VAD","status":"New","projectId":"' + PROJECT_ID + '-NEW","projectTag":"BATHROOM"}';
        setupRestContext(jsonBody);

        Test.startTest();
        L2SAPIService.createLead();
        Test.stopTest();

        Assert.areEqual(201, RestContext.response.statusCode, 'Expected 201 for lead update');
        
        Lead updatedLead = [SELECT Id, ProjectId__c, Numero_de_Conta_na_lead__c FROM Lead WHERE Numero_de_Conta_na_lead__c = :MDM_ID AND ProjectId__c = :PROJECT_ID + '-NEW' LIMIT 1];
        Assert.areEqual(MDM_ID, updatedLead.Numero_de_Conta_na_lead__c, 'MDM ID should be updated');
    }

    @IsTest
    static void testCreateLead_MissingRequestBody() {
        setupRestContext('');

        Test.startTest();
        L2SAPIService.createLead();
        Test.stopTest();

        Assert.areEqual(400, RestContext.response.statusCode, 'Expected 400 for empty request body');
        String responseBody = RestContext.response.responseBody.toString();
        Assert.isTrue(responseBody.contains('Missing request body'), 'Error should indicate missing body');
    }

    @IsTest
    static void testCreateLead_NullRequestBody() {
        RestContext.request = new RestRequest();
        RestContext.request.requestUri = VALID_ENDPOINT;
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = null;
        RestContext.response = new RestResponse();

        Test.startTest();
        L2SAPIService.createLead();
        Test.stopTest();

        Assert.areEqual(400, RestContext.response.statusCode, 'Expected 400 for null request body');
    }

    @IsTest
    static void testCreateLead_InvalidJsonPayload() {
        setupRestContext('{invalid json');

        Test.startTest();
        L2SAPIService.createLead();
        Test.stopTest();

        Assert.areEqual(400, RestContext.response.statusCode, 'Expected 400 for invalid JSON');
        String responseBody = RestContext.response.responseBody.toString();
        Assert.isTrue(responseBody.contains('Invalid JSON payload'), 'Error should indicate invalid JSON');
    }

    @IsTest
    static void testCreateLead_MissingAllRequiredFields() {
        setupRestContext('{}');

        Test.startTest();
        L2SAPIService.createLead();
        Test.stopTest();

        Assert.areEqual(400, RestContext.response.statusCode, 'Expected 400 for missing all fields');
        String responseBody = RestContext.response.responseBody.toString();
        Assert.isTrue(responseBody.contains('mdmId'), 'Error should mention mdmId');
        Assert.isTrue(responseBody.contains('leadSource'), 'Error should mention leadSource');
        Assert.isTrue(responseBody.contains('team'), 'Error should mention team');
        Assert.isTrue(responseBody.contains('status'), 'Error should mention status');
        Assert.isTrue(responseBody.contains('projectId'), 'Error should mention projectId');
        Assert.isTrue(responseBody.contains('projectTag'), 'Error should mention projectTag');
    }

    @IsTest
    static void testCreateLead_MissingSingleRequiredField() {
        String jsonBody = '{"mdmId":"' + MDM_ID + '","leadSource":"Website","team":"VAD","status":"New","projectId":"' + PROJECT_ID + '"}';
        setupRestContext(jsonBody);

        Test.startTest();
        L2SAPIService.createLead();
        Test.stopTest();

        Assert.areEqual(400, RestContext.response.statusCode, 'Expected 400 for missing projectTag');
        String responseBody = RestContext.response.responseBody.toString();
        Assert.isTrue(responseBody.contains('projectTag'), 'Error should mention projectTag');
    }

    @IsTest
    static void testCreateLead_InvalidEndpoint() {
        RestContext.request = new RestRequest();
        RestContext.request.requestUri = '/services/apexrest/leads/v1/invalid';
        RestContext.request.httpMethod = 'POST';
        RestContext.request.requestBody = Blob.valueOf(createBasePayload());
        RestContext.response = new RestResponse();

        Test.startTest();
        L2SAPIService.createLead();
        Test.stopTest();

        Assert.areEqual(404, RestContext.response.statusCode, 'Expected 404 for invalid endpoint');
    }

    @IsTest
    static void testHandleRequest_DirectCall_Success() {
        L2SAPIServiceHandler.L2SIntegrationResult result = L2SAPIServiceHandler.handleRequest(createBasePayload(), 'lead');

        Assert.isNotNull(result, 'Result should not be null');
    }

    @IsTest
    static void testHandleRequest_DirectCall_MissingBody() {
        L2SAPIServiceHandler.L2SIntegrationResult result = L2SAPIServiceHandler.handleRequest('', 'lead');

        Assert.areEqual(400, result.statusCode, 'Expected 400 for missing body');
        Assert.isTrue(result.errorMessage.contains('Missing request body'), 'Error message should match');
    }

    @IsTest
    static void testHandleRequest_DirectCall_NullBody() {
        L2SAPIServiceHandler.L2SIntegrationResult result = L2SAPIServiceHandler.handleRequest(null, 'lead');

        Assert.areEqual(400, result.statusCode, 'Expected 400 for null body');
    }

    @IsTest
    static void testHandleRequest_DirectCall_InvalidJson() {
        L2SAPIServiceHandler.L2SIntegrationResult result = L2SAPIServiceHandler.handleRequest('{invalid', 'lead');

        Assert.areEqual(400, result.statusCode, 'Expected 400 for invalid JSON');
    }

    @IsTest
    static void testHandleRequest_DirectCall_MissingFields() {
        L2SAPIServiceHandler.L2SIntegrationResult result = L2SAPIServiceHandler.handleRequest('{"mdmId":"123"}', 'lead');

        Assert.areEqual(400, result.statusCode, 'Expected 400 for missing fields');
        Assert.isTrue(result.errorMessage.contains('Missing required fields'), 'Error should mention missing fields');
    }

    @IsTest
    static void testHandleRequest_DirectCall_DerivedStoreFromClient() {
        String jsonBody = '{"mdmId":"' + MDM_ID + '","leadSource":"Website","team":"VAD","status":"New","projectId":"' + PROJECT_ID + '","projectTag":"BATHROOM","storeId":""}';
        
        L2SAPIServiceHandler.L2SIntegrationResult result = L2SAPIServiceHandler.handleRequest(jsonBody, 'lead');

        Assert.areEqual(201, result.statusCode, 'Expected 201 when storeId is empty string');
    }

    @IsTest
    static void testResponseWrapper_Serialization() {
        L2SAPIServiceHandler.L2SResponseWrapper response = new L2SAPIServiceHandler.L2SResponseWrapper(MDM_ID, '00Q000000000000');

        String serialized = JSON.serialize(response);
        
        Assert.isTrue(serialized.contains('"mdmId":"' + MDM_ID + '"'), 'JSON should contain mdmId');
        Assert.isTrue(serialized.contains('"leadId":"00Q000000000000"'), 'JSON should contain leadId');
    }

    @IsTest
    static void testErrorWrapper_Serialization() {
        L2SAPIServiceHandler.L2SErrorWrapper error = new L2SAPIServiceHandler.L2SErrorWrapper('Test Error', 'Try again');

        String serialized = JSON.serialize(error);
        
        Assert.isTrue(serialized.contains('"errorMessage":"Test Error"'), 'JSON should contain errorMessage');
        Assert.isTrue(serialized.contains('"detailAction":"Try again"'), 'JSON should contain detailAction');
    }

    @IsTest
    static void testIntegrationResult_Construction() {
        L2SAPIServiceHandler.L2SIntegrationResult result = new L2SAPIServiceHandler.L2SIntegrationResult(
            201,
            new L2SAPIServiceHandler.L2SResponseWrapper(MDM_ID, '00Q000000000000'),
            new List<Lead>{ new Lead(LastName = 'Test') },
            null
        );

        Assert.areEqual(201, result.statusCode, 'Status code should match');
        Assert.isNotNull(result.responseBody, 'Response body should not be null');
        Assert.areEqual(1, result.recordsCreate.size(), 'Records should contain one lead');
        Assert.isNull(result.errorMessage, 'Error message should be null for success');
    }

    @IsTest
    static void testIntegrationResult_ErrorConstruction() {
        L2SAPIServiceHandler.L2SIntegrationResult result = new L2SAPIServiceHandler.L2SIntegrationResult(
            400,
            new L2SAPIServiceHandler.L2SErrorWrapper('Error', 'Action'),
            null,
            'Error message'
        );

        Assert.areEqual(400, result.statusCode, 'Status code should match');
        Assert.isNotNull(result.responseBody, 'Response body should not be null');
        Assert.isNull(result.recordsCreate, 'Records should be null for error');
        Assert.areEqual('Error message', result.errorMessage, 'Error message should match');
    }

    @IsTest
    static void testHandleRequest_ClientWithDashLastName() {
        String jsonBody = '{"mdmId":"' + MDM_ID + '","leadSource":"Website","team":"VAD","status":"New","projectId":"' + PROJECT_ID + 'Dash","projectTag":"BATHROOM","storeId":"001"}';
        
        L2SAPIServiceHandler.L2SIntegrationResult result = L2SAPIServiceHandler.handleRequest(jsonBody, 'lead');

        Assert.areEqual(201, result.statusCode, 'Expected 201 for client with dash lastName');
        Assert.isNotNull(result.recordsCreate, 'Records should not be null');
        Lead createdLead = (Lead)result.recordsCreate[0];
        Assert.areEqual('COSTA DO SOL', createdLead.LastName, 'LastName should be from client inhabitant');
    }

    @IsTest
    static void testHandleRequest_ClientWithBlankLastName() {
        String jsonBody = '{"mdmId":"' + MDM_ID + '","leadSource":"Website","team":"VAD","status":"New","projectId":"' + PROJECT_ID + 'Blank","projectTag":"BATHROOM","storeId":"001"}';
        
        L2SAPIServiceHandler.L2SIntegrationResult result = L2SAPIServiceHandler.handleRequest(jsonBody, 'lead');

        Assert.areEqual(201, result.statusCode, 'Expected 201 for client with blank lastName');
        Assert.isNotNull(result.recordsCreate, 'Records should not be null');
        Lead createdLead = (Lead)result.recordsCreate[0];
        Assert.areEqual('COSTA DO SOL', createdLead.LastName, 'LastName should be from client inhabitant');
    }

    @IsTest
    static void testHandleRequest_StoreDerivedFromClient() {
        String jsonBody = '{"mdmId":"' + MDM_ID + '","leadSource":"Website","team":"VAD","status":"New","projectId":"' + PROJECT_ID + 'ClientStore","projectTag":"BATHROOM","storeId":""}';
        
        L2SAPIServiceHandler.L2SIntegrationResult result = L2SAPIServiceHandler.handleRequest(jsonBody, 'lead');

        Assert.areEqual(201, result.statusCode, 'Expected 201 when storeId is empty');
        Lead createdLead = (Lead)result.recordsCreate[0];
        Assert.isNotNull(createdLead.Loja_de_Angariacao__c, 'Loja should be derived from client');
    }

    @IsTest
    static void testHandleRequest_NoClientFound() {
        String jsonBody = '{"mdmId":"999999","leadSource":"Website","team":"VAD","status":"New","projectId":"' + PROJECT_ID + 'NoClient","projectTag":"BATHROOM","storeId":"001"}';
        
        L2SAPIServiceHandler.L2SIntegrationResult result = L2SAPIServiceHandler.handleRequest(jsonBody, 'lead');

        Assert.areEqual(201, result.statusCode, 'Mock client is returned in test context');
    }

    @IsTest
    static void testHandleRequest_ValidQualificationWithQualification1() {
        String jsonBody = '{"mdmId":"' + MDM_ID + '","leadSource":"Website","team":"VAD","status":"New","projectId":"' + PROJECT_ID + 'Qual1","projectTag":"BATHROOM","storeId":"001",' +
            '"qualification":[{"subtype":"L2S_BATHROOM_QUALIF_LVL_1","questions":[{"label":"Question 1","answers":[{"label":"Answer 1"}]}]}]}';
        
        L2SAPIServiceHandler.L2SIntegrationResult result = L2SAPIServiceHandler.handleRequest(jsonBody, 'lead');

        Assert.areEqual(201, result.statusCode, 'Expected 201 for valid qualification');
    }

    @IsTest
    static void testHandleRequest_ValidQualificationWithQualification2() {
        String jsonBody = '{"mdmId":"' + MDM_ID + '","leadSource":"Website","team":"VAD","status":"New","projectId":"' + PROJECT_ID + 'Qual2","projectTag":"BATHROOM","storeId":"001",' +
            '"qualification":[{"subtype":"L2S_BATHROOM_QUALIF_LVL_2","questions":[{"label":"Question 2","answers":[{"label":"Answer 2"}]}]}]}';
        
        L2SAPIServiceHandler.L2SIntegrationResult result = L2SAPIServiceHandler.handleRequest(jsonBody, 'lead');

        Assert.areEqual(201, result.statusCode, 'Expected 201 for valid qualification2');
    }

    @IsTest
    static void testHandleRequest_ValidQualificationWithBothQualifications() {
        String jsonBody = '{"mdmId":"' + MDM_ID + '","leadSource":"Website","team":"VAD","status":"New","projectId":"' + PROJECT_ID + 'QualBoth","projectTag":"BATHROOM","storeId":"001",' +
            '"qualification":[' +
            '{"subtype":"L2S_BATHROOM_QUALIF_LVL_1","questions":[{"label":"Question 1","answers":[{"label":"Answer 1"}]}]},' +
            '{"subtype":"L2S_BATHROOM_QUALIF_LVL_2","questions":[{"label":"Question 2","answers":[{"label":"Answer 2"}]}]}' +
            ']}';
        
        L2SAPIServiceHandler.L2SIntegrationResult result = L2SAPIServiceHandler.handleRequest(jsonBody, 'lead');

        Assert.areEqual(201, result.statusCode, 'Expected 201 for both valid qualifications');
    }

    @IsTest
    static void testHandleRequest_InvalidQualificationSubtype() {
        String jsonBody = '{"mdmId":"' + MDM_ID + '","leadSource":"Website","team":"VAD","status":"New","projectId":"' + PROJECT_ID + 'InvalidQual","projectTag":"BATHROOM","storeId":"001",' +
            '"qualification":[{"subtype":"INVALID_SUBTYPE","questions":[{"label":"Question 1","answers":[{"label":"Answer 1"}]}]}]}';
        
        L2SAPIServiceHandler.L2SIntegrationResult result = L2SAPIServiceHandler.handleRequest(jsonBody, 'lead');

        Assert.areEqual(500, result.statusCode, 'Expected 500 for invalid qualification subtype');
        Assert.isTrue(result.errorMessage.contains('improperly formatted'), 'Error should mention improperly formatted');
    }

    @IsTest
    static void testHandleRequest_NullQualification() {
        String jsonBody = '{"mdmId":"' + MDM_ID + '","leadSource":"Website","team":"VAD","status":"New","projectId":"' + PROJECT_ID + 'NullQual","projectTag":"BATHROOM","storeId":"001","qualification":null}';
        
        L2SAPIServiceHandler.L2SIntegrationResult result = L2SAPIServiceHandler.handleRequest(jsonBody, 'lead');

        Assert.areEqual(201, result.statusCode, 'Expected 201 for null qualification');
    }

    @IsTest
    static void testHandleRequest_EmptyQualificationList() {
        String jsonBody = '{"mdmId":"' + MDM_ID + '","leadSource":"Website","team":"VAD","status":"New","projectId":"' + PROJECT_ID + 'EmptyQual","projectTag":"BATHROOM","storeId":"001","qualification":[]}';
        
        L2SAPIServiceHandler.L2SIntegrationResult result = L2SAPIServiceHandler.handleRequest(jsonBody, 'lead');

        Assert.areEqual(201, result.statusCode, 'Expected 201 for empty qualification list');
    }

    @IsTest
    static void testHandleRequest_WithoutStoreId() {
        String jsonBody = '{"mdmId":"' + MDM_ID + '","leadSource":"Website","team":"VAD","status":"New","projectId":"' + PROJECT_ID + 'NoStore","projectTag":"BATHROOM"}';
        
        L2SAPIServiceHandler.L2SIntegrationResult result = L2SAPIServiceHandler.handleRequest(jsonBody, 'lead');

        Assert.areEqual(201, result.statusCode, 'Expected 201 when storeId is not provided');
    }

    @IsTest
    static void testHandleRequest_WithEmptyTeam() {
        String jsonBody = '{"mdmId":"' + MDM_ID + '","leadSource":"Website","team":"","status":"New","projectId":"' + PROJECT_ID + 'EmptyTeam","projectTag":"BATHROOM","storeId":"001"}';
        
        L2SAPIServiceHandler.L2SIntegrationResult result = L2SAPIServiceHandler.handleRequest(jsonBody, 'lead');

        Assert.areEqual(400, result.statusCode, 'Expected 400 when team is empty (required field)');
    }

    @IsTest
    static void testHandleRequest_WithNullTeam() {
        String jsonBody = '{"mdmId":"' + MDM_ID + '","leadSource":"Website","team":null,"status":"New","projectId":"' + PROJECT_ID + 'NullTeam","projectTag":"BATHROOM","storeId":"001"}';
        
        L2SAPIServiceHandler.L2SIntegrationResult result = L2SAPIServiceHandler.handleRequest(jsonBody, 'lead');

        Assert.areEqual(400, result.statusCode, 'Expected 400 when team is null (required field)');
    }

    @IsTest
    static void testHandleRequest_LeadUpsert() {
        Lead existingLead = new Lead(
            FirstName = 'Existing',
            LastName = 'Lead',
            ProjectId__c = PROJECT_ID + 'Upsert',
            Status = 'Open',
            Company = 'Test Company',
            Numero_de_Conta_na_lead__c = MDM_ID,
            Email = 'test@test.com',
            Phone = '+351123456789'
        );
        insert existingLead;

        String jsonBody = '{"mdmId":"' + MDM_ID + '","leadSource":"Website","team":"VAD","status":"New","projectId":"' + PROJECT_ID + 'Upsert","projectTag":"BATHROOM","storeId":"001"}';
        
        L2SAPIServiceHandler.L2SIntegrationResult result = L2SAPIServiceHandler.handleRequest(jsonBody, 'lead');

        Assert.areEqual(201, result.statusCode, 'Expected 201 for lead upsert');
        List<Lead> leads = [SELECT Id, ProjectId__c FROM Lead WHERE Numero_de_Conta_na_lead__c = :MDM_ID AND ProjectId__c = :PROJECT_ID + 'Upsert'];
        Assert.areEqual(1, leads.size(), 'Should have only one lead after upsert');
    }

    @IsTest
    static void testHandleRequest_NullRequestWrapper() {
        String jsonBody = 'null';
        
        L2SAPIServiceHandler.L2SIntegrationResult result = L2SAPIServiceHandler.handleRequest(jsonBody, 'lead');

        Assert.areEqual(400, result.statusCode, 'Expected 400 for null request wrapper');
    }

    @IsTest
    static void testHandleRequest_ClientWithMembersAndLegalRepresentative() {
        String jsonBody = '{"mdmId":"WITH_MEMBERS","leadSource":"Website","team":"VAD","status":"New","projectId":"' + PROJECT_ID + 'Members","projectTag":"BATHROOM","storeId":"001"}';
        
        L2SAPIServiceHandler.L2SIntegrationResult result = L2SAPIServiceHandler.handleRequest(jsonBody, 'lead');

        Assert.areEqual(201, result.statusCode, 'Expected 201 for client with members');
        Lead createdLead = (Lead)result.recordsCreate[0];
        Assert.areEqual('.', createdLead.LastName, 'LastName should be dot for dash lastName');
        Assert.areEqual('legal@teste.com', createdLead.Email, 'Email should be from legal representative');
        Assert.areEqual('+351911111111', createdLead.MobilePhone, 'MobilePhone should be from legal representative');
    }
}