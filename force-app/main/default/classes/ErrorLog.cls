public with sharing class ErrorLog {
    
    public static void  createErrorItem(String itemName, String obj, String method, String description, Id ownerId) {
        description = description.length() > 131072 ? description.substring(0, 131072) : description;
        Error_Item__c item = new Error_Item__c(
            Name = itemName,
            Error_Object__c = obj,
            Error_Method__c = method,
            Error_Description__c = description,
            Error_Owner__c = ownerId
        );
        insert item;
    }
    public static void debugException(Exception e) {
        System.debug(LoggingLevel.ERROR, '*** Exception occured!!***');
        System.debug(LoggingLevel.ERROR,'Exception Type caught: ' + e.getTypeName());
        System.debug(LoggingLevel.ERROR,'Message: ' + e.getMessage());
        System.debug(LoggingLevel.ERROR,'Cause: ' + e.getCause());
        System.debug(LoggingLevel.ERROR,'Line Number: ' + e.getLineNumber());
        System.debug(LoggingLevel.ERROR,'Stack trace: ' + e.getStackTraceString());
    }
}