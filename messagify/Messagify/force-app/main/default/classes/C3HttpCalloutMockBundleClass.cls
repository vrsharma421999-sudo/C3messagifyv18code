/**
* @class C3HttpCalloutMockBundleClass
* @description
*  This mock class simulates different types of HTTP callout responses for unit testing
*  WhatsApp-related APIs. It supports multiple response modes based on the provided mock type.
*
*  The supported mock types include:
*  - WhatsAppMessageText
*  - WhatsAppMessageMedia
*  - WhatsAppMessageSendTemplate
*  - WhatsAppMessageCreateTemplate
*  - WhatsAppUploadAPI
*  - WhatsAppMessageMediaAPI
*  - templateDeleteApi
*  - refreshTemplate
*
*  Used in unit tests via `Test.setMock(HttpCalloutMock.class, new C3HttpCalloutMockBundleClass(mockType));`.
*
* @author Asjad Ahmed
* @version 1.0
* @date June 2025
*/

@isTest
public class C3HttpCalloutMockBundleClass implements HttpCalloutMock {
    private String mockType;
    
    /**
* @description Constructor that initializes the mock class with a specific mock type.
* This mock type determines the behavior of the HTTP callout mock responses.
* @param mockType A string representing the type of mock response to initialize.
*/
    public C3HttpCalloutMockBundleClass(String mockType) {
        this.mockType = mockType;
    }
    
    /**
* @description Returns a mocked HTTP response based on the specified mock type.
* This method simulates different responses from the WhatsApp Business API 
* depending on the provided mock type and the request's endpoint.
*
* @param req The incoming HttpRequest object used to determine the response context.
* @return A mocked HttpResponse object with a predefined body and status code.
*/
    public HttpResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        
        switch on mockType {
            when 'WhatsAppMessageText' {
                res.setBody('{"messaging_product":"whatsapp","contacts":[{"input":"919911410564","wa_id":"919911410564"}],"messages":[{"id":"asdasdasd"}]}');
            }
            when 'WhatsAppMessageMedia', 'WhatsAppMessageSendTemplate' {
                res.setBody('{ "messaging_product": "whatsapp", "contacts": [ { "input": "48XXXXXXXXX", "wa_id": "48XXXXXXXXX " } ], "messages": [ { "id": "wamid.gBGGSFcCNEOPAgkO_KJ55r4w_ww" } ] }');
            }
            when 'WhatsAppMessageCreateTemplate' {
                res.setBody('{ "success": "true", "id": "1627019861106475", "status": "PENDING", "category": "MARKETING" }');
            }
            when 'WhatsAppUploadAPI' {
                res.setBody(
                    req.getEndpoint().contains('app/uploads') 
                    ? '{"id": "asdasdasdasdasd"}' 
                    : '{"h": "asdasdasdasdasd"}'
                );
            }
            when 'WhatsAppMessageMediaAPI' {
    if (req.getEndpoint().contains('phone_number_id')) {
        // Step 1: Return media metadata in JSON format
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"messaging_product": "whatsapp","url": "https://mocked.test.url/media-download","mime_type": "image/jpeg","sha256": "MOCKED_HASH","file_size": "303833","id": "mockedMediaId123"}');
    } else {
        // Step 2: Return actual media as binary content
        res.setHeader('Content-Type', 'application/octet-stream');
        res.setBodyAsBlob(Blob.valueOf('This is mocked binary media content'));
    }
}


            when 'templateDeleteApi' {
                res.setBody('{ "message": "Success"}');
            }
            when 'refreshTemplate' {
                res.setBody('{"data":[{"id":"WhatsAppID1","status":"Approved","name":"Updated Template 1"}]}');
            }
            when else {
                res.setBody('{"messaging_product":"whatsapp","contacts":[{"input":"919911410564","wa_id":"919911410564"}],"messages":[{"id":"asdasdasd"}]}');
            }
        }
        
        res.setStatusCode(200);
        return res;
    }
}