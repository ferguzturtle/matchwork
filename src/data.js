import { supabase } from './supabase.js';

export const CATEGORIES = {
    construccion: {
        label: "Construcción y Reformas",
        icon: "construction",
        subcategories: {
            albanileria: { label: "Albañilería", icon: "construction" },
            pintura: { label: "Pintura", icon: "format_paint" },
            carpinteria: { label: "Carpintería", icon: "handyman" },
            gasfiteria: { label: "Gasfitería", icon: "plumbing" }
        }
    },
    salud: {
        label: "Servicios de Salud y Cuidado",
        icon: "medical_services",
        subcategories: {
            enfermeria: { label: "Enfermería", icon: "medical_services" },
            kinesiologia: { label: "Kinesiología", icon: "physical_therapy" },
            adulto_mayor: { label: "Cuidado de Adulto Mayor", icon: "elderly" },
            ninos: { label: "Cuidado de Niños", icon: "child_care" }
        }
    },
    instalaciones: {
        label: "Instalaciones y Electricidad",
        icon: "engineering",
        subcategories: {
            electricidad: { label: "Electricidad Residencial", icon: "bolt" },
            climatizacion: { label: "Climatización", icon: "ac_unit" },
            redes: { label: "Redes y Telecomunicaciones", icon: "router" }
        }
    },
    mantenimiento: {
        label: "Mantenimiento y Limpieza",
        icon: "cleaning_services",
        subcategories: {
            limpieza_hogar: { label: "Limpieza de Hogar", icon: "cleaning_services" },
            fumigacion: { label: "Fumigación", icon: "pest_control" },
            jardineria: { label: "Jardinería", icon: "yard" },
            piscinas: { label: "Limpieza de Piscinas", icon: "pool" }
        }
    },
    profesionales: {
        label: "Servicios Profesionales",
        icon: "support_agent",
        subcategories: {
            tutorias: { label: "Tutorías / Clases", icon: "school" },
            asistencia_tec: { label: "Asistencia Tecnológica", icon: "computer" },
            mudanzas: { label: "Mudanzas y Desembalaje", icon: "local_shipping" }
        }
    }
};

export const getSubcategoryIcon = (subcat) => {
    for (const catKey in CATEGORIES) {
        if (CATEGORIES[catKey].subcategories[subcat]) {
            return CATEGORIES[catKey].subcategories[subcat].icon;
        }
    }
    return 'plumbing'; // default fallback icon
};

export const getSubcategoryLabel = (subcat) => {
    for (const catKey in CATEGORIES) {
        if (CATEGORIES[catKey].subcategories[subcat]) {
            return CATEGORIES[catKey].subcategories[subcat].label;
        }
    }
    return subcat;
};

export const getCategoryLabel = (catKey) => {
    return CATEGORIES[catKey]?.label || catKey;
};

export let providers = [];

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
                    category: up.category || p.category,
                    subcategory: up.subcategory || p.subcategory
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
                    subcategory: up.subcategory || '',
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


export const getRequestsForProvider = async (providerId) => {
    try {
        const { data, error } = await supabase
            .from('service_requests')
            .select('id, provider_id, customer_id, message, status, created_at')
            .eq('provider_id', providerId);
            
        if (error) throw error;
        
        let profiles = [];
        if (data && data.length > 0) {
            const customerIds = data.map(req => req.customer_id).filter(id => id && id !== '00000000-0000-0000-0000-000000000000');
            if (customerIds.length > 0) {
                const { data: profilesData } = await supabase
                    .from('profiles')
                    .select('id, name')
                    .in('id', customerIds);
                if (profilesData) profiles = profilesData;
            }
        }
        
        return (data || []).map(req => {
            const profile = profiles.find(p => p.id === req.customer_id);
            return {
                id: req.id,
                providerId: req.provider_id,
                customerId: req.customer_id,
                message: req.message,
                status: req.status,
                userName: profile ? profile.name : 'Cliente de MatchWorking',
                timestamp: req.created_at
            };
        });
    } catch (e) {
        console.log('Fallback: obteniendo solicitudes de localStorage', e.message);
        const requests = JSON.parse(localStorage.getItem('prolink_requests') || '[]');
        return requests.filter(req => req.providerId == providerId).map(req => ({
            id: req.id,
            providerId: req.providerId,
            customerId: req.userId || req.customerId,
            userId: req.userId || req.customerId,
            message: req.message,
            status: req.status,
            userName: req.userName || 'Cliente de MatchWorking',
            timestamp: req.timestamp
        }));
    }
};

export const updateRequestStatus = async (requestId, status) => {
    // ALWAYS update localStorage first to ensure consistency for offline/fallback/demo mode
    try {
        const requests = JSON.parse(localStorage.getItem('prolink_requests') || '[]');
        const index = requests.findIndex(req => req.id == requestId);
        if (index !== -1) {
            requests[index].status = status;
            localStorage.setItem('prolink_requests', JSON.stringify(requests));
        }
    } catch (localErr) {
        console.warn("Error updating request status in localStorage", localErr);
    }

    try {
        const { data, error } = await supabase
            .from('service_requests')
            .update({ status: status })
            .eq('id', requestId);
        if (error) throw error;
        return data;
    } catch (e) {
        console.log("Fallback: actualizando solicitud en localStorage falló en Supabase", e.message);
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
                        category: role === 'customer' ? "" : "construccion",
                        subcategory: role === 'customer' ? "" : "gasfiteria",
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
                        console.warn("Error al auto-crear perfil (quizás falta esquema), usando perfil local en memoria:", insertError);
                        return newProfile;
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
            category: role === 'customer' ? "" : "construccion",
            subcategory: role === 'customer' ? "" : "gasfiteria",
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
    let category = "construccion"; 
    let subcategory = "gasfiteria"; 
    let profession = "Prestador General";

    try {
        const profile = await getUserProfile(providerId);
        if (profile) {
            name = profile.name || name;
            image = profile.avatar_url || image;
            if (profile.profession) profession = profile.profession;
            if (profile.category) category = profile.category;
            if (profile.subcategory) subcategory = profile.subcategory;
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
            subcategory,
            status, 
            lat, 
            lng,
            rating: 4.9, // Valor por defecto
            icon: getSubcategoryIcon(subcategory)
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
            subcategory,
            rating: 4.9, // Valor por defecto
            icon: getSubcategoryIcon(subcategory)
        };
        if (lat !== null && lng !== null) {
            updateData.lat = lat;
            updateData.lng = lng;
        }

        // Fetch basic info from 'profiles' to seed the 'providers' entry if it doesn't exist yet (dentro de try-catch para máxima robustez)
        try {
            const { data: profile } = await supabase
                .from('profiles')
                .select('name, avatar_url, profession, category, subcategory')
                .eq('id', providerId)
                .single();

            if (profile) {
                updateData.name = profile.name || updateData.name;
                updateData.image = profile.avatar_url || updateData.image;
                if (profile.profession) updateData.profession = profile.profession;
                if (profile.category) updateData.category = profile.category;
                if (profile.subcategory) {
                    updateData.subcategory = profile.subcategory;
                    updateData.icon = getSubcategoryIcon(profile.subcategory);
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
        const filtered = locs.filter(l => String(l.user_id) === String(userId));
        return filtered.length > 0 ? filtered : locs;
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

export const updateUserLocation = async (id, label, address, lat, lng) => {
    try {
        const { data, error } = await supabase
            .from('user_locations')
            .update({ label, address, lat, lng })
            .eq('id', id)
            .select();
        if (error) throw error;
        return data;
    } catch (e) {
        console.log("Fallback: actualizando ubicación en localStorage", e.message);
        const locs = JSON.parse(localStorage.getItem('prolink_locations') || '[]');
        const idx = locs.findIndex(l => l.id == id);
        if (idx !== -1) {
            locs[idx].label = label;
            locs[idx].address = address;
            if (lat !== undefined) locs[idx].lat = parseFloat(lat);
            if (lng !== undefined) locs[idx].lng = parseFloat(lng);
            localStorage.setItem('prolink_locations', JSON.stringify(locs));
            return [locs[idx]];
        }
        return null;
    }
};

// --- FUNCIONALIDADES DE FASE 3: ELIMINADO ---


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
        ]).select();
        if (error) throw error;
        return data;
    } catch (e) {
        console.log("Fallback: guardando solicitud en localStorage", e.message);
        const requests = JSON.parse(localStorage.getItem('prolink_requests') || '[]');
        const newReq = {
            id: Date.now().toString(),
            providerId: providerId,
            userId: userId,
            message: message,
            status: 'pendiente',
            timestamp: new Date().toISOString()
        };
        requests.push(newReq);
        localStorage.setItem('prolink_requests', JSON.stringify(requests));
        return [newReq];
    }
};

export const submitAppFeedback = async (comment) => {
    try {
        const { data: { user } } = await supabase.auth.getUser();
        const userId = user ? user.id : null;
        
        const { data, error } = await supabase
            .from('app_feedback')
            .insert([{ user_id: userId, comment }]);
            
        if (error) {
            console.error("Error guardando feedback en Supabase:", error);
            throw error;
        }
        return data;
    } catch (e) {
        console.log("Simulando envío de feedback (offline/error)", e.message);
        // Fallback local
        const saved = JSON.parse(localStorage.getItem('prolink_feedback') || '[]');
        saved.push({ comment, created_at: new Date().toISOString() });
        localStorage.setItem('prolink_feedback', JSON.stringify(saved));
        return saved;
    }
};

// --- FUNCIONALIDADES DE FAVORITOS (SERVICIOS GUARDADOS) ---
export const getSavedProviders = (userId) => {
    if (!userId) return [];
    try {
        const saved = JSON.parse(localStorage.getItem(`prolink_favorites_${userId}`) || '[]');
        return saved;
    } catch (e) {
        return [];
    }
};

export const toggleSavedProvider = (userId, provider) => {
    if (!userId) return false;
    try {
        let saved = JSON.parse(localStorage.getItem(`prolink_favorites_${userId}`) || '[]');
        const exists = saved.findIndex(p => p.id === provider.id);
        let isSaved = false;
        
        if (exists >= 0) {
            saved.splice(exists, 1);
        } else {
            saved.push({
                id: provider.id,
                name: provider.name,
                image: provider.image || provider.avatar_url,
                profession: provider.profession,
                category: provider.category,
                subcategory: provider.subcategory,
                rating: provider.rating || 4.9,
                lat: provider.lat,
                lng: provider.lng
            });
            isSaved = true;
        }
        
        localStorage.setItem(`prolink_favorites_${userId}`, JSON.stringify(saved));
        return isSaved;
    } catch (e) {
        console.error("Error toggling favorite", e);
        return false;
    }
};

// --- LOGICA DE SOLICITUDES Y MATCH (FASE 3) ---

export const createServiceRequest = async (providerId, customerId, message = "") => {
    // Reutilizamos requestService para consistencia
    return await requestService(providerId, customerId, message);
};

export const getProviderRequests = async (providerId) => {
    // Reutilizamos getRequestsForProvider que formatea correctamente los nombres y tiene fallback
    return await getRequestsForProvider(providerId);
};

export const acceptServiceRequest = async (requestId) => {
    try {
        await updateRequestStatus(requestId, 'aceptado');
        return true;
    } catch (e) {
        console.error("Error accepting service request:", e);
        return null;
    }
};

export const rejectServiceRequest = async (requestId) => {
    try {
        await updateRequestStatus(requestId, 'rechazado');
        return true;
    } catch (e) {
        console.error("Error rejecting service request:", e);
        return false;
    }
};

export const checkIfMatched = async (providerId, customerId) => {
    try {
        const { data, error } = await supabase
            .from('service_requests')
            .select('*')
            .eq('provider_id', providerId)
            .eq('customer_id', customerId)
            .eq('status', 'aceptado');
        if (error) throw error;
        if (data && data.length > 0) return true;
        
        // Fallback local
        const requests = JSON.parse(localStorage.getItem('prolink_requests') || '[]');
        return requests.some(r => r.providerId == providerId && (r.customerId == customerId || r.userId == customerId) && r.status === 'aceptado');
    } catch (e) {
        console.error("Error checking match status, using local fallback:", e);
        const requests = JSON.parse(localStorage.getItem('prolink_requests') || '[]');
        return requests.some(r => r.providerId == providerId && (r.customerId == customerId || r.userId == customerId) && r.status === 'aceptado');
    }
};
