/**
 * @description Queueable class responsible for inserting a WhatsApp_Conversation__b record.
 *              Supports callouts and is used to enqueue WhatsApp message processing.
 */
public without sharing class C3CreateWhatsAppConversationQueue implements Queueable, Database.AllowsCallouts{
      /**
     * @description Stores the WhatsApp conversation record to be processed. 
     */
     
    public CCCWA__WhatsApp_Conversation__b  objfilteredMessages;
     /**
     * @description Constructor to initialize the queue with a WhatsApp conversation object.
     * @param objfilteredMessages The CCCWA__WhatsApp_Conversation__b  record to process.
     */
    public C3CreateWhatsAppConversationQueue(CCCWA__WhatsApp_Conversation__b  objfilteredMessages) {
        this.objfilteredMessages = new CCCWA__WhatsApp_Conversation__b();
        this.objfilteredMessages = objfilteredMessages;
    }
     /**
     * @description Executes the queueable job to insert the conversation record,
     *              bypassing test context to avoid inserting during test runs.
     * @param context The QueueableContext provided by Salesforce.
     */

    public void execute(QueueableContext context) {
        if (!Test.isRunningTest() ) {
             
            Database.insertImmediate(this.objfilteredMessages);  
        }
        
    }     
}