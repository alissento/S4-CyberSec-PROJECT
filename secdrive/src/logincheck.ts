import { auth } from '@/config';
import { onAuthStateChanged } from 'firebase/auth';
import router from '@/router/index.js';

export default function loginCheck() {
    onAuthStateChanged(auth, (user) => {
        if (user) {
            console.log('User is logged in');
            router.push('/dashboard');
        } else {
            console.log('User is not logged in');        
        }
    });
}