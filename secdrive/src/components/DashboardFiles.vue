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
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog'
import { Label } from '@/components/ui/label'
import { Progress } from '@/components/ui/progress'
import { auth, api } from '@/config';
import { FileText, Folder, Upload, Download, X, File, Image, FileVideo, FileAudio } from 'lucide-vue-next';
import { ref, computed, onMounted } from 'vue';

interface FileItem {
  id: string;
  name: string;
  type: string;
  size: string;
  modified: string;
  url?: string;
  isFolder: boolean;
}

interface SelectedFile {
  file: File;
  id: string;
  preview?: string;
}

const files = ref<FileItem[]>([]);

function getFileIcon(file: FileItem) {
  if (file.isFolder) {
    return Folder;
  }
  return FileText;
}

const isUploadDialogOpen = ref(false);
const selectedFiles = ref<SelectedFile[]>([]);
const isUploading = ref(false);
const uploadProgress = ref(0);
const fileInputRef = ref<HTMLInputElement | null>(null);
const isDragOver = ref(false);

function getFileTypeIcon(fileName: string) {
  const extension = fileName.split('.').pop()?.toLowerCase();
  
  switch (extension) {
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'gif':
    case 'svg':
    case 'webp':
      return Image;
    case 'mp4':
    case 'avi':
    case 'mov':
    case 'wmv':
    case 'webm':
      return FileVideo;
    case 'mp3':
    case 'wav':
    case 'flac':
    case 'aac':
      return FileAudio;
    default:
      return File;
  }
}

function formatFileSize(bytes: number): string {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

async function uploadFile() {
  isUploadDialogOpen.value = true;
}

function openFileDialog() {
  fileInputRef.value?.click();
}

function handleFileSelect(event: Event) {
  const target = event.target as HTMLInputElement;
  const fileList = target.files;
  
  if (fileList) {
    addFilesToSelection(fileList);
  }
  
  // Reset the input
  if (target) {
    target.value = '';
  }
}

function removeFile(fileId: string) {
  selectedFiles.value = selectedFiles.value.filter(f => f.id !== fileId);
}

function handleDragOver(event: DragEvent) {
  event.preventDefault();
  isDragOver.value = true;
}

function handleDragLeave(event: DragEvent) {
  event.preventDefault();
  isDragOver.value = false;
}

function handleDrop(event: DragEvent) {
  event.preventDefault();
  isDragOver.value = false;
  
  const files = event.dataTransfer?.files;
  if (files) {
    addFilesToSelection(files);
  }
}

function addFilesToSelection(fileList: FileList) {
  for (let i = 0; i < fileList.length; i++) {
    const file = fileList[i];
    const selectedFile: SelectedFile = {
      file,
      id: Date.now() + '-' + i + '-' + file.name,
    };

    // Create preview for images
    if (file.type.startsWith('image/')) {
      const reader = new FileReader();
      reader.onload = (e) => {
        selectedFile.preview = e.target?.result as string;
      };
      reader.readAsDataURL(file);
    }

    selectedFiles.value.push(selectedFile);
  }
}

async function uploadSelectedFiles() {
  if (selectedFiles.value.length === 0) return;
  
  isUploading.value = true;
  uploadProgress.value = 0;
  
  try {
    const totalFiles = selectedFiles.value.length;
    const user = auth.currentUser;
    
    if (!user) {
      throw new Error('User not authenticated');
    }
    
    for (let i = 0; i < selectedFiles.value.length; i++) {
      const selectedFile = selectedFiles.value[i];
      await uploadFileWithPresignedUrl(selectedFile.file, user.uid);
      uploadProgress.value = ((i + 1) / totalFiles) * 100;
    }
    
    // Clear selected files and close dialog
    selectedFiles.value = [];
    isUploadDialogOpen.value = false;
    
    console.log('All files uploaded successfully');
    
    // Refresh file list after upload
    await loadUserFiles();
    
  } catch (error) {
    console.error('Upload failed:', error);
    const errorMessage = error instanceof Error ? error.message : 'An unknown error occurred';
    alert(`Upload failed: ${errorMessage}`);
  } finally {
    isUploading.value = false;
    uploadProgress.value = 0;
  }
}

async function uploadFileWithPresignedUrl(file: File, userId: string): Promise<void> {
  try {
    // Step 1: Request pre-signed URL from backend
    const response = await api.post('/generatePresignedUrl', {
      user_id: userId,
      file_name: file.name,
      file_size: file.size,
      content_type: file.type
    });

    const { presigned_url, file_id, s3_key } = response.data;

    // Step 2: Upload file directly to S3 using pre-signed URL
    await fetch(presigned_url, {
      method: 'PUT',
      body: file,
      headers: {
        'Content-Type': file.type
      }
    });

    // Step 3: Confirm upload and store metadata
    await api.post('/confirmUpload', {
      file_id,
      user_id: userId,
      file_name: file.name,
      file_size: file.size,
      s3_key,
      content_type: file.type
    });

    console.log(`File ${file.name} uploaded successfully`);
  } catch (error) {
    console.error(`Failed to upload file ${file.name}:`, error);
    throw error;
  }
}

async function loadUserFiles(): Promise<void> {
  try {
    const user = auth.currentUser;
    if (!user) return;

    const response = await api.get(`/getUserData?user_id=${user.uid}`);
    files.value = response.data.files || [];
  } catch (error) {
    console.error('Failed to load user files:', error);
  }
}

const totalSelectedSize = computed(() => {
  return selectedFiles.value.reduce((total, selected) => total + selected.file.size, 0);
});

function handleDownload(event: Event, file: FileItem) {
  if (!file || !file.url || file.isFolder) return;

  event.preventDefault();

  console.log(`Initiating download for: ${file.name} from ${file.url}`);
  
  // Create a temporary anchor element to trigger download
  const link = document.createElement('a');
  link.href = file.url;
  link.download = file.name;
  link.target = '_blank';
  
  // Append to body, click, and remove
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
}

function handleRowClick(file: FileItem) {
  if (file.isFolder) {
    console.log(`Navigating into folder: ${file.name}`);
  }
}

// Load files when component is mounted
onMounted(() => {
  loadUserFiles();
});

</script>

<template>
  <div class="max-w-7xl mx-auto">
    <div class="flex justify-between items-center mb-6 mt-6">
      <h1 class="text-3xl font-semibold text-white">Your Files</h1>
      
      <Dialog v-model:open="isUploadDialogOpen">
        <DialogTrigger as-child>
          <Button @click="uploadFile" class="bg-indigo-600 hover:bg-indigo-700 text-white cursor-pointer">
            <Upload class="mr-2 h-4 w-4" /> Upload File
          </Button>
        </DialogTrigger>
        
        <DialogContent class="sm:max-w-2xl max-h-[80vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>Upload Files</DialogTitle>
            <DialogDescription>
              Select files to upload to your secure drive. Multiple files can be selected at once.
            </DialogDescription>
          </DialogHeader>
          
          <div class="space-y-4">
            <!-- File Input (Hidden) -->
            <input
              ref="fileInputRef"
              type="file"
              multiple
              class="hidden"
              @change="handleFileSelect"
              accept="*/*"
            />
            
            <!-- Upload Area -->
            <div 
              class="border-2 border-dashed rounded-lg p-8 text-center transition-colors cursor-pointer"
              :class="[
                isDragOver 
                  ? 'border-indigo-500 bg-indigo-50 dark:bg-indigo-950/20' 
                  : 'border-muted-foreground/25 hover:border-muted-foreground/50'
              ]"
              @click="openFileDialog"
              @dragover="handleDragOver"
              @dragleave="handleDragLeave"
              @drop="handleDrop"
            >
              <Upload class="mx-auto h-12 w-12 text-muted-foreground mb-4" />
              <p class="text-lg font-medium mb-2">
                {{ isDragOver ? 'Drop files here' : 'Drop files here or click to browse' }}
              </p>
              <p class="text-sm text-muted-foreground mb-4">You can select multiple files at once</p>
              <Button type="button" @click.stop="openFileDialog" variant="outline">
                Choose Files
              </Button>
            </div>
            
            <!-- Selected Files Preview -->
            <div v-if="selectedFiles.length > 0" class="space-y-4">
              <div class="flex items-center justify-between">
                <Label class="text-base font-medium">Selected Files ({{ selectedFiles.length }})</Label>
                <span class="text-sm text-muted-foreground">Total size: {{ formatFileSize(totalSelectedSize) }}</span>
              </div>
              
              <div class="max-h-60 overflow-y-auto space-y-2 border rounded-md p-3">
                <div
                  v-for="selectedFile in selectedFiles"
                  :key="selectedFile.id"
                  class="flex items-center gap-3 p-2 rounded-md bg-muted/30 hover:bg-muted/50 transition-colors"
                >
                  <!-- File Icon/Preview -->
                  <div class="flex-shrink-0">
                    <img
                      v-if="selectedFile.preview"
                      :src="selectedFile.preview"
                      :alt="selectedFile.file.name"
                      class="h-10 w-10 object-cover rounded"
                    />
                    <component
                      v-else
                      :is="getFileTypeIcon(selectedFile.file.name)"
                      class="h-10 w-10 text-muted-foreground"
                    />
                  </div>
                  
                  <!-- File Info -->
                  <div class="flex-1 min-w-0">
                    <p class="text-sm font-medium truncate" :title="selectedFile.file.name">
                      {{ selectedFile.file.name }}
                    </p>
                    <p class="text-xs text-muted-foreground">
                      {{ formatFileSize(selectedFile.file.size) }}
                    </p>
                  </div>
                  
                  <!-- Remove Button -->
                  <Button
                    type="button"
                    variant="ghost"
                    size="icon"
                    class="h-8 w-8 text-muted-foreground hover:text-destructive"
                    @click="removeFile(selectedFile.id)"
                    :disabled="isUploading"
                  >
                    <X class="h-4 w-4" />
                  </Button>
                </div>
              </div>
            </div>
            
            <!-- Upload Progress -->
            <div v-if="isUploading" class="space-y-2">
              <div class="flex items-center justify-between">
                <Label class="text-sm">Uploading files...</Label>
                <span class="text-sm text-muted-foreground">{{ Math.round(uploadProgress) }}%</span>
              </div>
              <Progress :value="uploadProgress" class="w-full" />
            </div>
          </div>
          
          <DialogFooter class="gap-2">
            <Button
              type="button"
              variant="outline"
              @click="isUploadDialogOpen = false"
              :disabled="isUploading"
            >
              Cancel
            </Button>
            <Button
              type="button"
              @click="uploadSelectedFiles"
              :disabled="selectedFiles.length === 0 || isUploading"
              class="bg-indigo-600 hover:bg-indigo-700"
            >
              <Upload class="mr-2 h-4 w-4" />
              {{ isUploading ? 'Uploading...' : `Upload ${selectedFiles.length} file${selectedFiles.length !== 1 ? 's' : ''}` }}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
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