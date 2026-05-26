import { supabase } from './supabase.js';

export let providers = [
  {
    id: "11111111-1111-1111-1111-111111111111",
    name: "Carlos Mendoza",
    profession: "Maestro Gasfitero Autorizado",
    category: "gasfiteria",
    rating: 4.9,
    distance: "1.2 km",
    status: "En línea",
    lat: -33.4489,
    lng: -70.6693,
    icon: "plumbing",
    price: "$150",
    image: "https://lh3.googleusercontent.com/aida-public/AB6AXuBX-KmXfHIjVb7JHEf1pifVUCMhUSzU0CKsNGpek6wiAOoi6GNjsG34f0IgeZosy9X43RoDme6BsKQ1JF2H08sM5kdNgMWv5QFBWBIb5XZQya-COp1W7C0MqhEG0qYJE9bat9exBgFlf4iNg7YP6uRFRXVEmyHO5cxHtWVLxHe7WsEVvZ5HfVyU_9mXS_S7-ea_FMvI2TstyPw-jxcZHe2Wt_cy8__UXWDC7_bpWDaxIqx-RIhRAMXjflaGgH7WY932QbEneKM6_Ls",
    description: "Con más de 10 años de experiencia, ofrezco servicios de gasfitería certificados y garantizados. Especialista en urgencias, fugas y reparaciones completas. Respuesta rápida en toda la zona metropolitana."
  },
  {
    id: "22222222-2222-2222-2222-222222222222",
    name: "Francisco Javier",
    profession: "Electricista Certificado SEC",
    category: "electricidad",
    rating: 4.8,
    distance: "3.4 km",
    status: "Online",
    lat: -33.4350,
    lng: -70.6500,
    icon: "bolt",
    price: "$85",
    image: "https://lh3.googleusercontent.com/aida-public/AB6AXuCkkUwOuvyN2Qm4vmOiICtijtED3CJu4s_rWpmOyynM4l801tEL6X3P_Jnr2IcpevBIYD4BSbXAPRUX2AMCBP8C5k_9XtGS38PGXsVoaf30OkmuoOH1-NpV9avYaTU5tjbgLhRGTa8Y5KeSeBg1dMPTM9SnJLZSiAOb3S3am7yhuZGkkS1GljZv7wprS8rV-uwaf6C96yBq8oywa5GT9o_AHsvRQnNRgE1GlSjXCa1b0-qJOwT0wK_lP8Z1AL7t0M3nAKYbJgL9kn0",
    description: "Instalaciones eléctricas residenciales y comerciales. Evaluación de tableros, aumento de capacidad y certificaciones TE1. Seguridad y profesionalismo en cada trabajo."
  },
  {
    id: "33333333-3333-3333-3333-333333333333",
    name: "Ana Silva",
    profession: "Especialista en Limpieza Profunda",
    category: "limpieza",
    rating: 5.0,
    distance: "2.1 km",
    status: "Ocupado",
    lat: -33.4500,
    lng: -70.6400,
    icon: "cleaning_services",
    price: "$50",
    image: "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=150&q=80",
    description: "Servicio de limpieza profunda para casas y departamentos post-construcción o mudanza. Utilizo productos de alta gama y amigables con el medio ambiente."
  },
  {
    id: "44444444-4444-4444-4444-444444444444",
    name: "Roberto Rojas",
    profession: "Gasfiter Urgencias 24/7",
    category: "gasfiteria",
    rating: 4.7,
    distance: "0.8 km",
    status: "Online",
    lat: -33.4480,
    lng: -70.6680,
    icon: "plumbing",
    price: "$120",
    image: "https://images.unsplash.com/photo-1540569014015-19a7be504e3a?auto=format&fit=crop&w=150&q=80",
    description: "Reparación de filtraciones, destapes y mantención de calefont. Servicio rápido y eficiente."
  },
  {
    id: "55555555-5555-5555-5555-555555555555",
    name: "Luis Soto",
    profession: "Gasfiter Instalador SEC",
    category: "gasfiteria",
    rating: 4.9,
    distance: "2.5 km",
    status: "Busy",
    lat: -33.4520,
    lng: -70.6710,
    icon: "plumbing",
    price: "$180",
    image: "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=150&q=80",
    description: "Instalación de redes de gas y agua potable. Tramitación de certificados SEC."
  }
];

export const getProviders = async () => {
    let usingRealDb = false;
    try {
        const { data, error } = await supabase.from('providers').select('*');
        if (error) throw error;
        if (data) {
            providers = data;
            usingRealDb = true;
        }
    } catch (e) {
        console.log("Supabase no configurado o sin datos, usando fallback estático para proveedores.");
    }

    // SIEMPRE fusionar y agregar actualizaciones locales de localStorage, incluso con base de datos activa.
    // Esto garantiza sincronización cross-tab instantánea en pruebas locales (side-by-side) y fallbacks.
    try {
        const localUpdates = JSON.parse(localStorage.getItem('prolink_providers_updates') || '{}');
        
        // Mapear los existentes (ya sean de Supabase o estáticos)
        providers = providers.map(p => {
            if (localUpdates[p.id]) {
                const up = localUpdates[p.id];
                return {
                    ...p,
                    status: up.status,
                    lat: up.lat !== null ? up.lat : p.lat,
                    lng: up.lng !== null ? up.lng : p.lng,
                    name: up.name || p.name,
                    image: up.image || p.image,
                    profession: up.profession || p.profession,
                    category: up.category || p.category
                };
            }
            return p;
        });

        // Agregar los nuevos que no estaban en la lista
        Object.keys(localUpdates).forEach(id => {
            if (!providers.some(p => p.id === id)) {
                const up = localUpdates[id];
                providers.push({
                    id: id,
                    name: up.name,
                    profession: up.profession,
                    category: up.category,
                    rating: up.rating || 4.9,
                    status: up.status,
                    lat: up.lat !== null ? up.lat : -33.4489,
                    lng: up.lng !== null ? up.lng : -70.6693,
                    icon: up.icon || 'plumbing',
                    image: up.image,
                    price: "$100",
                    description: "Prestador verificado de la red MatchWorking."
                });
            }
        });
    } catch (err) {
        console.warn("Error fusionando actualizaciones de localStorage", err);
    }

    return providers;
};

export const requestService = async (providerId, userId, message) => {
    try {
        const { data: { user } } = await supabase.auth.getUser();
        const customer_id = user ? user.id : "00000000-0000-0000-0000-000000000000";

        const { data, error } = await supabase.from('service_requests').insert([
            {
                provider_id: providerId,
                customer_id: customer_id,
                message: message,
                status: 'pendiente'
            }
        ]);
        if (error) throw error;
        return data;
    } catch (e) {
        console.log("Fallback: guardando solicitud en localStorage", e.message);
        const requests = JSON.parse(localStorage.getItem('prolink_requests') || '[]');
        requests.push({
            id: Date.now().toString(),
            providerId: providerId,
            userId: userId,
            message: message,
            status: 'pendiente',
            timestamp: new Date().toISOString()
        });
        localStorage.setItem('prolink_requests', JSON.stringify(requests));
    }
};

export const getRequestsForProvider = async (providerId) => {
    try {
        // Obtenemos las solicitudes unidas a los perfiles para obtener el nombre del cliente
        const { data, error } = await supabase
            .from('service_requests')
            .select(`
                id,
                provider_id,
                customer_id,
                message,
                status,
                created_at,
                profiles:customer_id ( name )
            `)
            .eq('provider_id', providerId);
        if (error) throw error;
        
        // Mapear para uniformar la respuesta
        return (data || []).map(req => ({
            id: req.id,
            providerId: req.provider_id,
            customerId: req.customer_id,
            message: req.message,
            status: req.status,
            userName: req.profiles ? req.profiles.name : 'Cliente de MatchWorking',
            timestamp: req.created_at
        }));
    } catch (e) {
        console.log("Fallback: obteniendo solicitudes de localStorage", e.message);
        const requests = JSON.parse(localStorage.getItem('prolink_requests') || '[]');
        return requests.filter(req => req.providerId == providerId);
    }
};

export const updateRequestStatus = async (requestId, status) => {
    try {
        const { data, error } = await supabase
            .from('service_requests')
            .update({ status: status })
            .eq('id', requestId);
        if (error) throw error;
        return data;
    } catch (e) {
        console.log("Fallback: actualizando solicitud en localStorage", e.message);
        const requests = JSON.parse(localStorage.getItem('prolink_requests') || '[]');
        const index = requests.findIndex(req => req.id == requestId);
        if (index !== -1) {
            requests[index].status = status;
            localStorage.setItem('prolink_requests', JSON.stringify(requests));
        }
    }
};

export const getMessages = async (senderId, receiverId) => {
    try {
        const { data, error } = await supabase
            .from('messages')
            .select('*')
            .or(`and(sender_id.eq.${senderId},receiver_id.eq.${receiverId}),and(sender_id.eq.${receiverId},receiver_id.eq.${senderId})`)
            .order('created_at', { ascending: true });
        if (error) throw error;
        return data || [];
    } catch (e) {
        console.log("Fallback: obteniendo mensajes de localStorage", e.message);
        const msgs = JSON.parse(localStorage.getItem('prolink_messages') || '[]');
        return msgs.filter(m => 
            (m.sender_id === senderId && m.receiver_id === receiverId) ||
            (m.sender_id === receiverId && m.receiver_id === senderId)
        );
    }
};

export const sendMessage = async (senderId, receiverId, text, imageUrl = null) => {
    try {
        const { data, error } = await supabase
            .from('messages')
            .insert([
                {
                    sender_id: senderId,
                    receiver_id: receiverId,
                    text: text,
                    image_url: imageUrl
                }
            ]);
        if (error) throw error;
        return data;
    } catch (e) {
        console.log("Fallback: guardando mensaje en localStorage", e.message);
        const msgs = JSON.parse(localStorage.getItem('prolink_messages') || '[]');
        const newMsg = {
            id: Date.now().toString(),
            created_at: new Date().toISOString(),
            sender_id: senderId,
            receiver_id: receiverId,
            text: text,
            image_url: imageUrl
        };
        msgs.push(newMsg);
        localStorage.setItem('prolink_messages', JSON.stringify(msgs));
        return [newMsg];
    }
};

export const getUserProfile = async (userId) => {
    try {
        const { data, error } = await supabase
            .from('profiles')
            .select('*')
            .eq('id', userId)
            .single();
        if (error) {
            // Si el perfil no existe en Supabase (error PGRST116), lo creamos dinámicamente con la sesión activa
            if (error.code === 'PGRST116') {
                const { data: authData } = await supabase.auth.getUser();
                if (authData && authData.user && authData.user.id === userId) {
                    const user = authData.user;
                    const defaultName = user.email.split('@')[0];
                    const role = user.user_metadata?.role || localStorage.getItem('user_role') || 'customer';
                    
                    const newProfile = {
                        id: userId,
                        name: defaultName,
                        email: user.email,
                        role: role,
                        avatar_url: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80",
                        profession: role === 'customer' ? "" : "Nuevo Prestador",
                        category: role === 'customer' ? "" : "gasfiteria",
                        description: role === 'customer' ? "" : "Sin descripción disponible.",
                        price: role === 'customer' ? "" : "$0"
                    };
                    
                    const { data: insertedData, error: insertError } = await supabase
                        .from('profiles')
                        .insert([newProfile])
                        .select()
                        .single();
                        
                    if (!insertError && insertedData) {
                        return insertedData;
                    } else {
                        console.error("Error al auto-crear perfil:", insertError);
                    }
                }
            }
            throw error;
        }
        return data;
    } catch (e) {
        console.log("Fallback: obteniendo perfil de localStorage", e.message);
        const role = localStorage.getItem('user_role') || 'customer';
        const localProf = localStorage.getItem(`prolink_profile_${userId}`);
        if (localProf) return JSON.parse(localProf);
        
        return {
            id: userId,
            name: role === 'customer' ? "Nuevo Cliente" : "Nuevo Prestador",
            email: role === 'customer' ? "cliente@ejemplo.cl" : "prestador@ejemplo.cl",
            role: role,
            avatar_url: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80",
            profession: role === 'customer' ? "" : "Nuevo Prestador",
            category: role === 'customer' ? "" : "gasfiteria",
            description: role === 'customer' ? "" : "Sin descripción disponible.",
            price: role === 'customer' ? "" : "$0"
        };
    }
};

export const updateUserProfile = async (userId, profileData) => {
    try {
        const { data, error } = await supabase
            .from('profiles')
            .update(profileData)
            .eq('id', userId);
        if (error) throw error;
        return data;
    } catch (e) {
        console.log("Fallback: actualizando perfil en localStorage", e.message);
        const current = await getUserProfile(userId);
        const updated = { ...current, ...profileData };
        localStorage.setItem(`prolink_profile_${userId}`, JSON.stringify(updated));
        return updated;
    }
};

export const updateProviderAvailability = async (providerId, status, lat = null, lng = null) => {
    // Intentar obtener el perfil del usuario para tener los datos reales (nombre, avatar) en local
    let name = "Prestador General";
    let image = "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80";
    let category = "gasfiteria"; // Categoría por defecto para que aparezca en el mapa cuando se filtre
    let profession = "Prestador General";

    try {
        const profile = await getUserProfile(providerId);
        if (profile) {
            name = profile.name || name;
            image = profile.avatar_url || image;
            if (profile.profession) profession = profile.profession;
            if (profile.category) category = profile.category;
        }
    } catch (e) {
        console.warn("No se pudo obtener perfil para la actualización local:", e);
    }

    // Primero, actualizar en localStorage para activar el evento 'storage' instantáneamente en otras pestañas locales
    try {
        const localUpdates = JSON.parse(localStorage.getItem('prolink_providers_updates') || '{}');
        localUpdates[providerId] = { 
            id: providerId,
            name,
            image,
            profession,
            category,
            status, 
            lat, 
            lng,
            rating: 4.9, // Valor por defecto
            icon: category === 'electricidad' ? 'bolt' : (category === 'limpieza' ? 'cleaning_services' : (category === 'climatizacion' ? 'ac_unit' : 'plumbing'))
        };
        localStorage.setItem('prolink_providers_updates', JSON.stringify(localUpdates));
    } catch (err) {
        console.warn("Error guardando actualizaciones locales de proveedores", err);
    }

    try {
        const updateData = { 
            id: providerId, 
            status,
            name,
            image,
            profession,
            category,
            rating: 4.9, // Valor por defecto
            icon: category === 'electricidad' ? 'bolt' : (category === 'limpieza' ? 'cleaning_services' : (category === 'climatizacion' ? 'ac_unit' : 'plumbing'))
        };
        if (lat !== null && lng !== null) {
            updateData.lat = lat;
            updateData.lng = lng;
        }

        // Fetch basic info from 'profiles' to seed the 'providers' entry if it doesn't exist yet (dentro de try-catch para máxima robustez)
        try {
            const { data: profile } = await supabase
                .from('profiles')
                .select('name, avatar_url, profession, category')
                .eq('id', providerId)
                .single();

            if (profile) {
                updateData.name = profile.name || updateData.name;
                updateData.image = profile.avatar_url || updateData.image;
                if (profile.profession) updateData.profession = profile.profession;
                if (profile.category) {
                    updateData.category = profile.category;
                    updateData.icon = profile.category === 'electricidad' ? 'bolt' : (profile.category === 'limpieza' ? 'cleaning_services' : (profile.category === 'climatizacion' ? 'ac_unit' : 'plumbing'));
                }
            }
        } catch (profileErr) {
            console.warn("Error consultando la tabla profiles en updateProviderAvailability:", profileErr);
        }

        const { data, error } = await supabase
            .from('providers')
            .upsert(updateData);
        if (error) throw error;
        return data;
    } catch (e) {
        console.log("Fallback: actualizando disponibilidad en local", e.message);
    }
};

// --- FUNCIONALIDADES DE FASE 2: MÚLTIPLES UBICACIONES ---

export const getUserLocations = async (userId) => {
    try {
        const { data, error } = await supabase
            .from('user_locations')
            .select('*')
            .eq('user_id', userId);
        if (error) throw error;
        return data || [];
    } catch (e) {
        console.log("Fallback: obteniendo ubicaciones de localStorage", e.message);
        const locs = JSON.parse(localStorage.getItem('prolink_locations') || '[]');
        
        // Retornar ubicaciones por defecto si está vacío
        if (locs.length === 0) {
            const defaults = [
                { id: 1, user_id: userId, label: 'Mi Casa (Santiago)', address: 'Santiago Centro, Chile', lat: -33.4489, lng: -70.6693 },
                { id: 2, user_id: userId, label: 'Casa de Mamá (Providencia)', address: 'Providencia, Santiago, Chile', lat: -33.4312, lng: -70.6124 },
                { id: 3, user_id: userId, label: 'Casa de Playa (Viña)', address: 'Viña del Mar, Valparaíso, Chile', lat: -33.0245, lng: -71.5518 }
            ];
            localStorage.setItem('prolink_locations', JSON.stringify(defaults));
            return defaults;
        }
        return locs.filter(l => l.user_id === userId);
    }
};

export const saveUserLocation = async (userId, label, address, lat, lng) => {
    try {
        const { data, error } = await supabase
            .from('user_locations')
            .insert([{ user_id: userId, label, address, lat, lng }])
            .select();
        if (error) throw error;
        return data;
    } catch (e) {
        console.log("Fallback: guardando ubicación en localStorage", e.message);
        const locs = JSON.parse(localStorage.getItem('prolink_locations') || '[]');
        const newLoc = {
            id: Date.now(),
            user_id: userId,
            label,
            address,
            lat: parseFloat(lat),
            lng: parseFloat(lng),
            created_at: new Date().toISOString()
        };
        locs.push(newLoc);
        localStorage.setItem('prolink_locations', JSON.stringify(locs));
        return [newLoc];
    }
};

export const deleteUserLocation = async (id) => {
    try {
        const { data, error } = await supabase
            .from('user_locations')
            .delete()
            .eq('id', id);
        if (error) throw error;
        return data;
    } catch (e) {
        console.log("Fallback: eliminando ubicación de localStorage", e.message);
        const locs = JSON.parse(localStorage.getItem('prolink_locations') || '[]');
        const filtered = locs.filter(l => l.id != id);
        localStorage.setItem('prolink_locations', JSON.stringify(filtered));
        return true;
    }
};

// --- FUNCIONALIDADES DE FASE 3: TRANSPORTE CON RETORNO VACÍO ---

export const getTrips = async () => {
    try {
        const { data, error } = await supabase
            .from('trips')
            .select(`
                id,
                provider_id,
                origin_name,
                dest_name,
                origin_lat,
                origin_lng,
                dest_lat,
                dest_lng,
                price,
                departure_time,
                status,
                profiles:provider_id ( name, avatar_url, profession, category )
            `)
            .eq('status', 'disponible');
        if (error) throw error;
        return (data || []).map(t => ({
            id: t.id,
            provider_id: t.provider_id,
            origin_name: t.origin_name,
            dest_name: t.dest_name,
            origin_lat: parseFloat(t.origin_lat),
            origin_lng: parseFloat(t.origin_lng),
            dest_lat: parseFloat(t.dest_lat),
            dest_lng: parseFloat(t.dest_lng),
            price: t.price,
            departure_time: t.departure_time,
            status: t.status,
            provider_name: t.profiles ? t.profiles.name : 'Transportista',
            provider_avatar: t.profiles ? t.profiles.avatar_url : 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80',
            provider_profession: t.profiles ? t.profiles.profession : 'Chofer de Fletes',
            provider_category: t.profiles ? t.profiles.category : 'transporte'
        }));
    } catch (e) {
        console.log("Fallback: obteniendo viajes de localStorage", e.message);
        let trips = JSON.parse(localStorage.getItem('prolink_trips') || '[]');
        if (trips.length === 0) {
            trips = [
                {
                    id: 901,
                    provider_id: "11111111-1111-1111-1111-111111111111",
                    origin_name: "Valparaíso (Puerto)",
                    dest_name: "Santiago Centro",
                    origin_lat: -33.0472,
                    origin_lng: -71.6127,
                    dest_lat: -33.4489,
                    dest_lng: -70.6693,
                    price: "$45.000",
                    departure_time: "Hoy a las 18:30 hrs",
                    status: "disponible",
                    provider_name: "Carlos Mendoza",
                    provider_avatar: "https://lh3.googleusercontent.com/aida-public/AB6AXuBX-KmXfHIjVb7JHEf1pifVUCMhUSzU0CKsNGpek6wiAOoi6GNjsG34f0IgeZosy9X43RoDme6BsKQ1JF2H08sM5kdNgMWv5QFBWBIb5XZQya-COp1W7C0MqhEG0qYJE9bat9exBgFlf4iNg7YP6uRFRXVEmyHO5cxHtWVLxHe7WsEVvZ5HfVyU_9mXS_S7-ea_FMvI2TstyPw-jxcZHe2Wt_cy8__UXWDC7_bpWDaxIqx-RIhRAMXjflaGgH7WY932QbEneKM6_Ls",
                    provider_profession: "Especialista en Transporte y Fletes",
                    provider_category: "transporte"
                },
                {
                    id: 902,
                    provider_id: "22222222-2222-2222-2222-222222222222",
                    origin_name: "Viña del Mar (Reñaca)",
                    dest_name: "Providencia, Santiago",
                    origin_lat: -32.9745,
                    origin_lng: -71.5318,
                    dest_lat: -33.4312,
                    dest_lng: -70.6124,
                    price: "$55.000",
                    departure_time: "Mañana a las 09:00 hrs",
                    status: "disponible",
                    provider_name: "Francisco Javier",
                    provider_avatar: "https://lh3.googleusercontent.com/aida-public/AB6AXuCkkUwOuvyN2Qm4vmOiICtijtED3CJu4s_rWpmOyynM4l801tEL6X3P_Jnr2IcpevBIYD4BSbXAPRUX2AMCBP8C5k_9XtGS38PGXsVoaf30OkmuoOH1-NpV9avYaTU5tjbgLhRGTa8Y5KeSeBg1dMPTM9SnJLZSiAOb3S3am7yhuZGkkS1GljZv7wprS8rV-uwaf6C96yBq8oywa5GT9o_AHsvRQnNRgE1GlSjXCa1b0-qJOwT0wK_lP8Z1AL7t0M3nAKYbJgL9kn0",
                    provider_profession: "Mudanzas y Fletes Retorno",
                    provider_category: "transporte"
                }
            ];
            localStorage.setItem('prolink_trips', JSON.stringify(trips));
        }
        return trips.filter(t => t.status === 'disponible');
    }
};

export const publishTrip = async (providerId, tripData) => {
    try {
        const { data, error } = await supabase
            .from('trips')
            .insert([{
                provider_id: providerId,
                origin_name: tripData.origin_name,
                dest_name: tripData.dest_name,
                origin_lat: parseFloat(tripData.origin_lat),
                origin_lng: parseFloat(tripData.origin_lng),
                dest_lat: parseFloat(tripData.dest_lat),
                dest_lng: parseFloat(tripData.dest_lng),
                price: tripData.price,
                departure_time: tripData.departure_time,
                status: 'disponible'
            }])
            .select();
        if (error) throw error;
        return data;
    } catch (e) {
        console.log("Fallback: guardando viaje en localStorage", e.message);
        const trips = JSON.parse(localStorage.getItem('prolink_trips') || '[]');
        
        // Obtener detalles del perfil local del proveedor
        let providerName = "Transportista Asociado";
        let providerAvatar = "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&q=80";
        try {
            const profile = JSON.parse(localStorage.getItem(`prolink_profile_${providerId}`) || '{}');
            providerName = profile.name || providerName;
            providerAvatar = profile.avatar_url || providerAvatar;
        } catch (_) {}

        const newTrip = {
            id: Date.now(),
            provider_id: providerId,
            origin_name: tripData.origin_name,
            dest_name: tripData.dest_name,
            origin_lat: parseFloat(tripData.origin_lat),
            origin_lng: parseFloat(tripData.origin_lng),
            dest_lat: parseFloat(tripData.dest_lat),
            dest_lng: parseFloat(tripData.dest_lng),
            price: tripData.price,
            departure_time: tripData.departure_time,
            status: 'disponible',
            provider_name: providerName,
            provider_avatar: providerAvatar,
            provider_profession: 'Fletes y Mudanzas Retorno',
            provider_category: 'transporte',
            created_at: new Date().toISOString()
        };
        trips.push(newTrip);
        localStorage.setItem('prolink_trips', JSON.stringify(trips));
        return [newTrip];
    }
};

export const relocateProviders = (lat, lng, forceRelocateReal = false) => {
    // Relocalizar los proveedores mock estáticos cerca de la ubicación del cliente
    providers.forEach((p, idx) => {
        if (p.id.startsWith("11111111") || p.id.startsWith("22222222") || p.id.startsWith("33333333") || p.id.startsWith("44444444") || p.id.startsWith("55555555")) {
            const offsets = [
                { lat: 0.002, lng: 0.002 },
                { lat: -0.005, lng: 0.003 },
                { lat: 0.001, lng: -0.004 },
                { lat: -0.003, lng: -0.002 },
                { lat: 0.004, lng: 0.001 }
            ];
            const offset = offsets[idx % offsets.length];
            p.lat = lat + offset.lat;
            p.lng = lng + offset.lng;
        } else if (forceRelocateReal) {
            // Si es un prestador nuevo real (ID UUID) y está en la ubicación de Santiago por defecto,
            // lo reubicamos sutilmente cerca del cliente para que sea visible de inmediato al encender su disponibilidad
            const isNearDefaultSantiago = Math.abs(p.lat - (-33.4489)) < 0.01 && Math.abs(p.lng - (-70.6693)) < 0.01;
            if (isNearDefaultSantiago) {
                p.lat = lat + 0.0015;
                p.lng = lng - 0.0015;
            }
        }
    });
};
