# LandLedger Setup Guide - Getting API Keys and Configuration

This guide will help you get all the necessary API keys and configuration for your LandLedger project.

## 🔧 Required Services and Keys

### 1. Blockchain & Web3 Services

#### **Infura (For Ethereum/Polygon Networks)**
- **What it's for**: Connecting to Ethereum mainnet, testnets, and Polygon
- **How to get**:
  1. Go to [https://infura.io](https://infura.io)
  2. Sign up for a free account
  3. Create a new project
  4. Copy your Project ID and Project Secret
- **Add to .env**:
  ```
  INFURA_PROJECT_ID="your_project_id_here"
  INFURA_PROJECT_SECRET="your_project_secret_here"
  ```

#### **Etherscan API (For Contract Verification)**
- **What it's for**: Verifying smart contracts on Ethereum
- **How to get**:
  1. Go to [https://etherscan.io/apis](https://etherscan.io/apis)
  2. Sign up and create an account
  3. Generate a free API key
- **Add to .env**:
  ```
  ETHERSCAN_API_KEY="your_etherscan_api_key"
  ```

#### **PolygonScan API (For Polygon Contract Verification)**
- **What it's for**: Verifying smart contracts on Polygon
- **How to get**:
  1. Go to [https://polygonscan.com/apis](https://polygonscan.com/apis)
  2. Sign up and create an account
  3. Generate a free API key
- **Add to .env**:
  ```
  POLYGONSCAN_API_KEY="your_polygonscan_api_key"
  ```

### 2. IPFS Services (For Document Storage)

#### **Pinata (Recommended for IPFS)**
- **What it's for**: Storing property documents on IPFS
- **How to get**:
  1. Go to [https://pinata.cloud](https://pinata.cloud)
  2. Sign up for a free account (1GB free)
  3. Go to API Keys section
  4. Generate new API key and secret
- **Add to .env**:
  ```
  PINATA_API_KEY="your_pinata_api_key"
  PINATA_SECRET_API_KEY="your_pinata_secret"
  ```

#### **Alternative: Infura IPFS**
- **What it's for**: Alternative IPFS service
- **How to get**:
  1. Same Infura account as above
  2. Enable IPFS service in your project
- **Add to .env**:
  ```
  IPFS_API_URL="https://ipfs.infura.io:5001"
  IPFS_GATEWAY_URL="https://ipfs.io/ipfs/"
  ```

### 3. Database Services

#### **Supabase (Recommended - Free tier available)**
- **What it's for**: User profiles, metadata, notifications
- **How to get**:
  1. Go to [https://supabase.com](https://supabase.com)
  2. Sign up for free account
  3. Create a new project
  4. Go to Settings > API
  5. Copy URL and anon key
- **Add to .env**:
  ```
  SUPABASE_URL="https://your-project.supabase.co"
  SUPABASE_ANON_KEY="your_anon_key"
  SUPABASE_SERVICE_ROLE_KEY="your_service_role_key"
  ```

#### **Alternative: MongoDB Atlas**
- **What it's for**: Traditional database option
- **How to get**:
  1. Go to [https://mongodb.com/atlas](https://mongodb.com/atlas)
  2. Sign up for free tier (512MB)
  3. Create cluster and get connection string
- **Add to .env**:
  ```
  MONGODB_URI="mongodb+srv://username:password@cluster.mongodb.net/landledger"
  ```

### 4. Communication Services

#### **SendGrid (For Email Notifications)**
- **What it's for**: Sending verification emails, notifications
- **How to get**:
  1. Go to [https://sendgrid.com](https://sendgrid.com)
  2. Sign up for free account (100 emails/day free)
  3. Create API key in Settings > API Keys
- **Add to .env**:
  ```
  SENDGRID_API_KEY="your_sendgrid_api_key"
  ```

#### **Twilio (For SMS Notifications)**
- **What it's for**: SMS notifications for important updates
- **How to get**:
  1. Go to [https://twilio.com](https://twilio.com)
  2. Sign up for free trial ($15 credit)
  3. Get Account SID, Auth Token, and phone number
- **Add to .env**:
  ```
  TWILIO_ACCOUNT_SID="your_account_sid"
  TWILIO_AUTH_TOKEN="your_auth_token"
  TWILIO_PHONE_NUMBER="+1234567890"
  ```

### 5. Security Keys

#### **JWT Secret (Generate Yourself)**
- **What it's for**: Securing user sessions
- **How to generate**:
  ```bash
  # Option 1: Use Node.js
  node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"
  
  # Option 2: Use online generator
  # Go to https://generate-secret.vercel.app/64
  ```
- **Add to .env**:
  ```
  JWT_SECRET="your_64_character_random_string"
  ```

#### **Encryption Key (Generate Yourself)**
- **What it's for**: Encrypting sensitive data
- **How to generate**:
  ```bash
  # Generate 32-character key
  node -e "console.log(require('crypto').randomBytes(16).toString('hex'))"
  ```
- **Add to .env**:
  ```
  ENCRYPTION_KEY="your_32_character_encryption_key"
  ```

### 6. Indian Government APIs (Optional - For Production)

#### **Aadhaar Verification API**
- **What it's for**: Verifying Aadhaar numbers
- **How to get**:
  1. Contact UIDAI or authorized service providers
  2. This requires business registration and compliance
- **Add to .env**:
  ```
  AADHAAR_API_KEY="your_aadhaar_api_key"
  ```

#### **PAN Verification API**
- **What it's for**: Verifying PAN numbers
- **How to get**:
  1. Contact Income Tax Department or authorized providers
  2. Requires business registration
- **Add to .env**:
  ```
  PAN_API_KEY="your_pan_api_key"
  ```

## 🚀 Quick Start Setup

### Step 1: Copy Environment File
```bash
cp .env.example .env
```

### Step 2: Fill in the Essential Keys (Minimum for Development)
```env
# Essential for development
NODE_ENV="development"
PORT=3000
JWT_SECRET="generate_a_64_character_random_string"
ENCRYPTION_KEY="generate_a_32_character_random_string"

# For blockchain development (get from Infura)
INFURA_PROJECT_ID="your_infura_project_id"

# For document storage (get from Pinata)
PINATA_API_KEY="your_pinata_api_key"
PINATA_SECRET_API_KEY="your_pinata_secret"

# For database (get from Supabase)
SUPABASE_URL="your_supabase_url"
SUPABASE_ANON_KEY="your_supabase_anon_key"
```

### Step 3: Test Your Setup
```bash
# Install dependencies
npm install

# Compile contracts
npx truffle compile

# Start Ganache (in another terminal)
npm run ganache

# Deploy contracts
npx truffle migrate --network development
```

## 🔒 Security Best Practices

1. **Never commit .env file to git**
   ```bash
   # Add to .gitignore
   echo ".env" >> .gitignore
   ```

2. **Use different keys for development and production**

3. **Rotate keys regularly in production**

4. **Use environment-specific configurations**

## 📞 Need Help?

If you need help getting any of these keys:

1. **Free Tier Services**: Infura, Pinata, Supabase, SendGrid - all have generous free tiers
2. **Development**: You can start with just Infura + Pinata + Supabase
3. **Production**: You'll need all services for full functionality

## 🎯 Priority Order for Setup

1. **High Priority** (needed for basic functionality):
   - Infura Project ID
   - Pinata API keys
   - Supabase credentials
   - JWT Secret

2. **Medium Priority** (needed for full features):
   - SendGrid for emails
   - Etherscan API for contract verification

3. **Low Priority** (production features):
   - Twilio for SMS
   - Indian government APIs
   - Polygon/mainnet deployment keys

Start with High Priority keys and add others as you develop more features!