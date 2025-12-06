<template>
  <div class="app-container">
    <MatrixReport />
  </div>
</template>

<script setup>
import MatrixReport from './views/MatrixReport.vue'
</script>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: 'Microsoft YaHei', 'Segoe UI', sans-serif;
  background: #f5f7fa;
  min-height: 100vh;
}

.app-container {
  padding: 20px;
  max-width: 1800px;
  margin: 0 auto;
}
</style>

