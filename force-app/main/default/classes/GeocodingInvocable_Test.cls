/**
 * Unit tests for the GeocodingInvocable class
 *
 * @author: Kerry Holsinger
 * @group: Geocoding
 * @created: Feb 2025
 */
@isTest
public class GeocodingInvocable_Test {
  /**
   * Verifies that a valid geocoding request enqueues a Queueable job successfully.
   */
  @isTest
  static void testSuccess() {
    GeocodingInvocable.Parameters parameters = GeocodingTestDataFactory.buildParameters();

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new GeocodingHTTPMock(200, 'success', parameters.records[0].id));
    GeocodingInvocable.enqueueJob(new List<GeocodingInvocable.Parameters>{ parameters });
    Test.stopTest();

    // Verify that a job was sucessfully enqueued
    Assert.areEqual(1, [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'Queueable'], 'Expected one job to be enqueued');
  }

  /** Verifies that an empty record collection provided in the parameters
   * triggers an IllegalArgumentException and no job is enqueued
   */
  @isTest
  static void testEmptyRecords() {
    GeocodingInvocable.Parameters parameters = GeocodingTestDataFactory.buildParameters();
    parameters.records = new List<SObject>(); // Empty record collection
    try {
      GeocodingInvocable.enqueueJob(new List<GeocodingInvocable.Parameters>{ parameters });
      // Immediately fail the test if the expected exception was not thrown
      Assert.fail('Expected IllegalArgumentException was not thrown - empty record collection');
    } catch (IllegalArgumentException e) {
      // Verify that the expected exception was thrown
      Assert.areEqual('The provided record collection is empty.', e.getMessage(), 'The expected exception was not thrown due - empty record collection');
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
    GeocodingInvocable.Parameters parameters = GeocodingTestDataFactory.buildParameters();
    parameters.zipField = 'Invalid_Field__c'; // Invalid field name
    try {
      GeocodingInvocable.enqueueJob(new List<GeocodingInvocable.Parameters>{ parameters });
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
