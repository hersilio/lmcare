@IsTest
private class EmailMessageVisibilityBatch_TEST {
    
    @IsTest
    static void testExecuteLogic() {
        // Criar dados de teste
        Account acc = new Account(Name = 'Test');
        insert acc;
        
        EmailMessage em = new EmailMessage(
            Subject             = 'Test',
            FromAddress         = 'test@example.com',
            ToAddress           = 'user@example.com',
            Status              = '0',
            Incoming            = false,
            IsExternallyVisible = false,
            RelatedToId         = acc.Id
        );
        insert em;

        // Obter scope que o start() devolveria
        List<EmailMessage> scope = [
            SELECT Id, IsExternallyVisible
            FROM EmailMessage
            WHERE Id = :em.Id
        ];

        Test.startTest();
        EmailMessageVisibilityBatch batch = new EmailMessageVisibilityBatch();
        batch.execute(null, scope);
        Test.stopTest();

        // Verificar que foi atualizado
        EmailMessage updated = [
            SELECT IsExternallyVisible
            FROM EmailMessage
            WHERE Id = :em.Id
        ];
        System.assertEquals(true, updated.IsExternallyVisible);
        System.assertEquals(1, batch.totalProcessed);
    }
    
    @IsTest
    static void testExecuteEmptyScope() {
        Test.startTest();
        EmailMessageVisibilityBatch batch = new EmailMessageVisibilityBatch();
        batch.execute(null, new List<EmailMessage>());
        Test.stopTest();
        
        System.assertEquals(0, batch.totalProcessed);
    }
    
    @IsTest
    static void testStartInactiveFlag() {
        EmailMessageVisibilityBatch batch = new EmailMessageVisibilityBatch();
        
        Test.startTest();
        Database.QueryLocator ql = batch.start(null);
        Test.stopTest();
        
        // Verificar que retorna vazio quando flag inativa
        Iterator<SObject> it = ql.iterator();
        System.assert(!it.hasNext(), 'QueryLocator deve estar vazio com flag inativa');
    }
    
    @IsTest
    static void testRunMethod() {
        Test.startTest();
        Id jobId = EmailMessageVisibilityBatch.run(10);
        Test.stopTest();
        
        System.assertNotEquals(null, jobId);
        AsyncApexJob job = [SELECT Id, Status FROM AsyncApexJob WHERE Id = :jobId];
        System.assertEquals('Completed', job.Status);
    }
}