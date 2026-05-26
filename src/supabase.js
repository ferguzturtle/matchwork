import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://llaneohgrdyklvietwtd.supabase.co'
const supabaseKey = 'sb_publishable_OUzYFVASx9tJMVZruUPYbA_k-jvLm1e'

export const supabase = createClient(supabaseUrl, supabaseKey)
