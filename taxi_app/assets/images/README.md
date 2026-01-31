# Assets - Images

This directory contains image assets for the Taxi Booking App.

## Required Images

Replace the placeholder images with high-quality versions:

### 1. **header.jpg** (1200x300px)
- Used for the app header/banner
- Recommended: Gradient background with taxi/transportation theme
- Colors: Deep red (#8B0000) to warm yellow (#FFC107)

### 2. **bike.png** (128x128px)
- Icon for Bike vehicle type
- Transparent background (PNG)
- Colors: Green (#4CAF50)

### 3. **scooty.png** (128x128px)
- Icon for Scooty/Scooter vehicle type
- Transparent background (PNG)
- Colors: Orange (#FF9800)

### 4. **sedan.png** (128x128px)
- Icon for Standard/Sedan vehicle type
- Transparent background (PNG)
- Colors: Blue (#2196F3)

### 5. **suv.png** (128x128px)
- Icon for Premium/SUV vehicle type
- Transparent background (PNG)
- Colors: Red (#F44336)

## Design Guidelines

- **Format**: PNG for icons (transparency), JPG for photos
- **Resolution**: 2x and 3x variants for different screen densities
- **Color Scheme**: 
  - Primary: Deep Red (#8B0000)
  - Accent: Warm Yellow (#FFC107)
  - Secondary: Light Cream (#F5F5DC)
- **Style**: Modern, flat design with subtle shadows
- **Consistency**: Maintain consistent icon style across all vehicle types

## Placeholder Generation

If you need quick placeholders, you can use:
- **Online tools**: Placeholder.com, PlaceImg
- **Design tools**: Figma, Canva
- **Command line**: ImageMagick (`convert` command)

Example placeholder creation:
```bash
# Create a simple colored PNG (requires ImageMagick)
convert -size 128x128 xc:green bike.png
```

## Integration

Once images are added, they're automatically available via:
```dart
Image.asset('assets/images/bike.png')
```

No additional configuration needed beyond the `pubspec.yaml` entry already added.
