public with sharing class LM_TokenGenerator {

    static final Integer SIZE = 6;

    public static String generateToken(Integer len) {
        String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        String[] result = new String[len];
        Integer idx = 0;

        while(idx < len) {
            Integer chr = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            result[idx++] = chars.substring(chr, chr+1);
        }
        return String.join(result,'');
    }

    @InvocableMethod(label='Generate Token')
    public static List<String> invocableGenerateToken(){
        return new List<String>{generateToken(SIZE)};
    }

    @AuraEnabled
    public static String auraGenerateToken(){
        
        return generateToken(SIZE);
    }
}