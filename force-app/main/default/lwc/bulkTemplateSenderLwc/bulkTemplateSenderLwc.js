import { LightningElement, track } from 'lwc';
import getObjectsfromNumberConfig from '@salesforce/apex/C3BulkTemplateSenderLwcController.getObjectsfromNumberConfig';
import validateObject from '@salesforce/apex/C3BulkTemplateSenderLwcController.validateObject';
import fetchObjectRecords from '@salesforce/apex/C3BulkTemplateSenderLwcController.fetchObjectRecords';
import getExistingTemplate from '@salesforce/apex/C3WhatsAppTemplateScreenLWCCtrl.getExistingTemplate';
import sendWhatsAppMessageBulk from '@salesforce/apex/C3WhatsAppTemplateScreenLWCCtrl.sendWhatsAppMessageBulk';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Main class for the Bulk Template Sender component
export default class BulkTemplateSenderLwc extends LightningElement {
    // Track properties for data binding
    @track tableData = [];
    @track columns = [];
    @track selectedRecordIds = [];
    @track objTemplate = {};
    @track templateViewBody = '';
    @track previewActionButtons = [];

    // Other properties
    objectOptions = [];
    selectedObject = '';
    isLoading = false;
    objectValidate = false;
    showRecordTable = false;
    showTemplateSelector = false;
    filter = {};
    templateRecordId = '';
    isModalOpen = false;
    isQuickReplyList = false;
    isActionList = false;
    isMediaImage = false;
    isMediaDoc = false;
    isMediaVideo = false;

    // Lifecycle hook: Called when the component is inserted into the DOM
    connectedCallback() {
        this.isLoading = true; // Start loading
        this.fetchObjectOptions(); // Fetch object options
    }

    // Fetch available object options from Apex
    fetchObjectOptions() {
        getObjectsfromNumberConfig()
            .then(result => {
                this.objectOptions = JSON.parse(result).sort((a, b) =>
                    a.label.toLowerCase().localeCompare(b.label.toLowerCase())
                );
                this.isLoading = false; // Stop loading
            })
            .catch(error => {
                this.isLoading = false; // Stop loading
                this.handleError(error); // Handle error
            });
    }

    // Handle the change event for the object selection
    genericChange(event) {
        let fieldName = event.target.name;
        let value = event.target.value;

        if (fieldName === 'templateObject') {
            this.selectedObject = value; // Set selected object
            this.resetTableData(); // Reset table data
            this.validateObject(value); // Validate selected object
        }
    }

    // Reset table data and columns
    resetTableData() {
        this.tableData = [];
        this.columns = [];
    }

    // Validate the selected object
    validateObject(objectName) {
        this.isLoading = true; // Start loading
        this.objectValidate = false; // Reset validation flag

        console.log('Object Name--->' +this.objectValidate);
        console.log('Object Name--->' +objectName);

        validateObject({ objectName: objectName })
            .then(result => {
                if (result) {
                    return fetchObjectRecords({ objectName: objectName }); // Fetch records if valid
                } else {
                    throw new Error('Validation failed for object: ' + objectName);
                }
            })
            .then(data => {
                if (data.length > 0) {
                    this.populateTableData(data); // Populate table data
                } else {
                    this.resetTableData(); // Reset if no data
                }
            })
            .catch(error => {
                this.objectValidate = false; // Reset validation flag
                this.handleError(error); // Handle error
            })
            .finally(() => {
                this.isLoading = false; // Ensure loading is stopped
            });
    }

    // Populate table data and columns


    populateTableData(data) {
        this.tableData = data;
        console.log('Data--->' + JSON.stringify(data[0]));
        this.columns = Object.keys(data[0])
            .filter(field => field !== 'Id' && typeof data[0][field] !== 'object')
            .map(field => ({
                label: field.replace(/_/g, ' '),
                fieldName: field,
                type: 'text'
            }));
        this.showRecordTable = true; // Show record table
        console.log('Show Record Table--->' +this.showRecordTable);
    }

    

    // Handle the Next button click
    handleNext() {
        const selectedRecords = this.template.querySelector('lightning-datatable').getSelectedRows();
        if (selectedRecords.length === 0) {
            this.showToast('Error', 'Please select at least one record before proceeding.', 'error');
        } else {
            this.selectedRecordIds = selectedRecords.map(record => record.Id); // Store selected record IDs
            this.showTemplateSelector = true; // Show template selector
            this.showRecordTable = false; // Hide record table
            this.setupFilter(); // Setup filter for templates
        }
    }

    // Setup filter for fetching templates
    setupFilter() {
        console.log(this.selectedObject);
        this.filter = {
            criteria: [
                {
                    fieldPath: 'CCCWA__Object__c',
                    operator: 'eq',
                    value: this.selectedObject,
                },
                {
                    fieldPath: 'CCCWA__Status__c',
                    operator: 'eq',
                    value: 'APPROVED',
                }
            ],
            filterLogic: '1 AND 2',
        };
    }

    // Handle the template selection
    handleGetSelectedRecordId(event) {
        this.templateRecordId = event.detail.recordId; // Get selected template ID
        if (this.templateRecordId) {
            this.isLoading = true; // Start loading
            this.fetchTemplateDetails(); // Fetch template details
        }
    }

    // Fetch template details from Apex
    fetchTemplateDetails() {
        getExistingTemplate({ templateId: this.templateRecordId })
            .then(result => {
                if (result) {
                    console.log('result  -- ' + result);
                    this.objTemplate = JSON.parse(result); // Parse template data
                    this.setupTemplatePreview(); // Setup preview
                    this.isLoading = false; // Stop loading
                }
            })
            .catch(error => {
                this.isLoading = false; // Stop loading
                this.handleError(error); // Handle error
            });
    }

    // Setup the template preview
    setupTemplatePreview() {
        this.isQuickReplyList = this.objTemplate.isQuickReplyList;
        this.isActionList = this.objTemplate.isActionList;
        this.templateViewBody = this.objTemplate.templateBody;

        // Check for media types
        this.isMediaImage = this.objTemplate.headerType === 'MEDIA' && this.objTemplate.mediaType === 'IMAGE';
        this.isMediaVideo = this.objTemplate.headerType === 'MEDIA' && this.objTemplate.mediaType === 'VIDEO';
        this.isMediaDoc = this.objTemplate.headerType === 'MEDIA' && this.objTemplate.mediaType === 'DOCUMENT';

        this.buildPreview(); // Build the preview
    }

    // Build the preview content
    buildPreview() {
        let header = this.objTemplate.isHeaderText ?
            `<div style="text-align:center"><b>${this.objTemplate.headerText}</b></div><div style="padding-left: 3px">${this.objTemplate.templateBody}</div>` :
            this.objTemplate.templateBody;

        if (this.objTemplate.footer) {
            header += `</br><p style="font-size : 12px" class="slds-text-color_inverse-weak">${this.objTemplate.footer}<p>`;
        }

        this.templateViewBody = header; // Set the preview body
        let body = this.templateViewBody;
        if (this.objTemplate.listMapping != null && this.objTemplate.listMapping != undefined && this.objTemplate.listMapping.length > 0) {
            let list = [];
            for (let i = 0; i < this.objTemplate.listMapping.length; i++) {
                list.push(this.objTemplate.listMapping[i].exampleText);
                // var expression = "^[" + this.lstMapping[i].placeHolder + "].*$";
                // const regex = new RegExp(expression, 'i'); ;
            }
            console.log('list -- ' + list);
            body = this.replacePlaceholders(body, list);
            this.templateViewBody = body;
            console.log('this.templateViewBody -- ' + this.templateViewBody);
        }
        this.previewActionButtons = this.isQuickReplyList ? this.objTemplate.listQuickReply : this.objTemplate.listActions; // Set action buttons
    }

    replacePlaceholders(text, replacements) {
        return text.replace(/\{\{(\d+)\}\}/g, (match, index) => {
            const replacement = replacements[Number(index) - 1];
            return replacement !== undefined ? replacement : match;
        });
    }

    // Handle sending the template
    handleSendTemplate() {

        if (this.templateRecordId && this.templateRecordId != '') {
            this.isLoading = true; // Start loading
            sendWhatsAppMessageBulk({ recordIds: this.selectedRecordIds, templateRecordId: this.templateRecordId })
                .then(() => {
                    this.isLoading = false; // Stop loading
                    this.showToast('Success', 'Templates sent successfully.', 'success'); // Show success message
                    setTimeout(() => {
                        window.location.reload(); // Reload the page after a delay
                    }, 500);
                })
                .catch(error => {
                    this.isLoading = false; // Stop loading
                    this.handleError(error); // Handle error
                });
        } else {
            this.showToast('Error!', 'Please select template before sending the message template!', 'error');
        }

    }

    handlePreviewTemplate() {
        if (this.templateRecordId) {
            this.isModalOpen = true;
        }
    }

    closeModal() {
        this.isModalOpen = false;
    }

    // Show toast messages
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt); // Dispatch the toast event
    }

    // Handle errors
    handleError(error) {
        if (error) {
            let tempErrorList = [];
            if (Array.isArray(error.body)) {
                tempErrorList = error.body.map((e) => e.message);
            } else if (error.body && typeof error.body.message === 'string') {
                tempErrorList = [error.body.message];
            } else if (error.body && error.body.fieldErrors && error.body.fieldErrors.message) {
                tempErrorList = Object.values(error.body.fieldErrors).flat().map((fieldError) => fieldError.message);
            } else if (Array.isArray(error.body.pageErrors) && error.body.pageErrors.length > 0) {
                tempErrorList = error.body.pageErrors.map((e) => e.message);
            } else if (typeof error.message === 'string') {
                tempErrorList = [error.message];
            }
            this.showToast('Error!', tempErrorList.join(', '), 'error'); // Show error message
        }
        this.isLoading = false; // Stop loading
    }
}