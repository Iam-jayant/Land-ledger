import React from 'react'
import { NavLink } from 'react-router-dom'
import { Home, Search, Briefcase, Activity, User } from 'lucide-react'
import { cn } from '../../utils/cn'

const navigationItems = [
  {
    name: 'Home',
    href: '/',
    icon: Home,
  },
  {
    name: 'Marketplace',
    href: '/marketplace',
    icon: Search,
  },
  {
    name: 'Portfolio',
    href: '/portfolio',
    icon: Briefcase,
  },
  {
    name: 'Transactions',
    href: '/transactions',
    icon: Activity,
  },
  {
    name: 'Profile',
    href: '/profile',
    icon: User,
  },
]

export const BottomNavigation: React.FC = () => {
  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 bg-white border-t border-gray-200 px-2 py-2 safe-area-inset-bottom">
      <div className="flex items-center justify-around">
        {navigationItems.map((item) => (
          <NavLink
            key={item.name}
            to={item.href}
            className={({ isActive }) =>
              cn(
                'flex flex-col items-center justify-center px-3 py-2 rounded-lg transition-colors duration-200 touch-target',
                isActive
                  ? 'text-primary-600 bg-primary-50'
                  : 'text-gray-500 hover:text-gray-700 hover:bg-gray-50'
              )
            }
          >
            {({ isActive }) => (
              <>
                <item.icon
                  className={cn(
                    'w-5 h-5 mb-1',
                    isActive ? 'text-primary-600' : 'text-gray-500'
                  )}
                />
                <span
                  className={cn(
                    'text-xs font-medium',
                    isActive ? 'text-primary-600' : 'text-gray-500'
                  )}
                >
                  {item.name}
                </span>
              </>
            )}
          </NavLink>
        ))}
      </div>
    </nav>
  )
}