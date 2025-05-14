<script setup lang="ts">
  import { ref } from 'vue';
  import { auth } from '@/config.js';
  import { signInWithEmailAndPassword } from 'firebase/auth';
  import router from '@/router/index.js';
  import { onMounted } from 'vue';
  import { Button } from '@/components/ui/button'

  const email = ref('');
  const password = ref('');

  async function signIn() {

        if (email.value === '' || password.value === '') {
            alert('Please fill in all fields');
            return;
        }

        const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailPattern.test(email.value)) {
            alert('Please enter a valid email address');
            return;
        }

        try {
            const userCredential = await signInWithEmailAndPassword(auth, email.value, password.value);
            const user = userCredential.user;
            console.log('User:', user);
            console.log('User id:', user.uid);

            alert('Successfully logged in');
            
            router.push('/dashboard');
        } catch (error: any) {
            if (error.code === 'auth/invalid-login-credentials' || error.code === 'auth/invalid-credential') {
              console.error('Error:', error);  
              alert('Invalid login credentials');
            } else {
                console.error('Error:', error);
                alert('An error occurred while logging in');
            }
        }
    }
</script>

<template>
  <div class="flex items-center justify-center min-h-screen bg-gradient-to-br from-gray-900 to-black px-4">
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
        <Button type="button" @click="signIn" class="w-full bg-indigo-600 hover:bg-indigo-700 text-white">Login</Button>
      </form>
      <p class="mt-4 text-center text-sm text-gray-300">
        Don't have an account? <router-link to="/signup" class="text-indigo-500 underline">Sign Up</router-link>
      </p>
      <p class="mt-4 text-center text-sm text-gray-300">
        <router-link to="/dashboard" class="text-navy-500">Go to dashboard (dev)</router-link>
      </p>
    </div>
  </div>
</template>