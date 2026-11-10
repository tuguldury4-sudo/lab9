# Лаборатори №9 — Код хамралт: JaCoCo-гоор тестээ хөтлөх

**Оюутан:** Я. Төгөлдөр **Оюутны код:** B242270806 **Хичээл:** F.CSA313 — Программ хангамжийн чанарын баталгаа ба туршилт (2026)

## 1. Ажлын орчин

```
$ java -version
openjdk version "17.0.20.1" 2026-08-18
OpenJDK Runtime Environment Temurin-17.0.20.1+1 (build 17.0.20.1+1)
OpenJDK 64-Bit Server VM Temurin-17.0.20.1+1 (build 17.0.20.1+1, mixed mode, sharing)

$ mvn -version
Apache Maven 3.9.9 (8e8579a9e76f7d015ee5ec7bfcdc97d260186937)
Maven home: C:\Users\THE_FEDzUP\tools\apache-maven-3.9.9
Java version: 17.0.20.1, vendor: Eclipse Adoptium, runtime: C:\Program Files\Eclipse Adoptium\jdk-17.0.20.101-hotspot
Default locale: en_US, platform encoding: Cp1252
OS name: "windows 11", version: "10.0", arch: "amd64", family: "windows"
```

| Зүйл | Утга |
|---|---|
| JDK | Eclipse Temurin OpenJDK 17.0.20.1 |
| Build | Apache Maven 3.9.9 |
| Тест хүрээ | JUnit Jupiter 5.10.2, maven-surefire-plugin 3.2.5 |
| Код хамралт | JaCoCo 0.8.12 (jacoco-maven-plugin) |
| ҮС | Windows 11 Pro, Git Bash |

**Орчны тайлбар.** Заавар Ubuntu-д зориулагдсан; энэ машин дээр WSL байхгүй тул Лаб 4-д тохируулсан Windows орчноо хэвээр ашиглав. Бүх командыг Git Bash дээр (`mvn verify 2>&1 | tee ...`) ажиллуулсан тул results/ доторх файлууд UTF-8 хэлбэртэй.

## 2. Репозиторийн бүтэц

```
pom.xml
src/main/java/mn/edu/must/sqat/ScholarshipCalculator.java       тестлэгдэх класс
src/test/java/mn/edu/must/sqat/ScholarshipCalculatorTest.java   миний тестүүд
cfg.png                                       scholarship()-ийн гараар зурсан CFG
results/mvn-verify-A.txt, jacoco-A.csv        Хэсэг A: happy path
results/mvn-verify-B.txt, jacoco-B.csv        Хэсэг B: Branch/Line 100%
results/mvn-test-D-fail.txt                   Хэсэг D: letterGrade(60) унасан гаралт
results/mvn-verify-final.txt, jacoco-final.csv  засварын дараах эцсийн байдал
ai/prompt.txt                                 нэмэлт даалгавар: AI-д өгсөн prompt
ai/AiScholarshipCalculatorTest.java.txt       AI-ийн бичсэн тест (src/test-д ОРУУЛААГҮЙ)
ai/run-ai-compare.sh                          AI-ийн тестийг алдаатай/засагдсан кодын эсрэг ажиллуулах скрипт
ai/ai-results.txt, ai-jacoco-buggy/fixed.csv  скриптийн гаралт
```

`ScholarshipCalculator` нь гурван функцтэй: `letterGrade` (оноо → A/B/C/D/F), `gpa` (дүнгүүдийн голч), `scholarship` (голч, кредит, сахилгын зөрчлөөр тэтгэлгийн хувь 0/50/70/100).

## 3. Хэсэг A — Happy path ба анхны хэмжилт

Зөвхөн хэвийн урсгалын 5 тест бичсэн: `letterGrade(95)="A"`, `letterGrade(85)="B"`, `gpa([95,85])=3.5`, `scholarship(3.9,16,false)=100`, `scholarship(3.9,16,true)=0`.

Анхны хамралт (results/jacoco-A.csv-ээс тооцсон):

| Хэмжүүр | Covered / Missed | Хувь |
|---|---|---|
| Line | **ӨӨРИЙН ТООГООР** | **...%** |
| Branch | **ӨӨРИЙН ТООГООР** | **...%** |

**Ажиглалт.** Шар ромбо бүхий мөрүүд нь `||` ба `&&` нөхцөлтэй `if`-үүд (жишээ нь `scholarship` дахь `gpa >= 3.8 && credits >= 15`): нэг талын утгыг л туршсан тул салаа хагас хамрагдсан. Улаан (огт хүрээгүй) мөрүүд нь бүгд алдааны зам: `throw new IllegalArgumentException(...)` мөрүүд, мөн `gpa()`-ийн `switch` дахь `default` (F дүн).

## 4. Хэсэг B — CFG ба Branch 100%

`scholarship()`-ийн CFG-г гараар зурж `cfg.png` болгон хадгалсан. Ирмэг бүрийн хажууд түүнийг дайрах тестийн нэрийг бичсэн:

| Шийдвэр | Ирмэг | Тест |
|---|---|---|
| `gpa < 0` | true | `scholarship_gpaNegative_throws` |
| `gpa > 4` | true | `scholarship_gpaOver4_throws` |
| `credits < 0` | true | `scholarship_creditsNegative_throws` |
| `hasViolation` | true / false | `scholarship_violation_isZero` / `scholarship_highGpaEnoughCredits_is100` |
| `gpa >= 3.8` | false | `scholarship_gpa35_credits12_is70` |
| `credits >= 15` | false | `scholarship_gpa38_creditsShort_falls_to70` |
| `gpa >= 3.4` | false | `scholarship_gpa30_manyCredits_is50` |
| `credits >= 12` | false | `scholarship_gpa35_creditsShort_falls_to50` |
| `gpa >= 3.0` | false | `scholarship_lowGpa_isZero` |

`gpa()`-ийн `switch` дахь `default` салааг `gpa_withFailingGrade_coversSwitchDefault`, `letterGrade`-ийн 0-100 хязгаараас гадуурх замыг `letterGrade_negative_throws`, `letterGrade_over100_throws`, null ба хоосон массивыг `gpa_null_throws`, `gpa_empty_throws` тестүүд хамарна.

Хэсэг B-ийн дараа нийт **22 тест** байна (results/mvn-verify-B.txt-ийн `Tests run:` тоотой таарна). results/jacoco-B.csv-д `BRANCH_MISSED = 0`, `LINE_MISSED = 0`.

## 5. Хэсэг C — Давталтын заагийн тестүүд (0 / 1 / 2+)

| Давталт | Тест | Хүлээгдэх үр дүн |
|---|---|---|
| 0 удаа | `gpa_loop0_emptyArray_throws`, `gpa_loop0_null_throws` | `IllegalArgumentException` (assertThrows) |
| 1 удаа | `gpa_loop1_singleScore_is4` | `gpa([95]) == 4.0` |
| 2+ удаа | `gpa_loop2plus_fourScores_is2point5` | `gpa([95,85,75,65]) == 2.5` |

**Яагаад хэрэгтэй вэ.** Эдгээр тест хамралтын тоог өсгөөгүй, учир нь салаа бүр аль хэдийн хамрагдсан байсан. Гэвч давталтын хязгаарын алдаа (off-by-one, хоосон оролтод 0-д хуваах, нэг элементтэй массивын буруу тооцоо) нь салаа хамралтаар харагддаггүй бөгөөд зөвхөн 0/1/2+ утгууд л илрүүлдэг.

## 6. Хэсэг D — Хамралт 100%, гэхдээ алдаа амьд

Спецификаци: 60-69.99 оноо "D". Зааг утгын тестүүд (`0, 59.99, 60, 69.99, 70, 79.99, 80, 89.99, 90, 100`) нэмж `mvn test` ажиллуулахад унав (results/mvn-test-D-fail.txt):

- Унасан тест: `letterGrade_boundaries` — `letterGrade(60) = D` мөр
- Алдааны мөр: `expected: <D> but was: <F>`

Шалтгаан нь `letterGrade` доторх `if (score > 60) return "D";` мөр байв: харьцуулах оператор нь `>` байсан тул 60 оноо "F" болж байсан. Спец ёсоор `>= 60` байх ёстой.

Засвар (тусдаа commit): `Fix letterGrade: > 60 -> >= 60, spec says 60 is D`. Дараа нь бүх тест ногоон болж, results/jacoco-final.csv-д `BRANCH_MISSED = 0`, `LINE_MISSED = 0`.

**Гол дүгнэлт.** Branch хамралт 100% байхад энэ алдаа "үл үзэгдэгч" байв, учир нь `score > 60` ба `score >= 60` хоёр нь яг ижил салаануудыг (true, false) үүсгэдэг. Хэсэг B-ийн тестүүд 65 (true) ба 30 (false) утгаар хоёр салааг аль хэдийн хамарсан тул JaCoCo-д дутуу зүйл харагдаагүй. Хамралт нь аль мөр, салаа ажилласныг хэмждэг боловч ажилласан код зөв хариу өгсөн эсэхийг хэмждэггүй. Зөвхөн яг 60 гэсэн зааг утгын тест хоёр операторын ялгааг илрүүлсэн. Иймээс хамралт нь тест дутуу газрыг хайх хэрэгсэл бөгөөд кодын зөв байдлын нотолгоо биш; түүнийг зааг утгын болон спецификацид суурилсан тестээр нөхөх ёстой.

## 7. Commit түүх

| № | Commit | Агуулга |
|---|---|---|
| 1 | Part A | happy path тест, jacoco-A.csv |
| 2 | Part B | 100% branch, cfg.png, jacoco-B.csv |
| 3 | Part C | давталтын заагийн тестүүд |
| 4 | Part D | зааг утгын тест нэмсэн (унасан), mvn-test-D-fail.txt |
| 5 | Fix letterGrade | `> 60` → `>= 60`, эцсийн results |

## 8. AI ашигласан тухай

AI туслахыг (Claude) `ScholarshipCalculator`-ийн кодыг уншуулж тестийн жагсаалт ба README-ийн бүтцийн төсөл гаргахад ашигласан. Тестүүдийг өөрийн машин дээр ажиллуулж, хамралтын тоо, унасан тестийн мөр, cfg.png-г өөрөө гаргаж шалгасан.

## 9. Нэмэлт даалгавар (Сонголт 2) — AI өнцөг

AI туслахад Хэсэг A-гийн дараах (100% болохоос өмнөх) төслийг (`pom.xml`, `ScholarshipCalculator.java`) өгч "хамралтыг 100% болгох тест бич" гэв ([`ai/prompt.txt`](ai/prompt.txt)); гаралт [`ai/AiScholarshipCalculatorTest.java.txt`](ai/AiScholarshipCalculatorTest.java.txt) (20 `@Test`). Үндсэн `Tests run:`-д нөлөөлөхгүйн тулд `src/test`-д оруулаагүй, [`ai/run-ai-compare.sh`](ai/run-ai-compare.sh) скриптээр түр хуулбар төсөл дээр алдаатай (`score > 60`) ба засагдсан (`score >= 60`) кодын эсрэг ажиллуулав ([`ai/ai-results.txt`](ai/ai-results.txt)):

| | Алдаатай код (`> 60`) | Засагдсан код (`>= 60`) |
|---|---|---|
| Тест унасан эсэх | **ai-results.txt-ээс бич** | **ai-results.txt-ээс бич** |
| Branch (missed / covered) | **ai-jacoco-buggy.csv-ээс** | **ai-jacoco-fixed.csv-ээс** |
| Line (missed / covered) | **ai-jacoco-buggy.csv-ээс** | **ai-jacoco-fixed.csv-ээс** |

Дүгнэлт (5–8 өгүүлбэр) — ai-results.txt-ийн бодит үр дүнгээр бич:
(1) AI-ийн тест хамралтыг 100% болгосон эсэх. (2) Хэсэг D-гийн `letterGrade(60)` алдааг барьсан эсэх, ямар тест унасан. (3) AI-ийн тест аль утгуудыг сонгосон (дунд зэргийн 95/85/75/65/30 үү, зааг утга уу). (4) Үр дүн нь "хамралт 100% = зөв код" гэсэн ойлголтын талаар юу хэлж байна. (5) AI-ийн тестийг шууд хуулахгүй, зааг утгаар нөхөж шалгах ёстой гэсэн дүгнэлт.
