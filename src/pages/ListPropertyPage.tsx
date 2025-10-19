import React from 'react'
import { Plus } from 'lucide-react'

export const ListPropertyPage: React.FC = () => {
  return (
    <div className="px-4 py-6 space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">List Property</h1>
      
      <div className="card text-center space-y-4">
        <div className="w-16 h-16 bg-primary-100 rounded-full flex items-center justify-center mx-auto">
          <Plus className="w-8 h-8 text-primary-600" />
        </div>
        <h3 className="text-lg font-semibold text-gray-900">Property Listing Coming Soon</h3>
        <p className="text-gray-600">
          The property tokenization interface will be available once smart contracts are deployed.
        </p>
      </div>
    </div>
  )
}