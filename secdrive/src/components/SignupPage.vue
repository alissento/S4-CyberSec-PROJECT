<script setup lang="ts">
  import { ref } from 'vue';
  import { auth, apiURL } from '@/config.js';
  import { createUserWithEmailAndPassword, signOut } from 'firebase/auth';
  import router from '@/router/index.js';
  import { onMounted } from 'vue';
  import loginCheck from '@/logincheck';
  import { Button } from '@/components/ui/button'

  const firstName = ref('');
  const lastName = ref('');
  const email = ref('');
  const password = ref('');
  const repeatPassword = ref('');

  async function registerIn() {

    if (!firstName || !lastName || !email || !password || !repeatPassword) {
      alert('Please fill in all fields');
      return;
    }

    const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailPattern.test(email.value)) {
      alert('Please enter a valid email address');
      return;
    }

    if (password.value !== repeatPassword.value) {
      alert('Passwords do not match');
      return;
    }

    try {
      const userCredential = await createUserWithEmailAndPassword(auth, email.value, password.value);
      const user = userCredential.user;
      console.log('User:', user);
      console.log('User id:', user.uid);

      alert('Successfully registered');
            
      storeUserData();

      signOut(auth);
      router.push('/login');

    } catch (error: any) {
      if (error.code === 'auth/email-already-in-use') {
        alert('Email already in use');
      } else {
        console.error('Error:', error);
        alert('An error occurred while registering');
      }
    }
  }

  async function storeUserData() {
    const user = auth.currentUser;
    const fullApiUrl = apiURL + '/storeUserData';
    const requestData = {
      user_id: user.uid,
      email: email.value,
      firstName: firstName.value,
      lastName: lastName.value
    };

    try {
      const response = await fetch(`${fullApiUrl}?operation=register`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
        body: JSON.stringify(requestData)
      });

        console.log('Data stored successfully');
      } catch (error) {
        console.error('Error:', error);
      }
    }

    onMounted(() => {
        loginCheck();
    });
</script>

<template>
  <div class="flex items-center justify-center min-h-screen bg-gradient-to-br from-gray-900 to-black px-4">
    <div class="w-full max-w-md bg-card p-8 rounded-lg shadow-md">
      <h2 class="text-2xl font-semibold mb-6 text-center text-white">Create Your SecDrive Account</h2>
      <form class="space-y-4">
        <input
          v-model="firstName"
          type="text"
          placeholder="First Name"
          class="w-full p-3 border border-gray-600 rounded-md bg-input text-gray-200"
        />
        <input
          v-model="lastName"
          type="text"
          placeholder="Last Name"
          class="w-full p-3 border border-gray-600 rounded-md bg-input text-gray-200"
        />
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
        <input
          v-model="repeatPassword"
          type="password"
          placeholder="Confirm Password"
          class="w-full p-3 border border-gray-600 rounded-md bg-input text-gray-200"
        />
        <Button type="button" @click="registerIn" class="w-full bg-indigo-600 hover:bg-indigo-700 text-white">Sign Up</Button>
      </form>
      <p class="mt-4 text-center text-sm text-gray-300">
        Already have an account? <router-link to="/login" class="text-indigo-500 underline">Login</router-link>
      </p>
    </div>
  </div>
</template>