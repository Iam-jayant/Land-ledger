import React from 'react'
import { User, Shield, Settings } from 'lucide-react'
import { useWeb3 } from '../providers/Web3Provider'

export const ProfilePage: React.FC = () => {
  const { address, isConnected } = useWeb3()

  return (
    <div className="px-4 py-6 space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">Profile</h1>
      
      {isConnected ? (
        <div className="space-y-4">
          {/* User Info */}
          <div className="card space-y-4">
            <div className="flex items-center space-x-3">
              <div className="w-12 h-12 bg-primary-100 rounded-full flex items-center justify-center">
                <User className="w-6 h-6 text-primary-600" />
              </div>
              <div>
                <h3 className="font-semibold text-gray-900">Wallet Address</h3>
                <p className="text-sm text-gray-600 font-mono">
                  {address ? `${address.slice(0, 6)}...${address.slice(-4)}` : 'Not connected'}
                </p>
              </div>
            </div>
          </div>

          {/* KYC Status */}
          <div className="card space-y-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-3">
                <Shield className="w-6 h-6 text-yellow-600" />
                <div>
                  <h3 className="font-semibold text-gray-900">KYC Verification</h3>
                  <p className="text-sm text-gray-600">Pending verification</p>
                </div>
              </div>
              <button className="btn-primary text-sm">
                Complete KYC
              </button>
            </div>
          </div>

          {/* Settings */}
          <div className="card">
            <div className="flex items-center space-x-3">
              <Settings className="w-6 h-6 text-gray-600" />
              <div>
                <h3 className="font-semibold text-gray-900">Settings</h3>
                <p className="text-sm text-gray-600">Manage your preferences</p>
              </div>
            </div>
          </div>
        </div>
      ) : (
        <div className="card text-center space-y-4">
          <User className="w-16 h-16 text-gray-400 mx-auto" />
          <h3 className="text-lg font-semibold text-gray-900">Connect Your Wallet</h3>
          <p className="text-gray-600">
            Please connect your wallet to view your profile.
          </p>
        </div>
      )}
    </div>
  )
}