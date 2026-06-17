import { LightningElement, track, api,wire} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveTemplateData from '@salesforce/apex/C3WhatsAppTemplateScreenLWCCtrl.saveTemplateData';
import sendWhatsAppTemplateToMeta from '@salesforce/apex/C3WhatsAppWebService.sendWhatsAppTemplateToMeta';
import verifyUpload from '@salesforce/apex/C3WhatsAppTemplateScreenLWCCtrl.verifyUpload';
import deleteUploadedDocument from '@salesforce/apex/C3WhatsAppTemplateScreenLWCCtrl.deleteUploadedDocument';
import getExistingTemplate from '@salesforce/apex/C3WhatsAppTemplateScreenLWCCtrl.getExistingTemplate';
import getObjectsfromNumberConfig from '@salesforce/apex/C3BulkTemplateSenderLwcController.getObjectsfromNumberConfig';
import objectFields from '@salesforce/apex/C3Utility.getObjectFields';
import getProjectNames from '@salesforce/apex/C3Utility.getProjectNames';


export default class whatsAppTemplateApprover extends LightningElement {
    @api recordId;
    @track templateDetails;
    @track fetchDetails = true;
    @track isLoading = false;
    @track error;
    @track getDetails = '';
    @track isEdit = false;
    @track Templateid;
    @track objectOptions = [];
    @track selectedObject = '';
    @track isShowPopup = false;
    @track website = false;
    @track fastReply = false;
    @track callToAction = false;
    @track isNextModal = false;
    @track expTimeValue = '';
    @track isExpirationTime = false;
    @track addSecurityRecom = '';
    @track button_value = '';
    @track buttonTextInput = '';
    @track phone_website = '';
    @track buttonTextCharacterCount = 0;
    @track phoneWebsiteCount = 0;
    @track actionType = '';
    @track URLvalue = 'static';
    @track countryCode = '';
    @track fielOptions = [];
    @track headerText = '';
    @track codeDeliveryOptionValue = '';
    @track isAutofill = false;
    @track autofillInputValue = '';
    @track copycodeInputValue = '';
    @track AppSignHashInputValue = '';
    @track packageNameInputValue = '';
   // @track autofillInputValue = '';
    @track otpType = '';
    @track bodyText = '';
    @track footerText = '';
    @track templateName = '';
    @track templateLanguage = '';
    @track category = '';
    @track isButton_marketing_optin = false;
    @track isCategoryNotAuth = true;
    @track lstMapping = [];
    @track fieldNameOptions = [];
    @track projectOptions = [];

    fieldDisabled = false;
    templateHelpText = 'Use "+ Add Parameter" button to create mapping used to bind fields dynamically from the records in the template.';
    selectObjectHelptext = "if you don't see your object in the dropdown,"+ ' please configure your object in the "WhatsApp Number Configuration" tab before proceeding further!';
    formats = [
        'bold',
        'italic',
        'strike',
    ];




    connectedCallback() {
        this.isLoading = true;
        console.log('recordId---  '+ this.recordId);
        if(this.recordId){
            this.fieldDisabled = true;
        }
        this.isShowPopup = true;
        this.template.language='en';
        // this.template.objectName='Contact';
        this.fetchTemplateDetails();
    }

    fetchTemplateDetails() {
        
        if(this.recordId){
            this.isUpdate = true;
            getExistingTemplate({templateId : this.recordId})
            .then(result => {
                this.isLoading = false;
                if(result){
                    this.objTemplate = JSON.parse(result);
                    console.log('objTemplate---  '+ JSON.stringify(this.objTemplate));
                    this.isQuickReplyList = this.objTemplate.isQuickReplyList;
                    this.isActionList = this.objTemplate.isActionList;
                    if(this.objTemplate.listMapping != null && this.objTemplate.listMapping != undefined && this.objTemplate.listMapping.length > 0){
                        this.showMapping = true;
                        this.lstMapping = this.objTemplate.listMapping;
                        this.tempListMapping = this.objTemplate.listMapping;
                        this.templateViewBody = this.objTemplate.templateBody;
                        if(this.objTemplate.templateBodyText)
                            this.bodyLength = 1024 - this.objTemplate.templateBodyText.length;
                        else
                            this.bodyLength = 1024 - this.objTemplate.templateBody.length;
                        
                        this.lstActions = this.objTemplate.listActions;
                    }
                    if(this.objTemplate.listQuickReply != null && this.objTemplate.listQuickReply != undefined && this.objTemplate.listQuickReply.length > 0){
                        this.listQuickReply = this.objTemplate.listQuickReply;
                        if(this.objTemplate.listQuickReply.length > 0 && this.objTemplate.listQuickReply.length < 2)
                            this.showAddButton = true;
                    }
                    if(this.objTemplate.listActions != null && this.objTemplate.listActions != undefined && this.objTemplate.listActions.length > 0){
                        this.listActions = this.objTemplate.listActions;
                        if(this.objTemplate.listActions.length > 0 && this.objTemplate.listActions.length < 2)
                            this.showAddButton = true;
                    }
                    if(this.objTemplate.category == 'UTILITY'){
                        this.divUtilityClick();
                    }else if(this.objTemplate.category == 'MARKETING'){
                        this.divClick();
                    }else if(this.objTemplate.category == 'AUTHENTICATION'){
                        this.divAuthClick();
                    }
                    this.handleHeaderType(this.objTemplate.headerType);
                    if(this.objTemplate.objectName != null && this.objTemplate.objectName != undefined && this.objTemplate.objectName != '')
                        this.handleObjectFields(this.objTemplate.objectName);
                }
            })
            .catch(error => {
                console.log('Error: ', JSON.stringify(error));

                this.isLoading = false;
                this.error = error;
                this.handleError(error);
            });
        }else{
            // this.handleObjectFields(this.objTemplate.objectName);
            this.isLoading = false;
        }
        
        getObjectsfromNumberConfig()
        .then(result => {
            this.objectOptions = JSON.parse(result);
        })
        .catch(error => {
            console.log('Error: ', JSON.stringify(error));
            this.handleError(error);
        });
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

    

    // @wire(getTemplateData)
    // wiredData({data, error}){
    //     if(data){
    //         this.templateDetails = data;
    //         console.log('data: ' + data);
    //         console.log('temp: ' + this.templateDetails);
    //     }
    //     else{
    //         console.log('Error');
    //     }
    // }

  

    
    get countryPhoneCodeOptions() {
        return [
            { "label": "(+93) Afghanistan", "value": "93" },
            { "label": "(+355) Albania", "value": "355" },
            { "label": "(+213) Algeria", "value": "213" },
            { "label": "(+376) Andorra", "value": "376" },
            { "label": "(+244) Angola", "value": "244" },
            { "label": "(+1264) Anguilla", "value": "1264" },
            { "label": "(+1268) Antigua and Barbuda", "value": "1268" },
            { "label": "(+54) Argentina", "value": "54" },
            { "label": "(+374) Armenia", "value": "374" },
            { "label": "(+297) Aruba", "value": "297" },
            { "label": "(+247) Ascension Island", "value": "247" },
            { "label": "(+61) Australia", "value": "61" },
            { "label": "(+43) Austria", "value": "43" },
            { "label": "(+994) Azerbaijan", "value": "994" },
            { "label": "(+1242) Bahamas", "value": "1242" },
            { "label": "(+973) Bahrain", "value": "973" },
            { "label": "(+880) Bangladesh", "value": "880" },
            { "label": "(+1246) Barbados", "value": "1246" },
            { "label": "(+375) Belarus", "value": "375" },
            { "label": "(+32) Belgium", "value": "32" },
            { "label": "(+501) Belize", "value": "501" },
            { "label": "(+229) Benin", "value": "229" },
            { "label": "(+1441) Bermuda", "value": "1441" },
            { "label": "(+975) Bhutan", "value": "975" },
            { "label": "(+591) Bolivia", "value": "591" },
            { "label": "(+387) Bosnia and Herzegovina", "value": "387" },
            { "label": "(+267) Botswana", "value": "267" },
            { "label": "(+55) Brazil", "value": "55" },
            { "label": "(+246) British Indian Ocean Territory", "value": "246" },
            { "label": "(+673) Brunei", "value": "673" },
            { "label": "(+359) Bulgaria", "value": "359" },
            { "label": "(+226) Burkina Faso", "value": "226" },
            { "label": "(+257) Burundi", "value": "257" },
            { "label": "(+855) Cambodia", "value": "855" },
            { "label": "(+237) Cameroon", "value": "237" },
            { "label": "(+1) Canada", "value": "1" },
            { "label": "(+238) Cape Verde", "value": "238" },
            { "label": "(+1345) Cayman Islands", "value": "1345" },
            { "label": "(+236) Central African Republic", "value": "236" },
            { "label": "(+235) Chad", "value": "235" },
            { "label": "(+56) Chile", "value": "56" },
            { "label": "(+86) China", "value": "86" },
            { "label": "(+61) Christmas Island", "value": "61" },
            { "label": "(+61) Cocos (Keeling) Islands", "value": "61" },
            { "label": "(+57) Colombia", "value": "57" },
            { "label": "(+269) Comoros", "value": "269" },
            { "label": "(+242) Congo (Brazzaville)", "value": "242" },
            { "label": "(+243) Congo (Kinshasa)", "value": "243" },
            { "label": "(+682) Cook Islands", "value": "682" },
            { "label": "(+506) Costa Rica", "value": "506" },
            { "label": "(+385) Croatia", "value": "385" },
            { "label": "(+53) Cuba", "value": "53" },
            { "label": "(+599) Curaçao", "value": "599" },
            { "label": "(+357) Cyprus", "value": "357" },
            { "label": "(+420) Czech Republic", "value": "420" },
            { "label": "(+225) Côte d'Ivoire", "value": "225" },
            { "label": "(+45) Denmark", "value": "45" },
            { "label": "(+253) Djibouti", "value": "253" },
            { "label": "(+1767) Dominica", "value": "1767" },
            { "label": "(+1809) Dominican Republic", "value": "1809" },
            { "label": "(+593) Ecuador", "value": "593" },
            { "label": "(+20) Egypt", "value": "20" },
            { "label": "(+503) El Salvador", "value": "503" },
            { "label": "(+240) Equatorial Guinea", "value": "240" },
            { "label": "(+291) Eritrea", "value": "291" },
            { "label": "(+372) Estonia", "value": "372" },
            { "label": "(+251) Ethiopia", "value": "251" },
            { "label": "(+500) Falkland Islands", "value": "500" },
            { "label": "(+298) Faroe Islands", "value": "298" },
            { "label": "(+679) Fiji", "value": "679" },
            { "label": "(+358) Finland", "value": "358" },
            { "label": "(+33) France", "value": "33" },
            { "label": "(+594) French Guiana", "value": "594" },
            { "label": "(+689) French Polynesia", "value": "689" },
            { "label": "(+241) Gabon", "value": "241" },
            { "label": "(+220) Gambia", "value": "220" },
            { "label": "(+995) Georgia", "value": "995" },
            { "label": "(+49) Germany", "value": "49" },
            { "label": "(+233) Ghana", "value": "233" },
            { "label": "(+350) Gibraltar", "value": "350" },
            { "label": "(+30) Greece", "value": "30" },
            { "label": "(+299) Greenland", "value": "299" },
            { "label": "(+1473) Grenada", "value": "1473" },
            { "label": "(+590) Guadeloupe", "value": "590" },
            { "label": "(+1671) Guam", "value": "1671" },
            { "label": "(+502) Guatemala", "value": "502" },
            { "label": "(+224) Guinea", "value": "224" },
            { "label": "(+245) Guinea-Bissau", "value": "245" },
            { "label": "(+592) Guyana", "value": "592" },
            { "label": "(+509) Haiti", "value": "509" },
            { "label": "(+504) Honduras", "value": "504" },
            { "label": "(+852) Hong Kong", "value": "852" },
            { "label": "(+36) Hungary", "value": "36" },
            { "label": "(+354) Iceland", "value": "354" },
            { "label": "(+91) India", "value": "91" },
            { "label": "(+62) Indonesia", "value": "62" },
            { "label": "(+98) Iran", "value": "98" },
            { "label": "(+964) Iraq", "value": "964" },
            { "label": "(+353) Ireland", "value": "353" },
            { "label": "(+972) Israel", "value": "972" },
            { "label": "(+39) Italy", "value": "39" },
            { "label": "(+1876) Jamaica", "value": "1876" },
            { "label": "(+81) Japan", "value": "81" },
            { "label": "(+962) Jordan", "value": "962" },
            { "label": "(+7) Kazakhstan", "value": "7" },
            { "label": "(+254) Kenya", "value": "254" },
            { "label": "(+686) Kiribati", "value": "686" },
            { "label": "(+383) Kosovo", "value": "383" },
            { "label": "(+965) Kuwait", "value": "965" },
            { "label": "(+996) Kyrgyzstan", "value": "996" },
            { "label": "(+856) Laos", "value": "856" },
            { "label": "(+371) Latvia", "value": "371" },
            { "label": "(+961) Lebanon", "value": "961" },
            { "label": "(+266) Lesotho", "value": "266" },
            { "label": "(+231) Liberia", "value": "231" },
            { "label": "(+218) Libya", "value": "218" },
            { "label": "(+423) Liechtenstein", "value": "423" },
            { "label": "(+370) Lithuania", "value": "370" },
            { "label": "(+352) Luxembourg", "value": "352" },
            { "label": "(+853) Macau", "value": "853" },
            { "label": "(+389) Macedonia", "value": "389" },
            { "label": "(+261) Madagascar", "value": "261" },
            { "label": "(+265) Malawi", "value": "265" },
            { "label": "(+60) Malaysia", "value": "60" },
            { "label": "(+960) Maldives", "value": "960" },
            { "label": "(+223) Mali", "value": "223" },
            { "label": "(+356) Malta", "value": "356" },
            { "label": "(+692) Marshall Islands", "value": "692" },
            { "label": "(+596) Martinique", "value": "596" },
            { "label": "(+222) Mauritania", "value": "222" },
            { "label": "(+230) Mauritius", "value": "230" },
            { "label": "(+262) Mayotte", "value": "262" },
            { "label": "(+52) Mexico", "value": "52" },
            { "label": "(+691) Micronesia", "value": "691" },
            { "label": "(+373) Moldova", "value": "373" },
            { "label": "(+377) Monaco", "value": "377" },
            { "label": "(+976) Mongolia", "value": "976" },
            { "label": "(+382) Montenegro", "value": "382" },
            { "label": "(+1664) Montserrat", "value": "1664" },
            { "label": "(+212) Morocco", "value": "212" },
            { "label": "(+258) Mozambique", "value": "258" },
            { "label": "(+95) Myanmar", "value": "95" },
            { "label": "(+264) Namibia", "value": "264" },
            { "label": "(+674) Nauru", "value": "674" },
            { "label": "(+977) Nepal", "value": "977" },
            { "label": "(+31) Netherlands", "value": "31" },
            { "label": "(+599) Netherlands Antilles", "value": "599" },
            { "label": "(+687) New Caledonia", "value": "687" },
            { "label": "(+64) New Zealand", "value": "64" },
            { "label": "(+505) Nicaragua", "value": "505" },
            { "label": "(+227) Niger", "value": "227" },
            { "label": "(+234) Nigeria", "value": "234" },
            { "label": "(+683) Niue", "value": "683" },
            { "label": "(+672) Norfolk Island", "value": "672" },
            { "label": "(+850) North Korea", "value": "850" },
            { "label": "(+1670) Northern Mariana Islands", "value": "1670" },
            { "label": "(+47) Norway", "value": "47" },
            { "label": "(+968) Oman", "value": "968" },
            { "label": "(+92) Pakistan", "value": "92" },
            { "label": "(+680) Palau", "value": "680" },
            { "label": "(+970) Palestine", "value": "970" },
            { "label": "(+507) Panama", "value": "507" },
            { "label": "(+675) Papua New Guinea", "value": "675" },
            { "label": "(+595) Paraguay", "value": "595" },
            { "label": "(+51) Peru", "value": "51" },
            { "label": "(+63) Philippines", "value": "63" },
            { "label": "(+48) Poland", "value": "48" },
            { "label": "(+351) Portugal", "value": "351" },
            { "label": "(+1787) Puerto Rico", "value": "1787" },
            { "label": "(+974) Qatar", "value": "974" },
            { "label": "(+262) Reunion", "value": "262" },
            { "label": "(+40) Romania", "value": "40" },
            { "label": "(+7) Russia", "value": "7" },
            { "label": "(+250) Rwanda", "value": "250" },
            { "label": "(+290) Saint Helena", "value": "290" },
            { "label": "(+1869) Saint Kitts and Nevis", "value": "1869" },
            { "label": "(+1758) Saint Lucia", "value": "1758" },
            { "label": "(+590) Saint Martin", "value": "590" },
            { "label": "(+508) Saint Pierre and Miquelon", "value": "508" },
            { "label": "(+1784) Saint Vincent and the Grenadines", "value": "1784" },
            { "label": "(+685) Samoa", "value": "685" },
            { "label": "(+378) San Marino", "value": "378" },
            { "label": "(+966) Saudi Arabia", "value": "966" },
            { "label": "(+221) Senegal", "value": "221" },
            { "label": "(+381) Serbia", "value": "381" },
            { "label": "(+248) Seychelles", "value": "248" },
            { "label": "(+232) Sierra Leone", "value": "232" },
            { "label": "(+65) Singapore", "value": "65" },
            { "label": "(+421) Slovakia", "value": "421" },
            { "label": "(+386) Slovenia", "value": "386" },
            { "label": "(+677) Solomon Islands", "value": "677" },
            { "label": "(+252) Somalia", "value": "252" },
            { "label": "(+27) South Africa", "value": "27" },
            { "label": "(+82) South Korea", "value": "82" },
            { "label": "(+211) South Sudan", "value": "211" },
            { "label": "(+34) Spain", "value": "34" },
            { "label": "(+94) Sri Lanka", "value": "94" },
            { "label": "(+249) Sudan", "value": "249" },
            { "label": "(+597) Suriname", "value": "597" },
            { "label": "(+47) Svalbard and Jan Mayen", "value": "47" },
            { "label": "(+268) Swaziland", "value": "268" },
            { "label": "(+46) Sweden", "value": "46" },
            { "label": "(+41) Switzerland", "value": "41" },
            { "label": "(+963) Syria", "value": "963" },
            { "label": "(+886) Taiwan", "value": "886" },
            { "label": "(+992) Tajikistan", "value": "992" },
            { "label": "(+255) Tanzania", "value": "255" },
            { "label": "(+66) Thailand", "value": "66" },
            { "label": "(+670) Timor-Leste", "value": "670" },
            { "label": "(+228) Togo", "value": "228" },
            { "label": "(+690) Tokelau", "value": "690" },
            { "label": "(+676) Tonga", "value": "676" },
            { "label": "(+1868) Trinidad and Tobago", "value": "1868" },
            { "label": "(+216) Tunisia", "value": "216" },
            { "label": "(+90) Turkey", "value": "90" },
            { "label": "(+993) Turkmenistan", "value": "993" },
            { "label": "(+1649) Turks and Caicos Islands", "value": "1649" },
            { "label": "(+688) Tuvalu", "value": "688" },
            { "label": "(+1340) U.S. Virgin Islands", "value": "1340" },
            { "label": "(+256) Uganda", "value": "256" },
            { "label": "(+380) Ukraine", "value": "380" },
            { "label": "(+971) United Arab Emirates", "value": "971" },
            { "label": "(+44) United Kingdom", "value": "44" },
            { "label": "(+1) United States", "value": "1" },
            { "label": "(+598) Uruguay", "value": "598" },
            { "label": "(+998) Uzbekistan", "value": "998" },
            { "label": "(+678) Vanuatu", "value": "678" },
            { "label": "(+379) Vatican City", "value": "379" },
            { "label": "(+58) Venezuela", "value": "58" },
            { "label": "(+84) Vietnam", "value": "84" },
            { "label": "(+681) Wallis and Futuna", "value": "681" },
            { "label": "(+212) Western Sahara", "value": "212" },
            { "label": "(+967) Yemen", "value": "967" },
            { "label": "(+260) Zambia", "value": "260" },
            { "label": "(+263) Zimbabwe", "value": "263" }
            // Add more countries as needed
        ]
    }

    get LanguageOptions() {
        return [
            { label: 'Afrikaans', value: 'af' },
            { label: 'Albanian', value: 'sq' },
            { label: 'Arabic', value: 'ar' },
            {label: 'Azerbaijani', value: 'az'},
            {label: 'Bengali', value: 'bn'},
            {label: 'Bulgarian', value: 'bg'},
            {label: 'Catalan', value: 'ca'},
            {label: 'Chinese (CHN)', value: 'zh_CN'},
            {label: 'Chinese (HKG)', value: 'zh_HK'},
            {label: 'Chinese (TAI)', value: 'zh_TW'},
            {label: 'Croatian', value: 'hr'},
            {label: 'Czech', value: 'cs'},
            {label:'Danish', value: 'da' },
            {label:'Dutch', value:'nl'},
            {label: 'English', value: 'en'},
            {label: 'English(UK)', value: ' en_GB'},
            {label:' English (US)', value:'en_US'},
            {label: 'Estonian', value:'et'},
            {label:'Filipino', value:'fil'},
            {label: 'Finnish', value:'fi'},
            {label: 'French', value: 'fr'},
            {label: 'Georgian', value:'ka'},
            {label: 'German', value: 'de'},
            {label: 'Greek', value: 'el'},
            {label: 'Gujarati', value:'gu'},
            {label: 'Hausa', value: 'ha'},
            {label:'Hebrew', value:'he'},
            {label: 'Hindi', value:'hi'},
            {label:'Hungarian', value: 'hu'},
            {label: 'Indonesian', value:'id'},
            {label: 'Irish', value: 'ga'},
            {label: 'Italian', value: 'it'},
            {label:'Japanese', value: 'ja'},
            {label: 'Kannada', value: 'kn'},
            {label:'Kazakh', value: 'kk'},
            {label: 'Kinyarwanda', value: 'rw_RW'},
            {label:'Korean', value:'ko'},
            {label: 'Kyrgyz (Kyrgyzstan)', value: 'ky_KG'},
            {label: 'Lao', value:'lo'},
            {label: 'latvian', value: 'lv'},
            {label: 'Lithuanian', value: 'lt'},
            {label:'Macedonian', value:'mk'},
            {label:'Malay', value:'ms'},
            {label:'Malayalam', value:'ml'},
            {label:'Marathi', value:'mr'},
            {label:'Norwegian', value:'nb'},
            {label:'Persian', value:'fa'},
            {label:'Polish', value:'pl'},
            {label:'Portuguese (BR)', value:'pt_BR'},
            {label:'Portuguese (POR)', value:'pt_PT'},
            {label:'Punjabi', value:'pa'},
            {label:'Romanian', value:'ro'},
            {label:'Russian', value:'ru'},
            {label:'Serbian', value:'sr'},
            {label:'Slovak', value:'sk'},
            {label:'Slovenian', value:'sl'},
            {label:'Spanish', value:'es'},
            {label:'Spanish (ARG)', value:'es_AR'},
            {label:'Spanish (SPA)', value:'es_ES'},
            {label:'Spanish (MEX)', value:' es_MX'},
            {label:'Swahili', value:'sw'},
            {label:'Swedish', value:'sv'},
            {label:'Tamil', value:'ta'},
            {label:'Telugu', value:'te'},
            {label:'Thai', value:'th'},
            {label:'Turkish', value:'tr'},
            {label:'Ukrainian', value:'uk'},
            {label: 'Urdu', value: 'ur'},
            {label:'Uzbek', value: 'uz'},
            {label: 'Vietnamese', value: 'vi'},
            {label: 'Zulu', value: 'zu'}
        ];
    } 
 

    
/*
get ProjectOptions() {
        return [
            { label: 'MyFairSKY', value: 'MyFairSKY' },
            { label: 'SkyLine', value: 'SkyLine' },
            { label: 'Cullinan', value: 'Cullinan' }
        ];
    }
    */

    get CategoryOptions() {
        return [
            { label: 'UTILITY', value: 'UTILITY' },
            { label: 'MARKETING', value: 'MARKETING' },
            { label: 'AUTHENTICATION', value: 'AUTHENTICATION' }
        ];
    }

    
    

    mappingGenericChange(event){
        let index = event.target.dataset.index;
        let fieldName = event.target.name;
        let fieldValue = event.target.value;
        
        if(fieldName == 'fieldName')
        {
            this.lstMapping[index].fieldName = fieldValue;
        }
        else if(fieldName == 'parameterNum')
        {
            this.lstMapping[index].parameterNum = fieldValue;
        }
        else if (fieldName == 'exampleText'){
            this.lstMapping[index].exampleText = fieldValue;
        }
    }

    handleTemplateCreate() {
        this.isShowPopup = true;
    }
    hidePopup() {
        this.resetDetails();
        this.isShowPopup = false;
        this.isNextModal = false;
        
    }

    handleTemplateNameChange(event) {
        this.templateName = event.target.value;
    }
    handleTemplateLanguageChange(event) {
        this.templateLanguage = event.target.value;
    }
    handleSelectChange(event) {
        this.category = event.target.value;
        if (this.category == 'AUTHENTICATION') {
            this.isCategoryNotAuth = false;
        }
        else {
            this.isCategoryNotAuth = true;
        }

    }
    handleBodyTextChange(event) {
        this.bodyText = event.target.value;
    }
    handleHeaderTextChange(event) {
        this.headerText = event.target.value;
    }
    handleFooterTextChange(event) {
        this.footerText = event.target.value;
    }

    
    get button_options() {
        if (this.category == 'MARKETING') {
            return [
                { label: 'call to action', value: 'call to action' },
                { label: 'fast reply', value: 'QUICK_REPLY' },
                { label: 'Marketing opt-out', value: 'marketing' }
            ];
        }
        else {
            return [
                { label: 'call to action', value: 'call to action' },
                { label: 'fast reply', value: 'QUICK_REPLY' }
            ];

        }
    }

    get actionTypeOptions() {

        return [
            { label: 'Call phone number', value: 'PHONE_NUMBER' },
            { label: 'Visit website', value: 'URL' }
        ];
    }

    get typeOptions() {

        return [
            { label: 'Custom', value: 'Custom' }
           
        ];
    }

    get URLoptions() {
        return [
            { label: 'static', value: 'static' }
            /*{ label: 'dynamic', value: 'dynamic' }*/
        ];
    }

    handleButtonChange(event) {
        this.button_value = event.detail.value;
        if (this.button_value === 'QUICK_REPLY') {
            this.callToAction = false;
            this.fastReply = true;
            this.isButton_marketing_optin = false;
            this.buttonTextInput = '';
            this.footerText = '';
        }
        if (this.button_value === 'call to action') {
            this.fastReply = false;
            this.callToAction = true;
            this.isButton_marketing_optin = false;
            this.buttonTextInput = '';
            this.footerText = '';
        }
        if (this.button_value === 'marketing') {
            this.fastReply = false;
            this.callToAction = false;
            this.isButton_marketing_optin = true;
            this.buttonTextInput = 'Stop promotions';
            this.footerText = 'Not interested? Tap Stop promotions'
            this.buttonTextCharacterCount = this.buttonTextInput.length;
            // this.button_value = 'QUICK_REPLY';
        }

    }

    /*handleNext(){
        this.isEdit = false;

        if (this.button_value === 'marketing') {
            this.button_value = 'QUICK_REPLY';
        }

        const allValid = [
            ...this.template.querySelectorAll('lightning-input'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);

        if (allValid) {
            this.isNextModal = true;
            this.isShowPopup = false;
        }
    }*/

    handleActionTypeChange(event) {
        this.actionType = event.detail.value;
        this.phone_website = '';
        this.phoneWebsiteCount = 0;
        this.buttonTextInput = '';
        this.buttonTextCharacterCount = 0;
        if (this.actionType === 'URL') {
            this.website = true;
        }
        else {
            this.website = false;
        }
    }

    handleCountryCode(event) {
        this.countryCode = event.target.value;
    }
    handleURLChange(event) {
        this.URLvalue = event.detail.value;
    }

    handleButtonTextInputChange(event) {
        this.buttonTextInput = event.target.value;
        this.buttonTextCharacterCount = this.buttonTextInput.length;
    }

    handlePhoneOrWebsiteChange(event) {
        this.phone_website = event.target.value;
        this.phoneWebsiteCount = this.phone_website.length;
    }


    
    get codeDeliveryOptions() {
        return [
            { label: 'Copy code', value: 'copyCode' },
            { label: 'Autofill', value: 'autofill' },
        ];
    }
    codeDelivery_radioGroupChange(event) {
        this.codeDeliveryOptionValue = event.detail.value;
        // console.log(this.codeDeliveryOptionValue);
        if (this.codeDeliveryOptionValue == 'autofill') {
            this.isAutofill = true;
            this.autofillInputValue = 'Autofill';
            this.copycodeInputValue = 'Copy code';
            this.otpType = 'ONE_TAP';
        }
        else {
            this.otpType = 'COPY_CODE';
            this.isAutofill = false;
        }
    }
    @track mesaageOptionsValue = [];
    get messageOptions() {
        return [
            { label: 'Add security recommendation', value: 'securityRecom' },
            { label: 'Add expiration time for the code', value: 'expirationTime' },
        ];
    }
    get selectedValues() {
        return this.value.join(',');
    }
    
    handleMessageContentChange(event) {
        this.mesaageOptionsValue = event.detail.value;
        // console.log(JSON.stringify(this.mesaageOptionsValue));
        this.isExpirationTime = false;
        if (this.mesaageOptionsValue.includes('expirationTime')) {
            this.isExpirationTime = true;
        }
        if (this.mesaageOptionsValue.includes('securityRecom')) {
            // this.isExpirationTime = false;

            this.addSecurityRecom = true;
        }
        // else {
        //     this.isExpirationTime = false;
        // }
    }
    handleButtonExpTimeChange(event) {
        this.expTimeValue = event.target.value;
    }
    handleButtonPackageNameChange(event) {
        this.packageNameInputValue = event.target.value;
    }
    handleButtonSignHashChange(event) {
        this.AppSignHashInputValue = event.target.value;
    }
    handleButtonCopycodeChange(event) {
        this.copycodeInputValue = event.target.value;
    }
    handleButtonAutofillChange(event) {
        this.autofillInputValue = event.target.value;
    }

    resetDetails(){
        this.headerText = '';
            this.bodyText = '';
            this.footerText = '';
            this.templateName = '';
            this.templateLanguage = '';
            this.category = '';
            this.isButton_marketing_optin = false;
            this.isCategoryNotAuth = true;
            this.website = false;
            this.fastReply = false;
            this.callToAction = false;
            this.button_value = '';
            this.buttonTextInput = '';
            this.phone_website = '';
            this.buttonTextCharacterCount = 0;
            this.phoneWebsiteCount = 0;
            this.actionType = '';
            this.URLvalue = 'static';
            this.countryCode = '';
            this.codeDeliveryOptionValue = '';
            this.isAutofill = false;
            this.autofillInputValue = '';
            this.copycodeInputValue = '';
            this.AppSignHashInputValue = '';
            this.packageNameInputValue = '';
            this.autofillInputValue = '';
            this.otpType = '';
            this.mesaageOptionsValue = [];
            this.expTimeValue = '';
            this.isExpirationTime = false;
            this.addSecurityRecom = '';
            this.isEdit = false;
            this.Templateid = '';
    }


    sfTemplateId = '';
    @track currentStep = "1";
    @track templateViewBody  = '';
    @track strDocPublicUrl = '';
    @track isPath1 = true;
    @track isPath2 = false;
    @track isPath3 = false;
    @track isPath4 = false;
    @track isPath5 = false;
    @track isPath6 = false;
    @track isMediaDoc = false;
    @track isMediaVideo = false;
    @track isMediaImage = false;
    @track showAddButton = false;
    @track isHeaderText = false;
    @track isHeaderMedia = false;
    @track showUploadFiles = false;
    @track showMapping = false;
    @track bodyLength = 1024;
    @track isUpdate = false;
    @track lstActions = [];
    @track listQuickReply = [];
    @track previewActionButtons = [];
    @track tempListMapping = [];


    @track objTemplate = {
        templateId : "",
        project :"",
        whatsAppTemplateId : "",
        headerType : "",
        headerText : "",
        documentId : "",
        mimeType : "",
        publicDocUrl : "",
        mediaHandler : "",
        contentVersionId : "",
        language : "en",
        templateName : "",
        templateBody : "",
        templateBodyText : "",
        footer : "",
        category : "",
        buttonOption : "",
        mediaType : "",
        fileName : "",
        objectName : undefined,
        isHeaderText : false,
        isHeaderMedia : false,
        isActionList : false,
        isQuickReplyList : false,
        listMapping : [],
        listQuickReply : [],
        listActions : []
    }


    get headerOptions() {
        return [
            { label: 'Text', value: 'TEXT' },
            { label: 'Media', value: 'MEDIA' },
        ];
    }
    @track _acceptedFormats  = '';
    get acceptedFormats() {
        console.log('this.acceptedFormats '+this._acceptedFormats );
        return this._acceptedFormats ;
    }


      handleFileSelect(event) {
        const selectedFileType = event.target.dataset.fileType; // Get the selected file type
        
        const fileInput = this.template.querySelector('input[type="file"]');
        const files = fileInput.files; // Get the selected files

        const filteredFiles = Array.from(files).filter(file => {
            return file.type.includes(selectedFileType);
        });

        console.log(filteredFiles); 
    }

    handleHeaderType(value){
        if(value == 'TEXT'){
            this.uploadError = false;
            this.isHeaderText = true;
            this.isHeaderMedia = false;
            this.isMediaImage = false;
            this.isMediaDoc = false;
            this.isMediaVideo = false;
            this.showUploadFiles = false;
            if (this.objTemplate.documentId && this.objTemplate.documentId != "" ) {
                this.deleteUploadedDocument();
            }
            this.objTemplate.headerType = 'TEXT';
            this.objTemplate.mediaType = '';
            this.objTemplate.documentId = "";
            this.objTemplate.contentVersionId = "";
            this.objTemplate.fileName = "";
            this.videoClass = 'width: 200px; height : 100px; border-radius: 5px; cursor: pointer;';
            this.imageClass = 'width: 200px; height : 100px; border-radius: 5px; cursor: pointer;';
            this.docClass = 'width: 200px; height : 100px; border-radius: 5px; cursor: pointer;';
        }else if(value == 'MEDIA'){
            this.isHeaderText = false;
            this.isHeaderMedia = true ;
            this.objTemplate.headerText     = "";   
            this.objTemplate.headerType     = "MEDIA";
            if(this.objTemplate.mediaType == 'VIDEO'){
                this.divVideoClick();
            }else if(this.objTemplate.mediaType == 'DOCUMENT'){
                this.divDocClick();
            }else{
                this.divImageClick();
            }
        }else{
            this.isHeaderText = false;
            this.isHeaderMedia = true ;
            this.objTemplate.headerText = "";
        }
    }

    deleteUploadedDocument(){
        this.isLoading = true;
        deleteUploadedDocument({documentId : this.objTemplate.documentId})
        .then(result => {
            this.isLoading = false;
            console.log('result-=----'+result);
            /*if(result){
            }*/
        })
        .catch(error => {
            this.isLoading = false;
            this.handleError(error);
        });
    }

    newGenericHandler(event){
        let fieldName = event.target.name;
        let fieldValue = event.target.value;

         switch (fieldName) {
            case "headerType":
                this.objTemplate.headerType = fieldValue;
                this.handleHeaderType(fieldValue);
                
                break;

            case "language":
                this.objTemplate.language = fieldValue;
                break;
                
            case "project":
               this.objTemplate.project =fieldValue;
               break;

            case "templateName":
                this.objTemplate.templateName = fieldValue;
                break;

            case "templateBody":
                this.bodyLength = 1024 - event.detail.value.length;
                if(this.bodyLength <= 0){
                    //this.objTemplate.templateBody = this.objTemplate.templateBody.slice(0, 1024);
                    this.showToast('Error!', 'Template body cannot accept more than 1024 words!', 'error');
                }
                this.objTemplate.templateBody = event.detail.value;
                this.objTemplate.templateBodyText = event.detail.value;
                console.log(event.detail.value);
                this.processBody(event.detail.value);
                if(event.detail.value)
                    this.bodyLength = 1024 - event.detail.value.length;
                else
                    this.bodyLength = 1024;
                
                if(this.bodyLength > 1024){
                    this.objTemplate.templateBody = this.objTemplate.templateBody.slice(0, 1024);
                }
                break;

            case "footer":
                this.objTemplate.footer = fieldValue;
                break;

            case "category":    
                this.objTemplate.category = fieldValue;
                break;

            case "headerText":    
                this.objTemplate.headerText = fieldValue;
                break;
                
            case "buttonOption":
                this.objTemplate.buttonOption = fieldValue;
                this.listQuickReply = [];
                this.lstActions = [];
                this.isActionList = false;
                this.isQuickReplyList = false;
                this.processActions();
                this.showAddButton = true;
                break;
        
        
            default:
                break;
        }
    }

    
    @track isActionList = false;
    @track isQuickReplyList = false;
    processActions(){
        if(this.objTemplate.buttonOption == 'call to action'){
            this.isActionList = true;
            if(this.lstActions.length < 2){
                let objAction = {
                    buttonId : "",
                    typeOfAction : "",
                    buttonText : "",
                    countryCode : "",
                    phoneNumber : "",
                    urlType : "",
                    websiteUrl : "",
                    isIcon : true,
                    iconName : "",
                    type : "",
                    isActionPhoneNumber : true,
                    isActionUrl : false,
                }
                this.lstActions.push(objAction);
                if(this.lstActions.length == 2 ){
                    this.showAddButton = false;
                }
            }
        }
        else if(this.objTemplate.buttonOption == 'QUICK_REPLY'){
            this.isQuickReplyList = true;
            if(this.listQuickReply.length < 2){
                let objAction = {
                    buttonId : "",
                    isIcon : false,
                    buttonText : "",
                    type : "Custom",
                }
                this.listQuickReply.push(objAction);
                if(this.listQuickReply.length == 2 ){
                    this.showAddButton = false;
                }
            }
        }
        console.log(JSON.stringify(this.listQuickReply));
        console.log(JSON.stringify(this.lstActions));
    }


    @track marketingClass = 'cursor: pointer; border-radius: 5px';
    divClick(event){
         console.log(event); // using 'event' avoids the lint warning
        this.marketingClass = 'cursor: pointer; border-radius: 5px;background-color:#bceae7;';
        this.utilityClass = 'cursor: pointer; border-radius: 5px';
        this.authClass = 'cursor: pointer; border-radius: 5px';
        this.objTemplate.category = 'MARKETING';
       
    }

    @track utilityClass = 'cursor: pointer; border-radius: 5px';
    divUtilityClick(event){
         console.log(event); // using 'event' avoids the lint warning
        this.utilityClass = 'cursor: pointer; border-radius: 5px;background-color:#bceae7;';
        this.marketingClass = 'cursor: pointer; border-radius: 5px';
        this.authClass = 'cursor: pointer; border-radius: 5px';
        this.objTemplate.category = 'UTILITY';
        
    }

    @track authClass = 'cursor: pointer; border-radius: 5px';
    divAuthClick(event){
         console.log(event); // using 'event' avoids the lint warning
        this.authClass = 'cursor: pointer; border-radius: 5px;background-color:#bceae7;';
        this.utilityClass = 'cursor: pointer; border-radius: 5px';
        this.marketingClass = 'cursor: pointer; border-radius: 5px';
        this.objTemplate.category = 'AUTHENTICATION';
        
        console.log('-----AUTHENTICATION----');
    }



    
    @track videoClass = 'width: 200px; height : 100px; border-radius: 5px; cursor: pointer;';
    divVideoClick(event){
         console.log(event); // using 'event' avoids the lint warning
        this.videoClass = 'width: 200px; height : 100px; border-radius: 5px; cursor: pointer;  background-color:#bceae7;';
        this.imageClass = 'width: 200px; height : 100px; border-radius: 5px; cursor: pointer;';
        this.docClass = 'width: 200px; height : 100px; border-radius: 5px; cursor: pointer;';
        this.objTemplate.mediaType = 'VIDEO';
        this.isMediaImage = false;
        this.isMediaVideo = true;
        this.isMediaDoc = false;
        this.showUploadFiles = true;
        this._acceptedFormats ='.mp4';

        

    }

    @track imageClass = 'width: 200px; height : 100px; border-radius: 5px; cursor: pointer;';
    divImageClick(event){
         console.log(event); // using 'event' avoids the lint warning
        this.imageClass = 'width: 200px; height : 100px; border-radius: 5px; cursor: pointer;  background-color:#bceae7;';
        this.videoClass = 'width: 200px; height : 100px; border-radius: 5px; cursor: pointer;';
        this.docClass = 'width: 200px; height : 100px; border-radius: 5px; cursor: pointer;';
        this.objTemplate.mediaType = 'IMAGE';
        this.isMediaImage = true;
        this.isMediaVideo = false;
        this.isMediaDoc = false;
        this.showUploadFiles = true;
        this._acceptedFormats ='.png','.jpg','.jpeg';
        console.log('this.acceptedFormat:- '+this.acceptedFormat);

    }

    @track docClass = 'width: 200px; height : 100px; border-radius: 5px; cursor: pointer;';
    divDocClick(event){
         console.log(event); // using 'event' avoids the lint warning
        this.docClass = 'width: 200px; height : 100px; border-radius: 5px; cursor: pointer;  background-color:#bceae7;';
        this.imageClass = 'width: 200px; height : 100px; border-radius: 5px; cursor: pointer;';
        this.videoClass = 'width: 200px; height : 100px; border-radius: 5px; cursor: pointer;';
        this.objTemplate.mediaType = 'DOCUMENT';
        this.isMediaImage = false;
        this.isMediaVideo = false;
        this.isMediaDoc = true;
        this.showUploadFiles = true;
        this._acceptedFormats ='.pdf,.doc,.docx';


    }



    handleObjectFields(objectName){
        this.isLoading = true;
        objectFields({sObjectName: objectName})
        .then((result)=>{
            console.log('resultFields==='+result);
            this.fieldNameOptions = JSON.parse(result).lstObjectPicklist;
            this.isLoading = false;
            
        }).catch((error) => {
            console.log('Error: ', JSON.stringify(error));
            this.isLoading = false;
            this.handleError(error);
        });
    }

    

    selectedObjectHandler(event){
        this.objTemplate.objectName = event.target.value;
        this.handleObjectFields(this.objTemplate.objectName);
    }

    buttonHandler(event){
        let fieldName = event.target.name;
        let fieldValue = event.target.value;
        let index = event.target.dataset.index;
        console.log('Field Value ' +fieldValue);
         switch (fieldName) {
            case "actionType":
                this.lstActions[index].actionType = fieldValue;
                if(fieldValue == 'PHONE_NUMBER'){
                    this.lstActions[index].isActionPhoneNumber = true;
                    this.lstActions[index].isActionUrl = false;
                    this.lstActions[index].iconName = 'utility:call';
                }else{
                    this.lstActions[index].isActionPhoneNumber = false;
                    this.lstActions[index].isActionUrl = true;
                    this.lstActions[index].iconName = 'utility:new_window';
                }
                break;

            case "countryCode":
                this.lstActions[index].countryCode = fieldValue;
                break;

            case "buttonText":
                this.lstActions[index].buttonText = fieldValue;
                break;

            case "phoneNumber":
                this.lstActions[index].phoneNumber = fieldValue;
                break;

            case "websiteUrl":
                this.lstActions[index].websiteUrl = fieldValue;
                break;

            case "urlType":
                this.lstActions[index].urlType = fieldValue;
                break;

            
            default:
                break;
        }
    }

    buttonReplyHandler(event){
        let fieldName = event.target.name;
        let fieldValue = event.target.value;
        let index = event.target.dataset.index;

         switch (fieldName) {
            

            case "buttonText":
                this.listQuickReply[index].buttonText = fieldValue;
                this.lstActions = [...this.lstActions];
                break;
            case "type":
                this.listQuickReply[index].type = fieldValue;
                this.lstActions = [...this.lstActions];
                break;
            case "countryCode":
                this.listQuickReply[index].countryCode = fieldValue;
                this.lstActions = [...this.lstActions];
                break;
            case "phoneNumber":
                this.listQuickReply[index].phoneNumber = fieldValue;
                this.lstActions = [...this.lstActions];
                break;
            default:
                break;
        }
    }

    uploadError = false;
    handleUploadFinished(event) {
        try {
            this.isLoading = true;
            const uploadedFiles = event.detail.files;
            console.log(uploadedFiles.length);
            //console.log(JSON.stringify(uploadedFiles));
            let file = uploadedFiles[0];
            if(file){
                this.objTemplate.documentId = file.documentId;
                this.objTemplate.contentVersionId = file.contentVersionId;
                this.objTemplate.fileName = file.name;
                this.objTemplate.mimeType = file.mimeType;
            }
            console.log(JSON.stringify(file));

            verifyUpload({contentVersionId : this.objTemplate.contentVersionId})
            .then(result => {
                this.isLoading = false;
                console.log('result-=----'+result);
                if(!result){
                    this.showToast('Error!', 'You cannot upload a file with size more than 4.3MB', 'error' );
                    this.uploadError = true;
                    this.objTemplate.documentId = '';
                    this.objTemplate.contentVersionId = '';
                    this.objTemplate.fileName = '';
                    this.objTemplate.mimeType = '';
                }else{
                    this.uploadError = false;
                }
            })
            .catch(error => {
                this.uploadError = true;
                this.isLoading = false;
                this.handleError(error);
            });
            
        } catch (error) {
            console.log(error);
        }
        
    }

    handleCancel(){
        this.isShowPopup = false;
        setTimeout(() => {
            let sfdcBaseURL = window.location.origin + '/lightning/n/CCCWA__WA_Templates';
            window.open(sfdcBaseURL, "_self");
        }, 500); 
    }

    handleNext(){
        if(this.validateData(this.currentStep)){
            switch (this.currentStep) {
                case "1":
                    this.currentStep = "2";
                    this.isPath1 = false;
                    this.isPath2 = true;
                    this.isPath3 = false;
                    this.isPath4 = false;
                    this.isPath5 = false;
                    this.isPath6 = false;
                    break;

                case "2":
                    this.currentStep = "3";
                    this.isPath1 = false;
                    this.isPath2 = false;
                    this.isPath3 = true;
                    this.isPath4 = false;
                    this.isPath5 = false;
                    this.isPath6 = false;
                    break;

                case "3":
                    this.currentStep = "4";
                    this.isPath1 = false;
                    this.isPath2 = false;
                    this.isPath3 = false;
                    this.isPath4 = true;
                    this.isPath5 = false;
                    this.isPath6 = false;
                    break;

                case "4":
                    this.currentStep = "5";
                    this.isPath1 = false;
                    this.isPath2 = false;
                    this.isPath3 = false;
                    this.isPath4 = false;
                    this.isPath5 = true;
                    this.isPath6 = false;
                    break;

                case "5":
                    this.currentStep = "6";
                    this.isPath1 = false;
                    this.isPath2 = false;
                    this.isPath3 = false;
                    this.isPath4 = false;
                    this.isPath5 = false;
                    this.isPath6 = true;
                    this.buildPreview();
                    break;

                default:
                    break;
            }
        }
    }


    handleBack(){
        switch (this.currentStep) {
                case "2":
                    this.currentStep = "1";
                    this.isPath1 = true;
                    this.isPath2 = false;
                    this.isPath3 = false;
                    this.isPath4 = false;
                    this.isPath5 = false;
                    this.isPath6 = false;
                    break;

                case "3":
                    this.currentStep = "2";
                    this.isPath1 = false;
                    this.isPath2 = true;
                    this.isPath3 = false;
                    this.isPath4 = false;
                    this.isPath5 = false;
                    this.isPath6 = false;
                    break;

                case "4":
                    this.currentStep = "3";
                    this.isPath1 = false;
                    this.isPath2 = false;
                    this.isPath3 = true;
                    this.isPath4 = false;
                    this.isPath5 = false;
                    this.isPath6 = false;
                    break;

                case "5":
                    this.currentStep = "4";
                    this.isPath1 = false;
                    this.isPath2 = false;
                    this.isPath3 = false;
                    this.isPath4 = true;
                    this.isPath5 = false;
                    this.isPath6 = false;
                    break;

                case "6":
                    this.currentStep = "5";
                    this.isPath1 = false;
                    this.isPath2 = false;
                    this.isPath3 = false;
                    this.isPath4 = false;
                    this.isPath5 = true;
                    this.isPath6 = false;
                    break;

                default:
                    break;
            }
    }

    addMappingParam(){
        if(this.validateData("4")){
            let body = this.objTemplate.templateBody;
            const placeholderRegex = /\{\{(\d+)\}\}/g;
            const placeholders = Array.from(body.matchAll(placeholderRegex));
            if(placeholders != undefined && placeholders != null && placeholders.length > 0){
                let lastParam = placeholders[placeholders.length -1][1];
                let lastParamNumber = Number(lastParam) +1;
                body = body.concat('{{'+String(lastParamNumber) + '}}')
            }else{
                body = body + ' {{1}} ';
            }
            console.log('body-----------   '+body);
            this.objTemplate.templateBody = body;
            this.processBody(body);
        }
    }


    replacePlaceholders(text, replacements) {
        return text.replace(/\{\{(\d+)\}\}/g, (match, index) => {
            const replacement = replacements[Number(index) - 1];
            return replacement !== undefined ? replacement : match;
        });
    }


   

    processBody(body){
        const myString = body;
        const placeholderRegex = /\{\{(\d+)\}\}/g;
        const placeholders = Array.from(myString.matchAll(placeholderRegex));
        console.log('placeholders--- '+JSON.stringify(placeholders));
        console.log('tempListMapping--- '+JSON.stringify(this.tempListMapping));
        this.showMapping = false;
        if(placeholders != null && placeholders != undefined && placeholders.length > 0){
            this.showMapping = true;
            let placeholdersLength =  placeholders.length;
            let tempListMappinglength = 0; // what was the length
            if(this.tempListMapping != null && this.tempListMapping != undefined && this.tempListMapping.length > 0){
                tempListMappinglength = this.tempListMapping.length;
            }
            if(placeholdersLength == tempListMappinglength){
                for (let index = 0; index < placeholders.length; index++) {
                    this.tempListMapping[index].placeHolder = placeholders[index][0];
                    this.tempListMapping[index].parameterNum = placeholders[index][1];
                    this.tempListMapping[index].objectName = this.objTemplate.objectName;
                }
                this.lstMapping = this.tempListMapping;
            }
            if(placeholdersLength > tempListMappinglength){
                for (let index = 0; index < this.tempListMapping.length; index++) {
                    this.tempListMapping[index].placeHolder = placeholders[index][0];
                    this.tempListMapping[index].parameterNum = placeholders[index][1];
                    this.tempListMapping[index].objectName = this.objTemplate.objectName;
                }
                this.lstMapping = this.tempListMapping;
                const secondPart = placeholders.slice(tempListMappinglength );
                console.log('secondPart--- '+JSON.stringify(secondPart));
                secondPart.forEach((match) => {
                    const placeholderNumber = match[1];
                    let placeHolder ='{{'+placeholderNumber+'}}';
                    let objMapping =
                    {
                        fieldName : "",
                        parameterNum : placeholderNumber,
                        exampleText : "",
                        mappingId : "",
                        placeHolder : placeHolder,
                        objectName : this.objTemplate.objectName,
                    };
                    this.lstMapping.push(objMapping);
                });
                this.tempListMapping = this.lstMapping;
            }
            if(placeholdersLength < tempListMappinglength){
                for (let index = 0; index < placeholders.length; index++) {
                    this.tempListMapping[index].placeHolder = placeholders[index][0];
                    this.tempListMapping[index].parameterNum = placeholders[index][1];
                    this.tempListMapping[index].objectName = this.objTemplate.objectName;
                }
                const firstPart = this.tempListMapping.slice(0, placeholdersLength);
                console.log(firstPart.length);
                this.lstMapping = firstPart;
            }
        }
        console.log('this.lstMapping--- '+JSON.stringify(this.lstMapping));
    }

    buildPreview(){
        console.log('this.objTemplate-- '+ JSON.stringify(this.objTemplate));
        let header = '';
        if(this.isHeaderText){
            header = '<div style="text-align:center"><b>'+ this.objTemplate.headerText + '</b></div><div style"style=" padding-left: 3px">' + this.objTemplate.templateBody+ '</div>';
        }else if(this.isHeaderMedia){
            if(this.isMediaImage)
                header = /*'<p><img src="'+this.strDocPublicUrl+'"  width="250" height="250"></p>' + */this.objTemplate.templateBody;
            else
                header = this.objTemplate.templateBody;
            
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
            for(let i=0; i < this.lstMapping.length; i++){
                list.push(this.lstMapping[i].exampleText);
                // var expression = "^[" + this.lstMapping[i].placeHolder + "].*$";
                // const regex = new RegExp(expression, 'i'); ;
            }
            body = this.replacePlaceholders(body, list);
            this.templateViewBody = body;
        }
        
        if(this.isQuickReplyList){
            this.previewActionButtons = this.listQuickReply;
        }
        if(this.isActionList){
            this.previewActionButtons = this.lstActions;
        }
        
        console.log(JSON.stringify(this.previewActionButtons));

    }

    handleSave(){
        if(this.validateData(this.currentStep)){
           try{
               this.isLoading = true;
                this.objTemplate.isHeaderMedia = this.isHeaderMedia;
                this.objTemplate.isHeaderText = this.isHeaderText;
                this.objTemplate.isActionList = this.isActionList;
                this.objTemplate.isQuickReplyList = this.isQuickReplyList;
                if(this.isActionList){
                    this.objTemplate.listActions = this.lstActions;
                    this.objTemplate.listQuickReply = [];
                }
                if(this.isQuickReplyList){
                    this.objTemplate.listQuickReply  = this.listQuickReply;
                    this.objTemplate.listActions = [];
                }
                if(this.lstMapping && this.lstMapping.length >0)
                    this.objTemplate.listMapping = this.lstMapping;
                
                console.log('json body:: '+ JSON.stringify(this.objTemplate));
                saveTemplateData({jsonData : JSON.stringify(this.objTemplate)})
                .then(result => {
                    this.isLoading = false;
                    if(result){
                        this.objTemplate = JSON.parse(result);
                        this.strDocPublicUrl = this.objTemplate.publicDocUrl;
                        console.log(this.strDocPublicUrl);
                        console.log('this.objTemplate----- '+JSON.stringify(this.objTemplate));
                    }
                    this.currentStep = "6";
                    this.buildPreview();
                    this.isPath1 = false;
                    this.isPath2 = false;
                    this.isPath3 = false;
                    this.isPath4 = false;
                    this.isPath5 = false;
                    
                    this.isPath6 = true;
                    this.showToast('Alert!', 'Do you want to submit it? it will take upto 24hrs to be approved from Meta!', 'info' );
                    console.log('result== '+result);
                })
                .catch(error => {
                    this.isLoading = false;
                    this.handleError(error);
                    console.log(JSON.stringify(error));
                });
           }catch(error){
               console.log('error----'+error)
           }
        }
    }

    handleFinish(){
        this.isLoading = true; 
        try{
            sendWhatsAppTemplateToMeta({jsonObject : JSON.stringify(this.objTemplate)})
            .then(data => {
                console.log('data ' +JSON.stringify(this.objTemplate));
                this.isLoading = false;
                if(data){
                    let result = JSON.parse(data);
                    if(result.isSuccess == true){
                        //this.showToast('success', result.messgae, 'success', false);
                        setTimeout(() => {
                            let sfdcBaseURL = window.location.origin + '/lightning/n/CCCWA__WA_Templates';
                            window.open(sfdcBaseURL, "_self");
                        }, 500); 
                    }else{
                        this.showToast('error', result.message, 'error', false);
                    } 
                }
                console.log('result== '+data);
            })
            .catch(error => {
                this.isLoading = false;
                this.handleError(error);
                console.log(error);
            });
        }catch(error){
            this.isLoading = false;
            this.showToast('error', error, 'error', false);
        }
    }

    validateData(step){
        console.log(step);
        switch (step) {
            case "1":
                if(this.objTemplate.category != '' && this.objTemplate.category != null && this.objTemplate.category != undefined){
                    return true;
                }
                this.showToast('error', 'Please Select Category before moving forward', 'error', false);
                //this.showToast('Error!', 'Please Select Category before moving forward', 'error');
                return false;
                //break;

            case "2":
                console.log('Camehere');
               
                if(this.isInputValid('.validate-step2') && ((this.isHeaderText == false && this.isHeaderMedia == false) || ((this.isHeaderText == true && (this.objTemplate.headerText != '' && this.objTemplate.headerText != null && this.objTemplate.headerText != undefined) ) || (this.isHeaderMedia && (this.objTemplate.mediaType != '' && this.objTemplate.mediaType != null && this.objTemplate.mediaType != undefined) && (this.objTemplate.fileName != '' && this.objTemplate.fileName != null && this.objTemplate.fileName != undefined)))) && (this.uploadError == false)){
                    return true;
                }
                if(this.uploadError){
                    this.showToast('error', 'Please upload file in size limit!', 'error', false);
                    //this.showToast('Error!', 'Please upload file in size limit!', 'error');
                }else{
                    this.showToast('error', 'Please fill the remaining fields!', 'error', false);
                    //this.showToast('Error!', 'Please fill the remaining fields!', 'error');
                }
                return false;
                //break;

            case "3":
                console.log(this.isInputValid('.validate-step3'));
                console.log(this.objTemplate.objectName);
                if(this.isInputValid('.validate-step3')){
                    return true;
                }
                this.showToast('error', 'Please fill the remaining fields!', 'error', false);
                //this.showToast('Error!', 'Please fill the remaining fields!', 'error');
                return false;
                //break;

            case "4":
                if(this.bodyLength <= 0){
                    //this.objTemplate.templateBody = this.objTemplate.templateBody.slice(0, 1024);
                    this.showToast('error', 'Template body cannot accept more than 1024 words!', 'error', false);
                    //this.showToast('Error!', 'Template body cannot accept more than 1024 words!', 'error');
                    return false;
                }
                if(this.isInputValid('.validate-step4') &&  (this.objTemplate.templateBody != '' && this.objTemplate.templateBody != null && this.objTemplate.templateBody != undefined)){
                    return true;
                }
                if(!this.isInputValid('.validate-step4')){
                    this.showToast('error', 'Please fill parameters of the template!', 'error', false);
                    //this.showToast('Error!', 'Please fill parameters of the template!', 'error');
                    return false;
                }
                this.showToast('error', 'Please fill the body of the template!', 'error', false);
                //this.showToast('Error!', 'Please fill the body of the template!', 'error');
                return false;
                //break;

            case "5":
                if(this.isInputValid('.validate-step5')){
                    return true;
                }
                this.showToast('error', 'Please fill the remaining fields!', 'error', false);
               // this.showToast('Error!', 'Please fill the remaining fields!', 'error');
                return false;
                //break;

            default:
                break;
        }
    }

    showToast(title, message, variant){
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
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
            this.showToast('error', tempErrorList.join(', '), 'error', false);
            //this.toastEvent('Error!',  tempErrorList.join(', ') , 'error');
        }
        this.isLoading = false;
    }

    isInputValid(selector) {
        let isValid = true;
        let inputFields = this.template.querySelectorAll(selector);
        console.log(inputFields.length);
        // inputFields.push(this.template.querySelectorAll('lightning-combobox'));
        inputFields.forEach(inputField => {
          if (!inputField.checkValidity()) {
            inputField.reportValidity();
            isValid = false;
          }
        });
        return isValid;
    }

    clickOnMedia(){
        if(this.strDocPublicUrl)
            window.open(this.strDocPublicUrl);
    }

    showCustomToast(title, msg, typeOfToast, isSticky) {
        this.template.querySelector('c-custom-toast').showToast(title, msg, typeOfToast, isSticky);
    }

    testclick(){
        
        this.templateViewBody = '<p><img src="https://cloudcentric--ss.sandbox.file.force.com/sfc/dist/version/download/?oid=00DP00000044pg0&ids=068P0000001s3UR&d=%2Fa%2FP0000000949U%2F8hdQajddOAwwVMM78MT5Bgaxz3TRqk8RV16AUBB7yq8&asPdf=false"  width="1000" height="500"></p><p>Hello</p><p>I ma  ajsdjas</p><p class="slds-text-color_inverse-weak" style="font-size : 12px; padding-bottom: 10px"> Powered By CCC</p>';
        console.log(this.templateViewBody);
        this.currentStep = "6";
        this.isPath1 = false;
        this.isPath2 = false;
        this.isPath3 = false;
        this.isPath4 = false;
        this.isPath5 = false;
        this.isPath6 = true;
    }
}