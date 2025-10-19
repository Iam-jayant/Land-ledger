import React from 'react'
import { ConnectButton } from '@rainbow-me/rainbowkit'
import { Bell, Menu } from 'lucide-react'
import { useWeb3 } from '../../providers/Web3Provider'

export const TopBar: React.FC = () => {
  const { isCorrectNetwork } = useWeb3()

  return (
    <header className="fixed top-0 left-0 right-0 z-50 bg-white border-b border-gray-200 px-4 py-3">
      <div className="flex items-center justify-between">
        {/* Logo */}
        <div className="flex items-center space-x-3">
          <button className="p-2 hover:bg-gray-100 rounded-lg">
            <Menu className="w-5 h-5 text-gray-600" />
          </button>
          <h1 className="text-lg font-bold text-gray-900">Land-Ledger</h1>
        </div>

        {/* Right side actions */}
        <div className="flex items-center space-x-2">
          {/* Network Status Indicator */}
          {!isCorrectNetwork && (
            <div className="px-2 py-1 bg-red-100 text-red-800 text-xs rounded-full">
              Wrong Network
            </div>
          )}
          
          {/* Notifications */}
          <button className="p-2 hover:bg-gray-100 rounded-lg relative">
            <Bell className="w-5 h-5 text-gray-600" />
            <span className="absolute -top-1 -right-1 w-3 h-3 bg-red-500 rounded-full"></span>
          </button>
          
          {/* Wallet Connection */}
          <div className="scale-90">
            <ConnectButton
              chainStatus="icon"
              accountStatus={{
                smallScreen: 'avatar',
                largeScreen: 'full',
              }}
              showBalance={{
                smallScreen: false,
                largeScreen: true,
              }}
            />
          </div>
        </div>
      </div>
    </header>
  )
}