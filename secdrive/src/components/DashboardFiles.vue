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
import { Skeleton } from '@/components/ui/skeleton'
import { auth, api } from '@/config';
import { FileText, Folder, Upload, Download, X, File, Image, FileVideo, FileAudio, Trash2 } from 'lucide-vue-next';
import { ref, computed, onMounted } from 'vue';
import { onAuthStateChanged, type User } from 'firebase/auth';
import { useRouter } from 'vue-router';
import { toast } from 'vue-sonner';
import { encryptFile, createEncryptedBlob, downloadAndDecryptFile } from '@/utils/encryption';
import { getCryptoKey, getCryptoKeyForDecryption } from '@/utils/encryptionService';

interface FileItem {
  id: string;
  name: string;
  type: string;
  size: string;
  modified: string;
  url?: string;
  isFolder: boolean;
  isEncrypted?: boolean;
  encryptedKey?: string;
}

interface SelectedFile {
  file: File;
  id: string;
  preview?: string;
}

const files = ref<FileItem[]>([]);
const isAuthReady = ref(false);
const currentUser = ref<User | null>(null);
const isLoadingFiles = ref(false);
const selectedFileIds = ref<Set<string>>(new Set());
const isSelectAll = ref(false);

const router = useRouter();

function getFileIcon(file: FileItem) {
  if (file.isFolder) {
    return Folder;
  }
  
  // Use the same logic as getFileTypeIcon for consistency
  const extension = file.name.split('.').pop()?.toLowerCase();
  
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
    case 'pdf':
      return FileText;
    case 'doc':
    case 'docx':
    case 'txt':
    case 'rtf':
      return FileText;
    case 'xls':
    case 'xlsx':
    case 'csv':
      return FileText;
    case 'ppt':
    case 'pptx':
      return FileText;
    case 'zip':
    case 'rar':
    case '7z':
    case 'tar':
    case 'gz':
      return File;
    default:
      return File;
  }
}

const isUploadDialogOpen = ref(false);
const selectedFiles = ref<SelectedFile[]>([]);
const isUploading = ref(false);
const uploadProgress = ref(0);
const currentUploadFile = ref<string>('');
const currentUploadStep = ref<string>('');
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
  currentUploadFile.value = '';
  currentUploadStep.value = '';
  
  try {
    const totalFiles = selectedFiles.value.length;
    const user = currentUser.value;
    
    if (!user) {
      throw new Error('User not authenticated');
    }
    
    // Calculate steps per file: encrypt (25%) + get presigned URL (25%) + upload (40%) + confirm (10%)
    const stepsPerFile = 4;
    const totalSteps = totalFiles * stepsPerFile;
    let currentStep = 0;
    
    const updateProgress = () => {
      uploadProgress.value = (currentStep / totalSteps) * 100;
    };
    
    for (let i = 0; i < selectedFiles.value.length; i++) {
      const selectedFile = selectedFiles.value[i];
      currentUploadFile.value = selectedFile.file.name;
      await uploadFileWithPresignedUrl(selectedFile.file, user.uid, updateProgress, () => currentStep++);
    }
    
    // Clear selected files and close dialog
    selectedFiles.value = [];
    isUploadDialogOpen.value = false;
    currentUploadFile.value = '';
    currentUploadStep.value = '';
    
    console.log('All files uploaded successfully');
    toast.success(`Successfully uploaded ${totalFiles} file${totalFiles > 1 ? 's' : ''}`);
    
    // Refresh file list after upload
    await loadUserFiles();
    
  } catch (error) {
    console.error('Upload failed:', error);
    const errorMessage = error instanceof Error ? error.message : 'An unknown error occurred';
    toast.error(`Upload failed: ${errorMessage}`);
  } finally {
    isUploading.value = false;
    uploadProgress.value = 0;
    currentUploadFile.value = '';
    currentUploadStep.value = '';
  }
}

async function uploadFileWithPresignedUrl(file: File, userId: string, updateProgress: () => void, incrementStep: () => void): Promise<void> {
  try {
    // Step 1: Get encryption key for this user (25% of file progress)
    currentUploadStep.value = 'Getting encryption key...';
    const { cryptoKey, encryptedKey } = await getCryptoKey(userId);
    incrementStep();
    updateProgress();
    await new Promise(resolve => setTimeout(resolve, 100)); // Small delay to see progress
    
    // Step 2: Encrypt the file (25% of file progress)
    currentUploadStep.value = 'Encrypting file...';
    toast.info(`Encrypting ${file.name}...`);
    const encryptionResult = await encryptFile(file, cryptoKey);
    const encryptedBlob = createEncryptedBlob(encryptionResult.encryptedData, encryptionResult.iv);
    incrementStep();
    updateProgress();
    await new Promise(resolve => setTimeout(resolve, 100)); // Small delay to see progress
    
    // Step 3: Request pre-signed URL from backend (25% of file progress)
    currentUploadStep.value = 'Requesting upload URL...';
    const response = await api.post('/generatePresignedUrl', {
      user_id: userId,
      file_name: file.name,
      file_size: encryptedBlob.size, // Use encrypted file size
      content_type: 'application/octet-stream' // Encrypted files are binary
    });

    const { presigned_url, file_id, s3_key } = response.data;
    incrementStep();
    updateProgress();
    await new Promise(resolve => setTimeout(resolve, 100)); // Small delay to see progress

    // Step 4: Upload encrypted file directly to S3 using pre-signed URL (25% of file progress)
    currentUploadStep.value = 'Uploading to cloud...';
    toast.info(`Uploading encrypted ${file.name}...`);
    await fetch(presigned_url, {
      method: 'PUT',
      body: encryptedBlob,
      headers: {
        'Content-Type': 'application/octet-stream'
      }
    });

    // Step 5: Confirm upload and store metadata with encryption info
    currentUploadStep.value = 'Finalizing upload...';
    await api.post('/confirmUpload', {
      file_id,
      user_id: userId,
      file_name: file.name,
      file_size: file.size, // Store original file size for display
      s3_key,
      content_type: file.type, // Store original content type
      encrypted_key: encryptedKey // Store encrypted data key
    });
    
    incrementStep();
    updateProgress();
    await new Promise(resolve => setTimeout(resolve, 100)); // Small delay to see progress

    console.log(`File ${file.name} uploaded and encrypted successfully`);
  } catch (error) {
    console.error(`Failed to upload file ${file.name}:`, error);
    throw error;
  }
}

async function loadUserFiles(): Promise<void> {
  try {
    if (!isAuthReady.value) {
      console.log('Authentication not ready yet, skipping file load');
      return;
    }

    const user = auth.currentUser;
    if (!user) {
      console.log('No authenticated user found');
      return;
    }

    isLoadingFiles.value = true;
    console.log('Loading files for user:', user.uid);
    const response = await api.get(`/getUserData?user_id=${user.uid}`);
    files.value = response.data.files || [];
    
    // Debug: Log file encryption status
    console.log('Loaded files with encryption status:', files.value.map(f => ({
      name: f.name,
      isEncrypted: f.isEncrypted,
      hasEncryptedKey: !!f.encryptedKey
    })));
    
    // Clear selections when files are reloaded
    clearSelection();
    
  } catch (error) {
    console.error('Failed to load user files:', error);
    toast.error('Failed to load files. Please try again.');
  } finally {
    isLoadingFiles.value = false;
  }
}

const totalSelectedSize = computed(() => {
  return selectedFiles.value.reduce((total, selected) => total + selected.file.size, 0);
});

async function handleDownload(event: Event, file: FileItem) {
  if (!file || !file.url || file.isFolder) return;

  event.preventDefault();

  try {
    console.log('Download request for file:', {
      name: file.name,
      isEncrypted: file.isEncrypted,
      hasEncryptedKey: !!file.encryptedKey,
      url: file.url
    });

    if (file.isEncrypted && file.encryptedKey) {
      // Handle encrypted file download
      console.log(`Downloading and decrypting encrypted file: ${file.name}`);
      
      const user = currentUser.value;
      if (!user) {
        throw new Error('User not authenticated');
      }
      
      toast.info(`Downloading and decrypting ${file.name}...`);
      
      // Get decryption key
      const decryptionKey = await getCryptoKeyForDecryption(user.uid, file.encryptedKey);
      console.log('Decryption key obtained successfully');
      
      // Download and decrypt the file
      await downloadAndDecryptFile(file.url, file.name, decryptionKey);
      
      toast.success(`Successfully downloaded and decrypted ${file.name}`);
    } else {
      // Handle unencrypted file download (legacy files)
      console.log(`Downloading unencrypted file: ${file.name} from ${file.url}`);
      
      const link = document.createElement('a');
      link.href = file.url;
      link.download = file.name;
      link.target = '_blank';
      
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
    }
  } catch (error) {
    console.error('Download failed:', error);
    const errorMessage = error instanceof Error ? error.message : 'An unknown error occurred';
    toast.error(`Download failed: ${errorMessage}`);
  }
}

function handleRowClick(file: FileItem) {
  if (file.isFolder) {
    console.log(`Navigating into folder: ${file.name}`);
  }
}

async function deleteFile(file: FileItem) {
  if (!file || file.isFolder) return;
  
  // Using toast instead of confirm for better UX
  toast.warning(`Delete "${file.name}"?`, {
    action: {
      label: 'Delete',
      onClick: async () => {
        try {
          const user = currentUser.value;
          if (!user) {
            throw new Error('User not authenticated');
          }
          
          // Call delete API
          await api.post('/deleteFile', {
            file_id: file.id,
            user_id: user.uid
          });
          
          console.log(`File ${file.name} deleted successfully`);
          toast.success(`File "${file.name}" deleted successfully`);
          
          // Remove from selection if it was selected
          selectedFileIds.value.delete(file.id);
          updateSelectAllState();
          
          // Refresh file list after deletion
          await loadUserFiles();
          
        } catch (error) {
          console.error('Delete failed:', error);
          const errorMessage = error instanceof Error ? error.message : 'An unknown error occurred';
          toast.error(`Delete failed: ${errorMessage}`);
        }
      }
    },
    cancel: {
      label: 'Cancel',
      onClick: () => {}
    }
  });
}

// Multi-select functions
function toggleFileSelection(fileId: string) {
  if (selectedFileIds.value.has(fileId)) {
    selectedFileIds.value.delete(fileId);
  } else {
    selectedFileIds.value.add(fileId);
  }
  updateSelectAllState();
}

function toggleSelectAll() {
  const nonFolderFiles = files.value.filter(f => !f.isFolder);
  
  if (isSelectAll.value) {
    // Deselect all
    selectedFileIds.value.clear();
    isSelectAll.value = false;
  } else {
    // Select all non-folder files
    selectedFileIds.value.clear();
    nonFolderFiles.forEach(file => selectedFileIds.value.add(file.id));
    isSelectAll.value = true;
  }
}

function updateSelectAllState() {
  const nonFolderFiles = files.value.filter(f => !f.isFolder);
  const selectedNonFolderFiles = nonFolderFiles.filter(f => selectedFileIds.value.has(f.id));
  
  isSelectAll.value = nonFolderFiles.length > 0 && selectedNonFolderFiles.length === nonFolderFiles.length;
}

function clearSelection() {
  selectedFileIds.value.clear();
  isSelectAll.value = false;
}

async function bulkDownload() {
  const selectedFiles = files.value.filter(file => 
    selectedFileIds.value.has(file.id) && !file.isFolder && file.url
  );
  
  if (selectedFiles.length === 0) {
    toast.warning('No downloadable files selected');
    return;
  }

  const user = currentUser.value;
  if (!user) {
    toast.error('User not authenticated');
    return;
  }

  toast.info(`Downloading ${selectedFiles.length} file${selectedFiles.length > 1 ? 's' : ''}...`);
  
  // Download each file sequentially with a small delay
  for (let i = 0; i < selectedFiles.length; i++) {
    const file = selectedFiles[i];
    console.log(`Downloading file ${i + 1}/${selectedFiles.length}: ${file.name}`);
    
    try {
      if (file.isEncrypted && file.encryptedKey) {
        // Handle encrypted file
        const decryptionKey = await getCryptoKeyForDecryption(user.uid, file.encryptedKey);
        await downloadAndDecryptFile(file.url!, file.name, decryptionKey);
      } else {
        // Handle unencrypted file (legacy)
        const link = document.createElement('a');
        link.href = file.url!;
        link.download = file.name;
        link.target = '_blank';
        
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
      }
    } catch (error) {
      console.error(`Failed to download ${file.name}:`, error);
      toast.error(`Failed to download ${file.name}`);
    }
    
    // Small delay between downloads to avoid overwhelming the browser
    if (i < selectedFiles.length - 1) {
      await new Promise(resolve => setTimeout(resolve, 200));
    }
  }
  
  toast.success(`Successfully downloaded ${selectedFiles.length} file${selectedFiles.length > 1 ? 's' : ''}`);
  clearSelection();
}

async function bulkDelete() {
  const selectedFiles = files.value.filter(file => 
    selectedFileIds.value.has(file.id) && !file.isFolder
  );
  
  if (selectedFiles.length === 0) {
    toast.warning('No files selected for deletion');
    return;
  }
  
  const fileNames = selectedFiles.slice(0, 3).map(f => f.name).join(', ');
  const displayNames = selectedFiles.length > 3 ? `${fileNames}... and ${selectedFiles.length - 3} more` : fileNames;
  
  toast.warning(`Delete ${selectedFiles.length} file${selectedFiles.length > 1 ? 's' : ''}?`, {
    description: `${displayNames}`,
    action: {
      label: 'Delete All',
      onClick: async () => {
        try {
          const user = currentUser.value;
          if (!user) {
            throw new Error('User not authenticated');
          }
          
          toast.info(`Deleting ${selectedFiles.length} file${selectedFiles.length > 1 ? 's' : ''}...`);
          
          // Delete files sequentially
          for (const file of selectedFiles) {
            await api.post('/deleteFile', {
              file_id: file.id,
              user_id: user.uid
            });
            console.log(`File ${file.name} deleted successfully`);
          }
          
          clearSelection();
          
          // Refresh file list after deletion
          await loadUserFiles();
          
          toast.success(`Successfully deleted ${selectedFiles.length} file${selectedFiles.length > 1 ? 's' : ''}`);
          
        } catch (error) {
          console.error('Bulk delete failed:', error);
          const errorMessage = error instanceof Error ? error.message : 'An unknown error occurred';
          toast.error(`Bulk delete failed: ${errorMessage}`);
        }
      }
    },
    cancel: {
      label: 'Cancel',
      onClick: () => {}
    }
  });
}

const selectedFilesCount = computed(() => selectedFileIds.value.size);

// Load files when component is mounted
onMounted(() => {
  // Wait for authentication state to be ready
  onAuthStateChanged(auth, (user) => {
    isAuthReady.value = true;
    currentUser.value = user;
    
    if (user) {
      console.log('User authenticated, loading files');
      loadUserFiles();
    } else {
      console.log('User not authenticated, redirecting to login');
      router.push('/login');
    }
  });
});

</script>

<template>
  <div class="max-w-7xl mx-auto">
    <div class="flex justify-between items-center mb-6 mt-6">
      <div class="flex items-center space-x-3">
        <h1 class="text-3xl font-semibold text-white">Your Files</h1>
        <div v-if="isLoadingFiles" class="flex items-center space-x-2">
          <div class="flex space-x-1">
            <div class="w-2 h-2 bg-indigo-500 rounded-full animate-bounce" style="animation-delay: 0ms"></div>
            <div class="w-2 h-2 bg-indigo-400 rounded-full animate-bounce" style="animation-delay: 150ms"></div>
            <div class="w-2 h-2 bg-indigo-300 rounded-full animate-bounce" style="animation-delay: 300ms"></div>
          </div>
          <span class="text-sm text-indigo-300 animate-pulse">Loading files...</span>
        </div>
        <div v-if="selectedFilesCount > 0" class="flex items-center space-x-2 bg-indigo-500/10 px-3 py-1.5 rounded-lg border border-indigo-500/20">
          <span class="text-sm font-medium text-indigo-300">{{ selectedFilesCount }} file{{ selectedFilesCount > 1 ? 's' : '' }} selected</span>
          <Button
            @click="bulkDownload"
            size="sm"
            variant="outline"
            class="text-indigo-400 border-indigo-400 hover:bg-indigo-400 hover:text-white"
          >
            <Download class="mr-1 h-3 w-3" />
            Download All
          </Button>
          <Button
            @click="bulkDelete"
            size="sm"
            variant="outline"
            class="text-red-400 border-red-400 hover:bg-red-400 hover:text-white"
          >
            <Trash2 class="mr-1 h-3 w-3" />
            Delete All
          </Button>
          <Button
            @click="clearSelection"
            size="sm"
            variant="ghost"
            class="text-gray-400 hover:text-white"
          >
            <X class="mr-1 h-3 w-3" />
            Clear
          </Button>
        </div>
      </div>
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
              <Button type="button" @click.stop="openFileDialog" variant="outline" class="cursor-pointer">
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
            <div v-if="isUploading" class="space-y-3">
              <div class="flex items-center justify-between">
                <Label class="text-sm">Uploading files...</Label>
                <span class="text-sm text-muted-foreground">{{ Math.round(uploadProgress) }}%</span>
              </div>
              
              <!-- Custom Progress Bar -->
              <div class="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-3 overflow-hidden">
                <div 
                  class="bg-gradient-to-r from-indigo-500 to-indigo-600 h-full rounded-full transition-all duration-300 ease-out"
                  :style="`width: ${uploadProgress}%`"
                >
                  <div class="h-full bg-white/20 rounded-full animate-pulse"></div>
                </div>
              </div>
              
              <!-- Current file and step details -->
              <div v-if="currentUploadFile" class="space-y-1">
                <div class="flex items-center justify-between text-xs text-muted-foreground">
                  <span class="truncate" :title="currentUploadFile">
                    Current: {{ currentUploadFile }}
                  </span>
                </div>
                <div v-if="currentUploadStep" class="text-xs text-indigo-400 font-medium">
                  {{ currentUploadStep }}
                </div>
              </div>
            </div>
          </div>
          
          <DialogFooter class="gap-2">
            <Button
              type="button"
              variant="outline"
              class="cursor-pointer"
              @click="isUploadDialogOpen = false"
              :disabled="isUploading"
            >
              Cancel
            </Button>
            <Button
              type="button"
              @click="uploadSelectedFiles"
              :disabled="selectedFiles.length === 0 || isUploading"
              class="bg-indigo-600 hover:bg-indigo-700 text-white cursor-pointer"
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
             <TableHead class="w-[50px]">
               <input 
                 type="checkbox" 
                 class="h-4 w-4 text-indigo-500 rounded border-gray-300 focus:ring-indigo-500 focus:ring-2"
                 :checked="isSelectAll"
                 @change="toggleSelectAll"
               />
             </TableHead>
             <TableHead class="min-w-[250px] w-[40%] lg:w-[50%] text-gray-400">Name</TableHead>
             <TableHead class="min-w-[80px] text-gray-400">Type</TableHead>
             <TableHead class="min-w-[100px] text-gray-400">Size</TableHead>
             <TableHead class="w-[120px] text-center text-gray-400">Actions</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          <!-- Loading Skeleton -->
          <template v-if="isLoadingFiles">
            <TableRow v-for="i in 5" :key="`skeleton-${i}`" class="hover:bg-muted/50">
              <TableCell>
                <Skeleton class="h-4 w-4 rounded" />
              </TableCell>
              <TableCell class="font-medium">
                <div class="flex items-center space-x-2">
                  <Skeleton class="h-4 w-4 rounded" />
                  <Skeleton class="h-4 w-32 rounded" />
                </div>
              </TableCell>
              <TableCell>
                <Skeleton class="h-4 w-16 rounded" />
              </TableCell>
              <TableCell>
                <Skeleton class="h-4 w-12 rounded" />
              </TableCell>
              <TableCell class="text-center">
                <div class="flex items-center justify-center gap-2">
                  <Skeleton class="h-8 w-8 rounded" />
                  <Skeleton class="h-8 w-8 rounded" />
                </div>
              </TableCell>
            </TableRow>
          </template>

          <!-- Actual File Rows -->
          <template v-else>
            <TableRow
               v-for="file in files"
               :key="file.id"
               class="hover:bg-muted/50 transition-all duration-200 ease-in-out"
               :class="{
                 'cursor-pointer': file.isFolder,
                 'bg-indigo-50/50 dark:bg-indigo-950/20 border-l-4 border-indigo-500 shadow-sm': selectedFileIds.has(file.id) && !file.isFolder
               }"
               @click="file.isFolder ? handleRowClick(file) : null"
            >
               <TableCell @click.stop>
                  <input 
                    v-if="!file.isFolder"
                    type="checkbox" 
                    :id="`select-${file.id}`" 
                    class="h-4 w-4 text-indigo-500 rounded border-gray-300 focus:ring-indigo-500 focus:ring-2"
                    :checked="selectedFileIds.has(file.id)"
                    @change="toggleFileSelection(file.id)"
                  />
                  <div v-else class="w-4 h-4"></div>
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

               <TableCell class="text-center">
                  <div class="flex items-center justify-center gap-1">
                    <Button
                       v-if="!file.isFolder"
                       variant="ghost"
                       size="icon"
                       @click.stop="handleDownload($event, file)"
                       title="Download"
                       class="h-8 w-8 text-muted-foreground hover:text-indigo-500"
                    >
                       <Download class="h-4 w-4" />
                    </Button>
                    
                    <Button
                       v-if="!file.isFolder"
                       variant="ghost"
                       size="icon"
                       @click.stop="deleteFile(file)"
                       title="Delete"
                       class="h-8 w-8 text-muted-foreground hover:text-red-500"
                    >
                       <Trash2 class="h-4 w-4" />
                    </Button>
                    
                    <div v-if="file.isFolder" class="h-8 w-16 flex items-center justify-center">
                      <span class="text-xs text-muted-foreground">—</span>
                    </div>
                  </div>
               </TableCell>
            </TableRow>

            <TableRow v-if="!isLoadingFiles && files.length === 0">
               <TableCell colspan="5" class="text-center text-muted-foreground py-8 h-48">
                  <div class="flex flex-col items-center justify-center space-y-3">
                    <div class="relative">
                      <Folder class="h-16 w-16 text-muted-foreground/30" />
                      <div class="absolute -top-1 -right-1 w-6 h-6 bg-indigo-500/20 rounded-full flex items-center justify-center">
                        <Upload class="h-3 w-3 text-indigo-400" />
                      </div>
                    </div>
                    <div class="space-y-1">
                      <p class="text-lg font-medium text-muted-foreground">No files found</p>
                      <p class="text-sm text-muted-foreground/70">Upload your first file to get started!</p>
                    </div>
                    <Button 
                      @click="uploadFile" 
                      class="mt-2 bg-indigo-600 hover:bg-indigo-700 text-white"
                      size="sm"
                    >
                      <Upload class="mr-2 h-4 w-4" /> Upload File
                    </Button>
                  </div>
               </TableCell>
            </TableRow>
          </template>
        </TableBody>
      </Table>
    </div>
  </div>
</template>