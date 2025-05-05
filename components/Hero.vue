<template>
  <section class="token">
    <div class="container">
      <p class="token__description">
        { "TerminalKey": "test", "Amount": 140000, "OrderId": "21090",
        "Description": "Подарочная карта на 1000 рублей", "DATA": { "Phone":
        "+71234567890", "Email": "a@test.com" }, "Receipt": { "Email":
        "a@test.ru", "Phone": "+79031234567", "Taxation": "osn", "Items": [] } }
      </p>
      <div class="token__wrapper">
        <textarea v-model="inputJson" class="token__input" />
        <input
          v-model="password"
          type="text"
          class="token__password"
          placeholder="Пароль"
        />
        <button
          @click="handleGenerate"
          class="mt-4 px-6 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
        >
          Сгенерировать токен
        </button>

        <div v-if="error" class="mt-4 text-red-600 font-medium">
          {{ error }}
        </div>

        <div v-if="outputJson" class="mt-6">
          <label class="block mb-2 font-medium">Результат:</label>
          <pre class="token__result"
            >{{ outputJson }}
      </pre
          >
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { ref } from 'vue'

const inputJson = ref('')
const password = ref('')
const outputJson = ref('')
const error = ref('')

// функция генерации токена
const generateToken = async (
  data: Record<string, any>,
  secretKey: string
): Promise<string> => {
  const filteredData = Object.fromEntries(
    Object.entries(data).filter(([key]) => key !== 'DATA' && key !== 'Receipt')
  )

  filteredData['Password'] = secretKey

  const sortedEntries = Object.entries(filteredData).sort(([a], [b]) =>
    a.localeCompare(b)
  )
  const concatenated = sortedEntries.map(([, value]) => value).join('')

  const encoder = new TextEncoder()
  const dataBuffer = encoder.encode(concatenated)
  const hashBuffer = await crypto.subtle.digest('SHA-256', dataBuffer)
  const hashArray = Array.from(new Uint8Array(hashBuffer))
  return hashArray.map((b) => b.toString(16).padStart(2, '0')).join('')
}

const handleGenerate = async () => {
  error.value = ''
  outputJson.value = ''

  if (!password.value.trim()) {
    error.value = 'Пожалуйста, введите пароль (секретный ключ).'
    return
  }

  try {
    const parsed = JSON.parse(inputJson.value)

    const token = await generateToken(parsed, password.value.trim())
    const withToken = {
      ...parsed,
      Token: token,
    }

    outputJson.value = JSON.stringify(withToken, null, 2)
  } catch (e) {
    error.value = 'Неверный JSON. Пожалуйста, проверьте синтаксис.'
  }
}
</script>

<style scoped lang="scss">
.token {
  padding: 50px 0;
  &__description {
    margin-bottom: 30px;
    background: #f5f5f6;
    padding: 15px;
  }
  &__wrapper {
    display: flex;
    flex-direction: column;
    gap: 20px;
  }
  &__input {
    background: #ecf1f7;
    min-height: 350px;
    resize: none;
    padding: 15px;
    outline: none;
  }
  &__password {
    background: #ecf1f7;
    outline: none;
    padding: 10px;
  }
  &__result {
    background: #f5f5f6;
    padding: 15px;
  }
}
</style>
