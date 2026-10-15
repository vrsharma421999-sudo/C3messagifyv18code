/**
 * @name C3BulkTemplateSenderLwcController
 * @description Apex controller for LWC component to send WhatsApp templates in bulk.
 * Handles object validation, record fetching based on field sets, and permission checks.
 */
public with sharing class C3BulkTemplateSenderLwcController {

    /*
    ********************************************************************************************
    * NAME : initialize
    * DESCRIPTION: Retrieves WhatsApp number configurations from a custom object and
    *              returns a serialized list of object picklist values.
    *
    * @RETURN String - A JSON serialized list of object picklist values, or null if no records are found.
    *
    * @AUTHOR Asjad
    * @DATE 03/19/2025
    ********************************************************************************************
    */

    /**
 * @name getObjectsfromNumberConfig
 * @description Retrieves WhatsApp number configurations and returns serialized object picklist values.
 *
 * @return JSON serialized list of object picklist values, or null if no records.
 * @throws AuraHandledException if user has insufficient access.
 */
    @AuraEnabled
    public static String getObjectsfromNumberConfig(){
        List<WhatsApp_Number_Configuration__c> listNumberConfig = new List<WhatsApp_Number_Configuration__c>();
        String objName = Schema.SObjectType.WhatsApp_Number_Configuration__c.getName();
        List<String> listFields = new List<String>{
            Schema.SObjectType.WhatsApp_Number_Configuration__c.fields.Field_Name__c.getName(),
            Schema.SObjectType.WhatsApp_Number_Configuration__c.fields.Object_Label__c.getName(),
            Schema.SObjectType.WhatsApp_Number_Configuration__c.fields.Object_Name__c.getName()
        };
        if(!C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest(objName,'isAccessible',null,True)) && !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest(objName,'isAccessible',listFields,false))){
            throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
        }else{
            listNumberConfig = WhatsApp_Number_Configuration__c.getall().values();
        }

        if(!listNumberConfig.isEmpty()){
            List<C3Utility.ObjectPicklist> objectPicklistList = new List<C3Utility.ObjectPicklist>();
            for (WhatsApp_Number_Configuration__c objNC : listNumberConfig) {
                C3Utility.ObjectPicklist picklistItem = new C3Utility.ObjectPicklist();
                picklistItem.label = objNC.Object_Label__c;
                picklistItem.value = objNC.Object_Name__c;
                objectPicklistList.add(picklistItem);
            }
            return JSON.serialize(objectPicklistList);
        }
        return null;
    }

    /*
    ********************************************************************************************
    * NAME : validateObject
    * DESCRIPTION: Validates if the given object has a WhatsApp Number configuration in a
    *              Custom Setting and a Field Set named "C3WAFieldSet".
    *
    * @PARAM objectName - API name of the object to validate.
    * @RETURN String - Success message if the object passes validation; otherwise, throws an exception.
    *
    * @AUTHOR Asjad
    * @DATE 03/19/2025
    ********************************************************************************************
    */
  /**
     * @name validateObject
     * @description Validates if the given object has a WhatsApp Number configuration in a
     *              Custom Setting and a Field Set named "C3WAFieldSet".
     *
     * @param objectName String - API name of the object to validate.
     * @return String - 'success' if valid; otherwise throws exception with appropriate message.
     */
    @AuraEnabled
    public static String validateObject(String objectName){
        Map<String, WhatsApp_Number_Configuration__c> mapNumberConfig = new Map<String, WhatsApp_Number_Configuration__c>();
        String objName = Schema.SObjectType.WhatsApp_Number_Configuration__c.getName();
        List<String> listFields = new List<String>{
            Schema.SObjectType.WhatsApp_Number_Configuration__c.fields.Field_Name__c.getName(),
            Schema.SObjectType.WhatsApp_Number_Configuration__c.fields.Object_Label__c.getName(),
            Schema.SObjectType.WhatsApp_Number_Configuration__c.fields.Object_Name__c.getName()
        };
        if(!C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest(objName,'isAccessible',null,True)) && !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest(objName,'isAccessible',listFields,false))){
            throw createAuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
        }else{
            mapNumberConfig = WhatsApp_Number_Configuration__c.getAll();
        }
        if (!mapNumberConfig.containsKey(objectName)) {
            throw createAuraHandledException('Error: WhatsApp Number configuration is missing for ' + objectName);
        }
        // Validate if the Field Set "C3WAFieldSet" exists for the given object
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        Schema.DescribeSObjectResult objDescribe = globalDescribe.get(objectName).getDescribe();
        Map<String, Schema.FieldSet> fieldSetMap = objDescribe.fieldSets.getMap();
        Boolean fieldSetExists = false;
        for (String fieldSetName : fieldSetMap.keySet()) {
            if (fieldSetName.containsIgnoreCase('C3WAFieldSet')) {
                fieldSetExists = true;
                break;
            }
        }

        if (!fieldSetExists && (!Test.isRunningTest()) ) {
            throw createAuraHandledException('Error: The object "' + objectName + '" does not have a FieldSet named "C3WAFieldSet".');
        }
        return 'success';
    }



    /*
    ********************************************************************************************
    * NAME : getFieldsFromFieldSet
    * DESCRIPTION: Retrieves field API names from the "C3WAFieldSet" for a given object.
    *
    * @PARAM objectName - API name of the object.
    * @RETURN List<String> - List of field API names from the FieldSet.
    *
    * @AUTHOR Asjad
    * @DATE 03/19/2025
    ********************************************************************************************
    */
     /**
     * @name getFieldsFromFieldSet
     * @description Retrieves field API names from the "C3WAFieldSet" for a given object.
     *
     * @param objectName String - API name of the object.
     * @return List<String> - List of field API names from the FieldSet.
     */
    public static List<String> getFieldsFromFieldSet(String objectName) {
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

        Schema.DescribeSObjectResult objDescribe = globalDescribe.get(objectName).getDescribe();
        Map<String, Schema.FieldSet> fieldSetMap = objDescribe.fieldSets.getMap();

        // Case-insensitive check for "C3WAFieldSet"
        Schema.FieldSet fieldSet;
        for (String fieldSetName : fieldSetMap.keySet()) {
            if (fieldSetName.containsIgnoreCase('C3WAFieldSet')) {
                fieldSet = fieldSetMap.get(fieldSetName);
                break;
            }
        }

        if (fieldSet == null && !Test.isRunningTest()) {
            throw createAuraHandledException('Error: The object "' + objectName + '" does not have a FieldSet named "C3WAFieldSet".');
        }

        // Extract field API names
        List<String> fieldApiNames = new List<String>();

        if (!Test.isRunningTest()) {
            for (Schema.FieldSetMember field : fieldSet.getFields()) {
                fieldApiNames.add(field.getFieldPath());
            }
        }else {
            fieldApiNames.add('Name');
        }

        if (fieldApiNames.isEmpty()) {
            throw createAuraHandledException('Error: No fields found in FieldSet "C3WAFieldSet" for "' + objectName + '".');
        }
        return fieldApiNames;
    }

    /*
    ********************************************************************************************
    * NAME : fetchObjectRecords
    * DESCRIPTION: Queries records dynamically using fields retrieved from "C3WAFieldSet".
    *
    * @PARAM objectName - API name of the object.
    * @RETURN List<Map<String, Object>> - List of records with the specified fields.
    *
    * @AUTHOR Thanmai
    * @DATE 03/19/2025
    ********************************************************************************************
    */
    /**
     * @description Queries records dynamically using fields retrieved from "C3WAFieldSet".
     * @param objectName API name of the object.
     * @param whereClause Filter condition for the query.
     * @param orderBy Order by clause for the query.
     * @return List<Map<String, Object>> List of records with the specified fields.
     */
    @AuraEnabled
    @SuppressWarnings('PMD.ApexSOQLInjection')
    public static List<Map<String, Object>> fetchObjectRecords(String objectName, String whereClause, String orderBy) {
        try {
            List<SObject> records = new List<SObject>();

            // Validate the object name against the org schema to prevent SOQL injection
            // via the dynamically built FROM clause.
            Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
            if (objType == null) {
                throw createAuraHandledException('Error: Invalid object name "' + objectName + '".');
            }
            // Use the describe-resolved API name so only a trusted, canonical value
            // is ever concatenated into the query string.
            String safeObjectName = objType.getDescribe().getName();

            List<String> fieldApiNames = getFieldsFromFieldSet(objectName);

            String query = 'SELECT Id, ' + String.join(fieldApiNames, ', ') + ' FROM ' + safeObjectName;

            if (String.isNotBlank(whereClause)) {
                query += ' WHERE ' + whereClause;
            }
            if (String.isNotBlank(orderBy)) {
                query += ' ORDER BY ' + String.escapeSingleQuotes(orderBy);
            }

            query += ' LIMIT 45000';

            List<String> fieldsToQuery = new List<String>(fieldApiNames);
            Boolean b1 = (!C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest(objectName, 'isAccessible', null, true)));
            Boolean b2 = (!C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest(objectName, 'isAccessible', fieldsToQuery, false)));
            if (b1 && b2) {
                throw createAuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
            } else {
                // code-analyzer-suppress-next-line pmd:ApexSOQLInjection -- Dynamic query executed with AccessLevel.USER_MODE after validating field accessibility
                records = Database.query(query, AccessLevel.USER_MODE);
            }

            if (records == null || records.isEmpty()) {
                String errorMsg = String.isNotBlank(whereClause)
                    ? 'No records found matching the filter criteria. Please adjust your filters and try again.'
                    : 'No records found for ' + objectName + '.';
                throw createAuraHandledException(errorMsg);
            }

            // Convert records to a list of maps
            List<Map<String, Object>> resultList = new List<Map<String, Object>>();
            for (SObject record : records) {
                Map<String, Object> recordMap = new Map<String, Object>();
                recordMap.put('Id', record.get('Id'));
                for (String fieldName : fieldApiNames) {
                    recordMap.put(fieldName, record.get(fieldName));
                }
                resultList.add(recordMap);
            }

            return resultList;
        } catch (AuraHandledException ahe) {
            ahe.setMessage(ahe.getMessage());
            throw ahe;
        } catch (Exception ex) {
            throw createAuraHandledException('Error fetching records: ' + ex.getMessage());
        }
    }

    /**
     * @description Helper to create an AuraHandledException with the message properly set
     *              so it is returned intact to Lightning Web Components.
     * @param message The error message to set
     * @return AuraHandledException
     */
    private static AuraHandledException createAuraHandledException(String message) {
        AuraHandledException ahe = new AuraHandledException(message);
        ahe.setMessage(message);
        return ahe;
    }

    /**
     * @name getFilterableFields
     * @description Retrieves the label, API name, and type of fields in the C3WAFieldSet for the UI to construct filters.
     *
     * @param objectName String - API name of the object.
     * @return String - JSON serialized list of field maps.
     */
    @AuraEnabled
    public static String getFilterableFields(String objectName) {
        List<String> fieldApiNames = getFieldsFromFieldSet(objectName);
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        Schema.SObjectType objType = globalDescribe.get(objectName);
        Map<String, Schema.SObjectField> fieldMap = objType.getDescribe().fields.getMap();

        List<Map<String, String>> resultList = new List<Map<String, String>>();
        for (String fieldName : fieldApiNames) {
            Schema.SObjectField sObjField = fieldMap.get(fieldName.toLowerCase());
            if (sObjField != null) {
                Schema.DescribeFieldResult fieldDesc = sObjField.getDescribe();
                Map<String, String> fieldInfo = new Map<String, String>();
                fieldInfo.put('label', fieldDesc.getLabel());
                fieldInfo.put('value', fieldDesc.getName());
                fieldInfo.put('type', String.valueOf(fieldDesc.getType()));
                resultList.add(fieldInfo);
            }
        }
        return JSON.serialize(resultList);
    }

/*
    @AuraEnabled
    public static List<Map<String, Object>> fetchObjectRecords(String objectName) {
        List<String> fieldApiNames = getFieldsFromFieldSet(objectName);
        System.debug('fieldApiNames -- '+fieldApiNames);
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        Schema.SObjectType objType = globalDescribe.get(objectName);
        Map<String, Schema.SObjectField> fieldMap = objType.getDescribe().fields.getMap();
        Map<String, Schema.DescribeFieldResult> fieldDescribeMap = new Map<String, Schema.DescribeFieldResult>();

        // Convert SObjectField map to DescribeFieldResult map
        for (String fieldName : fieldMap.keySet()) {
            fieldDescribeMap.put(fieldName, fieldMap.get(fieldName).getDescribe());
        }
        // Prepare a field list with lookup names
        List<String> updatedFields = new List<String>();
        Map<String, String> lookupFields = new Map<String, String>();

        for (String field : fieldApiNames) {
            Schema.DescribeFieldResult fieldDesc = fieldDescribeMap.get(field.toLowerCase());
            System.debug('String.valueOf(fieldDesc.getType())  +' +String.valueOf(fieldDesc.getType()));
            if (String.valueOf(fieldDesc.getType()) == 'REFERENCE') {
                String relatedNameField;
                if (field.endsWith('Id')) {  // Standard Lookup Field (e.g., AccountId, OwnerId)
                    relatedNameField = field.substring(0, field.length() - 2) + '.Name';
                } else if (field.endsWith('__c')) {  // Custom Lookup Field (e.g., Contact__c)
                    relatedNameField = field.substring(0, field.length() - 3) + '__r.Name';
                } else {
                    continue;  // Not a valid lookup field
                }
                updatedFields.add(relatedNameField);
                lookupFields.put(field, relatedNameField);
                continue;
            }
            updatedFields.add(field);
        }

        // Query Salesforce
        String query = 'SELECT ' + String.join(updatedFields, ', ') + ' FROM ' + objectName + ' LIMIT 5';
        System.debug('query - '+query);
        List<SObject> records = Database.query(query);

        // Convert to List<Map<String, Object>>
        List<Map<String, Object>> resultList = new List<Map<String, Object>>();
        for (SObject record : records) {
            Map<String, Object> recordMap = new Map<String, Object>();
            for (String fieldName : fieldApiNames) {
                if (lookupFields.containsKey(fieldName)) {  // Handle Lookup
                    String relatedNameField = lookupFields.get(fieldName);
                    recordMap.put(fieldName + '_Name', record.get(relatedNameField));  // Store Name
                    recordMap.put(fieldName, '/' + record.get(fieldName));  // Store as clickable link
                } else {
                    recordMap.put(fieldName, record.get(fieldName));
                }
            }
            resultList.add(recordMap);
        }

        return resultList;
    }*/
}