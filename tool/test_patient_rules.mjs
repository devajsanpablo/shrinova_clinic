import assert from 'node:assert/strict';
const project = 'demo-clinic';
const host = process.env.FIRESTORE_EMULATOR_HOST;
assert(host, 'Run through firebase emulators:exec');
const base = `projects/${project}/databases/(default)/documents`;
const root = `http://${host}/v1/${base}`;
const encode = value => Buffer.isBuffer(value) ? {bytesValue: value.toString('base64')} :
  typeof value === 'number' ? {integerValue: String(value)} :
  typeof value === 'string' ? {stringValue:value} :
  Array.isArray(value) ? {arrayValue:{values:value.map(encode)}} : {mapValue:{fields:fields(value)}};
const fields = data => Object.fromEntries(Object.entries(data).map(([k,v])=>[k,encode(v)]));
const token = uid => {
  const now = Math.floor(Date.now()/1000);
  return [{alg:'none',typ:'JWT'}, {sub:uid,user_id:uid,aud:project,iss:`https://securetoken.google.com/${project}`,iat:now,exp:now+3600,firebase:{sign_in_provider:'password'}}].map(v=>Buffer.from(JSON.stringify(v)).toString('base64url')).join('.')+'.';
};
async function call(path, method, body, auth) {
  return fetch(root+path,{method,headers:{'Content-Type':'application/json',...(auth?{Authorization:`Bearer ${auth}`}:{})},body:body?JSON.stringify(body):undefined});
}
async function check(response, allowed, label) {
  const body = await response.text();
  assert.equal(response.ok,allowed,`${label}: ${response.status} ${body}`);
  console.log(`PASS ${label}`);
}
await check(await call('/staff/staff','PATCH',{fields:fields({uid:'staff'})},'owner'),true,'seed staff');
await check(await call('/doctor/doctor','PATCH',{fields:fields({uid:'doctor'})},'owner'),true,'seed doctor');
await check(await call('/counters/patients','PATCH',{fields:fields({lastNumber:1})},token('staff')),true,'initialize at PT-01');
await check(await call('/counters/patients','PATCH',{fields:fields({lastNumber:3})},token('staff')),false,'counter cannot skip');
await check(await call('/counters/patients','PATCH',{fields:fields({lastNumber:2})},token('doctor')),true,'increment to PT-02');
await check(await call('/counters/patients','PATCH',{fields:fields({lastNumber:1})},token('staff')),false,'counter cannot reset');
await check(await call('/counters/patients','GET',null,token('outsider')),false,'outsider cannot read counter');
const competing = await Promise.all(['staff','doctor'].map(uid => call('/counters/patients','PATCH',{fields:fields({lastNumber:3})},token(uid))));
assert.equal(competing.filter(result => result.ok).length, 1, 'only one competing counter increment succeeds');
console.log('PASS conflicting counter increment rejected');
const data = {firstName:'Test',lastName:'Patient',dateOfBirth:'2000-01-01',registeredAt:'2026-01-01',gender:'Female',phone:'1234567',address:'Test',allergies:[],conditions:[],medications:[],consultations:[],medicalHistory:'',labs:'Report',emergencyContactName:'',emergencyContactPhone:'',createdBy:'staff',vaccinationStatus:'Yes',vaccines:['Influenza'],labAttachments:['report.png']};
const patientWrite = (id, changes={}) => ({update:{name:`${base}/patients/${id}`,fields:fields({...data,...changes})},updateTransforms:[{fieldPath:'consentConfirmedAt',setToServerValue:'REQUEST_TIME'}]});
const imageWrite = (id, bytes=Buffer.from('image')) => ({update:{name:`${base}/patients/${id}/labAttachments/0`,fields:fields({name:'report.png',bytes})}});
await check(await call(':commit','POST',{writes:[patientWrite('PT-01'),imageWrite('PT-01')]},token('staff')),true,'patient and image save atomically');
await check(await call('/patients/PT-01/labAttachments/0','GET',null,token('doctor')),true,'doctor can view lab image');
await check(await call('/patients/PT-01/labAttachments/0','GET',null,token('outsider')),false,'outsider cannot view lab image');
await check(await call(':commit','POST',{writes:[patientWrite('bad-vaccine',{vaccines:[]})]},token('staff')),false,'vaccinated requires vaccine type');
await check(await call(':commit','POST',{writes:[patientWrite('bad-image'),imageWrite('bad-image',Buffer.alloc(750001))]},token('staff')),false,'oversized image rejected');
await check(await call('/patients/bad-image','GET',null,token('staff')),false,'failed image does not leave patient behind');
await check(await call(':commit','POST',{writes:[imageWrite('missing')]},token('staff')),false,'orphan image rejected');
await check(await call(':commit','POST',{writes:[imageWrite('PT-01')]},token('doctor')),false,'another user cannot replace lab result');
console.log('All patient rules checks passed.');
