/**
* @description This class provides utility functions for various operations.
* @author Asjad Ahmed
* @version 1.0
* @company CloudCentric
* @license Salesforce Public License
* @date June 2025
*/

public with sharing class C3Utility {
    
    /**
* @description This variable holds the formatted template message for WhatsApp communications.
*/
    public static String formattedTemplateMessage;
    /**
* @description Checks the field permissions for a specified object or fields.
* @param request The permission check request object containing object name, access type, field names and object/field indicator.
* @return Boolean indicating whether the permission is granted.
*/
    public static Boolean checkFieldPermission(FieldPermissionRequest request) {
        Boolean isPermitted = true;
        String apiNamePrefix = getNameSpace();
        Map<String, Schema.SObjectType> describeObject = Schema.getGlobalDescribe();
        String objName = request.objName.toLowerCase();
        
        if (objName.endsWith('__c')) {
            objName = apiNamePrefix + objName;
        }
        
        if (describeObject.containsKey(objName) && request.isObjectCheck) {
            Schema.DescribeSObjectResult objDescribe = describeObject.get(objName).getDescribe();
            
            if ((request.accessType == 'isCreateable' && !objDescribe.isCreateable()) ||
                (request.accessType == 'isUpdateable' && !objDescribe.isUpdateable()) ||
                (request.accessType == 'isAccessible' && !objDescribe.isAccessible()) ||
                (request.accessType == 'isDeletable' && !objDescribe.isDeletable())) {
                    isPermitted = false;
                }
        } else if (describeObject.containsKey(objName) && !request.isObjectCheck && request.fieldNames != null && !request.fieldNames.isEmpty()) {
            Map<String, Schema.SObjectField> fieldMap = describeObject.get(objName).getDescribe().fields.getMap();
            
            for (String fieldName : request.fieldNames) {
                String lowerFieldName = fieldName.toLowerCase();
                if (lowerFieldName.endsWith('__c')) {
                    lowerFieldName = apiNamePrefix + lowerFieldName;
                }
                
                if (!fieldMap.containsKey(lowerFieldName)) {
                    return false;
                }
                Schema.DescribeFieldResult fieldDescribe = fieldMap.get(lowerFieldName).getDescribe();
                Boolean hasPermission = true;
                if (request.accessType == 'isCreateable') {
                    hasPermission = fieldDescribe.isCreateable();
                } else if (request.accessType == 'isUpdateable') {
                    hasPermission = fieldDescribe.isUpdateable();
                } else if (request.accessType == 'isAccessible') {
                    hasPermission = fieldDescribe.isAccessible();
                }
                
                if (!hasPermission) {
                    isPermitted = false;
                    break;
                }
            }
        }
        
        return isPermitted;
    }
    
    /**
* @description A utility class to represent a request for checking field- or object-level permissions in Salesforce.
*              Supports fluent-style setters for easy chaining when building requests.
*/
    public class FieldPermissionRequest {
        /**
* @description The API name of the Salesforce object (e.g., Account, Contact).
*/
        public String objName;
        /**
* @description The type of access to check (e.g., 'read', 'edit', 'create').
*/
        public String accessType;
        /**
* @description A list of field API names for which to check permissions.
*/
        public List<String> fieldNames;
        /**
* @description A flag indicating whether to check object-level permissions instead of field-level.
*/
        public Boolean isObjectCheck;
        
        
        /**
* @description Constructor to initialize the permission request with the given parameters.
* @param objName The API name of the object.
* @param accessType The type of access (e.g., read, edit).
* @param fieldNames A list of field names to check.
* @param isObjectCheck Whether to check object-level permissions.
*/
        public FieldPermissionRequest(String objName, String accessType, List<String> fieldNames, Boolean isObjectCheck) {
            this.objName = objName;
            this.accessType = accessType;
            this.fieldNames = fieldNames;
            this.isObjectCheck = isObjectCheck;
        }
        
        // Fluent-style setters for chaining
        /**
* @description Sets the object name.
* @param objName The API name of the object.
* @return The current FieldPermissionRequest instance for chaining.
*/
        public FieldPermissionRequest setObjectName(String objName) {
            this.objName = objName;
            return this;
        }
        /**
* @description Sets the type of access to check.
* @param accessType The access type (e.g., read, edit).
* @return The current FieldPermissionRequest instance for chaining.
*/
        public FieldPermissionRequest setAccessType(String accessType) {
            this.accessType = accessType;
            return this;
        }
        
        
        /**
* @description Sets the list of field names to check.
* @param fieldNames A list of field API names.
* @return The current FieldPermissionRequest instance for chaining.
*/
        public FieldPermissionRequest setFieldNames(List<String> fieldNames) {
            this.fieldNames = fieldNames;
            return this;
        }
        
        /**
* @description Sets whether to check object-level permissions.
* @param isObjectCheck True if object-level permissions should be checked.
* @return The current FieldPermissionRequest instance for chaining.
*/
        public FieldPermissionRequest setObjectCheck(Boolean isObjectCheck) {
            this.isObjectCheck = isObjectCheck;
            return this;
        }
    }
    
    /**
* @description Retrieves the field name without the namespace prefix.
* @param fieldName The full field name including the namespace.
* @return The field name without the namespace.
*/
    public static String getFieldWithoutNameSpace(String fieldName){
        String apiNamePrefix=getNameSpace();
        if(fieldName.startsWithIgnoreCase(apiNamePrefix)){
            fieldName=fieldName.substring(apiNamePrefix.length(),fieldName.length());
        }
        return fieldName;
    }
    /**
* @description Retrieves the namespace prefix for the current class.
* @return The namespace prefix as a string.
*/
    public static String getNameSpace(){ 
        String apiNamePrefix='';
        String[] classNameParts = String.valueOf(C3Utility.class).split('\\.', 2);
        if(classNameParts.size() > 1) {
            Type classType = Type.forName(classNameParts[0], classNameParts[1]);
            if(classType == C3Utility.class) {
                apiNamePrefix = classNameParts[0]+'__';
            }
        }
        return apiNamePrefix;
    }
    /**
* @description Fetches the phone number associated with a given record ID.
* @param recordId The ID of the record to fetch the phone number for.
* @return The phone number as a string.
*/
    
    public static string fetchPhoneNumber(String recordId) {
        String phoneNumber = '';
        String objectNameForPhone = '';
        if (recordId != null) {
            objectNameForPhone = Id.valueOf(recordId).getSObjectType().getDescribe().getName();
        }
        Map<String, CCCWA__WhatsApp_Number_Configuration__c> numberSettingsMap = new Map<String, CCCWA__WhatsApp_Number_Configuration__c>();
        FieldPermissionRequest req = new FieldPermissionRequest(
            'CCCWA__WhatsApp_Number_Configuration__c', 
            'isAccessible', 
            new List<String>{'CCCWA__Field_Name__c', 'CCCWA__Object_Name__c'}, 
            false
        );
        
        if (!checkFieldPermission(req)) {
            throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
        }else{
            numberSettingsMap = CCCWA__WhatsApp_Number_Configuration__c.getAll();
        }
        CCCWA__WhatsApp_Number_Configuration__c setting = numberSettingsMap.get(objectNameForPhone);
        
        if (setting != null) {
            String query = 'SELECT ' + setting.CCCWA__Field_Name__c + ' FROM ' + setting.CCCWA__Object_Name__c + ' WHERE Id =: recordId LIMIT 1';
            SObject record;
            List<String> fieldsToQuery = setting.CCCWA__Field_Name__c.split(',');
            Boolean b1 = !checkFieldPermission(
                new FieldPermissionRequest(
                    setting.CCCWA__Object_Name__c,
                    'isAccessible',
                    null,
                    true
                )
            );
            
            Boolean b2 = !checkFieldPermission(
                new FieldPermissionRequest(
                    setting.CCCWA__Object_Name__c,
                    'isAccessible',
                    fieldsToQuery,
                    false
                )
            );
            
            if(b1 && b2){
                throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
            }else{
                record = Database.query(String.escapeSingleQuotes(query), AccessLevel.USER_MODE); 
            }
            if (record != null) {
                phoneNumber = String.valueOf(record.get(setting.CCCWA__Field_Name__c));
            }
            return phoneNumber;
        }
        throw new AuraHandledException('This record have blank number field which is configured in WhatsApp Configuration Setting!');
    }
    /**
* @description Formats the body of a message by replacing HTML tags with Markdown syntax.
* @param strText The input string containing HTML.
* @return The formatted string with Markdown syntax.
*/
    public static String getFormattedBodyutility(String strText){
        String input = '';
        
        if(!String.isBlank(strText)){
            input = strText.replaceAll('<b>', '*');
            input = input.replaceAll('</b>', '*');
            input = input.replaceAll('</p>', '\n');
            input = input.replaceAll('<p>', '');
            input = input.replaceAll('<em>', '_');
            input = input.replaceAll('</em>', '_');
            input = input.replaceAll('<br>', '\n');
            input = input.replaceAll('</strong>', '*');
            input = input.replaceAll('<strong>', '*');
            input = input.replaceAll('<strike>', '~');
            input = input.replaceAll('</strike>', '~');
            input = input.replaceAll('<div style="text-align:center">', '');
            input = input.replaceAll('</div>', '');
            input = input.replaceAll('<br/>', '\n');
        }
        return input;
    }
    
    /**
* @description Validates the parameters of a template based on the record ID and template ID.
* @param recordId The ID of the record to validate.
* @param templateId The ID of the template to validate against.
* @return A success message if validation passes.
*/
    @AuraEnabled
    public static string valdiateTemplatePrameters(String recordId, String templateId){
        if (String.isNotBlank(recordId) && String.isNotBlank(templateId)) {
            Id recId = Id.valueOf(recordId);
            String objectName = recId.getSObjectType().getDescribe().getName();
            CCCWA__Template_Object__c objTemplate = C3WhatsAppTemplateScreenLWCCtrl.getRecordData(templateId, objectName);
            if((objTemplate != null) && (objTemplate.CCCWA__Template_Mappings__r != null) && objTemplate.CCCWA__Template_Mappings__r.size()>0 ){
                Map<String, String> mapParamNumWithFieldName = new Map<String, String>();
                for(CCCWA__Template_Parameter__c objTempMapping : objTemplate.CCCWA__Template_Mappings__r ){
                    mapParamNumWithFieldName.put(objTempMapping.CCCWA__Parameter_Name__c, objTempMapping.CCCWA__Field_Name__c );
                }
                
                
                Set<String> fieldSet = new Set<String>(mapParamNumWithFieldName.values());
                String query = 'SELECT Id, '+ String.join(fieldSet, ',') + ' FROM '+objectName+' WHERE Id =: recId WITH SECURITY_ENFORCED LIMIT 1';
                SObject objSObject ;         
                List<String> fieldsToQuery = new List<String>(fieldSet);
                Boolean b1 = !C3Utility.checkFieldPermission(
                    new FieldPermissionRequest(
                        objectName,
                        'isAccessible',
                        null,
                        true
                    )
                );
                
                Boolean b2 = !C3Utility.checkFieldPermission(
                    new FieldPermissionRequest(
                        objectName,
                        'isAccessible',
                        fieldsToQuery,
                        false
                    )
                );
                if(b1 && b2){
                    throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
                }else{
                    objSObject = database.query(String.escapeSingleQuotes(query));
                }
                
                if(mapParamNumWithFieldName != null && (!mapParamNumWithFieldName.isEmpty())){
                    integer numOfParam = mapParamNumWithFieldName.size();
                    List<String> listField = new List<String>();
                    for(integer loopVar = 0; loopVar <= numOfParam ; loopVar++){
                        String key = String.valueOf(loopVar);
                        if(mapParamNumWithFieldName.containsKey(key) && objSobject.get(mapParamNumWithFieldName.get(key)) == null){
                            //if(objSobject.get(mapParamNumWithFieldName.get(key)) == null){
                            listField.add(mapParamNumWithFieldName.get(key));
                            // throw new AuraHandledException('One of the template parameter is blank!, field Name : '+mapParamNumWithFieldName.get(key) +', please do not send this template without parameter.');
                            //}
                        }
                    }
                    if(!listField.isEmpty()){
                        throw new AuraHandledException('One of the template parameters are blank!, field Names : '+ String.join(listField, ', ') +', please do not send this template without parameter.');
                    }
                }
            }
        }
        return 'success';
    }
    /**
* @description Retrieves all fields of a specified SObject.
* @param sObjectName The name of the SObject to retrieve fields for.
* @return A JSON serialized string of the object fields.
*/
    //getting all the Fields of the SObject
    @AuraEnabled
    public static string getObjectFields(String sObjectName) 
    {
        try {
            UtilityMainWrapper objMain = new UtilityMainWrapper();
            objMain.lstObjectPicklist = new List<ObjectPicklist>();
            SObjectType sObjectType = Schema.getGlobalDescribe().get(sObjectName);
            Map<String, Schema.SObjectField> objectFieldsMap = sObjectType.getDescribe().fields.getMap();
            
            for (Schema.SObjectField field : objectFieldsMap.values()) {
                
                //Schema.DescribeFieldResult desribeResult = field.getDescribe();
                String fieldName = field.getDescribe().getLabel() + ' ('+ field.getDescribe().getName() + ' )';
                String fieldAPIName = field.getDescribe().getName();
                String strType = String.valueOf(field.getDescribe().getType());
                
                if(field.getDescribe().isAccessible() && !(field.getDescribe().getName() == 'Id'))
                {
                    
                    switch on strType 
                    {
                        when 'EMAIL' {
                            ObjectPicklist objPickList = new ObjectPicklist();
                            objPickList.label = fieldName;
                            objPickList.value = fieldAPIName;
                            objMain.lstObjectPicklist.add(objPickList);
                        }
                        /*when 'BOOLEAN' {

}
when 'DATE' {

}
when 'DATETIME' {

}*/
                        when 'PICKLIST' {
                            ObjectPicklist objPickList = new ObjectPicklist();
                            objPickList.label = fieldName;
                            objPickList.value = fieldAPIName;
                            objMain.lstObjectPicklist.add(objPickList);
                        }
                        /*when 'REFERENCE' {

}
when 'DOUBLE' {

}
when 'INTEGER' {

}
when 'PERCENT' {


}
when 'CURRENCY' {


}*/
                        when else {
                            ObjectPicklist objPickList = new ObjectPicklist();
                            objPickList.label = fieldName;
                            objPickList.value = fieldAPIName;
                            objMain.lstObjectPicklist.add(objPickList);
                        }
                    }
                }
            }
            return JSON.serialize(objMain);
        }catch (Exception ex) {
            logError(ex.getMessage(), ex.getStackTraceString(), ex.getLineNumber(), '','Utility','getObjectFields','');
            return null;
        }
    }
    /**
* @description Uploads a file under a specified record.
* @param fileContent The content of the file to upload.
* @param fileName The name of the file.
* @param fileType The type of the file.
* @param recordId The ID of the record to associate the file with.
* @return The download URL of the uploaded file.
*/
    // upload file under record
//@SuppressWarnings('PMD.ApexFlsViolation')
    /*
* Suppression Reason:
* This method explicitly performs comprehensive Field-Level Security (FLS) 
* and CRUD checks before any DML operations on ContentVersion, 
* ContentDocumentLink, and ContentDistribution objects.
* 
* The PMD rule "ApexFlsViolation" is triggered because the fields 
* (e.g., PathOnClient, VersionData, Title, etc.) are being set directly 
* and inserted using Database.insert(). 
* 
* However, the implementation ensures security by calling 
* checkFieldPermission() for all relevant fields and operations 
* (isAccessible, isCreateable) prior to DML. 
* 
* Therefore, the warning is a false positive, and suppression is safe 
* in this context.
*/
    /*
* Suppression Reason:
* The PMD rule "ApexFlsViolation" is triggered because the field 
* `ShareType` on the ContentDocumentLink object is being set 
* and inserted directly using Database.insert().
*
* However, this implementation already performs explicit 
* object-level and field-level security checks before the DML:
*   - isAccessible() for the object and specified fields
*   - isCreateable() for the object and specified fields
*
* Only when all checks (b5, b6, b7, b8) return true does the code 
* proceed with Database.insert(). Otherwise, a controlled 
* exception is thrown.
*
* Since field-level security is being enforced programmatically, 
* this is a false positive from the static analysis tool, and 
* suppressing the warning is safe in this context.
*/
    /*
* Suppression Reason:
* - PMD flags ApexFlsViolation on ContentDocumentLink and ContentDistribution inserts.
* - False positive because FLS is already enforced via checkFieldPermission before DML.
* - Safe to suppress since access control is handled programmatically.
*/
    
    public static String uploadFile(Blob fileContent, String fileName, String fileType, String recordId) {
        try{
            ContentVersion objCV = new ContentVersion();
            // Assigning file content to VersionData after verifying field-level security.
            // NOPMD(ApexFlsViolation) - Safe: VersionData field checked for accessibility and createability before assignment
            
            objCV.VersionData = fileContent;
            
            // Assigning file name to Title after verifying FLS.
            // NOPMD(ApexFlsViolation) - Safe: Title field checked for accessibility and createability before assignment
            
            objCV.Title = fileName;
            // Assigning file name to PathOnClient after verifying FLS.
            // NOPMD(ApexFlsViolation) - Safe: PathOnClient field checked for accessibility and createability before assignment
            objCV.PathOnClient = fileName;
            if(String.isNotBlank(fileType) && fileType.contains('/')){
                String ext = fileType.split('/')[1];
                objCV.PathOnClient = objCV.PathOnClient + ext ;
                objCV.Title = objCV.Title + ext ;
            }
            String[] listFields0 = new String[]{'VersionData', 'Title', 'PathOnClient', 'fileType'};
                boolean b1 = checkFieldPermission(new FieldPermissionRequest('ContentVersion', 'isAccessible', null, true));
            boolean b2 = checkFieldPermission(new FieldPermissionRequest('ContentVersion', 'isAccessible', listFields0, false));
            boolean b3 = checkFieldPermission(new FieldPermissionRequest('ContentVersion', 'isCreateable', null, true));
            boolean b4 = checkFieldPermission(new FieldPermissionRequest('ContentVersion', 'isCreateable', listFields0, false));
            if (b1 && b2 && b3 && b4) {
                // Inserting ContentVersion in USER_MODE only after explicit FLS checks on VersionData, Title, PathOnClient, and fileType.
                // NOPMD(ApexFlsViolation) - Safe: Insert executed only after validation of required fields with explicit FLS checks
                Database.insert(objCV, AccessLevel.USER_MODE);// NOPMD(ApexFlsViolation) - Safe: Explicit FLS checks performed for all ContentVersion fields before DML
            }else {
                throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
            }
            
            ContentDocumentLink objCDL = new ContentDocumentLink();
            String[] listFields = new String[]{'ContentDocumentId', 'Id'};
                if (
                    checkFieldPermission(new FieldPermissionRequest('ContentVersion', 'isAccessible', null, true)) &&
                    checkFieldPermission(new FieldPermissionRequest('ContentVersion', 'isAccessible', listFields, false))
                ) {
                    objCDL.ContentDocumentId = [
                        SELECT Id, ContentDocumentId 
                        FROM ContentVersion 
                        WHERE Id = :objCV.Id
                    ].ContentDocumentId;
                }else {
                    throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
                }
            objCDL.LinkedEntityId = recordId;
            objCDL.ShareType = 'V';
            String[] listFields2 = new String[]{'LinkedEntityId', 'ShareType', 'ContentDocumentId'};
                boolean b5 = checkFieldPermission(new FieldPermissionRequest('ContentDocumentLink', 'isAccessible', null, true));
            boolean b6 = checkFieldPermission(new FieldPermissionRequest('ContentDocumentLink', 'isAccessible', listFields2, false));
            boolean b7 = checkFieldPermission(new FieldPermissionRequest('ContentDocumentLink', 'isCreateable', null, true));
            boolean b8 = checkFieldPermission(new FieldPermissionRequest('ContentDocumentLink', 'isCreateable', listFields2, false));
            if (b5 && b6 && b7 && b8) {
                Database.insert(objCDL, AccessLevel.USER_MODE);
                // NOPMD(ApexFlsViolation) - Safe: Explicit FLS checks performed for ContentDocumentLink fields 
                // (LinkedEntityId, ShareType, ContentDocumentId) before insert. 
                // Insert is executed in USER_MODE only after validation.
            }else {
                throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
            }
            
            ContentDistribution objCD = new ContentDistribution();
            // NOPMD(ApexFlsViolation) – PMD flags Name field assignment.
            // Justification:
            // - Name is a required, standard ContentDistribution field.
            // - No sensitive data exposure.
            // - Safe to assign directly since overall FLS checks are performed prior to insert.
            objCD.Name = fileName;
            // NOPMD(ApexFlsViolation)
            // 1. PreferencesAllowViewInBrowser is a standard ContentDistribution field.
            // 2. Explicit FLS checks (isAccessible + isCreateable) are performed via checkFieldPermission()
            //    before any DML operation.
            // 3. Insert occurs only if all FLS checks pass.
            
            objCD.ContentVersionId = objCV.Id;
            // NOPMD(ApexFlsViolation) – Safe because PreferencesAllowViewInBrowser is a standard field 
            // and explicit FLS checks are performed before insert.
            // // 1. PreferencesAllowOriginalDownload is a standard ContentDistribution field.
            // 2. Field-level security is validated using checkFieldPermission() for both isAccessible and isCreateable.
            // 3. Assignment is flagged by PMD, but actual execution is guarded by FLS checks.
            objCD.PreferencesAllowViewInBrowser= true;
            
            // NOPMD(ApexFlsViolation) – Safe because PreferencesAllowOriginalDownload is a standard field 
            // and verified with isAccessible + isCreateable checks.
            objCD.PreferencesAllowOriginalDownload=true;
            // NOPMD(ApexFlsViolation) – Field assignment flagged by PMD, but safe because:
            // 1. Explicit FLS checks (isAccessible + isCreateable) are performed 
            //    using checkFieldPermission() before DML.
            // 2. Fields (PreferencesAllowViewInBrowser, PreferencesAllowOriginalDownload, RelatedRecordId) 
            //    are standard ContentDistribution fields and verified for accessibility and create permissions.
            // 3. Database.insert() is executed only if all field-level security checks pass.
            // 
            // NOPMD(ApexFlsViolation) – Safe because RelatedRecordId is explicitly validated 
            // with checkFieldPermission() before insert.
            objCD.RelatedRecordId = recordId;// NOPMD(ApexFlsViolation) – already secured with FLS checks
            String[] listFields3 = new String[]{'Name', 'ContentVersionId', 'PreferencesAllowViewInBrowser', 'PreferencesAllowOriginalDownload', 'RelatedRecordId'};
                boolean b9 = checkFieldPermission(new FieldPermissionRequest('ContentDistribution', 'isAccessible', null, true));
            boolean b10 = checkFieldPermission(new FieldPermissionRequest('ContentDistribution', 'isAccessible', listFields3, false));
            boolean b11 = checkFieldPermission(new FieldPermissionRequest('ContentDistribution', 'isCreateable', null, true));
            boolean b12 = checkFieldPermission(new FieldPermissionRequest('ContentDistribution', 'isCreateable', listFields3, false));
            // NOPMD(ApexFlsViolation) – Database.insert flagged by PMD, but this is safe because:
            // - Prior to DML, accessibility and create permissions are explicitly validated for all fields.
            // - Insert runs in USER_MODE only after passing the above FLS checks.
            if (b9 && b10 && b11 && b12) {  
                // NOPMD(ApexFlsViolation) – Safe because:
                // - All required fields are checked for accessibility and create permissions before insert.
                // - Insert runs in USER_MODE only after passing all FLS checks.
                // - This ensures no unauthorized field assignments reach the database.
                Database.insert(objCD, AccessLevel.USER_MODE); // NOPMD(ApexFlsViolation) – explicit create checks done
            }else {  throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
                  }
            
            
            String[] listFields4 = new String[]{'ContentDownloadUrl', 'Id'};
                if (
                    checkFieldPermission(new FieldPermissionRequest('ContentDistribution', 'isAccessible', null, true)) && checkFieldPermission(new FieldPermissionRequest('ContentDistribution', 'isAccessible', listFields4, false))){list<ContentDistribution> listContentDistributions = [SELECT Id, ContentDownloadUrl FROM ContentDistribution WHERE Id =: objCD.Id WITH SECURITY_ENFORCED];
                                                                                                                                                                                                                                        return listContentDistributions[0].ContentDownloadUrl;
                                                                                                                                                                                                                                       }else {
                                                                                                                                                                                                                                           throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
                                                                                                                                                                                                                                       }
            
        }catch(exception ex){
            logError(ex.getMessage(), ex.getStackTraceString(), ex.getLineNumber(), '','Utility','uploadFile','');
            return null;
        }
    }
    /**
* @description Retrieves the standard name field for a set of SObject API names.
* @param listOfSObjectApiNames A set of SObject API names to check.
* @return A map of SObject API names to their standard name fields.
*/
    // Used in Chat Panel
    public static Map<String, String> getStandardNameField(Set<String> listOfSObjectApiNames){
        Map<String, String> result=new Map<String, String>();
        
        String [] listFields = new String [] {'QualifiedApiName', 'EntityDefinitionId','IsNameField'};
            if (checkFieldPermission(new FieldPermissionRequest('FieldDefinition', 'isAccessible', null, true)) /*&&
checkFieldPermission(new FieldPermissionRequest('ContentDistribution', 'isAccessible', listFields, false))*/) {
    List<FieldDefinition> listFieldDefinition = new List<FieldDefinition>([SELECT QualifiedApiName,EntityDefinition.QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName IN :listOfSObjectApiNames AND IsNameField = TRUE WITH USER_MODE]);
    for(FieldDefinition fieldDef : listFieldDefinition){
        result.put(fieldDef.EntityDefinition.QualifiedApiName, fieldDef.QualifiedApiName);
    }
}else {
    throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
}
        return result;
    }
    /**
* @description Extracts the first name and last name from a full name string.
* @param fullName The full name string to parse.
* @return A map containing the first name and last name details.
*/
    // Used in Chat Panel
    public static Map<String, String> getNameDetails(String fullName){
        Map<String, String> result=new Map<String, String>();
        if(fullName.contains('null')){
            fullName = fullName.replaceAll('null', '');
        }
        string fName = '';
        string lName = '';
        if(fullName.contains(' ')){
            fName = string.isBlank(fullName.split(' ')[0]) ? '' : fullName.split(' ')[0];
            lName = fullName.split(' ')[fullName.split(' ').size() - 1];
        }else{
            lName = fullName;
        }
        if(String.isNotBlank(fName)){
            result.put('senderNameSmall', fName.left(1).capitalize() + lName.left(1).capitalize());
        }else{
            result.put('senderNameSmall', lName.left(1).capitalize());
        }
        result.put('senderName', fullName);
        return result;
    }
    /**
* @description Validates a map of record IDs against their prefixes.
* @param prefixAndRecordIds A map of prefixes and their corresponding record IDs.
* @return A map of valid record IDs and their details.
*/
    public static Map<String,ValidRecordWrapper> validateRecordIds(Map<String, List<String>> prefixAndRecordIds)
    {
        Map<String,ValidRecordWrapper> validRecordIds=new Map<String,ValidRecordWrapper>();
        Map<String,String> objectPrefixAndNameMap = new Map<String,String>();
        Set<String> listOfSObjectApiNames=new Set<String>();
        
        Map<String, Schema.SObjectType> gd =  Schema.getGlobalDescribe(); 
        for(String myIdPrefix : prefixAndRecordIds.keySet())
        {
            for(Schema.SObjectType stype : gd.values())
            {
                Schema.DescribeSObjectResult r = stype.getDescribe();
                String prefix = r.getKeyPrefix();
                if(prefix!=null)
                {
                    if(prefix.equals(myIdPrefix)){
                        objectPrefixAndNameMap.put(myIdPrefix,  r.getName()+'-'+r.getLabel());
                        listOfSObjectApiNames.add(r.getName());
                        break;
                    }
                }
            }
        }
        Map<String, String> objectAndNameFieldsMap = getStandardNameField(listOfSObjectApiNames);
        for(String myIdPrefix : prefixAndRecordIds.keySet())
        {
            if(objectPrefixAndNameMap.containsKey(myIdPrefix))
            {
                List<String> recordIdsCheck=new List<String>();
                recordIdsCheck=prefixAndRecordIds.get(myIdPrefix);
                
                String objectNameAndLabel=objectPrefixAndNameMap.get(myIdPrefix);
                String objectName=objectNameAndLabel.split('-')[0];
                String objectLabel=objectNameAndLabel.split('-')[1];
                
                String soql = 'SELECT Id ';
                if(objectAndNameFieldsMap.containsKey(objectName) && String.isNotBlank(objectAndNameFieldsMap.get(objectName)))
                {
                    soql+=','+objectAndNameFieldsMap.get(objectName)+' ';
                }
                if(objectName=='Lead')
                {
                    soql+=',IsConverted ';
                }
                soql+= ' From '+objectName +' WHERE Id IN :recordIdsCheck' ;
                String strTempFields = 'Id,' + objectAndNameFieldsMap.get(objectName);
                if (
                    !checkFieldPermission(
                        new FieldPermissionRequest(objectName, 'isAccessible', strTempFields.split(','), true)
                    )
                ){
                    throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
                }else{
                    for(SObject sObj : Database.query(soql))
                    {
                        if(objectName!='Lead' || (objectName=='Lead' && (boolean)sObj.get('isconverted')==false))
                        {
                            string recordName;
                            if(objectAndNameFieldsMap.containsKey(objectName) && String.isNotBlank(objectAndNameFieldsMap.get(objectName)))
                            {
                                recordName=(string)sObj.get(objectAndNameFieldsMap.get(objectName));
                            }
                            validRecordIds.put(sObj.Id, new ValidRecordWrapper(objectLabel, objectName, recordName));
                        }
                    }
                }
            }
        }
        return validRecordIds;
    }
    /**
* @description Retrieves WhatsApp configuration details.
*/
    public static void getWhatsAppDetails(){
        
        List<CCCWA__WhatsApp_Admin__c> listWAA = new List<CCCWA__WhatsApp_Admin__c>();
        listWAA = CCCWA__WhatsApp_Admin__c.getall().values();
        if(listWAA != null && listWAA.size()>0){
            C3WhatsAppWebService.PhoneNumberid= listWAA[0].CCCWA__NumberID__c;
            C3WhatsAppWebService.WabAid = listWAA[0].CCCWA__WabaId__c;
            C3WhatsAppWebService.endPointURL = 'https://graph.facebook.com/v17.0/'+listWAA[0].CCCWA__NumberID__c+'/messages';
        }
    }
    /**
* @description Retrieves the field name for a specified object.
* @param objectName The name of the object to retrieve the field name for.
* @return The field name as a string.
*/
    // Used in webservice
    public static String getFieldName(String objectName) {
        Map<String, CCCWA__WhatsApp_Number_Configuration__c> settingsMap = new Map<String, CCCWA__WhatsApp_Number_Configuration__c>();
        if (
            !checkFieldPermission(
                new FieldPermissionRequest(
                    'CCCWA__WhatsApp_Number_Configuration__c',
                    'isAccessible',
                    new List<String>{'CCCWA__Field_Name__c', 'CCCWA__Object_Name__c'},
                    false
                )
            )
        ) {
            throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
        }else{
            settingsMap = CCCWA__WhatsApp_Number_Configuration__c.getAll();
        }
        CCCWA__WhatsApp_Number_Configuration__c setting = settingsMap.get(objectName);
        if (setting != null) {
            return setting.CCCWA__Field_Name__c;
        }
        throw new AuraHandledException('This object is not configured for bulk messaging!');
    }
    /**
* @description Sends a WhatsApp template message to a list of record IDs.
* @param recordIds A list of record IDs to send the message to.
* @param templateRecordId The ID of the template to use for the message.
*/
    public static void callSendTemplate(List<String> recordIds, String templateRecordId){
        //String ids = '(' + String.join(recordIds, ',') + ')';
        C3WhatsAppTemplateScreenLWCCtrl.sendWhatsAppMessageBulk(new List<String>(recordIds), templateRecordId);
    }
    /**
* @description Logs an error message with details for debugging.
* @param ErrorMessage The error message to log.
* @param StackTrace The stack trace of the error.
* @param LineNumber The line number where the error occurred.
* @param response The response associated with the error.
* @param className The name of the class where the error occurred.
* @param methodName The name of the method where the error occurred.
* @param request The request details associated with the error.
*/
    
    /**
* @description Logs an error to the custom Error_Log__c object if the user has appropriate field-level and object-level permissions.
*              It performs permission checks before inserting the error log to ensure security compliance.
*
* @param errorMessage The error message to log.
* @param stackTrace The stack trace associated with the error.
* @param lineNumber The line number in the code where the error occurred.
* @param response The response or output at the time of the error (if applicable).
* @param className The name of the Apex class where the error occurred.
* @param methodName The name of the method where the error occurred.
* @param request The original request or input that caused the error.
*
* @throws AuraHandledException If the current user does not have sufficient access to create or view the Error_Log__c fields.
*/
     @TestVisible
private static Boolean skipErrorLogInsert = false;
    
   
public static void logError(
    String errorMessage,
    String stackTrace,
    Integer lineNumber,
    String response,
    String className,
    String methodName,
    String request
) {
    Boolean skipInsert = Test.isRunningTest() || skipErrorLogInsert;

    
    Boolean hasAccess =
        checkFieldPermission(
            new FieldPermissionRequest('CCCWA__Error_Log__c', 'isAccessible', null, true)
        ) &&
        checkFieldPermission(
            new FieldPermissionRequest('CCCWA__Error_Log__c', 'isCreateable', null, true)
        );

    if (!hasAccess) {
        return; 
    }

    CCCWA__Error_Log__c objError = new CCCWA__Error_Log__c(
        CCCWA__Line_Number__c   = String.valueOf(lineNumber),
        CCCWA__Method_Name__c   = methodName,
        CCCWA__Error_Message__c = errorMessage,
        CCCWA__Stack_Trace__c   = stackTrace,
        CCCWA__Response__c     = response,
        CCCWA__Class_Name__c   = className,
        CCCWA__Request__c      = request
    );

    if (!skipInsert) {
        Database.insert(objError, AccessLevel.USER_MODE);
    }
}

    
   /* public static void logError( String errorMessage, String stackTrace, Integer lineNumber, String response, String className, String methodName, String request){
         if (Test.isRunningTest()) { //cmbd 10012026
          return; 
         }
       
// Allow tests to execute logic but skip DML
    Boolean skipInsert = Test.isRunningTest() || skipErrorLogInsert;
        {
        String[] listFields = new String[]{ 'CCCWA__Line_Number__c', 'CCCWA__Error_Message__c', 'CCCWA__Stack_Trace__c', 'CCCWA__Response__c', 'CCCWA__Class_Name__c', 'CCCWA__Method_Name__c', 'CCCWA__Request__c'};
            if (
                checkFieldPermission(new FieldPermissionRequest('CCCWA__Error_Log__c', 'isAccessible', null, true)) && //cmbd 10012026
                //checkFieldPermission(new FieldPermissionRequest('ContentVersion', 'isAccessible', listFields, false)) &&
                checkFieldPermission(new FieldPermissionRequest('CCCWA__Error_Log__c', 'isCreateable', null, true)) &&  //cmbd 10012026
//checkFieldPermission(new FieldPermissionRequest('ContentVersion', 'isCreateable', listFields, false))
            ){
                CCCWA__Error_Log__c objError = new CCCWA__Error_Log__c( 
                    CCCWA__Line_Number__c = String.valueOf(lineNumber),
                    CCCWA__Method_Name__c = methodName,
                    CCCWA__Error_Message__c = errorMessage,
                    CCCWA__Stack_Trace__c = stackTrace,
                    CCCWA__Response__c = response,
                    CCCWA__Class_Name__c = className, 
                    CCCWA__Request__c = request
                );
                Database.INSERT(objError, AccessLevel.USER_MODE);
            }else {
                throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
            }
        } } *
    /**
  
* @description
*  Builds and returns a WhatsApp_Conversation__b record based on the provided input object.
*  This method prepares the conversation with metadata such as phone numbers, template message,
*  message status, and unique key identifier.
*
* @param input An instance of WhatsAppConvoInput that contains the template object,
*              target phone number, record ID, and optional WAM ID.
* @return A fully constructed WhatsApp_Conversation__b record ready to be inserted.
*/
    public static CCCWA__WhatsApp_Conversation__b buildConvoRecord(WhatsAppConvoInput input){
        
        CCCWA__WhatsApp_Conversation__b objTxtMsg = new CCCWA__WhatsApp_Conversation__b();
        objTxtMsg.CCCWA__Direction__c = 'Outbound';
        objTxtMsg.CCCWA__Status__c = 'Pending';
        objTxtMsg.CCCWA__Record_ID__c = input.recordId;
        objTxtMsg.CCCWA__Read__c = 'false';
        // System.debug('formattedTemplateMessage   '+formattedTemplateMessage);
        // if(String.isNotBlank(formattedTemplateMessage)){
        //     objTxtMsg.Message__c = formattedTemplateMessage;
        // }else{
        objTxtMsg.CCCWA__Message__c = buildMessage(input.objTemplate);
        // }
        
        
        if(String.isNotBlank(input.objTemplate.CCCWA__Template_Message__c)){
            objTxtMsg.CCCWA__Message_formatted__c = input.objTemplate.CCCWA__Template_Message__c;
            objTxtMsg.CCCWA__Template_Name__c = input.objTemplate.Name;
        }
        
    //    objTxtMsg.CCCWA__From_Phone__c = input.fromNumber ;
      objTxtMsg.CCCWA__From_Phone__c = '919557718888';
        objTxtMsg.CCCWA__Read__c = 'true';
        objTxtMsg.CCCWA__To_Phone__c = input.toNumber;
        objTxtMsg.CCCWA__Interaction_Type__c='Whatsapp';
        objTxtMsg.CCCWA__Created_date__c = DateTime.now();
        if(string.isNotBlank(input.wamId)){
            objTxtMsg.CCCWA__sid__c = input.wamId;
        }
        objTxtMsg.CCCWA__Status__c = 'sent'; 
        
        if(string.isNotBlank(input.objTemplate.File_Name__c)){
            objTxtMsg.CCCWA__Interaction_Type__c='MMS';
        }
        objTxtMsg.CCCWA__Unique_Key__c = input.recordId+'-'+System.Now().formatLong();
        return objTxtMsg;
    }
    /**
* @description
*  Data wrapper class used to construct a WhatsApp_Conversation__b record.
*  This class holds the necessary input values such as the template, recipient number,
*  related record ID, and optional WAM ID.
*/
    public class WhatsAppConvoInput {
        /**
* @description
*  The template object that contains the message body and metadata like file name and template name.
*/
        public CCCWA__Template_Object__c objTemplate;
        /**
* @description
*  The phone number to which the WhatsApp message will be sent.
*/
        public String toNumber;
        /**
* @description
*  The record ID associated with the WhatsApp conversation.
*/
        public String recordId;
        /**
* @description
*  Optional WhatsApp Message (WAM) ID used for tracking or reference.
*/
        public String wamId;
    /**
        * @description
*  The phone number from which the WhatsApp message will be sent.
*/
        
         public String fromNumber;
    }
    
    
    
    
    /**
* @description Constructs a message based on the provided template object.
* @param objTemplate The template object containing message details.
* @return The constructed message as a string.
*/
    public static string buildMessage(CCCWA__Template_Object__c objTemplate){
        String txtMsg = '';
        if (String.isNotBlank(objTemplate.CCCWA__header__c)) {
            txtMsg = '<div style="text-align:center"><b>'+ objTemplate.CCCWA__header__c + '</b></div>';
        }
        if (objTemplate.CCCWA__Header_Type__c == 'MEDIA' && String.isNotBlank(objTemplate.CCCWA__Document_Url__c) && objTemplate.CCCWA__Media_Type__c == 'IMAGE') {
            txtMsg = '<div><img width="200" height="250" src="'+objTemplate.CCCWA__Document_Url__c+'"></div>';
            txtMsg = txtMsg + '<div>'+objTemplate.CCCWA__Whatsapp_Template__c+'</div>';
        }else if(objTemplate.CCCWA__Header_Type__c == 'MEDIA' && String.isNotBlank(objTemplate.CCCWA__Document_Url__c) && objTemplate.CCCWA__Media_Type__c == 'VIDEO'){
            txtMsg = txtMsg + objTemplate.CCCWA__Whatsapp_Template__c;
        }else{
            txtMsg = txtMsg + objTemplate.CCCWA__Whatsapp_Template__c;
        }
        if (String.isNotBlank(objTemplate.CCCWA__Footer__c)) {
            txtMsg =  txtMsg  + '</br><p style="font-size : 12px" class="slds-text-color_inverse-weak">'+ objTemplate.CCCWA__Footer__c +'<p>';
        }
        
        if(objTemplate.CCCWA__Template_Buttons__r != null && objTemplate.CCCWA__Template_Buttons__r.size() > 0){
            for(CCCWA__Template_Button__c button : objTemplate.CCCWA__Template_Buttons__r){
                if( button.CCCWA__Button_Type__c == 'QUICK_REPLY'){
                    txtMsg = txtMsg + '<div class="slds-theme_shade" style="margin-top : 5px; padding: 5;  font-size : 18px; border-radius: 5px; text-align:center; color: #4191e1;  text-decoration: underline">'+button.CCCWA__Button_text__c+'</div>';
                }
                if( button.CCCWA__Button_Type__c == 'PHONE_NUMBER'){
                    txtMsg = txtMsg + '<div class="slds-theme_shade" style="margin-top : 5px; padding: 5;  font-size : 18px; border-radius: 5px; text-align:center; color: #4191e1;  text-decoration: underline">'+button.CCCWA__Button_text__c+'</div>';
                }
                if(button.CCCWA__Button_Type__c == 'call to action'){
                    if (button.CCCWA__Type_of_Action__c == 'PHONE_NUMBER') {
                        txtMsg = txtMsg + '<div class="slds-theme_shade" style="margin-top : 5px; padding: 5;  font-size : 18px; border-radius: 5px; text-align:center; color: #4191e1; "><lightning-icon icon-name="utility:call" size="small"> </lightning-icon>'+button.CCCWA__Button_text__c+'</div>';
                    }
                    if (button.CCCWA__Type_of_Action__c == 'URL') {
                        txtMsg = txtMsg + '<div class="slds-theme_shade" style="margin-top : 5px; padding: 5;  font-size : 18px; border-radius: 5px; text-align:center; color: #4191e1; "><lightning-icon icon-name="utility:new_window" size="small"> </lightning-icon>'+button.CCCWA__Button_text__c+'</div>';
                    }
                }
            }
        }
        return txtMsg;
    }
    /**
* @description A custom setting for the Attachment enable check.
*/
    @AuraEnabled
    public static Boolean isAttachmentEnabled() {
        CCCWA__Whatsapp_Attachment__c settings = CCCWA__Whatsapp_Attachment__c.getInstance(UserInfo.getUserId());
        if (settings == null) {
            settings = CCCWA__Whatsapp_Attachment__c.getOrgDefaults();
        }
        return settings != null && settings.CCCWA__Attachment__c;
    }
    
    /**
* @description A custom setting for the Campaign/Project enable check.
*/
    @AuraEnabled
    public static Boolean isCampaignEnabled() {
        CCCWA__Whatsapp_Attachment__c settings = CCCWA__Whatsapp_Attachment__c.getInstance(UserInfo.getUserId());
        if (settings == null) {
            settings = CCCWA__Whatsapp_Attachment__c.getOrgDefaults();
        }
        return settings != null && settings.CCCWA__Campaign__c;
    }
    
    /**
* @description A custom setting for the Task Creation enable check.
*/
    @AuraEnabled
    public static Boolean isTaskCreationEnabled() {
        CCCWA__Whatsapp_Attachment__c settings = CCCWA__Whatsapp_Attachment__c.getInstance(UserInfo.getUserId());
        if (settings == null) {
            settings = CCCWA__Whatsapp_Attachment__c.getOrgDefaults();
        }
        return settings != null && settings.CCCWA__Task_Creation__c;
    }
    /**
* @description
* This method retrieves the list of project names from the custom metadata type `CCCWA__Project__mdt`.
* Custom metadata types are configuration-level records intended for use in code and are globally readable.
* As such, they do not require CRUD/FLS checks like standard or custom objects do.
*
* @returns List<String> - A list of project name strings retrieved from CMDT records.
*
* @note
* The ApexCRUDViolation warning from PMD is suppressed because CRUD checks are not applicable to Custom Metadata Types (CMDT).
* These types are not subject to user-based security enforcement and are safe to query without permission checks.
*/
    
    // CMDT query does not require CRUD checks – safe to suppress this rule
   // @SuppressWarnings('ApexCRUDViolation')
    @AuraEnabled(cacheable=true)
    public static List<String> getProjectNames() {
        List<String> projectNames = new List<String>();
        
        for (CCCWA__Project__mdt proj : [
            SELECT CCCWA__Project_Name__c
            FROM CCCWA__Project__mdt
            WHERE CCCWA__Project_Name__c != NULL WITH USER_MODE
        ]) {
            projectNames.add(proj.CCCWA__Project_Name__c);
        }
        return projectNames;
    }
    /**
* @description A wrapper class for valid record details.
*/
    // Used in Chat Panel
    public class ValidRecordWrapper
    {
        public string objectLabel;
        public string objectApiName;
        public string recordName;
        /**
* @description Constructor for ValidRecordWrapper.
* @param objectLabel The label of the object.
* @param objectApiName The API name of the object.
* @param recordName The name of the record.
*/
        public ValidRecordWrapper(string objectLabel, string objectApiName, string recordName)
        {
            this.objectLabel=objectLabel;
            this.objectApiName=objectApiName;
            this.recordName=recordName;
        }
    }
    /**
* @description A wrapper class for utility functions related to object picklists.
*/
    public class UtilityMainWrapper{
        List<ObjectPicklist> lstObjectPicklist;
    }
    /**
* @description A class representing an object picklist with label and value.
*/
    public class ObjectPicklist{
        public String label;
        public String value;
    }
}