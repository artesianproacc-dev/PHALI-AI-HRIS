import{createClient}from '@supabase/supabase-js';
export const configured=Boolean(import.meta.env.VITE_SUPABASE_URL&&import.meta.env.VITE_SUPABASE_ANON_KEY);
export const supabase=createClient(import.meta.env.VITE_SUPABASE_URL||'https://placeholder.supabase.co',import.meta.env.VITE_SUPABASE_ANON_KEY||'belum-dikonfigurasi');
export type Metrics=Record<string,number|{label:string;nilai:number;[key:string]:unknown}[]>;
// RPC uses POST. Workbox cannot cache POST. Persist only aggregate results, scoped
// to auth user and full filter; never persist auth endpoints, AI, or employee rows.
export async function metrics(modul:string,dari:string,sampai:string,departemen:string,user:string,onCached?:(value:{data:Metrics;offline:boolean;saved:string})=>void):Promise<{data:Metrics;offline:boolean;saved:string}>{
 const key=`hr:${user}:${modul}:${dari}:${sampai}:${departemen}`;
 const cached=()=>{const raw=localStorage.getItem(key);if(!raw)throw Error('Belum ada ringkasan tersimpan untuk filter ini. Hubungkan internet terlebih dahulu.');const v=JSON.parse(raw);return{...v,offline:true}};
 if(!navigator.onLine)return cached();
 if(localStorage.getItem(key)&&onCached){try{onCached(cached())}catch{/* stale data is optional */}}
 const{data,error}=await supabase.rpc(`rpc_${modul}`,{p_dari:dari,p_sampai:sampai,p_departemen:departemen||null});
 if(error){if(!navigator.onLine||error.message.includes('fetch'))return cached();throw Error(error.message)}
 const value={data,saved:new Date().toISOString(),offline:false};try{localStorage.setItem(key,JSON.stringify(value))}catch{/* storage may be full */}return value;
}
export function clearOffline(){for(const k of Object.keys(localStorage))if(k.startsWith('hr:'))localStorage.removeItem(k)}
export async function ai(name:string,body:Record<string,unknown>){const{data,error}=await supabase.functions.invoke(name,{body});if(error){let message='Layanan AI belum tersedia atau kuota sedang penuh. Coba lagi sebentar.';if(error.context instanceof Response){const payload=await error.context.clone().json().catch(()=>null);if(payload&&typeof payload.error==='string')message=payload.error}throw Error(message);}if(data.error)throw Error(data.error);return data.isi as string;}
