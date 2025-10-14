/**
 * Controller for CBP Readiness Assessment
 * Handles LWC requests to assess port readiness using OpenAI
 */
public with sharing class ReadinessController {
    
    /**
     * Retrieves all ports with their geolocation data for map display
     * @return List of Port_of_Entry__c records with essential fields
     */
    @AuraEnabled(cacheable=true)
    public static List<Port_of_Entry__c> getPorts() {
        return [
            SELECT Id, Name, Geopoint__c, Readiness_Score__c, 
                   Assessment_Status__c, Last_Assessed_Date__c,
                   AI_Response_Summary__c, CBP_Sector__r.Name
            FROM Port_of_Entry__c
            ORDER BY Name
        ];
    }
    
    /**
     * Initiates readiness assessment for a specific port
     * Updates status and enqueues Queueable job for OpenAI callout
     * @param portId - ID of the Port_of_Entry__c record to assess
     * @return String message indicating success or error
     */
    @AuraEnabled
    public static String assessReadiness(Id portId) {
        try {
            // Validate port exists
            Port_of_Entry__c port = [
                SELECT Id, Name, Geopoint__c, Assessment_Status__c
                FROM Port_of_Entry__c
                WHERE Id = :portId
                LIMIT 1
            ];
            
            // Check if already in progress
            if (port.Assessment_Status__c == 'In Progress') {
                return 'Assessment already in progress for ' + port.Name;
            }
            
            // Update status to In Progress
            port.Assessment_Status__c = 'In Progress';
            update port;
            
            // Enqueue the assessment job
            System.enqueueJob(new ReadinessQueueable(portId));
            
            return 'Assessment queued successfully for ' + port.Name;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error initiating assessment: ' + e.getMessage());
            ErrorLog.createErrorItem('ReadinessController', 'Port_of_Entry__c', 'assessReadiness', e.getMessage(), UserInfo.getUserId());
        }
    }
    
    /**
     * Retrieves a single port's current data (for polling/refresh)
     * @param portId - ID of the Port_of_Entry__c record
     * @return Port_of_Entry__c record with updated fields
     */
    @AuraEnabled(cacheable=false)
    public static Port_of_Entry__c getPortStatus(Id portId) {
        return [
            SELECT Id, Name, Geopoint__c, Readiness_Score__c,
                   Assessment_Status__c, Last_Assessed_Date__c,
                   AI_Response_Summary__c, CBP_Sector__r.Name
            FROM Port_of_Entry__c
            WHERE Id = :portId
            LIMIT 1
        ];
    }
}
