# Geocoding Invocable Action for Salesforce

The **Geocoding Invocable Action** integrates with the Geocodio API to geocode addresses and update Salesforce records with geolocation data. Designed for use in Salesforce Flow, it works with any Salesforce object by specifying address field API names.

## Features

- **Flexible**: Works with any object by providing address field API names.
- **Automated Data Retrieval**: Retrieves geocoding data such as latitude, longitude, county, ZIP+4, census tract, and FIPS code.
- **Batch Processing**: Geocodes multiple addresses in a single call for efficiency.
- **Easy Setup**: Seamlessly integrates with Salesforce Flow with minimal configuration and setup.

## How It Works

1. **Trigger Geocoding**: Salesforce Flow determines when geocoding should run (e.g., record creation, update, or custom conditions).
2. **Invoke the Action**: The `Address Geocoding` action is called in Flow, processing a collection of records.
3. **API Call**: An HTTP request is sent to the Geocodio API, and the response is parsed.
4. **Update Records**: The specified fields in Salesforce are populated with geolocation data.

## Input Parameters

- **Required:**

  - Record collection (`List<SObject>`)
  - API names of Street, City, State, and ZIP fields

- **Optional:**
  - API names for County, Latitude, Longitude, Census Tract, and FIPS Code
  - Option to include ZIP+4 and append to the specified ZIP field

## Setup

1. **Store API Key**: Add your Geocodio API key to the `Geocodio_API_Key` custom label.
2. **Set Census Year (Optional)**: Define a census year in the `Geocodio_Census_Year` custom label.
3. **Configure Flow**: Add the `Address Geocoding` invocable action and specify address field API names.
4. **Map Data Fields**: Specify which geolocation data points to retrieve by mapping the optional parameters (e.g., set `County__c` as the `County Field API Name` to store county data).
