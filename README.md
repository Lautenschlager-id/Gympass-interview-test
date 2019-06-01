Olá!

Optei pela linguagem Lua por ser extremamente leve e flexível!<br>
Os comentários estão em inglês.

Você pode executar o código aqui → https://rextester.com/l/lua_online_compiler

Caso queira digitar o nome de um arquivo com outro log, alterar as linhas 1 até 24 (o trecho de log) por:
```Lua
local log = io.read() -- Digite o nome do arquivo no input
do
  local file = io.open(log, 'r')
  log = file:read("*a")
  file:close()
end
```
