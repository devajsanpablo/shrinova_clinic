import assert from 'node:assert/strict';
const project = 'demo-clinic';
const host = process.env.FIRESTORE_EMULATOR_HOST;
assert(host, 'Run through firebase emulators:exec');
const root = `http://${host}/v1/projects/${project}/databases/(default)/documents`;
const encode = value => value === null ? {nullValue:null} : typeof value === 'boolean' ? {booleanValue:value} : typeof value === 'number' ? {integerValue:value} : typeof value === 'string' ? {stringValue:value} : Array.isArray(value) ? {arrayValue:{values:value.map(encode)}} : {mapValue:{fields:fields(value)}};
const fields = data => Object.fromEntries(Object.entries(data).map(([k,v])=>[k,encode(v)]));
const token = uid => {
  const now = Math.floor(Date.now()/1000);
  return [ {alg:'none',typ:'JWT'}, {sub:uid,user_id:uid,aud:project,iss:`https://securetoken.google.com/${project}`,iat:now,exp:now+3600,firebase:{sign_in_provider:'password'}} ].map(v=>Buffer.from(JSON.stringify(v)).toString('base64url')).join('.')+'.';
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
await check(await call('/doctor/doctor','PATCH',{fields:fields({uid:'doctor',username:'Dr Test'})},'owner'),true,'seed doctor');
await check(await call('/patients/patient','PATCH',{fields:fields({firstName:'Test'})},'owner'),true,'seed patient');
const queueDay = new Date().toISOString().slice(0,10);
await check(await call(`/queueCounters/${queueDay}`,'PATCH',{fields:fields({count:1})},token('staff')),true,'staff creates daily queue counter');
await check(await call(`/queueCounters/${queueDay}`,'GET',null,token('staff')),true,'staff reads daily queue counter before ticket');
await check(await call(`/queueCounters/${queueDay}`,'GET',null,token('outsider')),false,'outsider cannot read daily queue counter');
await check(await call(`/queueCounters/${queueDay}`,'PATCH',{fields:fields({count:2})},token('staff')),true,'staff increments daily queue counter');
await check(await call(`/queueCounters/${queueDay}`,'PATCH',{fields:fields({count:1})},token('staff')),false,'daily queue counter cannot reset during the day');
await check(await call(`/queueCounters/${queueDay}-invalid`,'PATCH',{fields:fields({count:1})},token('staff')),false,'invalid day rejected');
const laterDay = new Date(Date.now() + 86400000).toISOString().slice(0,10);
await check(await call(`/queueCounters/${laterDay}`,'PATCH',{fields:fields({count:5})},token('staff')),true,'counter can begin after earlier tickets');
let next = 0;
async function create(uid, changes={}, allowed=true) {
  const id = `ticket-${next++}`;
  const data = {queueNumber:'No.1',patientId:'patient',complaint:'Headache',reason:'Visit',symptoms:['Dizziness'],bloodPressure:'',heartRate:'',temperature:'',oxygen:'',doctor:'Dr Test',doctorUid:'doctor',priority:'normal',notes:'',createdAt:new Date().toISOString(),status:'sent',createdBy:uid,consultation:null,...changes};
  const body={writes:[{update:{name:`projects/${project}/databases/(default)/documents/tickets/${id}`,fields:fields(data)},updateTransforms:[{fieldPath:'savedAt',setToServerValue:'REQUEST_TIME'}]}]};
  await check(await call(':commit','POST',body,uid?token(uid):undefined),allowed,`create ${uid || 'anonymous'} ${JSON.stringify(changes)}`);
  return id;
}
await check(await call('/doctor/other','PATCH',{fields:fields({uid:'other',username:'Other Doctor'})},'owner'),true,'seed other doctor');
await check(await call('/doctor','GET',null,token('staff')),true,'staff can load doctor usernames');
await check(await call('/doctor','GET',null,token('outsider')),false,'outsider cannot load doctors');
await create('staff',{doctorUid:'missing'},false);
await create('staff',{doctor:'Wrong username'},false);
const id = await create('staff');
await check(await call('/tickets/'+id+'?updateMask.fieldPaths=status','PATCH',{fields:fields({status:'inConsultation'})},token('other')),false,'unassigned doctor cannot accept ticket');
await check(await call('/doctor/doctor/notifications/test','PATCH',{fields:fields({read:false,title:'New ticket'})},'owner'),true,'seed inbox');
await check(await call('/doctor/doctor/notifications','GET',null,token('doctor')),true,'doctor reads own inbox');
await check(await call('/doctor/doctor/notifications','GET',null,token('staff')),false,'staff cannot read doctor inbox');
await check(await call('/doctor/doctor/notifications/test?updateMask.fieldPaths=read','PATCH',{fields:fields({read:true})},token('doctor')),true,'doctor marks read');
await check(await call('/doctor/doctor/notifications/test?updateMask.fieldPaths=title','PATCH',{fields:fields({title:'Forged'})},token('doctor')),false,'doctor cannot forge notification');
await check(await call('/doctor/doctor/devices/test','PATCH',{fields:fields({token:'test'})},'owner'),true,'seed device');
await check(await call('/doctor/doctor/devices','GET',null,token('other')),false,'other doctor cannot read tokens');
await check(await call('/doctor/doctor/devices/test','DELETE',null,token('doctor')),true,'doctor removes own token');
await create('doctor',{status:'draft'},false);
await create('staff',{status:'draft'},false);
await create('',{},false);
await create('outsider',{},false);
await create('staff',{patientId:'missing'},false);
await create('staff',{complaint:''},false);
await create('staff',{priority:'invalid'},false);
await create('staff',{status:'completed'},false);
await create('staff',{createdBy:'doctor'},false);
await create('staff',{extra:'field'},false);
await check(await call('/tickets','GET',null,token('staff')),true,'staff list');
await check(await call('/tickets','GET',null,token('outsider')),false,'outsider list');
await check(await call(`/tickets/${id}?updateMask.fieldPaths=status`,'PATCH',{fields:fields({status:'inConsultation'})},token('staff')),false,'staff cannot change clinical status');
await check(await call(`/tickets/${id}?updateMask.fieldPaths=status`,'PATCH',{fields:fields({status:'inConsultation'})},token('doctor')),true,'doctor starts');
const consultation={date:new Date().toISOString(),doctor:'Dr Test',complaint:'Headache',diagnosis:'Test diagnosis',treatment:'Test treatment',prescription:'None'};
await check(await call(`/tickets/${id}?updateMask.fieldPaths=status&updateMask.fieldPaths=consultation`,'PATCH',{fields:fields({status:'completed',consultation})},token('doctor')),true,'doctor completes');
await check(await call(`/tickets/${id}?updateMask.fieldPaths=status`,'PATCH',{fields:fields({status:'inConsultation'})},token('doctor')),false,'completed is immutable');
await check(await call(`/tickets/${id}`,'DELETE',null,token('doctor')),false,'deletion denied');
console.log('All ticket rules checks passed.');
