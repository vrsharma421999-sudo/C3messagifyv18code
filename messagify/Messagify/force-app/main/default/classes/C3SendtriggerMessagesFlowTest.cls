@isTest
private class C3SendtriggerMessagesFlowTest {
    
    @testSetup
    static void testSendTemplate() {

        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'Admin',
            Email = 'testadmin@example.com',
             Username = 'testadmin@example.com' + System.currentTimeMillis(), // Ensure unique username
            Alias = 'tadmin',
            ProfileId = sysAdminProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        // Assign Permission Sets
        List<PermissionSetAssignment> psAssignments = new List<PermissionSetAssignment>();
        map<String, string> mapPerSetNameWithId = new map<String, string>();
        for(PermissionSet objPerSet : [SELECT Id,Name FROM PermissionSet WHERE Name ='Admin_Panel' OR Name ='WhatsApp_Access']){
            mapPerSetNameWithId.put(objPerSet.Name,objPerSet.Id);
        }
        for (String permSetName : new List<String>{'Admin_Panel', 'WhatsApp_Access'}) {
            if(mapPerSetNameWithId.containskey(permSetName) && mapPerSetNameWithId.get(permSetName) != null){
                psAssignments.add(new PermissionSetAssignment(
                    AssigneeId = testUser.Id,
                    PermissionSetId = mapPerSetNameWithId.get(permSetName)
                ));
            }
        }
        insert psAssignments;
    
        System.runAs(testUser) {
        
            Lead testLead = new Lead(LastName = 'Test Lead', Company = 'Testing Lead');
            insert testLead;
            
            CCCWA__Template_Object__c templateRecord = new CCCWA__Template_Object__c();
            
            templateRecord.CCCWA__Category__c = 'Marketing';
            templateRecord.CCCWA__Header_Type__c = 'Text';
            templateRecord.CCCWA__Header__c = 'Demo';
            templateRecord.CCCWA__Template_Label__c = 'Test';
            templateRecord.CCCWA__Language_Code__c = 'English';
            templateRecord.CCCWA__Object__c = 'Lead';
            templateRecord.CCCWA__Template_Message__c = 'Testing';
            
            insert templateRecord;
        
        }
    }

    @isTest
    static void method1() {
        User testUser = [SELECT Id FROM User WHERE Email = 'testadmin@example.com' LIMIT 1];
        System.runAs(testUser) {
            Lead testLead = [SELECT Id FROM LEAD LIMIT 1];
            CCCWA__Template_Object__c templateRecord = [SELECT Id FROM CCCWA__Template_Object__c LIMIT 1];
            C3SendtriggerMessagesFlow.FlowInput flowInput = new C3SendtriggerMessagesFlow.FlowInput();
            flowInput.recordId = testLead.Id;
            flowInput.templateRecordId = templateRecord.Id;
            List<C3SendtriggerMessagesFlow.FlowInput> flowInputs = new List<C3SendtriggerMessagesFlow.FlowInput>{ flowInput };
            Test.startTest();
                Test.setMock(HttpCalloutMock.class, new C3HttpCalloutMockBundleClass('WhatsAppMessageSendTemplate'));
                C3SendtriggerMessagesFlow.sendTemplate(flowInputs);
            Test.stopTest();
            
            System.assertNotEquals(null, flowInput.recordId, 'recordId should not be null');
            System.assertNotEquals(null, flowInput.templateRecordId, 'templateRecordId should not be null');
   
        }
    }
}