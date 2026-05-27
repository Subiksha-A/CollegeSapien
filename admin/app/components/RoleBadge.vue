<script setup lang="ts">
const props = defineProps<{ role: string }>();

const colorClass = computed(() => {
  switch (props.role) {
    case "superadmin":
      return "bg-purple-100 text-purple-800";
    case "admin":
      return "bg-blue-100 text-blue-800";
    case "moderator":
      return "bg-green-100 text-green-800";
    case "ambassador":
      return "bg-orange-100 text-orange-800";
    default:
      return "bg-gray-100 text-gray-600";
  }
});
</script>

<template>
  <span
    class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium capitalize"
    :class="colorClass"
  >
    {{ role }}
  </span>
</template>
