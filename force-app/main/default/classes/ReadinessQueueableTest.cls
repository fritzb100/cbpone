/**
 * Test class for ReadinessController and ReadinessQueueable
 * Uses HttpCalloutMock to simulate OpenAI responses
 */
@isTest
private class ReadinessQueueableTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test sector
        CBP_Sector__c sector = new CBP_Sector__c(
            Name = 'Test Sector'
        );
        insert sector;
        
        // Create test port
        Port_of_Entry__c port = new Port_of_Entry__c(
            Name = 'Test Port - Chicago',
            CBP_Sector__c = sector.Id,
            Geopoint__Latitude__s = 41.8781,
            Geopoint__Longitude__s = -87.6298,
            Assessment_Status__c = 'Not Assessed'
        );
        insert port;
    }
    
    @isTest
    static void testGetPorts() {
        // Test getPorts method
        Test.startTest();
        List<Port_of_Entry__c> ports = ReadinessController.getPorts();
        Test.stopTest();
        
        System.assertEquals(1, ports.size(), 'Should return 1 port');
        System.assertEquals('Test Port - Chicago', ports[0].Name);
    }
    
    @isTest
    static void testAssessReadinessSuccess() {
        Port_of_Entry__c port = [SELECT Id, Name FROM Port_of_Entry__c LIMIT 1];
        
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new OpenAISuccessMock());
        
        Test.startTest();
        String result = ReadinessController.assessReadiness(port.Id);
        Test.stopTest();
        
        System.assert(result.contains('queued successfully'), 'Should return success message');
        
        // Verify port was updated to In Progress
        Port_of_Entry__c updatedPort = [
            SELECT Assessment_Status__c 
            FROM Port_of_Entry__c 
            WHERE Id = :port.Id
        ];
        System.assertEquals('Complete', updatedPort.Assessment_Status__c);
    }
    
    @isTest
    static void testAssessReadinessAlreadyInProgress() {
        Port_of_Entry__c port = [SELECT Id FROM Port_of_Entry__c LIMIT 1];
        port.Assessment_Status__c = 'In Progress';
        update port;
        
        Test.startTest();
        String result = ReadinessController.assessReadiness(port.Id);
        Test.stopTest();
        
        System.assert(result.contains('already in progress'), 'Should return already in progress message');
    }
    
    @isTest
    static void testQueueableSuccess() {
        Port_of_Entry__c port = [SELECT Id FROM Port_of_Entry__c LIMIT 1];
        port.Assessment_Status__c = 'In Progress';
        update port;
        
        Test.setMock(HttpCalloutMock.class, new OpenAISuccessMock());
        
        Test.startTest();
        System.enqueueJob(new ReadinessQueueable(port.Id));
        Test.stopTest();
        
        // Verify port was updated with score
        Port_of_Entry__c updatedPort = [
            SELECT Readiness_Score__c, Assessment_Status__c, 
                   AI_Response_Summary__c, Last_Assessed_Date__c
            FROM Port_of_Entry__c 
            WHERE Id = :port.Id
        ];
        
        System.assertEquals('Complete', updatedPort.Assessment_Status__c);
        System.assertEquals(85, updatedPort.Readiness_Score__c);
        System.assertNotEquals(null, updatedPort.AI_Response_Summary__c);
        System.assertNotEquals(null, updatedPort.Last_Assessed_Date__c);
    }
    
    @isTest
    static void testQueueableApiError() {
        Port_of_Entry__c port = [SELECT Id FROM Port_of_Entry__c LIMIT 1];
        port.Assessment_Status__c = 'In Progress';
        update port;
        
        Test.setMock(HttpCalloutMock.class, new OpenAIErrorMock());
        
        Test.startTest();
        System.enqueueJob(new ReadinessQueueable(port.Id));
        Test.stopTest();
        
        // Verify port status is Error
        Port_of_Entry__c updatedPort = [
            SELECT Assessment_Status__c, AI_Response_Summary__c
            FROM Port_of_Entry__c 
            WHERE Id = :port.Id
        ];
        
        System.assertEquals('Error', updatedPort.Assessment_Status__c);
        System.assert(updatedPort.AI_Response_Summary__c.contains('Error'));
    }
    
    @isTest
    static void testGetPortStatus() {
        Port_of_Entry__c port = [SELECT Id FROM Port_of_Entry__c LIMIT 1];
        
        Test.startTest();
        Port_of_Entry__c result = ReadinessController.getPortStatus(port.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assertEquals(port.Id, result.Id);
    }
    
    /**
     * Mock class for successful OpenAI response
     */
    private class OpenAISuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            
            // Simulate OpenAI response structure
            Map<String, Object> response = new Map<String, Object>{
                'id' => 'chatcmpl-test123',
                'object' => 'chat.completion',
                'created' => 1234567890,
                'model' => 'gpt-4o-mini',
                'choices' => new List<Object>{
                    new Map<String, Object>{
                        'index' => 0,
                        'message' => new Map<String, Object>{
                            'role' => 'assistant',
                            'content' => '{"score": 85, "reasoning": "Chicago is a major transportation hub with excellent infrastructure and strategic location for rapid deployment."}'
                        },
                        'finish_reason' => 'stop'
                    }
                }
            };
            
            res.setBody(JSON.serialize(response));
            return res;
        }
    }
    
    /**
     * Mock class for OpenAI error response
     */
    private class OpenAIErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(500);
            res.setStatus('Internal Server Error');
            res.setBody('{"error": {"message": "Service unavailable"}}');
            return res;
        }
    }
}
