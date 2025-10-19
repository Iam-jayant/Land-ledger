import React from 'react'
import { Shield } from 'lucide-react'

export const KYCPage: React.FC = () => {
  return (
    <div className="px-4 py-6 space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">KYC Verification</h1>
      
      <div className="card text-center space-y-4">
        <div className="w-16 h-16 bg-primary-100 rounded-full flex items-center justify-center mx-auto">
          <Shield className="w-8 h-8 text-primary-600" />
        </div>
        <h3 className="text-lg font-semibold text-gray-900">KYC Process Coming Soon</h3>
        <p className="text-gray-600">
          Identity verification and compliance features will be available once the system is fully deployed.
        </p>
      </div>
    </div>
  )
}