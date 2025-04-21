<script setup lang="ts">
import { Button } from '@/components/ui/button'
</script>

<template>
  <div
    class="flex flex-col items-center justify-center min-h-screen bg-gradient-to-br from-gray-900 to-black text-center px-4"
  >
    <h1 class="text-5xl font-bold mb-4 text-white drop-shadow-lg">
      Welcome to SecDrive
    </h1>
    <p class="text-lg text-gray-300 max-w-2xl mb-8">
      Secure cloud storage with end‑to‑end encryption and advanced security
      features. Access your files anywhere, anytime.
    </p>
    <div class="space-x-4">
      <router-link to="/signup">
        <Button variant="primary" size="lg" class="bg-indigo-600 hover:bg-indigo-700">
          Sign Up
        </Button>
      </router-link>
      <router-link to="/login">
        <Button variant="secondary" size="lg" class="border-gray-500 text-gray-200 hover:bg-gray-800">
          Log In
        </Button>
      </router-link>
    </div>
    <!-- Optional: simple features row -->
    <div class="mt-16 grid grid-cols-1 sm:grid-cols-3 gap-8 max-w-4xl">
      <div class="flex flex-col items-center text-gray-300">
        <Shield class="h-8 w-8 mb-2 text-indigo-500" />
        <h3 class="font-semibold">End‑to‑End Encryption</h3>
      </div>
      <div class="flex flex-col items-center text-gray-300">
        <Folder class="h-8 w-8 mb-2 text-indigo-500" />
        <h3 class="font-semibold">Organize Easily</h3>
      </div>
      <div class="flex flex-col items-center text-gray-300">
        <Users class="h-8 w-8 mb-2 text-indigo-500" />
        <h3 class="font-semibold">Team Sharing</h3>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* small fade‑in */
div > * {
  opacity: 0;
  animation: fadeIn 0.6s forwards;
}
div > *:nth-child(1) { animation-delay: 0.2s; }
div > *:nth-child(2) { animation-delay: 0.4s; }
div > *:nth-child(3) { animation-delay: 0.6s; }
@keyframes fadeIn {
  to { opacity: 1; transform: translateY(0); }
  from { opacity: 0; transform: translateY(10px); }
}
</style>