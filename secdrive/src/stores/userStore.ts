import { defineStore } from 'pinia';
import { api } from '@/config';

export const useUserStore = defineStore('user', {
    state: () => ({
        userData: null,
    }),
    actions: {
        async fetchUserData(userId: any) {
            if (this.userData) {
                return;
            }

            try {
                const response = await api.get(`/getUserData?user_id=${userId}`);
                this.userData = response.data;
            } catch (error) {
                console.error(error);
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