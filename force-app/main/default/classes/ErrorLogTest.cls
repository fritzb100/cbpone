@isTest
public with sharing class ErrorLogTest {
    private static String DESCRIPTION = 'This is a description of the error';
    private static String METHOD = 'Error in queueable';
    private static String ERROR_OBJECT = 'Articles__c';
    private static Id OWNER = UserInfo.getUserId();
    private static String NAME = 'Error when queueing Articles';


    @TestSetup
    static void makeData() {
        ErrorLog.createErrorItem(NAME, ERROR_OBJECT, METHOD, DESCRIPTION, OWNER);
    }

@isTest
static void testErrorItemCreation() {
    // get the Item that was created during the testSetup
    Error_Item__c createdItem = [SELECT Id, Error_Description__c, Error_Method__c, Error_Object__c, Error_Owner__c, Name FROM Error_Item__c];
    
    Assert.areEqual(NAME, createdItem.Name, 'The Name should match');
    Assert.areEqual(ERROR_OBJECT, createdItem.Error_Object__c, 'The object should match');
    Assert.areEqual(METHOD, createdItem.Error_Method__c, 'The Method should match');
    Assert.areEqual(DESCRIPTION, createdItem.Error_Description__c, 'The Description should match');
    Assert.areEqual(OWNER, createdItem.Error_Owner__c, 'The owner should match');
    }
}