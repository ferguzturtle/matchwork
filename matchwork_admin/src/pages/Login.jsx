import { useState } from 'react'
import { supabase } from '../lib/supabase'
import { ShieldAlert, User, Lock } from 'lucide-react'

export default function Login() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState(null)
  const [loading, setLoading] = useState(false)

  const handleLogin = async (e) => {
    e.preventDefault()
    setLoading(true)
    setError(null)
    
    // Aquí más adelante podremos agregar una validación adicional para 
    // verificar que el email pertenezca a la tabla 'admins' o similar.
    // Por ahora, iniciamos sesión normalmente para probar la conexión a Supabase.
    
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    })

    if (error) {
      setError(error.message)
    } else {
      // 🚨 VALIDACIÓN DE SEGURIDAD EXCLUSIVA PARA ADMIN 🚨
      // Aquí bloqueamos el paso a usuarios comunes de la app móvil
      const superAdminEmail = 'admin@gmail.com' 
      
      if (data.user && data.user.email !== superAdminEmail) {
        // Es un usuario normal que intentó colarse, lo expulsamos
        await supabase.auth.signOut()
        setError('Acceso Denegado. Esta cuenta no tiene privilegios de Administrador.')
      } else {
        // Es el Admin, lo dejamos pasar
        window.location.href = '/' // Redirige al Dashboard
      }
    }
    
    setLoading(false)
  }

  return (
    <div className="auth-container">
      <div className="glass-panel auth-box">
        <div style={{ display: 'flex', justifyContent: 'center', marginBottom: '1rem' }}>
          <div style={{ 
            background: 'rgba(59, 130, 246, 0.2)', 
            padding: '1rem', 
            borderRadius: '50%',
            border: '1px solid rgba(59, 130, 246, 0.4)'
          }}>
            <ShieldAlert size={40} color="#3B82F6" />
          </div>
        </div>
        
        <h1 className="auth-title">MatchWork Admin</h1>
        <p className="auth-subtitle">Portal de acceso exclusivo para CEOs</p>
        
        {error && (
          <div className="error-message">
            {error}
          </div>
        )}
        
        <form onSubmit={handleLogin}>
          <div className="form-group">
            <label className="form-label">Correo Administrativo</label>
            <div style={{ position: 'relative' }}>
              <User size={18} color="#94A3B8" style={{ position: 'absolute', left: '1rem', top: '12px' }} />
              <input
                type="email"
                className="glass-input"
                style={{ paddingLeft: '2.5rem' }}
                placeholder="ejemplo@matchwork.cl"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />
            </div>
          </div>
          
          <div className="form-group">
            <label className="form-label">Contraseña</label>
            <div style={{ position: 'relative' }}>
              <Lock size={18} color="#94A3B8" style={{ position: 'absolute', left: '1rem', top: '12px' }} />
              <input
                type="password"
                className="glass-input"
                style={{ paddingLeft: '2.5rem' }}
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
            </div>
          </div>
          
          <button type="submit" className="btn-primary" disabled={loading} style={{ marginTop: '1rem' }}>
            {loading ? 'Ingresando...' : 'Iniciar Sesión Segura'}
          </button>
        </form>
      </div>
    </div>
  )
}
