
## О скрипте
- Cкрипт Helper-Report специально для проекта Russia Role Play (Moscow).
- Цель скрипта: превратить текст репорта в функциональном интерфейсе, а также меню рекона и прочее


## Функция скрипта
- Активация автоматическая;
- Имеется авто-обновление (ваш страх и риск), если появится обновление вводите /hr_verify для подтверждения;
- Заменяет простой текст для ответа репорта на интерфейс, улучшенное окно;
- Если репорт отвечен от другого администратора (кроме последний репорт, которые Вы видите репорт), то удаляется с списка неотвеченные репорты. Это упрощает Ваших времени. Почувствуете, что Вы администрируете на Аризоне с репортами;
- Меню-рекон;
- Кейкап (`keycap`) игрока при рекон;
- Таймер репорта (формат `часов:минуты:секунды`), следите актуальные репорты, если забываете что репорт актуальный или нет - скажете автора репорта актуально ли; Обнуляются если Вы обновляете список свободных репортов на неактивном репорте;
- При включение скрипта - худ радары больше не скрывает. Например, пригодится для следящих по гетто;
- Перекраски в чате, а также можно менять цвет и формат админ-чата по Вашему желанию;
- Репорт сохраняет если игрок вышел с сервера (можно поставить галочка в настройка `Если игрок вышел с игры скипать жалобу (кроме последней)`, если хотите убрать)
- Убирает фриз после рекона.

## Окно репорта
**Неактивное окно**. Если хотите чтобы обновить, нажимаете **левую Alt** и нажимаете окно - репорты обновляются через командой `/define`. Обратите внимание, после обновления список репортов, таймеры сбрасывают.

**Кнопка ник автора и нарушителя**. Кнопка является селектабль (Selectable, выделенные таблицы, как таблицы с кнопкой). Если автор в сети, показывает меню автора и там входят по умолчанию, копирование ник и ид, наказать за уход от наказания (вынуждно указать англ.причина, из-за неправильные кодировки в база данных сервера), если 

**Кнопка "RE: Автор"**. Понаблюдать автор. Автор, который подал жалобу на игрока. Если автор не в сети либо не совпадает ID и Nick - кнопка скрывает.

**Кнопка "RE: ID**. Понаблюдать нарушитель. Нарушитель, который указан ID в жалобе. Если нарушитель не в сети либо не найдено ID в жалобе - кнопка скрывает.

**Кнопка "Ответы"**. Раскрывает список шаблонные ответы. Это можно заполнять командой /shr -> Ответы -> Создать или выбрать некоторые ответы и отредактировать. Если удерживаете **левую Ctrl** и выбираете ответ, то после ответа сразу переходит в следующем неотвеченныйе репорт (данная функция не работает на полном экране список ответов).

**Кнопка "Закрыть"**. Просто переходит в следующем неотвеченные репорты, если есть. Иначе переходит на неактивное окно.

**Кнопка "POS"**. Изменить позиция окно репорта. Если нажал, то выбираете что необходимо поставить, нажмите пробел (Space) чтобы сохранить. Добавлена команда `/reportpos` для особых случае, если окно находится вне рамки игры и там кнопки перекрыты и невозможно нажимать.

**Переключатель "PM" и "SMS"**. Настраивать можно в `/shr` -> `Настройки` -> `Переходить на SMS после первого ответа (жёлтая кнопка)`. Если Вам не нравится когда постоянно исправляете опечаток или поправить PM, то это Вам пригодится. Если по настройке активно, то после ответа автора сразу переключает на SMS, а также заменяет в ответе `/pm ` на `/sms `. Как это работает? Вы указали ответ **Привет** и отправил - скрипт отправил в чате `/pm id Привет` сразу переключает на SMS и снова отправляете с ответом **Здравствуйте** с активном переключатель SMS. И что получилось? Скрипт заменяет команду /pm на /sms (`/pm id Здравствуйте` -> `/sms id Здравствуйте`).

**Переключатель "SKIP"**. Настраивать можно в `/shr` -> `Настройки` -> `Переходить на SMS после первого ответа (жёлтая кнопка)`. Если кнопка SKIP жёлтая, то переключатель активный, после ответа сразу переходит в следующем репорт.


## Настройки (/shr, Settings Helper Report)
**Вкладка "Настройки"**. В настройках входит функция окно репорта и чат, а также формат админ-чата. Кнопка Restore - восстанавливает на прежнем формат админ-чата.

**Вкладка "Чаты"**. Входят цвет чата, менять Вы можете что угодно. Кнопка Restore - восстанавливает на прежнем цвет.

Что входят?
- [Репорт] В начале
- [Репорт] После ника
- [PM] В начале
- [PM] После ника
- [Админ-чат] В начале
- [Админ-чат] После ника
- Античит
- Действие адм (выдачи наказание, а также указаны ID)
- Прочее действие адм с префиксом [A]

**Вкладка "Ответы"**. Шаблон ответа /pm, можно создавать, отредактировать и удалять. Задержки каждые строка - 1 секунд. Форматы: `@anick` - ник автора, `@aid` - ид автора, `@rnick` - ник нарушителя (если нарушитель не в сети - ответы не будут отправлены), `@rid` - ид нарушителя (также и проверяет он в сети ли), `@msg` - текст репорта.

По умолчанию созданы шаблонные ответы:
- Телепорт к его
- Пожелать приятной игры
- Жалоба в сг
- Передать в /a


## Демонстрация работы
- **Скриншоты:**
Скоро


- **Видеозапись (кликбательно):**
Скоро


## Установка
1. Нажимаете зелёную кнопку "Code" -> "Download ZIP"
2. Архив успешно скачано, теперь открываем.
- Если у вас на сборке заранее установлены MoonLoader и SAMPFUNCS, а также работоспособны в любом скрипте. В таком случае скрипт `helper-report-auto.lua` скидывать в папке `moonloader` и переходите на 3 шаг.
- Скрипт `helper-report-auto.lua` скидывать в папку `moonloader`. Архив библиотеки `libs.zip` распокуете и всё что там хранится - скидываете в папке `lib` и соглашаем подтверждение
3. Заходить на SA-MP и прописывать команду /shr, настраиваете что хотите. Показать и скрыть окно репорта - **англ. P**, курсор - **левый Alt**.


## Автор скрипта
- Mikhail_Stewart aka kyrtion
- Telegram: https://t.me/kyrtion
- VKontakte: https://vk.com/kyrtion
- Discord: kyrtion#7310
