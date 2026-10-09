import { LightningElement, track } from 'lwc';
import getObjectsfromNumberConfig from '@salesforce/apex/C3BulkTemplateSenderLwcController.getObjectsfromNumberConfig';
import validateObject from '@salesforce/apex/C3BulkTemplateSenderLwcController.validateObject';
import fetchObjectRecords from '@salesforce/apex/C3BulkTemplateSenderLwcController.fetchObjectRecords';
import getFilterableFields from '@salesforce/apex/C3BulkTemplateSenderLwcController.getFilterableFields';
import getExistingTemplate from '@salesforce/apex/C3WhatsAppTemplateScreenLWCCtrl.getExistingTemplate';
import sendWhatsAppMessageBulk from '@salesforce/apex/C3WhatsAppTemplateScreenLWCCtrl.sendWhatsAppMessageBulk';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import TEMPLATE_OBJECT from '@salesforce/schema/Template_Object__c';
import OBJECT_FIELD from '@salesforce/schema/Template_Object__c.Object__c';
import STATUS_FIELD from '@salesforce/schema/Template_Object__c.Status__c';

// Main class for the Bulk Template Sender component
export default class BulkTemplateSenderLwc extends LightningElement {
    // Track properties for data binding
    @track tableData = [];
    @track columns = [];
    @track selectedRecordIds = [];
    @track objTemplate = {};
    @track templateViewBody = '';
    @track previewActionButtons = [];
    @track filterRows = [];
    @track filterableFields = [];
    @track sortDirection = 'asc';
    @track sortedBy = '';

    operatorOptions = [
        { label: 'Equals', value: '=' },
        { label: 'Not Equals', value: '!=' },
        { label: 'Greater Than', value: '>' },
        { label: 'Less Than', value: '<' },
        { label: 'Contains', value: 'LIKE' }
    ];

    // Other properties
    objectOptions = [];
    selectedObject = '';
    isLoading = false;
    objectValidate = false;
    showRecordTable = false;
    showTemplateSelector = false;
    filter = {};
    templateRecordId = '';
    templateObjectApiName = TEMPLATE_OBJECT.objectApiName;
    isModalOpen = false;
    isQuickReplyList = false;
    isActionList = false;
    isMediaImage = false;
    isMediaDoc = false;
    isMediaVideo = false;

    // Lifecycle hook: Called when the component is inserted into the DOM

    stripNamespace(obj) {
        if (!obj || typeof obj !== 'object') return obj;
        if (Array.isArray(obj)) return obj.map(item => this.stripNamespace(item));
        
        let newObj = {};
        for (let key in obj) {
            let newKey = key;
            if (key.endsWith('__c') && key.split('__').length === 3) {
                newKey = key.split('__')[1] + '__c';
            } else if (key.endsWith('__r') && key.split('__').length === 3) {
                newKey = key.split('__')[1] + '__r';
            }
            newObj[newKey] = this.stripNamespace(obj[key]);
        }
        return newObj;
    }

    connectedCallback() {
        this.isLoading = true; // Start loading
        this.fetchObjectOptions(); // Fetch object options
    }

    // Fetch available object options from Apex
    fetchObjectOptions() {
        getObjectsfromNumberConfig()
            .then(result => {
                if (result) {
                    this.objectOptions = this.stripNamespace(JSON.parse(result)).sort((a, b) =>
                        a.label.localeCompare(b.label)
                    );
                    this.isLoading = false; // Stop loading
                }
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
            this.filterRows = [];
            this.fetchFieldsAndValidate(value); 
        }
    }

    // Reset table data and columns
    resetTableData() {
        this.tableData = [];
        this.columns = [];
        this.showTemplateSelector = false;
        this.showRecordTable = false;
    }

    fetchFieldsAndValidate(objectName) {
        this.isLoading = true;
        this.objectValidate = false;
        
        validateObject({ objectName: objectName })
            .then(result => {
                if (result) {
                    return getFilterableFields({ objectName: objectName });
                } else {
                    throw new Error('Validation failed for object: ' + objectName);
                }
            })
            .then(fieldsJson => {
                if (fieldsJson) {
                    this.filterableFields = JSON.parse(fieldsJson);
                    // Initialize with one empty filter row
                    this.filterRows = [{ id: Date.now(), field: '', operator: '=', value: '' }];
                }
            })
            .catch(error => {
                this.objectValidate = false;
                this.handleError(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    get hasFilterableFields() {
        return this.filterableFields.length > 0;
    }

    handleAddFilter() {
        this.filterRows.push({ id: Date.now(), field: '', operator: '=', value: '' });
    }

    handleRemoveFilter(event) {
        const idToRemove = event.target.dataset.id;
        this.filterRows = this.filterRows.filter(row => row.id.toString() !== idToRemove.toString());
    }

    handleFilterChange(event) {
        const rowId = event.target.dataset.id;
        const fieldName = event.target.name;
        const value = event.target.value;
        
        const rowIndex = this.filterRows.findIndex(row => row.id.toString() === rowId.toString());
        if (rowIndex !== -1) {
            this.filterRows[rowIndex][fieldName] = value;
        }
    }

    buildWhereClause() {
        let conditions = [];
        this.filterRows.forEach(row => {
            if (row.field && row.value) {
                let condition = '';
                const fieldType = this.filterableFields.find(f => f.value === row.field)?.type;
                let val = String(row.value).trim();
                
                // Escape single quotes for SOQL
                val = val.replace(/'/g, "\\'");
                
                let isString = (fieldType === 'STRING' || fieldType === 'PICKLIST' || fieldType === 'TEXTAREA' || fieldType === 'PHONE' || fieldType === 'EMAIL' || fieldType === 'URL');
                
                if (row.operator === 'LIKE') {
                    condition = `${row.field} LIKE '%${val}%'`;
                } else if (isString && (row.operator === '=' || row.operator === '!=') ) {
                    condition = `${row.field} ${row.operator} '${val}'`;
                } else {
                    condition = `${row.field} ${row.operator} ${val}`;
                }
                conditions.push(condition);
            }
        });
        
        return conditions.join(' AND ');
    }

    handleApplyFilters() {
        this.isLoading = true;
        const whereClause = this.buildWhereClause();
        
        let orderBy = '';
        if (this.sortedBy) {
            orderBy = `${this.sortedBy} ${this.sortDirection}`;
        }
        
        fetchObjectRecords({ objectName: this.selectedObject, whereClause: whereClause, orderBy: orderBy })
            .then(data => {
                if (data && data.length > 0) {
                    this.populateTableData(data);
                } else {
                    this.resetTableData();
                    this.showToast('Info', 'No records found matching the criteria.', 'info');
                }
            })
            .catch(error => {
                this.handleError(error);
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    populateTableData(data) {
        this.tableData = data;
        this.columns = Object.keys(data[0])
            .filter(field => field !== 'Id' && typeof data[0][field] !== 'object')
            .map(field => ({
                label: field.replace(/_/g, ' '),
                fieldName: field,
                type: 'text',
                sortable: true
            }));
        this.showRecordTable = true; 
    }

    handleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.tableData];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.tableData = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    sortBy(field, reverse, primer) {
        const key = primer
            ? function (x) { return primer(x[field]); }
            : function (x) { return x[field]; };

        return function (a, b) {
            a = key(a);
            b = key(b);
            if (a === undefined) a = '';
            if (b === undefined) b = '';
            return reverse * ((a > b) - (b > a));
        };
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
                    fieldPath: OBJECT_FIELD.fieldApiName,
                    operator: 'eq',
                    value: this.selectedObject,
                },
                {
                    fieldPath: STATUS_FIELD.fieldApiName,
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
                    this.objTemplate = this.stripNamespace(JSON.parse(result)); // Parse template data
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