export const roles={hr_admin:'Admin SDM',hr_staff:'Staf HR',manager:'Manajer',viewer:'Pengamat'} as const;
export type Role=keyof typeof roles;
export const canManageHR=(role:string)=>['hr_admin','hr_staff'].includes(role);
export const canUseAI=(role:string)=>['hr_admin','hr_staff','manager'].includes(role);
export const canManageOrganization=(role:string)=>role==='hr_admin';
export const roleDescriptions={hr_admin:'Analitik, Ms. Phali, data HR, audit, pengaturan perusahaan dan peran.',hr_staff:'Analitik, Ms. Phali, serta tambah, ubah, hapus dan impor data HR.',manager:'Analitik dan Ms. Phali untuk meninjau opsi keputusan; tanpa perubahan data HR.',viewer:'Melihat analitik, mengekspor dan mencetak. Tanpa akses AI atau perubahan data HR.'};
