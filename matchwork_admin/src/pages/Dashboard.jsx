import { useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'
import { Users, Briefcase, Activity, Star } from 'lucide-react'

export default function Dashboard() {
  const [stats, setStats] = useState({
    totalUsers: 0,
    providers: 0,
    activeJobs: 0,
  })

  useEffect(() => {
    async function fetchStats() {
      // 1. Total Clientes
      const { count: clientCount } = await supabase
        .from('clients')
        .select('*', { count: 'exact', head: true })
        
      // 2. Total Proveedores
      const { count: providerCount } = await supabase
        .from('providers')
        .select('*', { count: 'exact', head: true })
        
      // 3. Trabajos Activos (donde status = 'trabajando')
      const { count: jobsCount } = await supabase
        .from('service_requests')
        .select('*', { count: 'exact', head: true })
        .eq('status', 'trabajando')

      setStats({
        totalUsers: (clientCount || 0) + (providerCount || 0),
        providers: providerCount || 0,
        activeJobs: jobsCount || 0,
      })
    }
    
    fetchStats()
  }, [])

  const StatCard = ({ title, value, icon, color }) => (
    <div className="glass-panel" style={{ padding: '1.5rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
      <div style={{ 
        background: `rgba(${color}, 0.2)`, 
        padding: '1rem', 
        borderRadius: '12px',
        border: `1px solid rgba(${color}, 0.4)`,
        color: `rgb(${color})`
      }}>
        {icon}
      </div>
      <div>
        <p style={{ color: 'var(--text-muted)', fontSize: '0.9rem', marginBottom: '0.25rem' }}>{title}</p>
        <h3 style={{ fontSize: '1.8rem', fontWeight: 'bold' }}>{value}</h3>
      </div>
    </div>
  )

  return (
    <div>
      <div style={{ marginBottom: '2rem' }}>
        <h1 style={{ fontSize: '2rem', fontWeight: 'bold', marginBottom: '0.5rem' }}>Visión General</h1>
        <p style={{ color: 'var(--text-muted)' }}>Métricas en tiempo real de la plataforma MatchWork.</p>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: '1.5rem' }}>
        <StatCard 
          title="Usuarios Totales" 
          value={stats.totalUsers} 
          icon={<Users size={28} />} 
          color="59, 130, 246" // Blue
        />
        <StatCard 
          title="Proveedores" 
          value={stats.providers} 
          icon={<Briefcase size={28} />} 
          color="139, 92, 246" // Purple
        />
        <StatCard 
          title="Trabajos en Curso" 
          value={stats.activeJobs} 
          icon={<Activity size={28} />} 
          color="16, 185, 129" // Green
        />
        <StatCard 
          title="Satisfacción (Media)" 
          value="4.8" 
          icon={<Star size={28} />} 
          color="245, 158, 11" // Orange
        />
      </div>
      
      <div className="glass-panel" style={{ marginTop: '2rem', padding: '2rem', height: '300px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <p style={{ color: 'var(--text-muted)' }}>Módulo de Gráficos de Crecimiento (Próximamente)</p>
      </div>
    </div>
  )
}
