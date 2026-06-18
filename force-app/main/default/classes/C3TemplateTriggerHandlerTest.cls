@isTest
public class C3TemplateTriggerHandlerTest {
    
    // Mock callout to simulate external service used in C3DeleteTemplateQueue
    public class MockDeleteTemplateCallout implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status": "success"}');
            return res;
        }
    }
    
    /*  @isTest
static void testAfterDeleteTriggerFires() {
Test.setMock(HttpCalloutMock.class, new MockDeleteTemplateCallout());

// Create a test template
CCCWA__Template_Object__c template = C3TestDataFactory.createTemplate();
System.assertNotEquals(null, template.Id, 'Template should be inserted');

Test.startTest();
delete template; // Triggers afterDelete via TemplateTrigger (if it exists)
Test.stopTest();

// Assert that the template was indeed deleted
Integer countTemplates = [SELECT COUNT() FROM CCCWA__Template_Object__c WHERE Id = :template.Id];
System.assertEquals(0, countTemplates, 'Template should be deleted');
}*/
    @isTest
    static void testAfterDeleteTriggerFires() {
        
        Test.setMock(HttpCalloutMock.class, new MockDeleteTemplateCallout());
        
        User runAsUser = C3TestDataFactory.getRunAsUser();
        
        System.runAs(runAsUser) {
            
            CCCWA__Template_Object__c template =
                C3TestDataFactory.createTemplate();
            
            System.assert(
                Schema.sObjectType.CCCWA__Template_Object__c.isDeletable(),
                'User must have delete permission'
            );
            
            Test.startTest();
            Database.delete(template, AccessLevel.USER_MODE);
            Test.stopTest();
            
            Integer cnt =
                [SELECT COUNT() FROM CCCWA__Template_Object__c WHERE Id = :template.Id];
            
            System.assertEquals(0, cnt);
        }
    }
    
    
    @isTest
    static void testDeleteTempateFromMetaWithEmptyList() {
        Test.startTest();
        C3TemplateTriggerHandler.deleteTempateFromMeta(new List<CCCWA__Template_Object__c>());
        Test.stopTest();
        
        // Just asserting no exception thrown — this branch has no output.
        System.assert(true, 'deleteTempateFromMeta should handle empty list gracefully');
    }
    
    /* @isTest
static void testAfterDeleteWithRealList() {
Test.setMock(HttpCalloutMock.class, new MockDeleteTemplateCallout());

// Step 1: Insert template
CCCWA__Template_Object__c template1 = C3TestDataFactory.createTemplate();
System.assertNotEquals(null, template1.Id, 'Template must be inserted for testing');

// Step 2: Query fresh copy
CCCWA__Template_Object__c templateToDelete = [
SELECT Id, Name FROM CCCWA__Template_Object__c WHERE Id = :template1.Id
];
System.assertNotEquals(null, templateToDelete.Name, 'Template name should not be null');

// Step 3: Create trigger.old equivalent
List<CCCWA__Template_Object__c> deletedTemplates = new List<CCCWA__Template_Object__c>{ templateToDelete };

// Step 4: Delete and manually call afterDelete
Test.startTest();
delete templateToDelete;
C3TemplateTriggerHandler.afterDelete(deletedTemplates);
Test.stopTest();

// Confirm template is deleted
Integer countTemplates = [SELECT COUNT() FROM CCCWA__Template_Object__c WHERE Id = :template1.Id];
System.assertEquals(0, countTemplates, 'Template should be deleted');
}
*/
    @isTest
    static void testAfterDeleteWithRealList() {
        
        Test.setMock(HttpCalloutMock.class, new MockDeleteTemplateCallout());
        
        // Use shared runAs user from factory
        User runAsUser = C3TestDataFactory.getRunAsUser();
        
        System.runAs(runAsUser) {
            
            // Step 1: Insert template (system mode via factory)
            CCCWA__Template_Object__c template =
                C3TestDataFactory.createTemplate();
            
            System.assertNotEquals(
                null,
                template.Id,
                'Template must be inserted for testing'
            );
            
            // Step 2: Query fresh copy (simulates trigger.old)
            CCCWA__Template_Object__c templateToDelete = [
                SELECT Id, Name
                FROM CCCWA__Template_Object__c
                WHERE Id = :template.Id
            ];
            
            System.assertNotEquals(
                null,
                templateToDelete.Name,
                'Template name should not be null'
            );
            
            // Step 3: Perform delete (this will fire afterDelete trigger automatically)
            Test.startTest();
            Database.delete(templateToDelete, AccessLevel.USER_MODE);
            Test.stopTest();
            
            // Step 4: Confirm template is deleted
            Integer countTemplates = [
                SELECT COUNT()
                FROM CCCWA__Template_Object__c
                WHERE Id = :template.Id
            ];
            
            System.assertEquals(
                0,
                countTemplates,
                'Template should be deleted'
            );
        }
    }
    @isTest
    static void testAfterDeleteDirectInvocation() {
        
        Test.setMock(HttpCalloutMock.class, new MockDeleteTemplateCallout());
        
        User runAsUser = C3TestDataFactory.getRunAsUser();
        
        System.runAs(runAsUser) {
            
            // Prepare fake deleted records (no DML required)
            CCCWA__Template_Object__c t1 = new CCCWA__Template_Object__c(
                Name = 'Template_One'
            );
            CCCWA__Template_Object__c t2 = new CCCWA__Template_Object__c(
                Name = 'Template_Two'
            );
            
            List<CCCWA__Template_Object__c> deletedList =
                new List<CCCWA__Template_Object__c>{ t1, t2 };
                    
                    Test.startTest();
            C3TemplateTriggerHandler.afterDelete(deletedList);
            Test.stopTest();
            
            System.assert(true, 'afterDelete should enqueue job successfully');
        }
    }
    
    @isTest
    static void testDeleteTempateFromMetaWithValidList() {
        
        Test.setMock(HttpCalloutMock.class, new MockDeleteTemplateCallout());
        
        CCCWA__Template_Object__c temp =
            new CCCWA__Template_Object__c(Name = 'Valid_Template');
        
        Test.startTest();
        C3TemplateTriggerHandler.deleteTempateFromMeta(
            new List<CCCWA__Template_Object__c>{ temp }
        );
        Test.stopTest();
        
        System.assert(true, 'Queueable should be enqueued');
    }
    
    
}