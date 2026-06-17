@isTest
public class C3AdminPanelLwcControllerTest {

    @isTest
    static void testInitializeAndSaveAdminConfig() {
        // Step 1: Insert test data that initialize() can query
        CCCWA__WhatsApp_Admin__c adminRecord = new CCCWA__WhatsApp_Admin__c(
            Name = 'Admin',
            CCCWA__WabaId__c = '108445142322979',
            CCCWA__NumberID__c = '108193625692105'
        );
        insert adminRecord;

        // Step 2: Call initialize
        CCCWA__WhatsApp_Admin__c adminConfig = C3AdminPanelLwcController.initialize();
        System.assertNotEquals(null, adminConfig, 'Expected result from initialize() to not be null');
        System.assertEquals('Admin', adminConfig.Name, 'Expected Name to match');

        // Step 3: Test saveAdminConfig
        String jsonConfig = '{"LastModifiedDate":"2025-04-11T05:47:42.000Z","IsDeleted":false,"CreatedById":"005gK000000zS5pQAE","CCCWA__WabaId__c":"108445142322979","CCCWA__NumberID__c":"108193625692105","CreatedDate":"2025-03-24T07:38:24.000Z","Id":"' + adminRecord.Id + '","LastModifiedById":"005gK000000zS5pQAE","Name":"Admin","SystemModstamp":"2025-04-11T05:47:42.000Z"}';

        C3AdminPanelLwcController.saveAdminConfig(jsonConfig);

        // Step 4: Verify the record was updated
        CCCWA__WhatsApp_Admin__c updated = [SELECT Id, Name FROM CCCWA__WhatsApp_Admin__c WHERE Id = :adminRecord.Id];
        System.assertEquals('Admin', updated.Name, 'Expected name to be Admin');
    }
}