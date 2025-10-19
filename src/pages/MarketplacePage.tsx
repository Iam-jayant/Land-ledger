import React from 'react'
import { Search, Filter } from 'lucide-react'

export const MarketplacePage: React.FC = () => {
  return (
    <div className="px-4 py-6 space-y-6">
      {/* Header */}
      <div className="space-y-4">
        <h1 className="text-2xl font-bold text-gray-900">Property Marketplace</h1>
        
        {/* Search Bar */}
        <div className="relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
            type="text"
            placeholder="Search properties..."
            className="input-field pl-10 pr-12"
          />
          <button className="absolute right-3 top-1/2 transform -translate-y-1/2 p-1">
            <Filter className="w-5 h-5 text-gray-400" />
          </button>
        </div>
      </div>

      {/* Coming Soon Message */}
      <div className="card text-center space-y-4">
        <div className="w-16 h-16 bg-primary-100 rounded-full flex items-center justify-center mx-auto">
          <Search className="w-8 h-8 text-primary-600" />
        </div>
        <h3 className="text-lg font-semibold text-gray-900">Marketplace Coming Soon</h3>
        <p className="text-gray-600">
          Property listings will appear here once smart contracts are deployed and properties are tokenized.
        </p>
      </div>
    </div>
  )
}