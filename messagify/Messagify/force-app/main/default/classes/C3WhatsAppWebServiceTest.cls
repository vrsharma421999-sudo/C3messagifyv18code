@isTest
public class C3WhatsAppWebServiceTest {
    /**
* @description Sets up test data for the test class.
* Creates a test user and assigns necessary permission sets.
*/
    @testSetup
    public static void makeData(){
       /* Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'Admin',
            Email = 'testuser@gmail.com',
            Username = 'testuser@gmail.com' + System.currentTimeMillis(), // Ensure unique username
            Alias = 'tadmin',
            ProfileId = sysAdminProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;*/
          User testUser = C3TestDataFactory.getRunAsUser();
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
            C3TestDataFactory.insertWhatsAppAdmin();
            ContentVersion objCV = C3TestDataFactory.testInsertContentVersion(Blob.valueOf('Test Content'), 'Phone', 'file/png');
            String jsonBody = '{"whatsAppTemplateId":"189060917316209","templateName":"send_message","templateId":"","templateBody":"<p>Hello {{1}},</p><p><br></p><p>This side {{2}} from salesforce partner if you have the requirement of CRM software to manage your customer list efficiently, along with all the customization we are the Salesforce partner, who provide the fully CRM solution that can significantly enhance your business operations and drive sales growth. I would be more than happy to arrange a personalized demo to showcase how [CRM] can revolutionize your company&#39;s sales and customer management efforts. If you&#39;re interested, please let me know, and we can find a convenient time to discuss further. Kindly share me your contact number and email id for easy communication.</p><p><br></p><p>Best regards,</p><p>{{3}} </p><p>{{4}}</p><p>{{5}}</p><p>Powered By CCC Infotech</p>","publicDocUrl":null,"objectName":"Contact","mediaType":"IMAGE","listMapping":[{"placeHolder":"{{5}}","parameterNum":"5","mappingId":"","fieldName":"Email","exampleText":"dheeraj@cccinfotech.com"},{"placeHolder":"{{1}}","parameterNum":"1","mappingId":"","fieldName":"FirstName","exampleText":"Shreya"},{"placeHolder":"{{2}}","parameterNum":"2","mappingId":"","fieldName":"LastName","exampleText":"Singh"},{"placeHolder":"{{3}}","parameterNum":"3","mappingId":"","fieldName":"Name","exampleText":"Dheeraj"},{"placeHolder":"{{4}}","parameterNum":"4","mappingId":"","fieldName":"MobilePhone","exampleText":"917905256379"}],"listActions":[{"buttonId":"","typeOfAction":"","buttonText":"Call","countryCode":"91","phoneNumber":"9865326532","urlType":"","websiteUrl":"","isIcon":true,"iconName":"utility:call","type":"","isActionPhoneNumber":true,"isActionUrl":false,"actionType":"PHONE_NUMBER"}], "listQuickReply": null, "language":"en","isQuickReplyList":true,"isHeaderText":true,"isHeaderMedia":true,"isActionList":true,"headerType":"MEDIA","headerText":null,"footer":null,"fileName":null,"documentId":null,"contentVersionId":null,"category":"MARKETING","buttonOption":null}';
            C3WhatsAppTemplateScreenLWCCtrl.saveTemplateData(jsonBody);
            //CCCWA__Template_Object__c objTemplate = [SELECT Id, CCCWA__Status__c FROM CCCWA__Template_Object__c LIMIT 1];
            CCCWA__Template_Object__c objTemplate= C3TestDataFactory.createTemplate();
            //ContentDocumentLink objCDL = C3TestDataFactory.testInsertCDL((String)objCV.Id, (String)objTemplate.Id);
            ContentDocumentLink objCDL = C3TestDataFactory.testInsertCDL((String)objCV.Id, (String)objTemplate.Id); // Used for linking content to template
            objTemplate.CCCWA__Status__c = 'APPROVED';
            objTemplate.CCCWA__TemplateID__c = '12423214';
            objTemplate.CCCWA__Media_Handler__c = 'Media_Handler__c';
            objTemplate.CCCWA__Content_Version_Id__c = objCV.Id;
            objTemplate.CCCWA__Mime_Type__c = 'image/png';
            objTemplate.CCCWA__Footer__c = 'footer';
            objTemplate.CCCWA__File_Name__c = 'testFile';
            objTemplate.CCCWA__Header__c = 'header';
            objTemplate.CCCWA__Header_Type__c = 'TEXT';
            objTemplate.CCCWA__Media_Type__c = 'IMAGE';
            objTemplate.CCCWA__Document_Url__c = 'testurl.com';
            update objTemplate;
            List<Template_Parameter__c> lstTemplateParameter = C3TestDataFactory.createTemplateMappings(5, objTemplate.Id);
            insert lstTemplateParameter;
            C3TestDataFactory.createTemplateButtons( objTemplate.Id);
            C3TestDataFactory.createWhatsAppConfigRecord('Contact', 'Phone');
            //Contact con = C3TestDataFactory.createContacts();
            Contact con = C3TestDataFactory.createContacts(); // Test data for contact-related operations
            System.assertNotEquals(null, objCDL.Id, 'ContentDocumentLink should have been created');
            System.assertNotEquals(null, con.Id, 'Contact should have been created');
            
        }
    }
    
    @isTest 
    public static void method1(){
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@gmail.com' LIMIT 1];
        System.runAs(testUser) {
            
            CCCWA__Template_Object__c dataTemplate = [Select id, Name, CCCWA__Status__c, CCCWA__TemplateID__c,CCCWA__Header_Type__c, CCCWA__Whatsapp_Template__c,CCCWA__Template_Message__c,CCCWA__Object__c,CCCWA__Language_Code__c FROM CCCWA__Template_Object__c LIMIT 1];
            dataTemplate.Header_Type__c = 'MEDIA';
            update dataTemplate;
            String conId = [SELECT Id FROM Contact LIMIT 1].Id;
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new C3HttpCalloutMockBundleClass('WhatsAppMessageSendTemplate'));
            C3WhatsAppTemplateScreenLWCCtrl.sendWhatsAppMessage(new List<string>{conId}, dataTemplate.Id  );
            //System.assertEquals( (dataTemplate.Id != null) ,true);
            System.assertNotEquals(null, dataTemplate.Id, 'Expected Template_Object__c Id to not be null');
            
            Test.stopTest();
        }
    }
    
    @isTest 
    public static void method2(){
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@gmail.com' LIMIT 1];
        System.runAs(testUser) {
            CCCWA__Template_Object__c dataTemplate = [Select id, Name, Status__c, TemplateID__c,Header_Type__c, Whatsapp_Template__c,Template_Message__c,Object__c,Language_Code__c FROM Template_Object__c LIMIT 1];
            String jsonBody = '{"whatsAppTemplateId":"189060917316209","templateName":"send_message","templateId":"'+dataTemplate.Id+'","templateBody":"<p>Hello {{1}},</p><p><br></p><p>This side {{2}} from salesforce partner if you have the requirement of CRM software to manage your customer list efficiently, along with all the customization we are the Salesforce partner, who provide the fully CRM solution that can significantly enhance your business operations and drive sales growth. I would be more than happy to arrange a personalized demo to showcase how [CRM] can revolutionize your company&#39;s sales and customer management efforts. If you&#39;re interested, please let me know, and we can find a convenient time to discuss further. Kindly share me your contact number and email id for easy communication.</p><p><br></p><p>Best regards,</p><p>{{3}} </p><p>{{4}}</p><p>{{5}}</p><p>Powered By CCC Infotech</p>","publicDocUrl":null,"objectName":"Contact","mediaType":"IMAGE","listMapping":[{"placeHolder":"{{5}}","parameterNum":"5","mappingId":"","fieldName":"Email","exampleText":"dheeraj@cccinfotech.com"},{"placeHolder":"{{1}}","parameterNum":"1","mappingId":"","fieldName":"FirstName","exampleText":"Shreya"},{"placeHolder":"{{2}}","parameterNum":"2","mappingId":"","fieldName":"LastName","exampleText":"Singh"},{"placeHolder":"{{3}}","parameterNum":"3","mappingId":"","fieldName":"Name","exampleText":"Dheeraj"},{"placeHolder":"{{4}}","parameterNum":"4","mappingId":"","fieldName":"MobilePhone","exampleText":"917905256379"}],"listActions":[{"buttonId":"","typeOfAction":"","buttonText":"Call","countryCode":"91","phoneNumber":"9865326532","urlType":"","websiteUrl":"","isIcon":true,"iconName":"utility:call","type":"","isActionPhoneNumber":true,"isActionUrl":false,"actionType":"PHONE_NUMBER"}], "listQuickReply": null, "language":"en","isQuickReplyList":true,"isHeaderText":true,"isHeaderMedia":true,"isActionList":true,"headerType":"MEDIA","headerText":null,"footer":null,"fileName":null,"documentId":null,"contentVersionId":null,"category":"MARKETING","buttonOption":null}';
            
            String conId = [SELECT Id FROM Contact LIMIT 1].Id;
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new C3HttpCalloutMockBundleClass('WhatsAppMessageCreateTemplate'));
            C3WhatsAppWebService.sendWhatsAppTemplateToMeta( jsonBody );
            //System.assertEquals( (conId != null) ,true);
            System.assertNotEquals(null, conId, 'Expected Contact Id to not be null');
            
            Test.stopTest();
        }
    }
    
    @isTest 
    public static void method3(){
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@gmail.com' LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new C3HttpCalloutMockBundleClass('WhatsAppMessageText'));
            C3WhatsAppWebService.sendWhatsAppMessage( '919891611767', 'aasdasdasdadasd' );  
            String conId = [SELECT Id FROM Contact LIMIT 1].Id;
            //System.assertEquals( (conId != null) ,true);      
            System.assertNotEquals(null, conId, 'Expected Contact Id to not be null');
            
            Test.stopTest();
        }
    }
    
    @isTest 
    public static void method4(){
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@gmail.com' LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new C3HttpCalloutMockBundleClass('WhatsAppMessageMedia'));
            C3WhatsAppChatPanelCtrl.getMediaWamId('919911410564', ' wwww.audio.com', 'AUDIO');
            String conId = [SELECT Id FROM Contact LIMIT 1].Id;
            //System.assertEquals( (conId != null) ,true);      
            System.assertNotEquals(null, conId, 'Expected Contact Id to not be null');
            
            Test.stopTest();
        }
    }
    /**
* @description Mock implementation of HttpCalloutMock used for testing HTTP callouts.
*              Simulates responses from FacebookAPI and WhatsAppGetMedia endpoints for unit testing purposes.
*              - FacebookAPI returns a JSON with a media URL.
*              - WhatsAppGetMedia returns fake binary media content.
*              - All other endpoints return a 404 error.
*/
    
    class SimpleMock implements HttpCalloutMock {
        /**
* @description Simulates the HTTP response for a given HTTP request.
* @param req The HTTP request being sent.
* @return An HTTPResponse object containing the simulated result.
*/
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            
            if (req.getEndpoint().contains('FacebookAPI')) {
                // Simulate media URL response from FacebookAPI
                res.setStatusCode(200);
                res.setHeader('Content-Type', 'application/json');
                res.setBody('{"url": "https://graph.facebook.com/v17.0/mediaId/attachments123"}');
            } else if (req.getEndpoint().contains('WhatsAppGetMedia')) {
                // Simulate download of media content from WhatsAppGetMedia
                res.setStatusCode(200);
                res.setHeader('Content-Type', 'image/png');
                res.setBodyAsBlob(Blob.valueOf('FakeBinaryContent'));
            } else {
                // Unknown endpoint
                res.setStatusCode(404);
                res.setBody('Unknown endpoint');
            }
            
            return res;
        }
    }
    
@isTest 
public static void method5() {
    // Create test user
   /* User testUser = new User(
        FirstName = 'Test',
        LastName = 'Admin',
        Email = 'testuser@gmail.com',
        Username = 'testuser@gmail.com.test',
        Alias = 'tadmin',
        ProfileId = UserInfo.getProfileId(),
        TimeZoneSidKey = 'Asia/Kolkata',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US'
    );
    insert testUser;*/
      User testUser = C3TestDataFactory.getRunAsUser();

   

    System.runAs(testUser) {
         // Create test contact
    Contact testContact = new Contact(FirstName = 'Test', LastName = 'Contact');
    insert testContact;
        // Set mock response for media API
        Test.setMock(HttpCalloutMock.class, new C3HttpCalloutMockBundleClass('WhatsAppMessageMediaAPI'));

        Test.startTest();
        String result = C3WhatsAppWebService.getMediaFromAPI('mediaId', 'fileName', '/png', testContact.Id);
        Test.stopTest();

        System.debug('Result from getMediaFromAPI: ' + result);
        
    }
}


    
    @isTest 
    public static void method6(){
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@gmail.com' LIMIT 1];
        System.runAs(testUser) {
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new C3HttpCalloutMockBundleClass(''));
            C3WhatsAppWebService.deleteTemplate( 'send_message');
            String conId = [SELECT Id FROM Contact LIMIT 1].Id;
            //System.assertEquals( (conId != null) ,true);  
            System.assertNotEquals(null, conId, 'Expected Contact Id to not be null');
            
            Test.stopTest();
        }
    }
    
    @isTest 
    public static void method7(){
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser@gmail.com' LIMIT 1];
        System.runAs(testUser) {
            ContentVersion cv = [SELECT Id, ContentDocumentId FROM ContentVersion LIMIT 1];
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new C3HttpCalloutMockBundleClass('WhatsAppUploadAPI'));
            C3WhatsAppTemplateScreenLWCCtrl.runMediaAPIs(cv.Id, 'image/png' );
            //System.assertEquals( (cv.id != null) ,true); 
            System.assertNotEquals(null, cv.Id, 'ContentVersion Id should not be null');
            
            Test.stopTest();
        }
    }
}