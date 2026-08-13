import { useEffect, useState } from 'react'
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { supabase } from './lib/supabase'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import Users from './pages/Users'
import LiveMap from './pages/LiveMap'
import JobsMonitor from './pages/JobsMonitor'
import Layout from './components/Layout'
import './index.css'

function App() {
  const [session, setSession] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session)
      setLoading(false)
    })

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session)
    })

    return () => subscription.unsubscribe()
  }, [])

  if (loading) {
    return <div style={{ display: 'flex', height: '100vh', justifyContent: 'center', alignItems: 'center' }}>Cargando sistema...</div>
  }

  return (
    <BrowserRouter>
      <Routes>
        {/* Rutas Privadas (Protegidas por Layout Shell) */}
        {session ? (
          <Route path="/" element={<Layout />}>
            <Route index element={<Dashboard />} />
            <Route path="users" element={<Users />} />
            <Route path="jobs" element={<JobsMonitor />} />
            <Route path="map" element={<LiveMap />} />
            <Route path="settings" element={<div style={{padding: '2rem'}}>Módulo de Configuración en Construcción</div>} />
          </Route>
        ) : (
          /* Si intenta entrar a cualquier ruta sin sesión, lo tira a login */
          <Route path="*" element={<Navigate to="/login" replace />} />
        )}
        
        {/* Ruta Pública de Login */}
        <Route 
          path="/login" 
          element={!session ? <Login /> : <Navigate to="/" replace />} 
        />
      </Routes>
    </BrowserRouter>
  )
}

export default App
