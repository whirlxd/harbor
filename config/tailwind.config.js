/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/**/*',
  ],
  theme: {
    extend: {
      colors: {
        'darker': '#121217',
        'dark': '#17171D',
        'darkless': '#252429',
        'red': '#EC3750',
        'orange': '#FF8C37',
        'yellow': '#F1C40F',
        'green': '#33D6A6',
        'cyan': '#5BC0DE',
        'blue': '#338EDA',
        'purple': '#A633D6',
        'primary': '#EC3750',
        'secondary': '#8492A6'
      }
    },
  },
  plugins: [],
}
