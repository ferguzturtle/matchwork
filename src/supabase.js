import { createClient } from "@supabase/supabase-js";

const supabaseUrl = "https://nbgbubmefhsvrykwdump.supabase.co";
const supabaseKey = "sb_publishable_3jFLNNT3JVmFCHlNRazdDA_PI3bG5Ow";

export const supabase = createClient(supabaseUrl, supabaseKey);
