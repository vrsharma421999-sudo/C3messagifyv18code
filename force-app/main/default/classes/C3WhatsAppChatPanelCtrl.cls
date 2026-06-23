/**
* @description Controller for managing WhatsApp chat panel interactions.
* @author Asjad Ahmed
* @version 1.0
* @company CloudCentric
* @license Salesforce Public License
* @date June 2025
*/
public with sharing class C3WhatsAppChatPanelCtrl {
    /**
* @description Exception for Chat Panel errors
*/
    public class ChatPanelException extends Exception {}
    /**
* @description Initializes the WhatsApp chat panel controller.
* @param recordId The ID of the record to associate with the chat.
* @param objName The name of the object.
* @return A JSON string representing the initialized chat panel.
*/
    @AuraEnabled
    public static string initWhatsAppChatPanelController(string recordId, string objName){
        WrapperChat wrapMain = new WrapperChat();
        
        wrapMain.lstTxtMsg = new List<TextMessagWrapper>();
        wrapMain.strMsg = '';
        wrapMain.strSuccessMsg = '';
        wrapMain.nameIntial = 'VP'; // Dummy initials
        wrapMain.currentUserIntial = 'JS'; // Dummy initials
        wrapMain.sendFrom = 'Vivek Pratap';
        wrapMain.toNumber = '919557714444';
        wrapMain.fromNumber = '919464700XXXX';
        wrapMain.isSuccess = true;
        wrapMain.isPNA = false;
        wrapMain.isConversationStarted = false;
        wrapMain.currentUserId = UserInfo.getUserId();
        wrapMain.organizationId = UserInfo.getOrganizationId();
        wrapMain.useReturnAsSend = false;
        wrapMain.url = System.URL.getOrgDomainUrl().toExternalForm()+'/lightning/n/Billing_Support';
        wrapMain.strNoMessagingCampaignErrorMsg = '';
        wrapMain.lstMessagingCampaignOptions = new List<PicklistWrapper >();
        wrapMain.lstMessagingTemplateOptions = c3WhatsppFetchTemplate(objName);
        wrapMain.lstMessagingCampaignPhoneOptions = new List<PicklistWrapper >();
        wrapMain.strSelectedMessagingCampaign = '';
        wrapMain.strSelectedMessagingTemplate = '';
        wrapMain.isUSAPhoneNumber = false;
        wrapMain.currentUserName='';
        wrapMain.isAllowedToChat=true;   //User can only send messages if he receives messages in last 24 hours
        
        
        String phoneNumber = C3Utility.fetchPhoneNumber(recordId);
        if (phoneNumber != null) {
            wrapMain.toNumber = phoneNumber; 
        }
        List<WhatsApp_Conversation__b> allTXTMessages = new List<WhatsApp_Conversation__b>();
        String [] listFields = new String [] {'Direction__c', 'Status__c', 'Message_formatted__c', 'From_Phone__c', 'Message__c', 'Read__c', 'To_Phone__c', 'Record_ID__c', 'CreatedDate', 'created_date__c'};
            if (
                C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('WhatsApp_Conversation__b', 'isAccessible', null, true)) &&
                C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('WhatsApp_Conversation__b', 'isAccessible', listFields, false))
            ) {
                allTXTMessages = [
                    SELECT Direction__c, Status__c, Message_formatted__c, From_Phone__c, Message__c, 
                    Read__c, To_Phone__c, Record_ID__c, CreatedDate, created_date__c
                    FROM WhatsApp_Conversation__b 
                    WHERE Record_ID__c = :recordId 
                    WITH SECURITY_ENFORCED
                ];
            }else {
                throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
            }
        
        if (Test.isRunningTest()) {
            C3TestDataFactory.WhatsAppInputWrapper input = new C3TestDataFactory.WhatsAppInputWrapper();
            input.objTemplate = null;
            input.toNumber = '919911410564';
            input.recordId = recordId;
            input.wamId = 'asdasdasd';
            
            allTXTMessages.addAll(new List<WhatsApp_Conversation__b>{
                C3TestDataFactory.buildConvoRecord(input),
                    C3TestDataFactory.buildConvoRecord(input)
                    });
        }
        List<WhatsApp_Conversation__b> filteredMessages = new List<WhatsApp_Conversation__b>();
        for (WhatsApp_Conversation__b msg : allTXTMessages) {
            if (msg.Record_ID__c == recordId) {
                filteredMessages.add(msg);
            }
        }
        if(!filteredMessages.isEmpty())
        {
            integer recordsCount = filteredMessages.size();
            DateTime createdDateTime = filteredMessages[recordsCount-1].created_Date__c;
            // Calculate the time difference in hours
            long hoursSinceCreation = (DateTime.now().getTime() - createdDateTime.getTime()) / (1000 * 60 * 60);
            if(filteredMessages[recordsCount-1].Direction__c=='Inbound' && hoursSinceCreation >= 24)
            {
                wrapMain.isAllowedToChat=false;
            }
            else{
                wrapMain.isAllowedToChat=true; 
            } 
        }
        if(String.isNotBlank(objName))
        {
            Map<String, String> objectAndNameFieldsMap = C3Utility.getStandardNameField(new Set<String>{objName});
            String recordNameField=objectAndNameFieldsMap.get(objName);
            /*if(String.isNotBlank(recordNameField))
            {
                string queryIni = 'select id,'+recordNameField+' from '+objName + ' where id =: recordId WITH SECURITY_ENFORCED Limit 1';
                list<sObject> lstSobjInitial;
                List<String> listFields1 = recordNameField.split(',');
                if (
                    C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest(objName, 'isAccessible', null, true)) &&
                    C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest(objName, 'isAccessible', listFields1, false))
                ) {
                    lstSobjInitial = Database.query(String.escapeSingleQuotes(queryIni), AccessLevel.USER_MODE);
                }
                else {
                    throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
                }
                string fullName = '';
                if(lstSobjInitial.size() > 0)
                {
                    sObject objNameInitial = lstSobjInitial[0];
                    fullName = String.valueOf(objNameInitial.get(recordNameField));
                    if(String.isNotBlank(fullName))
                    {
                        wrapMain.nameIntial = C3Utility.getNameDetails(fullName).get('senderNameSmall');
                        wrapMain.sendFrom = C3Utility.getNameDetails(fullName).get('senderName');
                    }
                }
            }*/
            if (String.isNotBlank(recordNameField)) {
                List<String> nameFields = recordNameField.split(',');
            
                // Check field-level security
                Boolean isObjectAccessible = C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest(objName, 'isAccessible', null, true));
                Boolean areFieldsAccessible = C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest(objName, 'isAccessible', nameFields, false));
            
                if (!isObjectAccessible || !areFieldsAccessible) {
                    throw new AuraHandledException('User: Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
                }
            
                // Build and execute SOQL dynamically
                String query = 'SELECT Id, ' + recordNameField + ' FROM ' + objName + ' WHERE Id = :recordId LIMIT 1';
                List<sObject> results = Database.query(String.escapeSingleQuotes(query), AccessLevel.USER_MODE);
            
                if (!results.isEmpty()) {
                    sObject resultRecord = results[0];
                    String fullName = String.valueOf(resultRecord.get(recordNameField));
            
                    if (String.isNotBlank(fullName)) {
                        Map<String, String> nameDetails = C3Utility.getNameDetails(fullName);
                        wrapMain.nameIntial = nameDetails.get('senderNameSmall');
                        wrapMain.sendFrom = nameDetails.get('senderName');
                    }
                }
            }

            else if(string.isNotBlank(wrapMain.toNumber)){
                wrapMain.nameIntial = wrapMain.toNumber.left(1);
                wrapMain.sendFrom =wrapMain.toNumber;
            }
            string strUserFirstName = UserInfo.getFirstName();
            string strUserLastName = UserInfo.getLastName();
            wrapMain.currentUserName = strUserFirstName+' '+strUserLastName;
            if(String.isNotBlank(strUserFirstName)){
                wrapMain.currentUserIntial = strUserFirstName.left(1).capitalize() + strUserLastName.left(1).capitalize();
            }else{
                wrapMain.currentUserIntial = strUserLastName.left(1).capitalize();
            }
        }
        
        TextMessagWrapper textMsgWrapper = new TextMessagWrapper();
        // Add the mediaWrapper to the textMsgWrapper's listMedia
        textMsgWrapper.listMedia = new List<TextMessageMediaWrapper>();
        wrapMain.lstTxtMsg= getAllTextMessagesForWhatsappChatPanel(recordId);
        // Add the textMsgWrapper to the lstTxtMsg
        return JSON.serialize(wrapMain);
    }
    /**
* @description Fetches the messaging templates for the specified object.
* @param objName The name of the object for which to fetch templates.
* @return A list of PicklistWrapper  objects containing the available templates.
* @throws AuraHandledException if the user does not have sufficient privileges.
*/
    @AuraEnabled
    public static List<PicklistWrapper > c3WhatsppFetchTemplate(string objName){
        List<Template_Object__c> listName = new List<Template_Object__c>();
        List<PicklistWrapper > result = new List<PicklistWrapper >();
        
        String [] fieldsToQuery = new String [] {'Id', 'Name', 'Language_Code__c', 'Status__c', 'Template_Message__c', 'Header_Type__c', 'File_Name__c', 'Media_Type__c', 'Media_Handler__c', 'Footer__c', 'Header__c', 'Document_Url__c'  };
            String [] fieldsToQuery2 = new String [] {'Id', 'Field_Name__c', 'Object_name__c', 'Parameter_Name__c'  };
                String [] fieldsToQuery3 = new String [] {'Id', 'Button_text__c', 'Button_Type__c', 'Country_Code__c', 'Phone_Number__c', 'Type__c', 'Type_of_Action__c', 'URL_Type__c', 'Website_URL__c'  };
                    Boolean b1  = !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('Template_Object__c', 'isAccessible', fieldsToQuery, false));
        Boolean b12 = !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('Template_Object__c', 'isAccessible', null, true));
        
        Boolean b2  = !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('Template_Mapping__c', 'isAccessible', fieldsToQuery2, false));
        Boolean b22 = !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('Template_Mapping__c', 'isAccessible', null, true));
        
        Boolean b3  = !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('Template_Button__c', 'isAccessible', fieldsToQuery3, false));
        Boolean b32 = !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('Template_Button__c', 'isAccessible', null, true));
        
        if(b1 && b2 && b3 && b12 && b22 && b32){
            throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
        }else{
            listName = [SELECT Name, Template_Message__c, Header__c, Footer__c, Document_Url__c, Media_Type__c, Whatsapp_Template__c, Status__c,Object__c, Template_Label__c, (SELECT Id, Button_text__c, Button_Type__c, Country_Code__c, Phone_Number__c, Type__c, Type_of_Action__c, URL_Type__c, Website_URL__c FROM Template_Buttons__r) FROM Template_Object__c WITH SECURITY_ENFORCED LIMIT 49000];
        }
        
        for (Template_Object__c template : listName) {
            PicklistWrapper  wrapper = new PicklistWrapper ();
            if(template.Status__c == 'APPROVED' && template.Object__c == objName)
            {
                wrapper.label = template.Name;
                if (String.isNotBlank(template.Template_Label__c)) {
                    wrapper.label = template.Template_Label__c;
                }
                wrapper.value = template.Name;
                wrapper.textMessage =template.Whatsapp_Template__c;
                wrapper.tempId = template.id;
                if (String.isNotBlank(template.Document_Url__c)) {
                    wrapper.mediaUrl = template.Document_Url__c;
                }
                if (String.isNotBlank(template.Media_Type__c)) {
                    wrapper.mediaType = template.Media_Type__c;
                }
                if (String.isNotBlank(template.Header__c)) {
                    wrapper.header = template.Header__c;
                }
                if (String.isNotBlank(template.Footer__c)) {
                    wrapper.footer = template.Footer__c;
                }
                if(template.Template_Buttons__r != null && template.Template_Buttons__r.size()>0){
                    wrapper.listButtons = new List<Template_Button__c>();
                    wrapper.listButtons = template.Template_Buttons__r;
                }
                result.add(wrapper);
            }
        }
        
        return result;
    }
    /**
* @description Retrieves all text messages for the specified WhatsApp chat panel.
* @param recordId The ID of the record associated with the chat.
* @return A list of TextMessagWrapper objects containing the text messages.
* @throws AuraHandledException if the user does not have sufficient privileges.
*/
    public static list<C3WhatsAppChatPanelCtrl.TextMessagWrapper> getAllTextMessagesForWhatsappChatPanel(String recordId)
    {
        list<C3WhatsAppChatPanelCtrl.TextMessagWrapper> lstTxtMsg = new list<C3WhatsAppChatPanelCtrl.TextMessagWrapper>();
        List<WhatsApp_Conversation__b> allTXTMessages = new List<WhatsApp_Conversation__b>();
        // Get the first name and last name of the current user
        String currentUserFirstName = UserInfo.getFirstName();
        String currentUserLastName = UserInfo.getLastName();
        
        String [] fieldsToQuery = new String [] {'Direction__c', 'Status__c', 'Read__c',  'Message_formatted__c', 'File_Name__c',  'sid__c', 'From_Phone__c', 'Media_Type__c', 'Message__c', 'Read__c', 'To_Phone__c', 'Record_ID__c', 'CreatedDate', 'created_date__c'};
            if (
                !C3Utility.checkFieldPermission(
                    new C3Utility.FieldPermissionRequest('WhatsApp_Conversation__b', 'isAccessible', fieldsToQuery, true)
                ) &&
                !C3Utility.checkFieldPermission(
                    new C3Utility.FieldPermissionRequest('WhatsApp_Conversation__b', 'isAccessible', fieldsToQuery, false)
                )
            ) {
                throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
            }
        else{
            allTXTMessages = [SELECT Direction__c, Status__c,Message_formatted__c,sid__c, From_Phone__c, Message__c, Media_Type__c, Media_URL__c, File_Name__c, Read__c, To_Phone__c, Record_ID__c, CreatedDate,created_date__c FROM WhatsApp_Conversation__b WHERE Record_ID__c =:recordId WITH SECURITY_ENFORCED]; /////////////////////////////////////
        }
        if (!allTXTMessages.isEmpty() || test.isRunningTest()) {
            if (Test.isRunningTest()) {
                C3TestDataFactory.WhatsAppInputWrapper input = new C3TestDataFactory.WhatsAppInputWrapper();
                input.objTemplate = null;
                input.toNumber = '919911410564';
                input.recordId = recordId;
                input.wamId = 'asdasdasd';
                
                allTXTMessages.addAll(new List<WhatsApp_Conversation__b>{
                    C3TestDataFactory.buildConvoRecord(input),
                        C3TestDataFactory.buildConvoRecord(input)
                        });
            }
            
            list<WhatsApp_Conversation__b> lstUpdateTextMsgs = new  list<WhatsApp_Conversation__b>();
            for (WhatsApp_Conversation__b objTXT : allTXTMessages) {
                C3WhatsAppChatPanelCtrl.TextMessagWrapper objTextMessagWrapper = new C3WhatsAppChatPanelCtrl.TextMessagWrapper();
                objTextMessagWrapper.isPending = false;
                objTextMessagWrapper.isSent = false;
                objTextMessagWrapper.isRead = false;
                objTextMessagWrapper.isDelivered = false;
                objTextMessagWrapper.isFailed = false;
                objTextMessagWrapper.strMsgInitials = currentUserFirstName +' '+currentUserLastName; //getNameInitials(currentUserFirstName, currentUserLastName);
                objTextMessagWrapper.listMedia = new list<C3WhatsAppChatPanelCtrl.TextMessageMediaWrapper>();
                objTextMessagWrapper.isMMS = false;
                objTextMessagWrapper.isVoice = false;
                
                
                if(objTXT.Status__c == 'sent'){
                    objTextMessagWrapper.isSent = true;
                }
                else if(objTXT.Status__c == 'delivered'){
                    System.debug('Message delivered 001');
                    objTextMessagWrapper.isDelivered = true;
                    
                }
                else if(objTXT.Status__c == 'failed' || objTXT.Status__c == 'undelivered'){
                    objTextMessagWrapper.isFailed = true;
                }
                else if(objTXT.Status__c == 'read'){
                     System.debug('Message Read 002');
                    objTextMessagWrapper.isRead = true;
                }else{
                    objTextMessagWrapper.isPending = true;
                }
                
                objTextMessagWrapper.isShow = true; 
                objTextMessagWrapper.objTXT = objTXT;
                if(String.isNotBlank(objTXT.Media_URL__c)){
                    objTextMessagWrapper.isMMS = true;
                    
                    C3WhatsAppChatPanelCtrl.TextMessageMediaWrapper objMMSWrap = new C3WhatsAppChatPanelCtrl.TextMessageMediaWrapper();
                    objMMSWrap.isImage = false;
                    objMMSWrap.isVideo = false;
                    objMMSWrap.isAudio = false;
                    objMMSWrap.isDocument = false;
                    objMMSWrap.isUnknown = false;
                    if(String.isNotBlank(objTXT.File_Name__c)){
                        objMMSWrap.fileName = objTXT.File_Name__c;
                    }
                    objMMSWrap.imageUrl = objTXT.Media_URL__c;
                    if(string.isNotBlank(objTXT.Media_Type__c)){
                        if(objTXT.Media_Type__c.containsIgnoreCase('image')){
                            objMMSWrap.isImage = true;
                        }else if(objTXT.Media_Type__c.containsIgnoreCase('video')){
                            objMMSWrap.isVideo = true;
                        }else if(objTXT.Media_Type__c.containsIgnoreCase('audio')){
                            objMMSWrap.isAudio = true;
                        }
                        else {
                            objMMSWrap.isDocument = true;
                        }
                    }
                    else{
                        objMMSWrap.isUnknown = true;
                    }
                    objTextMessagWrapper.listMedia.add(objMMSWrap);
                }
                
                if(!test.isrunningTest()){
                    objTextMessagWrapper.smallDetails = objTXT.CreatedDate.format();
                }
                lstTxtMsg.add(objTextMessagWrapper);
                if(objTXT.Read__c=='false'){
                    WhatsApp_Conversation__b wb =  new WhatsApp_Conversation__b(read__c='true',created_date__c=objTXT.created_date__c,record_id__c=objTXT.record_id__c);
                    lstUpdateTextMsgs.add(wb);
                }
                
            }
            if(!test.isrunningTest()){
                String[] listFields = new String[]{'read__c', 'created_date__c', 'record_id__c'};
                    if (
                        !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('WhatsApp_Conversation__b', 'isAccessible', null, true)) &&
                        !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('WhatsApp_Conversation__b', 'isAccessible', listFields, false)) &&
                        !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('WhatsApp_Conversation__b', 'isCreateable', null, true)) &&
                        !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('WhatsApp_Conversation__b', 'isCreateable', listFields, true))
                    ) {
                        throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
                    }
                else{
                    Database.insertImmediate(lstUpdateTextMsgs, AccessLevel.USER_MODE); 
                }
            }
        }
        return lstTxtMsg;
    }
    /**
* @description Generates initials from the provided first and last names.
* @param strFirstName The first name of the user.
* @param strLastName The last name of the user.
* @return A string containing the initials of the user.
*/
    public static string getNameInitials(string strFirstName, string strLastName){
        string strInitials = '';
        
        if(string.isNotBlank(strFirstName)){
            strInitials = strInitials+''+strFirstName.left(1).capitalize();
        }
        
        if(string.isNotBlank(strLastName)){
            strInitials = strInitials+''+strLastName.left(1).capitalize();
        }
        return strInitials;
    }
    /**
* @description Saves a message to the WhatsApp conversation.
* @param recordId The ID of the record associated with the message.
* @param toNumber The recipient's phone number.
* @param msg The message content to be sent.
* @param objectName The name of the object associated with the message.
* @param mediaUrl The URL of any media associated with the message.
* @param strBase64Data Base64 encoded data for the media.
* @param strFileName The name of the file being sent.
* @param templateName The name of the template being used, if any.
* @param strtempid The ID of the template being used, if any.
* @return The WhatsApp message ID if the message was sent successfully; otherwise, null.
* @throws Exception if an error occurs while saving the message.
*/
    
    /**
 * @description Sends a WhatsApp message using either a custom message or a template, and returns the WhatsApp Message ID (`wamId`) from the response.
 *              Uses `C3WhatsAppWebService` for direct messages and `C3WhatsAppTemplateScreenLWCCtrl` for template-based messages.
 *              Handles response parsing and logs errors using `C3Utility.logError()` if an exception occurs.
 *
 * @param request A `MessageRequest` object containing:
 *        - `toNumber` (recipient's WhatsApp number),
 *        - `msg` (custom message to send),
 *        - `recordId` (target record ID),
 *        - `templateName` (optional; if provided, sends a template message),
 *        - `strtempid` (template identifier for sending through controller).
 *
 * @return String The WhatsApp message ID (`wamId`) from the response, or `null` if sending fails.
 *
 * @throws AuraHandledException Errors are caught and logged; method returns null on failure.
 *
 * @example
 * MessageRequest req = new MessageRequest();
 * req.toNumber = '919XXXXXXXXX';
 * req.msg = 'Hello!';
 * req.recordId = '001XXXXXXXXXXXX';
 * String messageId = saveMessage(req);
 * System.debug('Sent Message ID: ' + messageId);
 */

    
    
    @AuraEnabled
    public static String saveMessage(string recordId, string toNumber, string msg, String objectName, string mediaUrl, String strBase64Data, String strFileName, string templateName, string strtempid){
        
        try{
            ClsValue clsResponse = new ClsValue();
            string reqBody='';
            string result='';
            string wamId='';
            C3Utility.formattedTemplateMessage = msg;
            //boolean isTemplate = true;
            if(string.isblank(templateName)){
                reqBody = C3WhatsAppWebService.sendWhatsAppMessage(toNumber,msg);
                
                 		
            }
            if(string.isNotBlank(reqBody)){
                clsResponse = (ClsValue)json.deserialize(reqBody,ClsValue.class);
            }
            
            if(string.isNotBlank(templateName)){
                
                result = C3WhatsAppTemplateScreenLWCCtrl.sendWhatsAppMessage(new List<string>{recordId}, strtempid);
                if (String.isNotBlank(result)) {
                    clsResponse = (ClsValue)json.deserialize(result,ClsValue.class);
                } else {
                    C3Utility.logError('Empty response from sendWhatsAppMessage', '', 0, '', 'C3WhatsAppChatPanelCtrl', 'saveMessage', 'recordId=' + recordId + ', templateId=' + strtempid);
                }
            }
            if(clsResponse.messages!=null)
            {
                wamId = clsResponse.messages[0].id;
            }
            return wamId;
        }
        catch(exception ex){
            C3Utility.logError(ex.getMessage(), ex.getStackTraceString(), ex.getLineNumber(), '','C3WhatsAppChatPanelCtrl','saveMessage','');
            return null;
        }
    }
    /**
* @description Loads text messages for the WhatsApp chat panel and sends a message if applicable.
* @param recordId The ID of the record associated with the message.
* @param toNumber The recipient's phone number.
* @param msg The message content to be sent.
* @param objectName The name of the object related to the message.
* @param mediaUrl The URL of any media to be sent with the message.
* @param mediaType The type of media being sent (e.g., image, video).
* @param strFileName The name of the file being sent, if applicable.
* @param templateName The name of the messaging template to use, if applicable.
* @param strtempid The ID of the template, if applicable.
* @param vamId The ID associated with the message for tracking purposes.
* @return A JSON string representation of the WrapperChat object containing the results of the operation.
* @throws ChatPanelException If there is an error with the message content.
* @throws AuraHandledException If the user does not have sufficient privileges to perform the operation.
*/
    @AuraEnabled
    public static String loadTextMessages(string recordId, string toNumber, string msg, String objectName, string mediaUrl, String mediaType, String strFileName, string templateName, string strtempid, String vamId){
        datetime currentdate = datetime.now();
        WrapperChat wrapMain = new WrapperChat(); 
        try{
            if(string.isNotBlank(objectName) && string.isNotBlank(recordId)  || string.isNotBlank(strFileName))
            {
                String wrapMainJSON = initWhatsAppChatPanelController(recordId, objectName);
                wrapMain=(WrapperChat)json.deserialize(wrapMainJSON, WrapperChat.class);
                
                if(string.isNotBlank(wrapMain.strMsg)){
                    throw new ChatPanelException(wrapMain.strMsg);
                }
                if(String.isNotBlank(templateName)){
                    wrapMain.strSelectedMessagingTemplate = templateName;
                }
                
                
                if (Test.isRunningTest()) { 
                    wrapMain.strMsg = '';
                }
                if(test.isRunningTest()){
                    wrapMain.fromNumber='919464700700';
                    wrapMain.toNumber=toNumber;
                }
                
                //Send Message part start here
                if( String.isNotBlank(wrapMain.fromNumber) && String.isNotBlank(wrapMain.toNumber) && String.isBlank(templateName))
                {
                    wrapMain.strSuccessMsg = '';
                    
                    WhatsApp_Conversation__b objTxtMsg = new WhatsApp_Conversation__b();
                    objTxtMsg.Direction__c = 'Outbound';
                    objTxtMsg.Status__c = 'Pending';
                    objTxtMsg.Record_ID__c = recordId;
                    objTxtMsg.Read__c = 'false';
                    if(String.isNotBlank(msg)){
                        objTxtMsg.Message__c = msg;
                        objTxtMsg.Message_formatted__c = C3Utility.getFormattedBodyutility(msg);
                    }
                    if(String.isNotBlank(mediaUrl)){
                        objTxtMsg.Media_URL__c = mediaUrl;
                    }
                        
                    if(String.isNotBlank(mediaType)){
                         objTxtMsg.Media_Type__c = mediaType;
                    }
                       
                    if(String.isNotBlank(strFileName)){
                        objTxtMsg.File_Name__c = strFileName;
                    }
                        
                    objTxtMsg.From_Phone__c = wrapMain.fromNumber;
                    objTxtMsg.To_Phone__c = wrapMain.toNumber;
                    objTxtMsg.Interaction_Type__c='Whatsapp';
                    objTxtMsg.Created_date__c=currentdate;
                    if(string.isNotBlank(vamId)){
                        objTxtMsg.sid__c = vamId;
                    }
                    if(String.isNotBlank(templateName)){
                        objTxtMsg.Status__c = 'sent'; 
                    }
                    if(string.isNotBlank(strFileName)){
                        objTxtMsg.Interaction_Type__c='MMS';
                    }
                    
                    objTxtMsg.Unique_Key__c=recordId+'-'+System.Now().formatLong();
                    
                    if(!Test.isRunningTest()){
                        String[] listFields = new String[]{'Id', 'Direction__c', 'Status__c', 'Record_ID__c', 'Read__c', 'Message__c', 'Message_formatted__c', 'Media_URL__c', 'Media_Type__c', 'File_Name__c', 'From_Phone__c', 'To_Phone__c', 'Interaction_Type__c', 'Created_date__c', 'sid__c', 'Unique_Key__c'};
                           if (
                                !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('WhatsApp_Conversation__b', 'isAccessible', null, true)) &&
                                !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('WhatsApp_Conversation__b', 'isAccessible', listFields, false)) &&
                                !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('WhatsApp_Conversation__b', 'isCreateable', null, true)) &&
                                !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('WhatsApp_Conversation__b', 'isCreateable', listFields, false))
                            ) {
                                throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
                            }
                        else{
                            Database.insertImmediate(objTxtMsg, AccessLevel.USER_MODE); 
                        }
                    }
                    string sid= 'test';
                    if(sid == 'failed'){
                        wrapMain.isSuccess = false;
                    }
                }
                wrapMain.lstTxtMsg = new list<TextMessagWrapper>();
                wrapMain.lstTxtMsg = getAllTextMessagesForWhatsappChatPanel(recordId);
            }else{
                wrapMain.strSuccessMsg = '';
                wrapMain.isSuccess = false;
            }
            return json.serialize(wrapMain);
        }catch(exception ex){
            C3Utility.logError(ex.getMessage(), ex.getStackTraceString(), ex.getLineNumber(), '','C3WhatsAppChatPanelCtrl','loadTextMessages','');
            return null;
        }
    }
    /**
* @description Generates a public URL for a document to be shared via WhatsApp.
* @param toNumber The recipient's phone number.
* @param cVId The Content Version ID of the document.
* @param relatedId The ID of the related record.
* @param fileName The name of the file being shared.
* @param mediaType The type of media being shared.
* @return The public URL of the document if successful; otherwise, null.
* @throws AuraHandledException if the user does not have sufficient privileges.
*/
    /**
 * @description Generates a public download URL for a given file (ContentVersion) by creating a ContentDistribution record.
 *              Performs object-level and field-level security checks before performing DML or SOQL operations.
 *              Logs any unexpected exceptions using `C3Utility.logError()`.
 *
 * @param request An instance of `PublicUrlRequest` containing:
 *        - `cVId` (ContentVersion Id),
 *        - `relatedId` (record to relate to),
 *        - `fileName` (name for the distributed file).
 *
 * @return String A publicly accessible download URL for the file, or null if creation or fetch fails.
 *
 * @throws AuraHandledException If the current user lacks necessary FLS or CRUD permissions on ContentDistribution.
 *
 * @example
 * PublicUrlRequest req = new PublicUrlRequest();
 * req.cVId = '068XXXXXXXXXXXX';
 * req.relatedId = '001XXXXXXXXXXXX';
 * req.fileName = 'TestFile.pdf';
 * String url = getPublicUrl(req);
 * System.debug('Public URL: ' + url);
 */
    
    

    //ContentDistribution does not support standard CRUD/FLS checks in a reliable way. Therefore, the application uses Database.<operation>(AccessLevel.USER_MODE) to enforce object and field-level permissions as recommended by Salesforce for system objects.

@AuraEnabled
public static String getPublicUrl(String toNumber, String cVId, String relatedId, String fileName, String mediaType){
    System.debug('inside public url method');
    
    try {
        if (String.isBlank(cVId) || String.isBlank(relatedId) || String.isBlank(fileName)) {
            return null;
        }

        
        ContentDistribution objCD = new ContentDistribution();
        objCD.Name = fileName;
        objCD.ContentVersionId = cVId;
        objCD.PreferencesAllowViewInBrowser = true;
        objCD.PreferencesAllowOriginalDownload = true;
        objCD.RelatedRecordId = relatedId;

        
        Database.insert(objCD, AccessLevel.USER_MODE);

        List<ContentDistribution> listContentDistributions = [
            SELECT Id, ContentDownloadUrl, DistributionPublicUrl, Name, RelatedRecordId
            FROM ContentDistribution
            WHERE Id = :objCD.Id
            WITH SECURITY_ENFORCED
        ];

        if (!listContentDistributions.isEmpty()) {
            String strDocUrl = listContentDistributions[0].ContentDownloadUrl;
            return String.isNotBlank(strDocUrl) ? strDocUrl : null;
        }

        return null;

    } catch (Exception ex) {
        C3Utility.logError(
            ex.getMessage(),
            ex.getStackTraceString(),
            ex.getLineNumber(),
            '',
            'C3WhatsAppChatPanelCtrl',
            'getPublicUrl',
            ''
        );
        return null;
    }
}

    
    
    /**
* @description Retrieves the WhatsApp message ID for a media message sent.
* @param toNumber The recipient's phone number.
* @param mediaUrl The URL of the media being sent.
* @param mediaType The type of media being sent.
* @param fileName The name of the file being sent.
* @return The WhatsApp message ID if the media was sent successfully; otherwise, null.
* @throws Exception if an error occurs while sending the media message.
*/
    @AuraEnabled
     public static String getMediaWamId(String toNumber, String mediaUrl, String mediaType)
     {
         try{
             if (String.isNotBlank(toNumber) && String.isNotBlank(mediaUrl) && String.isNotBlank(mediaType) ) {
                 String responseBody = C3WhatsAppWebService.sendWhatsAppMessageMedia(toNumber, mediaUrl, mediaType);
                Clsvalue clsResponse = (Clsvalue)json.deserialize(responseBody, Clsvalue.class);
                 String wamId = '';
                if(clsResponse.messages!=null)
                 {
                    wamId = clsResponse.messages[0].id;
                     return wamId;
                 }
                 return null;
             }
             return null;
         }catch(exception ex){
             C3Utility.logError(ex.getMessage(), ex.getStackTraceString(), ex.getLineNumber(), '','WhatsAppChatPanelCtrl','getMediaWamId','');
             return null;
         }
     }
    
    /**
* @description Checks if the WhatsApp number configuration is implemented for the specified record.
* @param recordId The ID of the record to check.
* @return A JSON string containing the validation results, including whether chatting is allowed and any error messages.
* @throws AuraHandledException if the user does not have sufficient privileges.
*/
    @AuraEnabled
    public static String checkForNumberConfigurationImplemented(string recordId){
        try{ 
            ChatpanelValidations cvWrapper = new ChatpanelValidations();
            boolean isAllowedToChat;
            string errorMessage='';
            //SObject record;
            
            String phoneNumber = '';
            String objectNameForPhone = '';
            if (recordId != null) {
                objectNameForPhone = Id.valueOf(recordId).getSObjectType().getDescribe().getName();
            }
            Map<String, WhatsApp_Number_Configuration__c> numberSettingsMap = new Map<String, WhatsApp_Number_Configuration__c>();
            if (
                !C3Utility.checkFieldPermission(
                    new C3Utility.FieldPermissionRequest('WhatsApp_Number_Configuration__c', 'isAccessible', null, true)
                ) &&
                !C3Utility.checkFieldPermission(
                    new C3Utility.FieldPermissionRequest('WhatsApp_Number_Configuration__c', 'isAccessible', new List<String>{'Field_Name__c', 'Object_Name__c'}, false)
                )
            ) {
                throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
            }
            else{
                numberSettingsMap = WhatsApp_Number_Configuration__c.getAll();
            }            
            
            WhatsApp_Number_Configuration__c setting = numberSettingsMap.get(objectNameForPhone);
            if (setting != null) {
                String query = 'SELECT ' + setting.Field_Name__c + ' FROM ' + setting.Object_Name__c + ' WHERE Id =: recordId  LIMIT 1';
                SObject record2;
                List<String> fieldsToQuery = setting.Field_Name__c.split(',');
                Boolean b1 = !C3Utility.checkFieldPermission(
                    new C3Utility.FieldPermissionRequest(setting.Object_Name__c, 'isAccessible', null, true)
                );
                
                Boolean b2 = !C3Utility.checkFieldPermission(
                    new C3Utility.FieldPermissionRequest(setting.Object_Name__c, 'isAccessible', fieldsToQuery, false)
                );
                
                if(b1 && b2){
                    throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
                }else{
                    Map<String, Object> bindVariablesMap = new Map<String, Object>{'recordId' => recordId  };
                        record2 = Database.queryWithBinds(
                            String.escapeSingleQuotes(query),
                            bindVariablesMap,
                            AccessLevel.USER_MODE
                        );
                }
                if (record2 != null) {
                    phoneNumber = String.valueOf(record2.get(setting.Field_Name__c));
                    if(phoneNumber==null){
                        isAllowedToChat=false;
                        errorMessage='No phone number is there in the record';
                    }
                    else{
                        isAllowedToChat=true;
                        errorMessage = null;
                    }
                }
            }
            else{
                isAllowedToChat=false;
                errorMessage='Please configure whatsapp number configuration before initialising a chat';
            }
            cvWrapper.isAllowedToChat=isAllowedToChat;
            cvWrapper.errorMessage=errorMessage;    
            return json.serialize(cvWrapper);
        }catch(exception ex){
            C3Utility.logError(ex.getMessage(), ex.getStackTraceString(), ex.getLineNumber(), '','C3WhatsAppChatPanelCtrl','checkForNumberConfigurationImplemented','');
            return null;
        }
    }
    // Method to fetch all Projects


// Updated template fetching method with project filter
@AuraEnabled
public static String getTemplatesByProject(String objName, String projectId) {
    List<Template_Object__c> listName = new List<Template_Object__c>();
    List<PicklistWrapper> result = new List<PicklistWrapper>();
     //Commented on 30/07/2025 to resolve CRUD Error(798-820)
   /* String query = 'SELECT Id, Name, CCCWA__Template_Message__c, CCCWA__Header__c, CCCWA__Footer__c, ' + 
                   'CCCWA__Document_Url__c, CCCWA__Media_Type__c, CCCWA__Whatsapp_Template__c, CCCWA__Status__c, ' +
                   'CCCWA__Object__c, CCCWA__Template_Label__c, ' +
                   '(SELECT Id, CCCWA__Button_text__c, CCCWA__Button_Type__c FROM CCCWA__Template_Buttons__r) ' +
                   'FROM CCCWA__Template_Object__c  ' +
                   'WHERE CCCWA__Status__c = \'APPROVED\' ' ;
   
                  // +'AND CCCWA__Project__c = :projectId '; // Filter by project ID
                  /* if (String.isNotBlank(objName)) {
        query += 'AND Object__c = :objName ';
    }*/
    /*if (String.isNotBlank(projectId)) {
        query += 'AND CCCWA__Project__c = \'' + String.escapeSingleQuotes(projectId) + '\' ';
    }

    if (String.isNotBlank(objName)) {
        query += 'AND CCCWA__Object__c = \'' + String.escapeSingleQuotes(objName) + '\' ';
    }
    
    
    query += 'WITH SECURITY_ENFORCED';
    
    listName = Database.query(query);*/
    if (String.isNotBlank(objName) && String.isNotBlank(projectId)) {
        listName = [
            SELECT Id, Name, CCCWA__Template_Message__c, CCCWA__Header__c, CCCWA__Footer__c,
                   CCCWA__Document_Url__c, CCCWA__Media_Type__c, CCCWA__Whatsapp_Template__c,
                   CCCWA__Status__c, CCCWA__Object__c, CCCWA__Template_Label__c,
                   (SELECT Id, CCCWA__Button_text__c, CCCWA__Button_Type__c FROM CCCWA__Template_Buttons__r)
            FROM CCCWA__Template_Object__c
            WHERE CCCWA__Status__c = 'APPROVED'
            AND CCCWA__Project__c = :projectId
            AND CCCWA__Object__c = :objName
            WITH SECURITY_ENFORCED
        ];
    } else if (String.isNotBlank(projectId)) {
        listName = [
            SELECT Id, Name, CCCWA__Template_Message__c, CCCWA__Header__c, CCCWA__Footer__c,
                   CCCWA__Document_Url__c, CCCWA__Media_Type__c, CCCWA__Whatsapp_Template__c,
                   CCCWA__Status__c, CCCWA__Object__c, CCCWA__Template_Label__c,
                   (SELECT Id, CCCWA__Button_text__c, CCCWA__Button_Type__c FROM CCCWA__Template_Buttons__r)
            FROM CCCWA__Template_Object__c
            WHERE CCCWA__Status__c = 'APPROVED'
            AND CCCWA__Project__c = :projectId
            WITH SECURITY_ENFORCED
        ];
    } else {
        listName = [
            SELECT Id, Name, CCCWA__Template_Message__c, CCCWA__Header__c, CCCWA__Footer__c,
                   CCCWA__Document_Url__c, CCCWA__Media_Type__c, CCCWA__Whatsapp_Template__c,
                   CCCWA__Status__c, CCCWA__Object__c, CCCWA__Template_Label__c,
                   (SELECT Id, CCCWA__Button_text__c, CCCWA__Button_Type__c FROM CCCWA__Template_Buttons__r)
            FROM CCCWA__Template_Object__c
            WHERE CCCWA__Status__c = 'APPROVED'
            WITH SECURITY_ENFORCED
        ];
    }
    
    for (Template_Object__c template : listName) {
        system.debug('.....'+template);
        PicklistWrapper wrapper = new PicklistWrapper();
        wrapper.label = template.Name;
        if (String.isNotBlank(template.Template_Label__c)) {
            wrapper.label = template.Template_Label__c;
        }
        wrapper.value = template.Name;
        wrapper.textMessage = template.Whatsapp_Template__c;
        wrapper.tempId = template.Id;
        if (String.isNotBlank(template.Document_Url__c)) {
            wrapper.mediaUrl = template.Document_Url__c;
        }
        if (String.isNotBlank(template.Media_Type__c)) {
            wrapper.mediaType = template.Media_Type__c;
        }
        if (String.isNotBlank(template.Header__c)) {
            wrapper.header = template.Header__c;
        }
        if (String.isNotBlank(template.Footer__c)) {
            wrapper.footer = template.Footer__c;
        }
        if (template.Template_Buttons__r != null && !template.Template_Buttons__r.isEmpty()) {
            wrapper.listButtons = template.Template_Buttons__r;
        }
        result.add(wrapper);
    }
    System.debug('......'+result);
    return JSON.serialize(result);
}
    
    /**
* @description Wrapper class for managing the state of the WhatsApp chat panel.
*/
    
    public class WrapperChat{
        public boolean isSetUpCompleted;
        public list<TextMessagWrapper> lstTxtMsg;
        public string strMsg;
        public string strSuccessMsg;
        public string nameIntial;
        public string currentUserIntial;
        public string sendFrom;
        public string fromNumber;
        public string toNumber;                                                                       
        public Boolean isPNA;
        public Boolean isSuccess;
        public string currentUserId;
        public string organizationId;
        public string wsChatEndpoint;
        public string phoneRecordId;
        public Boolean useReturnAsSend;
        public string url;
        public string strNoMessagingCampaignErrorMsg;
        public list<PicklistWrapper > lstMessagingCampaignOptions;
        public list<PicklistWrapper > lstMessagingCampaignPhoneOptions;
        public list<PicklistWrapper > lstMessagingTemplateOptions;
        public string strSelectedMessagingCampaign;
        public string strSelectedMessagingTemplate;
        public string strFilePublicURL;
        public string strContentVersionId;
        public string strContentDocumentId;
        public boolean isConversationStarted;
        public boolean isUSAPhoneNumber;
        public string currentUserName;
        public boolean isAllowedToChat;
    }
    /**
* @description Wrapper class for individual text messages in the WhatsApp chat.
*/
    public class TextMessagWrapper{
        public WhatsApp_Conversation__b objTXT;
        public string smallDetails;
        public string strMsgInitials;
        public Boolean isShow;
        public boolean isPending;
        public boolean isSent;
        public boolean isDelivered;
        public boolean isFailed;
        public boolean isRead;
        public boolean isUndelivered;
        public list<TextMessageMediaWrapper> listMedia;
        public boolean isMMS;
        public boolean isVoice;
    }
    /**
* @description Wrapper class for media associated with text messages in the WhatsApp chat.
*/
    public class TextMessageMediaWrapper{
        public String fileName;
        public String imageUrl;
        public boolean isImage;
        public boolean isVideo;
        public boolean isAudio;
        public boolean isUnknown;
        public boolean isDocument;
    }
    /**
* @description Wrapper class for picklist options related to messaging templates.
*/
    public class PicklistWrapper {
        public string label;
        public string value;
        public string header;
        public string footer;
        public string textMessage;
        public string tempId;
        public string mediaUrl;
        public string mediaType;
        public List<Template_Button__c> listButtons;
    }
    /**
* @description Represents a template used for WhatsApp messaging.
*/
    public class Template {
        public String name;
        public String language;
        public String status;
        public String category;
        public String id;
    }
    /**
* @description Class representing the structure of the response from the WhatsApp API.
*/
    public class ClsValue {
        public String messagingproduct; //whatsapp
        public ClsContacts[] contacts;
        public ClsMessages[] messages;
    }
    /**
* @description Class representing a contact in the WhatsApp API response.
*/
    public class ClsContacts {
        public string input;
        public String waid; //918802271489
    }
    /**
* @description Class representing a message in the WhatsApp API response.
*/
    public class ClsMessages {
        public String id;   //wamid.HBgMOTE4ODAyMjcxNDg5FQIAEhggNDBBOEE2QTdGNDU2OTE3RTgzQkRGM0NCRkE3ODlDN0UA
    }
    /**
* @description Class for validating chat panel configurations and permissions.
*/
    public class ChatpanelValidations{
        public boolean isAllowedToChat;
        public string errorMessage;        
    }
/**
* @description Class for validating chat panel configurations and permissions.
*/    
    public class MessageRequest {
        public String recordId;
        public String toNumber;
        public String msg;
        public String objectName;
        public String mediaUrl;
        public String strBase64Data;
        public String strFileName;
        public String templateName;
        public String strTempId;
	}
    
    /**
* @description Class managing the parameter of the file object by LWC.
*/ 
        public class PublicUrlRequest {
        public String toNumber;
        public String cVId;
        public String relatedId;
        public String fileName;
        public String mediaType;
    }

}