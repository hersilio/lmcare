/**
 * @description       : This class is used to merge text fields in an EmailTemplate with the provided record Ids.
 * @author            : Felipe Gil
*/

public with sharing class SCH_EmailTemplateMerger {

    @InvocableMethod(label='Merge text fields in EmailTemplate' description='Called from a flow, receive an EmailTemplate and record Id to merge the fields')
    public static List<MergeEmailTemplateResp> getMergedText(List<MergeEmailTemplateReq> requests){
        
        List<MergeEmailTemplateResp> result = new List<MergeEmailTemplateResp>();

        for (MergeEmailTemplateReq req : requests) {
            if (req.emailTemplate == null) {
                MergeEmailTemplateResp resp = new MergeEmailTemplateResp();
                resp.mergedBody = '';
                resp.mergedSubject = '';
                result.add(resp);
                continue;
            }
            if (req.whatId == null) {
                MergeEmailTemplateResp resp = new MergeEmailTemplateResp();
                resp.mergedBody = req.emailTemplate.HtmlValue;
                resp.mergedSubject = req.emailTemplate.Subject;
                result.add(resp);
                continue;
            }

            List<Messaging.RenderEmailTemplateBodyResult> renderedEmailBodies = Messaging.renderEmailTemplate(req.whoId, req.whatId, new List<String>{req.emailTemplate.HtmlValue});
            List<Messaging.RenderEmailTemplateBodyResult> renderedEmailSubjects = Messaging.renderEmailTemplate(req.whoId, req.whatId, new List<String>{req.emailTemplate.Subject});

            if (renderedEmailBodies.size() != renderedEmailSubjects.size()){
                MergeEmailTemplateResp resp = new MergeEmailTemplateResp();
                resp.mergedBody = '';
                resp.mergedSubject = '';
                result.add(resp);
                continue;
            } 

            for (Integer i = 0; i < renderedEmailBodies.size(); i++) {
                MergeEmailTemplateResp resp = new MergeEmailTemplateResp();
                resp.mergedBody = renderedEmailBodies[i].getMergedBody();
                resp.mergedSubject = renderedEmailSubjects[i].getMergedBody();
                result.add(resp);
            }
        }
        return result;
    }

    public class MergeEmailTemplateReq{
        @InvocableVariable
        public EmailTemplate emailTemplate;

        @InvocableVariable
        public Id whoId;

        @InvocableVariable
        public Id whatId;
    }

    public class MergeEmailTemplateResp {
        @InvocableVariable
        public String mergedBody;

        @InvocableVariable
        public String mergedSubject;
    }   

}