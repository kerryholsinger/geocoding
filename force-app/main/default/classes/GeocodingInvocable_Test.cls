@isTest
public class GeocodingInvocable_Test {
  @testSetup
  static void setupTestData() {
    Account account = new Account(
      Name = 'Test Account',
      BillingStreet = '37921 N Dilleys Rd',
      BillingCity = 'Wadsworth Rd',
      BillingState = 'IL',
      BillingPostalCode = '60083'
    );
    insert account;
  }

  @isTest
  static void testSuccess() {
    List<Account> accounts = [SELECT Id, BillingStreet, BillingCity, BillingState, BillingPostalCode FROM Account LIMIT 1];

    GeocodingInvocable.Parameters params = new GeocodingInvocable.Parameters();
    params.records = accounts;
    params.streetField = 'BillingStreet';
    params.cityField = 'BillingCity';
    params.stateField = 'BillingState';
    params.zipField = 'BillingPostalCode';

    Test.setMock(HttpCalloutMock.class, new GeocodingHTTPMock(200, 'success', accounts[0].Id));

    Test.startTest();
    GeocodingInvocable.enqueueGeocodingJob(new List<GeocodingInvocable.Parameters>{ params });
    Test.stopTest();

    System.assertEquals(1, [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'Queueable']);
  }

  @isTest
  static void testEmptyRecords() {
    GeocodingInvocable.Parameters params = new GeocodingInvocable.Parameters();
    params.records = new List<SObject>(); // Empty record list
    params.streetField = 'BillingStreet';
    params.cityField = 'BillingCity';
    params.stateField = 'BillingState';
    params.zipField = 'BillingPostalCode';

    try {
      GeocodingInvocable.enqueueGeocodingJob(new List<GeocodingInvocable.Parameters>{ params });
      System.assert(false, 'Expected IllegalArgumentException was not thrown');
    } catch (IllegalArgumentException e) {
      System.assertEquals('The provided record collection is empty.', e.getMessage());
    }
  }

  @isTest
  static void testInvalidField() {
    Account account = new Account(
      Name = 'Test Account with Missing Field',
      BillingStreet = '123 Fake St',
      BillingCity = 'Faketown',
      BillingState = 'CA',
      BillingPostalCode = '12345'
    );
    insert account;

    GeocodingInvocable.Parameters params = new GeocodingInvocable.Parameters();
    params.records = new List<SObject>{ account };
    params.streetField = 'BillingStreet';
    params.cityField = 'BillingCity';
    params.stateField = 'BillingState';
    params.zipField = 'NonExistentField'; // Invalid field name

    try {
      GeocodingInvocable.enqueueGeocodingJob(new List<GeocodingInvocable.Parameters>{ params });
      System.assert(false, 'Expected IllegalArgumentException was not thrown');
    } catch (IllegalArgumentException e) {
      System.assertEquals('Field does not exist on the provided record: NonExistentField', e.getMessage());
    }
  }
}
