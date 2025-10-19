import React from 'react'
import { Link } from 'react-router-dom'
import { Plus, TrendingUp, Shield, Zap } from 'lucide-react'
import { useWeb3 } from '../providers/Web3Provider'

export const HomePage: React.FC = () => {
  const { isConnected, isCorrectNetwork } = useWeb3()

  return (
    <div className="px-4 py-6 space-y-6">
      {/* Welcome Section */}
      <div className="text-center space-y-4">
        <h1 className="text-2xl font-bold text-gray-900">
          Welcome to Land-Ledger
        </h1>
        <p className="text-gray-600 max-w-sm mx-auto">
          Tokenize, trade, and manage real estate assets on the Polygon blockchain
        </p>
      </div>

      {/* Connection Status */}
      {!isConnected && (
        <div className="card text-center space-y-4">
          <Shield className="w-12 h-12 text-primary-600 mx-auto" />
          <h3 className="text-lg font-semibold">Connect Your Wallet</h3>
          <p className="text-gray-600">
            Connect your MetaMask wallet to start using Land-Ledger
          </p>
        </div>
      )}

      {isConnected && !isCorrectNetwork && (
        <div className="card text-center space-y-4 bg-red-50 border-red-200">
          <Zap className="w-12 h-12 text-red-600 mx-auto" />
          <h3 className="text-lg font-semibold text-red-900">Wrong Network</h3>
          <p className="text-red-700">
            Please switch to Polygon network to continue
          </p>
        </div>
      )}

      {/* Quick Actions */}
      {isConnected && isCorrectNetwork && (
        <div className="space-y-4">
          <h2 className="text-lg font-semibold text-gray-900">Quick Actions</h2>
          <div className="grid grid-cols-2 gap-4">
            <Link
              to="/marketplace"
              className="card text-center space-y-3 hover:shadow-md transition-shadow"
            >
              <TrendingUp className="w-8 h-8 text-primary-600 mx-auto" />
              <div>
                <h3 className="font-medium text-gray-900">Browse Properties</h3>
                <p className="text-sm text-gray-600">Explore available listings</p>
              </div>
            </Link>
            
            <Link
              to="/list-property"
              className="card text-center space-y-3 hover:shadow-md transition-shadow"
            >
              <Plus className="w-8 h-8 text-primary-600 mx-auto" />
              <div>
                <h3 className="font-medium text-gray-900">List Property</h3>
                <p className="text-sm text-gray-600">Tokenize your real estate</p>
              </div>
            </Link>
          </div>
        </div>
      )}

      {/* Features */}
      <div className="space-y-4">
        <h2 className="text-lg font-semibold text-gray-900">Why Land-Ledger?</h2>
        <div className="space-y-3">
          <div className="flex items-start space-x-3">
            <Shield className="w-5 h-5 text-primary-600 mt-1 flex-shrink-0" />
            <div>
              <h4 className="font-medium text-gray-900">Secure & Compliant</h4>
              <p className="text-sm text-gray-600">ERC-3643 compliance with KYC/AML verification</p>
            </div>
          </div>
          
          <div className="flex items-start space-x-3">
            <Zap className="w-5 h-5 text-primary-600 mt-1 flex-shrink-0" />
            <div>
              <h4 className="font-medium text-gray-900">Fast & Affordable</h4>
              <p className="text-sm text-gray-600">Built on Polygon for low-cost transactions</p>
            </div>
          </div>
          
          <div className="flex items-start space-x-3">
            <TrendingUp className="w-5 h-5 text-primary-600 mt-1 flex-shrink-0" />
            <div>
              <h4 className="font-medium text-gray-900">Transparent Trading</h4>
              <p className="text-sm text-gray-600">Immutable records and automated escrow</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}