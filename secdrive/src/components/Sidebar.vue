<script setup lang="ts">
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
import { LogOut, Settings, Folder, Shield } from 'lucide-vue-next';

const user = {
  initials: 'JD',
  email: 'john.doe@example.com',
  avatarUrl: 'https://github.com/radix-vue.png',
};

function handleLogout() {
  console.log('Logging out...');
}
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
         <Button variant="ghost" class="w-full justify-start text-muted-foreground hover:text-foreground">
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
        </div>
    </div>
  </aside>
</template>