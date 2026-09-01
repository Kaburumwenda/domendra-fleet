export interface BodyTypeOption {
  label: string
  value: string
  icon: string
}

export const bodyTypes: BodyTypeOption[] = [
  { label: 'Sedan', value: 'sedan', icon: 'mdi-car-side' },
  { label: 'SUV', value: 'suv', icon: 'mdi-car-estate' },
  { label: 'Hatchback', value: 'hatchback', icon: 'mdi-car-hatchback' },
  { label: 'Pickup Truck', value: 'pickup', icon: 'mdi-pickup-truck' },
  { label: 'Coupe', value: 'coupe', icon: 'mdi-car-sports' },
  { label: 'Convertible', value: 'convertible', icon: 'mdi-car-convertible' },
  { label: 'Wagon', value: 'wagon', icon: 'mdi-car-convertible' },
  { label: 'Van', value: 'van', icon: 'mdi-van-passenger' },
  { label: 'Minivan', value: 'minivan', icon: 'mdi-van' },
  { label: 'Box Truck', value: 'box_truck', icon: 'mdi-truck-outline' },
  { label: 'Semi Truck', value: 'semi_truck', icon: 'mdi-truck' },
  { label: 'Bus', value: 'bus', icon: 'mdi-bus' },
  { label: 'Motorcycle', value: 'motorcycle', icon: 'mdi-motorbike' },
  { label: 'Flatbed', value: 'flatbed', icon: 'mdi-truck-flatbed' },
  { label: 'Refrigerated', value: 'refrigerated', icon: 'mdi-snowflake' },
  { label: 'Crossover', value: 'crossover', icon: 'mdi-car-estate' },
]

interface CatalogEntry {
  make: string
  bodyType: string
  models: string[]
}

const catalog: CatalogEntry[] = [
  // Toyota
  { make: 'Toyota', bodyType: 'sedan', models: ['Camry', 'Corolla', 'Avalon', 'Prius', 'Crown'] },
  { make: 'Toyota', bodyType: 'suv', models: ['RAV4', 'Highlander', '4Runner', 'Sequoia', 'Land Cruiser', 'Venza', 'bZ4X'] },
  { make: 'Toyota', bodyType: 'hatchback', models: ['Yaris', 'Corolla Hatchback', 'GR Corolla'] },
  { make: 'Toyota', bodyType: 'pickup', models: ['Tacoma', 'Tundra', 'Hilux'] },
  { make: 'Toyota', bodyType: 'minivan', models: ['Sienna'] },
  { make: 'Toyota', bodyType: 'crossover', models: ['C-HR', 'Corolla Cross'] },
  { make: 'Toyota', bodyType: 'semi_truck', models: ['Hino 268', 'Hino 338', 'Hino 195', 'Hino 258LP', 'Hino L6'] },

  // Ford
  { make: 'Ford', bodyType: 'sedan', models: ['Fusion', 'Taurus'] },
  { make: 'Ford', bodyType: 'suv', models: ['Explorer', 'Edge', 'Escape', 'Expedition', 'Bronco', 'Bronco Sport'] },
  { make: 'Ford', bodyType: 'pickup', models: ['F-150', 'F-250', 'F-350', 'F-450', 'Ranger', 'Maverick'] },
  { make: 'Ford', bodyType: 'van', models: ['Transit', 'Transit Connect'] },
  { make: 'Ford', bodyType: 'box_truck', models: ['F-650', 'F-750'] },
  { make: 'Ford', bodyType: 'semi_truck', models: ['F-Max'] },
  { make: 'Ford', bodyType: 'coupe', models: ['Mustang'] },
  { make: 'Ford', bodyType: 'crossover', models: ['EcoSport'] },

  // Chevrolet
  { make: 'Chevrolet', bodyType: 'sedan', models: ['Malibu', 'Impala'] },
  { make: 'Chevrolet', bodyType: 'suv', models: ['Equinox', 'Traverse', 'Tahoe', 'Suburban', 'Blazer', 'Trailblazer'] },
  { make: 'Chevrolet', bodyType: 'pickup', models: ['Silverado 1500', 'Silverado 2500HD', 'Silverado 3500HD', 'Colorado'] },
  { make: 'Chevrolet', bodyType: 'van', models: ['Express', 'City Express'] },
  { make: 'Chevrolet', bodyType: 'coupe', models: ['Camaro', 'Corvette'] },
  { make: 'Chevrolet', bodyType: 'crossover', models: ['Trax', 'Spark'] },

  // Ram
  { make: 'Ram', bodyType: 'pickup', models: ['1500', '2500', '3500', '1500 Classic', 'TRX'] },
  { make: 'Ram', bodyType: 'van', models: ['Promaster', 'Promaster City', 'Promaster 1500', 'Promaster 2500'] },

  // GMC
  { make: 'GMC', bodyType: 'pickup', models: ['Sierra 1500', 'Sierra 2500HD', 'Sierra 3500HD', 'Canyon'] },
  { make: 'GMC', bodyType: 'suv', models: ['Terrain', 'Acadia', 'Yukon', 'Yukon XL', 'Hummer EV'] },
  { make: 'GMC', bodyType: 'van', models: ['Savana'] },

  // Honda
  { make: 'Honda', bodyType: 'sedan', models: ['Accord', 'Civic', 'Insight'] },
  { make: 'Honda', bodyType: 'suv', models: ['CR-V', 'Pilot', 'HR-V', 'Passport', 'Element'] },
  { make: 'Honda', bodyType: 'hatchback', models: ['Fit', 'Civic Hatchback'] },
  { make: 'Honda', bodyType: 'minivan', models: ['Odyssey'] },
  { make: 'Honda', bodyType: 'pickup', models: ['Ridgeline'] },
  { make: 'Honda', bodyType: 'coupe', models: ['Civic Coupe'] },

  // Nissan
  { make: 'Nissan', bodyType: 'sedan', models: ['Altima', 'Sentra', 'Maxima', 'Versa'] },
  { make: 'Nissan', bodyType: 'suv', models: ['Rogue', 'Murano', 'Pathfinder', 'Armada', 'Kicks', 'Ariya'] },
  { make: 'Nissan', bodyType: 'pickup', models: ['Frontier', 'Titan', 'Titan XD'] },
  { make: 'Nissan', bodyType: 'van', models: ['NV200', 'NV Cargo', 'NV Passenger'] },
  { make: 'Nissan', bodyType: 'coupe', models: ['370Z', '400Z'] },

  // Mazda
  { make: 'Mazda', bodyType: 'sedan', models: ['Mazda3', 'Mazda6'] },
  { make: 'Mazda', bodyType: 'suv', models: ['CX-3', 'CX-30', 'CX-5', 'CX-9', 'CX-50', 'CX-90'] },
  { make: 'Mazda', bodyType: 'hatchback', models: ['Mazda3 Hatchback'] },
  { make: 'Mazda', bodyType: 'coupe', models: ['MX-5 Miata'] },

  // Jeep
  { make: 'Jeep', bodyType: 'suv', models: ['Wrangler', 'Grand Cherokee', 'Cherokee', 'Compass', 'Renegade', 'Gladiator'] },
  { make: 'Jeep', bodyType: 'pickup', models: ['Gladiator', 'Scrambler'] },

  // Suzuki
  { make: 'Suzuki', bodyType: 'sedan', models: ['Swift', 'Dzire', 'Ciaz'] },
  { make: 'Suzuki', bodyType: 'suv', models: ['Vitara', 'S-Cross', 'Jimny', 'Grand Vitara'] },
  { make: 'Suzuki', bodyType: 'hatchback', models: ['Swift', 'Alto', 'Baleno', 'Celerio'] },
  { make: 'Suzuki', bodyType: 'pickup', models: ['Equator'] },
  { make: 'Suzuki', bodyType: 'motorcycle', models: ['GSX-R1000', 'Hayabusa', 'V-Strom 650'] },

  // Subaru
  { make: 'Subaru', bodyType: 'sedan', models: ['Impreza', 'Legacy', 'WRX'] },
  { make: 'Subaru', bodyType: 'suv', models: ['Outback', 'Forester', 'Crosstrek', 'Ascent', 'Solterra'] },
  { make: 'Subaru', bodyType: 'hatchback', models: ['Impreza Hatchback', 'Crosstrek'] },
  { make: 'Subaru', bodyType: 'coupe', models: ['BRZ', 'WRX'] },
  { make: 'Subaru', bodyType: 'wagon', models: ['Levorg'] },

  // Lexus
  { make: 'Lexus', bodyType: 'sedan', models: ['IS', 'ES', 'GS', 'LS'] },
  { make: 'Lexus', bodyType: 'suv', models: ['UX', 'NX', 'RX', 'GX', 'LX', 'RZ', 'TX'] },
  { make: 'Lexus', bodyType: 'coupe', models: ['RC', 'LC'] },
  { make: 'Lexus', bodyType: 'convertible', models: ['LC Convertible'] },
  { make: 'Lexus', bodyType: 'hatchback', models: ['CT 200h'] },

  // Acura
  { make: 'Acura', bodyType: 'sedan', models: ['Integra', 'TLX', 'TLX Type S'] },
  { make: 'Acura', bodyType: 'suv', models: ['RDX', 'MDX', 'ZDX'] },
  { make: 'Acura', bodyType: 'coupe', models: ['Integra A-Spec'] },

  // Infiniti
  { make: 'Infiniti', bodyType: 'sedan', models: ['Q50', 'Q60', 'Q70'] },
  { make: 'Infiniti', bodyType: 'suv', models: ['QX50', 'QX55', 'QX60', 'QX80'] },
  { make: 'Infiniti', bodyType: 'coupe', models: ['Q60'] },

  // Mercedes-Benz
  { make: 'Mercedes-Benz', bodyType: 'sedan', models: ['C-Class', 'E-Class', 'S-Class', 'CLA', 'A-Class'] },
  { make: 'Mercedes-Benz', bodyType: 'suv', models: ['GLA', 'GLB', 'GLC', 'GLE', 'GLS', 'G-Class', 'EQB', 'EQE', 'EQS'] },
  { make: 'Mercedes-Benz', bodyType: 'coupe', models: ['C-Class Coupe', 'E-Class Coupe', 'CLS'] },
  { make: 'Mercedes-Benz', bodyType: 'convertible', models: ['SL', 'C-Class Cabriolet', 'E-Class Cabriolet'] },
  { make: 'Mercedes-Benz', bodyType: 'van', models: ['Sprinter', 'Metris'] },
  { make: 'Mercedes-Benz', bodyType: 'semi_truck', models: ['Actros', 'Arocs', 'Atego'] },

  // BMW
  { make: 'BMW', bodyType: 'sedan', models: ['2 Series', '3 Series', '5 Series', '7 Series', '8 Series'] },
  { make: 'BMW', bodyType: 'suv', models: ['X1', 'X2', 'X3', 'X4', 'X5', 'X6', 'X7', 'XM', 'iX'] },
  { make: 'BMW', bodyType: 'coupe', models: ['2 Series Coupe', '4 Series Coupe', '8 Series Coupe'] },
  { make: 'BMW', bodyType: 'convertible', models: ['Z4', '4 Series Convertible', '8 Series Convertible'] },
  { make: 'BMW', bodyType: 'hatchback', models: ['1 Series'] },

  // Audi
  { make: 'Audi', bodyType: 'sedan', models: ['A3', 'A4', 'A6', 'A8', 'S3', 'S4', 'S6', 'RS6'] },
  { make: 'Audi', bodyType: 'suv', models: ['Q3', 'Q4 e-tron', 'Q5', 'Q7', 'Q8', 'e-tron', 'SQ5', 'RS Q8'] },
  { make: 'Audi', bodyType: 'coupe', models: ['A5 Coupe', 'TT', 'R8'] },
  { make: 'Audi', bodyType: 'convertible', models: ['A5 Cabriolet', 'TT Roadster'] },
  { make: 'Audi', bodyType: 'wagon', models: ['A4 Avant', 'A6 Avant', 'RS6 Avant'] },

  // Volkswagen
  { make: 'Volkswagen', bodyType: 'sedan', models: ['Jetta', 'Passat', 'Arteon', 'Virtus'] },
  { make: 'Volkswagen', bodyType: 'suv', models: ['Tiguan', 'Atlas', 'Taos', 'Touareg', 'ID.4'] },
  { make: 'Volkswagen', bodyType: 'hatchback', models: ['Golf', 'Polo', 'Golf GTI', 'Golf R'] },
  { make: 'Volkswagen', bodyType: 'van', models: ['Transporter', 'Crafter', 'Caddy', 'ID. Buzz'] },
  { make: 'Volkswagen', bodyType: 'wagon', models: ['Golf SportWagen'] },
  { make: 'Volkswagen', bodyType: 'semi_truck', models: ['Man eTGM'] },

  // Porsche
  { make: 'Porsche', bodyType: 'sedan', models: ['Taycan', 'Panamera'] },
  { make: 'Porsche', bodyType: 'suv', models: ['Macan', 'Cayenne', 'Cayenne Coupe'] },
  { make: 'Porsche', bodyType: 'coupe', models: ['911', '718 Cayman', '918 Spyder'] },
  { make: 'Porsche', bodyType: 'convertible', models: ['718 Boxster', '911 Cabriolet'] },
  { make: 'Porsche', bodyType: 'wagon', models: ['Panamera Sport Turismo'] },

  // Land Rover
  { make: 'Land Rover', bodyType: 'suv', models: ['Range Rover', 'Range Rover Sport', 'Range Rover Velar', 'Range Rover Evoque', 'Discovery', 'Discovery Sport', 'Defender'] },

  // Jaguar
  { make: 'Jaguar', bodyType: 'sedan', models: ['XE', 'XF', 'XJ'] },
  { make: 'Jaguar', bodyType: 'suv', models: ['E-Pace', 'F-Pace', 'I-Pace'] },
  { make: 'Jaguar', bodyType: 'coupe', models: ['F-Type'] },
  { make: 'Jaguar', bodyType: 'convertible', models: ['F-Type Convertible'] },

  // Volvo (cars)
  { make: 'Volvo', bodyType: 'sedan', models: ['S60', 'S90'] },
  { make: 'Volvo', bodyType: 'suv', models: ['XC40', 'XC60', 'XC90', 'EX30', 'EX90', 'C40 Recharge'] },
  { make: 'Volvo', bodyType: 'wagon', models: ['V60', 'V90'] },
  { make: 'Volvo', bodyType: 'semi_truck', models: ['VNL 860', 'VNR', 'VHD', 'FH16', 'FMX', 'FH', 'FM'] },

  // Buick
  { make: 'Buick', bodyType: 'sedan', models: ['LaCrosse'] },
  { make: 'Buick', bodyType: 'suv', models: ['Encore', 'Encore GX', 'Envision', 'Enclave'] },

  // Cadillac
  { make: 'Cadillac', bodyType: 'sedan', models: ['CT4', 'CT5', 'CT5-V Blackwing'] },
  { make: 'Cadillac', bodyType: 'suv', models: ['XT4', 'XT5', 'XT6', 'Escalade', 'Lyriq'] },
  { make: 'Cadillac', bodyType: 'coupe', models: ['CT5-V'] },

  // Lincoln
  { make: 'Lincoln', bodyType: 'sedan', models: ['MKZ', 'Continental'] },
  { make: 'Lincoln', bodyType: 'suv', models: ['Corsair', 'Nautilus', 'Aviator', 'Navigator'] },

  // Chrysler
  { make: 'Chrysler', bodyType: 'sedan', models: ['300'] },
  { make: 'Chrysler', bodyType: 'minivan', models: ['Pacifica', 'Voyager'] },

  // Dodge
  { make: 'Dodge', bodyType: 'sedan', models: ['Charger'] },
  { make: 'Dodge', bodyType: 'coupe', models: ['Challenger'] },
  { make: 'Dodge', bodyType: 'suv', models: ['Durango', 'Journey'] },
  { make: 'Dodge', bodyType: 'minivan', models: ['Grand Caravan'] },
  { make: 'Dodge', bodyType: 'pickup', models: ['Dakota', 'Ram 1500 Classic'] },

  // Hyundai
  { make: 'Hyundai', bodyType: 'sedan', models: ['Elantra', 'Sonata', 'Accent', 'Ioniq 6'] },
  { make: 'Hyundai', bodyType: 'suv', models: ['Tucson', 'Santa Fe', 'Palisade', 'Kona', 'Venue', 'Ioniq 5'] },
  { make: 'Hyundai', bodyType: 'hatchback', models: ['Veloster', 'i20', 'Ioniq'] },
  { make: 'Hyundai', bodyType: 'coupe', models: ['Veloster N'] },
  { make: 'Hyundai', bodyType: 'minivan', models: ['Staria'] },

  // Kia
  { make: 'Kia', bodyType: 'sedan', models: ['Forte', 'K5', 'Rio', 'Stinger', 'EV6'] },
  { make: 'Kia', bodyType: 'suv', models: ['Sportage', 'Sorento', 'Telluride', 'Seltos', 'Niro', 'Soul'] },
  { make: 'Kia', bodyType: 'hatchback', models: ['Rio 5-Door', 'Ceed'] },
  { make: 'Kia', bodyType: 'minivan', models: ['Carnival', 'Sedona'] },
  { make: 'Kia', bodyType: 'coupe', models: ['Stinger GT'] },

  // Genesis
  { make: 'Genesis', bodyType: 'sedan', models: ['G70', 'G80', 'G90', 'Electrified G80'] },
  { make: 'Genesis', bodyType: 'suv', models: ['GV70', 'GV80', 'GV60', 'Electrified GV70'] },
  { make: 'Genesis', bodyType: 'coupe', models: ['G70 3.3T'] },

  // Tesla
  { make: 'Tesla', bodyType: 'sedan', models: ['Model 3', 'Model S'] },
  { make: 'Tesla', bodyType: 'suv', models: ['Model Y', 'Model X'] },
  { make: 'Tesla', bodyType: 'pickup', models: ['Cybertruck'] },
  { make: 'Tesla', bodyType: 'coupe', models: ['Roadster'] },

  // Mitsubishi
  { make: 'Mitsubishi', bodyType: 'sedan', models: ['Mirage', 'Lancer', 'Attrage'] },
  { make: 'Mitsubishi', bodyType: 'suv', models: ['Outlander', 'Outlander Sport', 'Eclipse Cross'] },
  { make: 'Mitsubishi', bodyType: 'hatchback', models: ['Mirage Hatchback', 'i-MiEV'] },
  { make: 'Mitsubishi', bodyType: 'pickup', models: ['L200', 'Triton', 'Raider', 'Strada'] },
  { make: 'Mitsubishi', bodyType: 'minivan', models: ['Delica'] },

  // Isuzu
  { make: 'Isuzu', bodyType: 'box_truck', models: ['NPR', 'NQR', 'NRR', 'FTR', 'FVR'] },
  { make: 'Isuzu', bodyType: 'semi_truck', models: ['F-Series', 'C-Series', 'E-Series'] },
  { make: 'Isuzu', bodyType: 'pickup', models: ['D-Max', 'Hombre'] },
  { make: 'Isuzu', bodyType: 'suv', models: ['MU-X', 'Trooper'] },

  // Hino
  { make: 'Hino', bodyType: 'semi_truck', models: ['268', '338', '195', '258LP', 'L6', '268A', '3384'] },
  { make: 'Hino', bodyType: 'box_truck', models: ['195', '258', '268', '338'] },

  // Freightliner
  { make: 'Freightliner', bodyType: 'semi_truck', models: ['Cascadia', 'Coronado', 'M2 106', '114SD', '122SD', '108SD', 'Business Class'] },
  { make: 'Freightliner', bodyType: 'box_truck', models: ['M2 106 Box', 'M2 112'] },

  // Kenworth
  { make: 'Kenworth', bodyType: 'semi_truck', models: ['T680', 'T880', 'W990', 'T680 Next Gen', 'PACCAR PX', 'T270', 'T370', 'T440'] },
  { make: 'Kenworth', bodyType: 'box_truck', models: ['K270', 'K370'] },

  // Peterbilt
  { make: 'Peterbilt', bodyType: 'semi_truck', models: ['579', '567', '389', '579EV', '220 EV'] },
  { make: 'Peterbilt', bodyType: 'box_truck', models: ['220', '330', '337', '348'] },

  // International (Navistar)
  { make: 'International', bodyType: 'semi_truck', models: ['LT Series', 'HX Series', 'MV Series', 'RH Series', '9900i', 'LT860'] },
  { make: 'International', bodyType: 'box_truck', models: ['MV607', 'HV507'] },

  // Scania
  { make: 'Scania', bodyType: 'semi_truck', models: ['S-Series', 'R-Series', 'G-Series', 'P-Series'] },
  { make: 'Scania', bodyType: 'bus', models: ['Citywide', 'Interlink'] },

  // MAN
  { make: 'MAN', bodyType: 'semi_truck', models: ['TGX', 'TGS', 'TGL', 'TGM', 'eTGM'] },
  { make: 'MAN', bodyType: 'bus', models: ['Lion City', 'Lion Coach'] },

  // DAF
  { make: 'DAF', bodyType: 'semi_truck', models: ['XF', 'XG', 'XG+', 'CF', 'LF'] },
  { make: 'DAF', bodyType: 'box_truck', models: ['LF Box', 'CF Box'] },

  // Stellantis / European brands
  { make: 'Fiat', bodyType: 'sedan', models: ['Tipo', '500'] },
  { make: 'Fiat', bodyType: 'hatchback', models: ['500', 'Panda', 'Punto'] },
  { make: 'Fiat', bodyType: 'suv', models: ['500X', 'Pulse'] },
  { make: 'Fiat', bodyType: 'van', models: ['Doblo', 'Ducato', 'Talento'] },
  { make: 'Fiat', bodyType: 'convertible', models: ['500C', '124 Spider'] },

  { make: 'Alfa Romeo', bodyType: 'sedan', models: ['Giulia'] },
  { make: 'Alfa Romeo', bodyType: 'suv', models: ['Stelvio', 'Tonale'] },
  { make: 'Alfa Romeo', bodyType: 'coupe', models: ['4C'] },

  { make: 'Mini', bodyType: 'hatchback', models: ['Cooper', 'Cooper SE', 'Cooper S'] },
  { make: 'Mini', bodyType: 'suv', models: ['Countryman', 'Countryman SE'] },
  { make: 'Mini', bodyType: 'convertible', models: ['Cooper Convertible'] },
  { make: 'Mini', bodyType: 'coupe', models: ['Cooper Coupe'] },

  { make: 'Peugeot', bodyType: 'sedan', models: ['508', '308', '301'] },
  { make: 'Peugeot', bodyType: 'hatchback', models: ['208', '308'] },
  { make: 'Peugeot', bodyType: 'suv', models: ['2008', '3008', '5008', 'e-2008'] },
  { make: 'Peugeot', bodyType: 'van', models: ['Partner', 'Expert', 'Boxer'] },
  { make: 'Peugeot', bodyType: 'wagon', models: ['508 SW'] },

  { make: 'Renault', bodyType: 'sedan', models: ['Megane', 'Latitude', 'Fluence'] },
  { make: 'Renault', bodyType: 'hatchback', models: ['Clio', 'Megane', 'Zoe'] },
  { make: 'Renault', bodyType: 'suv', models: ['Captur', 'Kadjar', 'Arkana', 'Austral', 'Koleos', 'Megane E-Tech'] },
  { make: 'Renault', bodyType: 'van', models: ['Kangoo', 'Trafic', 'Master'] },
  { make: 'Renault', bodyType: 'semi_truck', models: ['T High', 'T 520', 'K Series'] },

  { make: 'Citroen', bodyType: 'sedan', models: ['C4', 'C5', 'C-Elysee'] },
  { make: 'Citroen', bodyType: 'hatchback', models: ['C1', 'C3', 'C4'] },
  { make: 'Citroen', bodyType: 'suv', models: ['C3 Aircross', 'C5 Aircross'] },
  { make: 'Citroen', bodyType: 'van', models: ['Berlingo', 'Jumper', 'Jumpy'] },

  { make: 'Skoda', bodyType: 'sedan', models: ['Octavia', 'Superb', 'Scala'] },
  { make: 'Skoda', bodyType: 'hatchback', models: ['Fabia', 'Citigo'] },
  { make: 'Skoda', bodyType: 'suv', models: ['Kamiq', 'Karoq', 'Kodiaq', 'Enyaq'] },
  { make: 'Skoda', bodyType: 'wagon', models: ['Octavia Combi', 'Superb Combi'] },

  { make: 'Seat', bodyType: 'sedan', models: ['Toledo'] },
  { make: 'Seat', bodyType: 'hatchback', models: ['Ibiza', 'Leon'] },
  { make: 'Seat', bodyType: 'suv', models: ['Arona', 'Ateca', 'Tarraco'] },

  { make: 'Dacia', bodyType: 'sedan', models: ['Logan'] },
  { make: 'Dacia', bodyType: 'hatchback', models: ['Sandero'] },
  { make: 'Dacia', bodyType: 'suv', models: ['Duster', 'Jogger', 'Spring'] },

  { make: 'Opel', bodyType: 'sedan', models: ['Astra', 'Insignia'] },
  { make: 'Opel', bodyType: 'hatchback', models: ['Corsa', 'Astra', 'Karl'] },
  { make: 'Opel', bodyType: 'suv', models: ['Mokka', 'Grandland', 'Crossland', 'Frontera'] },
  { make: 'Opel', bodyType: 'van', models: ['Combo', 'Vivaro', 'Movano'] },

  // Luxury / exotic
  { make: 'Maserati', bodyType: 'sedan', models: ['Ghibli', 'Quattroporte'] },
  { make: 'Maserati', bodyType: 'suv', models: ['Levante', 'Grecale', 'MC20'] },
  { make: 'Maserati', bodyType: 'coupe', models: ['MC20', 'GranTurismo'] },
  { make: 'Maserati', bodyType: 'convertible', models: ['GranCabrio', 'MC20 Cielo'] },

  { make: 'Bentley', bodyType: 'sedan', models: ['Flying Spur', 'Continental GT'] },
  { make: 'Bentley', bodyType: 'suv', models: ['Bentayga'] },
  { make: 'Bentley', bodyType: 'coupe', models: ['Continental GT'] },
  { make: 'Bentley', bodyType: 'convertible', models: ['Continental GTC'] },

  { make: 'Rolls-Royce', bodyType: 'sedan', models: ['Ghost', 'Phantom', 'Spectre'] },
  { make: 'Rolls-Royce', bodyType: 'coupe', models: ['Wraith', 'Dawn'] },
  { make: 'Rolls-Royce', bodyType: 'suv', models: ['Cullinan'] },
  { make: 'Rolls-Royce', bodyType: 'convertible', models: ['Dawn'] },

  { make: 'Ferrari', bodyType: 'coupe', models: ['Roma', '296 GTB', 'SF90 Stradale', '812'] },
  { make: 'Ferrari', bodyType: 'convertible', models: ['Roma Spider', '812 GTS', '296 GTS'] },
  { make: 'Ferrari', bodyType: 'suv', models: ['Purosangue'] },

  { make: 'Lamborghini', bodyType: 'coupe', models: ['Huracan', 'Revuelto', 'Aventador'] },
  { make: 'Lamborghini', bodyType: 'suv', models: ['Urus', 'Urus Performante'] },
  { make: 'Lamborghini', bodyType: 'convertible', models: ['Huracan Spyder'] },

  { make: 'Aston Martin', bodyType: 'coupe', models: ['Vantage', 'DB11', 'DB12'] },
  { make: 'Aston Martin', bodyType: 'convertible', models: ['Vantage Roadster', 'DB12 Volante'] },
  { make: 'Aston Martin', bodyType: 'suv', models: ['DBX', 'DBX707'] },
  { make: 'Aston Martin', bodyType: 'sedan', models: ['Rapide'] },

  // EV specialists
  { make: 'Lucid', bodyType: 'sedan', models: ['Air', 'Air Pure', 'Air Touring', 'Air Grand Touring', 'Air Sapphire'] },
  { make: 'Lucid', bodyType: 'suv', models: ['Gravity'] },

  { make: 'Rivian', bodyType: 'pickup', models: ['R1T', 'R2T'] },
  { make: 'Rivian', bodyType: 'suv', models: ['R1S', 'R2S'] },
  { make: 'Rivian', bodyType: 'van', models: ['EDV', 'Commercial Van'] },

  { make: 'Polestar', bodyType: 'sedan', models: ['Polestar 2', 'Polestar 3'] },
  { make: 'Polestar', bodyType: 'suv', models: ['Polestar 3', 'Polestar 4'] },
  { make: 'Polestar', bodyType: 'coupe', models: ['Polestar 5'] },

  { make: 'Nio', bodyType: 'sedan', models: ['ET5', 'ET7'] },
  { make: 'Nio', bodyType: 'suv', models: ['ES6', 'ES7', 'ES8', 'EC6', 'EC7', 'EL7', 'EL8'] },
  { make: 'Nio', bodyType: 'coupe', models: ['ET5'] },

  { make: 'Xpeng', bodyType: 'sedan', models: ['P7', 'P5'] },
  { make: 'Xpeng', bodyType: 'suv', models: ['G3', 'G9'] },

  { make: 'BYD', bodyType: 'sedan', models: ['Han EV', 'Seal', 'Dolphin'] },
  { make: 'BYD', bodyType: 'suv', models: ['Tang', 'Atto 3', 'Yuan Plus', 'Seal U'] },
  { make: 'BYD', bodyType: 'hatchback', models: ['Dolphin'] },
  { make: 'BYD', bodyType: 'pickup', models: ['Shark', 'P1'] },

  { make: 'Fisker', bodyType: 'sedan', models: ['Ocean'] },
  { make: 'Fisker', bodyType: 'suv', models: ['Ocean', 'Pear'] },

  // Indian / emerging makes
  { make: 'Tata', bodyType: 'sedan', models: ['Tigor', 'Tiago'] },
  { make: 'Tata', bodyType: 'hatchback', models: ['Tiago', 'Altroz', 'Nano'] },
  { make: 'Tata', bodyType: 'suv', models: ['Nexon', 'Harrier', 'Safari', 'Punch', 'Hexa'] },
  { make: 'Tata', bodyType: 'pickup', models: ['Xenon', 'Tamo Racer'] },
  { make: 'Tata', bodyType: 'semi_truck', models: ['Prima', 'LPT', 'Signa', 'Ace'] },

  { make: 'Mahindra', bodyType: 'suv', models: ['Scorpio', 'Scorpio-N', 'XUV500', 'XUV700', 'Thar', 'Bolero', 'KUV100', 'Marazzo'] },
  { make: 'Mahindra', bodyType: 'pickup', models: ['Scorpio Getaway', 'Bolero Pik-Up'] },
  { make: 'Mahindra', bodyType: 'hatchback', models: ['KUV100'] },
  { make: 'Mahindra', bodyType: 'minivan', models: ['Marazzo'] },

  { make: 'Maruti Suzuki', bodyType: 'sedan', models: ['Dzire', 'Ciaz'] },
  { make: 'Maruti Suzuki', bodyType: 'hatchback', models: ['Swift', 'Baleno', 'Alto', 'Wagon R', 'Celerio', 'Ignis'] },
  { make: 'Maruti Suzuki', bodyType: 'suv', models: ['Vitara Brezza', 'Grand Vitara', 'S-Cross', 'Jimny', 'Fronx'] },
  { make: 'Maruti Suzuki', bodyType: 'minivan', models: ['Ertiga', 'XL6'] },

  // Motorcycle makes (body_type motorcycle)
  { make: 'Harley-Davidson', bodyType: 'motorcycle', models: ['Sportster', 'Softail', 'Road Glide', 'Street Glide', 'Electra Glide', 'LiveWire', 'Pan America'] },
  { make: 'Honda', bodyType: 'motorcycle', models: ['CBR1000RR', 'Gold Wing', 'Africa Twin', 'CB650R', 'Rebel 1100', 'CB300R'] },
  { make: 'Yamaha', bodyType: 'motorcycle', models: ['YZF-R1', 'MT-07', 'MT-09', 'XSR900', 'Tracer 9', 'Tenere 700'] },
  { make: 'Kawasaki', bodyType: 'motorcycle', models: ['Ninja 400', 'Ninja ZX-10R', 'Z900', 'Versys 650', 'KLR650', 'Concours 14'] },
  { make: 'Ducati', bodyType: 'motorcycle', models: ['Panigale V4', 'Monster', 'Multistrada V4', 'Scrambler', 'Streetfighter V4', 'Diavel'] },
  { make: 'BMW', bodyType: 'motorcycle', models: ['R 1250 GS', 'S 1000 RR', 'F 750 GS', 'R 18', 'K 1600 GTL'] },
  { make: 'KTM', bodyType: 'motorcycle', models: ['390 Duke', '890 Duke', '1290 Super Duke', '390 Adventure', '890 Adventure', 'RC 390'] },
  { make: 'Triumph', bodyType: 'motorcycle', models: ['Bonneville T120', 'Street Triple', 'Tiger 900', 'Rocket 3', 'Speed Twin', 'Scrambler 1200'] },
  { make: 'Indian', bodyType: 'motorcycle', models: ['Chief', 'Scout', 'Chieftain', 'Roadmaster', 'FTR 1200', 'Pursuit'] },
  { make: 'Royal Enfield', bodyType: 'motorcycle', models: ['Classic 350', 'Meteor 350', 'Interceptor 650', 'Continental GT 650', 'Himalayan', 'Hunter 350'] },

  // Commercial / bus
  { make: 'Blue Bird', bodyType: 'bus', models: ['Vision', 'Vision Activity Bus', 'All American'] },
  { make: 'Thomas Built', bodyType: 'bus', models: ['Saf-T-Liner C2', 'Saf-T-Liner EFx'] },
  { make: 'IC Bus', bodyType: 'bus', models: ['CE Series', 'RE Series'] },
  { make: 'Nova Bus', bodyType: 'bus', models: ['LFS', 'LFSe'] },
  { make: 'New Flyer', bodyType: 'bus', models: ['Xcelsior', 'Xcelsior CHARGE'] },
  { make: 'Mercedes-Benz', bodyType: 'bus', models: ['Citaro', 'Sprinter Minibus', 'Tourismo'] },
  { make: 'Volkswagen', bodyType: 'bus', models: ['Transporter Van', 'Microbus'] },
]

export const vehicleCatalog = catalog

export function catalogMakes(): string[] {
  return Array.from(new Set(catalog.map((c) => c.make))).sort()
}

export function bodyTypesForMake(make: string): BodyTypeOption[] {
  const values = new Set(
    catalog.filter((c) => c.make === make).map((c) => c.bodyType)
  )
  return bodyTypes.filter((b) => values.has(b.value))
}

export function modelsForMakeBodyType(make: string, bodyType: string): string[] {
  const entry = catalog.find((c) => c.make === make && c.bodyType === bodyType)
  return entry ? entry.models : []
}

export function bodyTypeIcon(value: string): string {
  return bodyTypes.find((b) => b.value === value)?.icon || 'mdi-car'
}
