#import "/common/template.typ": *
#import "@preview/tenv:0.1.2": parse_dotenv
#import "@preview/codelst:2.0.2": sourcecode, sourcefile

#let env = parse_dotenv(read("/.env"))

#show: project.with(
  week: "第10回 課題",
  authors: (
    (name: env.STUDENT_NAME, email: "学籍番号：" + env.STUDENT_ID, affiliation: "所属：情報科学類"),
  ),
  date: "2026 年 1 月 1 日",
)

#show math.equation: set text(font: ("New Computer Modern Math", "Noto Serif", "Noto Serif CJK JP"))
#show raw: set text(font: "Hack Nerd Font")

本課題を行った環境を以下に示す。
OS は Void Linux である。

#sourcecode[```
$ cat /proc/version
Linux version 6.12.52_1 (voidlinux@voidlinux) (gcc (GCC) 14.2.1 20250405, GNU ld (GNU Binutils) 2.44) #1 SMP PREEMPT_DYNAMIC Sun Oct 12 20:52:41 UTC 2025
```]

#include "1.typ"

#include "2.typ"
