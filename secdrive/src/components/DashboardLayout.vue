<script setup lang="ts">
import Sidebar from '@/components/Sidebar.vue';
import DashboardFiles from '@/components/DashboardFiles.vue';
</script>

<template>
  <div class="flex min-h-screen w-full bg-muted/40">
    <Sidebar />
    <div class="flex flex-1 flex-col sm:pl-60">
      <main class="flex-1 container mx-auto p-4 sm:p-6 md:p-8">
        <DashboardFiles />
      </main>
    </div>
  </div>
</template>