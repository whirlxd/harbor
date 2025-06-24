/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/**/*',
  ],
  theme: {
    extend: {
      colors: {
        'darker': '#121217',
        'dark': '#17171d',
        'darkless': '#252429',
        'black': '#1f2d3d',
        'steel': '#273444',
        'slate': '#3c4858',
        'muted': '#8492a6',
        'smoke': '#e0e6ed',
        'snow': '#f9fafc',
        'white': '#ffffff',
        'red': '#ec3750',
        'orange': '#ff8c37',
        'yellow': '#f1c40f',
        'green': '#33d6a6',
        'cyan': '#5bc0de',
        'blue': '#338eda',
        'purple': '#a633d6',
        'primary': '#ec3750',
        'secondary': '#8492a6',
        'accent': '#5bc0de',
        'text': '#ffffff',
        'background': '#121217',
        'elevated': '#17171d',
        'sheet': '#252429',
        'sunken': '#252429',
        'border': '#252429'
      }
    },
  },
  plugins: [],
}
