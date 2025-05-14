<script setup lang="ts">
import { ref } from 'vue'
import { Button } from '@/components/ui/button'
import { Card, CardHeader, CardTitle, CardContent, CardFooter } from '@/components/ui/card'

const fullName = ref('')
const email = ref('')
const newPassword = ref('')
const confirmPassword = ref('')

function saveSettings() {
  console.log('Saving settings', { fullName: fullName.value, email: email.value, newPassword: newPassword.value, confirmPassword: confirmPassword.value })
}
</script>

<template>
  <div class="max-w-7xl mx-auto">
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-3xl font-semibold text-white">Settings</h1>
    </div>
    <Card>
      <CardHeader>
        <CardTitle>User Settings</CardTitle>
      </CardHeader>
      <form @submit.prevent="saveSettings">
        <CardContent class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-muted-foreground">First Name</label>
            <input v-model="fullName" type="text" placeholder="First Name" class="mt-1 w-full p-2 rounded-md bg-input text-foreground" />
          </div>
          <div>
            <label class="block text-sm font-medium text-muted-foreground">Last Name</label>
            <input v-model="fullName" type="text" placeholder="Last Name" class="mt-1 w-full p-2 rounded-md bg-input text-foreground" />
          </div>
          <div>
            <label class="block text-sm font-medium text-muted-foreground">Email Address</label>
            <input v-model="email" type="email" placeholder="Email Address" class="mt-1 w-full p-2 rounded-md bg-input text-foreground" />
          </div>
          <div>
            <label class="block text-sm font-medium text-muted-foreground">New Password</label>
            <input v-model="newPassword" type="password" placeholder="New Password" class="mt-1 w-full p-2 rounded-md bg-input text-foreground" />
          </div>
          <div>
            <label class="block text-sm font-medium text-muted-foreground">Confirm Password</label>
            <input v-model="confirmPassword" type="password" placeholder="Confirm Password" class="mt-1 w-full p-2 rounded-md bg-input text-foreground" />
          </div>
        </CardContent>
        <CardFooter class="mt-6 flex justify-center">
          <Button type="submit" class="bg-indigo-600">Save Changes</Button>
        </CardFooter>
      </form>
    </Card>
  </div>
</template>