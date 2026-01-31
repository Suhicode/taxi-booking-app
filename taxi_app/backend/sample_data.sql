-- Sample zones for Mumbai
INSERT INTO zones (name, slug, geom, base_fare, per_km, per_min, minimum_fare, surge_enabled) VALUES
(
    'South Mumbai',
    'south-mumbai',
    ST_GeomFromGeoJSON('{"type":"Polygon","coordinates":[[[72.8197,19.0200],[72.8197,19.0300],[72.8297,19.0300],[72.8297,19.0200],[72.8197,19.0200]]]}'),
    40.00,
    18.00,
    2.50,
    60.00,
    true
),
(
    'Bandra West',
    'bandra-west',
    ST_GeomFromGeoJSON('{"type":"Polygon","coordinates":[[[72.8300,19.0600],[72.8300,19.0700],[72.8400,19.0700],[72.8400,19.0600],[72.8300,19.0600]]]}'),
    35.00,
    16.00,
    2.00,
    55.00,
    false
),
(
    'Andheri East',
    'andheri-east',
    ST_GeomFromGeoJSON('{"type":"Polygon","coordinates":[[[72.8700,19.1100],[72.8700,19.1200],[72.8800,19.1200],[72.8800,19.1100],[72.8700,19.1100]]]}'),
    30.00,
    15.00,
    1.50,
    50.00,
    false
);
