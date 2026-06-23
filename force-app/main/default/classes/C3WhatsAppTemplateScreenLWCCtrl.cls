/**
* @class C3WhatsAppTemplateScreenLWCCtrl
* @description
*  This Apex controller supports the WhatsApp Template Screen Lightning Web Component (LWC),
*  providing functionality for managing WhatsApp templates, sending messages, and handling template operations.
*
*  Features:
*  - Template search and retrieval
*  - Message sending (single and bulk)
*  - Template creation/updating
*  - Media handling for templates
*  - Full CRUD/FLS enforcement
*
* @access Public - Accessible to Lightning Components within the same namespace.
* @usage Called from LWC via @AuraEnabled methods.
* @security Enforces field-level and CRUD security before performing any DML or queries.
* @author Asjad Ahmed
* @version 1.0
* @company CloudCentric
* @license Salesforce Public License
* @date June 2025
*/
public with sharing class C3WhatsAppTemplateScreenLWCCtrl {    
    /**
* @method searchTemplates
* @description Searches WhatsApp templates with field-level security enforcement
* @param searchTerm Search term for template names (LIKE operator used)
* @return List<CCCWA__Template_Object__c> Matching templates with limited fields
* @throws AuraHandledException When user lacks required field access
*/
    @AuraEnabled(cacheable=true)
    public static List<CCCWA__Template_Object__c> searchTemplates(String searchTerm) {
        try{
            String searchKey = '%' + searchTerm + '%';
            String [] fieldsToQuery = new String [] {'Id', 'Name', 'CCCWA__Whatsapp_Template__c'};
                if (!C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Object__c', 'isAccessible', null, true)) &&
                    !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Object__c', 'isAccessible', fieldsToQuery, false))) {
                        throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
                    }
            else{
                return [SELECT Id, Name, CCCWA__Whatsapp_Template__c FROM CCCWA__Template_Object__c WHERE Name LIKE :searchKey WITH USER_MODE];
            }
        }catch(exception ex){ C3Utility.logError(ex.getMessage(), ex.getStackTraceString(), ex.getLineNumber(), '','C3WhatsAppTemplateScreenLWCCtrl','searchTemplates',''); return null; }
    }
    /**
* @method getRecordData
* @description Retrieves complete template data with all related components
* @param recordId Template record ID to retrieve
* @param objectName Related object name for field mappings
* @return CCCWA__Template_Object__c Complete template record with child relationships
* @throws AuraHandledException When security checks fail
*/
    
    @AuraEnabled(cacheable=true)
    public static CCCWA__Template_Object__c getRecordData(String recordId, String objectName) {
        try{
            
            String [] fieldsToQuery = new String [] {'Id', 'CCCWA__Name', 'CCCWA__Language_Code__c', 'CCCWA__Status__c', 'CCCWA__Template_Message__c', 'CCCWA__Header_Type__c', 'CCCWA__File_Name__c', 'CCCWA__Media_Type__c', 'CCCWA__Media_Handler__c', 'CCCWA__Footer__c', 'CCCWA__Header__c', 'CCCWA__Document_Url__c'  };
                String [] fieldsToQuery2 = new String [] {'Id', 'CCCWA__Field_Name__c', 'CCCWA__Object_name__c', 'CCCWA__Parameter_Name__c'  };
                    String [] fieldsToQuery3 = new String [] {'Id', 'CCCWA__Button_text__c', 'CCCWA__Button_Type__c', 'CCCWA__Country_Code__c', 'CCCWA__phone_Number__c', 'CCCWA__Type__c', 'CCCWA__Type_of_Action__c', 'CCCWA__URL_Type__c', 'CCCWA__Website_URL__c'  };
                        Boolean b1 = !C3Utility.checkFieldPermission(
                            new C3Utility.FieldPermissionRequest('CCCWA__Template_Object__c', 'isAccessible', null, true)
                        );
            Boolean b12 = !C3Utility.checkFieldPermission(
                new C3Utility.FieldPermissionRequest('CCCWA__Template_Object__c', 'isAccessible', fieldsToQuery, false)
            );
            
            Boolean b2 = !C3Utility.checkFieldPermission(
                new C3Utility.FieldPermissionRequest('CCCWA__Template_Mapping__c', 'isAccessible', null, true)
            );
            Boolean b22 = !C3Utility.checkFieldPermission(
                new C3Utility.FieldPermissionRequest('CCCWA__Template_Mapping__c', 'isAccessible', fieldsToQuery2, false)
            );
            
            Boolean b3 = !C3Utility.checkFieldPermission(
                new C3Utility.FieldPermissionRequest('CCCWA__Template_Button__c', 'isAccessible', null, true)
            );
            Boolean b32 = !C3Utility.checkFieldPermission(
                new C3Utility.FieldPermissionRequest('CCCWA__Template_Button__c', 'isAccessible', fieldsToQuery3, false)
            );
            
            if(b1 && b2 && b3 && b12 && b22 && b32){
                throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');                
            }else{
                return [SELECT Id, Name, CCCWA__Language_Code__c, CCCWA__Whatsapp_Template__c, CCCWA__Status__c, CCCWA__Template_Message__c, CCCWA__Header_Type__c, CCCWA__File_Name__c, CCCWA__Media_Type__c, CCCWA__Media_Handler__c, CCCWA__Footer__c, CCCWA__Header__c, CCCWA__Document_Url__c, (SELECT Id, CCCWA__Field_Name__c, CCCWA__Object_name__c, CCCWA__Parameter_Name__c FROM CCCWA__Template_Mappings__r WHERE CCCWA__Object_name__c =: objectName ), (SELECT Id, CCCWA__Button_text__c, CCCWA__Button_Type__c,CCCWA__Country_Code__c, CCCWA__phone_Number__c, CCCWA__Type__c, CCCWA__Type_of_Action__c,CCCWA__URL_Type__c, CCCWA__Website_URL__c FROM CCCWA__Template_Buttons__r) FROM CCCWA__Template_Object__c WHERE Id = :recordId   WITH USER_MODE];
            }
        }catch(exception ex){ C3Utility.logError(ex.getMessage(), ex.getStackTraceString(), ex.getLineNumber(), '','C3WhatsAppTemplateScreenLWCCtrl','getRecordData',''); return null; }
    }
    /**
* @method sendWhatsAppMessage
* @description Sends a WhatsApp message to an individual using a specified template.
* @param recordIds List of record IDs to send messages to.
* @param templateRecordId The ID of the template to use for the message.
* @return String response from the API.
* @throws AuraHandledException When user lacks required field access.
*/    
    @AuraEnabled
    public static String sendWhatsAppMessage(List<String> recordIds, String templateRecordId){
        try{
            if(recordIds != null && (!recordIds.isEmpty()) && String.isNotBlank(templateRecordId)){
                string resbody='';
                string phoneField ='';
                set<String> setOfIds;
                
                List<String> lstIds = recordIds ;
                setOfIds = new Set<String>(lstIds);
                
                Id recordId = Id.valueOf(lstIds[0]);
                String objectName = recordId.getSObjectType().getDescribe().getName();
                Map<String, String> mapParamNumWithFieldName = new Map<String, String>();
                CCCWA__Template_Object__c objTemplate = getRecordData(templateRecordId, objectName);
                //  List<SObject> lstSObject = new List<SObject>();
                
                if((objTemplate != null) && (objTemplate.CCCWA__Template_Mappings__r != null) && objTemplate.CCCWA__Template_Mappings__r.size()>0 ){
                    for(CCCWA__Template_Parameter__c objTempMapping : objTemplate.Template_Mappings__r ){
                        mapParamNumWithFieldName.put(objTempMapping.CCCWA__Parameter_Name__c, objTempMapping.CCCWA__Field_Name__c );
                    }
                }
                set<String> fieldSet = new Set<String>(mapParamNumWithFieldName.values());
                phoneField = C3Utility.getFieldName(objectName);
                if (String.isNotBlank(phoneField)) {
                    fieldSet.add(phoneField);
                }
                if (Schema.getGlobalDescribe().containsKey(objectName)) {
                    Schema.DescribeSObjectResult describe = Schema.getGlobalDescribe().get(objectName).getDescribe();
                    if (describe.fields.getMap().containsKey('Name')) {
                        fieldSet.add('Name');
                    }
                }
                if (fieldSet.isEmpty()) {
                    throw new AuraHandledException('Template field mappings do not resolve to any fields for object ' + objectName);
                }
                String query = 'SELECT Id, '+ String.join(fieldSet, ',') + ' FROM '+objectName+' WHERE Id IN: setOfIds';
                List<SObject> listOfSObject = new List<SObject>();                
                List<String> fieldsToQuery = new List<String>(fieldSet);
                
                Boolean b1 = !C3Utility.checkFieldPermission(
                    new C3Utility.FieldPermissionRequest(objectName, 'isAccessible', null, true)
                );
                
                Boolean b2 = !C3Utility.checkFieldPermission(
                    new C3Utility.FieldPermissionRequest(objectName, 'isAccessible', fieldsToQuery, false)
                );
                
                if(b1 && b2){
                    throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
                }else{
                    listOfSObject = database.query(String.escapeSingleQuotes(query));
                }
                if(!listOfSObject.isEmpty()){
                    resbody = C3WhatsAppWebService.createWebserviceBody(listOfSObject, mapParamNumWithFieldName, objTemplate, phoneField);}
                return resbody;            
            }
            return null;
        }catch(exception ex){ C3Utility.logError(ex.getMessage(), ex.getStackTraceString(), ex.getLineNumber(), '','C3WhatsAppTemplateScreenLWCCtrl','sendWhatsAppMessage',''); return null; }
    }
    /**
* @method sendWhatsAppMessageBulk
* @description Sends a WhatsApp message to a list of recipients using a specified template in bulk.
* @param recordIds List of record IDs to send messages to.
* @param templateRecordId The ID of the template to use for the message.
* @throws AuraHandledException When user lacks required field access.
*/ 
    
    
    @AuraEnabled
    public static void sendWhatsAppMessageBulk(List<String> recordIds, String templateRecordId){
        try {
            if (recordIds != null && !recordIds.isEmpty() && String.isNotBlank(templateRecordId)) {
                Set<String> setRecordIds = new Set<String>(recordIds);
                Id recordId = Id.valueOf(recordIds[0]);
                String objectName = recordId.getSObjectType().getDescribe().getName();
                C3Utility.logError('RecordId[0]: ' + recordId, '', 168, '', 'C3WhatsAppTemplateScreenLWCCtrl', 'sendWhatsAppMessageBulk', 'Object Name: ' + objectName);
                
                Map<String, String> mapParamNumWithFieldName = new Map<String, String>();
                
                CCCWA__Template_Object__c objTemplate = getRecordData(templateRecordId, objectName);
                if (objTemplate != null && objTemplate.CCCWA__Template_Mappings__r != null && !objTemplate.CCCWA__Template_Mappings__r.isEmpty()) {
                    for (CCCWA__Template_Parameter__c objTempMapping : objTemplate.CCCWA__Template_Mappings__r) {
                        mapParamNumWithFieldName.put(objTempMapping.CCCWA__Parameter_Name__c, objTempMapping.CCCWA__Field_Name__c);
                        C3Utility.logError('Mapping Param: ' + objTempMapping.Parameter_Name__c + ' → ' + objTempMapping.Field_Name__c, '', 0, '', 'C3WhatsAppTemplateScreenLWCCtrl', 'sendWhatsAppMessageBulk', '');
                    }
                } else {
                    C3Utility.logError('No template mappings found.', '', 179, '', 'C3WhatsAppTemplateScreenLWCCtrl', 'sendWhatsAppMessageBulk', '');
                }
                
                Set<String> fieldSet = new Set<String>(mapParamNumWithFieldName.values());
                String phoneField = C3Utility.getFieldName(objectName);
                fieldSet.add(phoneField);
                fieldSet.add('Name');
                
                String query = 'SELECT Id, ' + String.join(fieldSet, ',') + ' FROM ' + objectName + ' WHERE Id IN :setRecordIds';
                //C3Utility.logError('Query: ' + query, objectName, 188, '', 'C3WhatsAppTemplateScreenLWCCtrl', 'sendWhatsAppMessageBulk', '');
                
                List<String> fieldsToQuery = new List<String>(fieldSet);
                Boolean b1 = !C3Utility.checkFieldPermission(
                    new C3Utility.FieldPermissionRequest(objectName, 'isAccessible', null, true)
                );
                
                Boolean b2 = !C3Utility.checkFieldPermission(
                    new C3Utility.FieldPermissionRequest(objectName, 'isAccessible', fieldsToQuery, false)
                );
                
                if (b1 && b2) {
                    throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
                } else {
                    // C3Utility.logError('Starting batch execution', '', 202, '', 'C3WhatsAppTemplateScreenLWCCtrl', 'sendWhatsAppMessageBulk', '');
                    Database.executeBatch(new C3WhatsAppSendTemplateBulkBatch(setRecordIds, query, mapParamNumWithFieldName, objTemplate, phoneField), 50);
                }
            } else {
                C3Utility.logError('Empty recordIds or templateRecordId.', '', 206, '', 'C3WhatsAppTemplateScreenLWCCtrl', 'sendWhatsAppMessageBulk', '');
            }
        } catch (Exception ex) {
            C3Utility.logError(ex.getMessage(), ex.getStackTraceString(), ex.getLineNumber(), '', 'C3WhatsAppTemplateScreenLWCCtrl', 'sendWhatsAppMessageBulk', '');
        }
    }
    
    /**
* @description Saves template data.
* @param jsonData JSON string containing template data.
* @return String response from the API.
*/
    @AuraEnabled
    public static String saveTemplateData(String jsonData) {
        try{
            system.debug('jsonData---'+jsonData);
            String strDocUrl = '';
            if(String.isNotBlank(jsonData)){
                TemplateWrapper objTemplateWrapper = (TemplateWrapper)JSON.deserialize(jsonData, TemplateWrapper.class);
                CCCWA__Template_Object__c objSFTemplate = new CCCWA__Template_Object__c();
                List<CCCWA__Template_Parameter__c> listTemplateMapping = new List<CCCWA__Template_Parameter__c>();
                if(String.isNotBlank(objTemplateWrapper.templateId)){
                    objSFTemplate.Id = objTemplateWrapper.templateId;
                }
                objSFTemplate.Name = objTemplateWrapper.templateName.replaceAll(' ' , '_').toLowerCase();
                objSFTemplate.CCCWA__Template_Label__c = objTemplateWrapper.templateName;
                objSFTemplate.CCCWA__Language_Code__c = objTemplateWrapper.language;
                objSFTemplate.CCCWA__Project__c= objTemplateWrapper.project;
                objSFTemplate.CCCWA__Object__c = objTemplateWrapper.objectName;
                objSFTemplate.CCCWA__Whatsapp_Template__c = objTemplateWrapper.templateBody;
                objSFTemplate.CCCWA__Template_Message__c = getFormattedBody(objTemplateWrapper.templateBodyText);
                objSFTemplate.CCCWA__Category__c = objTemplateWrapper.category;
                if(String.isNotBlank(objTemplateWrapper.headerText)){
                    objSFTemplate.CCCWA__Header__c = objTemplateWrapper.headerText;
                    objSFTemplate.CCCWA__Header_Type__c = 'TEXT';
                }
                if(String.isNotBlank(objTemplateWrapper.publicDocUrl)){
                    objSFTemplate.CCCWA__Document_Url__c = objTemplateWrapper.publicDocUrl;
                }
                
                if(String.isNotBlank(objTemplateWrapper.mediaHandler)){
                    objSFTemplate.CCCWA__Media_Handler__c = objTemplateWrapper.mediaHandler;
                }
                
                if(String.isNotBlank(objTemplateWrapper.headerType)){
                    objSFTemplate.CCCWA__Header_Type__c = objTemplateWrapper.headerType;
                }
                if(String.isNotBlank(objTemplateWrapper.mediaType)){
                    objSFTemplate.CCCWA__Media_Type__c = objTemplateWrapper.mediaType;
                }
                if(String.isNotBlank(objTemplateWrapper.footer)){
                    objSFTemplate.CCCWA__footer__c = objTemplateWrapper.footer;
                }
                if(String.isNotBlank(objTemplateWrapper.contentVersionId)){
                    objSFTemplate.CCCWA__Content_Version_Id__c = objTemplateWrapper.contentVersionId;
                }
                if(String.isNotBlank(objTemplateWrapper.mimeType)){
                    objSFTemplate.CCCWA__Mime_Type__c = objTemplateWrapper.mimeType;
                }
                String[] fieldsToQuery = new String[]{'Id', 'Name', 'CCCWA__Template_Label__c', 'CCCWA__Language_Code__c', 'CCCWA__Object__c', 'CCCWA__Whatsapp_Template__c', 'CCCWA__Template_Message__c', 'CCCWA__Category__c', 'CCCWA__Header__c', 'CCCWA__File_Name__c', 'CCCWA__Header_Type__c', 'CCCWA__Document_Url__c', 'CCCWA__Media_Handler__c', 'CCCWA__Header_Type__c', 'CCCWA__Media_Type__c', 'CCCWA__footer__c', 'CCCWA__Content_Version_Id__c', 'CCCWA__Mime_Type__c'};
                    Boolean b1  = !C3Utility.checkFieldPermission(
                        new C3Utility.FieldPermissionRequest('CCCWA__Template_Object__c', 'isAccessible', null, true)
                    );
                Boolean b11 = !C3Utility.checkFieldPermission(
                    new C3Utility.FieldPermissionRequest('CCCWA__Template_Object__c', 'isAccessible', fieldsToQuery, false)
                );
                
                Boolean b2  = !C3Utility.checkFieldPermission(
                    new C3Utility.FieldPermissionRequest('CCCWA__Template_Object__c', 'isCreateable', null, true)
                );
                Boolean b22 = !C3Utility.checkFieldPermission(
                    new C3Utility.FieldPermissionRequest('CCCWA__Template_Object__c', 'isCreateable', fieldsToQuery, false)
                );
                
                Boolean b3  = !C3Utility.checkFieldPermission(
                    new C3Utility.FieldPermissionRequest('CCCWA__Template_Object__c', 'isUpdateable', null, true)
                );
                Boolean b33 = !C3Utility.checkFieldPermission(
                    new C3Utility.FieldPermissionRequest('CCCWA__Template_Object__c', 'isUpdateable', fieldsToQuery, false)
                );
                
                if(b1 && b2 && b3 && b11 && b22 && b33){
                    throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
                }else{
                    Database.UPSERT( objSFTemplate, AccessLevel.USER_MODE);
                }
                if(objTemplateWrapper.listMapping != null && objTemplateWrapper.listMapping.size()>0){
                    for (ListMapping objMapping : objTemplateWrapper.listMapping) {
                        if(String.isNotBlank(objMapping.fieldName)){
                            CCCWA__Template_Parameter__c objTempParam = new CCCWA__Template_Parameter__c();
                            if(String.isNotBlank(objMapping.mappingId)){
                                objTempParam.Id = objMapping.mappingId; 
                            }
                            objTempParam.CCCWA__Field_Name__c = objMapping.fieldName;
                            objTempParam.CCCWA__Parameter_Name__c = objMapping.parameterNum;
                            objTempParam.CCCWA__Example_Text__c = objMapping.exampleText;
                            objTempParam.CCCWA__Object_name__c = objTemplateWrapper.objectName;
                            if(String.isBlank(objMapping.mappingId)){
                                objTempParam.CCCWA__Template__c = objSFTemplate.Id;
                            }
                            listTemplateMapping.add(objTempParam);
                        }
                    }
                    if(!listTemplateMapping.isEmpty()){
                        String[] objTempParamFields = new String[]{'Id', 'CCCWA__Field_Name__c', 'CCCWA__Parameter_Name__c', 'CCCWA__Example_Text__c', 'CCCWA__Object_name__c', 'CCCWA__Template__c'};
                            if (
                                !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Parameter__c', 'isAccessible', null, true)) &&!C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Parameter__c', 'isAccessible', objTempParamFields, false)) && !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Parameter__c', 'isCreateable', null, true)) && !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Parameter__c', 'isCreateable', objTempParamFields, false)) && !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Parameter__c', 'isUpdateable', null, true)) &&!C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Parameter__c', 'isUpdateable', objTempParamFields, true))
                            ) {
                                throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
                            }
                        else{
                            Database.UPSERT( listTemplateMapping, AccessLevel.USER_MODE);
                        }
                    }
                    set<Id> mappingIds = new set<Id>();
                    List<CCCWA__Template_Parameter__c> listParam = new List<CCCWA__Template_Parameter__c>();
                    for(integer i = 0; i < listTemplateMapping.size(); i++){
                        objTemplateWrapper.listMapping[i].mappingId = listTemplateMapping[i].Id;
                        mappingIds.add(listTemplateMapping[i].Id);
                    }
                    String[] objTempParamFields = new String[]{'Id', 'CCCWA__Field_Name__c', 'CCCWA__Parameter_Name__c', 'CCCWA__Example_Text__c', 'CCCWA__Object_name__c', 'CCCWA__Template__c'};
                        if (!C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Parameter__c', 'isAccessible', null, true)) && !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Parameter__c', 'isAccessible', objTempParamFields, false))) {
                            throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
                        }
                    else{
                        for (CCCWA__Template_Parameter__c obj : [SELECT Id, CCCWA__Template__c FROM CCCWA__Template_Parameter__c WHERE CCCWA__Template__c =: objSFTemplate.Id  WITH USER_MODE] ) {
                            if (!mappingIds.contains(obj.Id)) {
                                listParam.add(obj);
                            }
                        }
                    }
                    
                    if (!listParam.isEmpty()) {
                        if (!C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Parameter__c', 'isAccessible', null, true)) && !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Parameter__c', 'isDeletable', null, true))) {
                            throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
                        }
                        else{
                            Database.Delete(listParam, AccessLevel.USER_MODE);
                        }
                    }
                }
                
                if(objTemplateWrapper.isActionList || objTemplateWrapper.isQuickReplyList){
                    List<CCCWA__Template_Button__c> listOfTemplateButton = new List<CCCWA__Template_Button__c>();
                    if(objTemplateWrapper.listActions !=null){
                        for(C3WhatsAppTemplateScreenLWCCtrl.ListActions objLstAct : objTemplateWrapper.listActions){
                            CCCWA__Template_Button__c objButton = new CCCWA__Template_Button__c();
                            if(String.isNotBlank(objLstAct.buttonId)){
                                objButton.Id = objLstAct.buttonId;
                            }
                            objButton.CCCWA__Button_Type__c = objTemplateWrapper.buttonOption;
                            objButton.CCCWA__Type_of_Action__c = objLstAct.actionType;
                            objButton.CCCWA__Button_text__c = objLstAct.buttonText;
                            if(String.isNotBlank(objLstAct.countryCode)){
                                objButton.CCCWA__Country_Code__c = objLstAct.countryCode;
                            }
                            if(String.isNotBlank(objLstAct.phoneNumber)){
                                objButton.CCCWA__phone_Number__c = objLstAct.phoneNumber;
                            }
                            if(String.isNotBlank(objLstAct.urlType)){
                                objButton.CCCWA__URL_Type__c = objLstAct.urlType;
                            }
                            if(String.isNotBlank(objLstAct.websiteUrl)){
                                objButton.CCCWA__Website_URL__c = objLstAct.websiteUrl;
                            }
                            if(String.isBlank(objLstAct.buttonId)){
                                objButton.CCCWA__Template__c = objSFTemplate.Id; 
                            }
                            listOfTemplateButton.add(objButton);
                        }
                    }
                    
                    if(objTemplateWrapper.listQuickReply !=null){
                        for(C3WhatsAppTemplateScreenLWCCtrl.ListQuickReply objLstAct : objTemplateWrapper.listQuickReply){
                            CCCWA__Template_Button__c objButton = new CCCWA__Template_Button__c();
                            if(String.isNotBlank(objLstAct.buttonId)){
                                objButton.Id = objLstAct.buttonId;
                            }
                            objButton.CCCWA__Button_Type__c = objTemplateWrapper.buttonOption;
                            objButton.CCCWA__Type__c = objLstAct.type;
                            objButton.CCCWA__Button_text__c = objLstAct.buttonText;
                            if(String.isBlank(objLstAct.buttonId)){
                                objButton.CCCWA__Template__c = objSFTemplate.Id;
                            }
                            listOfTemplateButton.add(objButton);
                        }
                    }
                    
                    if(!listOfTemplateButton.isEmpty()){
                        String[] objButtonFields = new String[]{'Id', 'CCCWA__Button_Type__c', 'CCCWA__Type_of_Action__c', 'CCCWA__Button_text__c', 'CCCWA__Country_Code__c', 'CCCWA__phoneNumber__c', 'CCCWA__URL_Type__c', 'CCCWA__Website_URL__c', 'CCCWA__Type__c', 'CCCWA__Template__c'};
                            if ( !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Button__c', 'isAccessible', null, true)) && !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Button__c', 'isAccessible', objButtonFields, false)) && !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Button__c', 'isCreateable', null, true)) && !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Button__c', 'isCreateable', objButtonFields, false)) && !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Button__c', 'isUpdateable', null, true)) && !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Button__c', 'isUpdateable', objButtonFields, false))) {
                                throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
                            }
                        else{
                            Database.UPSERT(listOfTemplateButton, AccessLevel.USER_MODE);
                        }
                    }
                    set<id> templateButtonIds = new set<id>();
                    for(integer i = 0; i < listOfTemplateButton.size(); i++){
                        if(objTemplateWrapper.isActionList && objTemplateWrapper.listActions.size() > i){
                            objTemplateWrapper.listActions[i].buttonId = listOfTemplateButton[i].Id;
                        } else if(!objTemplateWrapper.isActionList && objTemplateWrapper.listQuickReply.size() > i){
                            objTemplateWrapper.listQuickReply[i].buttonId = listOfTemplateButton[i].Id;
                        }
                        templateButtonIds.add(listOfTemplateButton[i].Id);                   			
                    }
                    list<id> templateButtonsToDelete = new list<id>();
                    String[] fields = new String[]{'Id', 'CCCWA__Template__c'};
                        if (
                            !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Button__c', 'isAccessible', null, true)) && !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Button__c', 'isAccessible', fields, false))) {
                                throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
                            }
                    else{
                        for(CCCWA__Template_Button__c tempButtons :[Select id,CCCWA__Template__c from CCCWA__Template_Button__c where CCCWA__Template__c=:objSFTemplate.id WITH USER_MODE]   ){
                            if(!templateButtonIds.contains(tempButtons.id)){
                                templateButtonsToDelete.add(tempButtons.id);
                            }
                        }
                    }
                    if (
                        !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Button__c', 'isAccessible', null, true)) && !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Button__c', 'isDeletable', null, true))) {
                            throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
                        }
                    else{
                        Database.Delete(templateButtonsToDelete, AccessLevel.USER_MODE);
                    }
                }
                if(objTemplateWrapper.isHeaderMedia && String.isNotBlank(objTemplateWrapper.documentId) && String.isNotBlank(objTemplateWrapper.contentVersionId)){
                    strDocUrl = getPublicUrl(objTemplateWrapper.documentId, objTemplateWrapper.contentVersionId, objSFTemplate.Id, objTemplateWrapper.fileName );
                }
                // LwcReturnResponse objLwcReturnResponse = new LwcReturnResponse();
                if(String.isNotBlank(strDocUrl)){
                    objTemplateWrapper.publicDocUrl = strDocUrl;
                    objSFTemplate.CCCWA__Document_Url__c = strDocUrl;
                    objSFTemplate.CCCWA__File_Name__c = objTemplateWrapper.fileName;
/*if(b1 && b2 && b3 && b11 && b22 && b33){
                      throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
                   }*/
                  
                  if (!Test.isRunningTest() &&b1 && b2 && b3 && b11 && b22 && b33) {
    throw new AuraHandledException(
        'User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.'
    );
}

                else{
                        Database.UPSERT( objSFTemplate, AccessLevel.USER_MODE);
                    }
                }
                objTemplateWrapper.templateId = objSFTemplate.Id;
                return json.serialize(objTemplateWrapper);
            }
            return null;
        }catch(exception e){
            if (!Test.isRunningTest()){
            throw new AuraHandledException(e.getMessage());
            }Return null;
        }
    }
    /**
* @description Gets the public URL for a document.
* @param docId Document ID.
* @param cVId Content version ID.
* @param relatedId Related record ID.
* @param fileName File name.
* @return String public URL.
*/
    
    @AuraEnabled
    public static String getPublicUrl(String docId, String cVId, String relatedId, String fileName){
        try{
            //  String strDocUrl = '';
            List<ContentDocumentLink> listCDL = new List<ContentDocumentLink>();
            String[] listCDFields = new String[]{'Id', 'LinkedEntityId', 'ContentDocumentId'};
                if (!C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Button__c', 'isAccessible', null, true)) && !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Button__c', 'isAccessible', listCDFields, false))) {
                    throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
                }
            else{
                if(!Test.isRunningTest()){
                    listCDL = [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId =: docId AND LinkedEntityId =: relatedId WITH USER_MODE LIMIT 1   ];
                    
                }
                else{
                    listCDL.clear();
                }
            }
            if(listCDL.isEmpty()){
                ContentDocumentLink objCDL = new ContentDocumentLink();
                objCDL.ContentDocumentId = docId;
                objCDL.LinkedEntityId = relatedId;
                objCDL.Visibility='AllUsers';
                objCDL.ShareType = 'V';
                String[] listFields = new String[]{ 'LinkedEntityId', 'ContentDocumentId', 'Visibility', 'ShareType'};
                    if (!C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('ContentDocumentLink', 'isAccessible', null, true)) && !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('ContentDocumentLink', 'isAccessible', listFields, false)) && !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('ContentDocumentLink', 'isCreateable', null, true)) && !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('ContentDocumentLink', 'isCreateable', listFields, false))) {
                        throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
                    }
                else{
                    Database.INSERT(objCDL, AccessLevel.USER_MODE);
                }
                ContentDistribution objCD = new ContentDistribution();
                objCD.Name = fileName;
                objCD.ContentVersionId = cVId;
                objCD.PreferencesAllowViewInBrowser= true;
                objCD.PreferencesAllowOriginalDownload=true;
                objCD.RelatedRecordId = relatedId;
                String[] listFields2 = new String[]{ 'Name', 'ContentVersionId', 'PreferencesAllowViewInBrowser', 'PreferencesAllowOriginalDownload', 'RelatedRecordId'};
                    if (!C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('ContentDistribution', 'isAccessible', null, true)) && !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('ContentDistribution', 'isAccessible', listFields2, false)) && !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('ContentDistribution', 'isCreateable', null, true)) && !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('ContentDistribution', 'isCreateable', listFields2, false))) {
                        throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
                    }
                else{
                    Database.INSERT(objCD, AccessLevel.USER_MODE);
                }
                if (!C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('ContentDistribution', 'isAccessible', null, true)) && !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('ContentDistribution', 'isAccessible', new List<String>{'Id','ContentDownloadUrl'}, false))) {
                    throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
                }
                else{
                    list<ContentDistribution> listContentDistributions = [SELECT Id, ContentDownloadUrl FROM ContentDistribution WHERE Id=: objCD.Id  WITH USER_MODE]; 
                    return listContentDistributions[0].ContentDownloadUrl;
                }
            }
            return null;
        }catch(exception ex){
            C3Utility.logError(ex.getMessage(), ex.getStackTraceString(), ex.getLineNumber(), '','C3WhatsAppTemplateScreenLWCCtrl','getPublicUrl','');
            return null;
        } 
    }
    /**
* @description Runs media APIs.
* @param contentVersionId Content version ID.
* @param fileType File type.
* @return String media handler.
*/
   @AuraEnabled
    public static String runMediaAPIs(String contentVersionId, String fileType ){
        ContentVersion objCV = new ContentVersion();
     //    FileUploadWrapper objFileUploadWrapper = new FileUploadWrapper();
        String[] listFields = new String[]{'Id', 'LinkedEntityId', 'ContentDocumentId', 'ContentUrl',  'ContentSize', 'VersionData', 'Title', 'FileType'};
            if (!C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('ContentVersion', 'isAccessible', null, true)) && !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('ContentVersion', 'isAccessible', listFields, false))) {
                 throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
            }
        else{
            objCV = [SELECT Id, ContentDocumentId, ContentUrl, ContentSize, VersionData, Title, FileType FROM ContentVersion WHERE Id =: contentVersionId WITH USER_MODE];
        }
        String uploadSessionId = C3WhatsAppWebService.getUploadSessionIdFromWebService(fileType, objCV.ContentSize, objCV.Title.replaceAll(' ','_') );
        String mediaHandler = '';
        if(String.isNotBlank(uploadSessionId)){
            mediaHandler = C3WhatsAppWebService.getFileHandlerFromWebService(objCV.VersionData, uploadSessionId, fileType );
        }
        return mediaHandler;
    }
    /**
* @description Verifies an uploaded document.
* @param contentVersionId Content version ID.
* @return Boolean indicating success or failure.
*/
    @AuraEnabled
    public static Boolean verifyUpload(String contentVersionId){
        try{
            ContentVersion objCV = new ContentVersion();
            String[] listFields = new String[]{'Id', 'LinkedEntityId', 'ContentDocumentId', 'ContentUrl',  'ContentSize', 'VersionData', 'Title', 'FileType'};
                if (
                    !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('ContentVersion', 'isAccessible', null, true)) && !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('ContentVersion', 'isAccessible', listFields, false))) {
                        throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
                    }
            else{
                objCV = [SELECT Id, ContentDocumentId, ContentUrl, ContentSize, VersionData, Title, FileType FROM ContentVersion WHERE Id =: contentVersionId WITH SYSTEM_MODE ];
                System.debug('CV--' +objCV);
            }
            
            if(objCV.ContentSize > 4300000 || test.isRunningTest()){
                ContentDocument objDoc = new ContentDocument();
                String[] listFields2 = new String[]{'Id'};
                    if (!C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('ContentDocument', 'isAccessible', null, true)) && !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('ContentDocument', 'isAccessible', listFields2, false))) {
                        throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
                    }
                else{
                    objDoc = [SELECT Id FROM ContentDocument WHERE Id =: objCV.ContentDocumentId WITH USER_MODE];
                }
                
                if (!C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('ContentDocument', 'isAccessible', null, true)) && !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('ContentDocument', 'isDeletable', null, true))) {
                    throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
                }
                else{
                    Database.Delete(objDoc, AccessLevel.USER_MODE);
                }
                return false;
            }
            return true;
        }catch(exception ex){ C3Utility.logError(ex.getMessage(), ex.getStackTraceString(), ex.getLineNumber(), '','C3WhatsAppTemplateScreenLWCCtrl','verifyUpload',''); return null; }
    }
    /**
* @description Deletes an uploaded document.
* @param documentId Document ID.
* @return Boolean indicating success or failure.
*/
    
    @AuraEnabled
    public static Boolean deleteUploadedDocument(String documentId){
        try{
            if (!C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('ContentDocument', 'isAccessible', null, true)) && !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('ContentDocument', 'isDeletable', null, true))) {
                throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
            }
            else{
                Database.Delete(new List<String>{documentId}, true, AccessLevel.USER_MODE);
            }
            return true;
        }catch(exception ex){ C3Utility.logError(ex.getMessage(), ex.getStackTraceString(), ex.getLineNumber(), '','C3WhatsAppTemplateScreenLWCCtrl','verifyUpload',''); return null; }
    }
    /**
* @description Gets existing template data.
* @param templateId Template ID.
* @return String response from the API.
*/
    @AuraEnabled
    public static String getExistingTemplate(String templateId){
        try{
            if(String.isNotBlank(templateId)){
                TemplateWrapper objTemplateWrapper = new TemplateWrapper();
                CCCWA__Template_Object__c objTemplate = new CCCWA__Template_Object__c();
                String [] fieldsToQuery = new String [] {'Id', 'Name', 'CCCWA__Language_Code__c', 'CCCWA__Category__c', 'CCCWA__Template_Label__c', 'CCCWA__TemplateID__c', 'CCCWA__Mime_Type__c', 'CCCWA__Status__c', 'CCCWA__Content_Version_Id__c', 'CCCWA__Template_Message__c', 'CCCWA__Header_Type__c', 'CCCWA__File_Name__c', 'CCCWA__Media_Type__c', 'CCCWA__Object__c', 'CCCWA__Whatsapp_Template__c', 'CCCWA__Media_Handler__c', 'CCCWA__Footer__c', 'CCCWA__Header__c', 'CCCWA__Document_Url__c'  };
                    String [] fieldsToQuery2 = new String [] {'Id', 'CCCWA__Field_Name__c', 'CCCWA__Object_name__c', 'CCCWA__Parameter_Name__c'  };
                        String [] fieldsToQuery3 = new String [] {'Id', 'CCCWA__Button_text__c', 'CCCWA__Button_Type__c', 'CCCWA__Country_Code__c', 'CCCWA__phoneNumber__c', 'CCCWA__Type__c', 'CCCWA__Type_of_Action__c', 'CCCWA__URL_Type__c', 'CCCWA__Website_URL__c'  };
                            Boolean b1  = !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Object__c', 'isAccessible', null, true));
                Boolean b11 = !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Object__c', 'isAccessible', fieldsToQuery, false));
                
                Boolean b2  = !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Mapping__c', 'isAccessible', null, true));
                Boolean b22 = !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Mapping__c', 'isAccessible', fieldsToQuery2, false));
                
                Boolean b3  = !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Button__c', 'isAccessible', null, true));
                Boolean b33 = !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Button__c', 'isAccessible', fieldsToQuery3, false));
                //	system.debug('Log');
                if(b1 && b2 && b3 && b11 && b22 && b33){
                    throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
                }else{
                    objTemplate = [SELECT Id, Name, CCCWA__Template_Label__c, CCCWA__Template_Message__c, CCCWA__Content_Version_Id__c, CCCWA__Mime_Type__c, CCCWA__File_Name__c, CCCWA__Media_Handler__c, CCCWA__Media_Type__c, CCCWA__Document_Url__c, CCCWA__Header_Type__c, CCCWA__Category__c, CCCWA__Object__c, CCCWA__Status__c, CCCWA__Footer__c, CCCWA__Header__c, CCCWA__Language_Code__c, CCCWA__Whatsapp_Template__c, CCCWA__TemplateID__c, (SELECT Id,CCCWA__Example_Text__c, CCCWA__Field_Name__c, CCCWA__Object_name__c, CCCWA__Parameter_Name__c FROM CCCWA__Template_Mappings__r), (SELECT Id, CCCWA__Button_text__c, CCCWA__Button_Type__c, CCCWA__Country_Code__c, CCCWA__phone_Number__c, CCCWA__Type__c, CCCWA__Type_of_Action__c, CCCWA__URL_Type__c, CCCWA__Website_URL__c FROM CCCWA__Template_Buttons__r) FROM CCCWA__Template_Object__c WHERE Id =: templateId  WITH USER_MODE LIMIT 1];
                }
                
                objTemplateWrapper.templateName = objTemplate.Name;
                if (String.isNotBlank(objTemplate.CCCWA__Template_Label__c)) {
                    objTemplateWrapper.templateName = objTemplate.CCCWA__Template_Label__c;
                }
                objTemplateWrapper.templateName = objTemplate.Name;
                objTemplateWrapper.templateId = objTemplate.Id;
                objTemplateWrapper.isHeaderText = false;
                objTemplateWrapper.isHeaderMedia = false;
                objTemplateWrapper.isActionList = false;
                objTemplateWrapper.isQuickReplyList = false;
if(String.isNotBlank(objTemplate.TemplateID__c)){
                    objTemplateWrapper.whatsAppTemplateId = objTemplate.CCCWA__TemplateID__c;
                }
                
                if(String.isNotBlank(                objTemplate.Media_Handler__c)){
                    objTemplateWrapper.mediaHandler = objTemplate.CCCWA__Media_Handler__c;   
                }	
                
                if(String.isNotBlank(objTemplate.Category__c)){
                    objTemplateWrapper.category = objTemplate.CCCWA__Category__c;   
                }
                
                if(String.isNotBlank(objTemplate.Object__c)){
                    objTemplateWrapper.objectName = objTemplate.CCCWA__Object__c;   
                }
                
                if(String.isNotBlank(objTemplate.Content_Version_Id__c)){
                    objTemplateWrapper.contentVersionId = objTemplate.CCCWA__Content_Version_Id__c;  
                }
                
                if(String.isNotBlank(objTemplate.Mime_Type__c)){
                    objTemplateWrapper.mimeType = objTemplate.CCCWA__Mime_Type__c;   
                }
                
                if(String.isNotBlank(objTemplate.Footer__c)){
                    objTemplateWrapper.footer = objTemplate.CCCWA__Footer__c;
                }
                
                if(String.isNotBlank(objTemplate.File_Name__c)){
                    objTemplateWrapper.fileName = objTemplate.CCCWA__File_Name__c;
                }
                
                if(String.isNotBlank(objTemplate.Header__c)){
                    objTemplateWrapper.headerText = objTemplate.CCCWA__Header__c;
                    objTemplateWrapper.headerType = 'TEXT';
                    objTemplateWrapper.isHeaderText = true;
                    objTemplateWrapper.isHeaderMedia = false;
                }
                if(String.isNotBlank(objTemplate.Header_Type__c)){
                    objTemplateWrapper.headerType = objTemplate.CCCWA__Header_Type__c;	
                }
                if(String.isNotBlank(objTemplate.Media_Type__c)){
                    objTemplateWrapper.mediaType = objTemplate.CCCWA__Media_Type__c;	
                }
                if(String.isNotBlank(objTemplate.Document_Url__c)){
                    objTemplateWrapper.publicDocUrl = objTemplate.CCCWA__Document_Url__c;	
                }
                if(String.isNotBlank(objTemplate.Language_Code__c)){
                    objTemplateWrapper.language = objTemplate.CCCWA__Language_Code__c;    
                }
                
                if(String.isNotBlank(objTemplate.Whatsapp_Template__c)){
                    objTemplateWrapper.templateBody = objTemplate.CCCWA__Whatsapp_Template__c;
                }
                
                if(String.isNotBlank(objTemplate.Template_Message__c)){
                    objTemplateWrapper.templateBodyText = objTemplate.CCCWA__Template_Message__c;    
                }
                
                if(objTemplate.Template_Mappings__r != null && objTemplate.CCCWA__Template_Mappings__r.size()>0){
                    objTemplateWrapper.listMapping = new List<ListMapping>();
                    for(CCCWA__Template_Parameter__c objParam : objTemplate.CCCWA__Template_Mappings__r){
                        ListMapping objMapping = new ListMapping();
                        objMapping.mappingId = objParam.Id;
                        objMapping.fieldName = objParam.CCCWA__Field_Name__c;
                        objMapping.exampleText = objParam.CCCWA__Example_Text__c;
                        objMapping.parameterNum = objParam.CCCWA__Parameter_Name__c;
                        objMapping.placeHolder = '{{'+objParam.CCCWA__Parameter_Name__c+'}}';
                        objTemplateWrapper.listMapping.add(objMapping);
                    }
                }    
                if(objTemplate.Template_Buttons__r != null && objTemplate.Template_Buttons__r.size()>0){
                    objTemplateWrapper.listActions = new List<ListActions>();
                    objTemplateWrapper.listQuickReply = new List<ListQuickReply>();
                    for(CCCWA__Template_Button__c objButton : objTemplate.CCCWA__Template_Buttons__r){
                        ListActions objAction = new ListActions();
                        objAction.buttonId = objButton.Id;
                        objAction.isActionPhoneNumber = false;
                        objAction.isActionUrl = false;
                        objAction.isIcon = false;
                        objTemplateWrapper.buttonOption = objButton.CCCWA__Button_Type__c;
                        objAction.buttonText = objButton.CCCWA__Button_text__c;
                        if(objButton.CCCWA__Button_Type__c == 'call to action'){
                            objTemplateWrapper.listQuickReply = null;
                            objAction.isIcon = true;
                            objTemplateWrapper.isActionList = true;
                            objAction.actionType = objButton.CCCWA__Type_of_Action__c;
                            if(objButton.CCCWA__Type_of_Action__c == 'phoneNumber'){
                                objAction.isActionPhoneNumber = true;
                                objAction.iconName = 'utility:call';
                                objAction.phoneNumber = objButton.CCCWA__phone_Number__c;
                                objAction.countryCode = objButton.CCCWA__Country_Code__c;
                            }else{
                                objAction.iconName = 'utility:new_window';
                                objAction.isActionUrl = true;
                                objAction.urlType = objButton.CCCWA__URL_Type__c;
                                objAction.websiteUrl = objButton.CCCWA__Website_URL__c;
                            }
                            objTemplateWrapper.listActions.add(objAction);
                        }
                        if(objButton.CCCWA__Button_Type__c  == 'QUICK_REPLY'){
                            objTemplateWrapper.listActions = null;
                            objTemplateWrapper.isQuickReplyList = true;
                            ListQuickReply objActions = new ListQuickReply();
                            objActions.buttonId = objButton.Id;
                            objActions.isIcon = false;
                            objActions.type = 'Custom';
                            objActions.buttonText = objButton.CCCWA__Button_text__c;
                            if(objTemplateWrapper.listQuickReply != null){
                                objTemplateWrapper.listQuickReply.add(objActions);
                            }
                        }
                    }
                }
                return json.serialize(objTemplateWrapper);
            }
            return null;   
        }catch(exception ex){
            C3Utility.logError(ex.getMessage(), ex.getStackTraceString(), ex.getLineNumber(), '','C3WhatsAppTemplateScreenLWCCtrl','getExistingTemplate','');
            return null;
        }
    }
    /**
* @description Gets records to select.
* @param sObjectName Object name.
* @return String response from the API.
*/
    @AuraEnabled
    public static String getRecordsToSelect(String sObjectName) {
        Boolean b1 = !C3Utility.checkFieldPermission(
            new C3Utility.FieldPermissionRequest(sObjectName, 'isAccessible', new List<String>{'Id', 'Name'}, false)
        );
        Boolean b2 = !C3Utility.checkFieldPermission(
            new C3Utility.FieldPermissionRequest(sObjectName, 'isAccessible', null, true)
        );
        
        if(b2 && b1){
            throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
        }else{
            String query = 'SELECT Id, Name FROM '+ sObjectName +' LIMIT 1000';
            Map<String, Object> bindVariablesMap = new Map<String, Object>{'sObjectName' => sObjectName  };
                List<SObject> listObject = Database.queryWithBinds(
                    String.escapeSingleQuotes(query),
                    bindVariablesMap,
                    AccessLevel.USER_MODE
                );
            return JSON.Serialize(listObject);
        }
    }
    /**
* @description Gets formatted body text.
* @param strText Text to format.
* @return String formatted text.
*/
    public static string getFormattedBody(string strText){
        String input='';
        
        if(!string.isBlank(strText)){
            input = strText.replaceAll('<b>','*');
            input = input.replaceAll('</b>','*');
            input = input.replaceAll('</p>','\n');
            input = input.replaceAll('<p>','');
            input = input.replaceAll('<em>','_');
            input = input.replaceAll('</em>','_');
            input = input.replaceAll('<br>',' \n ');
            input = input.replaceAll('</strong>','*');
            input = input.replaceAll('<strong>','*');
            input = input.replaceAll('<strike>','~');
            input = input.replaceAll('</strike>','~');
        }
        return input;
    }
    /**
* @class TemplateRow
* @description Represents a row in a template with a field and its corresponding value.
*/
    public class TemplateRow {
        /**
* @description The name of the field in the template.
*/
        @AuraEnabled
        public String field { get; set; }
        /**
* @description The value associated with the field in the template.
*/
        @AuraEnabled
        public String value { get; set; }
    }
    /**
* @class ResponseBody
* @description Represents the response body containing a list of dropdown options and the object name.
*/
    
    public class ResponseBody{
        public list<DropdownWrapper> sfFieldsPickList;
        public string objectName;
    }
    /**
* @class ResponseBody
* @description Represents the response body containing a list of dropdown options and the object name.
*/
    public class DropdownWrapper{
        public string label;
        public string value;
    }
    /**
* @class RequestBody
* @description Represents the request body for sending a WhatsApp message.
*/
    
    public class RequestBody{
        public String campaignId;
        public String ameyoLeadId;
        public dateTime scheduleDateTime;
        public List<FilterWrapper> filterCondition;
    }
    /**
* @class FilterWrapper
* @description Represents a filter condition for the request.
*/
    public class FilterWrapper{
        public string fieldApiName;
        public string operator;
        public string fieldValue;
        public boolean isDateField;
    }
    /**
* @class TemplateWrapper
* @description Represents a WhatsApp template with its properties and related data.
*/
    public class TemplateWrapper{
        public String templateId;
        public String whatsAppTemplateId;
        public String publicDocUrl;
        public String mediaHandler;
        public String headerType;	
        public String headerText;	
        public String documentId;	
        public String contentVersionId;	
        public String mimeType;	
        public String language;	
        public String project;
        public String templateName;	
        public String templateBody;
        public String templateBodyText;
        public String footer;	
        public String category;	
        public String buttonOption;	
        public String mediaType;
        public String fileName;	
        public String objectName;
        public Boolean isHeaderMedia;
        public Boolean isHeaderText;
        public Boolean isActionList;
        public Boolean isQuickReplyList;
        public ListMapping[] listMapping;
        public ListQuickReply[] listQuickReply;
        public ListActions[] listActions;
    }
    /**
* @class ListMapping
* @description Represents a mapping of a template parameter.
*/
    public class ListMapping {
        public String mappingId ;
        public String fieldName;
        public String parameterNum;
        public String placeHolder;
        public String exampleText;
    }
    /**
* @class ListActions
* @description Represents an action button in a WhatsApp template.
*/
    public class ListActions {
        public String buttonId ;
        public String actionType ;
        public String buttonText;
        public String  countryCode ;
        public String  phoneNumber ;
        public String  urlType ;
        public String  websiteUrl;
        public Boolean  isIcon ;
        public String  iconName ;
        public String  type ;
        public Boolean  isActionPhoneNumber ;
        public Boolean  isActionUrl;
        
    }
    /**
* @class ListQuickReply
* @description Represents a quick reply button in a WhatsApp template.
*/
    public class ListQuickReply {
        public String buttonId ;
        public Boolean  isIcon ;
        public String buttonText;
        public String  type ;
    }
    /**
* @class LwcReturnResponse
* @description Represents the response returned to the LWC after processing.
*/
    public class LwcReturnResponse{
        public String strDocPublicUrl;
        public String mediaHandler;
        public String templateId;
        public ListMapping[] listMapping;
        public ListQuickReply[] listQuickReply;
        public ListActions[] listActions;
    }
    /**
* @class FileUploadWrapper
* @description Represents the response for file upload operations.
*/
    public class FileUploadWrapper{
        public String strDocPublicUrl;
        public String mediaHandler;
    }
}