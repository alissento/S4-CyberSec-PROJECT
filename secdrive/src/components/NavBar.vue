<template>
    <nav class="border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div class="container mx-auto flex h-14 max-w-screen-2xl items-center justify-between px-4 sm:px-6 lg:px-8">
        <!-- Logo -->
        <a href="/" class="mr-6 flex items-center space-x-2">
          <!-- Replace with your SVG or img tag -->
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="h-6 w-6">
            <path d="M15 6v12a3 3 0 1 0 3-3H6a3 3 0 1 0 3 3V6a3 3 0 1 0-3 3h12a3 3 0 1 0-3-3"/>
          </svg>
          <span class="font-bold inline-block">MyApp</span>
        </a>
  
        <!-- Navigation Links -->
        <div class="hidden md:flex flex-1 items-center justify-center space-x-6 text-sm font-medium">
          <a
            href="#"
            class="text-foreground/60 transition-colors hover:text-foreground/80"
          >
            Features
          </a>
          <a
            href="#"
            class="text-foreground/60 transition-colors hover:text-foreground/80"
          >
            Pricing
          </a>
          <a
            href="#"
            class="text-foreground/60 transition-colors hover:text-foreground/80"
          >
            Docs
          </a>
          <a
            href="#"
            class="text-foreground/60 transition-colors hover:text-foreground/80"
          >
            About
          </a>
        </div>
  
        <!-- Login/Actions -->
        <div class="flex items-center space-x-4">
           <!-- Using the shadcn-vue Button component -->
          <Button variant="ghost" size="sm">Log in</Button>
          <Button size="sm">Sign Up</Button>
           <!-- Mobile Menu Button (optional, requires more logic) -->
           <Button variant="outline" size="icon" class="md:hidden">
              <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="h-5 w-5"><line x1="3" x2="21" y1="6" y2="6"/><line x1="3" x2="21" y1="12" y2="12"/><line x1="3" x2="21" y1="18" y2="18"/></svg>
              <span class="sr-only">Toggle Menu</span>
           </Button>
        </div>
      </div>
    </nav>
  </template>
  
  <script setup lang="ts">
  // Import the Button component after adding it via shadcn-vue CLI
  import { Button } from '@/components/ui/button' // Adjust path if needed
  
  // No specific script logic needed for this simple static navbar
  // Add mobile menu toggle logic here if implementing the mobile button
  </script>
  
  <style scoped>
  /* Add any component-specific scoped styles here if needed */
  /* Usually, shadcn-vue relies on global styles and Tailwind utilities */
  </style>