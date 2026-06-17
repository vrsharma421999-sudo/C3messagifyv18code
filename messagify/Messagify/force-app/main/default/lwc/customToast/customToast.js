/**
 * @module customToast.js
 * @author Sri Ram Kumar
 * @date 25-10-2022
 * @extends LightningElement
 * @description This component is used to show a toast message on the screen.
 * @example
 * In HTML:- <c-custom-toast duration="3000"></c-custom-toast>
 *  Method In Js:- showToast(title, msg, typeOfToast, isSticky) {
        this.template.querySelector('c-custom-toast').showToast(title, msg, typeOfToast, isSticky);
    }
 * Call the above method in other method to fire the showToast example.
 * this.showToast('error', 'Have received some error.', 'error', true);
 * this.showToast('Success', 'Record saved successfully.', 'success', false);
 */
    import { LightningElement, api, track } from 'lwc';

    export default class CustomToast extends LightningElement {
        @track title = '';
        @track message = '';
        variant = '';
        @api duration = '';
        @track showToastBar = false;
        autoCloseTime = 3000;
    
        /**
         * This function takes in a title, message, variant, and mode. If the mode is false, the toast will
         * close after the duration
         * @param title{String} - The title of the toast
         * @param message{string} - The message you want to display in the toast.
         * @param {string}variant - This is the type of toast you want to show. It can be 'success', 'error',
         * 'warning', 'info'.
         * @param mode{boolean} - If you want to show the toast bar for a long time, you can set this to
         * true.
         */
        @api showToast(title, message, variant, mode) {
            try {
                this.title = title;
                this.message = message;
                this.variant = variant;
                if (this.duration) {
                    this.autoCloseTime = this.duration;
                }
                this.showToastBar = true;
                if (mode == false) {
                    setTimeout(() => {
                        this.close();
                    }, this.autoCloseTime);
                }
            } catch (error) {
                console.log('toast error');
            }
        }
    
        /**
         * The close() function sets the showToastBar property to false, which hides the toast bar
         */
        close() {
            this.showToastBar = false;
            this.title = '';
            this.message = '';
            this.messageType = '';
            this.variant = '';
        }
    
        /**
         * It returns the icon name based on the variant.
         * @returns The icon name for the variant.
         */
        get iconName() {
            let icon = '';
            switch (this.variant) {
                case 'error':
                    icon = 'utility:error';
                    break;
                case 'warning':
                    icon = 'utility:warning';
                    break;
                case 'success':
                    icon = 'utility:success';
                    break;
                case 'info':
                    icon = 'utility:info';
                    break;
                default:
                    break;
            }
            return icon;
        }
    
        /**
         * If the variant is 'success', then return 'slds-icon_container slds-m-right_small slds-no-flex
         * slds-align-top  slds-icon-utility-success'
         * @returns The value of the iconClass property.
         */
        get iconClass() {
            return 'slds-icon_container slds-m-right_small slds-no-flex slds-align-top  slds-icon-utility-' + this.variant;
        }
    
        get themeClass() {
            return 'slds-notify slds-notify_toast slds-theme_' + this.variant;
        }
    }