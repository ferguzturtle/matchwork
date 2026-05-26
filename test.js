import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://llaneohgrdyklvietwtd.supabase.co'
const supabaseKey = 'sb_publishable_OUzYFVASx9tJMVZruUPYbA_k-jvLm1e'

const supabase = createClient(supabaseUrl, supabaseKey)

async function testConnection() {
    try {
        const { data, error } = await supabase.auth.signInWithPassword({
            email: 'test_connection2@test.com',
            password: 'password123',
        })
        console.log("SignIn response:", data, error)
    } catch (e) {
        console.error("SignUp exception:", e)
    }
}

testConnection()
