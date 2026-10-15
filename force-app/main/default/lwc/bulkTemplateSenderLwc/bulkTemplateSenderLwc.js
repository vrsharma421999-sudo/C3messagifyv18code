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

        const newObj = {};
        for (const key in obj) {
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
        const fieldName = event.target.name;
        const value = event.target.value;

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
                    // Automatically load initial records for the selected object
                    return fetchObjectRecords({ objectName: objectName, whereClause: '', orderBy: '' });
                }
                return null;
            })
            .then(data => {
                if (data && data.length > 0) {
                    this.populateTableData(data);
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
        this.filterRows = [...this.filterRows, { id: Date.now(), field: '', operator: '=', value: '' }];
    }

    handleRemoveFilter(event) {
        const idToRemove = event.target.dataset?.id || event.currentTarget?.dataset?.id;
        if (!idToRemove) return;
        this.filterRows = this.filterRows.filter(row => String(row.id) !== String(idToRemove));
    }

    handleFilterChange(event) {
        const rowId = event.target.dataset?.id || event.currentTarget?.dataset?.id;
        const fieldName = event.target.name;
        const value = event.target.value;

        if (!rowId) return;

        const rowIndex = this.filterRows.findIndex(row => String(row.id) === String(rowId));
        if (rowIndex !== -1) {
            this.filterRows[rowIndex] = {
                ...this.filterRows[rowIndex],
                [fieldName]: value
            };
            this.filterRows = [...this.filterRows];
        }
    }

    handleClearFilters() {
        this.filterRows = [{ id: Date.now(), field: '', operator: '=', value: '' }];
        this.handleApplyFilters();
    }

    buildWhereClause() {
        const conditions = [];
        this.filterRows.forEach(row => {
            if (row.field && row.value !== '' && row.value !== undefined && row.value !== null) {
                let condition = '';
                let val = String(row.value).trim();
                val = val.replace(/\\/g, "\\\\").replace(/'/g, "\\'");

                const fieldObj = this.filterableFields.find(f => f.value?.toLowerCase() === row.field?.toLowerCase());
                const fieldType = fieldObj ? fieldObj.type : 'STRING';

                const isStringOrId = (
                    fieldType === 'STRING' ||
                    fieldType === 'PICKLIST' ||
                    fieldType === 'MULTIPICKLIST' ||
                    fieldType === 'TEXTAREA' ||
                    fieldType === 'PHONE' ||
                    fieldType === 'EMAIL' ||
                    fieldType === 'URL' ||
                    fieldType === 'ID' ||
                    fieldType === 'REFERENCE' ||
                    fieldType === 'COMBOBOX'
                );

                if (row.operator === 'LIKE') {
                    condition = `${row.field} LIKE '%${val}%'`;
                } else if (isStringOrId) {
                    condition = `${row.field} ${row.operator} '${val}'`;
                } else if (fieldType === 'BOOLEAN') {
                    const boolVal = (val.toLowerCase() === 'true' || val === '1') ? 'true' : 'false';
                    condition = `${row.field} ${row.operator} ${boolVal}`;
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
        try {
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
                        this.showToast('Warning', 'No records found matching the filter criteria. Please adjust your filters and try again.', 'warning');
                    }
                })
                .catch(error => {
                    this.resetTableData();
                    this.handleError(error);
                })
                .finally(() => {
                    this.isLoading = false;
                });
        } catch (err) {
            this.isLoading = false;
            this.handleError(err);
        }
    }

    populateTableData(data) {
        if (!data || !Array.isArray(data) || data.length === 0) {
            this.resetTableData();
            this.showToast('Warning', 'No records found matching the filter criteria.', 'warning');
            return;
        }
        this.tableData = data;

        const labelMap = new Map();
        if (this.filterableFields && Array.isArray(this.filterableFields)) {
            this.filterableFields.forEach(f => {
                if (f.value) {
                    labelMap.set(f.value.toLowerCase(), f.label);
                }
            });
        }

        const sampleRecord = data[0] || {};
        this.columns = Object.keys(sampleRecord)
            .filter(field => field.toLowerCase() !== 'id')
            .map(field => ({
                label: labelMap.get(field.toLowerCase()) || field.replace(/_/g, ' '),
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
            const list = [];
            for (let i = 0; i < this.objTemplate.listMapping.length; i++) {
                list.push(this.objTemplate.listMapping[i].exampleText);
                // var expression = "^[" + this.lstMapping[i].placeHolder + "].*$";
                // const regex = new RegExp(expression, 'i'); ;
            }
            body = this.replacePlaceholders(body, list);
            this.templateViewBody = body;
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
            let errorMsg = 'An unexpected error occurred.';
            if (tempErrorList.length > 0 && tempErrorList.join(', ').trim() !== '') {
                errorMsg = tempErrorList.join(', ');
            } else if (typeof error === 'string') {
                errorMsg = error;
            } else if (error && error.message) {
                errorMsg = error.message;
            }
            this.showToast('Error!', errorMsg, 'error'); // Show error message
        }
        this.isLoading = false; // Stop loading
    }
}