#!/bin/bash

# ==============================
# Interactive CSR Generator
# ==============================

# Get common certificate details once
read -p "Enter Country (C): " Country
read -p "Enter State / County / District (ST): " State
read -p "Enter City / Locality (L): " City
read -p "Enter Organization Name (O): " Organization

# Ask for domains
read -p "Enter domain names separated by commas: " DomainsInput
IFS=',' read -r -a Domains <<< "$DomainsInput"

# Get system date + hour + minute for folder suffix
CurrentDate=$(date +%d%m%y_%H%M)

# Loop through each domain
for Domain in "${Domains[@]}"; do
    Domain=$(echo $Domain | xargs)  # Trim whitespace
    SafeDomain=$(echo $Domain | sed 's/\*/wildcard/g')  # Replace * with 'wildcard'

    # Folder name includes domain + date + time (hhmm)
    Folder="./${SafeDomain}_$CurrentDate"
    mkdir -p "$Folder"

    # Ask for key size
    read -p "Enter key size for $Domain (default 2048): " KeySize
    KeySize=${KeySize:-2048}

    # Generate private key
    openssl genrsa -out "$Folder/$SafeDomain.key" $KeySize

    # Create OpenSSL config for CSR
    cat > "$Folder/csr_$SafeDomain.cnf" <<EOL
[req]
default_bits       = $KeySize
prompt             = no
default_md         = sha256
distinguished_name = dn

[dn]
C=$Country
ST=$State
L=$City
O=$Organization
CN=$Domain
EOL

    # Generate CSR
    openssl req -new -key "$Folder/$SafeDomain.key" \
        -out "$Folder/$SafeDomain.csr" \
        -config "$Folder/csr_$SafeDomain.cnf"
	
	# Delete the temporary config file
    rm -f "$ConfigPath"

    echo "✅ CSR and key generated for $Domain in folder $Folder with key size $KeySize"
done

echo "🎉 All CSRs and keys have been generated."
