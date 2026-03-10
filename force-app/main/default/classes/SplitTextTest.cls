@isTest
public class SplitTextTest {
    @isTest
    public static void testSplit(){
        LM_SplitText.FlowInput i1 = new LM_SplitText.FlowInput();
        
        i1.TextToSplit = '123,456,789';
        i1.Separator = ',';
       
        List<List<String>> expectedOutput = new List<List<String>>{
            new List<String>{'123', '456', '789'}
        };
        
        List<LM_SplitText.FlowInput> inputs = new List<LM_SplitText.FlowInput>{i1};
        System.AssertEquals(expectedOutput, LM_SplitText.splitString(inputs));
    }
}