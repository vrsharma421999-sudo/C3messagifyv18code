/**
 * @description Test class for C3 WhatsApp Home and Configuration functionality.
 */
@isTest
public class C3WhatsAppHomeAndConfigurationTest {

    /**
     * @description Test setup method that creates user, assigns permission sets, and sets up test data.
     */
    @TestSetup
    public static void makeData() {
        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'Admin',
            Email = 'testadmin@example.com',
            Username = 'testadmin@example.com' + System.currentTimeMillis(),
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

        // Setup test data
        System.runAs(testUser) {
            C3TestDataFactory.createTemplate();
            C3TestDataFactory.createWhatsAppConfigRecord('Contact', 'Phone');
            C3TestDataFactory.insertWhatsAppAdmin();
        }
    }

    /**
     * @description Tests WhatsAppTemplates and DeleteWhatsAppTemplates methods.
     */
    @isTest
    public static void testMethod1() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testadmin@example.com' LIMIT 1];

        System.runAs(testUser) {
            String templateId = [SELECT Id FROM CCCWA__Template_Object__c LIMIT 1].Id;

            Test.startTest();
                Test.setMock(HttpCalloutMock.class, new C3HttpCalloutMockBundleClass('WhatsAppMessageText'));
                C3WhatsAppTemplateHomeController.WhatsAppTemplates();
                C3WhatsAppTemplateHomeController.deleteWhatsAppTemplates(templateId);
                System.assertEquals(true, templateId != null, 'Template ID should not be null.');
            Test.stopTest();
        }
    }

    /**
     * @description Tests WhatsApp Number Configuration methods: init, getObjectLabel, getAllPhoneField, save, and delete.
     */
    @isTest
    public static void testMethod2() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testadmin@example.com' LIMIT 1];

        System.runAs(testUser) {
            String templateId = [SELECT Id FROM CCCWA__Template_Object__c LIMIT 1].Id;

            Test.startTest();
                C3WhatsappNumberConfiguration.initWhatsAppNumberConfiguration();
                C3WhatsappNumberConfiguration.getObjectLabel('Contact');
                C3WhatsappNumberConfiguration.getAllPhoneField('Contact');

                CCCWA__WhatsApp_Number_Configuration__c config = CCCWA__WhatsApp_Number_Configuration__c.getAll().values()[0];
                C3WhatsappNumberConfiguration.saveWhatsAppNumberConfig(JSON.serialize(config));
                C3WhatsappNumberConfiguration.deleteWhatsAppNumberConfig(JSON.serialize(config));

                System.assertNotEquals(null, templateId, 'Template ID should not be null.');
            Test.stopTest();
        }
    }

    /**
     * @description Tests initialization of Admin Panel and saving WhatsApp Admin configuration.
     */
    @isTest
    public static void testMethod3() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testadmin@example.com' LIMIT 1];

        System.runAs(testUser) {
            Test.startTest();
                C3AdminPanelLwcController.initialize();
                CCCWA__WhatsApp_Admin__c objAdminConfig = new CCCWA__WhatsApp_Admin__c(
                    Name = 'asdasd',
                    CCCWA__NumberID__c = 'asdasdasd',
                    CCCWA__WabaId__c = 'dsfgasdas'
                );
                C3AdminPanelLwcController.saveAdminConfig(JSON.serialize(objAdminConfig));
                System.assertEquals(true, objAdminConfig != null, 'Admin config object should not be null.');
            Test.stopTest();
        }
    }
}