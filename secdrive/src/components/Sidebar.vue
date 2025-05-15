<script setup lang="ts">
  import { Button } from '@/components/ui/button'
  import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuLabel,
    DropdownMenuSeparator,
    DropdownMenuTrigger,
  } from '@/components/ui/dropdown-menu'

  import { Separator } from '@/components/ui/separator'
  import { LogOut, Settings, Folder, Shield, UserRound } from 'lucide-vue-next';
  import router from '@/router/index'
  import { auth } from '@/config'
  import { ref, onMounted } from 'vue'
  import { signOut } from 'firebase/auth'
  import { useUserStore } from '@/stores/userStore'
  import { toast } from 'vue-sonner'

  const firstName = ref('');
  const lastName = ref('');
  const email = ref('');

  const userStore = useUserStore();

  interface UserData {
    first_name?: string;
    last_name?: string;
    email?: string;
  }

  async function logout() {
    try {
      await signOut(auth);
      console.log('User logged out');
      await userStore.clearUserData();
      toast.success('Successfully logged out', { style: { backgroundColor: 'green' } });
      router.push('/login');
    } catch (error) {
      console.error('Error logging out:', error);
      toast.error('An error occurred while logging out', { style: { backgroundColor: 'red' } });
    }
  }

  async function populateUserData() {
    const user = auth.currentUser;
    if (!user) {
      console.error('No user is currently logged in');
      return;
    }
    await userStore.fetchUserData(user.uid);
    const data = userStore.getUserData as unknown as UserData;
    console.log('User data:', data);
    if (data) {
      if (data.first_name) firstName.value = data.first_name;
      if (data.last_name) lastName.value = data.last_name;
      if (data.email) email.value = data.email;
    }

    console.log('First Name:', firstName.value);
    console.log('Last Name:', lastName.value);
    console.log('Email:', email.value);
  }

  onMounted(() => {
    populateUserData();
  });
</script>

<template>
  <aside class="fixed inset-y-0 left-0 z-10 flex h-full w-54 flex-col border-r bg-background">
    <div class="flex h-14 items-center border-b px-6">
      <a href="/" class="flex items-center gap-2 font-semibold">
        <Shield class="h-6 w-6" />
        <span>SecDrive</span>
      </a>
    </div>

    <nav class="flex-1 space-y-1 p-4">
       <router-link to="/dashboard/files" class="block">
         <Button variant="ghost" class="w-full justify-start">
           <Folder class="mr-2 h-4 w-4" />
           My Files
         </Button>
       </router-link>
       <router-link to="/dashboard/settings" class="block">
         <Button variant="ghost" class="w-full justify-start">
           <Settings class="mr-2 h-4 w-4" />
           Settings
         </Button>
       </router-link>
    </nav>

    <div class="mt-auto p-4">
       <Separator class="my-4" />
       <div class="flex items-center justify-center">
        <DropdownMenu>
                <DropdownMenuTrigger as-child>
                    <Button variant="outline" size="icon" class="overflow-hidden rounded-full">
                        <UserRound class="h-8 w-8" />
                    </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end" class="w-56">
                     <DropdownMenuLabel class="font-normal">
                        <div class="flex flex-col space-y-1">
                            <p class="text-sm font-medium leading-none">{{ firstName }} {{ lastName }}</p>
                            <p class="text-xs leading-none text-muted-foreground">{{ email }}</p>
                        </div>
                    </DropdownMenuLabel>
                    <DropdownMenuSeparator />
                    <DropdownMenuItem @click="logout">
                        <LogOut class="mr-2 h-4 w-4" />
                        <span>Log out</span>
                    </DropdownMenuItem>
                </DropdownMenuContent>
            </DropdownMenu>
        </div>
    </div>
  </aside>
</template>