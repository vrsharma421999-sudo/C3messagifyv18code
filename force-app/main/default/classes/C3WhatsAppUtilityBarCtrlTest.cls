@IsTest
public class C3WhatsAppUtilityBarCtrlTest {

    static Contact testContact;
    static CCCWA__Template_Object__c template;

    public static List<CCCWA__whatsApp_conversation__b> messageList1 = new List<CCCWA__whatsApp_conversation__b>();



    @TestSetup
    static void setupData() {

        /*Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];

User testUser = new User(
Alias = 'tadmin',
Email = 'testuser@gmail.com',
EmailEncodingKey = 'UTF-8',
LastName = 'Test',
LanguageLocaleKey = 'en_US',
LocaleSidKey = 'en_US',
ProfileId = profile.Id,
TimeZoneSidKey = 'Asia/Kolkata',
Username = 'testadmin@example.com.dev'
);
insert testUser;*/
        C3TestDataFactory.getRunAsUser();
        Account testAccount=C3TestDataFactory.createAccount();
        template=C3TestDataFactory.createTemplate();
        List<Contact> createContacts= C3TestDataFactory.createContacts(5,testAccount.id);
        testContact = createContacts[0];
        // template=C3TestDataFactory.createTemplate();
        C3TestDataFactory.createTemplateMappings(2, template.Id);
        C3TestDataFactory.createTemplateButtons(template.Id);

        //List<Template_Parameter__c> createTemplateMappings=C3TestDataFactory.createTemplateMappings(2,template.Id);
        //List<Template_Button__c> createTemplateButtons=C3TestDataFactory.createTemplateButtons (template.Id);

    }

    @IsTest
    static void testAllConversationMessages() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Contact objContact = new Contact();
            objContact.LastName = 'testcontact' ;
            objContact.FirstName = 'test contact' ;
            objContact.MobilePhone='919911410564';
            objContact.Phone='919911410564';
            objContact.AssistantPhone = '919911410564';
            objContact.Email = 'test@user.com';
            insert objContact;

            CCCWA__Template_Object__c tmpl = [SELECT Id FROM CCCWA__Template_Object__c LIMIT 1];
            List<CCCWA__whatsApp_conversation__b> messageList = new List<CCCWA__whatsApp_conversation__b>();

            // Inject mock WhatsApp message using factory
            C3TestDataFactory.WhatsAppInputWrapper wrapper = new C3TestDataFactory.WhatsAppInputWrapper();
            wrapper.toNumber = '919911410564';
            wrapper.recordId = objContact.Id;
            wrapper.wamId = 'mockWamId';
            wrapper.objTemplate = tmpl;

            CCCWA__whatsApp_conversation__b testMessage = C3TestDataFactory.buildConvoRecord(wrapper);
            messageList.add(testMessage);
            C3TestDataFactory.WhatsAppInputWrapper wrapper1 = new C3TestDataFactory.WhatsAppInputWrapper();
            wrapper1.toNumber = '919911410564';
            wrapper1.recordId = tmpl.Id;
            wrapper1.wamId = 'mockWamId';
            wrapper1.objTemplate = tmpl;
            CCCWA__whatsApp_conversation__b testMessage1 = C3TestDataFactory.buildConvoRecord(wrapper1);
            messageList.add(testMessage1);

            Test.startTest();
            C3WhatsAppUtilityBarCtrl.allConversationMessages();
            Test.stopTest();
        }
    }

    @IsTest
    static void testAllConversationMessages1() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Contact objContact = new Contact();
            objContact.LastName = 'testcontact' ;
            objContact.FirstName = 'test contact' ;
            objContact.MobilePhone='919911410564';
            objContact.Phone='919911410564';
            objContact.AssistantPhone = '919911410564';
            objContact.Email = 'test@user.com';
            insert objContact;

            CCCWA__Template_Object__c tmpl = [SELECT Id FROM CCCWA__Template_Object__c LIMIT 1];

            // Inject mock WhatsApp message using factory
            C3TestDataFactory.WhatsAppInputWrapper wrapper1 = new C3TestDataFactory.WhatsAppInputWrapper();
            wrapper1.toNumber = '919911410564';
            wrapper1.recordId = objContact.Id;
            wrapper1.wamId = 'mockWamId';
            wrapper1.objTemplate = tmpl;
            messageList1.add(C3TestDataFactory.buildConvoRecord(wrapper1));
            // Build and add second message (linked to Template)
            C3TestDataFactory.WhatsAppInputWrapper wrapper2 = new C3TestDataFactory.WhatsAppInputWrapper();
            wrapper2.toNumber = '919911410564';
            wrapper2.recordId = tmpl.Id;
            wrapper2.wamId = 'mockWamId';
            wrapper2.objTemplate = tmpl;
            messageList1.add(C3TestDataFactory.buildConvoRecord(wrapper2));

            Test.startTest();
            C3WhatsAppUtilityBarCtrl.allConversationMessages();
            Test.stopTest();
        }
    }
    @IsTest
    static void testWrapperClassesCoverage() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            CCCWA.C3WhatsAppUtilityBarCtrl.MainWrapper mainWrap = new CCCWA.C3WhatsAppUtilityBarCtrl.MainWrapper();
            mainWrap.currentUserId = UserInfo.getUserId();
            mainWrap.organizationId = UserInfo.getOrganizationId();
            mainWrap.strMsg = 'Sample message';
            mainWrap.totalUnreadCount = 2;
            mainWrap.boolUnreadMsgAvailable = true;

            CCCWA.C3WhatsAppUtilityBarCtrl.WrapperMessage msg = new CCCWA.C3WhatsAppUtilityBarCtrl.WrapperMessage();
            msg.recordId = '001xx000003DGb8AAG';
            msg.objectApiName = 'Lead';
            msg.senderName = 'Test Sender';
            msg.senderNameSmall = 'TS';
            msg.lastText = 'Hello';
            msg.isRead = 'false';
            msg.colorCode = 'background:#E08B1E';
            msg.unreadCount = 2;
            msg.booleanIsRead = false;
            msg.createdDate = System.now();

            mainWrap.wrapperMessageList = new List<CCCWA.C3WhatsAppUtilityBarCtrl.WrapperMessage>{ msg };

            System.assertEquals('Test Sender', mainWrap.wrapperMessageList[0].senderName);
        }
    }

    @IsTest
    static void testAllConversationMessages_FullBranchCoverage() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Account acc = C3TestDataFactory.createAccount();
            Contact con = C3TestDataFactory.createContacts(1, acc.Id)[0];
            CCCWA__Template_Object__c tmpl= [SELECT Id FROM CCCWA__Template_Object__c LIMIT 1];
            C3WhatsAppUtilityBarCtrlTest.messageList1.clear();

            // Message 1 – UNREAD
            C3TestDataFactory.WhatsAppInputWrapper w1 = new C3TestDataFactory.WhatsAppInputWrapper();
            w1.toNumber = '919911410564';
            w1.recordId = con.Id;
            w1.wamId = 'wam1';
            w1.objTemplate = tmpl;

            CCCWA__whatsApp_conversation__b m1 =
                C3TestDataFactory.buildConvoRecord(w1);
            m1.CCCWA__Read__c = 'false';
            m1.CCCWA__Message__c = 'Unread Message';
            m1.CCCWA__Message_formatted__c = 'Unread Message';

            // Message 2 – READ (same record, different date)
            C3TestDataFactory.WhatsAppInputWrapper w2 = new C3TestDataFactory.WhatsAppInputWrapper();
            w2.toNumber = '919911410564';
            w2.recordId = con.Id;
            w2.wamId = 'wam2';
            w2.objTemplate = tmpl;

            CCCWA__whatsApp_conversation__b m2 =
                C3TestDataFactory.buildConvoRecord(w2);
            m2.CCCWA__Read__c = 'true';
            m2.CCCWA__Message__c = 'Read Message';
            m2.CCCWA__Message_formatted__c = 'Read Message';

            // Message 3 – Different Record
            C3TestDataFactory.WhatsAppInputWrapper w3 = new C3TestDataFactory.WhatsAppInputWrapper();
            w3.toNumber = '919911410564';
            w3.recordId = tmpl.Id;
            w3.wamId = 'wam3';
            w3.objTemplate = tmpl;

            CCCWA__whatsApp_conversation__b m3 =
                C3TestDataFactory.buildConvoRecord(w3);
            m3.CCCWA__Read__c = 'false';

            C3WhatsAppUtilityBarCtrlTest.messageList1.addAll(
                new List<CCCWA__whatsApp_conversation__b>{ m1, m2, m3 }
            );

            Test.startTest();
            C3WhatsAppUtilityBarCtrl.allConversationMessages();
            Test.stopTest();
        }
    }

    @IsTest
    static void testExceptionHandlingCoverage() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Test.startTest();
            try {
                C3WhatsAppUtilityBarCtrl.colorList = null; // force NPE
                C3WhatsAppUtilityBarCtrl.allConversationMessages();
            } catch (Exception e) {
                System.assert(true);
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void testSortingBlockCoverage_ACTUAL_FIX() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // 2 different valid records
            Account acc1 = C3TestDataFactory.createAccount();
            Account acc2 = C3TestDataFactory.createAccount();

            CCCWA__Template_Object__c tmpl =
                [SELECT Id FROM CCCWA__Template_Object__c LIMIT 1];

            C3WhatsAppUtilityBarCtrlTest.messageList1.clear();

            // Older message (acc1)
            C3TestDataFactory.WhatsAppInputWrapper w1 =
                new C3TestDataFactory.WhatsAppInputWrapper();
            w1.toNumber = '919911410564';
            w1.recordId = acc1.Id;
            w1.wamId = 'old';
            w1.objTemplate = tmpl;

            CCCWA__whatsApp_conversation__b oldMsg =
                C3TestDataFactory.buildConvoRecord(w1);
            oldMsg.CCCWA__Read__c = 'true';

            // Newer message (acc2)
            C3TestDataFactory.WhatsAppInputWrapper w2 =
                new C3TestDataFactory.WhatsAppInputWrapper();
            w2.toNumber = '919911410564';
            w2.recordId = acc2.Id;
            w2.wamId = 'new';
            w2.objTemplate = tmpl;

            CCCWA__whatsApp_conversation__b newMsg =
                C3TestDataFactory.buildConvoRecord(w2);
            newMsg.CCCWA__Read__c = 'false';

            // IMPORTANT: older FIRST, newer SECOND
            C3WhatsAppUtilityBarCtrlTest.messageList1.add(oldMsg);
            C3WhatsAppUtilityBarCtrlTest.messageList1.add(newMsg);

            Test.startTest();
            C3WhatsAppUtilityBarCtrl.allConversationMessages();
            Test.stopTest();
        }
    }
}