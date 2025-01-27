# Geocoding Invocable Action for Salesforce  

The **Geocoding Invocable Action** is a Salesforce Queueable class that integrates with the Geocodio API to geocode addresses and update Salesforce records with location data. It is designed to work with any Salesforce object using an invocable action in Salesforce Flow.  

## Features  

- **Flexible**: Works with any object by providing address field API names.  
- **Powerful Data Retrieval**: Retrieves geocoding data such as latitude, longitude, county, ZIP+4, census tract, and FIPS code.  
- **Scalable**: Leverages asynchronous processing for reliable performance, even with high volumes of records.  
- **Easy Integration**: Can be seamlessly triggered via Salesforce Flow.  

## How It Works  

1. **Trigger Geocoding**: Use Salesforce Flow to determine when geocoding should run (e.g., record creation, update, or custom conditions).  
2. **Invocable Action**: Use the `Geocode an Address` action in Flow to enqueue a geocoding job.  
3. **API Integration**: Sends an HTTP request to the Geocodio API and processes the response.  
4. **Update Records**: Populates specified fields in the target record with geocoding results.  

## Input Parameters  

- **Required**:  
  - Record (SObject).  
  - API names of the Street, City, State, and ZIP fields.  
- **Optional**:  
  - API names for County, Latitude, Longitude, Census Tract, and FIPS Code fields.  
  - Option to include ZIP+4.  

## Setup  

1. Add your Geocodio API key to the `Geocodio_API_Key` custom label.  
2. Optionally, set a Census year in the `Geocodio_Census_Year` custom label.  
3. Use Flow to configure the `Geocode an Address` action and pass the required parameters (e.g., field API names).  
