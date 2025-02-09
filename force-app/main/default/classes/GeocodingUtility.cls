public class GeocodingUtility {
  public static String getCensusYear() {
    String censusYear = String.isBlank(System.Label.Geocodio_Census_Year)
      ? String.valueOf(Date.today().year() - 2) // Default to 2 years ago to ensure Census data is available
      : System.Label.Geocodio_Census_Year;
    return censusYear;
  }
}
