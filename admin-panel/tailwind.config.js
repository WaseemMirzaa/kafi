/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        rose: { DEFAULT: '#FF8FAB', dark: '#FF5C8A', light: '#FFB5C8', pale: '#FFF0F5' },
        purple: { DEFAULT: '#9B6EDB', light: '#F5EEFF' },
        green: { DEFAULT: '#6DBF8A', light: '#E8F8EE', dark: '#2E9A58' },
        amber: { DEFAULT: '#FFB347', light: '#FFF4E0' },
        navy: { DEFAULT: '#1E2A4A', soft: '#E8EBF5' },
        teal: '#0EA5A0',
        td: '#3D1A26',
        tm: '#7A3A50',
        ts: '#C490A0',
      },
      fontFamily: {
        pacifico: ['Pacifico', 'cursive'],
        fredoka: ['Fredoka', 'sans-serif'],
        nunito: ['Nunito', 'sans-serif'],
      },
    },
  },
  plugins: [],
};
