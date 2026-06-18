import { LightningElement ,track} from 'lwc';
import whatsAppTemplates from '@salesforce/apex/C3WhatsAppTemplateHomeController.whatsAppTemplates';
import deleteWhatsAppTemplates from '@salesforce/apex/C3WhatsAppTemplateHomeController.deleteWhatsAppTemplates';
import getExistingTemplate from '@salesforce/apex/C3WhatsAppTemplateScreenLWCCtrl.getExistingTemplate';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class WhatsAppTemplateHome extends LightningElement {
    showMapping = true;
    @track isLoading=false;
    @track isModalOpen = false;
    @track templateViewBody = '';
    @track isQuickReplyList = false;
    @track isActionList = false;
    @track lstActions = [];
    @track listQuickReply = [];
    @track previewActionButtons = [];
    @track isMediaImage = false;
    @track isMediaDoc = false;
    @track isMediaVideo = false;
    @track isCreateNewTemplate = false;
    @track isTemplateTab = false;
    @track isEditTemplate = false;
    @track recordId;

    @track objTemplate = {
        templateId : "",
        whatsAppTemplateId : "",
        headerType : "",
        headerText : "",
        documentId : "",
        mimeType : "",
        publicDocUrl : "",
        mediaHandler : "",
        contentVersionId : "",
        language : "en",
        project : " ",
        templateName : "",
        templateBody : "",
        templateBodyText : "",
        footer : "",
        category : "",
        buttonOption : "",
        mediaType : "",
        fileName : "",
        objectName : "Contact",
        isHeaderText : false,
        isHeaderMedia : false,
        isActionList : false,
        isQuickReplyList : false,
        listMapping : [],
        listQuickReply : [],
        listActions : []
    }



    @track filtered = [];
    @track lstRecords = [];
    connectedCallback() {  
        this.isTemplateTab = true; 
        this.showMapping=true;
        this.init();
    }

    init(){
        console.log('came here')
        whatsAppTemplates({})
        .then(result => {
            if(JSON.parse(result).success){
                console.log(JSON.parse(result));
                this.filtered = [];
                this.lstRecords=JSON.parse(result);
                for (let i = 0; i < this.lstRecords.listOfTemplates.length; i++) {
                    if(this.lstRecords.listOfTemplates[i].CCCWA__Status__c=='APPROVED'){
                        this.filtered.push({ APPROVED: true, Template: this.lstRecords.listOfTemplates[i] });    
                    }
                    else if(this.lstRecords.listOfTemplates[i].CCCWA__Status__c=='REJECTED'){
                        this.filtered.push({ REJECTED: true, Template: this.lstRecords.listOfTemplates[i] });      
                    }
                    else{
                        this.filtered.push({ PENDING: true, Template: this.lstRecords.listOfTemplates[i] });      
                    }    
                    this.showPopup = false;                            
                }                         
            } else{
                this.filtered = [];
            }                                               
        })
        /*.catch(error => {
        });*/
    }

    handlePreview(event){
        let templateId = event.target.value;
        console.log('templateId ---- '+templateId);
        if(templateId){
            this.isLoading = true;
            getExistingTemplate({templateId : templateId})
            .then(result => {
                if(result){
                    this.objTemplate = JSON.parse(result);
                    console.log('objTemplate---  '+ JSON.stringify(this.objTemplate));
                    this.isQuickReplyList = this.objTemplate.isQuickReplyList;
                    this.isActionList = this.objTemplate.isActionList;
                    this.templateViewBody = this.objTemplate.templateBody;
                    this.lstActions = this.objTemplate.listActions;
                    
                    if(this.objTemplate.listQuickReply != null && this.objTemplate.listQuickReply != undefined && this.objTemplate.listQuickReply.length > 0){
                        this.listQuickReply = this.objTemplate.listQuickReply;
                    }
                    if(this.objTemplate.listActions != null && this.objTemplate.listActions != undefined && this.objTemplate.listActions.length > 0){
                        this.listActions = this.objTemplate.listActions;
                    }
                    if(this.objTemplate.headerType == 'MEDIA'){
                        if(this.objTemplate.mediaType == 'IMAGE'){
                            this.isMediaImage = true;
                        }
                        if(this.objTemplate.mediaType == 'VIDEO'){
                            this.isMediaVideo = true;
                        }
                        if(this.objTemplate.mediaType == 'DOCUMENT'){
                            this.isMediaDoc = true;
                        }
                    }
                    else{
                        this.isMediaImage = false;
                        this.isMediaVideo = false;
                        this.isMediaDoc = false;
                    }
                    this.buildPreview();
                    this.isModalOpen = true;
                    this.isLoading = false;
                }

            })
            .catch(error => {
                this.isLoading = false;
                
                console.log('Error: '+JSON.stringify(error));
            });
        }
        
    }

    closeModal() {
        this.isModalOpen = false;
    }

    deletingRecordId;
    @track showPopup = false;
    handleDelete(event){
        this.deletingRecordId = event.target.value;
        this.showPopup = true;
    }

    handleCancel(){
        this.showPopup = false;
        this.deletingRecordId = '';
    }

    handleDeleteYes(){
        if(this.deletingRecordId){
            this.isLoading=true;
            deleteWhatsAppTemplates({RecordId:this.deletingRecordId})
            .then(result => {
    if (JSON.parse(result).success) {
        this.RecordDeleted();
        this.init(); 
    } else {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: 'Failed to delete the template.',
            variant: 'error'
        }));
    }
    this.isLoading = false;
    this.showPopup = false;
})

            .catch(error => {
                console.log(error)
            });
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

    buildPreview(){
        try{
            console.log('this.objTemplate-- '+ JSON.stringify(this.objTemplate));
            let header = '';
            if(this.objTemplate.isHeaderText){
                header = '<div style="text-align:center"><b>'+ this.objTemplate.headerText + '</b></div><div style"style=" padding-left: 3px">' + this.objTemplate.templateBody+ '</div>';
            }else{
                header = this.objTemplate.templateBody;
            }   
            

            if(this.objTemplate.footer != '' && this.objTemplate.footer != null && this.objTemplate.footer != undefined){
            let footer = '</br><p style="font-size : 12px" class="slds-text-color_inverse-weak">'+ this.objTemplate.footer +'<p>';
            header = header + footer;
            }

            console.log('header---- '+ header);
            this.templateViewBody = header;
            let body = this.templateViewBody;

            if(this.objTemplate.listMapping != null && this.objTemplate.listMapping != undefined && this.objTemplate.listMapping.length > 0){
                let list = [];
                for(let i=0; i < this.objTemplate.listMapping.length; i++){
                    list.push(this.objTemplate.listMapping[i].exampleText);
                    // var expression = "^[" + this.lstMapping[i].placeHolder + "].*$";
                    // const regex = new RegExp(expression, 'i'); ;
                }
                console.log('list -- '+list);
                body = this.replacePlaceholders(body, list);
                this.templateViewBody = body;
                console.log('this.templateViewBody -- '+this.templateViewBody);
            }

            if(this.isQuickReplyList){
                this.previewActionButtons = this.listQuickReply;
            }
            if(this.isActionList){
                this.previewActionButtons = this.lstActions;
            }
            
        }catch(error){
            console.log('error---'+error);
        }
        
    }

    replacePlaceholders(text, replacements) {
        return text.replace(/\{\{(\d+)\}\}/g, (match, index) => {
            const replacement = replacements[Number(index) - 1];
            return replacement !== undefined ? replacement : match;
        });
    }

    handleNCSave(){
        this.isCreateNewTemplate = true;
        this.isTemplateTab = false;
    }

    handleNCEdit(event){
        this.recordId = event.target.value;
        this.isEditTemplate = true;
        this.isCreateNewTemplate = false;
        this.isTemplateTab = false;
        
    }
}