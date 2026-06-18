import { LightningElement,api,track } from 'lwc';
import initWhatsAppNumberConfiguration from '@salesforce/apex/C3WhatsappNumberConfiguration.initWhatsAppNumberConfiguration'; // 
import saveWhatsAppNumberConfig from '@salesforce/apex/C3WhatsappNumberConfiguration.saveWhatsAppNumberConfig'; //
import deleteWhatsAppNumberConfig from '@salesforce/apex/C3WhatsappNumberConfiguration.deleteWhatsAppNumberConfig'; //
import getAllPhoneField from '@salesforce/apex/C3WhatsappNumberConfiguration.getAllPhoneField'; //
import getObjectLabel from '@salesforce/apex/C3WhatsappNumberConfiguration.getObjectLabel'; //
// import upsertNumberConfig from '@salesforce/apex/WhatsappNumberConfiguration.upsertNumberConfig';
//import DeleteNumberConfig from '@salesforce/apex/WhatsappNumberConfiguration.DeleteNumberConfig';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class WhatsAppNumberConfiguration extends LightningElement {
lstObjectDetailsWrapper = [{ strObjectName: '-- None --', strObjectAPIName: '', strObject3DigitCode: '', lstFieldDetailWrapper: [] }];
    lstField = [{ label: '-- None --', value: '' }];

    lstObjectCreateMapping = [{ strObjectName: '-- None --', strObjectAPIName: '', strObject3DigitCode: '', lstFieldDetailWrapper: [] }];
    lstFieldCreatedMapping = [{ label: '-- None --', value: '' }];

    lstRecords = [];
    lstRecordsEmpty = true;
    error;
    objectValue = "";
    fieldValue = "";
    objectCode = "";
    showMapping = false;
    disable = false;
    strErrorMsg = "";
    strSuccess = "";
    strRecordId = "";
    @track loaded = false;
    @track isNewConfigPopup = false;
    isShowNext = false;
    isDisplayComp = false;
    @api identifylocation;
    hasDefaultResults;
    cssClass = 'slds-scrollable_y text cssForWizard';

    @track objMainWrap;
    @track hasRecords = false;
    @track objectPicklist = [];
    @track fieldPicklist = [];
    @track inLinefieldPicklist = [];
    @track configRecords = [];
    @track isLoading = false;
    objectName = '';




    connectedCallback() {      
        this.isLoading = true;   
        


        initWhatsAppNumberConfiguration({})
        .then(result => {
            this.isLoading = false;   
            if (result) {
                this.objMainWrap = JSON.parse(result);
                
                if(this.objMainWrap.objectPickList != null && this.objMainWrap.objectPickList != undefined && this.objMainWrap.objectPickList.length > 0)
                    this.objectPicklist = this.objMainWrap.objectPickList;
                if(this.objMainWrap.lstToNumberConfiguration != null && this.objMainWrap.lstToNumberConfiguration != undefined && this.objMainWrap.lstToNumberConfiguration.length > 0){
                    this.configRecords = this.objMainWrap.lstToNumberConfiguration;
                    for (let index = 0; index < this.configRecords.length; index++) {
                        this.configRecords[index].isEditMode = false;
                    }
                }
                this.hasRecords =  this.objMainWrap.hasRecords
                    
                console.log('this.objMainWrap---  '+JSON.stringify(this.objMainWrap));
            }
        })
        .catch(error => {
            this.isLoading = false;  
            console.log(error);
        });
    }

    getInlineFields(objectName){
        this.isLoading = true;
        getAllPhoneField({sObjectName : objectName})
        .then(result => {
            this.isLoading = false;   
            if (result) {
                this.inLinefieldPicklist = JSON.parse(result);
            }
        })
        .catch(error => {
            this.isLoading = false;  
            console.log(error);
        });
    }

    getFields(){
        this.isLoading = true;
        getAllPhoneField({sObjectName : this.objectName})
        .then(result => {
            this.isLoading = false;   
            if (result) {
                this.fieldPicklist = JSON.parse(result);
            }
        })
        .catch(error => {
            this.isLoading = false;  
            console.log(error);
        });
    }

    onGenericChange(event){
        let strFieldName = event.target.name;
        let value = event.target.value;
        if(strFieldName == 'objectName'){
            this.objectName = value;
            if (this.objectName) {
                this.isLoading = true; 
                this.getFields();
            }
        }

        if(strFieldName == 'fieldName'){
            this.fieldName = event.target.value;
        }
    }

    onNewConfigClick(event){
    console.log('New config clicked:', event.target);
    this.isNewConfigPopup = true;
    }


    onTableGenericChange(event){
        let index = event.target.dataset.index;
        this.configRecords[index].CCCWA__Field_Name__c = event.target.value;
    }

    handleEdit(event){
        this.disable = true;
        let index = event.target.dataset.index;
        this.configRecords[index].isEditMode = true;
        this.getInlineFields(this.configRecords[index].CCCWA__Object_Name__c);
    }

    handleCancel(event){
        this.disable = false;
        let index = event.target.dataset.index;
        this.configRecords[index].isEditMode = false;
    }
    handleInlineSave(event){
        this.disable = false;
        let index = event.target.dataset.index;
        console.log(JSON.stringify(this.configRecords[index]));
        this.configRecords[index].isEditMode = false;
        this.saveMethod(this.configRecords[index]);
    }

    handleSave(){
        console.log('--before--');
        if (this.isInputValid('.validate')) {
            console.log('--later--');
            for(let i = 0; i < this.objectPicklist.length; i++){
                if(this.objectPicklist[i].value == this.objectName){
                    let tempList = this.objectPicklist;
                    tempList.splice(i, 1);
                    this.objectPicklist = JSON.parse(JSON.stringify(tempList));
                    break;
                }
            }
            console.log(this.objectName+'--'+this.fieldName);
            this.saveMethod({Name : this.objectName, CCCWA__Object_Name__c :  this.objectName, CCCWA__Field_Name__c : this.fieldName});
            this.objectName = '';
            this.fieldName = '';
            this.fieldPicklist = [];
        }
    }

    saveMethod(objWhatsAppConfigSetting){
        this.isLoading = true;
        saveWhatsAppNumberConfig({jsonNumberConfig : JSON.stringify(objWhatsAppConfigSetting)})
        .then(result => {
            this.isLoading = false;   
            if (result) {
                console.log('came here')
                this.configRecords = JSON.parse(result);
                for (let index = 0; index < this.configRecords.length; index++) {
                    this.configRecords[index].isEditMode = false;
                    this.hasRecords = true;
                }
                this.showToast('Success!', 'Config setting saved successfully!', 'success')
            }
        })
        .catch(error => {
            this.isLoading = false;  
            console.log(error);
        });
    }

    handleDelete(event){
        this.isLoading = true;
        let index = event.target.dataset.index;
        // this.configRecords[index].isEditMode = true;
        // this.handleAfterDelete(this.configRecords[index].CCCWA__Object_Name__c);
        deleteWhatsAppNumberConfig({jsonNumberConfig : JSON.stringify(this.configRecords[index])})
        .then(result => {
            this.isLoading = false; 
            console.log(result);
            if (result) {
                
                this.configRecords = JSON.parse(result);
                if(this.configRecords != null && this.configRecords != undefined && this.configRecords.length > 0){
                    this.hasRecords = true;
                    for (let index = 0; index < this.configRecords.length; index++) {
                        this.configRecords[index].isEditMode = false;
                    }
                }else{
                    this.hasRecords = false;
                }
                this.showToast('Success!', 'Config setting has been deleted successfully!', 'success')
            }
        })
        .catch(error => {
            this.isLoading = false;  
            console.log(error);
        });
    }

    handleAfterDelete(strObjectName){
        this.isLoading = true; 
        getObjectLabel({objectName : strObjectName})
        .then(result => {
            this.isLoading = false;
            
            if (result) {
                let obj = {
                    label : result,
                    value : strObjectName
                }
                let tempList = this.objectPicklist;
                tempList.push(obj);
                this.objectPicklist = JSON.parse(JSON.stringify(tempList));
            }
        })
        .catch(error => {
            this.isLoading = false;  
            console.log(error);
        });
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





        handleObjectSelect(event) {
        this.loaded = !this.loaded;
        this.objectValue = event.target.value;

        this.lstField = [{ label: '-- None --', value: '' }];
        for (let i = 0; i < this.lstObjectDetailsWrapper.length; i++) {
            if (this.objectValue == this.lstObjectDetailsWrapper[i].strObjectAPIName) {
                if (this.lstObjectDetailsWrapper[i].lstFieldDetailWrapper.length > 0) {
                    for (let j = 0; j < this.lstObjectDetailsWrapper[i].lstFieldDetailWrapper.length; j++) {
                        this.lstField.push({
                            label: this.lstObjectDetailsWrapper[i].lstFieldDetailWrapper[j].strLabel,
                            value: this.lstObjectDetailsWrapper[i].lstFieldDetailWrapper[j].strAPIName
                        });
                    }
                } else {
                    this.lstField = [];
                    this.lstField.push({
                        label: 'Not Found',
                        value: ''
                    });
                }
                this.fieldValue = '';
                this.objectCode = this.lstObjectDetailsWrapper[i].strObject3DigitCode;
            }
        }
        this.loaded = !this.loaded;
    }

    handleFieldSelect(event) {
        this.fieldValue = event.target.value;
    }

    

    handleClear(){
        this.objectName = '';
        this.fieldName = '';
        this.isNewConfigPopup = false;
    }

    handleNCClear() {   
    this.strRecordId = '';
    this.fieldValue = "";
    this.objectCode = '';
    this.objectValue = "";
    const selectedObj = this.template.querySelector('[data-id="objOption"]');
    if (selectedObj) {
        selectedObj.value = this.objectValue;
    }    
    this.lstField = [];
    }
    handleNCEdit(event) {        
        this.loaded = !this.loaded;
        this.disable = true;
        this.strRecordId = event.target.value;
        this.hasDefaultResults = null;

        for (let i = 0; i < this.lstRecords.length; i++) {
            if (this.lstRecords[i].ToNumberConfiguration.Id == this.strRecordId) {
                this.objectValue = this.lstRecords[i].ToNumberConfiguration.CCCWA__Object_Name__c;
                this.fieldValue = this.lstRecords[i].ToNumberConfiguration.CCCWA__Field_Name__c;
                this.lstRecords[i].isShow = true;
            } else {
                if (this.lstRecords[i].isShow) {
                    this.lstRecords[i].isShow = false;
                }
            }
        }
        // set field list into select option
        this.lstFieldCreatedMapping = [];
        for (let i = 0; i < this.lstObjectCreateMapping.length; i++) {
            if (this.objectValue == this.lstObjectCreateMapping[i].strObjectAPIName) {
                if (this.lstObjectCreateMapping[i].lstFieldDetailWrapper.length > 0) {
                    for (let j = 0; j < this.lstObjectCreateMapping[i].lstFieldDetailWrapper.length; j++) {
                        if (this.lstObjectCreateMapping[i].lstFieldDetailWrapper[j].strAPIName != this.fieldValue) {
                            this.lstFieldCreatedMapping.push({
                                label: this.lstObjectCreateMapping[i].lstFieldDetailWrapper[j].strLabel,
                                value: this.lstObjectCreateMapping[i].lstFieldDetailWrapper[j].strAPIName
                            });
                        } else {
                            this.hasDefaultResults = this.lstObjectCreateMapping[i].lstFieldDetailWrapper[j]
                        }
                    }
                } else {
                    this.lstFieldCreatedMapping = [];
                    this.lstFieldCreatedMapping.push({
                        label: 'Not Found',
                        value: ''
                    });
                }
                this.objectCode = this.lstObjectCreateMapping[i].strObject3DigitCode;
            }
        }
        this.loaded = !this.loaded;
    }
    handleNCCancel(event) {
        this.disable = false;
        this.strRecordId = event.target.value;
        for (let i = 0; i < this.lstRecords.length; i++) {
            if (this.lstRecords[i].ToNumberConfiguration.Id == this.strRecordId) {
                this.lstRecords[i].isShow = false;
            }
        }
    }
    
    
    RecordDeleted() {
        // Create and dispatch the toast event
        const event = new ShowToastEvent({
            title: 'Deleted',
            message: 'Record deleted successfully',
            variant: 'success',
        });
        this.dispatchEvent(event);
    }
     RecordUpdated() {
        // Create and dispatch the toast event
        const event = new ShowToastEvent({
            title: 'Updated',
            message: 'Record Updated successfully',
            variant: 'info',
        });
        this.dispatchEvent(event);
    }
    RecordCreated() {
        // Create and dispatch the toast event
        const event = new ShowToastEvent({
            title: 'Created',
            message: 'Record Created successfully',
            variant: 'success',
        });
        this.dispatchEvent(event);
    }


    showToast(title, message, variant){
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }
}