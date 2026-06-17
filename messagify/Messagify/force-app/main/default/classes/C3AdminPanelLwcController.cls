/**
 * @description Controller class for managing the WhatsApp Admin Panel configuration in the LWC.
 *              Handles initialization and saving of WhatsApp_Admin__c records with field-level security checks.
 */
public with sharing class C3AdminPanelLwcController {
    
  /**
     * @description Initializes and retrieves the WhatsApp_Admin__c record.
     *              Checks for field-level access before returning the first available admin config.
     * @return The first WhatsApp_Admin__c record if accessible; otherwise, null.
     * @throws AuraHandledException If the user lacks field-level permissions.
     */
    @AuraEnabled 
    public static CCCWA__WhatsApp_Admin__c  initialize(){
        List<CCCWA__WhatsApp_Admin__c> listWAA = new List<CCCWA__WhatsApp_Admin__c>();
        if(!C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__WhatsApp_Admin__c','isAccessible',null,True)) && !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__WhatsApp_Admin__c','isAccessible',new List<String>{'CCCWA__NumberID__c', 'CCCWA__WabaId__c'},False))){
            throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
        }else{
            listWAA = CCCWA__WhatsApp_Admin__c.getall().values();
          //  system.debug('listWAA::::'+listWAA);
        }
        
        if(listWAA != null && listWAA.size()>0){
            return listWAA[0];
        }
        return null;
    }
    /**
     * @description Saves the WhatsApp_Admin__c configuration passed in as a JSON string.
     *              Performs full FLS checks before allowing insert/update.
     * @param jsonAdminConfig A JSON representation of the WhatsApp_Admin__c object to be saved.
     * @return The Id of the saved WhatsApp_Admin__c record, or null if input is blank.
     * @throws AuraHandledException If the user lacks create/update or field-level permissions.
     */

    @AuraEnabled
    public static string saveAdminConfig(String jsonAdminConfig){
        if(String.isnotblank(jsonAdminConfig)){
           // System.debug('jsonAdminconfig' + jsonAdminConfig);
            CCCWA__WhatsApp_Admin__c objAdminConfig = (CCCWA__WhatsApp_Admin__c)JSON.deserialize(jsonAdminConfig, CCCWA__WhatsApp_Admin__c.class);
            List<String> listFields = new List<String>{'CCCWA__NumberID__c', 'CCCWA__WabaId__c'};
            Boolean canAccessAll = C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__WhatsApp_Admin__c', 'isAccessible', null, true));
            Boolean canAccessFields = C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__WhatsApp_Admin__c', 'isAccessible', listFields, false));
            Boolean canCreateAll = C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__WhatsApp_Admin__c', 'isCreateable', null, true));
            Boolean canCreateFields = C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__WhatsApp_Admin__c', 'isCreateable', listFields, false));
            Boolean canUpdateAll = C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__WhatsApp_Admin__c', 'isUpdateable', null, true));
            Boolean canUpdateFields = C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__WhatsApp_Admin__c', 'isUpdateable', listFields, false));
            
            if (canAccessAll && canAccessFields && canCreateAll && canCreateFields && canUpdateAll && canUpdateFields) {
                Database.UPSERT(objAdminConfig, AccessLevel.USER_MODE);
            } else {
                throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
            }
            return objAdminConfig.Id;
        }
        return null;
    }



}