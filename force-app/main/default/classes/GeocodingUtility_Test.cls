/**
 * Unit tests for the GeocodingUtility class
 *
 * @author: Kerry Holsinger
 * @group: Geocoding
 * @created: Feb 2025
 */
@IsTest
public class GeocodingUtility_Test {
  /**
   * Verifies GeocodingUtility.getCensusYear() returns the custom label value or defaults to two years ago.
   */
  @IsTest
  static void testGetCensusYear() {
    String censusYear = GeocodingUtility.getCensusYear();
    if (System.Label.Geocodio_Census_Year == null) {
      // Verify that the default is two years ago
      Assert.areEqual(String.valueOf(Date.today().year() - 2), censusYear, 'Expected Census Year to be ' + String.valueOf(Date.today().year() - 2));
    } else {
      // Verify that the Census Year matchess the custom label
      Assert.areEqual(System.Label.Geocodio_Census_Year, censusYear, 'Expected Census Year to be ' + System.Label.Geocodio_Census_Year);
    }
  }
}
