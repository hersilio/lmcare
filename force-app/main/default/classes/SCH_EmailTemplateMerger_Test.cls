@isTest
public class SCH_EmailTemplateMerger_Test {

    @testSetup
    static void setupTestData() {
        // Create a Contact and an Account for merge fields
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = acc.Id, Email = 'test@example.com');
        insert con;

    }

    @isTest
    static void testGetMergedTextWithValidTemplateAndIds() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        EmailTemplate et = new EmailTemplate(
            Name = 'TestTemplate',
            DeveloperName = 'TestTemplate',
            TemplateType = 'custom',
            HtmlValue = 'Hello {!Contact.FirstName}, your account is {!Account.Name}.',
            Subject = 'Welcome {!Contact.FirstName}',
            FolderId = UserInfo.getUserId(),
            IsActive = true
        );

        SCH_EmailTemplateMerger.MergeEmailTemplateReq req = new SCH_EmailTemplateMerger.MergeEmailTemplateReq();
        req.emailTemplate = et;
        req.whoId = con.Id;
        req.whatId = acc.Id;

        List<SCH_EmailTemplateMerger.MergeEmailTemplateResp> respList = SCH_EmailTemplateMerger.getMergedText(new List<SCH_EmailTemplateMerger.MergeEmailTemplateReq>{req});
        System.assertEquals(1, respList.size());
        System.assert(respList[0].mergedBody.contains('Hello Test'), 'Merged body should contain Contact FirstName');
        System.assert(respList[0].mergedBody.contains('your account is Test Account'), 'Merged body should contain Account Name');
        System.assert(respList[0].mergedSubject.contains('Welcome Test'), 'Merged subject should contain Contact FirstName');
    }

    @isTest
    static void testGetMergedTextWithNullTemplate() {
        SCH_EmailTemplateMerger.MergeEmailTemplateReq req = new SCH_EmailTemplateMerger.MergeEmailTemplateReq();
        req.emailTemplate = null;
        req.whoId = null;
        req.whatId = null;

        List<SCH_EmailTemplateMerger.MergeEmailTemplateResp> respList = SCH_EmailTemplateMerger.getMergedText(new List<SCH_EmailTemplateMerger.MergeEmailTemplateReq>{req});
        System.assertEquals(1, respList.size());
        System.assertEquals('', respList[0].mergedBody);
        System.assertEquals('', respList[0].mergedSubject);
    }

    @isTest
    static void testGetMergedTextWithNullWhatId() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        EmailTemplate et = new EmailTemplate(
            Name = 'TestTemplate',
            DeveloperName = 'TestTemplate',
            TemplateType = 'custom',
            HtmlValue = 'Hello {!Contact.FirstName}, your account is {!Account.Name}.',
            Subject = 'Welcome {!Contact.FirstName}',
            FolderId = UserInfo.getUserId(),
            IsActive = true
        );


        SCH_EmailTemplateMerger.MergeEmailTemplateReq req = new SCH_EmailTemplateMerger.MergeEmailTemplateReq();
        req.emailTemplate = et;
        req.whoId = con.Id;
        req.whatId = null;

        List<SCH_EmailTemplateMerger.MergeEmailTemplateResp> respList = SCH_EmailTemplateMerger.getMergedText(new List<SCH_EmailTemplateMerger.MergeEmailTemplateReq>{req});
        System.assertEquals(1, respList.size());
        System.assertEquals(et.HtmlValue, respList[0].mergedBody);
        System.assertEquals(et.Subject, respList[0].mergedSubject);
    }

    @isTest
    static void testGetMergedTextWithEmptyRequests() {
        List<SCH_EmailTemplateMerger.MergeEmailTemplateResp> respList = SCH_EmailTemplateMerger.getMergedText(new List<SCH_EmailTemplateMerger.MergeEmailTemplateReq>());
        System.assertEquals(0, respList.size());
    }
}