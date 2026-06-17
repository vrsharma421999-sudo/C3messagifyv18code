/**
 *  @description This class handles WhatsApp number configuration logic for various SObjects.
 * It provides AuraEnabled methods to initialize, retrieve, and persist configuration records,
 * including checking for phone-type fields and object accessibility.
 */
public with sharing class C3WhatsappNumberConfiguration {
    /**
 *  @description Custom exception class used for handling errors specific to WhatsApp number configuration.
 */
    public class WhatsappNumberConfigurationException extends Exception {}
/**
 * @description Initializes the WhatsApp number configuration UI.
 * Returns a JSON string containing existing configuration and available objects with phone fields.
 *
 * @return JSON string with main wrapper data for frontend display.
 */
    @AuraEnabled
    public static string initWhatsAppNumberConfiguration() {
        try{
            MainWrapper objMain = new MainWrapper();
            objMain.hasRecords = false;
            objMain.lstToNumberConfiguration = new List<WhatsApp_Number_Configuration__c>();
            objMain.objectPickList = new List<PickList>();
            Map<String, String> mapObjectNamewithLable = new Map<String, String>();
            Set<String> setOfObjectSaved = new Set<String>();
            if(!C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('WhatsApp_Number_Configuration__c','isAccessible',new List<String>{'Field_Name__c', 'Object_Name__c'},False))){
                throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
            }else{
                objMain.lstToNumberConfiguration = WhatsApp_Number_Configuration__c.getAll().values();
                
            }
            
            for(WhatsApp_Number_Configuration__c objCustToNumber : objMain.lstToNumberConfiguration){
                setOfObjectSaved.add(objCustToNumber.Object_Name__c);
                objMain.hasRecords = true;
                
            }

            //List<String> listAllObjectNames = new List<String>();
            for(Schema.SObjectType strObjType : Schema.getGlobalDescribe().Values()){
                String name = strObjType.getDescribe().getName();
                String label = strObjType.getDescribe().getlabel();
                if(!setOfObjectSaved.contains(strObjType.getDescribe().getName()) && strObjType.getDescribe().isAccessible() && strObjType.getDescribe().isCreateable() && !strObjType.getDescribe().isCustomSetting() 
                && strObjType.getDescribe().isQueryable() && strObjType.getDescribe().isUpdateable() && !strObjType.getDescribe().getName().containsignorecase('history') && !strObjType.getDescribe().getName().containsignorecase('tag') && !strObjType.getDescribe().getName().containsignorecase('event') &&
                !strObjType.getDescribe().getName().containsignorecase('share') && !strObjType.getDescribe().getName().containsignorecase('feed')){      
                    mapObjectNamewithLable.put(name, label);
                   
                }
            }

            for(String objectName : mapObjectNamewithLable.keySet()){
                if(hasPhoneField(objectName)){
                    PickList objPickList = new PickList();
                    objPickList.label = mapObjectNamewithLable.get(objectName);
                    objPickList.value = objectName;
                    objMain.objectPickList.add(objPickList);
                }
            }
            return json.serialize(objMain);
        }catch(exception ex){
            C3Utility.logError(ex.getMessage(), ex.getStackTraceString(), ex.getLineNumber(), '','WhatsappNumberConfiguration','initWhatsAppNumberConfiguration','');
            return null;
        }
    }
    /**
 *  @description Gets the label for the specified SObject name.
 *
 * @param objectName The API name of the object.
 * @return The label of the object, or null if not found.
 */
    @AuraEnabled
    public static string getObjectLabel(String objectName){
    try{
        if(String.isNotBlank(objectName)){
            SObjectType sObjectType = Schema.getGlobalDescribe().get(objectName);
            return sobjectType.getDescribe().getlabel();
        }
        return null;
        }catch(exception ex){
            C3Utility.logError(ex.getMessage(), ex.getStackTraceString(), ex.getLineNumber(), '','WhatsappNumberConfiguration','getObjectLabel','');
            return null;
        }
    } 
    /**
 *  @description Checks if the given SObject contains at least one accessible phone field.
 *
 * @param sObjectName The API name of the SObject.
 * @return true if a phone field exists; false otherwise.
 */

    public static Boolean hasPhoneField(String sObjectName){
        SObjectType sObjectType = Schema.getGlobalDescribe().get(sObjectName);
        Map<String, Schema.SObjectField> objectFieldsMap = SObjectType.getDescribe().fields.getMap();
        for (Schema.SObjectField field : objectFieldsMap.values()) {
            //Schema.DescribeFieldResult desribeResult = field.getDescribe();
            //String fieldName = field.getDescribe().getLabel();
            //String fieldAPIName = field.getDescribe().getName();
            String strType = String.valueOf(field.getDescribe().getType());
            
            if(field.getDescribe().isAccessible() && !(field.getDescribe().getName() == 'Id'))
            {
                switch on strType 
                {
                    when 'PHONE' {
                        return true;
                    }
                }
            }
        }
        return false;
    }
    /**
 *  @description Retrieves all accessible phone fields for the given SObject.
 *
 * @param sObjectName The API name of the SObject.
 * @return JSON string representing a list of phone field options, or null if none.
 */
    @AuraEnabled
    public static String getAllPhoneField(String sObjectName){
        try{
            List<PickList> listPickList = new List<PickList>();
            SObjectType sobjectType = Schema.getGlobalDescribe().get(sObjectName);
            Map<String, Schema.SObjectField> objectFieldsMap = sobjectType.getDescribe().fields.getMap();
            for (Schema.SObjectField field : objectFieldsMap.values()) {
               // Schema.DescribeFieldResult desribeResult = field.getDescribe();
                String fieldName = field.getDescribe().getLabel();
                String fieldAPIName = field.getDescribe().getName();
                String strType = String.valueOf(field.getDescribe().getType());
                
                if(field.getDescribe().isAccessible() && !(field.getDescribe().getName() == 'Id'))
                {
                    switch on strType 
                    {
                        when 'PHONE' {
                            PickList objPickList = new PickList();
                            objPickList.label = fieldName;
                            objPickList.value = fieldAPIName;
                            listPickList.add(objPickList);
                        }
                    }
                }
            }
            if (!listPickList.isEmpty()) {
                return json.serialize(listPickList);
            }
            return null;
        }catch(exception ex){
            C3Utility.logError(ex.getMessage(), ex.getStackTraceString(), ex.getLineNumber(), '','WhatsappNumberConfiguration','getAllPhoneField','');
            return null;
        }
    }
    /**
 *  @description Saves or updates a WhatsApp number configuration record.
 *
 * @param jsonNumberConfig JSON string representing the WhatsApp_Number_Configuration__c object.
 * @return null if successful, or error string if failure.
 */

    @AuraEnabled
    public static string saveWhatsAppNumberConfig(String jsonNumberConfig){
        
        try{
            if(String.isnotblank(jsonNumberConfig)){
                WhatsApp_Number_Configuration__c objWhatsAppNumConfig = (WhatsApp_Number_Configuration__c)JSON.deserialize(jsonNumberConfig, WhatsApp_Number_Configuration__c.class);
                Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
                Schema.DescribeSObjectResult objectDescribe = globalDescribe.get(objWhatsAppNumConfig.Object_Name__c).getDescribe();
                objWhatsAppNumConfig.Object_Label__c = objectDescribe.getLabel();
                
                List<String> listFields = new List<String>{'Field_Name__c', 'Object_Name__c'};
                if(C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('WhatsApp_Number_Configuration__c', 'isAccessible', null, true))
                && C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('WhatsApp_Number_Configuration__c', 'isAccessible', listFields, false))
                && C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('WhatsApp_Number_Configuration__c', 'isCreateable', null, true))
                && C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('WhatsApp_Number_Configuration__c', 'isCreateable', listFields, false))
                && C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('WhatsApp_Number_Configuration__c', 'isUpdateable', null, true))
                && C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('WhatsApp_Number_Configuration__c', 'isUpdateable', listFields, false))){
                    Database.UPSERT(objWhatsAppNumConfig, AccessLevel.USER_MODE);
                }else {
                    throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
                }
                return json.serialize(WhatsApp_Number_Configuration__c.getAll().values());
            }
            return null;
        }catch(exception ex){
            C3Utility.logError(ex.getMessage(), ex.getStackTraceString(), ex.getLineNumber(), '','WhatsappNumberConfiguration','saveWhatsAppNumberConfig','');
            return null;
        }
    }
/**
 *  @description Deletes a WhatsApp Number Configuration record if the user has sufficient permissions.
 *
 * @param jsonNumberConfig A JSON string representing the WhatsApp_Number_Configuration__c object with an Id.
 * @return A serialized list of all remaining WhatsApp_Number_Configuration__c records.
 * @throws AuraHandledException If the user lacks delete access.
 */
    @AuraEnabled
    public static string deleteWhatsAppNumberConfig(String jsonNumberConfig){
        if(String.isnotblank(jsonNumberConfig)){
            WhatsApp_Number_Configuration__c objWhatsAppNumConfig = (WhatsApp_Number_Configuration__c)JSON.deserialize(jsonNumberConfig, WhatsApp_Number_Configuration__c.class);
            if(C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('WhatsApp_Number_Configuration__c', 'isDeletable', null, true) )
            && C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('WhatsApp_Number_Configuration__c', 'isAccessible', null, true))){
                Database.Delete(objWhatsAppNumConfig, AccessLevel.USER_MODE);
            }else{
                throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
            }
            return json.serialize(WhatsApp_Number_Configuration__c.getAll().values());
        }
        return null;
    }
/**
 *  @description Wrapper class to hold information about WhatsApp Number Configurations and picklist metadata.
 */
    public class MainWrapper{
        public boolean hasRecords;        
        public list<WhatsApp_Number_Configuration__c> lstToNumberConfiguration;
        public list<PickList> objectPickList;
    }
    /**
 *  @description Simple key-value pair class used to represent a picklist option.
 */

    public class PickList{
        public String label;
        public String value;
    }


/**
 *  @description Wrapper used to pass data from Apex to Lightning Web Component.
 */

    public class LWCWrapper{
        public string strMessage;
        public Boolean isSetUpCompleted;
        public boolean isSuccess;        
        public list<WhatsApp_Number_Configuration__c> lstToNumberConfiguration;
        public list<ObjectDetailWrapper> lstObjectDetailWrapper;
        public list<ObjectDetailWrapper> lstObjectCreatedMapping;
    }
    /**
 *  @description Represents metadata of a specific Salesforce object including field details.
 */
    public class ObjectDetailWrapper{
        public String strObjectName;
        public String strObjectAPIName;
        public String strObject3DigitCode;
        public List<FieldDetailWrapper> lstFieldDetailWrapper;
    }
    /**
 *  @description Represents metadata about a single field of a Salesforce object.
 */
    public class FieldDetailWrapper{
        public String strLabel;
        public String strAPIName;
    }
}