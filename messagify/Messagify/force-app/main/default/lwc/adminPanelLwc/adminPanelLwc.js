import { LightningElement,  track } from 'lwc';
import initialize from '@salesforce/apex/C3AdminPanelLwcController.initialize';
import saveAdminConfig from '@salesforce/apex/C3AdminPanelLwcController.saveAdminConfig';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import WhatappIcon from "@salesforce/resourceUrl/WhatappIcon";

export default class AdminPanelLwc extends LightningElement {
    whatappIconUrl = WhatappIcon;
    isWelcome = false;
    @track isLoading;
    objWhatsAppAdmin = {
        name : "Admin",
        CCCWA__NumberID__c : "",
        CCCWA__WabaId__c : "",
    }
    isDisabled = false;
    isSave = false;
    
    // For WABA ID
    get maskedWabaId() {
        return this.maskValue(this.objWhatsAppAdmin.CCCWA__WabaId__c);
    }
    set maskedWabaId(value) {
        this.objWhatsAppAdmin.CCCWA__WabaId__c = value;
    }

    // For Number ID

    get maskedNumberId() {
        return this.maskValue(this.objWhatsAppAdmin.CCCWA__NumberID__c);
    }
    set maskedNumberId(value) {
        this.objWhatsAppAdmin.CCCWA__NumberID__c = value;
    }

    
    

    maskValue(value) {
        console.log('=-=-=-=-=-42-=-=-=-=-'+value);
        if (value && value.length > 2) {
            const firstChar = value.charAt(0);  // First character
            const lastChar = value.charAt(value.length - 1);  // Last character
            const middle = '*'.repeat(value.length - 2);  // Replace middle characters with asterisks
            return firstChar + middle + lastChar;
        }
        return value;  // For short values (1 or 2 characters), return as is
    }
    
    connectedCallback(){
        this.isDisabled = true;
        //this.adjustHeight();
        
        //loadStyle(this, modal);
        this.isLoading = true;
        this.init();
    }

    init(){
        initialize()
        .then(data => {
            this.isLoading = false;
            if (data) {
                this.objWhatsAppAdmin = data;
                this.isDisabled = true;
            }else{
                this.isWelcome = true;
                this.isDisabled = false;
                this.isSave = true;
            }
            console.log(this.isDisabled)
        }).catch(error => {
            this.handleError(error);
        });
    }


    genericHandler(event){
        let value = event.target.value;
        let fieldName = event.target.name; 
        if (fieldName == "wabaId") {
            this.objWhatsAppAdmin.CCCWA__WabaId__c = value;
        }
        if (fieldName == "numId") {
            this.objWhatsAppAdmin.CCCWA__NumberID__c = value;
        }
       
    }


    adjustHeight(){
        //this.res = "Height: "+screen.height + "Width: "+screen.width;
        let tempHeight = screen.height;
        if(screen.width < 500){
            this.height = 'max-height : '+String(tempHeight - 25) + 'px' ;
        }else{
            this.height = 'max-height : '+String((tempHeight * 0.6) - 35) + 'px' ;
        }
            
    }  

    handleSave(){
        if(this.isInputValid('.validate')){
            this.isSave = false;
            this.isDisabled = true;
            this.isLoading = true;
            saveAdminConfig({jsonAdminConfig : JSON.stringify(this.objWhatsAppAdmin)})
            .then(result => {
                this.isLoading = false;

                if (result) {
                                        console.log(JSON.stringify(result));
                    this.toastEvent('success', 'Success!', 'Config setting saved successfully!',)
                }
            })
            .catch(error => {
                this.handleError(error);
            });
        }
    }

    edit(){
        this.isSave = true;
        this.isDisabled = false;
    }

    letsGo(){
        this.isWelcome = false;
    }
    


    toastEvent(type,title, message){
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: type
        });
        this.dispatchEvent(evt);
    }

    handleError(error) {
        if (error) {
            let tempErrorList = [];
            if (Array.isArray(error.body)) {
                tempErrorList = error.body.map((e) => e.message);
            } 
            else if (error.body && typeof error.body.message === 'string') {
                tempErrorList = [error.body.message];
            } 
            else if (error.body && error.body.fieldErrors && error.body.fieldErrors.message) {
                console.log('fielderror');
                tempErrorList = Object.values(error.body.fieldErrors)
                    .flat() 
                    .map((fieldError) => fieldError.message);
            }
            else if (Array.isArray(error.body.pageErrors) && error.body.pageErrors.length > 0) {
                tempErrorList = error.body.pageErrors.map((e) => e.message);
            }
            else if (typeof error.message === 'string') {
                tempErrorList = [error.message];
            }
            tempErrorList;
            // Pass the error messages to toastEvent or display logic
            this.toastEvent('error', 'Error!', tempErrorList.join(', '));
        }
        this.isLoading = false;
    }

    isInputValid(selector) {
        let isValid = true;
        let inputFields = this.template.querySelectorAll(selector);
        // inputFields.push(this.template.querySelectorAll('lightning-combobox'));
        inputFields.forEach(inputField => {
          if (!inputField.checkValidity()) {
            inputField.reportValidity();
            isValid = false;
          }
        });
        return isValid;
    }

   
}