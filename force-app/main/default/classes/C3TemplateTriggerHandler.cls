/**
 * @class C3TemplateTriggerHandler
 * @description
 *  This Apex class handles trigger logic for 'Template_Object__c' records.
 *  Specifically, it manages post-delete logic to clean up corresponding metadata entries asynchronously.
 *
 *  Features:
 *  - afterDelete: Trigger handler that processes deleted template records.
 *  - deleteTempateFromMeta: Enqueues a job to delete related metadata using a queueable class.
 *
 * @access Public - Invoked by triggers handling Template_Object__c.
 * @usage Called from 'after delete' context in a trigger on Template_Object__c.
 * @security Depends on the queueable class for access enforcement.
 * @author Asjad Ahmed
 * @version 1.0
 * @company CloudCentric
 * @license Salesforce Public License (https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_license.htm)
 * @date June 2025
 */
public with sharing class C3TemplateTriggerHandler {
     /**
     * @method afterDelete
     * @description
     *  Trigger handler for 'after delete' events on Template_Object__c.
     *  Delegates logic to delete template metadata via the queueable job.
     *
     * @param listTemplate List<Template_Object__c> - The list of deleted template records.
     * @access Public
     * @usage Invoked from trigger after Template_Object__c records are deleted.
     */
    public static void afterDelete(List<CCCWA__Template_Object__c> listTemplate){
        deleteTempateFromMeta(listTemplate);
    }
    /**
     * @method deleteTempateFromMeta
     * @description
     *  Extracts template names from deleted records and enqueues a 'C3DeleteTemplateQueue' job
     *  to delete the associated metadata entries from the system.
     *
     * @param listTemplate List<Template_Object__c> - List of deleted template records.
     * @access Private
     * @usage Internal method to perform metadata cleanup asynchronously.
     */

    public static void deleteTempateFromMeta(List<CCCWA__Template_Object__c> listTemplate){
        Set<string> setTemplateNames = new Set<string>();
         if (listTemplate == null || listTemplate.isEmpty()) {
        return;
    }
        for (CCCWA__Template_Object__c objTemplate : listTemplate) {
            setTemplateNames.add(objTemplate.Name);
        }
        if (!setTemplateNames.isEmpty()) {
            system.enqueueJob(new C3DeleteTemplateQueue(setTemplateNames));
        }
    }
}