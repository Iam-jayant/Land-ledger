import React from 'react'
import { Briefcase } from 'lucide-react'

export const PortfolioPage: React.FC = () => {
  return (
    <div className="px-4 py-6 space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">My Portfolio</h1>
      
      <div className="card text-center space-y-4">
        <div className="w-16 h-16 bg-primary-100 rounded-full flex items-center justify-center mx-auto">
          <Briefcase className="w-8 h-8 text-primary-600" />
        </div>
        <h3 className="text-lg font-semibold text-gray-900">No Properties Yet</h3>
        <p className="text-gray-600">
          Your owned property tokens will appear here once you make your first purchase.
        </p>
      </div>
    </div>
  )
}