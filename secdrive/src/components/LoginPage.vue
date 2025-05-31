<script setup lang="ts">
  import { ref } from 'vue';
  import { auth } from '@/config';
  import { signInWithEmailAndPassword } from 'firebase/auth';
  import router from '@/router/index.js';
  import { onMounted } from 'vue';
  import { Button } from '@/components/ui/button'
  import loginCheck from '@/logincheck';
  import { useUserStore } from '@/stores/userStore'
  import { toast } from 'vue-sonner'

  const userStore = useUserStore();
  const email = ref('');
  const password = ref('');
  async function signIn() {

        if (email.value === '' || password.value === '') {
            toast.error('Please fill in all fields', { style: { backgroundColor: 'red' } });
            return;
        }

        const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailPattern.test(email.value)) {
            toast.error('Please enter a valid email address', { style: { backgroundColor: 'red' } });
            return;
        }

        try {
            const userCredential = await signInWithEmailAndPassword(auth, email.value, password.value);
            const user = userCredential.user;
            console.log('User:', user);
            console.log('User id:', user.uid);

            toast.success('Successfully logged in', { style: { backgroundColor: 'green' } });
            userStore.fetchUserData(user.uid);
            router.push('/dashboard');
        } catch (error: any) {
            if (error.code === 'auth/invalid-login-credentials' || error.code === 'auth/invalid-credential') {
              console.error('Error:', error);  
              toast.error('Invalid login credentials', { style: { backgroundColor: 'red' } });
            } else if (error.code === 'auth/too-many-requests') {
              console.error('Error:', error);
              toast.error('Too many failed login attempts. Please try again later or reset your password.', { 
                style: { backgroundColor: 'red' },
                duration: 6000 
              });
            } else if (error.code === 'auth/user-disabled') {
              console.error('Error:', error);
              toast.error('This account has been disabled. Please contact support.', { 
                style: { backgroundColor: 'red' },
                duration: 6000 
              });
            } else {
              console.error('Error:', error);
              toast.error('An error occurred while logging in', { style: { backgroundColor: 'red' } });
            }
        }
    }

    onMounted(() => {
        loginCheck();
    });
</script>

<template>
  <div class="flex items-center justify-center min-h-screen bg-gradient-to-br from-indigo-900 to-black px-4">
    <div class="w-full max-w-md bg-card p-8 rounded-lg shadow-md">
      <h2 class="text-2xl font-semibold mb-6 text-center text-white">Login to SecDrive</h2>
      <form class="space-y-4">
        <input
          v-model="email"
          type="email"
          placeholder="Email"
          class="w-full p-3 border border-gray-600 rounded-md bg-input text-gray-200"
        />
        <input
          v-model="password"
          type="password"
          placeholder="Password"
          class="w-full p-3 border border-gray-600 rounded-md bg-input text-gray-200"
        />
        <Button 
          type="button" 
          @click="signIn" 
          class="w-full bg-indigo-600 hover:bg-indigo-700 text-white cursor-pointer"
          >
          Login
        </Button>
      </form>
      <p class="mt-4 text-center text-sm text-gray-300">
        Don't have an account? <router-link to="/signup" class="text-indigo-500 underline">Sign Up</router-link>
      </p>
    </div>
  </div>
</template>