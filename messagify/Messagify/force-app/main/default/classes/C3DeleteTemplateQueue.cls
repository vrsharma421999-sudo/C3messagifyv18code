/**
 * @class C3DeleteTemplateQueue
 * @description
 *  This Queueable Apex class is responsible for asynchronously deleting WhatsApp templates
 *  using the C3WhatsAppWebService. It accepts a set of template names to be deleted during execution.
 *
 *  Features:
 *  - Asynchronous Execution: Implements the Queueable interface.
 *  - External Callouts: Supports HTTP callouts during execution.
 *  - Template Deletion: Calls external service to remove specified WhatsApp templates.
 *
 * @access Public - Can be invoked from Apex or another asynchronous context.
 * @usage Enqueue via 'System.enqueueJob(new C3DeleteTemplateQueue(templateNames));'
 * @security Requires only necessary permissions for callouts and Apex execution.
 * @author Asjad Ahmed
 * @version 1.0
 * @company CloudCentric
 * @license Salesforce Public License (https://developer.salesforce.com/docs/atlas.en-us/apexcode.meta/apexcode/apex_license.htm)
 * @date June 2025
 */
public with sharing class C3DeleteTemplateQueue implements Queueable, Database.AllowsCallouts {
    /**
     * @description
     *  A set of WhatsApp template names to be deleted during queue execution.
     */
    public Set<String> listTemplateNames;
     /**
     * @constructor C3DeleteTemplateQueue
     * @description
     *  Constructor to initialize the queue job with a set of WhatsApp template names.
     *
     * @param listTemplateNames Set<String> - Template names to be deleted.
     */
    public C3DeleteTemplateQueue(Set<String> listTemplateNames) {
        this.listTemplateNames = listTemplateNames;
    }
    /**
     * @description
     *  Executes the queueable job to delete the specified WhatsApp templates.
     *
     * @param context QueueableContext - The context for the queueable job.
     */
    public void execute(QueueableContext context){
        if (this.listTemplateNames != null && this.listTemplateNames.size()>0) {
            for (String templateName : this.listTemplateNames) {
                C3WhatsAppWebService.deleteTemplate(templateName);
            }
        }
    }
}