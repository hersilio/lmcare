public with sharing class GSMUtils {
    private static final Map<String, String> accentMap = new Map<String, String>{
        'á' => 'a','â' => 'a','ã' => 'a',
        'Á' => 'A','Â' => 'A','Ã' => 'A',
        'ê' => 'e','Ê' => 'E',
        'í' => 'i','î' => 'i',
        'Í' => 'I','Î' => 'I', 
        'ô' => 'o','õ' => 'o', 'ó' => 'o',
        'Ô' => 'O','Õ' => 'O', 'Ó' => 'O',
        'û' => 'u','Û' => 'U',
        'ç' => 'c'
    };

    // GSM-7 basic and extended characters
    private static final Set<String> gsmCharSet = new Set<String>{
        '@','£','$','¥','è','é','ù','ì','ò','Ç','\n','Ø','ø','\r','Å','å','Δ','_','Φ','Γ','Λ','Ω','Π','Ψ','Σ','Θ','Ξ','Æ','æ','ß','É',' ','!','"','#','¤','%','&','\'','(',')','*','+',',','-','.','/','0','1','2','3','4','5','6','7','8','9',':',';','<','=','>','?','¡',
        'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','Ä','Ö','Ñ','Ü','§','¿',
        'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','ä','ö','ñ','ü','à',
        '^','{','}','\\','[','~',']','|','€'
    };

    // Helper method to convert a string to a set of its characters
    private static Set<String> stringToSet(String str) {
        Set<String> charSet = new Set<String>();
        for (Integer i = 0; i < str.length(); i++) {
            charSet.add(str.substring(i, i+1));
        }
        return charSet;
    }

    /**
     * Converts the input string to a GSM-7 compliant string by replacing accented characters
     * and unsupported characters with '?'.
     * 
     * @param input The input string to be converted.
     * @return A GSM-7 compliant string with unsupported characters replaced.
    */
    public static String toGSM7(String input) {
        if (String.isBlank(input)) return input;

        String output = input;

        Set<String> inputChars  = stringToSet(input);
        Set<String> accentChars = accentMap.keySet();
        Set<String> accentCharsToReplace = inputChars.clone(); // Temp set for accented chars
        Set<String> otherCharsToReplace  = inputChars.clone(); // Temp set for other unsupported chars
        accentCharsToReplace.retainAll(accentChars);

        // If there are accented characters, replace them
        if (!accentCharsToReplace.isEmpty()){
            for (String ch : accentCharsToReplace)
                output = output.replace(ch, accentMap.get(ch));
        }

        otherCharsToReplace.removeAll(gsmCharSet);
        // If there are unsupported characters, replace them with '?'
        if (!otherCharsToReplace.isEmpty()) {
            for (String ch : otherCharsToReplace) 
                output = output.replace(ch, '?');
        }

        return output;
    }
}