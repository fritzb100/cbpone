// Get a port
Port_of_Entry__c port = [SELECT Id, Name FROM Port_of_Entry__c LIMIT 1];

// Trigger assessment
ReadinessController.assessReadiness(port.Id);

// Wait 10-15 seconds, then check result
Port_of_Entry__c result = [
    SELECT Name, Readiness_Score__c, Assessment_Status__c, 
           AI_Response_Summary__c, Last_Assessed_Date__c
    FROM Port_of_Entry__c 
    WHERE Id = :port.Id
];

System.debug('Status: ' + result.Assessment_Status__c);
System.debug('Score: ' + result.Readiness_Score__c);
System.debug('Summary: ' + result.AI_Response_Summary__c);