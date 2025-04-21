<script setup lang="ts">
import Sidebar from '@/components/Sidebar.vue';
</script>

<template>
  <div class="flex min-h-screen w-full bg-background">
    <Sidebar />
    <div class="flex flex-1 flex-col sm:pl-60">
      <main class="flex-1 p-6 bg-background">
        <router-view />
      </main>
    </div>
  </div>
</template>