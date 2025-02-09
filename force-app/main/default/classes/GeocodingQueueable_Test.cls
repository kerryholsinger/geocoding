/**
 * Unit tests for the GeocodingQueueable class
 *
 * @author: Kerry Holsinger
 * @group: Geocoding
 * @created: Feb 2025
 */
@IsTest
public class GeocodingQueueable_Test {
  /**
   * Verifies that the GeocodingQueueable job enqueues successfully
   */
  @isTest
  public static void testQueueable() {
    GeocodingInvocable.Parameters parameters = GeocodingTestDataFactory.buildParameters();
    String recordId = parameters.records[0].id;

    Test.startTest();
    Test.setMock(HttpCalloutMock.class, new GeocodingHTTPMock(200, 'success', recordId));
    GeocodingQueueable queueable = new GeocodingQueueable(parameters);
    System.enqueueJob(queueable);
    Test.stopTest();

    // Verify that a job was sucessfully enqueued
    Assert.areEqual(1, [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'Queueable'], 'Expected one job to be enqueued');
  }
}
