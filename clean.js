const url = 'https://nbgbubmefhsvrykwdump.supabase.co';
const key = 'sb_publishable_3jFLNNT3JVmFCHlNRazdDA_PI3bG5Ow';

async function run() {
  // 1. Check who is there
  const res1 = await fetch(`${url}/rest/v1/providers?select=name,id`, {
    headers: { 'apikey': key, 'Authorization': `Bearer ${key}` }
  });
  const data = await res1.json();
  console.log('Current providers:', data);

  // 2. Delete Pablo and Diego
  const res2 = await fetch(`${url}/rest/v1/providers?name=in.(Pablo,Diego)`, {
    method: 'DELETE',
    headers: { 'apikey': key, 'Authorization': `Bearer ${key}` }
  });
  console.log('Deleted status:', res2.status);
}
run();
