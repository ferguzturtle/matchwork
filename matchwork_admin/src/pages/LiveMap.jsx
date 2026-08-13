import { useEffect, useState } from 'react'
import { MapContainer, TileLayer, Marker, Popup } from 'react-leaflet'
import { supabase } from '../lib/supabase'
// Se importa el CSS de Leaflet directamente
import 'leaflet/dist/leaflet.css'

// Para arreglar el ícono por defecto de Leaflet en React (bug conocido)
import L from 'leaflet'
import iconRetinaUrl from 'leaflet/dist/images/marker-icon-2x.png'
import iconUrl from 'leaflet/dist/images/marker-icon.png'
import shadowUrl from 'leaflet/dist/images/marker-shadow.png'

delete L.Icon.Default.prototype._getIconUrl
L.Icon.Default.mergeOptions({
  iconRetinaUrl,
  iconUrl,
  shadowUrl,
})

export default function LiveMap() {
  const [markers, setMarkers] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function fetchLocations() {
      // Obtenemos solo a los proveedores ONLINE con ubicación
      const { data } = await supabase
        .from('providers')
        .select('*')
        .eq('is_online', true)
        .not('latitude', 'is', null)
        .not('longitude', 'is', null)

      setMarkers(data || [])
      setLoading(false)
    }
    fetchLocations()
    
    // Auto-actualizar el mapa cada 10 segundos
    const interval = setInterval(fetchLocations, 10000)
    return () => clearInterval(interval)
  }, [])

  // Coordenadas centro base (Santiago por defecto si no hay nada)
  const defaultCenter = [-33.4489, -70.6693]

  // Función para crear pines de colores dinámicos
  const createCustomIcon = (isOccupied) => {
    const color = isOccupied ? '#F59E0B' : '#10B981' // Amarillo o Verde
    const htmlString = `
      <div style="
        background-color: ${color};
        width: 16px;
        height: 16px;
        border-radius: 50%;
        border: 2px solid white;
        box-shadow: 0 0 10px ${color};
      "></div>
    `
    return L.divIcon({
      className: 'custom-pin',
      html: htmlString,
      iconSize: [20, 20],
      iconAnchor: [10, 10],
    })
  }

  return (
    <div style={{ height: 'calc(100vh - 100px)' }}>
      <div style={{ marginBottom: '1.5rem' }}>
        <h1 style={{ fontSize: '2rem', fontWeight: 'bold', marginBottom: '0.5rem' }}>Mapa Global (Spy-Map)</h1>
        <p style={{ color: 'var(--text-muted)' }}>Visualiza la ubicación en tiempo real de todos tus trabajadores activos.</p>
      </div>

      <div className="glass-panel" style={{ height: '100%', overflow: 'hidden' }}>
        {loading ? (
          <div style={{ height: '100%', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
            <p>Cargando posiciones satelitales...</p>
          </div>
        ) : (
          <MapContainer 
            center={markers.length > 0 ? [markers[0].latitude, markers[0].longitude] : defaultCenter} 
            zoom={12} 
            style={{ height: '100%', width: '100%', zIndex: 0 }}
          >
            <TileLayer
              url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png"
              attribution='&copy; <a href="https://carto.com/">CARTO</a>'
            />

            {markers.map((prov) => (
              <Marker 
                key={prov.id} 
                position={[prov.latitude, prov.longitude]}
                icon={createCustomIcon(prov.is_occupied)}
              >
                <Popup>
                  <div style={{ color: '#000' }}>
                    <strong style={{ fontSize: '1.1rem' }}>{prov.name}</strong><br />
                    <em>{prov.profession}</em><br />
                    Estado: {prov.is_occupied ? '🟠 Ocupado (Trabajando)' : '🟢 Disponible'}<br />
                    Contacto: {prov.phone || 'N/A'}<br />
                    ID: {prov.id.substring(0,6)}
                  </div>
                </Popup>
              </Marker>
            ))}
          </MapContainer>
        )}
      </div>
    </div>
  )
}
