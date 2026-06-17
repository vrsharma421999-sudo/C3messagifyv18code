import { LightningElement, api } from "lwc";
import getAllTextMessages from "@salesforce/apex/C3WhatsAppUtilityBarCtrl.allConversationMessages";
//import Component_Refersh from '@salesforce/label/c.Component_Refersh';
export default class WhatsAppUtilityBar extends LightningElement {
    wrapMain = new Object();
    lstMessage = [];
    loaded = true;
    isRead;
    height = 'margin-top: 10px; padding-left: 8px'

    isMobile = false;
    isPC = false;
    
    // label = {
    //     Component_Refersh
    // };

    @api diplayChatPanel = false;
    @api recordId;
    @api objectApiName;
    
    strErrorMsg = '';
    currentUserId;
    organizationId;
    totalUnreadCount = 0;

    connectedCallback() {
        this.getAllTexts(false);
        this.created();
        this.checkDevice();
    }

    checkDevice() {
        const userAgent = navigator.userAgent || navigator.vendor || window.opera;
        if (/android|iPad|iPhone|iPod|BlackBerry|IEMobile|Opera Mini/i.test(userAgent)) {
            this.isMobile = true;
            this.height = 'margin-top: 10px; height: 550px; padding-left: 8px'
            this.isPC = false;
        } else {
            this.isMobile = false;
            this.isPC = true;
        }
    }

    getAllTexts() {
        this.onClearMessage();
        getAllTextMessages()
            .then((result) => {
                  console.log('Full result:', JSON.stringify(result));
        this.lstMessage = result?.wrapperMessageList || [];
                    //this.lstMessage = result.WrapperMessageList;
                    // this.lstMessage = JSON.parse(result).WrapperMessageList;
                         //this.lstMessage = result.wrapperMessageList;

                        this.currentUserId = result.currentUserId;
                        this.organizationId = result.organizationId;
                        this.wsChatEndpoint = result.wsChatEndpoint;
                       //this.currentUserId = JSON.parse(result).currentUserId;

                       // this.organizationId = JSON.parse(result).organizationId;

                        //this.wsChatEndpoint = JSON.parse(result).wsChatEndpoint;

                        console.log('this.lstMessage---- '+this.currentUserId);
                        console.log('this.lstMessage---- '+this.organizationId);
                        console.log('this.lstMessage---- '+this.wsChatEndpoint);
                           console.log('this.lstMessage---- ' + JSON.stringify(this.lstMessage));

                    this.totalUnreadCount = result.totalUnreadCount;
                    //console.log('this.lstMessage---- '+this.lstMessage);
                    this.totalUnreadCount = (JSON.parse(result).totalUnreadCount);

                    console.log('this.lstMessage---- '+JSON.stringify(this.lstMessage))
                    this.displayUnreadMsgCount(this.totalUnreadCount);


                    

            })
            .catch((error) => {
                if (error) {
                    var errorMg = "Unknown error";
                    if (Array.isArray(error.body)) {
                        errorMg = error.body.map((e) => e.message);
                    }
                    // UI API DML, Apex and network errors
                    else if (error.body && typeof error.body.message === "string") {
                        errorMg = error.body.message;
                    }
                    // JS errors
                    else if (typeof error.message === "string") {
                        errorMg = error.message;
                    }
                    this.strErrorMsg = errorMg;
                }
            });
    }

    onClearMessage() {
        this.strErrorMsg = '';
    }

  
    handleClickTextMessage(event) {
        if (event.target.dataset.id) {
            var selectedMsg = this.lstMessage.find(
                (item) => item.recordId == event.target.dataset.id
            );
            this.recordId = event.target.dataset.id;
            this.objectApiName = selectedMsg.objectApiName;
            this.diplayChatPanel = true;
        }
    }

    handleClickBack(event) {
        this.onClearMessage();
        this.recordId = "";
        this.objectApiName = "";
        this.unReadOnly = event.detail;
        this.diplayChatPanel = false;
        this.getAllTexts(this.unReadOnly);
    }

    handleClickOpenRecord(event) {
        this.unReadOnly = event.detail;
        this.getAllTexts(this.unReadOnly);
    }

    created() {
        // if(this.label.Component_Refersh === 'ON'){
        // setInterval(() => this.refresh(), 3000);
        // }
    }

  refresh() {
      this.getAllTexts(false);
    
  }
    

    displayUnreadMsgCount(unreadMsgCount) {
        this.dispatchEvent(new CustomEvent('chatnotification', { detail: { 'unreadMsgCount': unreadMsgCount } }));
    }



}