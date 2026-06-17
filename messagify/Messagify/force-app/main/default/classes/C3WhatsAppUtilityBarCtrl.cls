/**
* @class C3WhatsAppUtilityBarCtrl
* @description
*  This class provides utility functions for managing WhatsApp conversations and messages.
*  It includes methods for retrieving all conversation messages, handling message formatting,
*  and managing user interactions with WhatsApp.
*
*  Features:
*  - Exception Handling: Custom exception class for WhatsApp-related errors.
*  - Color Management: Predefined color list for UI elements.
*  - Message Retrieval: Fetches all conversation messages with user permissions.
*
* @access Public - Can be accessed from other classes and components.
* @author Asjad Ahmed
* @company CloudCentric
* @license Salesforce Public License (https://developer.salesforce.com/docs/atlas.en-us/apexcode.meta/apexcode/apex_license.htm)
* @version 1.0
* @date June 2025
*/
public with sharing class C3WhatsAppUtilityBarCtrl {
    /**
* @description A list of color codes used for UI elements in the WhatsApp utility bar.
*/
    public static List<String> colorList = new List<String>{'#2BA9B9', '#2ECC40', '#E08B1E', '#FF5733', '#6A0572', '#AB83A1', '#0074D9', '#FFDC00', '#2ECC40', '#FF4136', '#F012BE', '#FF851B', '#7FDBFF', '#B10DC9', '#01FF70', '#FFD700', '#00FF00', '#FF1493', '#001F3F', '#85144B', '#F1EDEC', '#7FFF00', '#B22222', '#FF8C00', '#4169E1', '#8A2BE2', '#A52A2A', '#32CD32', '#FFD700', '#9932CC', '#00FFFF', '#4B0082', '#FF6347', '#40E0D0', '#9370DB', '#808000', '#00FA9A', '#8B008B', '#800000', '#ADFF2F', '#20B2AA', '#8B4513', '#00BFFF', '#DC143C', '#6B8E23', '#FF00FF', '#00FF7F', '#8B0000', '#228B22', '#4682B4', '#D2B48C', '#556B2F', '#8B4513', '#2F4F4F', '#87CEEB', '#8B0000', '#8B4513', '#8B4513', '#008080', '#8B4513', '#8B4513', '#556B2F', '#8B4513', '#2BA9B9', '#48844B00','#E08B1E', '#FF5733', '#6A0572', '#AB83A1', '#0074D9', '#FFDC00', '#2ECC40', '#FF4136', '#F012BE', '#FF851B', '#7FDBFF', '#B10DC9', '#01FF70', '#FFD700', '#00FF00', '#FF1493', '#001F3F', '#85144B', '#F1EDEC', '#7FFF00', '#B22222', '#FF8C00', '#4169E1', '#8A2BE2', '#A52A2A', '#32CD32', '#FFD700', '#9932CC', '#00FFFF', '#4B0082', '#FF6347', '#40E0D0', '#9370DB', '#808000', '#00FA9A', '#8B008B', '#800000', '#ADFF2F', '#20B2AA', '#8B4513', '#00BFFF', '#DC143C', '#6B8E23', '#FF00FF', '#00FF7F', '#8B0000', '#228B22', '#4682B4', '#D2B48C', '#556B2F', '#8B4513', '#2F4F4F', '#87CEEB', '#8B0000', '#8B4513', '#8B4513', '#008080', '#8B4513', '#8B4513', '#556B2F', '#8B4513'};
      
    /**
* @description Custom exception class for handling WhatsApp-related errors.
*/
    public class WhatsAppException extends Exception {}
      /**
* @description Retrieves all conversation messages for the current user.
* @return A JSON serialized string containing all conversation messages.
*/
        @AuraEnabled(cacheable=true)
        public static MainWrapper allConversationMessages() 
    { 
        
        try{
            for (Integer i = 0; i < colorList.size(); i++) {
                colorList[i] = 'background:' + colorList[i];
            }
            MainWrapper wrapM=new MainWrapper();
            Integer totalUnreadCount=0;
            wrapM.currentUserId=userInfo.getUserId();
            wrapM.organizationId=UserInfo.getOrganizationId();
            List<WrapperMessage> wrapperMessageList=new List<WrapperMessage>();
            Map<String, List<CCCWA__whatsApp_conversation__b>> mapRecordIdWhatsAppConvo =new Map<String, List<CCCWA__whatsApp_conversation__b>>();
            List<CCCWA__whatsApp_conversation__b> messagesList = new List<CCCWA__whatsApp_conversation__b>();
            Map<String, CCCWA__whatsApp_conversation__b> textMessageMap=new Map<String, CCCWA__whatsApp_conversation__b>();
            String query='select id, CCCWA__From_Phone__c, CCCWA__Message__c , CCCWA__Read__c ,CCCWA__Message_formatted__c ,CCCWA__To_Phone__c,createdById,'+ 'CCCWA__Record_ID__c,createdDate'+' FROM CCCWA__whatsApp_conversation__b limit 50000';
            
            List<String> fieldsToQuery = new List<String>{'id', 'CCCWA__From_Phone__c', 'CCCWA__Message__c', 'CCCWA__Read__c', 'CCCWA__Message_formatted__c', 'CCCWA__To_Phone__c', 'createdById', 'CCCWA__Record_ID__c', 'createdDate' };
                Boolean b1 = !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__whatsApp_conversation__b', 'isAccessible', null, true));
            	Boolean b2 = !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__whatsApp_conversation__b', 'isAccessible', fieldsToQuery, false));    
            if(b1 && b2){throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
                }else{
                    messagesList = Database.Query(String.escapeSingleQuotes(query), AccessLevel.USER_MODE);
                }
            
          /*   if(Test.isRunningTest()) {
                Template_Object__c tempObj = Database.query('SELECT Id FROM Template_Object__c LIMIT 1 WITH USER MODE');
                
                C3TestDataFactory.WhatsAppInputWrapper wrapper = new C3TestDataFactory.WhatsAppInputWrapper();
                wrapper.toNumber = '919911410564';
                wrapper.recordId = tempObj.Id;
                wrapper.wamId = 'asdasdasd';
                wrapper.objTemplate = tempObj;
                
                messagesList.add(C3TestDataFactory.buildConvoRecord(wrapper));
            } */
            
            if(Test.isRunningTest()) {
                messagesList = C3WhatsAppUtilityBarCtrlTest.messageList1;
            }
            system.debug('messagesList>>' +messagesList);
            if(!messagesList.isEmpty()){
                Map<String, List<String>> recordIdsPrefix =new Map<String, List<String>>();
                Map<String, Integer> recordTotalUnreadMsgMap=new Map<String, Integer>();
                
                
                
                for(CCCWA__whatsApp_conversation__b msg:messagesList)
                {
                    if(String.isNotBlank(msg.CCCWA__Record_ID__c))
                    {
                        //prepare map of records by object to make 1 query each
                        if(!recordIdsPrefix.containsKey(String.valueOf(msg.CCCWA__Record_ID__c).substring(0,3)))
                        {
                            recordIdsPrefix.put(String.valueOf(msg.CCCWA__Record_ID__c).substring(0,3), new List<String>());
                        }
                        recordIdsPrefix.get(String.valueOf(msg.CCCWA__Record_ID__c).substring(0,3)).add(msg.CCCWA__Record_ID__c);
                        
                        //Unread message count
                        if(msg.Read__c=='false')
                        {
                            if(!recordTotalUnreadMsgMap.containsKey(msg.CCCWA__Record_ID__c))
                            {
                                recordTotalUnreadMsgMap.put(msg.CCCWA__Record_ID__c, 1);
                            }else{
                                recordTotalUnreadMsgMap.put(msg.CCCWA__Record_ID__c, (recordTotalUnreadMsgMap.get(msg.CCCWA__Record_ID__c))+1);
                            }
                        }
                    }
                    
                }
                Map<String, C3Utility.ValidRecordWrapper> validatedRecordIds= C3Utility.validateRecordIds(recordIdsPrefix);
                
                Integer maxConversations = 100;
                Integer countRecords=0;
                for(CCCWA__whatsApp_conversation__b msg : messagesList)
                {
                    if (!mapRecordIdWhatsAppConvo.containsKey(msg.CCCWA__Record_ID__c)) {
                        mapRecordIdWhatsAppConvo.put(msg.CCCWA__Record_ID__c, new List<CCCWA__whatsApp_conversation__b>());
                    }
                    mapRecordIdWhatsAppConvo.get(msg.CCCWA__Record_ID__c).add(msg);
                }
                for (String key : mapRecordIdWhatsAppConvo.keySet()) {
                    List<CCCWA__whatsApp_conversation__b> lstMegs = mapRecordIdWhatsAppConvo.get(key);
                    List<CCCWA__whatsApp_conversation__b> lstMegsSorted = new List<CCCWA__whatsApp_conversation__b>();
                    for (Integer i = mapRecordIdWhatsAppConvo.get(key).size(); i > 0; --i) {
                        lstMegsSorted.add(lstMegs[i-1]);
                    }
                    mapRecordIdWhatsAppConvo.put(key, lstMegsSorted);
                }
                integer colorIndex = 0;
                for(CCCWA__whatsApp_conversation__b msg : messagesList)
                {
                    if(countRecords< maxConversations &&String.isNotBlank(msg.CCCWA__Record_ID__c) && validatedRecordIds.containsKey(msg.CCCWA__Record_ID__c) 
                       && !textMessageMap.containsKey(msg.CCCWA__Record_ID__c))
                    {
                        textMessageMap.put(msg.CCCWA__Record_ID__c, msg);
                        
                        String objectLabel='';
                        objectLabel=validatedRecordIds.get(msg.CCCWA__Record_ID__c).objectLabel;
                        
                        WrapperMessage wrap=new WrapperMessage();
                        wrap.colorCode = colorList[colorIndex];
                        wrap.recordId=msg.CCCWA__Record_ID__c;
                        wrap.objectApiName=validatedRecordIds.get(msg.CCCWA__Record_ID__c).objectApiName;
                        wrap.lastText = '';
                        wrap.createdDate = mapRecordIdWhatsAppConvo.get(msg.CCCWA__Record_ID__c)[0].CreatedDate;
                        if (mapRecordIdWhatsAppConvo.containsKey(msg.CCCWA__Record_ID__c) && mapRecordIdWhatsAppConvo.get(msg.CCCWA__Record_ID__c)[0].CCCWA__Message__c != null ) {
                            wrap.lastText = mapRecordIdWhatsAppConvo.get(msg.CCCWA__Record_ID__c)[0].CCCWA__Message_formatted__c;
                        }
                        wrap.isRead =  mapRecordIdWhatsAppConvo.get(msg.CCCWA__Record_ID__c)[0].CCCWA__read__c;
                        
                        if(wrap.isRead=='true'){
                            wrap.booleanIsRead=true; 
                        }
                        else{
                            wrap.booleanIsRead=false;
                        }
                        
                        if(msg.Read__c=='false')
                        {
                            wrapM.boolUnreadMsgAvailable = true;
                        }
                        
                        
                        if(String.isNotBlank(validatedRecordIds.get(msg.CCCWA__Record_ID__c).recordName))
                        {
                            wrap.senderNameSmall = C3Utility.getNameDetails(validatedRecordIds.get(msg.CCCWA__Record_ID__c).recordName).get('senderNameSmall');
                            wrap.senderName = C3Utility.getNameDetails(validatedRecordIds.get(msg.CCCWA__Record_ID__c).recordName).get('senderName')+' ('+objectLabel+')';
                        }
                        wrap.unreadCount=0;
                        if(recordTotalUnreadMsgMap.containsKey(msg.CCCWA__Record_ID__c))
                        {
                            wrap.unreadCount=recordTotalUnreadMsgMap.get(msg.CCCWA__Record_ID__c);
                        }
                        totalUnreadCount+=wrap.unreadCount;
                        
                        wrapperMessageList.add(wrap);
                        countRecords++;
                        colorIndex++;
                    }
                }
                
            }
            if(wrapperMessageList != null && wrapperMessageList.size() > 0) {
                for(Integer i=0; i<wrapperMessageList.size(); i++) {
                    for(Integer j=i+1; j<wrapperMessageList.size(); j++) {
                        if(wrapperMessageList[i].createdDate < wrapperMessageList[j].createdDate) {
                            wrapperMessage temp = wrapperMessageList[i];
                            wrapperMessageList[i] = wrapperMessageList[j];
                            wrapperMessageList[j] = temp;
                        }
                    }
                }
            }
            list<WrapperMessage> unreadMessages = new list<WrapperMessage>();
            list<WrapperMessage> readMessages = new list<WrapperMessage>();
            for(WrapperMessage wrp : wrapperMessageList){
                if(wrp.unreadCount!=0){
                    unreadMessages.add(wrp);
                }
                else{
                    readMessages.add(wrp);
                }
            }
            wrapM.wrapperMessageList = unreadMessages;
            wrapM.wrapperMessageList.addall(readMessages);
            //wrapM.wrapperMessageList=wrapperMessageList;
            
            wrapM.totalUnreadCount=totalUnreadCount;
            
            return wrapM;
        }catch(exception ex){
            C3Utility.logError(ex.getMessage(), ex.getStackTraceString(), ex.getLineNumber(), '','UtilityBarClass','AllConversationMessages','');
            return null;
        } 
    }
    
    
    /**
* @description Wrapper class for managing main data related to WhatsApp messages.
*/
    public class MainWrapper{
         @AuraEnabled public string currentUserId;
         @AuraEnabled public string organizationId;
         @AuraEnabled public string strMsg;
         @AuraEnabled public List<WrapperMessage> wrapperMessageList;
         @AuraEnabled public boolean boolUnreadMsgAvailable;
        
        @AuraEnabled public Integer totalUnreadCount=0;
    }
    /**
* @description Wrapper class for individual WhatsApp messages.
*/
    public class WrapperMessage {
        @AuraEnabled  public string recordId;
        @AuraEnabled  public string objectApiName;
        @AuraEnabled  public string senderNameSmall;
         @AuraEnabled public string senderName;
         @AuraEnabled public string lastText;
        @AuraEnabled  public string isRead;
         @AuraEnabled public string colorCode;
         @AuraEnabled public Integer unreadCount=0;
         @AuraEnabled public boolean booleanIsRead;
         @AuraEnabled public datetime createdDate;
    }
}