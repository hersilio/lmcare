@IsTest
private class GSMUtilsTest {
    @IsTest
    static void testRemoveAccents() {
        // Input includes accents to be replaced, safe GSM-7 chars, digits, punctuation
        String input    = 'Olá, João! Êxito 123 àéü'; 
        String expected = 'Ola, Joao! Exito 123 àéü'; // Only 'á', 'ã', 'â', 'ê', 'í', 'î' should be replaced
        String result   = GSMUtils.toGSM7(input);
        System.assertEquals(expected, result, 'Accents to replace should be removed, others should remain');
    }

    @IsTest
    static void testUnsupportedCharacterReplacement() {
        String input  = 'Hello ☺'; // Smiley not in GSM-7
        String result = GSMUtils.toGSM7(input);
        System.assertEquals('Hello ?', result, 'Unsupported characters should be replaced with ?');
    }

    @IsTest
    static void testSupportedCharactersRemain() {
        String input  = 'Hello World!'; // All GSM-7 safe
        String result = GSMUtils.toGSM7(input);
        System.assertEquals('Hello World!', result, 'Supported GSM-7 characters should remain unchanged');
    }

    @IsTest
    static void testEmptyAndBlankStrings() {
        System.assertEquals(null, GSMUtils.toGSM7(null), 'Null should return null');
        System.assertEquals('', GSMUtils.toGSM7(''), 'Empty string should return empty');
        System.assertEquals('   ', GSMUtils.toGSM7('   '), 'Whitespace string should remain unchanged');
    }

    @IsTest
    static void testBigStringPerformance() {
        // Generate a large string for testing
        String largeString = '';
        for (Integer i = 0; i < 10000; i++) {
            largeString += 'Olá, João! ☺';
        }

        // Measure CPU time before
        Integer startTime = Limits.getCpuTime();

        String result = GSMUtils.toGSM7(largeString);

        // Measure CPU time after
        Integer endTime = Limits.getCpuTime();
        System.debug('GSMUtils.toGSM7 took: ' + (endTime - startTime) + ' ms');
    }
}