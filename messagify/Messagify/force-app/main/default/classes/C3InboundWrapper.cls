/**
 * @class C3InboundWrapper
 * @description
 *  Wrapper class to represent the inbound payload structure for WhatsApp webhook messages.
 *  This structure maps to JSON received from WhatsApp Business API, including messages, statuses, contacts, and errors.
 *
 * @access Public
 * @usage Used to deserialize WhatsApp webhook payloads.
 * @author Asjad Ahmed
 * @version 1.0
 * @date June 2025 
 */
public class C3InboundWrapper {
     /** The main object type, e.g., 'whatsappbusinessaccount'. */
    public String obj; // whatsappbusinessaccount

    /** Array of entry objects in the webhook payload. */
    public ClsEntry[] entry;

    /**
     * @class ClsEntry
     * @description Represents each individual entry in the webhook event.
     */
    public class ClsEntry {
        public String id; // 108445142322979
        public ClsChanges[] changes;
    }
     /**
     * @class ClsChanges
     * @description Captures the changes related to messages or statuses in the event.
     */

    public class ClsChanges {
        public ClsValue value;
        public String field; // messages
    } 
    /**
     * @class ClsValue
     * @description The core structure of the payload including contacts, messages, metadata, and statuses.
     */

    public class ClsValue {
        public String messagingproduct; // whatsapp
        public ClsMetadata metadata;
        public ClsContacts[] contacts;
        public ClsMessages[] messages;
        
        public ClsStatuses[] statuses;
    }
     /**
     * @class ClsMetadata
     * @description Metadata for the WhatsApp business account.
     */

    public class ClsMetadata {
        public String displayphonenumber; // 917042912244
        public String phonenumberid; // 108193625692105
    }
    /**
     * @class ClsContacts
     * @description Contains sender contact details.
     */

    public class ClsContacts {
        public ClsProfile profile;
        public String waid; // 918802271489
    }
    /**
     * @class ClsProfile
     * @description User profile information for the contact.
     */

    public class ClsProfile {
        public String name; // Shivam
    }
    /**
     * @class ClsStatuses
     * @description Represents the delivery status of a WhatsApp message.
     */

    public class ClsStatuses {
        public String id; // wamid.HBg...
        public String status; // failed / delivered
        public String timestamp; // 1745992373
        public String recipientid; // 918449616698
        public ClsConversation conversation;
        public ClsPricing pricing;
        public ClsError[] errors; // NEW
    }
    /**
     * @class ClsConversation
     * @description Conversation context metadata.
     */

    public class ClsConversation {
        public String id;
        public ClsOrigin origin;
    }
     /**
     * @class ClsOrigin
     * @description Origin details for the conversation.
     */

    public class ClsOrigin {
        public String type; // marketing
    }
    /**
     * @class ClsPricing
     * @description Pricing details for the message.
     */

    public class ClsPricing {
        public Boolean billable;
        public String pricingmodel; // CBP
        public String category; // marketing
    }
     /**
     * @class ClsError
     * @description Represents an error returned in the statuses section.
     */

    public class ClsError { // NEW
        public Integer code;
        public String title;
        public String message;
        public ClsErrordata errordata;
        public String href;
    }
     /**
     * @class ClsErrordata
     * @description Additional details about an error.
     */

    public class ClsErrordata { // NEW
        public String details;
    }
    /**
     * @class ClsMessages
     * @description Represents a message sent or received, including various media types.
     */

    public class ClsMessages {
        public String fromNumber; // 918802271489
        public String id;
        public String timestamp;
        public ClsText text;
        public String type; // text
        public ClsImage image;
        public ClsDocument document;
        public ClsVideo video;
        public ClsAudio audio;
        public ClsButton button;
    }
    /**
     * @class ClsText
     * @description Represents a text message.
     */

    public class ClsText {
        public String body;
    }
    
       /**
     * @class ClsButton
     * @description Represents a button in a message.
     */

    public class ClsButton {
        public String payload;
        public String text;
    }
    /**
     * @class ClsDocument
     * @description Represents a document sent in a message.
     */

    public class ClsDocument {
        public String caption;
        public String filename;
        public String mimetype;
        public String sha256;
        public String id;
    }
    /**
     * @class ClsVideo
     * @description Represents a video message.
     */

    public class ClsVideo {
        public String caption;
        public String filename;
        public String mimetype;
        public String sha256;
        public String id;
    }
    /**
     * @class ClsImage
     * @description Represents an image sent in a message.
     */

    public class ClsImage {
        public String caption;
        public String mimetype;
        public String sha256;
        public String id;
    }
     /**
     * @class ClsAudio
     * @description Represents an audio file sent in a message.
     */

    public class ClsAudio {
        public String mimetype;
        public String id;
    }
}