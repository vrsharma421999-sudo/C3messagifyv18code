/**
* @class C3TestDataFactory
* @description Factory class to create test data for WhatsApp-related custom objects including Account, Contact,
* Template_Object__c, Template_Parameter__c, and Template_Button__c. Intended for use in unit tests.
*/
@isTest
public with sharing class C3TestDataFactory {
    
    
    public static User cachedUser;
    
    public static User getRunAsUser() {
        if (cachedUser != null) return cachedUser;
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User u = new User(
            Alias = 'tusr',
            Email = 'testuser@gmail.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'Asia/Kolkata',
            UserName = 'testuser' + System.currentTimeMillis() + '@gmail.com'
        );
        insert u;
        
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Messagify_WhatsApp' LIMIT 1];
        insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);
        
        PermissionSet ps3 = [SELECT Id FROM PermissionSet WHERE Name = 'WhatsApp_Named_Credential' LIMIT 1];
        insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps3.Id);
        PermissionSet ps4 = [SELECT Id FROM PermissionSet WHERE Name = 'WhatsApp_Site_Access' LIMIT 1];
        insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps4.Id);
        
        cachedUser = u;
        return cachedUser;
    }
    
    
    
    
    
    //user created with assigned permissions
    
    /**

* @description Creates a test Account record with predefined values.
* @return Account - A test Account record (not inserted).
*/
    public static Account createAccount(){
        Account objAccount = new Account();
        objAccount.Name='Test class Account';
        objAccount.AccountNumber='99999999999';
        objAccount.AccountSource='';
        objAccount.BillingCity='Noida';
        objAccount.BillingCountry ='India';
        objAccount.Industry = 'Education';
        objAccount.NumberOfEmployees = 89;
        objAccount.Website = 'www.cccinfotech.com/contact-us';
        objAccount.Type='Customer';
        
        return objAccount;
    }
    /**
* @method createTemplate
* @description Creates and inserts a Template_Object__c record with predefined values.
* @return Template_Object__c - The inserted template record.
*/
    public static CCCWA__Template_Object__c createTemplate(){
        CCCWA__Template_Object__c objTemplate = new CCCWA__Template_Object__c();
        System.runAs(getRunAsUser()) {
            objTemplate.CCCWA__Category__c ='UTILITY';
            objTemplate.CCCWA__Language_Code__c ='en';
            objTemplate.CCCWA__Status__c ='APPROVED';
            objTemplate.Name='greeting_message';
            objTemplate.CCCWA__Template_Label__c='greeting_message';
            objTemplate.CCCWA__Status__c='APPROVED';
            objTemplate.CCCWA__TemplateID__c='123465';
            objTemplate.CCCWA__Language_Code__c='en';
            objTemplate.CCCWA__Header_Type__c='IMAGE';
            objTemplate.CCCWA__Object__c='Lead';
            objTemplate.CCCWA__Header__c='Lead';
            objTemplate.CCCWA__Template_Message__c='Hello {{1}},This side {{2}} from salesforce partner if you have the requirement of CRM software to manage your customer list efficiently, along with all the customization we are the Salesforce partner, who provide the fully CRM solution that can significantly enhance your business operations and drive sales growth. I would be more than happy to arrange a personalized demo to showcase how [CRM] can revolutionize your companys sales and customer management efforts. If you are interested, please let me know, and we can find a convenient time to discuss further. Kindly share me your contact number and email id for easy communication.Best regards,{{3}} {{4}}{{5}}Powered By CCC Infotech';
            objTemplate.CCCWA__Whatsapp_Template__c='Hello {{1}},This side {{2}} from salesforce partner if you have the requirement of CRM software to manage your customer list efficiently, along with all the customization we are the Salesforce partner, who provide the fully CRM solution that can significantly enhance your business operations and drive sales growth. I would be more than happy to arrange a personalized demo to showcase how [CRM] can revolutionize your companys sales and customer management efforts. If you are interested, please let me know, and we can find a convenient time to discuss further. Kindly share me your contact number and email id for easy communication.Best regards,{{3}} {{4}}{{5}}Powered By CCC Infotech';
            objTemplate.CCCWA__Media_Handler__c = 'asdasdasd'; 
            if (Test.isRunningTest()) {
                insert objTemplate; // 🔥 SYSTEM MODE
            } else {
                Database.insert(objTemplate, AccessLevel.USER_MODE);
            }
        }
        return objTemplate;
    }
    /**
* @method createContacts
* @description Creates a list of test Contact records associated with a given Account Id.
* @param num Integer - Number of Contact records to create.
* @param accId String - AccountId to associate the contacts with.
* @return List<Contact> - List of unsaved Contact records.
*/
    public static List<Contact> createContacts(integer num, String accId){
        List<Contact> lstContact = new List<Contact>();
        for(Integer i = 0; i<= num; i++){
            Contact objContact = new Contact();
            objContact.LastName = 'testcontact' + i;
            objContact.FirstName = ' test contact' +i;
            objContact.AccountId = accId;
            objContact.MobilePhone='919911410564';
            objContact.Phone='919911410564';
            objContact.AssistantPhone = '919911410564';
            objContact.Email = 'shreya@cccinfotech.com';
            
            lstContact.add(objContact);
        }
        
        return lstContact;
    }
    /**
* @method createContacts
* @description Creates and inserts a single Contact record with predefined values.
* @return Contact - The inserted Contact record.
*/
    
    public static Contact createContacts(){
        // List<Contact> lstContact = new List<Contact>();
        Contact objContact = new Contact();
        objContact.LastName = 'testcontact' ;
        objContact.FirstName = 'test contact' ;
        objContact.MobilePhone='919911410564';
        objContact.Phone='919911410564';
        objContact.AssistantPhone = '919911410564';
        objContact.Email = 'shreya@cccinfotech.com';
        Database.INSERT(objContact, AccessLevel.USER_MODE);
        return objContact;
    }
    
    /**
* @method createTemplateMappings
* @description Creates a list of Template_Parameter__c records linked to a given template.
* @param numb Integer - Number of parameters to create (currently unused).
* @param templateId String - ID of the related Template_Object__c.
* @return List<Template_Parameter__c> - List of Template_Parameter__c records (not inserted).
*/
    
    public static List<Template_Parameter__c> createTemplateMappings(Integer numb, String templateId){
        List<Template_Parameter__c> listTemplateParameter = new List<Template_Parameter__c>();
        
        Template_Parameter__c objTemplateParameter1 = new Template_Parameter__c();
        objTemplateParameter1.Example_Text__c='test';
        objTemplateParameter1.Object_name__c = 'Contact';
        objTemplateParameter1.Parameter_Name__c= '1' ;
        objTemplateParameter1.Field_Name__c= 'FirstName';
        objTemplateParameter1.Template__c = templateId;
        listTemplateParameter.add(objTemplateParameter1);
        
        Template_Parameter__c objTemplateParameter2 = new Template_Parameter__c();
        objTemplateParameter2.Example_Text__c='test';
        objTemplateParameter2.Object_name__c = 'Contact';
        objTemplateParameter2.Parameter_Name__c= '2' ;
        objTemplateParameter2.Field_Name__c= 'LastName';
        objTemplateParameter2.Template__c = templateId;
        listTemplateParameter.add(objTemplateParameter2);
        
        Template_Parameter__c objTemplateParameter3 = new Template_Parameter__c();
        objTemplateParameter3.Example_Text__c='test';
        objTemplateParameter3.Object_name__c = 'Contact';
        objTemplateParameter3.Parameter_Name__c= '3' ;
        objTemplateParameter3.Field_Name__c= 'Name';
        objTemplateParameter3.Template__c = templateId;
        listTemplateParameter.add(objTemplateParameter3);
        
        Template_Parameter__c objTemplateParameter4 = new Template_Parameter__c();
        objTemplateParameter4.Example_Text__c='917948948998';
        objTemplateParameter4.Object_name__c = 'Contact';
        objTemplateParameter4.Parameter_Name__c= '4' ;
        objTemplateParameter4.Field_Name__c= 'MobilePhone';
        objTemplateParameter4.Template__c = templateId;
        listTemplateParameter.add(objTemplateParameter4);
        
        Template_Parameter__c objTemplateParameter5 = new Template_Parameter__c();
        objTemplateParameter5.Example_Text__c='test@gmail.com';
        objTemplateParameter5.Object_name__c = 'Contact';
        objTemplateParameter5.Parameter_Name__c= '5' ;
        objTemplateParameter5.Field_Name__c= 'Email';
        objTemplateParameter5.Template__c = templateId;
        listTemplateParameter.add(objTemplateParameter5);
        return listTemplateParameter;
        
    }
    /**
* @method createTemplateButtons
* @description Creates and inserts a list of Template_Button__c records linked to the given template.
* @param templateId String - ID of the related Template_Object__c.
* @return List<Template_Button__c> - Inserted list of Template_Button__c records.
*/
    
    
    public static List<Template_Button__c> createTemplateButtons( String templateId){
        
        List<Template_Button__c> listOfTemplateButton = new List<Template_Button__c>();
        System.runAs(getRunAsUser()){
            Template_Button__c objButton = new Template_Button__c();
            objButton.Button_Type__c = 'call to action';
            objButton.Type_of_Action__c = 'PHONE_NUMBER';
            objButton.Button_text__c = 'asdasd';
            objButton.Country_Code__c = '91';
            objButton.Phone_Number__c = 'objLstAct.phoneNumber';
            
            objButton.URL_Type__c = 'static';
            
            objButton.Website_URL__c = 'objLstAct.websiteUrl';
            
            objButton.Template__c = templateId;
            listOfTemplateButton.add(objButton);
            
            Template_Button__c objButton2 = new Template_Button__c();
            objButton2.Button_Type__c = 'QUICK_REPLY';
            objButton2.Button_text__c = 'asdasd';
            
            
            objButton2.Template__c = templateId;
            listOfTemplateButton.add(objButton2);
            
            Database.INSERT(listOfTemplateButton, AccessLevel.USER_MODE);
        }
        return listOfTemplateButton;
    }
    
    /**
* @description Builds a WhatsApp conversation record with test/mock data using a wrapper input.
* This method is typically used in test classes to generate WhatsApp_Conversation__b records.
*
* @param input A wrapper class (WhatsAppInputWrapper) containing:
*        - objTemplate: Template object (optional for test)
*        - toNumber: Recipient's WhatsApp number
*        - recordId: Related record ID
*        - wamId: WhatsApp message ID (WAM ID)
*
* @return WhatsApp_Conversation__b record populated with sample values.
*/
    
    public static CCCWA__whatsApp_conversation__b buildConvoRecord(WhatsAppInputWrapper input){
        CCCWA__whatsApp_conversation__b objTxtMsg = new CCCWA__whatsApp_conversation__b();
        
        objTxtMsg.CCCWA__Direction__c = 'Outbound';
        objTxtMsg.CCCWA__Status__c = 'sent';
        objTxtMsg.CCCWA__Record_ID__c = input.recordId;
        objTxtMsg.CCCWA__Read__c = 'true';
        objTxtMsg.CCCWA__Message__c = 'test Messagae';
        objTxtMsg.CCCWA__Message_formatted__c = 'test Messagae';
        objTxtMsg.CCCWA__From_Phone__c = '919911410564';
        objTxtMsg.CCCWA__To_Phone__c = input.toNumber;
        objTxtMsg.CCCWA__Interaction_Type__c = 'MMS';
        objTxtMsg.CCCWA__Created_date__c = DateTime.now();
        objTxtMsg.CCCWA__sid__c = input.wamId;
        objTxtMsg.CCCWA__Media_URL__c = 'testURL.com'; 
        objTxtMsg.CCCWA__File_Name__c = 'Test_file_Name'; 
        objTxtMsg.CCCWA__Media_Type__c = 'image'; 
        objTxtMsg.CCCWA__Unique_Key__c = input.recordId + '-' + System.Now().formatLong();
        return objTxtMsg;
    }
    /**
* @description Wrapper class to group input parameters required
*              to build a WhatsApp_Conversation__b record.
*/
    public class WhatsAppInputWrapper {
        public CCCWA__Template_Object__c objTemplate;
        public String toNumber;
        public String recordId;
        public String wamId;
    }
    /**
* @description Creates a WhatsApp Number Configuration record with the provided object and field names.
* @param objectName API name of the object.
* @param fieldName API name of the field.
*/
    public static void createWhatsAppConfigRecord(String objectName, String fieldName){
        WhatsApp_Number_Configuration__c objWNC = new WhatsApp_Number_Configuration__c();
        objWNC.Name =  objectName;
        objWNC.Object_Name__c =  objectName;
        objWNC.Field_Name__c =  fieldName;
        objWNC.Object_Label__c =  objectName;
        //Database.INSERT(objWNC, AccessLevel.USER_MODE);
        insert objWNC;
        //return objWNC;
    }
    /**
* @description Inserts a ContentVersion record with test file data.
* @param fileContent The binary file content as a Blob.
* @param fileName Name of the file.
* @param fileType MIME type of the file (e.g., image/png).
* @return The inserted ContentVersion record.
*/
    
    public static ContentVersion testInsertContentVersion(Blob fileContent, String fileName, String fileType) {
        ContentVersion objCV = new ContentVersion();
        
        objCV.VersionData = fileContent;
        objCV.Title = fileName;
        objCV.PathOnClient = fileName;
        if(String.isNotBlank(fileType) && fileType.contains('/')){
            String ext = fileType.split('/')[1];
            objCV.PathOnClient = objCV.PathOnClient + ext ;
            objCV.Title = objCV.Title + ext ;
        }
        Database.INSERT(objCV, AccessLevel.USER_MODE);
        
        return objCV;
    }
    /**
* @description Creates a ContentDocumentLink to associate a ContentVersion with a record.
* @param cvId ID of the ContentVersion.
* @param recordId ID of the record to link to.
* @return The inserted ContentDocumentLink.
* @throws AuraHandledException If the user lacks field access.
*/
    public static ContentDocumentLink testInsertCDL(String cvId, String recordId) {
        ContentDocumentLink objCDL = new ContentDocumentLink();
        String[] listFields = new String[]{'ContentDocumentId', 'Id'};
            if (
                C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('ContentVersion', 'isAccessible', null, true)) &&
                C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('ContentVersion', 'isAccessible', listFields, false))
            ) {
                objCDL.ContentDocumentId = [
                    SELECT Id, ContentDocumentId 
                    FROM ContentVersion 
                    WHERE Id = :cvId
                ].ContentDocumentId;
            }
        else {
            throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
        }
        objCDL.LinkedEntityId = recordId;
        objCDL.ShareType = 'V';
        Database.INSERT(objCDL, AccessLevel.USER_MODE);
        return objCDL;
    }
    /**
* @description Inserts a WhatsApp Admin configuration record with test data.
* @return The inserted WhatsApp_Admin__c record.
*/
    
    public static WhatsApp_Admin__c insertWhatsAppAdmin() {
        WhatsApp_Admin__c objAdminConfig = new WhatsApp_Admin__c(Name = 'admin', NumberID__c = 'asdasdasd', WabaId__c = 'dsfgasdas');
        insert objAdminConfig; // SYSTEM MODE by default
        //Database.INSERT(objAdminConfig, AccessLevel.USER_MODE);
        
        return objAdminConfig;
    }
    /**
* @description Inserts a WhatsApp Number Configuration record for the Lead object.
* @return The inserted WhatsApp_Number_Configuration__c record.
*/
    
    public static WhatsApp_Number_Configuration__c insertWhatsNumberConfig() {
        WhatsApp_Number_Configuration__c objNumberConfig = new WhatsApp_Number_Configuration__c(Name = 'Lead', Field_Name__c = 'MobilePhone', Object_Name__c = 'Lead');
        Database.INSERT(objNumberConfig, AccessLevel.USER_MODE);
        return objNumberConfig;
    }
}