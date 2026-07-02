<script setup lang="ts">
interface CurriculumSubject {
  semester: string;
  parent_semester?: number | null;
  subject_code?: string;
  subject_name: string;
  course_type?: string;
  l_t_p?: string;
  tcp?: number | null;
  credits?: number | null;
  category?: string;
  is_elective?: boolean;
  elective_type?: string | null;
  record_type?: string;
  elective_stream?: string | null;
  options_from?: string | null;
}

const props = defineProps<{
  subject: CurriculumSubject;
  isNew: boolean;
}>();

const emit = defineEmits<{
  save: [subject: CurriculumSubject];
  cancel: [];
}>();

const form = reactive<CurriculumSubject>({ ...props.subject });

const recordTypeOptions = ["core", "slot", "option"];

const save = () => {
  if (!form.subject_name.trim() || !form.semester.trim()) return;
  emit("save", {
    ...form,
    subject_name: form.subject_name.trim(),
    semester: form.semester.trim(),
    parent_semester:
      form.parent_semester === undefined ||
      form.parent_semester === null ||
      (form.parent_semester as unknown as string) === ""
        ? null
        : Number(form.parent_semester),
    tcp:
      form.tcp === undefined || form.tcp === null || (form.tcp as unknown as string) === ""
        ? null
        : Number(form.tcp),
    credits:
      form.credits === undefined ||
      form.credits === null ||
      (form.credits as unknown as string) === ""
        ? null
        : Number(form.credits),
  });
};
</script>

<template>
  <div
    class="fixed inset-0 z-[60] flex items-center justify-center bg-black/40 p-4"
    @click.self="emit('cancel')"
  >
    <div class="bg-white rounded-xl shadow-xl w-full max-w-lg max-h-[85vh] overflow-y-auto p-6">
      <h3 class="text-base font-semibold text-gray-900 mb-4">
        {{ isNew ? "Add subject" : "Edit subject" }}
      </h3>

      <div class="grid grid-cols-2 gap-3">
        <div class="col-span-2">
          <label class="block text-xs font-medium text-gray-600 mb-1"
            >Subject name *</label
          >
          <input
            v-model="form.subject_name"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-yellow-400"
          />
        </div>

        <div>
          <label class="block text-xs font-medium text-gray-600 mb-1"
            >Subject code</label
          >
          <input
            v-model="form.subject_code"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-yellow-400"
          />
        </div>

        <div>
          <label class="block text-xs font-medium text-gray-600 mb-1"
            >Record type</label
          >
          <select
            v-model="form.record_type"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-yellow-400"
          >
            <option v-for="rt in recordTypeOptions" :key="rt" :value="rt">
              {{ rt }}
            </option>
          </select>
        </div>

        <div>
          <label class="block text-xs font-medium text-gray-600 mb-1"
            >Semester / pool *</label
          >
          <input
            v-model="form.semester"
            placeholder="e.g. 3 or Programme Elective"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-yellow-400"
          />
        </div>

        <div>
          <label class="block text-xs font-medium text-gray-600 mb-1"
            >Parent semester</label
          >
          <input
            v-model="form.parent_semester"
            type="number"
            placeholder="Numeric semester (for slots)"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-yellow-400"
          />
        </div>

        <div>
          <label class="block text-xs font-medium text-gray-600 mb-1"
            >Course type</label
          >
          <input
            v-model="form.course_type"
            placeholder="T / LIT / L"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-yellow-400"
          />
        </div>

        <div>
          <label class="block text-xs font-medium text-gray-600 mb-1"
            >L-T-P</label
          >
          <input
            v-model="form.l_t_p"
            placeholder="3-0-0"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-yellow-400"
          />
        </div>

        <div>
          <label class="block text-xs font-medium text-gray-600 mb-1"
            >TCP</label
          >
          <input
            v-model="form.tcp"
            type="number"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-yellow-400"
          />
        </div>

        <div>
          <label class="block text-xs font-medium text-gray-600 mb-1"
            >Credits</label
          >
          <input
            v-model="form.credits"
            type="number"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-yellow-400"
          />
        </div>

        <div>
          <label class="block text-xs font-medium text-gray-600 mb-1"
            >Category</label
          >
          <input
            v-model="form.category"
            placeholder="BS / HUM / ES (PC)"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-yellow-400"
          />
        </div>

        <div>
          <label class="block text-xs font-medium text-gray-600 mb-1"
            >Elective type</label
          >
          <input
            v-model="form.elective_type"
            placeholder="Programme Elective"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-yellow-400"
          />
        </div>

        <div>
          <label class="block text-xs font-medium text-gray-600 mb-1"
            >Elective stream</label
          >
          <input
            v-model="form.elective_stream"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-yellow-400"
          />
        </div>

        <div>
          <label class="block text-xs font-medium text-gray-600 mb-1"
            >Options from</label
          >
          <input
            v-model="form.options_from"
            placeholder="Pool this slot picks from"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-yellow-400"
          />
        </div>

        <div class="col-span-2">
          <label class="flex items-center gap-2 cursor-pointer">
            <input v-model="form.is_elective" type="checkbox" class="w-4 h-4" />
            <span class="text-sm text-gray-700">Is elective</span>
          </label>
        </div>
      </div>

      <div class="flex justify-end gap-2 pt-5">
        <button
          class="px-4 py-2 text-sm border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
          @click="emit('cancel')"
        >
          Cancel
        </button>
        <button
          class="px-4 py-2 text-sm bg-yellow-400 text-gray-900 font-medium rounded-lg hover:bg-yellow-500 transition-colors"
          @click="save"
        >
          {{ isNew ? "Add" : "Save" }}
        </button>
      </div>
    </div>
  </div>
</template>
