import { Link, useLocation } from 'react-router-dom'
import { LayoutDashboard, Users, Settings, LogOut, Map, Activity } from 'lucide-react'
import { supabase } from '../lib/supabase'

export default function Sidebar() {
  const location = useLocation()
  
  const handleLogout = async () => {
    await supabase.auth.signOut()
    window.location.href = '/login'
  }

  const navItems = [
    { path: '/', name: 'Dashboard', icon: <LayoutDashboard size={20} /> },
    { path: '/users', name: 'Usuarios (CRM)', icon: <Users size={20} /> },
    { path: '/jobs', name: 'Monitor Trabajos', icon: <Activity size={20} /> },
    { path: '/map', name: 'Mapa Global', icon: <Map size={20} /> },
    { path: '/settings', name: 'Configuración', icon: <Settings size={20} /> },
  ]

  return (
    <div style={{
      width: '260px',
      height: '100vh',
      backgroundColor: 'var(--bg-card)',
      borderRight: '1px solid rgba(255,255,255,0.05)',
      display: 'flex',
      flexDirection: 'column',
      padding: '1.5rem',
      position: 'fixed',
      left: 0,
      top: 0,
    }}>
      <div style={{ marginBottom: '3rem', paddingLeft: '1rem' }}>
        <h2 style={{ fontSize: '1.5rem', fontWeight: 'bold', background: 'linear-gradient(to right, #3B82F6, #8B5CF6)', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>
          MatchWork
        </h2>
        <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>Admin Portal</span>
      </div>

      <nav style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
        {navItems.map((item) => {
          const isActive = location.pathname === item.path
          return (
            <Link 
              key={item.path} 
              to={item.path}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '12px',
                padding: '0.8rem 1rem',
                borderRadius: '8px',
                textDecoration: 'none',
                color: isActive ? '#fff' : 'var(--text-muted)',
                backgroundColor: isActive ? 'rgba(59, 130, 246, 0.15)' : 'transparent',
                border: isActive ? '1px solid rgba(59, 130, 246, 0.3)' : '1px solid transparent',
                transition: 'all 0.2s ease'
              }}
            >
              <div style={{ color: isActive ? '#3B82F6' : 'inherit' }}>{item.icon}</div>
              <span style={{ fontWeight: isActive ? '600' : '400' }}>{item.name}</span>
            </Link>
          )
        })}
      </nav>

      <div style={{ marginTop: 'auto' }}>
        <button 
          onClick={handleLogout}
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: '12px',
            width: '100%',
            padding: '0.8rem 1rem',
            background: 'transparent',
            border: 'none',
            color: '#EF4444',
            cursor: 'pointer',
            textAlign: 'left',
            borderRadius: '8px',
            transition: 'background 0.2s',
          }}
          onMouseOver={(e) => e.currentTarget.style.backgroundColor = 'rgba(239, 68, 68, 0.1)'}
          onMouseOut={(e) => e.currentTarget.style.backgroundColor = 'transparent'}
        >
          <LogOut size={20} />
          <span style={{ fontWeight: '500' }}>Cerrar Sesión</span>
        </button>
      </div>
    </div>
  )
}
