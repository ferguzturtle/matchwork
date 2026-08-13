import { useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'
import { Activity, Clock, CheckCircle, XCircle } from 'lucide-react'

export default function JobsMonitor() {
  const [jobs, setJobs] = useState([])
  const [loading, setLoading] = useState(true)

  const fetchJobsData = async () => {
    setLoading(true)
    
    // 1. Obtener todas las solicitudes de trabajo
    const { data: requests } = await supabase
      .from('service_requests')
      .select('*')
      .order('created_at', { ascending: false })
      
    // 2. Obtener perfiles para el cruce de nombres
    const { data: profiles } = await supabase.from('profiles').select('id, name')
    
    const profileMap = {}
    if (profiles) {
      profiles.forEach(p => {
        profileMap[p.id] = p.name || 'Desconocido'
      })
    }

    // 3. Ensamblar los datos
    const assembledJobs = (requests || []).map(job => ({
      ...job,
      clientName: profileMap[job.client_id] || 'Cliente Borrado',
      providerName: profileMap[job.provider_id] || 'Trabajador Borrado'
    }))
    
    setJobs(assembledJobs)
    setLoading(false)
  }

  useEffect(() => {
    fetchJobsData()
    // Auto-actualizar cada 10 segundos para ver si alguien aceptó/terminó un trabajo
    const interval = setInterval(fetchJobsData, 10000)
    return () => clearInterval(interval)
  }, [])

  // Helper para colores de estados
  const getStatusStyle = (status) => {
    switch (status) {
      case 'pendiente':
        return { color: '#F59E0B', bg: 'rgba(245, 158, 11, 0.1)', icon: <Clock size={16} /> }
      case 'trabajando':
      case 'solicitud_trabajo':
      case 'aceptado':
        return { color: '#3B82F6', bg: 'rgba(59, 130, 246, 0.1)', icon: <Activity size={16} /> }
      case 'completado':
        return { color: '#10B981', bg: 'rgba(16, 185, 129, 0.1)', icon: <CheckCircle size={16} /> }
      case 'rechazado':
      case 'cancelado':
        return { color: '#EF4444', bg: 'rgba(239, 68, 68, 0.1)', icon: <XCircle size={16} /> }
      default:
        return { color: '#94A3B8', bg: 'rgba(148, 163, 184, 0.1)', icon: <Clock size={16} /> }
    }
  }

  return (
    <div>
      <div style={{ marginBottom: '2rem' }}>
        <h1 style={{ fontSize: '2rem', fontWeight: 'bold', marginBottom: '0.5rem' }}>Monitor Logístico de Trabajos</h1>
        <p style={{ color: 'var(--text-muted)' }}>Supervisa el estado y ciclo de vida de todos los servicios contratados en la aplicación.</p>
      </div>

      <div className="glass-panel" style={{ overflow: 'hidden' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
          <thead>
            <tr style={{ borderBottom: '1px solid rgba(255,255,255,0.1)', backgroundColor: 'rgba(255,255,255,0.02)' }}>
              <th style={{ padding: '1rem', color: 'var(--text-muted)', fontWeight: '500' }}>ID Trabajo</th>
              <th style={{ padding: '1rem', color: 'var(--text-muted)', fontWeight: '500' }}>Cliente Contrata</th>
              <th style={{ padding: '1rem', color: 'var(--text-muted)', fontWeight: '500' }}>Trabajador Asignado</th>
              <th style={{ padding: '1rem', color: 'var(--text-muted)', fontWeight: '500' }}>Estado Actual</th>
              <th style={{ padding: '1rem', color: 'var(--text-muted)', fontWeight: '500' }}>Fecha / Hora</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan="5" style={{ padding: '2rem', textAlign: 'center' }}>Sincronizando operaciones en vivo...</td></tr>
            ) : jobs.length === 0 ? (
              <tr><td colSpan="5" style={{ padding: '2rem', textAlign: 'center' }}>No hay trabajos registrados en la base de datos.</td></tr>
            ) : (
              jobs.map((job) => {
                const statusStyle = getStatusStyle(job.status)
                return (
                  <tr key={job.id} style={{ borderBottom: '1px solid rgba(255,255,255,0.05)', transition: 'background 0.2s' }} onMouseOver={(e) => e.currentTarget.style.backgroundColor = 'rgba(255,255,255,0.02)'} onMouseOut={(e) => e.currentTarget.style.backgroundColor = 'transparent'}>
                    <td style={{ padding: '1rem', fontFamily: 'monospace', color: '#94A3B8' }}>
                      #{job.id.substring(0, 8)}
                    </td>
                    <td style={{ padding: '1rem' }}>
                      <strong style={{ display: 'block' }}>{job.clientName}</strong>
                      <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>{job.client_id.substring(0,6)}</span>
                    </td>
                    <td style={{ padding: '1rem' }}>
                      <strong style={{ display: 'block' }}>{job.providerName}</strong>
                      <span style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>{job.provider_id.substring(0,6)}</span>
                    </td>
                    <td style={{ padding: '1rem' }}>
                      <span style={{
                        display: 'inline-flex', alignItems: 'center', gap: '6px',
                        background: statusStyle.bg, color: statusStyle.color,
                        padding: '6px 12px', borderRadius: '20px', fontSize: '0.85rem', fontWeight: '600', textTransform: 'capitalize'
                      }}>
                        {statusStyle.icon}
                        {job.status}
                      </span>
                    </td>
                    <td style={{ padding: '1rem', color: 'var(--text-muted)', fontSize: '0.9rem' }}>
                      {new Date(job.created_at).toLocaleString()}
                    </td>
                  </tr>
                )
              })
            )}
          </tbody>
        </table>
      </div>
    </div>
  )
}
