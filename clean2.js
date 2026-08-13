const url = 'https://nbgbubmefhsvrykwdump.supabase.co';
const key = 'sb_publishable_3jFLNNT3JVmFCHlNRazdDA_PI3bG5Ow';

async function run() {
  const res2 = await fetch(`${url}/rest/v1/providers?name=eq.Diego Miranda`, {
    method: 'DELETE',
    headers: { 'apikey': key, 'Authorization': `Bearer ${key}` }
  });
  console.log('Deleted Diego Miranda status:', res2.status);
}
run();
