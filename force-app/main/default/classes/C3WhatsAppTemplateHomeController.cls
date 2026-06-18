/**
* @class C3WhatsAppTemplateHomeController
* @description
*  Apex controller for managing WhatsApp templates used within a Lightning/Aura component.
*  Provides methods for retrieving and deleting WhatsApp templates securely.
*
* @access public
* @author Asjad Ahmed
* @version 1.0
* @date June 2025
* @company CloudCentric
*/
public with sharing class C3WhatsAppTemplateHomeController { 
    
    /**
* @method WhatsAppTemplates
* @description
*  Retrieves a list of available WhatsApp templates from the Template_Object__c object.
*  Ensures field-level security using a utility method before executing the query.
*
* @return String - JSON serialized object of type TemplateWrapper containing templates and success status.
* @throws AuraHandledException - if user lacks field-level access.
* @access public
* @AuraEnabled This method is exposed to Aura and LWC components.
*/
    @AuraEnabled
    public static String whatsAppTemplates() {
        try {
            TemplateWrapper objwrap = new TemplateWrapper();
            List<CCCWA__Template_Object__c > listOfTemplates = new List<CCCWA__Template_Object__c >();
            
            if (!C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest(
                'Template_Object__c',
                'isAccessible',
                new List<String>{'Id', 'Name', 'Language_Code__c', 'Template_Message__c', 'Object__c', 'CCCWA__Project__c','Category__c'},
                true
            ))) {
                throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
            } else {
                listOfTemplates = [
                    SELECT Id, Name, Status__c, Language_Code__c, Template_Message__c, Object__c,CCCWA__Project__c, Category__c
                    FROM CCCWA__Template_Object__c
                    WITH SECURITY_ENFORCED
                    LIMIT 49000
                ];
            }
            
            if (!listOfTemplates.isEmpty()) {
                objwrap.success = true;
                objwrap.listOfTemplates = listOfTemplates;
            }
            
            return JSON.serialize(objwrap);
            
        } catch (Exception ex) {
            C3Utility.logError(ex.getMessage(), ex.getStackTraceString(), ex.getLineNumber(), '', 'WhatsAppTemplateHomeController', 'WhatsAppTemplates', '');
            return null;
        }
    }
    
    /**
* @method deleteWhatsAppTemplates
* @description
*  Deletes a WhatsApp template by its record ID after checking field- and object-level access.
*  After deletion, retrieves the updated list of templates and returns it as JSON.
*
* @param recordId String - ID of the Template_Object__c record to delete.
* @return String - JSON serialized object of type TemplateWrapper containing updated templates and success status.
* @throws AuraHandledException - if user lacks required access.
* @access public
* @AuraEnabled This method is exposed to Aura and LWC components.
*/
    @AuraEnabled
    public static String deleteWhatsAppTemplates(String recordId) {
        try {
            TemplateWrapper objwrap = new TemplateWrapper();
            
            if (String.isNotBlank(recordId)) {
                List<CCCWA__Template_Object__c > deleteTemp = new List<CCCWA__Template_Object__c >();
                
                if (!C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Object__c ', 'isAccessible', new List<String>{'Id'}, true))) {
                    throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
                } else {
                    deleteTemp = [SELECT Id FROM CCCWA__Template_Object__c WHERE Id = :recordId WITH SECURITY_ENFORCED];
                }
                
                if (!deleteTemp.isEmpty()) {
                    Schema.DescribeSObjectResult describeResult = CCCWA__Template_Object__c.SObjectType.getDescribe();
                    
                    if (describeResult.isAccessible() && describeResult.isDeletable()) {
                        Database.delete(deleteTemp, AccessLevel.USER_MODE);
                    } else {
                        throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
                    }
                }
                
            }
            
            objwrap = (TemplateWrapper) JSON.deserialize(WhatsAppTemplates(), TemplateWrapper.class);
            return JSON.serialize(objwrap);
            
        } catch (Exception ex) {
            C3Utility.logError(ex.getMessage(), ex.getStackTraceString(), ex.getLineNumber(), '', 'WhatsAppTemplateHomeController', 'deleteWhatsAppTemplates', '');
            return null;
        }
    }
     
    /**
* @class TemplateWrapper
* @description
*  Wrapper class for returning WhatsApp template data and a success flag.
*/
    public class TemplateWrapper {
        /**
* Indicates success of the operation.
*/
        public Boolean success;
        
        /**
* List of WhatsApp templates returned from the query.
*/
        public List<Template_Object__c> listOfTemplates;
    }
    
    /**
* @class TemplateObject
* @description
*  A simple model class representing a template's display attributes.
*/
    public class TemplateObject {
        /**
* Name of the template.
*/
        public String name;
        
        /**
* Status of the template.
*/
        public String status;
    }
}