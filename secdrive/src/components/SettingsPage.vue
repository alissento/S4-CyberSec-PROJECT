<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { Button } from '@/components/ui/button'
import { Card, CardHeader, CardTitle, CardContent, CardFooter } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { auth } from '@/config'
import { onAuthStateChanged, updateEmail, updatePassword, type User } from 'firebase/auth'
import { useUserStore } from '@/stores/userStore'
import { toast } from 'vue-sonner'

const firstName = ref('')
const lastName = ref('')
const email = ref('')
const newPassword = ref('')
const confirmPassword = ref('')
const isLoading = ref(false)
const isAuthReady = ref(false)
const currentUser = ref<User | null>(null)

const userStore = useUserStore()

interface UserData {
  first_name?: string;
  last_name?: string;
  email?: string;
}

async function loadUserData() {
  if (!isAuthReady.value || !currentUser.value) {
    console.log('Authentication not ready yet');
    return;
  }

  try {
    await userStore.fetchUserData(currentUser.value.uid);
    const data = userStore.getUserData as unknown as UserData;
    
    if (data) {
      firstName.value = data.first_name || '';
      lastName.value = data.last_name || '';
      email.value = data.email || '';
    }
  } catch (error) {
    console.error('Failed to load user data:', error);
    toast.error('Failed to load user data');
  }
}

async function saveSettings() {
  if (!currentUser.value) {
    toast.error('User not authenticated');
    return;
  }

  if (newPassword.value && newPassword.value !== confirmPassword.value) {
    toast.error('Passwords do not match');
    return;
  }

  isLoading.value = true;

  try {
    // Update profile data
    const profileData: any = {};
    if (firstName.value) profileData.first_name = firstName.value;
    if (lastName.value) profileData.last_name = lastName.value;
    if (email.value) profileData.email = email.value;

    if (Object.keys(profileData).length > 0) {
      await userStore.updateUserData(currentUser.value.uid, profileData);
    }

    // Update email in Firebase Auth if changed
    if (email.value && email.value !== currentUser.value.email) {
      await updateEmail(currentUser.value, email.value);
    }

    // Update password in Firebase Auth if provided
    if (newPassword.value) {
      await updatePassword(currentUser.value, newPassword.value);
      newPassword.value = '';
      confirmPassword.value = '';
    }

    toast.success('Settings updated successfully');
  } catch (error: any) {
    console.error('Failed to update settings:', error);
    
    if (error.code === 'auth/too-many-requests') {
      toast.error('Too many update attempts. Please try again later.', {
        style: { backgroundColor: 'red' },
        duration: 6000
      });
    } else if (error.code === 'auth/requires-recent-login') {
      toast.error('Please log out and log back in before updating sensitive information.', {
        style: { backgroundColor: 'red' },
        duration: 6000
      });
    } else if (error.code === 'auth/invalid-email') {
      toast.error('Invalid email address format.', {
        style: { backgroundColor: 'red' }
      });
    } else if (error.code === 'auth/email-already-in-use') {
      toast.error('This email address is already in use by another account.', {
        style: { backgroundColor: 'red' },
        duration: 5000
      });
    } else if (error.code === 'auth/weak-password') {
      toast.error('Password is too weak. Please choose a stronger password.', {
        style: { backgroundColor: 'red' },
        duration: 5000
      });
    } else {
      const errorMessage = error.message || 'Failed to update settings';
      toast.error(errorMessage);
    }
  } finally {
    isLoading.value = false;
  }
}

onMounted(() => {
  onAuthStateChanged(auth, (user) => {
    isAuthReady.value = true;
    currentUser.value = user;
    
    if (user) {
      console.log('User authenticated, loading user data');
      loadUserData();
    } else {
      console.log('User not authenticated');
    }
  });
});
</script>

<template>
  <div class="max-w-7xl mx-auto">
    <div class="flex justify-between items-center mb-6 mt-6">
      <h1 class="text-3xl font-semibold text-white">Settings</h1>
    </div>
    
    <Card class="max-w-2xl">
      <CardHeader>
        <CardTitle>Profile Settings</CardTitle>
      </CardHeader>
      
      <form @submit.prevent="saveSettings">
        <CardContent class="space-y-6">
          <div class="grid grid-cols-2 gap-4">
            <div class="space-y-2">
              <Label for="firstName">First Name</Label>
              <Input 
                id="firstName"
                v-model="firstName" 
                type="text" 
                placeholder="Enter your first name"
                :disabled="isLoading"
              />
            </div>
            <div class="space-y-2">
              <Label for="lastName">Last Name</Label>
              <Input 
                id="lastName"
                v-model="lastName" 
                type="text" 
                placeholder="Enter your last name"
                :disabled="isLoading"
              />
            </div>
          </div>
          
          <div class="space-y-2">
            <Label for="email">Email Address</Label>
            <Input 
              id="email"
              v-model="email" 
              type="email" 
              placeholder="Enter your email address"
              :disabled="isLoading"
            />
          </div>
          
          <div class="border-t pt-6">
            <h3 class="text-lg font-medium mb-4">Change Password</h3>
            <div class="space-y-4">
              <div class="space-y-2">
                <Label for="newPassword">New Password</Label>
                <Input 
                  id="newPassword"
                  v-model="newPassword" 
                  type="password" 
                  placeholder="Enter new password (leave blank to keep current)"
                  :disabled="isLoading"
                />
              </div>
              <div class="space-y-2">
                <Label for="confirmPassword">Confirm Password</Label>
                <Input 
                  id="confirmPassword"
                  v-model="confirmPassword" 
                  type="password" 
                  placeholder="Confirm new password"
                  :disabled="isLoading"
                />
              </div>
            </div>
          </div>
        </CardContent>
        
        <CardFooter class="flex justify-end">
          <Button 
            type="submit" 
            :disabled="isLoading"
            class="bg-indigo-600 text-white hover:bg-indigo-700"
          >
            {{ isLoading ? 'Saving...' : 'Save Changes' }}
          </Button>
        </CardFooter>
      </form>
    </Card>
  </div>
</template>