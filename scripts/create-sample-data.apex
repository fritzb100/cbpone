/**
 * Script to create sample CBP Sectors and Ports of Entry
 * Run this in Anonymous Apex after deploying metadata
 */

// Delete existing data (optional - comment out if you want to keep existing data)
delete [SELECT Id FROM Port_of_Entry__c];
delete [SELECT Id FROM CBP_Sector__c];

// Create CBP Sectors
List<CBP_Sector__c> sectors = new List<CBP_Sector__c>{
    new CBP_Sector__c(Name = 'Great Lakes Sector'),
    new CBP_Sector__c(Name = 'Southwest Sector'),
    new CBP_Sector__c(Name = 'Northern Border Sector'),
    new CBP_Sector__c(Name = 'Coastal Sector')
};
insert sectors;

// Map sectors by name for easy reference
Map<String, Id> sectorMap = new Map<String, Id>();
for (CBP_Sector__c sector : sectors) {
    sectorMap.put(sector.Name, sector.Id);
}

// Create Ports of Entry with realistic coordinates
List<Port_of_Entry__c> ports = new List<Port_of_Entry__c>{
    // Great Lakes Sector
    new Port_of_Entry__c(
        Name = 'Chicago O\'Hare International Airport',
        CBP_Sector__c = sectorMap.get('Great Lakes Sector'),
        Geopoint__Latitude__s = 41.9742,
        Geopoint__Longitude__s = -87.9073,
        Assessment_Status__c = 'Not Assessed'
    ),
    new Port_of_Entry__c(
        Name = 'Detroit-Windsor Tunnel',
        CBP_Sector__c = sectorMap.get('Great Lakes Sector'),
        Geopoint__Latitude__s = 42.3223,
        Geopoint__Longitude__s = -83.0466,
        Assessment_Status__c = 'Not Assessed'
    ),
    new Port_of_Entry__c(
        Name = 'Cleveland Hopkins International Airport',
        CBP_Sector__c = sectorMap.get('Great Lakes Sector'),
        Geopoint__Latitude__s = 41.4117,
        Geopoint__Longitude__s = -81.8498,
        Assessment_Status__c = 'Not Assessed'
    ),
    
    // Southwest Sector
    new Port_of_Entry__c(
        Name = 'Laredo Port of Entry',
        CBP_Sector__c = sectorMap.get('Southwest Sector'),
        Geopoint__Latitude__s = 27.5306,
        Geopoint__Longitude__s = -99.4803,
        Assessment_Status__c = 'Not Assessed'
    ),
    new Port_of_Entry__c(
        Name = 'San Diego-Tijuana Border',
        CBP_Sector__c = sectorMap.get('Southwest Sector'),
        Geopoint__Latitude__s = 32.5423,
        Geopoint__Longitude__s = -117.0382,
        Assessment_Status__c = 'Not Assessed'
    ),
    new Port_of_Entry__c(
        Name = 'El Paso Port of Entry',
        CBP_Sector__c = sectorMap.get('Southwest Sector'),
        Geopoint__Latitude__s = 31.7619,
        Geopoint__Longitude__s = -106.4850,
        Assessment_Status__c = 'Not Assessed'
    ),
    new Port_of_Entry__c(
        Name = 'Nogales Port of Entry',
        CBP_Sector__c = sectorMap.get('Southwest Sector'),
        Geopoint__Latitude__s = 31.3404,
        Geopoint__Longitude__s = -110.9342,
        Assessment_Status__c = 'Not Assessed'
    ),
    
    // Northern Border Sector
    new Port_of_Entry__c(
        Name = 'Peace Bridge - Buffalo',
        CBP_Sector__c = sectorMap.get('Northern Border Sector'),
        Geopoint__Latitude__s = 42.9069,
        Geopoint__Longitude__s = -78.9053,
        Assessment_Status__c = 'Not Assessed'
    ),
    new Port_of_Entry__c(
        Name = 'Blaine-Pacific Highway',
        CBP_Sector__c = sectorMap.get('Northern Border Sector'),
        Geopoint__Latitude__s = 48.9958,
        Geopoint__Longitude__s = -122.7479,
        Assessment_Status__c = 'Not Assessed'
    ),
    new Port_of_Entry__c(
        Name = 'Portal North Dakota',
        CBP_Sector__c = sectorMap.get('Northern Border Sector'),
        Geopoint__Latitude__s = 48.9975,
        Geopoint__Longitude__s = -102.5513,
        Assessment_Status__c = 'Not Assessed'
    ),
    
    // Coastal Sector
    new Port_of_Entry__c(
        Name = 'Port of Los Angeles/Long Beach',
        CBP_Sector__c = sectorMap.get('Coastal Sector'),
        Geopoint__Latitude__s = 33.7405,
        Geopoint__Longitude__s = -118.2720,
        Assessment_Status__c = 'Not Assessed'
    ),
    new Port_of_Entry__c(
        Name = 'Miami International Airport',
        CBP_Sector__c = sectorMap.get('Coastal Sector'),
        Geopoint__Latitude__s = 25.7959,
        Geopoint__Longitude__s = -80.2870,
        Assessment_Status__c = 'Not Assessed'
    ),
    new Port_of_Entry__c(
        Name = 'JFK International Airport',
        CBP_Sector__c = sectorMap.get('Coastal Sector'),
        Geopoint__Latitude__s = 40.6413,
        Geopoint__Longitude__s = -73.7781,
        Assessment_Status__c = 'Not Assessed'
    ),
    new Port_of_Entry__c(
        Name = 'Port of Seattle',
        CBP_Sector__c = sectorMap.get('Coastal Sector'),
        Geopoint__Latitude__s = 47.6062,
        Geopoint__Longitude__s = -122.3321,
        Assessment_Status__c = 'Not Assessed'
    )
};

insert ports;

System.debug('✅ Successfully created:');
System.debug('   - ' + sectors.size() + ' CBP Sectors');
System.debug('   - ' + ports.size() + ' Ports of Entry');
System.debug('\nSample ports by sector:');
for (CBP_Sector__c sector : sectors) {
    Integer count = [SELECT COUNT() FROM Port_of_Entry__c WHERE CBP_Sector__c = :sector.Id];
    System.debug('   - ' + sector.Name + ': ' + count + ' ports');
}
