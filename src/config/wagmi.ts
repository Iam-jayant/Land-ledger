import { configureChains, createConfig } from 'wagmi'
import { polygon, polygonMumbai } from 'wagmi/chains'
import { publicProvider } from 'wagmi/providers/public'
import { jsonRpcProvider } from 'wagmi/providers/jsonRpc'
import { getDefaultWallets } from '@rainbow-me/rainbowkit'

// Define Polygon Amoy testnet (replacing Mumbai)
export const polygonAmoy = {
  id: 80002,
  name: 'Polygon Amoy Testnet',
  network: 'polygon-amoy',
  nativeCurrency: {
    decimals: 18,
    name: 'MATIC',
    symbol: 'MATIC',
  },
  rpcUrls: {
    public: { http: ['https://rpc-amoy.polygon.technology/'] },
    default: { http: ['https://rpc-amoy.polygon.technology/'] },
  },
  blockExplorers: {
    default: { name: 'PolygonScan', url: 'https://amoy.polygonscan.com' },
  },
  testnet: true,
} as const

// Configure chains - Polygon mainnet and Amoy testnet only
export const { chains, publicClient, webSocketPublicClient } = configureChains(
  [polygon, polygonAmoy],
  [
    jsonRpcProvider({
      rpc: (chain) => {
        if (chain.id === polygon.id) {
          return {
            http: import.meta.env.VITE_POLYGON_MAINNET_RPC || 'https://polygon-rpc.com/',
          }
        }
        if (chain.id === polygonAmoy.id) {
          return {
            http: import.meta.env.VITE_POLYGON_TESTNET_RPC || 'https://rpc-amoy.polygon.technology/',
          }
        }
        return null
      },
    }),
    publicProvider(),
  ]
)

// Configure wallets
const { connectors } = getDefaultWallets({
  appName: 'Land-Ledger Mobile DApp',
  projectId: import.meta.env.VITE_WALLET_CONNECT_PROJECT_ID || 'your_project_id',
  chains,
})

// Create wagmi config
export const wagmiConfig = createConfig({
  autoConnect: true,
  connectors,
  publicClient,
  webSocketPublicClient,
})

// Export chain configurations for easy access
export const SUPPORTED_CHAINS = {
  POLYGON_MAINNET: polygon.id,
  POLYGON_TESTNET: polygonAmoy.id,
} as const

// Default chain for development
export const DEFAULT_CHAIN = polygonAmoy