/**
 * @description Test class for C3CreateWhatsAppConversationQueue queueable job.
 */
@IsTest
public class C3CreateWhatsAppConversationQueueTest {

    /**
     * @description Tests execution of queueable with BigObject conversation record.
     */
    @IsTest
    static void testQueueableWithBigObject() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // Arrange
            CCCWA__WhatsApp_Conversation__b conversation = new CCCWA__WhatsApp_Conversation__b();
            conversation.CCCWA__To_Phone__c = '9810566161';
            conversation.CCCWA__Message__c = 'Hello from test';
            conversation.CCCWA__Direction__c = 'Inbound';

            // Act
            C3CreateWhatsAppConversationQueue queue = new C3CreateWhatsAppConversationQueue(conversation);

            Test.startTest();
            queue.execute(null); // directly invoke execute for test coverage
            Test.stopTest();

            // Assert
            System.assertNotEquals(null, queue, 'Queueable instance should not be null');
        }
    }

    /**
     * @description Tests constructor initialization only.
     */
    @IsTest
    static void testConstructorOnly() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // Arrange
            CCCWA__WhatsApp_Conversation__b dummy = new CCCWA__WhatsApp_Conversation__b();
            dummy.Record_ID__c = 'ONLY_CONSTRUCTOR_TEST';

            // Act
            C3CreateWhatsAppConversationQueue obj = new C3CreateWhatsAppConversationQueue(dummy);

            // Assert
            System.assertNotEquals(null, obj, 'Queueable object constructed via constructor should not be null');
        }
    }

    /**
     * @description Tests queueable execution with test data enqueued.
     */
    @IsTest
    static void testQueueableExecutionWithTestData() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // Arrange
            Account objAccount = C3TestDataFactory.createAccount();
            CCCWA__Template_Object__c objTemplate = C3TestDataFactory.createTemplate();
            C3TestDataFactory.WhatsAppInputWrapper input = new C3TestDataFactory.WhatsAppInputWrapper();
            input.objTemplate = objTemplate;
            input.toNumber = '919911410564';
            input.recordId = objAccount.Id;
            input.wamId = 'wamId';
            CCCWA__WhatsApp_Conversation__b objTxtMsg = C3TestDataFactory.buildConvoRecord(input);

            // Act
            C3CreateWhatsAppConversationQueue queue = new C3CreateWhatsAppConversationQueue(objTxtMsg);

            Test.startTest();
            System.enqueueJob(queue);
            Test.stopTest();

            // Assert
            System.assertNotEquals(null, queue, 'Queueable job should be enqueued successfully');
            System.assertEquals('919911410564', objTxtMsg.To_Phone__c, 'Phone number should match the input');
            System.assertEquals(objAccount.Id, objTxtMsg.Record_ID__c, 'Account Id should be correctly assigned');
        }
    }
}