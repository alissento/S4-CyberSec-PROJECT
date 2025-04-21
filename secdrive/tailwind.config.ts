import { defineConfig } from 'tailwindcss/helpers'
import colors from 'tailwindcss/colors'

export default defineConfig({
  content: ['./index.html', './src/**/*.{vue,js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        gray: colors.neutral,
      },
    },
  },
  plugins: [],
})