const fs = require('fs');
let content = fs.readFileSync('src/data.js', 'utf8');

// The new logic to insert
const newLogic = `export const getRequestsForProvider = async (providerId) => {
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
};`;

// Find and replace the FIRST getRequestsForProvider
const startMatch = content.indexOf('export const getRequestsForProvider');
const endMatch = content.indexOf('export const updateRequestStatus');
if (startMatch !== -1 && endMatch !== -1) {
    content = content.substring(0, startMatch) + newLogic + '\n\n' + content.substring(endMatch);
}

// Find and remove the SECOND getRequestsForProvider that was appended at the end
const startMatch2 = content.lastIndexOf('export const getRequestsForProvider');
const endMatch2 = content.indexOf('export const checkIfMatched');
if (startMatch2 !== -1 && startMatch2 !== startMatch && endMatch2 !== -1) {
    content = content.substring(0, startMatch2) + content.substring(endMatch2);
}

fs.writeFileSync('src/data.js', content);
