import { initializeApp } from "firebase/app"
import { getAuth } from 'firebase/auth'
import axios from 'axios'

const firebaseConfig = {
  apiKey: "AIzaSyAg776WGD63lgtui9dsq63mYpkx01viEVs",
  authDomain: "secdrive-48782.firebaseapp.com",
  projectId: "secdrive-48782",
  storageBucket: "secdrive-48782.firebasestorage.app",
  messagingSenderId: "131786730288",
  appId: "1:131786730288:web:7335de95be20afee0b76f5"
};

const apiURL = 'https://api.nknez.tech';
const api = axios.create({
    baseURL: apiURL,
    headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
    },
});

export const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);

export { apiURL, api };
export default app;