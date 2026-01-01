/// <reference types="vite/client" />

// Allow importing HTML files as raw strings
declare module '*.html?raw' {
  const content: string;
  export default content;
}
