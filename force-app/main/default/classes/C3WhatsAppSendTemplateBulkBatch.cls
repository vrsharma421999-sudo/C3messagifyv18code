/**
* @class C3WhatsAppSendTemplateBulkBatch 
* @description
*  This Apex batch class is used to send WhatsApp template messages in bulk by querying
*  a specific set of sObject records and using the `C3WhatsAppWebService` utility to send messages.
*
*  Features:
*  - Executes as a batch job using a dynamic SOQL query.
*  - Processes records in chunks for scalable message sending.
*  - Supports HTTP callouts to external WhatsApp API.
*
* @implements Database.Batchable<sObject>, Database.AllowsCallouts
* @access Public - Invokable as a batch class from Apex.
* @usage Called from Apex with necessary parameters for sending WhatsApp messages.
* @security This class does not perform FLS/CRUD checks — ensure caller context enforces security.
* @author Asjad Ahmed
* @version 1.0
* @company CloudCentric
* @license Salesforce Public License (https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_license.htm)
* @date June 2025
*/
public with sharing class C3WhatsAppSendTemplateBulkBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
    
    public Set<String> setRecordIds;
    public String phoneField;
    public String query;
    Map<String, String> mapParamNumWithFieldName;
    Template_Object__c objTemplate;
    
    /**
* @constructor C3WhatsAppSendTemplateBulkBatch
* @description
*  Initializes the batch class with record IDs, query string, parameter mappings, template metadata, and phone field name.
*
* @param setRecordIds Set<String> - Set of record IDs to process.
* @param query String - Dynamic SOQL query to fetch records.
* @param mapParamNumWithFieldName Map<String, String> - Template parameter number to field name map.
* @param objTemplate Template_Object__c - WhatsApp message template object.
* @param phoneField String - Field API name representing the phone number to send messages to.
*/
    public C3WhatsAppSendTemplateBulkBatch(
        Set<String> setRecordIds,
        String query,
        Map<String, String> mapParamNumWithFieldName,
        Template_Object__c objTemplate,
        String phoneField
    ) {
        this.setRecordIds = new Set<String>();
        this.mapParamNumWithFieldName = new Map<String, String>();
        this.objTemplate = new Template_Object__c();
        this.objTemplate = objTemplate;
        this.mapParamNumWithFieldName = mapParamNumWithFieldName;
        this.setRecordIds = setRecordIds;
        this.query = query;
        this.phoneField = phoneField;
    }
    
    /**
* @method start
* @description
*  Returns a QueryLocator to iterate over records returned by the dynamic SOQL query.
*
* @param bc Database.BatchableContext - Context of the batch job.
* @return Database.QueryLocator - QueryLocator object to iterate through records.
*/
   /*  public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(this.query);
    }*/
    
   public Iterable<SObject> start(Database.BatchableContext bc) {
  // Run  dynamic SOQL in USER MODE
    List<SObject> records = Database.query(
        this.query,
        AccessLevel.USER_MODE
    );
    return records;
}

    
    /**
* @method execute
* @description
*  Executes for each batch of records. Calls C3WhatsAppWebService to send messages for each record.
*
* @param bc Database.BatchableContext - Context of the batch job.
* @param lstSObject List<sObject> - List of sObject records to process in this chunk.
*/
    public void execute(Database.BatchableContext bc, List<sObject> lstSObject) {
        if (lstSObject != null && lstSObject.size() > 0) {
            C3WhatsAppWebService.createWebserviceBody(
                lstSObject,
                this.mapParamNumWithFieldName,
                this.objTemplate,
                this.phoneField
            );
        }
    }
    
    /**
* @method finish
* @description
*  Called after all batches are processed. Can be used to send notifications or perform cleanup.
*
* @param bc Database.BatchableContext - Context of the batch job.
*/
    public void finish(Database.BatchableContext bc) {
        if (Test.isRunningTest() || System.isBatch()) {
            System.debug(LoggingLevel.INFO, 'Batch job finished.');
        }
    }
}