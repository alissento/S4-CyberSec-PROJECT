<script setup lang="ts">
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { Button } from '@/components/ui/button'
import { FileText, Folder, Upload, Download } from 'lucide-vue-next';
import { ref } from 'vue';

const files = ref([
  { id: 1, name: 'Project Proposal.docx', type: 'doc', size: '2.5 MB', modified: '2024-03-15 10:30 AM', isFolder: false, url: '/download/1' }, // Added dummy URL
  { id: 2, name: 'Client Assets', type: 'folder', size: '1.2 GB', modified: '2024-03-14 09:00 AM', isFolder: true, url: null },
  { id: 3, name: 'presentation_final_v3.pptx', type: 'ppt', size: '15.8 MB', modified: '2024-03-15 08:15 AM', isFolder: false, url: '/download/3' },
  { id: 4, name: 'Website Mockups', type: 'folder', size: '350 MB', modified: '2024-03-12 14:20 PM', isFolder: true, url: null },
  { id: 5, name: 'budget_report.xlsx', type: 'xls', size: '512 KB', modified: '2024-03-10 11:05 AM', isFolder: false, url: '/download/5' },
  { id: 6, name: 'logo.svg', type: 'img', size: '8 KB', modified: '2024-02-28 16:45 PM', isFolder: false, url: '/download/6' },
]);

function getFileIcon(file: { isFolder: any; }) {
  if (file.isFolder) {
    return Folder;
  }
  return FileText;
}

function handleUploadClick() {
    console.log("Upload button clicked");
}

function handleDownload(event: { preventDefault: () => void; }, file: { url: any; isFolder: any; name: any; }) {
  if (!file || !file.url || file.isFolder) return;


  event.preventDefault();

  console.log(`Initiating download for: ${file.name} from ${file.url}`);
}

function handleRowClick(file: { isFolder: any; name: any; }) {
    if (file.isFolder) {
        console.log(`Navigating into folder: ${file.name}`);
    }
}

</script>

<template>
  <div class="max-w-7xl mx-auto">
    <div class="flex justify-between items-center mb-6 mt-6">
      <h1 class="text-3xl font-semibold text-white">Your Files</h1>
      <Button @click="handleUploadClick" class="bg-indigo-600 hover:bg-indigo-700">
        <Upload class="mr-2 h-4 w-4" /> Upload File
      </Button>
    </div>
    <div class="bg-card rounded-lg shadow overflow-x-auto p-4">
      <Table>
        <TableHeader>
          <TableRow>
             <TableHead class="w-[50px]"><input type="checkbox" class="h-4 w-4 text-indigo-500" /></TableHead>
             <TableHead class="min-w-[250px] w-[40%] lg:w-[50%] text-gray-400">Name</TableHead>
             <TableHead class="min-w-[80px] text-gray-400">Type</TableHead>
             <TableHead class="min-w-[100px] text-gray-400">Size</TableHead>
             <TableHead class="min-w-[150px] text-right text-gray-400">Last Modified</TableHead>
             <TableHead class="w-[100px] text-center text-gray-400">Actions</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          <TableRow
             v-for="file in files"
             :key="file.id"
             class="hover:bg-muted/50"
             :class="{'cursor-pointer': file.isFolder}"
             @click="handleRowClick(file)"
          >
             <TableCell>
                <input type="checkbox" :id="`select-${file.id}`" class="h-4 w-4 text-indigo-500" />
             </TableCell>

            <TableCell class="font-medium">
              <div class="flex items-center space-x-2">
                 <component :is="getFileIcon(file)" class="h-4 w-4 text-muted-foreground flex-shrink-0" />
                 <span
                    v-if="file.isFolder"
                    class="truncate"
                    :title="file.name"
                 >
                    {{ file.name }}
                 </span>
                 <a
                    v-else
                    href="#"
                    @click.stop="handleDownload($event, file)"
                    class="hover:underline truncate cursor-pointer"
                    :title="`Download ${file.name}`"
                 >
                     {{ file.name }}
                 </a>
              </div>
            </TableCell>

            <TableCell class="capitalize text-muted-foreground">{{ file.isFolder ? 'Folder' : file.type }}</TableCell>
            <TableCell class="text-muted-foreground">{{ file.size }}</TableCell>
            <TableCell class="text-right text-muted-foreground whitespace-nowrap">{{ file.modified }}</TableCell>

             <TableCell class="text-center">
                <Button
                   v-if="!file.isFolder"
                   variant="ghost"
                   size="icon"
                   @click.stop="handleDownload($event, file)"
                   title="Download"
                   class="h-8 w-8"
                >
                   <Download class="h-4 w-4" />
                </Button>
                 <Button v-else variant="ghost" size="icon" class="h-8 w-8 invisible"> Placeholder </Button>
             </TableCell>
          </TableRow>

          <TableRow v-if="files.length === 0">
             <TableCell colspan="6" class="text-center text-muted-foreground py-8 h-48">
                No files found. Upload your first file!
             </TableCell>
          </TableRow>
        </TableBody>
      </Table>
    </div>
  </div>
</template>