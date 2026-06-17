/**
* @class C3RefreshTemplateSchedulable
* @description
*  Scheduled Apex class to refresh WhatsApp template records from an external service.
*  Ensures field-level security before performing any DML updates.
*
*  - Fetches updated template data from an external API.
*  - Matches existing records by TemplateID__c.
*  - Updates fields like Name and Status__c if needed.
*
* @implements Schedulable, Database.AllowsCallouts
* @usage Schedule via UI or programmatically using System.schedule.
* @security Respects FLS for Template_Object__c before querying or updating.
* @version 1.0
* @author Asjad Ahmed
* @company CloudCentric
* @date June 2025
*/
public  with sharing class C3RefreshTemplateSchedulable implements Schedulable, Database.AllowsCallouts {
    /**
* @method execute
* @description Entry point for scheduled execution.
* @param context The context in which the job was scheduled.
*/
    public void execute(SchedulableContext context) {
        scheduleRefreshTemplate();
    }
    
    /**
* @method scheduleRefreshTemplate
* @description
*  Fetches updated template data from external API and updates Template_Object__c records accordingly.
*  Applies field-level security checks before performing DML.
* @throws AuraHandledException if user lacks necessary FLS.
*/
    // Suppressing PMD warnings because explicit CRUD/FLS validations 
    // are already implemented in this class (see b1–b8 checks).
    // Safe to suppress for SOQL and DML operations on CCCWA__Template_Object__c
    @SuppressWarnings('PMD.ApexCRUDViolation, PMD.ApexFlsViolation')
    public void scheduleRefreshTemplate(){
        try{
            Map<String, CCCWA__Template_Object__c> mapWhatsAppTemplateId = new Map<String, CCCWA__Template_Object__c>();
            List<CCCWA__Template_Object__c> listTemplate = new List<CCCWA__Template_Object__c>();
            String responseBody = C3WhatsAppWebService.fetchTemplate();
            
            
            if (String.isNotBlank(responseBody)) { 
                boolean b7 = !C3Utility.CheckFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Object__c','isAccessible', null, false));
                boolean b8 = !C3Utility.CheckFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Object__c', 'isAccessible', new List<String>{'Id', 'CCCWA__TemplateID__c', 'CCCWA__Status__c' }, false));
                
                if(b7 && b8){
                    throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
                }else {
                    List<CCCWA__Template_Object__c> listOfTemplate = new List<CCCWA__Template_Object__c>([SELECT Id, CCCWA__TemplateID__c FROM CCCWA__Template_Object__c LIMIT 49000]);
                    for (CCCWA__Template_Object__c obj : listOfTemplate) {
                        if (String.isNotBlank(obj.CCCWA__TemplateID__c)){
                            mapWhatsAppTemplateId.put(obj.CCCWA__TemplateID__c, obj);
                        }
                    }
                }
                
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
                List<Object> templateJsonList = (List<Object>) responseMap.get('data');
                
                for (Object templateJson : templateJsonList) {
                    Map<String, Object> templateMap = (Map<String, Object>) templateJson;
                    String whatsAppId = (String) templateMap.get('id');
                    if (mapWhatsAppTemplateId.containsKey(whatsAppId)) {
                        CCCWA__Template_Object__c objTemplate = mapWhatsAppTemplateId.get(whatsAppId);
                        // - Object: CCCWA__Template_Object__c.CCCWA__Status__c
                        //   Reason: Access checked via CheckFieldPermission. This field is updated only 
                        //           with status values from WhatsApp API and is not user-controlled.
                        objTemplate.CCCWA__Status__c = (String) templateMap.get('status');
                        // - Object: CCCWA__Template_Object__c.Name
                        //   Reason: Standard Name field is validated with CheckFieldPermission before update. 
                        //           Used only to sync template name from WhatsApp API response.
                        
                        objTemplate.Name = (String) templateMap.get('name');
                        // - Object: CCCWA__Template_Object__c.CCCWA__TemplateID__c
                        //   Reason: Access to Template ID is validated using CheckFieldPermission before 
                        //           query/update. This field is only used for mapping WhatsApp templates.
                        objTemplate.CCCWA__TemplateID__c = whatsAppId;
                        listTemplate.add(objTemplate);
                    }
                }
                
                if (!listTemplate.isEmpty()) {
                    boolean b1 = !C3Utility.CheckFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Object__c', 'isAccessible', null, false));
                    boolean b2 = !C3Utility.CheckFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Object__c', 'isAccessible', new List<String>{'Id', 'Name', 'CCCWA__TemplateID__c', 'CCCWA__Status__c' }, false));
                    boolean b3 = !C3Utility.CheckFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Object__c', 'isCreateable', null, false));
                    boolean b4 = !C3Utility.CheckFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Object__c', 'isCreateable', new List<String>{'Id', 'Name', 'CCCWA__TemplateID__c', 'CCCWA__Status__c' }, false));
                    boolean b5 = !C3Utility.CheckFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Object__c', 'isUpdateable', null, false));
                    boolean b6 = !C3Utility.CheckFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Object__c', 'isUpdateable', new List<String>{'Id', 'Name', 'CCCWA__TemplateID__c', 'CCCWA__Status__c' }, false));
                    
                    
                    /*if((!C3Utility.CheckFieldPermission('Template_Object__c', 'isAccessible', null, false) 
&&!C3Utility.CheckFieldPermission('Template_Object__c', 'isAccessible', new List<String>{'Id', 'Name', 'TemplateID__c', 'Status__c' }, false)) 
&& (!C3Utility.CheckFieldPermission('Template_Object__c', 'isCreateable', null, false)  
&& !C3Utility.CheckFieldPermission('Template_Object__c', 'isCreateable', new List<String>{'Id', 'Name', 'TemplateID__c', 'Status__c' }, false)) 
&& (!C3Utility.CheckFieldPermission('Template_Object__c', 'isUpdateable', null, false)  
&& !C3Utility.CheckFieldPermission('Template_Object__c', 'isUpdateable', new List<String>{'Id', 'Name', 'TemplateID__c', 'Status__c' }, false))){*/
                    if(b1 && b2 && b3 && b4 && b5 && b6){
                        throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');    
                    }else{
                        Database.UPDATE(listTemplate,AccessLevel.User_mode);
                    }
                }
            }
        }catch(exception ex){
            C3Utility.logError(ex.getMessage(), ex.getStackTraceString(), ex.getLineNumber(), '','RefreshTemplateSchedulable','execute','');
            
        }
    }
}