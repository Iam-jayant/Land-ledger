# Land-Ledger Mobile DApp

A decentralized real estate tokenization and marketplace platform built on Polygon blockchain with ERC-3643 compliance.

## Features

- 🏠 **Property Tokenization**: Convert real estate into compliant digital tokens
- 🔐 **ERC-3643 Compliance**: Built-in KYC/AML and regulatory compliance
- 📱 **Mobile-First**: Progressive Web App optimized for mobile devices
- ⚡ **Polygon Network**: Fast and low-cost transactions
- 🔒 **Secure Escrow**: Automated smart contract-based transactions
- 📄 **IPFS Storage**: Decentralized document and metadata storage
- 🏛️ **Legal Framework**: SPV/LLC integration for legal compliance

## Tech Stack

### Frontend
- **React 18** with TypeScript
- **Vite** for fast development and building
- **Tailwind CSS** for styling
- **Framer Motion** for animations
- **PWA** capabilities with offline support

### Web3 Integration
- **Wagmi** for React Web3 hooks
- **Viem** for Ethereum interactions
- **RainbowKit** for wallet connections
- **Ethers.js** for contract interactions

### Blockchain
- **Polygon PoS** (Mainnet & Amoy Testnet)
- **Hardhat** for smart contract development
- **OpenZeppelin** for secure contract libraries
- **ERC-3643** token standard for compliance

### Storage
- **Pinata IPFS** for decentralized metadata and document storage
- **Global CDN** for fast content delivery
- **Reliable pinning** for guaranteed persistence

## Getting Started

### Prerequisites

- Node.js 18+ and npm/yarn
- MetaMask or compatible Web3 wallet
- Polygon network access

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd land-ledger-mobile-dapp
```

2. Install dependencies:
```bash
npm install
```

3. Copy environment variables:
```bash
cp .env.example .env
```

4. Configure your environment variables in `.env`:
   - Add your private key for contract deployment
   - Configure RPC URLs for Polygon networks
   - Set up Pinata IPFS credentials (API key and JWT)
   - Add PolygonScan API key for contract verification

### Development

1. Start the development server:
```bash
npm run dev
```

2. Compile smart contracts:
```bash
npm run compile
```

3. Run tests:
```bash
npm run test
```

### Deployment

1. Deploy to Polygon testnet:
```bash
npm run deploy:testnet
```

2. Deploy to Polygon mainnet:
```bash
npm run deploy:mainnet
```

3. Build for production:
```bash
npm run build
```

## Project Structure

```
src/
├── components/          # Reusable UI components
│   └── layout/         # Layout components
├── pages/              # Page components
├── providers/          # React context providers
├── hooks/              # Custom React hooks
├── utils/              # Utility functions
├── types/              # TypeScript type definitions
├── config/             # Configuration files
└── contracts/          # Contract ABIs and addresses

contracts/              # Solidity smart contracts
scripts/               # Deployment scripts
test/                  # Contract tests
```

## Smart Contracts

The platform uses four main smart contracts:

1. **IdentityRegistry**: Manages KYC claims and user verification
2. **Compliance**: Enforces transfer restrictions and regulatory rules
3. **PropertyToken**: ERC-3643 compliant property tokens
4. **MarketplaceEscrow**: Handles secure property transactions

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Security

This project handles real-world assets and financial transactions. Please:
- Report security vulnerabilities responsibly
- Use testnet for development and testing
- Conduct thorough audits before mainnet deployment
- Follow smart contract security best practices

## Support

For questions and support:
- Create an issue in the repository
- Check the documentation
- Join our community discussions