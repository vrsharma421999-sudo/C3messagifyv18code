/**
 * @class C3SendtriggerMessagesFlow
 * @description
 *  Flow-invocable class that facilitates sending WhatsApp template messages
 *  by delegating to the C3Utility.sendTemplate method.
 *  Used in Flow automation to pass selected record IDs and template.
 *
 * @author Asjad Ahmed
 * @date June 2025
 * @company CloudCentric
 * @version 1.0
 */
global without sharing class C3SendtriggerMessagesFlow {
    /**
     * @method sendTemplate
     * @description
     *  Invocable method to send WhatsApp template messages for a list of record IDs using a specified template.
     *
     * @param objFlowInput List of FlowInput containing record IDs and the template record ID.
     */


    @InvocableMethod(label='Send WhatsApp Template (Single)' category='WhatsApp')
    global static void sendTemplate(List<FlowInput> objFlowInput) {
        List<String> setRecordIds = new List<String>();
        for (FlowInput flowInput : objFlowInput) {
            setRecordIds.add(flowInput.recordId);
        }
        C3Utility.callSendTemplate(setRecordIds, objFlowInput[0].templateRecordId);
    }
    /**
     * @class FlowInput
     * @description
     *  Wrapper class for Flow input values to be passed into the sendTemplate method.
     *  Used to map invocable variables for Flow usage.
     */


    global class FlowInput {
        /**
         * @description The ID of the record for which the WhatsApp message will be sent.
         */
        @InvocableVariable(label='List Record IDs')
        global String recordId;
        /**
         * @description The ID of the active WhatsApp template to be used for the message.
         */

        @InvocableVariable(label='Active Template Id') 
        global String templateRecordId;
    }
}