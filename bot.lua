local api = require("telegram-bot-lua.core").configure("enter your token here") -- Enter your token
local json = require("dkjson")

local driver = require("luasql.sqlite3")
local env = driver.sqlite3()
local db = env:connect("db.sqlite")

local cursor = db:execute [[
  SELECT * FROM pushkin
]]

local results = {}
local row = cursor:fetch({}, "a")
while row do
  table.insert(results, {name = row.name, text = row.text, img = row.img})
  row = cursor:fetch({}, "a")
end

cursor:close()
db:close()
env:close()

function utf8_sub(s, i, j)
  i = utf8.offset(s, i)
  j = utf8.offset(s, j + 1) - 1
  return string.sub(s, i, j)
end

function api.on_message(message)
  if message.text then
    if message.text:sub(1, 1) == "/" then
      api.send_message(message.chat.id, "Добро пожаловать! Введите текст для поиска.")
      return
    end

    local text = message.text:lower()
    local buttons = {}
    local search_text = text

    while #search_text > 3 do
      for _, result in ipairs(results) do
        if #buttons >= 3 then
          break
        end
        if result.name:lower():find(search_text, 1, true) then
          table.insert(buttons, {text = result.name, callback_data = result.name})
        end
      end
      if #buttons > 0 then
        break
      end
      search_text = utf8_sub(search_text, 1, utf8.len(search_text) - 1)
    end

    os.execute("sleep 0.5")
    if #buttons > 0 then
      local keyboard = api.inline_keyboard()
      local row = api.row()
      for _, button in ipairs(buttons) do
        row:callback_data_button(button.text, button.callback_data)
      end
      keyboard:row(row)
      keyboard:row(api.row():callback_data_button("Вернуться", "/start"))
      api.send_message(message.chat.id, "Выберите один из вариантов:", nil, nil, nil, nil, false, false, nil, keyboard)
    else
      api.send_message(message.chat.id, "Ничего не найдено.")
    end
  end
end

function api.on_callback_query(callback_query)
  local name = callback_query.data
  if name == "/start" then
    api.send_message(callback_query.message.chat.id, "Добро пожаловать! Введите текст для поиска.")
  else
    for _, result in ipairs(results) do
      if result.name == name then
        api.send_message(callback_query.message.chat.id, result.text)
        api.send_photo(callback_query.message.chat.id, "img/" .. result.img)
        break
      end
    end
  end
  api.answer_callback_query(callback_query.id)
end

api.run()