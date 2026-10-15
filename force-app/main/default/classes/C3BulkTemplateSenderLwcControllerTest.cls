/**
 * @name C3BulkTemplateSenderLwcControllerTest
 * @description Test class for validating the C3BulkTemplateSenderLwcController Apex methods.
 *              This includes testing template fetching, WhatsApp configuration, and record retrieval logic.
 *
 * @author Asjad Ahmed
 * @version 1.0
 * @company CloudCentric
 * @license Salesforce Public License (https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_license.htm)
 * @date June 2025
 */
@IsTest
public class C3BulkTemplateSenderLwcControllerTest {
    @TestSetup
       /**
     * @description Test setup method that creates test data including a User with permission sets,
     *              WhatsApp configuration, a Template, and test Account and Contacts.
     *              Runs as the inserted test user to simulate real user context.
     */
    public static void makeData(){
        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'Admin',
            Email = 'testadmin@example.com',
             Username = 'testadmin@example.com' + System.currentTimeMillis(), // Ensure unique username
            Alias = 'tadmin',
            ProfileId = sysAdminProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        // Assign Permission Sets
        List<PermissionSetAssignment> psAssignments = new List<PermissionSetAssignment>();
        map<String, string> mapPerSetNameWithId = new map<String, string>();
        for(PermissionSet objPerSet : [SELECT Id,Name FROM PermissionSet WHERE Name ='Admin_Panel' OR Name ='WhatsApp_Access']){
            mapPerSetNameWithId.put(objPerSet.Name,objPerSet.Id);
        }
        for (String permSetName : new List<String>{'Admin_Panel', 'WhatsApp_Access'}) {
            if(mapPerSetNameWithId.containskey(permSetName) && mapPerSetNameWithId.get(permSetName) != null){
                psAssignments.add(new PermissionSetAssignment(
                    AssigneeId = testUser.Id,
                    PermissionSetId = mapPerSetNameWithId.get(permSetName)
                ));
            }
        }
        insert psAssignments;

        System.runAs(testUser) {
            C3TestDataFactory.createTemplate();
            C3TestDataFactory.createWhatsAppConfigRecord('Contact', 'Phone');
            C3TestDataFactory.insertWhatsAppAdmin();
            Account objAcc = C3TestDataFactory.createAccount();
            INSERT objAcc;
            INSERT C3TestDataFactory.createContacts(2, objAcc.Id);
        }
    }
    /**
     * @description Validates controller methods including object fetch, config validation,
     *              and record retrieval for the 'Contact' object.
     */

    @IsTest
    public static void testMethod1(){
        User testUser = [SELECT Id FROM User WHERE Email = 'testadmin@example.com' LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
                C3BulkTemplateSenderLwcController.getObjectsfromNumberConfig();
                C3BulkTemplateSenderLwcController.validateObject('Contact');
                C3BulkTemplateSenderLwcController.getFilterableFields('Contact');
                List<Map<String, Object>> jsonMap =  C3BulkTemplateSenderLwcController.fetchObjectRecords('Contact', '', '');
                System.assertNotEquals(null, jsonMap, 'jsonMap should not be null');
            Test.stopTest();
        }
    }

    /**
     * @description Validates record retrieval when a where clause filter and order by are provided.
     */
    @IsTest
    public static void testFetchObjectRecordsWithFilter() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testadmin@example.com' LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
                List<Map<String, Object>> records = C3BulkTemplateSenderLwcController.fetchObjectRecords('Contact', 'LastName != null', 'LastName ASC');
                System.assertNotEquals(null, records, 'Records should not be null');
                System.assert(records.size() > 0, 'Should return contacts');
            Test.stopTest();
        }
    }

    /**
     * @description Validates that when a filter matches zero records, an AuraHandledException
     *              with a clean custom error message is thrown instead of a null exception.
     */
    @IsTest
    public static void testFetchObjectRecordsNoRecordsFoundException() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testadmin@example.com' LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
                try {
                    C3BulkTemplateSenderLwcController.fetchObjectRecords('Contact', 'LastName = \'NonExistentSurnameXYZ\'', '');
                    System.assert(false, 'Expected AuraHandledException was not thrown');
                } catch (AuraHandledException e) {
                    System.assert(e.getMessage().contains('No records found matching the filter criteria'), 'Expected custom error message, got: ' + e.getMessage());
                }
            Test.stopTest();
        }
    }

    /**
     * @description Validates that passing an invalid object name throws an AuraHandledException.
     */
    @IsTest
    public static void testFetchObjectRecordsInvalidObject() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testadmin@example.com' LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
                try {
                    C3BulkTemplateSenderLwcController.fetchObjectRecords('NonExistentObjectXYZ__c', '', '');
                    System.assert(false, 'Expected AuraHandledException was not thrown');
                } catch (AuraHandledException e) {
                    System.assert(e.getMessage().contains('Invalid object name'), 'Expected invalid object error message, got: ' + e.getMessage());
                }
            Test.stopTest();
        }
    }

    /**
     * @description Validates that an unconfigured object throws an AuraHandledException.
     */
    @IsTest
    public static void testValidateObjectMissingConfig() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testadmin@example.com' LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
                try {
                    C3BulkTemplateSenderLwcController.validateObject('Lead');
                    System.assert(false, 'Expected AuraHandledException was not thrown');
                } catch (AuraHandledException e) {
                    System.assert(e.getMessage().contains('WhatsApp Number configuration is missing'), 'Expected missing config message, got: ' + e.getMessage());
                }
            Test.stopTest();
        }
    }
}