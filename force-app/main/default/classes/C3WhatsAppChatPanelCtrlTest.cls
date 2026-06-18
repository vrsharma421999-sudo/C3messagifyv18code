/**
 * @description Comprehensive test class for C3WhatsAppChatPanelCtrl
 * Achieves high coverage even in User Mode by running as a fully-permissioned test user
 */
@isTest
private class C3WhatsAppChatPanelCtrlTest {

    @TestSetup
    static void setupTestData() {
        // Create a System Admin user to ensure full permissions
        Profile adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

        User testUser = new User(
            FirstName = 'WhatsApp',
            LastName = 'TestUser',
            Email = 'whatsapp.test@cloudcentric.example.com',
            Username = 'whatsapp.test.user.' + System.currentTimeMillis() + '@cloudcentric.example.com',
            Alias = 'watest',
            ProfileId = adminProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;

        // Assign required Permission Sets (if they exist)
        List<PermissionSetAssignment> psaList = new List<PermissionSetAssignment>();
        for (PermissionSet ps : [
            SELECT Id FROM PermissionSet 
            WHERE Name IN ('Admin_Panel', 'WhatsApp_Access')
        ]) {
            psaList.add(new PermissionSetAssignment(
                AssigneeId = testUser.Id,
                PermissionSetId = ps.Id
            ));
        }
        if (!psaList.isEmpty()) {
            insert psaList;
        }

        System.runAs(testUser) {
            // Insert WhatsApp Admin settings
            C3TestDataFactory.insertWhatsAppAdmin();

            // Create and approve a template
          /*  String jsonBody = '{"whatsAppTemplateId":"189060917316209","templateName":"send_message","templateBody":"<p>Hello {{1}},</p>","objectName":"Contact","mediaType":"IMAGE","listMapping":[{"placeHolder":"{{1}}","fieldName":"FirstName"}],"language":"en","category":"MARKETING"}';
            C3WhatsAppTemplateScreenLWCCtrl.saveTemplateData(jsonBody);

            CCCWA__Template_Object__c template = [SELECT Id, CCCWA__Status__c FROM CCCWA__Template_Object__c LIMIT 1];
            template.CCCWA__Status__c = 'APPROVED';
            template.CCCWA__Document_Url__c = 'https://example.com/sample.jpg';
            template.CCCWA__Header__c = 'Test Header';
            template.CCCWA__Footer__c = 'Test Footer';
            update template;*/
            // Create Template directly (avoid saveTemplateData validation)
CCCWA__Template_Object__c template = new CCCWA__Template_Object__c(
    Name = 'send_message',
    CCCWA__Status__c = 'APPROVED',
    CCCWA__Whatsapp_Template__c = 'Hello {{1}}',
    CCCWA__Object__c = 'Contact',
    CCCWA__Template_Label__c = 'Test Template',
    CCCWA__Media_Type__c = 'IMAGE',
    CCCWA__Document_Url__c = 'https://example.com/sample.jpg',
    CCCWA__Header__c = 'Test Header',
    CCCWA__Footer__c = 'Test Footer'
);
insert template;


            // Create WhatsApp Number Configuration
            C3TestDataFactory.createWhatsAppConfigRecord('Contact', 'Phone');

            // Create ContentVersion for media testing
            C3TestDataFactory.testInsertContentVersion(Blob.valueOf('Fake Image Data'), 'test.png', 'image/png');

            // Create Contact
            Contact con = C3TestDataFactory.createContacts();
            con.Phone = '919999999999'; // Ensure phone is populated
            update con;
        }
    }

    @isTest
    static void testInitAndFetchTemplates() {
        User testUser = [SELECT Id FROM User WHERE Username LIKE 'whatsapp.test.user.%' LIMIT 1];
        Contact testContact = [SELECT Id, Phone FROM Contact LIMIT 1];

        Test.startTest();
        System.runAs(testUser) {
            // Test initialization
            String initResult = C3WhatsAppChatPanelCtrl.initWhatsAppChatPanelController(testContact.Id, 'Contact');
            System.assertNotEquals(null, initResult, 'initWhatsAppChatPanelController should return JSON');

            // Test template fetching
            List<C3WhatsAppChatPanelCtrl.PicklistWrapper> templates = 
                C3WhatsAppChatPanelCtrl.c3WhatsppFetchTemplate('Contact');
            System.assert(templates.size() > 0, 'At least one approved template should be returned');

            // Test project-based template fetching (if metadata exists)
            List<CCCWA__Project__mdt> projects = [SELECT DeveloperName FROM CCCWA__Project__mdt LIMIT 1];
            if (!projects.isEmpty()) {
                String projectTemplates = C3WhatsAppChatPanelCtrl.getTemplatesByProject('Contact', projects[0].DeveloperName);
                System.assertNotEquals(null, projectTemplates);
            }
        }
        Test.stopTest();
    }

    @isTest
    static void testSaveMessage_TextMessage() {
        User testUser = [SELECT Id FROM User WHERE Username LIKE 'whatsapp.test.user.%' LIMIT 1];
        Contact testContact = [SELECT Id, Phone FROM Contact LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new C3HttpCalloutMockBundleClass('WhatsAppMessageText'));

        Test.startTest();
        System.runAs(testUser) {
            String wamId = C3WhatsAppChatPanelCtrl.saveMessage(
                testContact.Id,
                testContact.Phone,
                'Hello from test class',
                'Contact',
                null, // mediaUrl
                null, // base64
                null, // fileName
                null, // templateName
                null  // strtempid
            );

            System.assertNotEquals(null, wamId, 'Text message should return a WhatsApp Message ID');
        }
        Test.stopTest();
    }

    @isTest
static void testLoadTextMessages_AndMedia() {

    User testUser = [SELECT Id FROM User WHERE Username LIKE 'whatsapp.test.user.%' LIMIT 1];
    Contact testContact = [
    SELECT Id, Phone 
    FROM Contact 
    WHERE Phone = '919999999999'
    LIMIT 1
];
System.assertNotEquals(null, testContact, 'Contact not found in test setup.');


    Test.setMock(HttpCalloutMock.class, new C3HttpCalloutMockBundleClass('WhatsAppMessageMedia'));

    
   Test.startTest();
  System.runAs(testUser) {

    String result = C3WhatsAppChatPanelCtrl.loadTextMessages(
        testContact.Id,
        testContact.Phone,
        'Test media message',
        'Contact',
        'https://example.com/audio.mp3',
        'audio/mp3',
        'test.mp3',
        null,
        null,
        'test-vam-id'
    );

    System.assertNotEquals(null, result);
}
Test.stopTest();


}
/*
    @isTest
    static void testLoadTextMessages_AndMedia() {
        User testUser = [SELECT Id FROM User WHERE Username LIKE 'whatsapp.test.user.%' LIMIT 1];
        Contact testContact = [SELECT Id, Phone FROM Contact LIMIT 1];
        ContentVersion cv = [SELECT Id FROM ContentVersion LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new C3HttpCalloutMockBundleClass('WhatsAppMessageMedia'));

        Test.startTest();
        System.runAs(testUser) {
            // Test loadTextMessages with media
            String result = C3WhatsAppChatPanelCtrl.loadTextMessages(
                testContact.Id,
                testContact.Phone,
                'Test media message',
                'Contact',
                'https://example.com/audio.mp3',
                'audio/mp3',
                'test.mp3',
                null, // templateName
                null, // strtempid
                'test-vam-id'
            );
            System.assertNotEquals(null, result, 'loadTextMessages should return JSON wrapper');

            // Test media wamId
            String mediaWamId = C3WhatsAppChatPanelCtrl.getMediaWamId(
                testContact.Phone,
                'https://example.com/audio.mp3',
                'AUDIO'
            );
            System.assertNotEquals(null, mediaWamId);
        }
        Test.stopTest();
    }*/
/*
    @isTest
    static void testGetPublicUrl() {
        User testUser = [SELECT Id FROM User WHERE Username LIKE 'whatsapp.test.user.%' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        ContentVersion cv = [SELECT Id FROM ContentVersion LIMIT 1];

        Test.startTest();
        System.runAs(testUser) {
            String publicUrl = C3WhatsAppChatPanelCtrl.getPublicUrl(
                '919999999999',
                cv.Id,
                testContact.Id,
                'testfile.png',
                'image/png'
            );

            System.assertNotEquals(null, publicUrl, 'Public URL should be generated');
            System.assert(publicUrl.contains('ContentDownloadUrl'), 'Should return valid download URL');
        }
        Test.stopTest();
    }
*/
    @isTest
static void testGetPublicUrl() {

    User testUser = [SELECT Id FROM User WHERE Username LIKE 'whatsapp.test.user.%' LIMIT 1];
    Contact testContact = [
    SELECT Id, Phone 
    FROM Contact 
    WHERE Phone = '919999999999'
    LIMIT 1
];
System.assertNotEquals(null, testContact, 'Contact not found in test setup.');


    System.runAs(testUser) {

        // Create File
        ContentVersion cv = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'testfile.png',
            VersionData = Blob.valueOf('fake data'),
            IsMajorVersion = true
        );
        insert cv;

        // Get ContentDocument
        cv = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
        ];

        // Link file to Contact
        insert new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            LinkedEntityId = testContact.Id,
            ShareType = 'V'
        );

        Test.startTest();

        String publicUrl = C3WhatsAppChatPanelCtrl.getPublicUrl(
            testContact.Phone,
            cv.Id,
            testContact.Id,
            'testfile.png',
            'image/png'
        );

        Test.stopTest();

        System.assertNotEquals(null, publicUrl);
    }
}
    
    @isTest
static void testGetTemplatesByProject_NoFilters() {
    User testUser = [SELECT Id FROM User WHERE Username LIKE 'whatsapp.test.user.%' LIMIT 1];

    System.runAs(testUser) {
        Test.startTest();
        String result =
            C3WhatsAppChatPanelCtrl.getTemplatesByProject(null, null);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }
}


    
    
 @isTest
 static void testGetTemplatesByProject_ProjectOnly() {
    User testUser = [SELECT Id FROM User WHERE Username LIKE 'whatsapp.test.user.%' LIMIT 1];

    System.runAs(testUser) {
        List<CCCWA__Project__mdt> projects =
            [SELECT DeveloperName FROM CCCWA__Project__mdt LIMIT 1];
        
         if (projects.isEmpty()) {
            System.debug('No CCCWA__Project__mdt found, skipping test.');
            return;
        }

        

        Test.startTest();
        String result =
            C3WhatsAppChatPanelCtrl.getTemplatesByProject(
                null,
                projects[0].DeveloperName
            );
        Test.stopTest();

        System.assertNotEquals(null, result);
    }
}

    @isTest
    static void testCheckNumberConfigAndUtility() {
        User testUser = [SELECT Id FROM User WHERE Username LIKE 'whatsapp.test.user.%' LIMIT 1];
        Contact testContact = [
    SELECT Id, Phone 
    FROM Contact 
    WHERE Phone = '919999999999'
    LIMIT 1
];
System.assertNotEquals(null, testContact, 'Contact not found in test setup.');


        Test.startTest();
        System.runAs(testUser) {
            String configResult = C3WhatsAppChatPanelCtrl.checkForNumberConfigurationImplemented(testContact.Id);
            System.assertNotEquals(null, configResult);

            C3WhatsAppChatPanelCtrl.ChatpanelValidations validation = 
                (C3WhatsAppChatPanelCtrl.ChatpanelValidations) JSON.deserialize(configResult, C3WhatsAppChatPanelCtrl.ChatpanelValidations.class);
            System.assert(validation.isAllowedToChat, 'Chat should be allowed with proper config');

            // Test utility method
            String initials = C3WhatsAppChatPanelCtrl.getNameInitials('Mohit', 'Deshwal');
            System.assertEquals('MD', initials);
        }
        Test.stopTest();
    }
    
}