# 🏛️ LandLedger - Revolutionary Blockchain Land Registry for India

[![Solidity](https://img.shields.io/badge/Solidity-0.8.19-blue.svg)](https://soliditylang.org/)
[![OpenZeppelin](https://img.shields.io/badge/OpenZeppelin-4.9.3-green.svg)](https://openzeppelin.com/)
[![Truffle](https://img.shields.io/badge/Truffle-5.11.5-orange.svg)](https://trufflesuite.com/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **LandLedger** is an advanced blockchain-powered digital land registry and transfer platform designed specifically for India. It combines cutting-edge Web3 technologies with beginner-friendly interfaces to create a secure, transparent, and accessible land ownership system.

## 🌟 Key Features

### 🔐 **Advanced Security**
- **Smart Contract Security**: OpenZeppelin-based contracts with reentrancy guards, access control, and pausable functionality
- **Document Integrity**: IPFS-based tamper-proof document storage with hash verification
- **Multi-layer Authentication**: MetaMask wallet integration with role-based access control

### 🇮🇳 **Indian Compliance**
- **ULPIN Integration**: Unique Land Parcel Identification Number support
- **KYC Compliance**: Aadhar and PAN number verification
- **Multi-language Support**: Hindi and Tamil language options
- **Government Workflow**: Built-in land inspector approval process

### 🚀 **Revolutionary Technology**
- **Ethereum Smart Contracts**: Immutable and transparent property records
- **IPFS Document Storage**: Decentralized, tamper-proof document management
- **Escrow System**: Secure multi-party payment handling
- **Real-time Verification**: Instant document authenticity checks

### 👥 **User-Friendly Design**
- **Dual Interface**: Advanced features for experts, simple UI for beginners
- **Step-by-step Guidance**: Clear workflows for all user types
- **Comprehensive Help**: Context-sensitive assistance throughout

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Frontend (React)                         │
├─────────────────────────────────────────────────────────────┤
│  Seller Portal  │  Buyer Portal   │  Inspector Dashboard    │
│  Property Mgmt  │  Search & Buy   │  Verification Tools     │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                   Smart Contracts                           │
├─────────────────────────────────────────────────────────────┤
│  LandRegistry   │  EscrowManager  │  DocumentVerification   │
│  User & Property│  Secure Payments│  IPFS Integration       │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                   Blockchain & Storage                      │
├─────────────────────────────────────────────────────────────┤
│  Ethereum       │  IPFS Network   │  Traditional DB         │
│  Immutable      │  Document       │  User Metadata          │
│  Records        │  Storage        │  Analytics              │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites
- Node.js (v16 or higher)
- npm or yarn
- Git
- MetaMask browser extension

### 1. Clone the Repository
```bash
git clone https://github.com/your-username/landledger.git
cd landledger
```

### 2. Install Dependencies
```bash
npm install
```

### 3. Set Up Environment
```bash
# Copy environment template
cp .env.example .env

# Edit .env with your API keys (see SETUP_GUIDE.md)
```

### 4. Start Local Blockchain
```bash
# Terminal 1: Start Ganache
npm run ganache
```

### 5. Deploy Contracts
```bash
# Terminal 2: Deploy to local network
npx truffle migrate --network development

# Run setup script for demo data
npx truffle exec scripts/deploy-local.js --network development
```

### 6. Run Tests
```bash
npm test
```

## 📋 Smart Contracts

### LandRegistry.sol
**Main contract managing users, properties, and transactions**
- User registration and verification (Sellers, Buyers, Inspectors)
- Property listing and verification
- Purchase request and approval workflow
- Ownership transfer with inspector approval
- Comprehensive event logging

### EscrowManager.sol
**Secure multi-party payment handling**
- Escrow creation and funding
- Multi-party approval system (Buyer, Seller, Inspector)
- Automatic payment release
- Dispute resolution mechanism
- Timeout and refund handling

### DocumentVerification.sol
**IPFS-based document management**
- Document upload and verification
- Hash-based authenticity checks
- Batch document operations
- Public transparency features
- Document expiration handling

## 🧪 Testing

### Run All Tests
```bash
npm test
```

### Run Specific Test
```bash
npx truffle test test/LandRegistry.test.js
```

### Test Coverage
```bash
npm run coverage
```

## 🔧 Configuration

### Truffle Networks
- **development**: Local Ganache (default)
- **ganache**: Ganache CLI
- **goerli**: Ethereum Goerli testnet
- **polygon**: Polygon mainnet

### Environment Variables
See `SETUP_GUIDE.md` for detailed instructions on obtaining API keys.

## 📊 Demo Scenario

The platform includes a complete demo scenario:

1. **Manthan** (Seller) lists a 1500 sq ft property in Mumbai for 15 ETH
2. **Ved** (Buyer) discovers the property and requests to purchase
3. **Land Inspector** verifies all documents and approves the transaction
4. **Automatic Transfer** occurs with escrow protection
5. **Digital Deed** is generated with blockchain verification

## 🛠️ Development

### Project Structure
```
landledger/
├── contracts/              # Smart contracts
│   ├── LandRegistry.sol
│   ├── EscrowManager.sol
│   └── DocumentVerification.sol
├── migrations/             # Deployment scripts
├── test/                   # Test files
├── scripts/                # Utility scripts
├── client/                 # React frontend (coming soon)
└── docs/                   # Documentation
```

### Adding New Features
1. Write smart contract functions
2. Add comprehensive tests
3. Update migration scripts
4. Document API changes

## 🔒 Security Features

- **Access Control**: Role-based permissions with OpenZeppelin
- **Reentrancy Protection**: Guards against reentrancy attacks
- **Input Validation**: Comprehensive parameter checking
- **Emergency Controls**: Pausable contracts for emergency situations
- **Audit Trail**: Complete transaction history on blockchain

## 🌍 Indian Government Integration

- **ULPIN Support**: Unique Land Parcel Identification
- **KYC Compliance**: Aadhar and PAN verification
- **RTI Compliance**: Right to Information transparency
- **State-wise Configuration**: Customizable for different states
- **Stamp Duty Calculator**: Automated tax calculations

## 📈 Roadmap

### Phase 1: Core Platform ✅
- Smart contract development
- Basic user registration and verification
- Property listing and transfer
- IPFS document storage

### Phase 2: Advanced Features 🚧
- React frontend development
- Mobile-responsive design
- Advanced search and filtering
- Notification system

### Phase 3: Government Integration 📋
- Official API integrations
- Multi-language support
- Compliance reporting
- Production deployment

### Phase 4: Scale & Optimize 🚀
- Layer 2 integration
- Performance optimization
- Advanced analytics
- Mobile app development

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Process
1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation**: Check our [Setup Guide](SETUP_GUIDE.md)
- **Issues**: Report bugs on [GitHub Issues](https://github.com/your-username/landledger/issues)
- **Discussions**: Join our [GitHub Discussions](https://github.com/your-username/landledger/discussions)

## 🙏 Acknowledgments

- **OpenZeppelin** for secure smart contract libraries
- **Truffle Suite** for development framework
- **IPFS** for decentralized storage
- **Ethereum Foundation** for blockchain infrastructure

---

**Built with ❤️ for India's digital transformation**

*LandLedger - Making land ownership transparent, secure, and accessible for everyone.*