// Read-only schema inspection using the existing Firebase CLI login.
const path = require('node:path');
const cli = path.join(process.env.APPDATA, 'npm/node_modules/firebase-tools/lib');
const auth = require(path.join(cli, 'auth'));
const {requireAuth} = require(path.join(cli, 'requireAuth'));
const {Client} = require(path.join(cli, 'apiv2'));

(async () => {
  const account = auth.getProjectDefaultAccount(process.cwd()) || auth.getGlobalDefaultAccount();
  if (!account) throw new Error('Firebase CLI sign-in is required.');
  await requireAuth({project: 'clinic-86788', ...account});
  const client = new Client({urlPrefix: 'https://firestore.googleapis.com', apiVersion: 'v1'});
  const response = await client.get('projects/clinic-86788/databases/(default)/documents/doctor', {
    queryParams: {pageSize: 20},
  });
  const docs = response.body.documents || [];
  console.log(JSON.stringify({
    collection: 'doctor',
    documents: docs.map((doc, index) => ({
      index,
      fields: Object.fromEntries(Object.entries(doc.fields || {}).map(([key, value]) => [key, {
        type: Object.keys(value)[0],
        populated: value.stringValue !== undefined ? value.stringValue.trim().length > 0 : true,
      }])),
    })),
    hasMore: Boolean(response.body.nextPageToken),
  }, null, 2));
})().catch(() => {
  console.error('Doctor schema inspection failed (network or Firebase authorization).');
  process.exitCode = 1;
});

