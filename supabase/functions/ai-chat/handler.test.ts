type Handler=(req:Request)=>Promise<Response>;
function assert(value:unknown,message:string){if(!value)throw Error(message)}
Deno.test('Diskusi dua giliran mempertahankan konteks dan menolak sesi pengguna lain',async()=>{
 const savedFetch=globalThis.fetch,savedServe=Deno.serve;
 const keys=['SUPABASE_URL','SUPABASE_ANON_KEY','SUPABASE_SERVICE_ROLE_KEY','GROQ_API_KEY'];const env=Object.fromEntries(keys.map(k=>[k,Deno.env.get(k)]));
 Deno.env.set('SUPABASE_URL','https://phali-test.invalid');Deno.env.set('SUPABASE_ANON_KEY','public-test');Deno.env.set('SUPABASE_SERVICE_ROLE_KEY','service-test');Deno.env.set('GROQ_API_KEY','groq-test');
 let handler:Handler|undefined;let calls=0;const prompts:Record<string,any>[]=[];const cache=new Map<string,{isi:string;dibuat_pada:string}>();
 const userA='aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',userB='bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
 const json=(value:unknown,status=200)=>new Response(JSON.stringify(value),{status,headers:{'Content-Type':'application/json'}});
 Object.defineProperty(Deno,'serve',{configurable:true,writable:true,value:(fn:Handler)=>{handler=fn;return{}}});
 globalThis.fetch=(async(input:RequestInfo|URL,init?:RequestInit)=>{
  const req=new Request(input,init),url=new URL(req.url);const auth=req.headers.get('Authorization')||'';
  if(url.pathname==='/auth/v1/user')return json({id:auth.includes('user-b')?userB:userA,email:'synthetic@example.invalid',role:'authenticated'});
  if(url.pathname==='/rest/v1/profiles')return json({role:auth.includes('viewer')?'viewer':'hr_admin'});
  if(url.pathname==='/rest/v1/rpc/admit_ai')return json(true);
  if(url.pathname==='/rest/v1/ai_cache'){
   if(req.method==='GET'){const key=(url.searchParams.get('kunci')||'').replace(/^eq\./,'');const row=cache.get(key);return json(row?[row]:[])}
   const body=await req.json();assert(auth.includes('service-test'),'Konteks hanya boleh ditulis memakai service role');cache.set(body.kunci,{isi:body.isi,dibuat_pada:body.dibuat_pada});return json(null);
  }
  if(url.pathname==='/rest/v1/audit_log')return json(null);
  if(url.pathname==='/rest/v1/rpc/rpc_turnover'){assert(!auth.includes('service-test'),'RPC metrik harus atas nama pengguna');return json({jumlah_keluar:4,bulanan:[{label:'2026-01',nilai:2}]})}
  if(url.hostname==='api.groq.com'){
   const body=await req.json();prompts.push(body);calls++;
   if(calls%2===1)return json({choices:[{message:{role:'assistant',content:null,tool_calls:[{id:'tool-'+calls,type:'function',function:{name:'get_turnover',arguments:'{}'}}]}}]});
   return json({choices:[{message:{role:'assistant',content:calls===2?'**Opsi pertama:** evaluasi retensi. **Opsi kedua:** periksa beban kerja.':'Opsi kedua memerlukan validasi beban kerja sebelum bertindak.'}}]});
  }
  throw Error('Panggilan tidak terduga: '+url.pathname);
 }) as typeof fetch;
 try{
  await import('./handler.ts');assert(handler,'Handler harus terdaftar');
  const request=(question:string,id?:string,user='user-a',sampai='2026-09-30')=>new Request('https://function.invalid',{method:'POST',headers:{Authorization:'Bearer '+user,'Content-Type':'application/json'},body:JSON.stringify({pertanyaan:question,dari:'2025-10-01',sampai,departemen:null,...(id?{percakapan_id:id}:{})})});
  const first=await handler!(request('Tinjau turnover, detail rahasia contact@example.invalid'));assert(first.status===200,'Giliran pertama harus berhasil');const a=await first.json();assert(typeof a.percakapan_id==='string','ID percakapan harus dikembalikan');
  const second=await handler!(request('Apa risiko opsi kedua?',a.percakapan_id));assert(second.status===200,'Giliran kedua harus berhasil');const b=await second.json();assert(b.percakapan_id===a.percakapan_id,'Diskusi harus menggunakan ID sama');
  assert(JSON.stringify(prompts[2].messages).includes('Opsi kedua'),'Jawaban sebelumnya harus menjadi konteks model');assert(!JSON.stringify(prompts).includes('contact@example.invalid'),'Identitas bebas tidak boleh dikirim ke model');
  const denied=await handler!(request('Lanjutkan',a.percakapan_id,'user-b'));assert(denied.status===409,'Pengguna lain tidak boleh membuka konteks percakapan');
  const changed=await handler!(request('Lanjutkan',a.percakapan_id,'user-a','2026-08-31'));assert(changed.status===409,'Filter berubah harus menolak konteks lama');
  const viewer=await handler!(request('Tinjau turnover',undefined,'viewer'));assert(viewer.status===403,'Pengamat tidak boleh memakai chat');assert(calls===4,'Permintaan ditolak tidak boleh memanggil Groq');
 }finally{globalThis.fetch=savedFetch;Object.defineProperty(Deno,'serve',{configurable:true,writable:true,value:savedServe});for(const key of keys){if(env[key]===undefined)Deno.env.delete(key);else Deno.env.set(key,env[key]!)}}
});
