# README 

Простой скрипт для запуска парсинга развернутых deployments в текущем project на предмет той или иной переменной.
```sh
searchVar="test"
```
Передав в переменную искомое значение, на выходе мы получим рядом со скриптов файл res.txt в котором будет указанно примерно следующее:
```sh
------------------
test-deploy
        - name: test
          value: "false"
------------------
------------------
test-deploy2
 
--
        - name: test
          value: "true"
--
        - name: test_policy
          value: "test-test"
------------------
------------------
```
,где в блоках ограниченных при помощи "----" первым идёт имя deployment, а далее имена переменных и значения к ним.
***That's All Folks(c)***