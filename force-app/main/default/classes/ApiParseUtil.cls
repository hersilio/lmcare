/**
 * @description       :
 * @author            : Hersilio Belini de Oliveira
 * @group             :
 * @last modified on  : 2025-11-27
 * @last modified by  : Hersilio Belini de Oliveira
**/
public with sharing class ApiParseUtil {

    public class InvalidPayloadException extends Exception {}

    /**
    * @description parse Date Time from String
    * @author Hersilio Belini de Oliveira | 2025-11-27
    * @param rawValue
    * @param propertyName
    * @return Datetime
    **/
    public static Datetime parseDatetime(String rawValue, String propertyName){
        if(String.isBlank(rawValue)){
            return null;
        }
        try{
            String normalizedDate = rawValue.replace('T', ' ');
            if(normalizedDate.endsWith('Z')){
                normalizedDate = normalizedDate.substring(0, normalizedDate.length() - 1);
                return Datetime.valueOfGmt(normalizedDate);
            }
            return Datetime.valueOf(normalizedDate);
        } catch(Exception e){
            throw new InvalidPayloadException('Valor inválido para ' + propertyName);
        }
    }

    /**
    * @description pase Decimal from String
    * @author Hersilio Belini de Oliveira | 2025-11-27
    * @param rawValue
    * @param propertyName
    * @return Decimal
    **/
    public static Decimal parseDecimal(String rawValue, String propertyName){
        if(String.isBlank(rawValue)){
            return null;
        }
        try{
            return Decimal.valueOf(rawValue);
        } catch(Exception e){
            throw new InvalidPayloadException('Valor inválido para ' + propertyName);
        }
    }

    /**
    * @description pase Boolean from String
    * @author Hersilio Belini de Oliveira | 2025-11-27
    * @param rawValue
    * @param propertyName
    * @return Boolean
    **/
    public static Boolean parseBoolean(String rawValue, String propertyName){
        if(String.isBlank(rawValue)){
            return null;
        }
        if(rawValue.equalsIgnoreCase('true') || rawValue == '1'){
            return true;
        }
        if(rawValue.equalsIgnoreCase('false') || rawValue == '0'){
            return false;
        }
        throw new InvalidPayloadException('Valor inválido para ' + propertyName);
    }

    /**
    * @description pase Integer from String
    * @author Miguel Lopes | 2025-11-27
    * @param rawValue
    * @param propertyName
    * @return Intetger
    **/
    public static Integer parseInteger(String rawValue, String propertyName){

        if(propertyName == 'orderLineItems.pdo'){
            if(rawValue == ''){
                return 0;
            }
        }

        if(String.isBlank(rawValue)){
            return null;
        }
        try{
            return Integer.valueOf(rawValue);
        } catch(Exception e){
            throw new InvalidPayloadException('Valor inválido para ' + propertyName);
        }
    }

    /**
    * @description Validated if Null
    * @author Miguel Lopes | 2025-12-11
    * @param rawValue
    * @param propertyName
    * @return Default value
    **/
    public static String checkIfNull (String rawValue, String propertyName){
        String defaultValue = '';
        if(rawValue == ''){
            if(propertyName == 'orderLineItems.productReferenceEan'){
                defaultValue = 'productReferenceEan_EMPTY_';
            }
            if(propertyName == 'quoteLineItems.productReferenceEan'){
                defaultValue = 'productReferenceEan_EMPTY_';
            }
            if(propertyName == 'orderItems.productReferenceEan'){
                defaultValue = 'productReferenceEan_EMPTY_';
            }
        }
        else{
            defaultValue = rawValue; 
        }
        return defaultValue;
    }
}