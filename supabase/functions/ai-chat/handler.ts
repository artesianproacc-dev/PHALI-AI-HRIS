import {cors,respond,context,body,filters,SafeError,system,groq,failure,discussionPlan} from '../_shared/core.ts';
const mapping:Record<string,string>={get_ringkasan:'ringkasan',get_turnover:'turnover',get_absensi:'absensi',get_biaya:'biaya',get_rekrutmen:'rekrutmen',get_kinerja:'kinerja_pelatihan'};
type Turn={role:'user'|'assistant';content:string};
type Conversation={filter:Record<string,unknown>;modul:string[];messages:Turn[]};
Deno.serve(async req=>{
 if(req.method==='OPTIONS')return new Response('ok',{headers:cors});
 try{
  const c=await context(req),b=await body(req),f=filters(b);
  if(typeof b.pertanyaan!=='string'||!b.pertanyaan.trim()||b.pertanyaan.length>1500)throw new SafeError('Pesan wajib diisi, maksimal 1.500 karakter.');
  if(b.percakapan_id!=null&&(typeof b.percakapan_id!=='string'||!/^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/i.test(b.percakapan_id)))throw new SafeError('Identitas percakapan tidak valid.');
  const id=b.percakapan_id||crypto.randomUUID();
  const key=`chat:${c.id}:${id}`;
  let conversation:Conversation={filter:f,modul:[],messages:[]};
  if(b.percakapan_id){
   const{data:cached,error}=await c.service.from('ai_cache').select('isi,dibuat_pada').eq('kunci',key).maybeSingle();
   if(error)throw new SafeError('Percakapan belum dapat dibuka.',503);
   if(!cached||Date.now()-Date.parse(cached.dibuat_pada)>86400000)throw new SafeError('Percakapan sudah berakhir. Pilih Percakapan baru untuk melanjutkan.',409);
   try{conversation=JSON.parse(cached.isi)}catch{throw new SafeError('Percakapan tidak dapat dimuat. Mulai percakapan baru.',409)}
   if(JSON.stringify(conversation.filter)!==JSON.stringify(f))throw new SafeError('Filter telah berubah. Mulai percakapan baru agar data tetap sesuai.',409);
  }
  const plan=discussionPlan(b.pertanyaan,conversation.modul);
  if(plan.denied)return respond({isi:'Saya hanya membahas data agregat dan praktik HRD. Untuk menjaga privasi, saya tidak memberikan data atau penilaian karyawan perorangan.',percakapan_id:b.percakapan_id||null});
  if(plan.greeting)return respond({isi:'Halo! Saya **Ms. Phali**, HRD Assistant Anda. Kita bisa berdiskusi tentang kondisi SDM, retensi, absensi, biaya, rekrutmen, kinerja, atau praktik HRD. Apa yang ingin Anda bahas?',percakapan_id:b.percakapan_id||null});
  if(!plan.selected.length)return respond({isi:'Saya bisa membantu diskusi **SDM dan HRD**. Ceritakan topiknya, misalnya turnover, beban kerja, konflik tim, onboarding, atau prioritas pelatihan. Setelah itu, Anda bisa melanjutkan dengan pertanyaan seperti “mengapa begitu?” atau “buat rencana 30 hari”.',percakapan_id:b.percakapan_id||null});
  const tools=Object.entries(mapping).filter(([,m])=>plan.selected.includes(m)).map(([name,modul])=>({type:'function',function:{name,description:`Ambil metrik agregat ${modul} untuk filter aktif.`,parameters:{type:'object',properties:{},additionalProperties:false}}}));
  const prompt=system+' Anda sedang berdiskusi dengan Admin atau HRD. Gunakan gaya percakapan yang ramah, langsung menjawab tujuan pesan, dan kaitkan dengan diskusi sebelumnya bila relevan. Jangan selalu mengulang seluruh ringkasan. Pertanyaan user telah dinormalisasi di server untuk privasi. Gunakan tool pada setiap giliran untuk memverifikasi angka terkini. Pisahkan temuan angka dari saran kualitatif. Untuk pertanyaan mengapa, jangan menyimpulkan sebab hanya dari korelasi; sebutkan hipotesis dan cara memeriksanya. Jika diminta opsi kedua/pertama, rujuk opsi pada jawaban sebelumnya; jika tidak jelas, minta klarifikasi singkat. Untuk rencana, berikan tindakan, penanggung jawab berupa peran, dan indikator evaluasi; target numerik harus dilabeli usulan, bukan hasil data. Hindari pemecatan atau penilaian individu serta perlakuan merugikan berdasarkan usia/gender. Jangan mengklaim kepatuhan hukum tanpa sumber. Gunakan Markdown sederhana dengan paragraf pendek dan daftar; tabel hanya bila membantu. Maksimal sekitar 350 kata. Akhiri dengan satu pertanyaan tindak lanjut yang relevan bila membantu diskusi.';
  const messages:any[]=[{role:'system',content:prompt},...conversation.messages.slice(-8),{role:'user',content:`Tujuan diskusi: ${plan.canonical}. Filter data aktif: ${JSON.stringify(f)}`}];
  let isi='';
  for(let i=0;i<4;i++){
   const msg=await groq(messages,tools,i===0);messages.push(msg);
   if(!msg.tool_calls?.length){isi=msg.content||'Data belum cukup untuk menjawab. Bisa Anda perjelas topik HRD yang ingin dibahas?';break}
   if(msg.tool_calls.length>6)throw new SafeError('Pertanyaan terlalu luas. Pilih satu topik HRD terlebih dahulu.');
   for(const call of msg.tool_calls){const module=mapping[call.function.name];if(!module||!plan.selected.includes(module))throw new SafeError('Permintaan tool tidak diizinkan.');const{data,error}=await c.user.rpc(`rpc_${module}`,f);if(error)throw new SafeError('Ringkasan gagal dimuat.',503);messages.push({role:'tool',tool_call_id:call.id,content:JSON.stringify(data)})}
  }
  if(!isi){messages.push({role:'user',content:'Batas tool tercapai. Jawab berdasarkan agregat yang sudah tersedia tanpa menambah angka.'});isi=(await groq(messages)).content||'Saya belum mendapatkan data yang cukup. Mari persempit topiknya.'}
  const history:Turn[]=[...conversation.messages,{role:'user',content:`Tujuan diskusi: ${plan.canonical}`},{role:'assistant',content:isi}].slice(-8) as Turn[];
  const{error:saveError}=await c.service.from('ai_cache').upsert({kunci:key,isi:JSON.stringify({filter:f,modul:plan.selected,messages:history}),dibuat_pada:new Date().toISOString()});
  if(saveError)throw new SafeError('Konteks diskusi belum dapat disimpan. Coba lagi sebentar.',503);
  await c.service.from('audit_log').insert({user_id:c.id,aksi:'ai_chat',detail:{modul:plan.selected,filter:f,percakapan_id:id}});
  return respond({isi,percakapan_id:id});
 }catch(e){return failure(e)}
});
