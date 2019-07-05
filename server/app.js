const http = require('http');

const server = http.createServer((req, res) => {
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/plain');

  let theParams = splitParams(req);

  if (typeof theParams !== 'undefined') {
  	let mid = theParams['mid'];

  	if (typeof mid !== 'undefined') {
  		getFirebaseCustomToken(res, mid);
  	}
  }

});

var ip = require("ip");

var hostname = ip.address();
const port = 3000;

server.listen(port, hostname, () => {
  console.log(`Server running at http://${hostname}:${port}/`);
});

var admin = require("firebase-admin");

initFirebase();

function initFirebase() {
	var serviceAccount = require("./chat-e9a53-firebase-adminsdk-4jfyn-0dc966850f.json");

	admin.initializeApp({
  		credential: admin.credential.cert(serviceAccount),
  		databaseURL: "https://chat-e9a53.firebaseio.com"
	});
}

function getFirebaseCustomToken(res, mid) {
	admin.auth().createCustomToken(mid)
	.then(function(customToken){
		res.end(customToken);
	})
	.catch(function(error) {
		console.log('Error creating custom token:', error);
	});
}

var splitParams = function(req) {
	let q = req.url.split('?'), result = {};
	if (q.length >= 2) {
		q[1].split('&').forEach((item) => {
			try {
				result[item.split('=')[0]] = item.split('=')[1];
			} catch (e) {
				result[item.split('=')[0]] = '';
			}
		})
	}
	return result;
}
