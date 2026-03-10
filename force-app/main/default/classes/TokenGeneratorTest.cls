@isTest
public with sharing class TokenGeneratorTest {
    
    static Integer SIZE = 6;
    static String regexPattern = '^[A-Z0-9]{' + SIZE + '}$';

    @isTest
    public static void generateTokenTest(){

        String token = LM_TokenGenerator.generateToken(SIZE);
        System.assertEquals(SIZE, token.length());
        
        Pattern pattern = Pattern.compile(regexPattern);
        Matcher matcher = pattern.matcher(token);

        System.assert(matcher.matches());
    }


    @isTest
    public static void invocableGenerateTokenTest(){
        List<String> result = LM_TokenGenerator.invocableGenerateToken();
        
        Pattern pattern = Pattern.compile(regexPattern);

        for (String token: result){
            Matcher matcher = pattern.matcher(token);
            System.assert(matcher.matches());
            System.assertEquals(SIZE, token.length());
        }
    }

    @isTest
    public static void auraGenerateTokenTest(){
        String token = LM_TokenGenerator.auraGenerateToken();

        Pattern pattern = Pattern.compile(regexPattern);
        Matcher matcher = pattern.matcher(token);

        System.assertEquals(SIZE, token.length());
        System.assert(matcher.matches());
    }
}