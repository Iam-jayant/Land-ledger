import React from 'react'
import { useParams } from 'react-router-dom'

export const PropertyDetailsPage: React.FC = () => {
  const { tokenId } = useParams<{ tokenId: string }>()

  return (
    <div className="px-4 py-6">
      <h1 className="text-2xl font-bold text-gray-900">Property Details</h1>
      <p className="text-gray-600 mt-2">Token ID: {tokenId}</p>
      
      <div className="card mt-6 text-center space-y-4">
        <h3 className="text-lg font-semibold text-gray-900">Property Details Coming Soon</h3>
        <p className="text-gray-600">
          Detailed property information will be displayed here once properties are tokenized.
        </p>
      </div>
    </div>
  )
}