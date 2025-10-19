import React from 'react'
import { Activity } from 'lucide-react'

export const TransactionsPage: React.FC = () => {
  return (
    <div className="px-4 py-6 space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">Transaction History</h1>
      
      <div className="card text-center space-y-4">
        <div className="w-16 h-16 bg-primary-100 rounded-full flex items-center justify-center mx-auto">
          <Activity className="w-8 h-8 text-primary-600" />
        </div>
        <h3 className="text-lg font-semibold text-gray-900">No Transactions Yet</h3>
        <p className="text-gray-600">
          Your transaction history will appear here once you start trading properties.
        </p>
      </div>
    </div>
  )
}