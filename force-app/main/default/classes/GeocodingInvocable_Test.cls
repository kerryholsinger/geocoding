/**
 * Unit tests for the GeocodingInvocable class.
 * Ensures proper validation, execution, and error handling of the invocable action.
 *
 * @author: Kerry Holsinger
 * @group: Geocoding
 * @created: Feb 2025
 */
@isTest
public class GeocodingInvocable_Test {
  private final static String BILLING_STREET_FIELD = 'BillingStreet';
  private final static String BILLING_CITY_FIELD = 'BillingCity';
  private final static String BILLING_STATE_FIELD = 'BillingState';
  private final static String BILLING_ZIP_FIELD = 'BillingPostalCode';

  /**
   * Setup test data for the invocable action.
   */
  @testSetup
  static void setupTestData() {
    Account account = new Account(
      Name = 'Test Account',
      BillingStreet = '37921 N Dilleys Rd',
      BillingCity = 'Wadsworth',
      BillingState = 'IL',
      BillingPostalCode = '60083'
    );
    insert account;
  }

  /**
   * Verifies that a valid geocoding request enqueues a Queueable job successfully.
   */
  @isTest
  static void testSuccess() {
    List<Account> accounts = [SELECT Id, BillingStreet, BillingCity, BillingState, BillingPostalCode FROM Account LIMIT 1];

    GeocodingInvocable.Parameters params = new GeocodingInvocable.Parameters();
    params.records = accounts;
    params.streetField = BILLING_STREET_FIELD;
    params.cityField = BILLING_CITY_FIELD;
    params.stateField = BILLING_STATE_FIELD;
    params.zipField = BILLING_ZIP_FIELD;

    Test.setMock(HttpCalloutMock.class, new GeocodingHTTPMock(200, 'success', accounts[0].Id));
    Test.startTest();
    GeocodingInvocable.enqueueJob(new List<GeocodingInvocable.Parameters>{ params });
    Test.stopTest();

    // Verify that a job was sucessfully enqueued
    Assert.areEqual(1, [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'Queueable'], 'Expected one job to be enqueued');
  }

  /** Verifies that an empty record collection provided in the parameters
   * triggers an IllegalArgumentException and no job is enqueued
   */
  @isTest
  static void testEmptyRecords() {
    GeocodingInvocable.Parameters params = new GeocodingInvocable.Parameters();
    params.records = new List<SObject>(); // Empty record collection
    params.streetField = BILLING_STREET_FIELD;
    params.cityField = BILLING_CITY_FIELD;
    params.stateField = BILLING_STATE_FIELD;
    params.zipField = BILLING_ZIP_FIELD;

    try {
      GeocodingInvocable.enqueueJob(new List<GeocodingInvocable.Parameters>{ params });
      // Immediately fail the test if the expected exception was not thrown
      Assert.fail('Expected IllegalArgumentException was not thrown - empty record collection');
    } catch (IllegalArgumentException e) {
      // Verify that the expected exception was thrown
      Assert.areEqual('The provided record collection is empty.', e.getMessage(), 'The expected exception was not thrown due to empty record collection');
      // Verify that no jobs were enqueued
      Assert.areEqual(0, [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'Queueable'], 'Expected no jobs to be enqueued');
    }
  }

  /**
   * Verifies that providing an invalid field name in the parameters
   * triggers an IllegalArgumentException and no job is enqueued
   */
  @isTest
  static void testInvalidField() {
    List<Account> accounts = [SELECT Id, BillingStreet, BillingCity, BillingState, BillingPostalCode FROM Account LIMIT 1];

    GeocodingInvocable.Parameters params = new GeocodingInvocable.Parameters();
    params.records = accounts;
    params.streetField = BILLING_STREET_FIELD;
    params.cityField = BILLING_CITY_FIELD;
    params.stateField = BILLING_STATE_FIELD;
    params.zipField = 'Invalid_Field__c'; // Invalid field name

    try {
      GeocodingInvocable.enqueueJob(new List<GeocodingInvocable.Parameters>{ params });
      // Immediately fail the test if the expected exception was not thrown
      Assert.fail('Expected IllegalArgumentException was not thrown - invalid field name');
    } catch (IllegalArgumentException e) {
      // Verify that the expected exception was thrown
      Assert.areEqual(
        'Field does not exist on the provided record: Invalid_Field__c',
        e.getMessage(),
        'The expected exception was not thrown due to invalid field name'
      );
      // Verify that no jobs were enqueued
      Assert.areEqual(0, [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'Queueable'], 'Expected no jobs to be enqueued');
    }
  }
}
