import { useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'
import { Search, MapPin, Phone, ShieldAlert, X, Star } from 'lucide-react'

export default function Users() {
  const [usersList, setUsersList] = useState([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [selectedUser, setSelectedUser] = useState(null)
  const [isBanning, setIsBanning] = useState(false)

  const fetchUsers = async () => {
    setLoading(true)
    
    // Obtenemos todos los perfiles base (clientes)
    const { data: profilesData } = await supabase.from('profiles').select('*')
    // Obtenemos todos los registros de trabajadores (providers)
    const { data: providersData } = await supabase.from('providers').select('*')
    
    // Mapeamos a un diccionario por ID para unificar
    const unifiedUsers = {}
    
    ;(profilesData || []).forEach(p => {
      unifiedUsers[p.id] = {
        id: p.id,
        name: p.name,
        phone: p.phone,
        created_at: p.created_at,
        is_banned: p.is_banned,
        isClient: true,
        isProvider: false,
        displayRole: 'Cliente'
      }
    })
    
    ;(providersData || []).forEach(p => {
      if (unifiedUsers[p.id]) {
        unifiedUsers[p.id].isProvider = true
        unifiedUsers[p.id].displayRole = 'Cliente y Trabajador'
        unifiedUsers[p.id].providerData = p
        // Si el provider tiene ban y el cliente no (o viceversa), unificamos el ban visualmente
        if (p.is_banned) unifiedUsers[p.id].is_banned = true
      } else {
        unifiedUsers[p.id] = {
          id: p.id,
          name: p.name,
          phone: p.phone,
          created_at: p.created_at,
          is_banned: p.is_banned,
          isClient: false,
          isProvider: true,
          displayRole: 'Trabajador',
          providerData: p
        }
      }
    })
    
    const allUsers = Object.values(unifiedUsers).sort((a, b) => 
      new Date(b.created_at) - new Date(a.created_at)
    )
    
    setUsersList(allUsers)
    setLoading(false)
  }

  useEffect(() => {
    fetchUsers()
  }, [])

  const handleBanUser = async (user) => {
    const isCurrentlyBanned = user.is_banned === true
    const confirmMessage = isCurrentlyBanned 
      ? `¿Estás seguro de DESBLOQUEAR a ${user.name}?`
      : `¿Estás seguro de SUSPENDER a ${user.name}? No podrá iniciar sesión.`
      
    if (!window.confirm(confirmMessage)) return
    
    setIsBanning(true)
    
    // Bloqueamos en ambas tablas por seguridad si el usuario existe en ambas
    if (user.isClient) {
      await supabase.from('profiles').update({ is_banned: !isCurrentlyBanned }).eq('id', user.id)
    }
    if (user.isProvider) {
      await supabase.from('providers').update({ is_banned: !isCurrentlyBanned }).eq('id', user.id)
    }
    
    // Actualizamos la lista local
    setUsersList(prev => prev.map(u => 
      u.id === user.id ? { ...u, is_banned: !isCurrentlyBanned } : u
    ))
    if (selectedUser?.id === user.id) {
      setSelectedUser({ ...selectedUser, is_banned: !isCurrentlyBanned })
    }
    setIsBanning(false)
  }

  const filteredUsers = usersList.filter(u => 
    (u.name || '').toLowerCase().includes(search.toLowerCase()) || 
    u.displayRole.toLowerCase().includes(search.toLowerCase())
  )

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', marginBottom: '2rem' }}>
        <div>
          <h1 style={{ fontSize: '2rem', fontWeight: 'bold', marginBottom: '0.5rem' }}>Directorio de Usuarios (CRM)</h1>
          <p style={{ color: 'var(--text-muted)' }}>Administra y visualiza la base de datos completa.</p>
        </div>
        
        <div style={{ position: 'relative', width: '300px' }}>
          <Search size={18} color="#94A3B8" style={{ position: 'absolute', left: '1rem', top: '12px' }} />
          <input 
            type="text" 
            className="glass-input" 
            placeholder="Buscar por nombre o rol..." 
            style={{ paddingLeft: '2.5rem' }}
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
      </div>

      <div className="glass-panel" style={{ overflow: 'hidden' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
          <thead>
            <tr style={{ borderBottom: '1px solid rgba(255,255,255,0.1)', backgroundColor: 'rgba(255,255,255,0.02)' }}>
              <th style={{ padding: '1rem', color: 'var(--text-muted)', fontWeight: '500' }}>Usuario</th>
              <th style={{ padding: '1rem', color: 'var(--text-muted)', fontWeight: '500' }}>Rol en Plataforma</th>
              <th style={{ padding: '1rem', color: 'var(--text-muted)', fontWeight: '500' }}>Contacto</th>
              <th style={{ padding: '1rem', color: 'var(--text-muted)', fontWeight: '500' }}>Estado</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan="4" style={{ padding: '2rem', textAlign: 'center' }}>Cargando datos maestros...</td></tr>
            ) : filteredUsers.map((user) => (
              <tr 
                key={user.id} 
                onClick={() => setSelectedUser(user)}
                style={{ 
                  borderBottom: '1px solid rgba(255,255,255,0.05)', 
                  cursor: 'pointer',
                  transition: 'background 0.2s',
                  backgroundColor: user.is_banned ? 'rgba(239, 68, 68, 0.05)' : 'transparent'
                }}
                onMouseOver={(e) => e.currentTarget.style.backgroundColor = 'rgba(255,255,255,0.02)'}
                onMouseOut={(e) => e.currentTarget.style.backgroundColor = user.is_banned ? 'rgba(239, 68, 68, 0.05)' : 'transparent'}
              >
                <td style={{ padding: '1rem' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                    <div style={{ 
                      width: '40px', height: '40px', borderRadius: '50%', 
                      background: user.is_banned ? 'rgba(239, 68, 68, 0.2)' : 'rgba(59, 130, 246, 0.2)',
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                      color: user.is_banned ? '#EF4444' : '#3B82F6', fontWeight: 'bold'
                    }}>
                      {user.name?.charAt(0).toUpperCase()}
                    </div>
                    <div>
                      <div style={{ fontWeight: '600', color: user.is_banned ? '#EF4444' : '#fff' }}>
                        {user.name || 'Sin Nombre'} {user.is_banned && '(Bloqueado)'}
                      </div>
                      <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>ID: {user.id.substring(0,8)}...</div>
                    </div>
                  </div>
                </td>
                <td style={{ padding: '1rem' }}>
                  <span style={{
                    background: user.displayRole === 'Cliente y Trabajador' ? 'rgba(59, 130, 246, 0.15)' 
                              : user.displayRole === 'Cliente' ? 'rgba(16, 185, 129, 0.15)' 
                              : 'rgba(139, 92, 246, 0.15)',
                    color: user.displayRole === 'Cliente y Trabajador' ? '#3B82F6' 
                         : user.displayRole === 'Cliente' ? '#10B981' 
                         : '#8B5CF6',
                    padding: '4px 10px', borderRadius: '20px', fontSize: '0.8rem', fontWeight: '600'
                  }}>
                    {user.displayRole}
                  </span>
                </td>
                <td style={{ padding: '1rem' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '0.9rem' }}>
                    <Phone size={14} color="var(--text-muted)" />
                    {user.phone || 'No registrado'}
                  </div>
                </td>
                <td style={{ padding: '1rem', color: 'var(--text-muted)', fontSize: '0.9rem' }}>
                  {user.is_banned ? <span style={{color: '#EF4444'}}>Suspendido</span> : <span style={{color: '#10B981'}}>Activo</span>}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* MODAL DE EXPEDIENTE MEJORADO */}
      {selectedUser && (
        <div style={{
          position: 'fixed', top: 0, left: 0, right: 0, bottom: 0,
          backgroundColor: 'rgba(0,0,0,0.7)', backdropFilter: 'blur(4px)',
          display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 1000
        }} onClick={() => setSelectedUser(null)}>
          
          <div className="glass-panel" style={{ width: '500px', padding: '2rem', position: 'relative', maxHeight: '90vh', overflowY: 'auto' }} onClick={e => e.stopPropagation()}>
            <button 
              onClick={() => setSelectedUser(null)}
              style={{ position: 'absolute', top: '15px', right: '15px', background: 'transparent', border: 'none', color: '#fff', cursor: 'pointer' }}
            >
              <X size={24} />
            </button>
            
            <div style={{ display: 'flex', gap: '1rem', alignItems: 'center', marginBottom: '1.5rem' }}>
               <div style={{ width: '70px', height: '70px', borderRadius: '50%', background: '#3B82F6', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '2rem', fontWeight: 'bold' }}>
                  {selectedUser.name?.charAt(0)}
               </div>
               <div>
                 <h2 style={{ fontSize: '1.5rem', fontWeight: 'bold' }}>{selectedUser.name}</h2>
                 <p style={{ color: 'var(--text-muted)' }}>{selectedUser.displayRole} • Se unió el {new Date(selectedUser.created_at).toLocaleDateString()}</p>
               </div>
            </div>

            <div style={{ background: 'rgba(255,255,255,0.05)', padding: '1rem', borderRadius: '8px', marginBottom: '1rem' }}>
              <h3 style={{ fontSize: '1.1rem', fontWeight: '600', marginBottom: '0.5rem', color: '#3B82F6' }}>Información Base</h3>
              <p style={{ marginBottom: '0.5rem' }}><strong>Teléfono:</strong> {selectedUser.phone || 'N/A'}</p>
              <p><strong>ID Sistema:</strong> {selectedUser.id}</p>
            </div>

            {selectedUser.isProvider && selectedUser.providerData && (
              <div style={{ background: 'rgba(139, 92, 246, 0.05)', padding: '1rem', borderRadius: '8px', marginBottom: '1.5rem', border: '1px solid rgba(139, 92, 246, 0.2)' }}>
                <h3 style={{ fontSize: '1.1rem', fontWeight: '600', marginBottom: '0.5rem', color: '#8B5CF6' }}>Expediente de Trabajador</h3>
                
                <div style={{ display: 'flex', alignItems: 'center', gap: '5px', marginBottom: '0.5rem' }}>
                   <strong>Calificación:</strong> 
                   <Star size={16} fill="#F59E0B" color="#F59E0B" /> 
                   {selectedUser.providerData.rating?.toFixed(1) || 'Nuevo'}
                </div>
                
                <p style={{ marginBottom: '0.5rem', textTransform: 'capitalize' }}>
                  <strong>Rubro Principal:</strong> {selectedUser.providerData.category || 'No definido'} 
                  {selectedUser.providerData.subcategory ? ` (${selectedUser.providerData.subcategory})` : ''}
                </p>
                <p style={{ marginBottom: '0.5rem' }}><strong>Profesión Comercial:</strong> {selectedUser.providerData.profession || 'N/A'}</p>
                <p style={{ marginBottom: '0.5rem' }}><strong>Tarifa Base:</strong> ${selectedUser.providerData.price_per_hour || 0} /hr</p>
                <p style={{ marginBottom: '0.5rem' }}><strong>Trabajos Completados:</strong> {selectedUser.providerData.jobs_completed || 0}</p>
                <p><strong>Biografía:</strong> {selectedUser.providerData.description || 'Sin descripción'}</p>
              </div>
            )}

            <button 
              className="btn-primary" 
              onClick={() => handleBanUser(selectedUser)}
              disabled={isBanning}
              style={{ 
                background: selectedUser.is_banned ? '#10B981' : '#EF4444', 
                display: 'flex', justifyContent: 'center', alignItems: 'center', gap: '8px',
                width: '100%'
              }}
            >
              <ShieldAlert size={18} />
              {isBanning ? 'Procesando...' : selectedUser.is_banned ? 'Restaurar Cuenta' : 'Suspender Usuario Definitivamente'}
            </button>

          </div>
        </div>
      )}
    </div>
  )
}

