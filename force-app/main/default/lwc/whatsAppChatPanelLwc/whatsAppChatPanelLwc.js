import { LightningElement, api, track,wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import verifyUpload from '@salesforce/apex/C3WhatsAppTemplateScreenLWCCtrl.verifyUpload';
import initWhatsAppChatPanelController from '@salesforce/apex/C3WhatsAppChatPanelCtrl.initWhatsAppChatPanelController';
import saveMessage from '@salesforce/apex/C3WhatsAppChatPanelCtrl.saveMessage';
import valdiateTemplatePrameters from '@salesforce/apex/C3Utility.valdiateTemplatePrameters';
import getPublicUrl from '@salesforce/apex/C3WhatsAppChatPanelCtrl.getPublicUrl';
import getMediaWamId from '@salesforce/apex/C3WhatsAppChatPanelCtrl.getMediaWamId';
import checkForNumberConfigurationImplemented from '@salesforce/apex/C3WhatsAppChatPanelCtrl.checkForNumberConfigurationImplemented';
import LoadTextMessages from '@salesforce/apex/C3WhatsAppChatPanelCtrl.loadTextMessages';
import WhatappIcon from "@salesforce/resourceUrl/WhatappIcon";
import IMAGE from "@salesforce/resourceUrl/DoubleTickWhatsApp";
import VideoPreview from "@salesforce/resourceUrl/VideoPreview";
import DocumentPreview from "@salesforce/resourceUrl/DocumentPreview";
import ReadIMG from "@salesforce/resourceUrl/ReadDoubleTick";

import getProjectNames from '@salesforce/apex/C3Utility.getProjectNames';

//import getTemplatesByProject from '@salesforce/apex/C3WhatsAppChatPanelCtrl.getTemplatesByProject';

const MAX_FILE_SIZE = 5000000;

export default class WhatsAppChatPanelLwc extends LightningElement {
    // Resource URLs
    whatappIconUrl = WhatappIcon;
    doubletick = IMAGE;
    readDoubleTick = ReadIMG;
    videoPreviewUrl = VideoPreview;
    documentPreviewUrl = DocumentPreview;

    // Public properties
    @api recordId;
    @api objectApiName;
    @api displayBackBtn = false;
    @api unReadOnly = false;
    @api componentHeight = 'margin-top: 10px; height: 400px; padding-left: 8px';
    @api styleDivOutbound = 'slds-chat-message__text slds-chat-message__text_outbound-agent outboundStyle';
    @api styleDivTextOutbound = 'slds-chat-message__text OutboundStyle';
    @api styleDivInbound = 'slds-chat-message__text slds-chat-message__text_inbound inboundStyle';
    @api styleDivTextInbound = 'slds-chat-message__text inboundStyle';

    // Track properties
    @track lstMessagingTemplateOptions = [];
    @track strSelectedMessagingTemplate = '';
    @track shadowCss = '';
    @track lstMessage = [];
    @track fileName = '';
    @track fileContent = '';
    @track isButtonDisabled = true;
    @track isLoading = true;
    @track notNumberConfigurationImplemented = false;

    @track projectOptions;

    @track selectedProjectId;
  
    

    // Other properties
    wrapMain = {};
    strChatBodyClass = 'myScrollClass';
    strChatHeaderClass = 'chatHeaderDefaultBG';
    NameOfChatStarter = '';
    txtMsg = '';
    tempId = '';
    medialUrl = '';
    isBtn = false;
    loaded = false;
    isErrorMessage = false;
    isSetUpCompleted = false;
    isFileUploadPopup = false;
    fileData;
    currentUserName = '';
    currentUserIntial = '';
    strSelectedFromNumber = '';
    fromNumber = '';
    toNumber = '';
    erroMessage;
    intervalId

    disconnectedCallback() {
        if (this.intervalId) {
            clearInterval(this.intervalId);
        }
    }

    connectedCallback() {
        this.checkForNumberConfigurationImplemented();
        this.initializeChatPanel();

       this.intervalId = setInterval(() => {
           this.initializeChatPanel();
}, 4000);
    }

    checkForNumberConfigurationImplemented() {
        console.log('recordId--97'+this.recordId);
        checkForNumberConfigurationImplemented({ recordId: this.recordId })
        .then(result => {
                this.validations = JSON.parse(result);
                this.NumberConfigurationImplemented = this.validations.isAllowedToChat;
                this.notNumberConfigurationImplemented = !this.validations.isAllowedToChat;
                this.erroMessage = this.validations.errorMessage;
            })
            .catch(error => {
                console.error('Error fetching permission:', error);
            });
    }

    initializeChatPanel() {
        initWhatsAppChatPanelController({ recordId: this.recordId, objName: this.objectApiName })
            .then(result => {
                if (JSON.parse(result).isSuccess) {
                    this.wrapMain = JSON.parse(result);
                    this.lstMessagingTemplateOptions = this.wrapMain.lstMessagingTemplateOptions;
                    this.strSelectedFromNumber = this.wrapMain.fromNumber;
                    this.isAllowedToChat = this.wrapMain.isAllowedToChat;
                    this.formatPhoneNumbers();
                    this.loadMessages();
                }
            })
            .catch(error => {
                console.error('Error initializing chat panel:', error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    formatPhoneNumbers() {
        this.strSelectedFromNumber = this.strSelectedFromNumber.replace('+1', '');
        this.strSelectedFromNumber = this.formatPhoneNumber(this.strSelectedFromNumber);
        if (this.wrapMain && this.wrapMain.fromNumber) {
            this.fromNumber = this.wrapMain.fromNumber.replace('+', '');
            this.fromNumber = this.formatPhoneNumber(this.fromNumber);
        }
        if (this.wrapMain && this.wrapMain.toNumber) {
            this.toNumber = this.wrapMain.toNumber.replace('+', '');
            this.toNumber = this.formatPhoneNumber(this.toNumber);
        }
    }

    formatPhoneNumber(number) {
        if (number.length === 10) {
            return `+1 (${number.substring(0, 3)}) ${number.substring(3, 6)} - ${number.substring(6, 10)}`;
        } else if (number.length === 11) {
            return `+${number.substring(0, 1)} (${number.substring(1, 4)}) ${number.substring(4, 7)} - ${number.substring(7, 11)}`;
        }
        return number;
    }

    loadMessages() {
        this.lstMessage = [];
        if (this.wrapMain.lstTxtMsg.length > 0) {
            this.wrapMain.lstTxtMsg.forEach(msg => {
                this.lstMessage.push(this.createMessageObject(msg));
            });
            console.log('messages  --  '+JSON.stringify(this.lstMessage));
        }
    }

    createMessageObject(msg) {
        let listMediaFiles = msg.listMedia ? msg.listMedia.map(media => ({
            fileName: media.fileName,
            isImage: media.isImage,
            isVideo: media.isVideo,
            isDocument: media.isDocument,
            isAudio: media.isAudio,
            isUnknown: media.isUnknown
        })) : [];

        return {
            showAvatar: msg.objTXT.CCCWA__Direction__c !== 'Outbound',
            showSmallDetails: msg.isShow,
            avatr: msg.objTXT.CCCWA__Direction__c === 'Outbound' ? '' : this.wrapMain.nameIntial,
            objDetails: msg.objTXT,
            senderName: msg.smallDetails,
            styleClass: `slds-chat-listitem slds-chat-listitem_${msg.objTXT.CCCWA__Direction__c.toLowerCase()}`,
            styleDiv: msg.objTXT.CCCWA__Direction__c === 'Outbound' ? this.styleDivOutbound : this.styleDivInbound,
            styleDivText: msg.objTXT.CCCWA__Direction__c === 'Outbound' ? this.styleDivTextOutbound : this.styleDivTextInbound,
            shadowCss: msg.objTXT.CCCWA__Direction__c === 'Outbound'? 'box-shadow: -5px 5px 10px rgba(0, 0, 0, 0.7);' : 'box-shadow: 5px 5px 10px #a4a1a1, -5px -5px 10px #ffffff;',
            isPending: msg.isPending,
            isSent: msg.isSent,
            isDelivered: msg.isDelivered,
            isRead: msg.isRead,
            isFailed: msg.isFailed,
            strMsgOwnerInitials: msg.strMsgInitials,
            lstMMSFiles: listMediaFiles,
            isMMS: msg.isMMS,
            isVoice: msg.isVoice,
        };
    }
    

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

    handleImageUploadClick() {
        this.isFileUploadPopup = true;
    }

    closeMMSPopup() {
        this.isFileUploadPopup = false;
        this.resetFileData();
    }

    resetFileData() {
        this.fileContent = null;
        this.fileName = null;
        this.fileData = null;
    }

    handleInputFileChange(event) {
        this.onClearMessage();
        this.loaded = false;

        const uploadedFiles = event.detail.files;
        if (uploadedFiles.length > 0) {
            this.processUploadedFile(uploadedFiles[0]);
        }
    }

    processUploadedFile(file) {
        this.isFileUploadPopup = false;
        this.documentId = file.documentId;
        this.contentVersionId = file.contentVersionId;

        verifyUpload({ contentVersionId: this.contentVersionId })
            .then(result => {
                this.isLoading = false;
                if (!result) {
                    this.showToast('Error!', 'You cannot upload a file with size more than 4.3MB', 'error');
                    this.resetFileData();
                } else {
                    this.fileName = file.name;
                    this.mimeType = this.getMimeType(file.mimeType);
                    this.uploadFile(file);
                }
            })
            .catch(error => {
                this.isLoading = false;
                this.handleError(error);
            });
    }

    getMimeType(mimeType) {
        if (mimeType.includes('image')) return 'image';
        if (mimeType.includes('video')) return 'video';
        if (mimeType.includes('audio')) return 'audio';
        return 'document';
    }

    uploadFile(file) {
        getPublicUrl({ toNumber: this.toNumber, cVId: this.contentVersionId, relatedId: this.recordId, fileName: this.fileName, mediaType: this.mimeType })
            .then(result => {
                if (result) {
                    this.publicDocUrl = result;
                    return getMediaWamId({ toNumber: this.toNumber, mediaUrl: this.publicDocUrl, mediaType: this.mimeType, fileName: this.fileName });
                }
            })
            .then(wamId => {
                if (wamId) {
                    console.log('wamId  = '+wamId);
                    return LoadTextMessages({ recordId: this.recordId, toNumber: this.toNumber, msg: '', objectName: this.objectApiName, mediaUrl: this.publicDocUrl, mediaType: this.mimeType, strFileName: this.fileName, templateName: this.strSelectedMessagingTemplate, strtempid: this.tempId, vamId: wamId });
                }
            })
            .then(data => {
                if (data) {
                    this.handleLoadTextMessagesResponse(data);
                }
            })
            .catch(error => {
                this.handleError(error);
            });
    }

    handleLoadTextMessagesResponse(data) {
        const responseData = JSON.parse(data);
        if (responseData.isSuccess) {
            this.lstMessage = [];
            this.wrapMain = responseData;
            this.resetFileData();
            this.loadMessages();
        } else {
            this.handleErrorResponse(responseData);
        }
    }

    handleErrorResponse(responseData) {
        this.NameOfChatStarter = 'None';
        this.wrapMain = responseData;
        this.wrapMain.isPNA = true;
        if (this.wrapMain.strMsg) {
            this.isErrorMessage = true;
            this.isBtn = true;
            this.isButtonDisabled = true;
        }
    }

    keyUpHandler(event) {
        if (event.target.value) {
            this.strSelectedMessagingTemplate = '';
            this.isButtonDisabled = false;
            this.txtMsg = event.target.value;
        }else {
            this.txtMsg = '';
            this.isButtonDisabled = true;
        }
    }

    handleSend() {
        this.onClearMessage();
        this.loaded = false;
        const msg = this.txtMsg;
        this.isButtonDisabled = true;
        this.txtMsg = '';
        this.isFileUploadPopup = false;
        this.isSaveInProgress = true;

        saveMessage({ recordId: this.recordId, toNumber: this.wrapMain.toNumber, msg: msg, objectName: this.objectApiName, mediaUrl: this.medialUrl, strBase64Data: this.fileContent, strFileName: this.fileName, templateName: this.strSelectedMessagingTemplate, strtempid: this.tempId })
        .then(data => {
            if (data) {
                LoadTextMessages({ recordId: this.recordId, toNumber: this.wrapMain.toNumber, msg, objectName: this.objectApiName, mediaUrl: '', mediaType: '', strFileName: '', templateName: this.strSelectedMessagingTemplate, strtempid: this.tempId, vamId: data })
                .then(result => {
                    this.handleLoadTextMessagesResponse(result);
                })
            }else{
                this.showToast('Error!', 'Some error came in the META API, please check Error log!', 'error');
            }
        })
        
        .catch(error => {
            this.handleError(error);
        });
    }
    onClearMessage() {
        this.wrapMain.strMsg = '';
        this.isErrorMessage = false;
        if (this.txtMsg) {
            this.isButtonDisabled = false;
        }
    }

    onMessagingTemplateChange(event) {
        this.strSelectedMessagingTemplate = event.target.value;
        this.strSelectedMessagingTemplateId = event.target.id;

        if (this.strSelectedMessagingTemplate.length > 0) {
            const template = this.lstMessagingTemplateOptions.find(t => t.value === this.strSelectedMessagingTemplate);
            if (template) {
                this.txtMsg = this.buildMessageFromTemplate(template);
                this.tempId = template.tempId;
            }
        }

        this.isButtonDisabled = this.strSelectedMessagingTemplate.length === 0;

        this.isLoading = true;
        valdiateTemplatePrameters({ recordId: this.recordId, templateId : this.tempId })
        .then(data => {
            console.log(data);
            this.isLoading = false;
            /*if (data) {
                
            }*/
        })
        .catch(error => {
            this.handleError(error);
        });
    }

    buildMessageFromTemplate(template) {
        let message = '';
        if (template.header) {
            message += `<div style="text-align:center"><b>${template.header}</b></div>`;
        }
        if (template.mediaType === 'VIDEO') {
            message += `<div><img width="200" height="250" src="${this.videoPreviewUrl}"></div>`;
            message += `<div>${template.textMessage}</div>`;
        } else if (template.mediaUrl && template.mediaType === 'IMAGE') {
            message += `<div><img width="200" height="250" src="${template.mediaUrl}"></div>`;
            message += `<div>${template.textMessage}</div>`;
        } else if (template.mediaUrl && template.mediaType === 'DOCUMENT') {
            message += `<div><img width="200" height="250" src="${this.documentPreviewUrl}"></div>`;
            message += `<div>${template.textMessage}</div>`;
        } else {
            message += template.textMessage;
        }
        if (template.footer) {
            message += `</br><p style="font-size : 12px" class="slds-text-color_inverse-weak">${template.footer}<p>`;
        }
        if (template.listButtons && template.listButtons.length > 0) {
            template.listButtons.forEach(button => {
                if (button.CCCWA__Button_Type__c === 'QUICK_REPLY' || button.CCCWA__Button_Type__c === 'PHONE_NUMBER') {
                    message += `<div class="slds-theme_shade" style="margin-top : 5px; padding: 5; font-size : 18px; border-radius: 5px; text-align:center; color: #4191e1; text-decoration: underline">${button.CCCWA__Button_text__c}</div>`;
                }
            });
        }
        return message;
    }
     

   

        

    

    handleError(error) {
        console.log('error -- '+error);
        console.log('JSON error -- '+JSON.stringify(error));
        if (error) {
            let tempErrorList = [];
            if (Array.isArray(error.body)) {
                tempErrorList = error.body.map((e) => e.message);
            } 
            else if (error.body && typeof error.body.message === 'string') {
                tempErrorList = [error.body.message];
            } 
            else if (Array.isArray(error.body.pageErrors) && error.body.pageErrors.length > 0) {
                tempErrorList = error.body.pageErrors.map((e) => e.message);
            }
            else if (error.body && error.body.fieldErrors && error.body.fieldErrors.message) {
                console.log('fielderror');
                tempErrorList = Object.values(error.body.fieldErrors)
                    .flat() 
                    .map((fieldError) => fieldError.message);
            }
            else if (error.body && error.body.fieldErrors) {
                Object.keys(error.body.fieldErrors).forEach((fieldName) => {
                    const fieldErrorArray = error.body.fieldErrors[fieldName];
                    if (Array.isArray(fieldErrorArray) && fieldErrorArray.length > 0) {
                        fieldErrorArray.forEach((fieldError) => {
                            tempErrorList.push(fieldError.message);
                        });
                    }
                });
            }
            
            else if (typeof error.message === 'string') {
                tempErrorList = [error.message];
            }
            tempErrorList;
            // Pass the error messages to toastEvent or display logic
            this.showToast('Error!', tempErrorList.join(', '), 'error');
        }
       
       
       
        this.isLoading = false;
    }

           getProjectNames({ error, data }) {   

        if (data) {

            this.projectOptions = data.map(name => ({

                label: name,

                value: name

            }));

        } else if (error) {

            console.error('Project load error:', error);

        }

    }



    @wire(getProjectNames)

    wiredProjects({ error, data }) {   

        if (data) {

            this.projectOptions = data.map(name => ({

                label: name,

                value: name

            }));

        } else if (error) {

            console.error(error);

        }

    }



    handleProjectChange(event) {

        this.selectedProjectId = event.detail.value;

        console.log('Event detail--- ' +this.selectedProjectId);

       /* if (this.selectedProjectId) {

            this.fetchTemplatesByProject();

        } else {

            this.lstMessagingTemplateOptions = []; 

            this.strSelectedMessagingTemplate = '';

        } */

    }
}