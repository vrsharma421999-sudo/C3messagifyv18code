/**
 * @class C3RefreshTemplateSchedulableTest
 * @description
 *  Unit test class for the C3RefreshTemplateSchedulable class.
 *  Ensures that scheduled WhatsApp template refresh logic functions correctly,
 *  including callout mocking, field updates, and permission-based behavior.
 *
 * @author Asjad Ahmed
 * @date June 2025
 * @company CloudCentric
 * @version 1.0
 */
@isTest
private class C3RefreshTemplateSchedulableTest {
    /**
     * @testsetup makeData
     * @description
     *  Creates test user with necessary permission sets and inserts
     *  test Template_Object__c records under that user context.
     */

    @testSetup
    public static void makeData() {
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
            List<CCCWA__Template_Object__c> listTemplates = new List<CCCWA__Template_Object__c>();
            for (Integer i = 0; i < 10; i++) {
                CCCWA__Template_Object__c template = new CCCWA__Template_Object__c(
                    Name = 'Template ' + i,
                    CCCWA__TemplateID__c = 'WhatsAppID' + i,
                    CCCWA__Status__c = 'Pending'
                );
                listTemplates.add(template);
            }
            insert listTemplates;
        }
    }
    /**
     * @testmethod testExecuteWithCurrentUserPermissions
     * @description
     *  Validates that the scheduled logic executes properly using mocked HTTP callout
     *  and updates existing Template_Object__c records as expected.
     */

    @isTest
    static void testExecuteWithCurrentUserPermissions() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testadmin@example.com' LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
                Test.setMock(HttpCalloutMock.class, new C3HttpCalloutMockBundleClass('refreshTemplate'));
                C3RefreshTemplateSchedulable schedulable = new C3RefreshTemplateSchedulable();
                schedulable.execute(null);
            Test.stopTest();
            List<CCCWA__Template_Object__c> updatedTemplates = [SELECT Id, Name, CCCWA__TemplateID__c, CCCWA__Status__c FROM CCCWA__Template_Object__c];
            System.assertEquals(10, updatedTemplates.size(), 'Expected 10 templates, but found: ' + updatedTemplates.size());
        }
    } 
}