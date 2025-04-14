<script setup lang="ts">
import { ref } from 'vue';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
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
import { LogOut, Settings, LayoutGrid, Moon, Sun, Folder, Users, Trash } from 'lucide-vue-next';

const isDarkMode = ref(false);
function toggleDarkMode() {
  isDarkMode.value = !isDarkMode.value;
  console.log('Toggling dark mode, new state:', isDarkMode.value);
  if (isDarkMode.value) {
      document.documentElement.classList.add('dark');
      localStorage.setItem('theme', 'dark');
  } else {
      document.documentElement.classList.remove('dark');
      localStorage.setItem('theme', 'light');
  }
}
const initializeTheme = () => {
    const savedTheme = localStorage.getItem('theme');
    const systemPrefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    if (savedTheme === 'dark' || (!savedTheme && systemPrefersDark)) {
        isDarkMode.value = true;
        document.documentElement.classList.add('dark');
    } else {
        isDarkMode.value = false;
        document.documentElement.classList.remove('dark');
    }
};
initializeTheme();

const user = {
  initials: 'JD',
  email: 'john.doe@example.com',
  avatarUrl: 'https://github.com/radix-vue.png',
};

function handleLogout() {
  console.log('Logging out...');
}
function goToSettings() {
  console.log('Navigating to settings...');
}
function navigateTo(path: string) {
    console.log(`Navigating to ${path}...`);
}

</script>

<template>
  <aside class="fixed inset-y-0 left-0 z-10 flex h-full w-54 flex-col border-r bg-background">
    <div class="flex h-14 items-center border-b px-6">
      <a href="/" class="flex items-center gap-2 font-semibold">
        <LayoutGrid class="h-6 w-6" />
        <span>SecDrive</span>
      </a>
    </div>

    <nav class="flex-1 space-y-1 p-4">
       <Button @click="navigateTo('/files')" variant="ghost" class="w-full justify-start">
          <Folder class="mr-2 h-4 w-4" />
          My Files
       </Button>
       <Button @click="navigateTo('/shared')" variant="ghost" class="w-full justify-start text-muted-foreground hover:text-foreground">
          <Users class="mr-2 h-4 w-4" />
          Shared with me
       </Button>
       <Button @click="navigateTo('/trash')" variant="ghost" class="w-full justify-start text-muted-foreground hover:text-foreground">
          <Trash class="mr-2 h-4 w-4" />
          Trash
       </Button>
    </nav>

    <div class="mt-auto p-4">
       <Separator class="my-4" />
       <div class="flex items-center justify-between space-x-2">
        <DropdownMenu>
                <DropdownMenuTrigger as-child>
                    <Button variant="outline" size="icon" class="overflow-hidden rounded-full">
                        <Avatar class="h-8 w-8">
                            <AvatarImage :src="user.avatarUrl" :alt="`@${user.initials}`" />
                            <AvatarFallback>{{ user.initials }}</AvatarFallback>
                        </Avatar>
                    </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end" class="w-56">
                     <DropdownMenuLabel class="font-normal">
                        <div class="flex flex-col space-y-1">
                            <p class="text-sm font-medium leading-none">{{ user.initials }}</p>
                            <p class="text-xs leading-none text-muted-foreground">
                            {{ user.email }}
                            </p>
                        </div>
                    </DropdownMenuLabel>
                    <DropdownMenuSeparator />
                    <DropdownMenuItem @click="handleLogout">
                        <LogOut class="mr-2 h-4 w-4" />
                        <span>Log out</span>
                    </DropdownMenuItem>
                </DropdownMenuContent>
            </DropdownMenu>

            <Button @click="goToSettings" variant="outline" size="icon" aria-label="Settings">
                <Settings class="h-[1.2rem] w-[1.2rem]" />
            </Button>

            <Button @click="toggleDarkMode" variant="outline" size="icon" aria-label="Toggle theme">
                <Sun v-if="!isDarkMode" class="h-[1.2rem] w-[1.2rem] transition-all dark:scale-0" />
                <Moon v-else class="h-[1.2rem] w-[1.2rem] scale-0 transition-all dark:scale-100" />
            </Button>
        </div>
    </div>
  </aside>
</template>