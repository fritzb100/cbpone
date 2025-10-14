/**
 * Queueable job to perform OpenAI callout for readiness assessment
 * Runs asynchronously to avoid blocking UI
 */
public class ReadinessQueueable implements Queueable, Database.AllowsCallouts {
    
    private Id portId;
    
    // OpenAI configuration
    private static final String OPENAI_ENDPOINT = 'callout:OpenAI_Legacy/v1/chat/completions';
    private static final String MODEL = 'gpt-4o-mini'; // Cost-effective model
    
    // Get API key from Custom Metadata (replace 'Default' with your record's DeveloperName)
    private static final String API_KEY = openAiKey__mdt.getInstance('TheKey')?.Key__c; //TODO: update to external credential instead
    
    public ReadinessQueueable(Id portId) {
        this.portId = portId;
    }
    
    public void execute(QueueableContext context) {
        try {
            System.debug('Starting ReadinessQueueable for portId: ' + portId);
            
            // Fetch port data
            Port_of_Entry__c port = [
                SELECT Id, Name, Geopoint__Latitude__s, Geopoint__Longitude__s,
                       CBP_Sector__r.Name
                FROM Port_of_Entry__c
                WHERE Id = :portId
                LIMIT 1
            ];
            
            System.debug('Port fetched: ' + port);
            
            // Build prompt
            String prompt = buildPrompt(port);
            System.debug('Prompt built successfully');
            
            // Make callout to OpenAI
            HttpRequest req = new HttpRequest();
            req.setEndpoint(OPENAI_ENDPOINT);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Bearer ' + API_KEY);
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
                'temperature' => 0.3,
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
        System.debug('Building prompt for port: ' + port.Name);
        System.debug('Sector: ' + port.CBP_Sector__r.Name);
        System.debug('Coordinates: ' + port.Geopoint__Latitude__s + ', ' + port.Geopoint__Longitude__s);
        
        // Use simple string concatenation instead of String.format to avoid escaping issues
        String prompt = 'You are a CBP deployment readiness analyst. Assess the readiness score for deploying CBP resources to: ' + port.Name + 
            ' (Sector: ' + port.CBP_Sector__r.Name + ') at coordinates ' + 
            port.Geopoint__Latitude__s + ', ' + port.Geopoint__Longitude__s + '.\n\n' +
            'Scoring Guidelines:\n' +
            '- 90-100: Major international hub, excellent infrastructure, high strategic value\n' +
            '- 70-89: Significant port with good infrastructure, moderate strategic importance\n' +
            '- 50-69: Regional port, adequate infrastructure, limited strategic value\n' +
            '- 30-49: Small port, basic infrastructure, low priority\n' +
            '- 0-29: Remote location, poor infrastructure, minimal strategic need\n\n' +
            'Evaluate based on:\n' +
            '1. Port size and international traffic volume (research the actual port)\n' +
            '2. Infrastructure quality and accessibility\n' +
            '3. Proximity to major cities and transportation networks\n' +
            '4. Border security strategic importance\n' +
            '5. Regional threat level and enforcement needs\n\n' +
            'Be specific and vary scores meaningfully based on actual port characteristics.\n\n' +
            'Respond ONLY with valid JSON:\n' +
            '{\n' +
            '  "score": <number between 0-100>,\n' +
            '  "reasoning": "<2-3 sentences explaining the score with specific factors>"\n' +
            '}';
        
        System.debug('Generated prompt: ' + prompt);
        return prompt;
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
