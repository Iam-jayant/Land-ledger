import React from 'react'
import { Outlet } from 'react-router-dom'
import { BottomNavigation } from './BottomNavigation'
import { TopBar } from './TopBar'

export const MobileLayout: React.FC = () => {
  return (
    <div className="min-h-screen bg-gray-50 flex flex-col">
      {/* Top Bar */}
      <TopBar />
      
      {/* Main Content */}
      <main className="flex-1 pb-20 pt-16">
        <Outlet />
      </main>
      
      {/* Bottom Navigation */}
      <BottomNavigation />
    </div>
  )
}