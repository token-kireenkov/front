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

        <div v-if="outputJson" class="token__result-container">
          <div class="token__result-header">
            <label class="block mb-2 font-medium">Результат:</label>
            <button
              class="token__copy-button"
              @click="copyToClipboard(outputJson, 'Результат скопирован!')"
              :disabled="isCopying"
            >
              Копировать
            </button>
          </div>
          <pre class="token__result-1">{{ outputJson }}</pre>
        </div>

        <div v-if="concatenatedString" class="token__result-container">
          <div class="token__result-header">
            <label class="block mb-2 font-medium">Строка конкатенации:</label>
            <button
              class="token__copy-button"
              @click="
                copyToClipboard(
                  concatenatedString,
                  'Строка конкатенации скопирована!'
                )
              "
              :disabled="isCopying"
            >
              Копировать
            </button>
          </div>
          <pre class="token__result">{{ concatenatedString }}</pre>
        </div>

        <div v-if="copyNotification" class="token__notification">
          {{ copyNotification }}
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
const isCopying = ref(false)
const copyNotification = ref('')

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

const copyToClipboard = async (text: string, message: string) => {
  if (isCopying.value) return

  isCopying.value = true

  try {
    await navigator.clipboard.writeText(text)
    copyNotification.value = message

    setTimeout(() => {
      copyNotification.value = ''
    }, 2000)
  } catch (err) {
    copyNotification.value = 'Ошибка при копировании'
    console.error('Ошибка копирования:', err)
  } finally {
    setTimeout(() => {
      isCopying.value = false
    }, 300)
  }
}

const handleGenerate = async () => {
  const scrollY = window.scrollY

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
    setTimeout(() => window.scrollTo(0, scrollY), 0)
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
    setTimeout(() => window.scrollTo(0, scrollY), 0)
  } catch (e) {
    error.value = 'Произошла ошибка при генерации токена.'
    setTimeout(() => window.scrollTo(0, scrollY), 0)
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
    border: none;
    cursor: pointer;
    font-weight: 600;

    &:hover {
      background: #f0d000;
    }
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

  &__result-container {
    display: flex;
    flex-direction: column;
    gap: 10px;
  }

  &__result-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    flex-wrap: wrap;
    gap: 10px;
  }

  &__copy-button {
    padding: 8px 16px;
    background: #4caf50;
    color: white;
    border: none;
    border-radius: 6px;
    cursor: pointer;
    font-size: 14px;
    font-weight: 500;
    transition: all 0.2s ease;
    min-width: 100px;

    &:hover:not(:disabled) {
      background: #45a049;
      transform: translateY(-1px);
    }

    &:active:not(:disabled) {
      transform: translateY(0);
    }

    &:disabled {
      background: #45a049;
      cursor: not-allowed;
      transform: none;
    }
  }

  &__result {
    background: #f5f5f6;
    padding: 15px;
    font-family: monospace;
    overflow-x: scroll;
    margin: 0;
  }

  &__result-1 {
    background: #f5f5f6;
    padding: 15px;
    font-family: monospace;
    overflow-x: scroll;
    margin: 0;
  }

  &__error {
    background: #f5f5f6;
    padding: 15px;
    font-family: monospace;
    color: rgb(121, 4, 4);
    display: flex;
    flex-direction: column;
  }

  &__notification {
    position: fixed;
    top: 20px;
    right: 20px;
    background: #4caf50;
    color: white;
    padding: 12px 20px;
    border-radius: 6px;
    font-weight: 500;
    z-index: 1000;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
    animation: slideIn 0.3s ease-out;
    transition: opacity 0.3s ease;
  }
}

@keyframes slideIn {
  from {
    transform: translateX(100%);
    opacity: 0;
  }
  to {
    transform: translateX(0);
    opacity: 1;
  }
}
</style>
