/**
 * Queueable job to perform OpenAI callout for readiness assessment
 * Runs asynchronously to avoid blocking UI
 */
public class ReadinessQueueable implements Queueable, Database.AllowsCallouts {
    
    private Id portId;
    
    // OpenAI configuration - will be replaced with Named Credential
    private static final String OPENAI_ENDPOINT = 'callout:OpenAI_NC/v1/chat/completions';
    private static final String MODEL = 'gpt-4o-mini'; // Cost-effective model
    
    public ReadinessQueueable(Id portId) {
        this.portId = portId;
    }
    
    public void execute(QueueableContext context) {
        try {
            // Fetch port data
            Port_of_Entry__c port = [
                SELECT Id, Name, Geopoint__Latitude__s, Geopoint__Longitude__s,
                       CBP_Sector__r.Name
                FROM Port_of_Entry__c
                WHERE Id = :portId
                LIMIT 1
            ];
            
            // Build prompt
            String prompt = buildPrompt(port);
            
            // Make callout to OpenAI
            HttpRequest req = new HttpRequest();
            req.setEndpoint(OPENAI_ENDPOINT);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setTimeout(120000); // 120 seconds
            
            // Build request body
            Map<String, Object> requestBody = new Map<String, Object>{
                'model' => MODEL,
                'messages' => new List<Object>{
                    new Map<String, String>{
                        'role' => 'system',
                        'content' => 'You are a CBP readiness assessment expert. Respond only with valid JSON.'
                    },
                    new Map<String, String>{
                        'role' => 'user',
                        'content' => prompt
                    }
                },
                'temperature' => 0.7,
                'max_tokens' => 500
            };
            
            req.setBody(JSON.serialize(requestBody));
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                processSuccessResponse(res.getBody(), port);
            } else {
                handleError('OpenAI API Error: ' + res.getStatus() + ' - ' + res.getBody(), port);
            }
            
        } catch (Exception e) {
            handleError('Exception: ' + e.getMessage() + '\n' + e.getStackTraceString(), 
                       [SELECT Id FROM Port_of_Entry__c WHERE Id = :portId LIMIT 1]);
        }
    }
    
    /**
     * Builds the assessment prompt for OpenAI
     */
    private String buildPrompt(Port_of_Entry__c port) {
        return String.format(
            'Assess CBP readiness for deployment to {0} (Sector: {1}) located at coordinates {2}, {3}.\n\n' +
            'Consider factors like:\n' +
            '- Geographic location and accessibility\n' +
            '- Proximity to major transportation hubs\n' +
            '- Strategic importance of the location\n' +
            '- Typical resource availability in this region\n\n' +
            'Respond ONLY with a JSON object in this exact format:\n' +
            '{{\n' +
            '  "score": <number between 0-100>,\n' +
            '  "reasoning": "<brief 2-3 sentence explanation>"\n' +
            '}}',
            new List<String>{
                port.Name,
                port.CBP_Sector__r.Name,
                String.valueOf(port.Geopoint__Latitude__s),
                String.valueOf(port.Geopoint__Longitude__s)
            }
        );
    }
    
    /**
     * Parses OpenAI response and updates port record
     */
    private void processSuccessResponse(String responseBody, Port_of_Entry__c port) {
        try {
            // Parse OpenAI response
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            List<Object> choices = (List<Object>) response.get('choices');
            Map<String, Object> firstChoice = (Map<String, Object>) choices[0];
            Map<String, Object> message = (Map<String, Object>) firstChoice.get('message');
            String content = (String) message.get('content');
            
            // Parse the JSON content from the AI
            Map<String, Object> assessment = (Map<String, Object>) JSON.deserializeUntyped(content);
            
            Decimal score = Decimal.valueOf(String.valueOf(assessment.get('score')));
            String reasoning = (String) assessment.get('reasoning');
            
            // Update port record
            port.Readiness_Score__c = score;
            port.AI_Response_Summary__c = reasoning;
            port.Assessment_Status__c = 'Complete';
            port.Last_Assessed_Date__c = System.now();
            
            update port;
            
        } catch (Exception e) {
            handleError('Error parsing response: ' + e.getMessage() + '\nResponse: ' + responseBody, port);
        }
    }
    
    /**
     * Handles errors by updating port status
     */
    private void handleError(String errorMessage, Port_of_Entry__c port) {
        port.Assessment_Status__c = 'Error';
        port.AI_Response_Summary__c = 'Error: ' + errorMessage.left(32768);
        update port;
    }
}
