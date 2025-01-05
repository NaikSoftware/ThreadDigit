#!/bin/bash

# Set script to use UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Check if catalog file exists
if [ ! -f "MADEIRAA.TXT" ]; then
    echo "Error: MADEIRAA.TXT file not found"
    exit 1
fi

# Create temporary file with correct encoding
cp MADEIRAA.TXT temp.txt
dos2unix temp.txt

# Create class file with UTF-8 BOM
printf '\xEF\xBB\xBF' > madeira_catalog.dart

# Add class definition
cat >> madeira_catalog.dart << 'EOL'
// This file is generated automatically. DO NOT EDIT.

class ThreadColor {
  final String name;
  final String code;
  final int red;
  final int green;
  final int blue;
  final String catalog;

  const ThreadColor({
    required this.name,
    required this.code,
    required this.red,
    required this.green,
    required this.blue,
    required this.catalog,
  });
}

// Catalog of Madeira colors
const List<ThreadColor> madeiraColors = [
EOL

# Read and process each line
while IFS=',' read -r code catalog name red green blue; do
    # Debug output
    echo "Processing line:"
    echo "Code: '$code'"
    echo "Catalog: '$catalog'"
    echo "Name: '$name'"
    echo "RGB: '$red' '$green' '$blue'"

    # Write color entry
    printf "  ThreadColor(\n" >> madeira_catalog.dart
    printf "    code: \"%s\",\n" "${code}" >> madeira_catalog.dart
    printf "    catalog: \"%s\",\n" "${catalog}" >> madeira_catalog.dart
    printf "    name: \"%s\",\n" "${name}" >> madeira_catalog.dart
    printf "    red: %d,\n" "${red}" >> madeira_catalog.dart
    printf "    green: %d,\n" "${green}" >> madeira_catalog.dart
    printf "    blue: %d,\n" "${blue}" >> madeira_catalog.dart
    printf "  ),\n" >> madeira_catalog.dart
done < temp.txt

# Clean up
rm temp.txt

# Close the list
cat >> madeira_catalog.dart << 'EOL'
];
EOL

echo "Catalog generated successfully in madeira_catalog.dart"
