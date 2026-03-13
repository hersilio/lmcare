public without sharing class LM_SplitText {
	@invocableMethod(label='Split Text' description='Splits text by separator and outputs a collection of strings')
    public static List<List<String>> splitString(List<FlowInput> input){
        List<List<String>> output = new List<List<String>>();
        for(FlowInput i:input){
            if (String.IsBlank(i.TextToSplit) || String.IsBlank(i.Separator)) continue;
            List<String> tempEmailList = i.TextToSplit.split(i.Separator, -1);
            System.debug(tempEmailList);
            output.add(tempEmailList);
        }
        return output;
    }
    
    public class FlowInput{
        @invocableVariable 
        public String TextToSplit;
        @invocableVariable 
        public String Separator;
    }
}