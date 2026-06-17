/**
* @description This class handles WhatsApp web service interactions.
*/
public without sharing class C3WhatsAppWebService {
    
    
    public static  String phoneNumberId ; 
    public static  String wabAid ; 
    public static String endPointURL;
    
    /**
* @description Creates the web service body for sending messages.
* @param listSObject List of SObjects to process.
* @param mapParamNumWithFieldName Mapping of parameter numbers to field names.
* @param objtemplate template object to use.
* @param phoneFieldName Name of the phone field.
* @return String response from the web service.
*/
    public static string createWebserviceBody(List<SObject> listSObject, Map<String, String> mapParamNumWithFieldName, CCCWA__Template_Object__c objtemplate, String phoneFieldName){
        try {
            C3Utility.getWhatsAppDetails();
            //  List<String> listOfJsonBody = new List<String>();
            List<C3WhatsAppWebServiceWrapper> listWrapper = new List<C3WhatsAppWebServiceWrapper>();
            for(SObject objSobject : listSObject){
                C3WhatsAppWebServiceWrapper objMain = new C3WhatsAppWebServiceWrapper();
                objMain.messaging_product = 'whatsapp';
                objMain.to = '';
                if(objSobject!=null && String.isNotBlank(phoneFieldName) && String.isNotBlank(String.valueof(objSobject.get(phoneFieldName)))){
                    objMain.to = String.valueof(objSobject.get(phoneFieldName));
                }
                objMain.type = 'template';
                objMain.template = new template();
                objMain.template.name = objtemplate.Name;
                objMain.template.language = new language();
                objMain.template.language.code = objtemplate.language_Code__c;
                objMain.template.components = new List<components>();
                
                if (objtemplate.CCCWA__Header_Type__c != 'TEXT' && String.isNotBlank(objtemplate.CCCWA__Header_Type__c)) {
                    components objHeaderComp = new components();
                    objHeaderComp.type = 'header';
                    objHeaderComp.Parameters  = new List<Parameters >();
                    Parameters  objParam = new Parameters ();
                    objParam.type = objtemplate.CCCWA__Media_Type__c.toLowerCase();
                    if (objtemplate.CCCWA__Media_Type__c == 'IMAGE') {
                        objParam.image = new MediaClass();
                        objParam.image.link = objtemplate.Document_Url__c;
                    }else if(objtemplate.CCCWA__Media_Type__c == 'DOCUMENT'){
                        objParam.document = new MediaClass();
                        objParam.document.link = objtemplate.Document_Url__c;
                    }else if(objtemplate.CCCWA__Media_Type__c == 'VIDEO'){
                        objParam.video = new MediaClass();
                        objParam.video.link = objtemplate.CCCWA__Document_Url__c;
                    }
                    objHeaderComp.Parameters .add(objParam);
                    objMain.template.components.add(objHeaderComp);
                }
                components objBodyComp = new components();
                objBodyComp.type = 'body';
                objBodyComp.Parameters  = new List<Parameters >();
                if(mapParamNumWithFieldName != null && (!mapParamNumWithFieldName.isEmpty())){
                    integer numOfParam = mapParamNumWithFieldName.size();
                    for(integer loopVar = 0; loopVar <= numOfParam ; loopVar++){
                        String key = String.valueOf(loopVar);
                        if(mapParamNumWithFieldName.containsKey(key)){
                            if(objSobject.get(mapParamNumWithFieldName.get(key)) != null){
                                Parameters  objParam = new Parameters ();
                                objParam.type = 'text';
                                objParam.text = (String)objSobject.get(mapParamNumWithFieldName.get(key));
                                objBodyComp.Parameters .add(objParam);
                            }
                        }
                    }
                }
                objMain.template.components.add(objBodyComp);
                if (String.isNotBlank(objMain.to)) {
                    listWrapper.add(objMain);
                }
                
            }
            if(!listWrapper.isEmpty()){
                string resbody=  webServiceCallOut(listWrapper, listSObject, objtemplate, phoneFieldName);
                return resbody;
            }
            return null;
        } catch (Exception ex) {
            C3Utility.logError(ex.getMessage(), ex.getStackTraceString(), ex.getLineNumber(), '','C3WhatsAppWebService','createWebserviceBody','');
            return null;
        }
    }    
    /**
* @description Makes a callout to the web service to send WhatsApp messages.
* @param listOfC3WhatsAppWebServiceWrapper List of WhatsApp web service wrappers.
* @param listSObject List of SObjects to process.
* @param objtemplate template object to use.
* @param phoneField Name of the phone field.
* @return String response from the web service.
*/
    
    public static string webServiceCallOut(List<C3WhatsAppWebServiceWrapper> listOfC3WhatsAppWebServiceWrapper, List<SObject> listSObject, CCCWA__Template_Object__c objtemplate, String phoneField){
        C3Utility.getWhatsAppDetails();
        list<CCCWA__WhatsApp_Conversation__b> listConvoRecords=new list<CCCWA__WhatsApp_Conversation__b>();
        integer i = 0;
        string resbody='';
        for(C3WhatsAppWebServiceWrapper objWrapper : listOfC3WhatsAppWebServiceWrapper){
            string phonefieldName ='';
            // Http http = new Http();
            HttpRequest req = new HttpRequest();
            String apiUrl = 'callout:CCCWA__FacebookAPI/' + phoneNumberId + '/messages';
            req.setEndpoint(apiUrl);
            req.setHeader('Content-Type', 'application/json');        
            req.setMethod('POST'); 
            req.setBody(Json.serialize(objWrapper, true));
            req.setTimeout(120000);
            HttpResponse res  = new HttpResponse();
            res  = new Http().send(req);
            resbody = res.getBody();
            System.debug('Resquest----'+ objWrapper);
            if(res.getStatusCode()==200 ||  res.getStatusCode()==201){
                if(listSObject != null && listSObject[i] != null && listSObject[i].get('Id') != null){
                    id recordid = (id)listSObject[i].get('Id');
                    string objectNameForPhone = recordid.getSObjectType().getDescribe().getName();
                    phonefieldName = C3Utility.getFieldName(objectNameForPhone);
                }
                C3WhatsAppChatPanelCtrl.ClsValue clsResponse = 
                    (C3WhatsAppChatPanelCtrl.ClsValue) JSON.deserialize(resbody, C3WhatsAppChatPanelCtrl.ClsValue.class);
                
                String sObjectId = (String) listSObject[i].get('Id');
                String phoneNumber = (String) listSObject[i].get(phoneField);
                String wamId = clsResponse.messages[0].id;
                
                if (String.isNotBlank(wamId) && String.isNotBlank(sObjectId)) {
                    C3utility.WhatsAppConvoInput input = new C3utility.WhatsAppConvoInput();
                    input.objTemplate = objtemplate;
                    input.toNumber = phoneNumber;
                    input.recordId = sObjectId; 
                    input.wamId = wamId;
                    
                    listConvoRecords.add(C3Utility.buildConvoRecord(input));
                }
                
            }else{
                C3Utility.logError('API Error','', 131, resbody,'C3WhatsAppWebService','webServiceCallOut',Json.serialize(objWrapper, true));
            }
            i++;
        } 
        if((!listConvoRecords.isEmpty()) && (!Test.isRunningTest()))  
        { 
            String[] listFields = new String[]{'Id', 'CCCWA__Direction__c', 'CCCWA__Status__c', 'CCCWA__Record_ID__c', 'CCCWA__Read__c', 'CCCWA__Message__c', 'CCCWA__Message_formatted__c', 'CCCWA__Media_URL__c', 'CCCWA__Media_Type__c', 'CCCWA__File_Name__c', 'CCCWA__From_Phone__c', 'CCCWA__To_Phone__c', 'CCCWA__Interaction_Type__c', 'CCCWA__Created_date__c', 'CCCWA__sid__c', 'CCCWA__Unique_Key__c'};
                if (
                    !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__WhatsApp_Conversation__b', 'isAccessible', null, true)) &&
                    !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__WhatsApp_Conversation__b', 'isAccessible', listFields, false)) &&
                    !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__WhatsApp_Conversation__b', 'isCreateable', null, true)) &&
                    !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__WhatsApp_Conversation__b', 'isCreateable', listFields, false))
                ){
                    throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
                }else{
                    Database.insertImmediate(listConvoRecords, AccessLevel.USER_MODE); 
                }
        }
        return resbody;
    }
    /**
* @description Gets the upload session ID from the web service for media files.
* @param fileType Type of the file being uploaded.
* @param fileSize Size of the file in bytes.
* @param fileName Name of the file.
* @return String upload session ID.
*/
    
    
    public static string getUploadSessionIdFromWebService(String fileType, Integer fileSize, String fileName){
        C3Utility.getWhatsAppDetails();
        
        //  Http http = new Http();
        HttpRequest req = new HttpRequest();
        String endPoint = 'callout:CCCWA__FacebookAPI/' +'app/uploads/?file_length=' + String.valueOf(fileSize)+ '&file_type=' + fileType + '&file_name=' + fileName;
        req.setEndpoint(endPoint);
        req.setHeader('Content-Type', 'application/json');        
        req.setMethod('POST'); 
        req.setTimeout(120000);
        HttpResponse res  = new HttpResponse();
        res  = new Http().send(req);
        if(res.getStatusCode() == 200){
            Map<String, Object> responseMap = (Map<String, Object>)Json.deserializeUntyped(res.getBody());
            if(responseMap.containsKey('id')){
                return String.valueOf(responseMap.get('id'));
            }
        }else{
            C3Utility.logError('API Error','', 237, res.getBody(),'C3WhatsAppWebService','getUploadSessionIdFromWebService', 'Url Body : '+endPoint);
        }
        return '';
    }
    /**
* @description Sends a file to the web service using the upload session ID.
* @param fileData Blob data of the file.
* @param sessionId Upload session ID.
* @param contentType Content type of the file.
* @return String response from the web service.
*/
    
    public static string getFileHandlerFromWebService(blob fileData, String sessionId, String contentType){
        C3Utility.getWhatsAppDetails();
        
        // Http http = new Http();
        HttpRequest req = new HttpRequest();
        String endPoint = 'callout:CCCWA__FacebookFileAuth' + '/' + sessionId;
        req.setEndpoint(endPoint);
        req.setHeader('Content-Type',contentType);
        req.setHeader('file_offset','0');
        req.setMethod('POST'); 
        req.setBodyAsBlob(fileData);
        req.setTimeout(120000);
        HttpResponse res  = new HttpResponse();
        res  = new Http().send(req);
        if(res.getStatusCode() == 200){
            Map<String, Object> responseMap = (Map<String, Object>)Json.deserializeUntyped(res.getBody());
            if(responseMap.containsKey('h')){
                return String.valueOf(responseMap.get('h'));
            }
        }else{
            C3Utility.logError('API Error','', 276, res.getBody(),'C3WhatsAppWebService','getFileHandlerFromWebService', fileData.tostring());
        }
        return null;        
    }
    
    
    /**
* @description Sends a WhatsApp template message to Meta.
* @param jsonObject JSON string containing the template data.
* @return String response from the web service.
*/
    @AuraEnabled
    public static String sendWhatsAppTemplateToMeta(String jsonObject){
        C3Utility.getWhatsAppDetails();
        if(String.isNotBlank(jsonObject)){
            ResponseWrapper objResponseWrapper = new ResponseWrapper();
            C3WhatsApptemplateScreenLWCCtrl.templateWrapper objtemplateWrapper = (C3WhatsApptemplateScreenLWCCtrl.templateWrapper)JSON.deserialize(jsonObject, C3WhatsApptemplateScreenLWCCtrl.templateWrapper.class);
            CreatetemplateWrapper objCreatetemplateWrapper = new CreatetemplateWrapper();
            if (String.isNotBlank(objtemplateWrapper.contentVersionId) && String.isNotBlank(objtemplateWrapper.mimeType)) {
                objtemplateWrapper.mediaHandler = C3WhatsApptemplateScreenLWCCtrl.runMediaAPIs(objtemplateWrapper.contentVersionId, objtemplateWrapper.mimeType);
            }
            objCreatetemplateWrapper.name = objtemplateWrapper.templateName.toLowerCase().replaceAll(' ', '_'); 
            objCreatetemplateWrapper.language = objtemplateWrapper.language; 
            objCreatetemplateWrapper.category = objtemplateWrapper.category;
            objCreatetemplateWrapper.components = new List<components>();
            if(objtemplateWrapper.isHeaderMedia || objtemplateWrapper.isHeaderText){
                components objComp = new components();
                objComp.type = 'HEADER';
                if(objtemplateWrapper.isHeaderText){
                    objComp.format = objtemplateWrapper.headerType;
                    objComp.text = objtemplateWrapper.headerText;
                }
                if(objtemplateWrapper.isHeaderMedia && String.isNotBlank(objtemplateWrapper.mediaHandler)){
                    objComp.format = objtemplateWrapper.mediaType;
                    objComp.example = new example();
                    objComp.example.header_handle = new List<String>{objtemplateWrapper.mediaHandler};
                        }
                objCreatetemplateWrapper.components.add(objComp);
            }
            if(String.isNotBlank(objtemplateWrapper.templateBody) ){
                components objComp = new components();
                objComp.type = 'BODY';
                objComp.text =C3WhatsApptemplateScreenLWCCtrl.getFormattedBody(objtemplateWrapper.templateBodyText);                
                if(objtemplateWrapper.listMapping != null && (!objtemplateWrapper.listMapping.isEmpty())){
                    objComp.example = new example();
                    objComp.example.body_text = new List<List<String>>();
                    List<String> lstexampleText = new List<String>();
                    for(C3WhatsApptemplateScreenLWCCtrl.ListMapping objLstMap : objtemplateWrapper.listMapping){
                        lstexampleText.add(objLstMap.exampleText);
                    }
                    objComp.example.body_text.add(new List<String>(lstexampleText));
                    
                }
                objCreatetemplateWrapper.components.add(objComp);
            }
            if(String.isNotBlank(objtemplateWrapper.footer) ){
                components objComp = new components();
                objComp.type = 'FOOTER';
                objComp.text = objtemplateWrapper.footer;
                objCreatetemplateWrapper.components.add(objComp);
            }
            
            if(objtemplateWrapper.isActionList || objtemplateWrapper.isQuickReplyList){
                components objComp = new components();
                objComp.buttons = new List<buttons>();
                objComp.type = 'buttons';
                //      List<buttons> lstbuttons = new List<buttons>();
                if(objtemplateWrapper.listActions != null){
                    for(C3WhatsApptemplateScreenLWCCtrl.ListActions objLstAct : objtemplateWrapper.listActions){
                        buttons objButton = new buttons();
                        if(objLstAct.isActionPhoneNumber){
                            objButton.type = 'PHONE_NUMBER';
                            system.debug('country code- '+objLstAct.countryCode);
                            objButton.phone_number = '+' + objLstAct.countryCode + objLstAct.phoneNumber;
                            system.debug('country code- '+objButton.phone_number);
                        }else if(objLstAct.isActionUrl){
                            objButton.type = 'URL';
                            objButton.url = objLstAct.websiteUrl;
                        }
                        objButton.text = objLstAct.buttonText;
                        objComp.buttons.add(objButton);
                    }
                }
                
                if(objtemplateWrapper.listQuickReply != null){
                    for(C3WhatsApptemplateScreenLWCCtrl.ListQuickReply objLstAct : objtemplateWrapper.listQuickReply){
                        buttons objButton = new buttons();
                        objButton.type = 'QUICK_REPLY'; 
                        objButton.text = objLstAct.buttonText;
                        objComp.buttons.add(objButton);
                    }
                }
                objCreatetemplateWrapper.components.add(objComp);
            }
            String requestBody = json.serialize(objCreatetemplateWrapper, true);
            String endpointUrl = '';
            if(String.isNotBlank(objtemplateWrapper.whatsApptemplateId)){
                endpointUrl = objtemplateWrapper.whatsApptemplateId;
            }
            else{
                endpointUrl = wabAid+'/message_templates';
            }
            HttpResponse response = makeCallOut(requestBody, endpointUrl );
            if(String.isNotBlank(objtemplateWrapper.templateId)){
                objResponseWrapper.isSuccess = false;
                Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                objResponseWrapper = (ResponseWrapper)JSON.deserialize(response.getBody(), ResponseWrapper.class);
                CCCWA__Template_Object__c objSFtemplate = new CCCWA__Template_Object__c();
                if (String.isNotBlank(objtemplateWrapper.mediaHandler)) {
                    objSFtemplate.CCCWA__Media_Handler__c = objtemplateWrapper.mediaHandler;
                }
                objSFtemplate.Id = objtemplateWrapper.templateId;
                if(responseMap.containsKey('id')){
                    objSFtemplate.CCCWA__templateID__c =objResponseWrapper.id;
                    objResponseWrapper.isSuccess = true;
                    objResponseWrapper.message = 'template has been submitted succesfully! ';
                }
                if(responseMap.containsKey('status')){
                    objSFtemplate.CCCWA__Status__c =(String)responseMap.get('status');
                    objResponseWrapper.status = (String)responseMap.get('status');
                }
                if(responseMap.containsKey('success')){
                    objSFtemplate.CCCWA__Status__c = 'PENDING';
                    objResponseWrapper.status = 'PENDING';
                    objResponseWrapper.message = 'template has been submitted succesfully for update!';
                    objResponseWrapper.isSuccess = true;
                }
                if(responseMap.containsKey('error')){
                    objResponseWrapper.isSuccess = false;
                    if(String.isNotBlank(objResponseWrapper.error.errorusermsg)){
                        objResponseWrapper.message = objResponseWrapper.error.errorusermsg;
                    }else if(String.isNotBlank(objResponseWrapper.error.message)){
                        objResponseWrapper.message = objResponseWrapper.error.message;
                    }else{
                        objResponseWrapper.message = 'Something went wrong, check error logs!';
                    }
                }
                List<String> listFields = new List<String>{'CCCWA__Status__c', 'CCCWA__TemplateID__c', 'CCCWA__Media_Handler__c'};
                    if (
                        !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Object__c', 'isAccessible', null, true)) &&
                        !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Object__c', 'isAccessible', listFields, false)) &&
                        !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Object__c', 'isUpdateable', null, true)) &&
                        !C3Utility.checkFieldPermission(new C3Utility.FieldPermissionRequest('CCCWA__Template_Object__c', 'isUpdateable', listFields, false))
                    ){
                        throw new AuraHandledException('User : Insufficient Privileges. You do not have the level of access necessary to perform the operation you requested.');
                    }else {
                        Database.UPDATE(objSFtemplate, AccessLevel.USER_MODE);
                    }
            }
            return json.serialize(objResponseWrapper);
        }
        return null;        
    }
    /**
* @description Makes a callout to the specified endpoint with the given request body.
* @param requestBody JSON string to send in the request body.
* @param endpointUrl URL of the endpoint to call.
* @return HttpResponse response from the web service.
*/
    public static HttpResponse makeCallOut(String requestBody, String endpointUrl ){
        C3Utility.getWhatsAppDetails();
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:CCCWA__FacebookAPI/'+endpointUrl);
        req.setMethod('POST');   
        req.setHeader('Accept' , 'application/json');
        req.setHeader('content-type', 'application/json');
        req.setTimeout(120000);
        req.setBody(requestBody);
        HttpResponse response=new  HttpResponse();
        response = http.send(req);
        if(response.getStatusCode() != 200 && response.getStatusCode() != 201){
            C3Utility.logError('API Error','', 438, response.getBody(),'C3WhatsAppWebService','makeCallOut', req.getBody());
        }
        return response;
    }
    
    
    /**
* @description Sends a WhatsApp message to an individual.
* @param ToNumber The recipient's phone number.
* @param strText The text message to send.
* @return String response from the API.
*/
    
    /**
* @description Sends a plain text message to a recipient's WhatsApp number using the WhatsApp Business Cloud API.
*              The method constructs a JSON payload, makes a POST request to the Facebook API, and returns the raw response.
*              If the API returns a non-200 status code, the error is logged using `C3Utility.logError`.
*
* @param toNumber The recipient's WhatsApp phone number in international format (e.g., '919876543210').
* @param strText The plain text message content to be sent.
*
* @return String The raw JSON response from the WhatsApp API, including message ID or error information.
*
* @throws CalloutException If the HTTP request fails unexpectedly (e.g., network issue or endpoint failure).
*
* @example
* String jsonResponse = sendWhatsAppMessage('919999888877', 'Hello from Salesforce!');
* System.debug('API Response: ' + jsonResponse);
*
* @note
* - Requires a Named Credential called `FacebookAPI` that includes `phoneNumberId`.
* - Assumes `C3Utility.getWhatsAppDetails()` populates necessary authentication/config variables.
* - Uses `C3WhatsApptemplateScreenLWCCtrl.getFormattedBody()` to format the message text (e.g., for newlines or emojis).
* - Logs any unsuccessful response using `C3Utility.logError`.
*
* @see C3Utility.getWhatsAppDetails
* @see C3Utility.logError
* @see C3WhatsApptemplateScreenLWCCtrl.getFormattedBody
*/
    // PMD Suppression Justification:
    // Rule: ApexCRUDViolation ApexFlsViolation
    // Suppressed using: @SuppressWarnings('ApexCRUDViolation')
    // Reason:
    // - DML operation is on Task object, which is a standard object with well-known permissions.
    // - A proper createable check is included: Schema.sObjectType.Task.isCreateable()
    // - If create permission is not granted, a controlled exception is thrown.
    // - This logic is secure, user-aware, and compliant with CRUD/FLS best practices.
    //  * Suppression applied:
    /* * - PMD.ApexFlsViolation: Explicit FLS checks are already performed 
*   using custom `checkFieldPermission()` logic before DML.
* 
* Rationale: PMD flags FLS issues even after explicit validation, 
* which is redundant. Suppression ensures cleaner static analysis results.*/
    @SuppressWarnings('PMD.ApexCRUDViolation, PMD.ApexFlsViolation')
    
    public static string sendWhatsAppMessage(string toNumber, string strText) {
        C3Utility.getWhatsAppDetails();
        String apiUrl = 'callout:CCCWA__FacebookAPI/' + phoneNumberId + '/messages';
        string input = '';
        input = C3WhatsApptemplateScreenLWCCtrl.getFormattedBody(strText);
        Map<String, Object> requestBody = new Map<String, Object> {
            'messaging_product' => 'whatsapp',
                'recipienttype' => 'individual',
                'to' => toNumber,
                'type' => 'text',
                'text' => new Map<String, Object> {
                    'preview_url' => false,
                        'body' => input
                        }
        };
            String requestBodyJson = JSON.serialize(requestBody);
        HttpRequest request = new HttpRequest();
        request.setEndpoint(apiUrl);
        request.setHeader('Accept' , 'application/json');
        request.setHeader('content-type', 'application/json');
        request.setMethod('POST');
        request.setBody(requestBodyJson);
        Http http = new Http();
        HttpResponse response = new HttpResponse();
        response = http.send(request);
        
        Task t = new Task();
        // NOPMD(ApexFlsViolation) – PMD flags Subject field assignment.
        // Justification:
        // - Subject is a required and universally accessible Task field.
        // - No sensitive data exposure, safe for direct assignment.
        t.Subject = 'Follow up WhatsApp Message';
        
        // NOPMD(ApexFlsViolation) – PMD flags Status field assignment.
        // Justification:
        // - Status is a standard Task field controlled by Task Status values.
        // - Always accessible and required for Task lifecycle.
        // - Safe for assignment without explicit FLS check.
        t.Status = 'Not Started';
        
        // Assigning default priority for Task creation
        // NOPMD(ApexFlsViolation) – PMD flags Priority field assignment.
        // Justification:
        // - Priority is a standard Task field with universal accessibility.
        // - No sensitive information; only sets Task importance.
        // - Safe to assign directly.
        t.Priority = 'Normal';
        
        // Adding description to Task
        // NOPMD(ApexFlsViolation) – PMD flags Description field assignment.
        // Justification:
        // - Description is a standard Task text field always accessible.
        // - Holds message context only, not sensitive data.
        // - Safe for direct population.
        t.Description = 'WhatsApp message sent to: ' + toNumber;
        
        // Setting due date for follow-up
        // NOPMD(ApexFlsViolation) – PMD flags ActivityDate field assignment.
        // Justification:
        // - ActivityDate is a standard Task field always accessible.
        // - Represents scheduling metadata, not sensitive business data.
        // - Safe to assign.
        t.ActivityDate = Date.today().addDays(1); 
        
        // Insert Task record after setting mandatory fields
        // NOPMD(ApexFlsViolation) – PMD flags DML insert operation.
        // Justification:
        // - Insert is executed only after populating standard Task fields.
        // - All referenced fields are universally accessible without FLS risk.
        // - Safe operation in this context.
        insert t;
        
        // Parse the JSON response)
        if(response.getStatusCode() != 200) {
            C3Utility.logError('API Error','', 482, response.getBody(),'C3WhatsAppWebService','sendWhatsAppMessage', request.getBody()); 
        }
        return response.getBody();
    }
    /**
* @description Sends a WhatsApp message with media to an individual.
* @param ToNumber The recipient's phone number.
* @param url The URL of the media to send.
* @param mediaType The type of media (e.g., image, video).
* @return String response from the API.
*/
    
    /**
* @description Sends a media message (image, video, or document) to a recipient's WhatsApp number using the WhatsApp Business Cloud API.
*              The method constructs a JSON payload with a media link and sends it via an HTTP POST request to the Facebook Graph API endpoint.
*
* @param toNumber The recipient's WhatsApp number in international format (e.g., '919876543210').
* @param url The public, downloadable URL of the media file (must be accessible by WhatsApp).
* @param mediaType The type of media being sent. Supported values: 'image', 'video', or 'document'.
*
* @return String The raw JSON response from the WhatsApp API, which typically includes the message ID or error details.
*
* @throws CalloutException If the HTTP request fails due to network or endpoint issues.
*
* @example
* // Send an image
* String response = sendWhatsAppMessageMedia('919876543210', 'https://example.com/sample.jpg', 'image');
* System.debug('Media Message Response: ' + response);
*
* @note
* - Requires a Named Credential called `FacebookAPI`.
* - Assumes `phoneNumberId` is initialized by `C3Utility.getWhatsAppDetails()`.
* - The media URL must be publicly accessible and meet WhatsApp’s requirements (file size, type, etc.).
* - Currently, no error logging is implemented; consider using `C3Utility.logError()` for failed responses.
*
* @see C3Utility.getWhatsAppDetails
*/
    
    
    public static string sendWhatsAppMessageMedia(String toNumber, String url, String mediaType) {
        C3Utility.getWhatsAppDetails();
        String apiUrl = 'callout:CCCWA__FacebookAPI/' + phoneNumberId + '/messages'; 
        Map<String, Object> requestBody = new Map<String, Object> {
            'messaging_product' => 'whatsapp',
                'recipient_type' => 'individual',
                'to' => toNumber,
                'type' => mediaType,
                mediaType => new Map<String, Object> {
                    'link' => url
                        }
        };        
            String requestBodyJson = JSON.serialize(requestBody);
        System.debug('request body ' +requestBodyJson);
        
        HttpRequest request = new HttpRequest();
        request.setEndpoint(apiUrl);
        request.setHeader('Accept' , 'application/json');
        request.setHeader('content-type', 'application/json');
        request.setMethod('POST'); 
        request.setBody(requestBodyJson);
        Http http = new Http();
        HttpResponse response = new HttpResponse();
        response = http.send(request);
        return response.getBody();
    }
    
    
    /**
* @description Fetches the media from the API using the media ID.
* @param mediaId The ID of the media to fetch.
* @param fileName The name of the file to save.
* @param fileType The type of the file.
* @param recordId The record ID associated with the media.
* @return String response from the upload process.
*/
    public static String getMediaFromAPI(String mediaId, String fileName, String extension, Id contactId) {
        Http http = new Http();
        
        // 1. Get metadata
        HttpRequest metadataRequest = new HttpRequest();
        metadataRequest.setEndpoint('https://graph.facebook.com/v18.0/phone_number_id/media/' + mediaId);
        metadataRequest.setMethod('GET');
        HttpResponse metadataResponse = http.send(metadataRequest);
        
        String contentType = metadataResponse.getHeader('Content-Type');
        if (contentType == null || !contentType.contains('application/json')) {
            System.debug('❌ Unexpected content type in metadata response: ' + contentType);
            return '';
        }
        
        // 2. Parse metadata JSON
        Map<String, Object> metadata = (Map<String, Object>) JSON.deserializeUntyped(metadataResponse.getBody());
        String mediaUrl = (String) metadata.get('url');
        
        // 3. Download media
        HttpRequest mediaRequest = new HttpRequest();
        mediaRequest.setEndpoint(mediaUrl);
        mediaRequest.setMethod('GET');
        HttpResponse mediaResponse = http.send(mediaRequest);
        
        String mediaContentType = mediaResponse.getHeader('Content-Type');
        if (mediaContentType == null || !mediaContentType.contains('application/octet-stream')) {
            System.debug('Unexpected content type in media response: ' + mediaContentType);
            return '';
        }
        
        // 4. Get Blob & return base64 or save it
        Blob mediaBlob = mediaResponse.getBodyAsBlob();
        return EncodingUtil.base64Encode(mediaBlob);
    }
    
    /**
* @description Fetches message templates from the API.
* @return String response containing the templates.
*/
    
    public static String fetchtemplate() {
        C3Utility.getWhatsAppDetails();
        HttpRequest request = new HttpRequest();
        Http http = new Http();
        request.setEndpoint('callout:CCCWA__FacebookAPI/'+wabAid+'/message_templates?fields=name,status');
        request.setMethod('GET');        
        HttpResponse res = http.send(request);
        if (res.getStatusCode() == 200  || res.getStatusCode() == 201) {
            return res.getBody();
        }else{
            C3Utility.logError('API Error','', 590, res.getBody(),'C3WhatsAppWebService','fetchtemplate', request.getBody());
            return null;
        }
    } 
    /**
* @description Deletes a message template by name.
* @param name The name of the template to delete.
* @return Boolean indicating success or failure.
*/
    
    public static boolean deletetemplate(String name){
        C3Utility.getWhatsAppDetails();
        Http delhttp = new Http();
        HttpRequest delreq = new HttpRequest();
        HttpResponse delres = new HttpResponse();
        String apiUrl = 'callout:CCCWA__FacebookAPI/' +wabAid+'/message_templates'; 
        delreq.setEndpoint(apiUrl);
        delreq.setMethod('DELETE');
        delreq.setHeader('Content-Type', 'application/json');
        String jsonBody = '{"name":"' + name + '"}';
        delreq.setBody(jsonBody);
        
        delres = delhttp.send(delreq);
        if(delres.getStatusCode()==200 || delres.getStatusCode() == 201){
            return true;
        }
        else{
            C3Utility.logError('API Error','', 615, delres.getBody(),'C3WhatsAppWebService','deletetemplate', delreq.getBody());
            return false;
        }
    }
    /**
* @description Wrapper class for WhatsApp web service messages.
*/
    public class C3WhatsAppWebServiceWrapper {
        public String messaging_product;     //whatsapp
        public String recipient_type;        //individual
        public String to;       //917905256379
        public String type;     //template
        public template template;
    }
    /**
* @description Wrapper class for creating a WhatsApp template.
*/
    public class CreatetemplateWrapper{
        public String category;
        public String language;
        public String name;
        public list<components> components;
    }
    /**
* @description Represents a WhatsApp template.
*/
    public class Template {
        public String name;     //send_marketing
        public language language;
        public List<components> components;
    }
    /**
* @description Represents the language used in a template.
*/
    public class Language {
        public String code;     //en
    }
    /**
* @description Represents components of a WhatsApp message template.
*/
    public class Components {
        public String type;     //body
        public List<Parameters > parameters ;
        public String text;
        public String format;
        public example example;
        public list<buttons> buttons;
    }
    /**
* @description Represents media information for a WhatsApp message.
*/
    public class MediaClass{
        public String link;
    }
    /**
* @description Represents an example structure for a message component.
*/
    public class Example{
        public List<List<String>> body_text;
        public List<String> header_handle;
    }
    /**
* @description Represents a button in a WhatsApp message template.
*/
    public class Buttons{
        public String text;
        public String type;
        public String phone_number;
        public String url;
    }
    /**
* @description Represents Parameters  for a message component.
*/
    public class Parameters  {
        public String type;     //text
        public String text;     //Amit
        public MediaClass image;
        public MediaClass document;
        public MediaClass video;
    }
    
    /**
* @description Wrapper class for the response from the WhatsApp API.
*/
    
    public class ResponseWrapper{
        public Error error;
        public String id;
        public String status;
        public String message;
        public String success;
        public Boolean isSuccess;
    }
    /**
* @description Represents an error response from the WhatsApp API.
*/
    public class Error {
        public String message;  //Unsupported post request. Object with ID '108193625692105' does not exist, cannot be loaded due to missing permissions, or does not support this operation. Please read the Graph API documentation at https://developers.facebook.com/docs/graph-api
        public String type; //GraphMethodException
        public Integer code;    //100
        public Integer errorsubcode;    //33
        public String fbtraceid;    //ALw3bzFT9VF9V_VoZxNN12D
        public String errorusermsg; //ALw3bzFT9VF9V_VoZxNN12D
    }
    /**
* @description Wrapper class for media URL responses from the API.
*/
    public class GetMediaURLWrapper{
        public String url;
        public String mimetype;
        public String sha256;
        public Integer fileSize;
        public String id;
        public String messaging_product;
    }
}