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
        <textarea
          v-model="inputJson"
          class="token__input"
          placeholder="Введите JSON"
        />
        <input
          v-model="password"
          type="text"
          class="token__password"
          placeholder="Пароль"
        />

        <button class="token__button" @click="handleGenerate">
          Сгенерировать токен
        </button>

        <div v-if="error" class="token__error">
          {{ error }}
        </div>

        <div v-if="outputJson">
          <label class="block mb-2 font-medium">Результат:</label>
          <pre class="token__result">{{ outputJson }}</pre>
        </div>

        <div v-if="concatenatedString">
          <label class="block mb-2 font-medium">Строка конкатенации:</label>
          <pre class="token__result">{{ concatenatedString }}</pre>
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
const concatenatedString = ref('')

const generateToken = async (
  data: Record<string, any>,
  secretKey: string
): Promise<{ token: string; concatenated: string }> => {
  const filteredData = Object.fromEntries(
    Object.entries(data).filter(
      ([key]) => key !== 'DATA' && key !== 'Receipt' && key !== 'Token'
    )
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
  const token = hashArray.map((b) => b.toString(16).padStart(2, '0')).join('')

  return { token, concatenated }
}

const handleGenerate = async () => {
  error.value = ''
  outputJson.value = ''
  concatenatedString.value = ''

  const errors = []

  if (!inputJson.value.trim()) {
    errors.push('* Пожалуйста, введите JSON.')
  } else {
    try {
      JSON.parse(inputJson.value)
    } catch {
      errors.push('* Неверный JSON. Пожалуйста, проверьте синтаксис.')
    }
  }

  if (!password.value.trim()) {
    errors.push('* Пожалуйста, введите пароль (секретный ключ).')
  }

  if (errors.length) {
    error.value = errors.join('\n')
    return
  }

  try {
    const parsed = JSON.parse(inputJson.value)
    const { token, concatenated } = await generateToken(
      parsed,
      password.value.trim()
    )
    concatenatedString.value = concatenated

    const withToken = {
      ...parsed,
      Token: token,
    }

    outputJson.value = JSON.stringify(withToken, null, 2)
  } catch (e) {
    error.value = 'Произошла ошибка при генерации токена.'
  }
}
</script>

<style scoped lang="scss">
.token {
  padding: 50px 0;
  &__button {
    padding: 10px 20px;
    background: #ffdd31;
    border-radius: 30px;
  }
  &__description {
    margin-bottom: 30px;
    background: #f5f5f6;
    padding: 15px;
    font-family: monospace;
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
    font-family: monospace;
  }

  &__password {
    background: #ecf1f7;
    outline: none;
    padding: 10px;
  }

  &__result {
    background: #f5f5f6;
    padding: 15px;
    font-family: monospace;
  }
  &__error {
    background: #f5f5f6;
    padding: 15px;
    font-family: monospace;
    color: rgb(121, 4, 4);
    display: flex;
    flex-direction: column;
  }
}
</style>
