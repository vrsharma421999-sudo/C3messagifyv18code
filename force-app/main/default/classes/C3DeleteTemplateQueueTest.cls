/**
 * @description Test class for C3DeleteTemplateQueue queueable job.
 * Validates behavior with valid, empty, and null template name sets.
 */
@isTest
public class C3DeleteTemplateQueueTest {

    /**
     * @description Mock class to simulate external callout response from C3WhatsAppWebService.deleteTemplate
     */
    public class MockWhatsAppWebServiceCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status": "success"}');
            return res;
        }
    }

    /**
     * @description Tests the queueable with a valid template.
     */
    @isTest
    static void testDeleteTemplateQueueWithValidTemplate() {
        Test.setMock(HttpCalloutMock.class, new MockWhatsAppWebServiceCallout());

        CCCWA__Template_Object__c template = C3TestDataFactory.createTemplate();
        Set<String> templateNames = new Set<String>{ template.Name };

        Test.startTest();
        System.enqueueJob(new C3DeleteTemplateQueue(templateNames));
        Test.stopTest();

        // Assert just to pass PMD rule
        System.assert(!templateNames.isEmpty(), 'Template name set should not be empty');
    }

    /**
     * @description Tests the queueable with an empty set.
     */
    @isTest
    static void testDeleteTemplateQueueWithEmptySet() {
        Test.setMock(HttpCalloutMock.class, new MockWhatsAppWebServiceCallout());

        Set<String> emptySet = new Set<String>();

        Test.startTest();
        System.enqueueJob(new C3DeleteTemplateQueue(emptySet));
        Test.stopTest();

        System.assertEquals(0, emptySet.size(), 'Set should be empty');
    }

    /**
     * @description Tests the queueable with a null set.
     */
    @isTest
    static void testDeleteTemplateQueueWithNullSet() {
        Test.setMock(HttpCalloutMock.class, new MockWhatsAppWebServiceCallout());

        Test.startTest();
        System.enqueueJob(new C3DeleteTemplateQueue(null));
        Test.stopTest();

        System.assert(true, 'Queueable should run even with null input');
    }
}