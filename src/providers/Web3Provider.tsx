import React, { createContext, useContext, useEffect, useState } from 'react'
import { useAccount, useNetwork, useSwitchNetwork } from 'wagmi'
import { polygon } from 'wagmi/chains'
import { polygonAmoy, SUPPORTED_CHAINS } from '../config/wagmi'
import toast from 'react-hot-toast'

interface Web3ContextType {
  isConnected: boolean
  address: string | undefined
  chainId: number | undefined
  isCorrectNetwork: boolean
  switchToPolygon: () => Promise<void>
  switchToPolygonTestnet: () => Promise<void>
}

const Web3Context = createContext<Web3ContextType | undefined>(undefined)

export const useWeb3 = () => {
  const context = useContext(Web3Context)
  if (!context) {
    throw new Error('useWeb3 must be used within a Web3Provider')
  }
  return context
}

interface Web3ProviderProps {
  children: React.ReactNode
}

export const Web3Provider: React.FC<Web3ProviderProps> = ({ children }) => {
  const { address, isConnected } = useAccount()
  const { chain } = useNetwork()
  const { switchNetwork } = useSwitchNetwork()
  const [isCorrectNetwork, setIsCorrectNetwork] = useState(false)

  // Check if user is on a supported Polygon network
  useEffect(() => {
    if (chain) {
      const isSupportedChain = Object.values(SUPPORTED_CHAINS).includes(chain.id)
      setIsCorrectNetwork(isSupportedChain)
      
      if (isConnected && !isSupportedChain) {
        toast.error('Please switch to Polygon network')
      }
    }
  }, [chain, isConnected])

  const switchToPolygon = async () => {
    try {
      if (switchNetwork) {
        await switchNetwork(polygon.id)
        toast.success('Switched to Polygon Mainnet')
      }
    } catch (error) {
      console.error('Failed to switch to Polygon:', error)
      toast.error('Failed to switch network')
    }
  }

  const switchToPolygonTestnet = async () => {
    try {
      if (switchNetwork) {
        await switchNetwork(polygonAmoy.id)
        toast.success('Switched to Polygon Amoy Testnet')
      }
    } catch (error) {
      console.error('Failed to switch to Polygon testnet:', error)
      toast.error('Failed to switch network')
    }
  }

  const value: Web3ContextType = {
    isConnected,
    address,
    chainId: chain?.id,
    isCorrectNetwork,
    switchToPolygon,
    switchToPolygonTestnet,
  }

  return (
    <Web3Context.Provider value={value}>
      {children}
    </Web3Context.Provider>
  )
}