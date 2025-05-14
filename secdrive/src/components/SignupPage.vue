<script setup lang="ts">
import { Button } from '@/components/ui/button'
</script>

<template>
  <div class="flex items-center justify-center min-h-screen bg-gradient-to-br from-gray-900 to-black px-4">
    <div class="w-full max-w-md bg-card p-8 rounded-lg shadow-md">
      <h2 class="text-2xl font-semibold mb-6 text-center text-white">Create Your SecDrive Account</h2>
      <form class="space-y-4">
        <input
          type="text"
          placeholder="First Name"
          class="w-full p-3 border border-gray-600 rounded-md bg-input text-gray-200"
        />
        <input
          type="text"
          placeholder="Last Name"
          class="w-full p-3 border border-gray-600 rounded-md bg-input text-gray-200"
        />
        <input
          type="email"
          placeholder="Email"
          class="w-full p-3 border border-gray-600 rounded-md bg-input text-gray-200"
        />
        <input
          type="password"
          placeholder="Password"
          class="w-full p-3 border border-gray-600 rounded-md bg-input text-gray-200"
        />
        <input
          type="password"
          placeholder="Confirm Password"
          class="w-full p-3 border border-gray-600 rounded-md bg-input text-gray-200"
        />
        <Button type="submit" class="w-full bg-indigo-600 hover:bg-indigo-700 text-white">Sign Up</Button>
      </form>
      <p class="mt-4 text-center text-sm text-gray-300">
        Already have an account? <router-link to="/login" class="text-indigo-500 underline">Login</router-link>
      </p>
    </div>
  </div>
</template>