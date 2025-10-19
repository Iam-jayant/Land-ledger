import React from 'react'
import { Routes, Route } from 'react-router-dom'
import { MobileLayout } from '../components/layout/MobileLayout'
import { HomePage } from '../pages/HomePage'
import { MarketplacePage } from '../pages/MarketplacePage'
import { PortfolioPage } from '../pages/PortfolioPage'
import { TransactionsPage } from '../pages/TransactionsPage'
import { ProfilePage } from '../pages/ProfilePage'
import { PropertyDetailsPage } from '../pages/PropertyDetailsPage'
import { ListPropertyPage } from '../pages/ListPropertyPage'
import { KYCPage } from '../pages/KYCPage'

export const AppRoutes: React.FC = () => {
  return (
    <Routes>
      <Route path="/" element={<MobileLayout />}>
        <Route index element={<HomePage />} />
        <Route path="marketplace" element={<MarketplacePage />} />
        <Route path="portfolio" element={<PortfolioPage />} />
        <Route path="transactions" element={<TransactionsPage />} />
        <Route path="profile" element={<ProfilePage />} />
        <Route path="property/:tokenId" element={<PropertyDetailsPage />} />
        <Route path="list-property" element={<ListPropertyPage />} />
        <Route path="kyc" element={<KYCPage />} />
      </Route>
    </Routes>
  )
}