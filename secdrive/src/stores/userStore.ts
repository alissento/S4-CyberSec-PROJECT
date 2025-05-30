import { defineStore } from 'pinia';
import { api } from '@/config';

export const useUserStore = defineStore('user', {
    state: () => ({
        userData: null,
    }),
    actions: {
        async fetchUserData(userId: any) {
            try {
                const response = await api.get(`/getUserProfile?user_id=${userId}`);
                this.userData = response.data;
                console.log('Fetched user profile:', response.data);
            } catch (error) {
                console.error('Failed to fetch user profile:', error);
                this.userData = null;
            }
        },
        async updateUserData(userId: string, userData: any) {
            try {
                const response = await api.post('/storeUserData?operation=update', {
                    user_id: userId,
                    ...userData
                });
                
                // Update local store after successful API call
                await this.fetchUserData(userId);
                return response.data;
            } catch (error) {
                console.error('Failed to update user data:', error);
                throw error;
            }
        },
        async clearUserData() {
            this.userData = null;
        }
    },
    getters: {
        getUserData: (state) => state.userData,
    },
});