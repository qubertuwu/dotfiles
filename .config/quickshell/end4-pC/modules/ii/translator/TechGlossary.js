// Tech and Developer Slang Glossary & Smart Post-Processor
.pragma library

// UI Buttons, Actions & Dialog Statuses (lowercase English -> Russian UI equivalent)
var uiActionsEnToRu = {
    "dismiss": "Закрыть",
    "dismissed": "Закрыто",
    "dismissing": "Закрытие",
    "cancel": "Отмена",
    "close": "Закрыть",
    "closed": "Закрыто",
    "discard": "Сбросить / Отклонить",
    "discarded": "Сброшено",
    "apply": "Применить",
    "applied": "Применено",
    "ok": "ОК",
    "save": "Сохранить",
    "saved": "Сохранено",
    "save as": "Сохранить как",
    "skip": "Пропустить",
    "skipped": "Пропущено",
    "retry": "Повторить",
    "ignore": "Игнорировать",
    "ignored": "Игнорировано",
    "got it": "Понятно",
    "i understand": "Понятно",
    "learn more": "Подробнее",
    "read more": "Читать далее",
    "details": "Подробнее",
    "more info": "Дополнительная информация",
    "submit": "Отправить",
    "submitted": "Отправлено",
    "continue": "Продолжить",
    "done": "Готово",
    "finish": "Завершить",
    "finished": "Завершено",
    "exit": "Выйти",
    "quit": "Выйти",
    "clear": "Очистить",
    "reset": "Сбросить",
    "refresh": "Обновить",
    "reload": "Перезагрузить",
    "abort": "Прервать",
    "aborted": "Прервано",
    "undo": "Отменить",
    "redo": "Повторить",
    "copy": "Копировать",
    "copied": "Скопировано",
    "paste": "Вставить",
    "cut": "Вырезать",
    "select all": "Выделить всё",
    "settings": "Настройки",
    "preferences": "Параметры",
    "help": "Справка",
    "about": "О программе",
    "agree": "Согласен",
    "accept": "Принять",
    "decline": "Отклонить",
    "reject": "Отклонить",
    "view": "Просмотр",
    "edit": "Редактировать",
    "delete": "Удалить",
    "remove": "Удалить",
    "enable": "Включить",
    "disable": "Отключить",
    "turn down": "Отключение / Вывод из эксплуатации",
    "turning down": "Отключение",
    "deprecated": "Устарело (deprecated)",
    "deprecation": "Устаревание / Вывод из эксплуатации (deprecation)",
    "sunset": "Прекращение поддержки (sunset)",
    "sunsetting": "Прекращение поддержки"
};

// Exact term dictionary (lowercase English -> Russian IT explanation/translation)
var dictEnToRu = {
    // Core Concepts & Idioms
    "boilerplate": "шаблонный код (бойлерплейт)",
    "boilerplate code": "шаблонный код (бойлерплейт)",
    "deprecated": "устарело / не рекомендуется (депрекейтед)",
    "deprecate": "объявить устаревшим (deprecate)",
    "deprecation": "устаревание / вывод из эксплуатации (deprecation)",
    "out of the box": "из коробки (работает без доп. настройки)",
    "under the hood": "под капотом (внутреннее устройство)",
    "side effect": "побочный эффект (сайд-эффект)",
    "side effects": "побочные эффекты (сайд-эффекты)",
    "thread pool": "пул потоков",
    "thread-safe": "потокобезопасный",
    "race condition": "состояние гонки (race condition)",
    "deadlock": "взаимная блокировка (дедлок)",
    "livelock": "активная взаимная блокировка (лайвлок)",
    "garbage collector": "сборщик мусора (GC)",
    "garbage collection": "сборка мусора (GC)",
    "memory leak": "утечка памяти",
    "stack overflow": "переполнение стека",
    "stack trace": "стек вызовов (стектрейс)",
    "null pointer": "нулевой указатель (null / nullptr)",
    "null pointer exception": "исключение нулевого указателя (NPE)",
    "null reference": "нулевая ссылка (NullReference)",
    "segfault": "ошибка сегментации (сегфолт)",
    "segmentation fault": "ошибка сегментации (сегфолт)",
    "buffer overflow": "переполнение буфера",
    "dangling pointer": "висячий указатель",
    "wildcard": "маска подстановки (вайлдкард)",
    "scaffolding": "скаффолдинг (генерация каркаса)",
    "parsing": "парсинг (синтаксический анализ)",
    "parse": "распарсить",
    "pipe": "пайп (канал передачи данных)",
    "concurrency": "конкурентность / многозадачность",
    "multithreading": "многопоточность",
    "thread": "поток выполнения",
    "threads": "потоки выполнения",
    "mutex": "мьютекс (взаимное исключение)",
    "semaphore": "семафор",
    "atomic": "атомарный",
    "marshalling": "маршалинг (упаковка структур в байты)",
    "serialization": "сериализация",
    "deserialization": "десериализация",
    "wrapper": "обёртка (враппер)",
    "polyfill": "полифил (модуль совместимости)",
    "transpiler": "транспилер",
    "transpile": "транспилировать",
    "crutch": "костыль (временный костыль в коде)",
    "hack": "хак / обходной путь",
    "workaround": "обходное решение (воркараунд)",
    "escape": "экранировать (спецсимвол)",
    "escaping": "экранирование",
    "render": "отрисовать / зарендерить",
    "rendering": "рендеринг / отрисовка",
    "hook": "хук (перехватчик / функция React)",
    "hooks": "хуки",
    "duck typing": "утиная типизация",
    "rubber ducking": "метод утёнка",
    "framework": "фреймворк",
    "library": "библиотека (либа)",
    "sdk": "SDK (инструменты разработки)",
    "cli": "CLI (консольный интерфейс)",
    "gui": "GUI (графический интерфейс)",
    "tui": "TUI (терминальный интерфейс)",
    "lookup": "поиск в словаре/таблице (лукап)",
    "handshake": "рукопожатие / согласование связи (handshake)",
    "query": "запрос",
    "mutation": "мутация (изменение состояния)",
    "singleton": "одиночка (паттерн синглтон)",
    "polymorphism": "полиморфизм",
    "inheritance": "наследование",
    "encapsulation": "инкапсуляция",
    "abstraction": "абстракция",

    // Lifecycle, Cloud & Deprecation
    "turn down": "вывод из эксплуатации / отключение",
    "turning down": "вывод из эксплуатации / отключение",
    "turned down": "отключен / выведен из эксплуатации",
    "sunset": "прекращение поддержки (sunset)",
    "sunsetting": "прекращение поддержки (sunsetting)",
    "breaking change": "ломающее изменение (breaking change)",
    "breaking changes": "ломающие изменения (breaking changes)",
    "teardown": "завершение / демонтаж окружения",
    "spin up": "запустить / развернуть экземпляр",
    "canary": "канареечный релиз (canary)",
    "rolling update": "поэтапное обновление (rolling update)",
    "blue-green deployment": "сине-зелёное развертывание",
    "cold start": "холодный старт",
    "warm up": "прогрев инстанса",
    "ingress": "входящий трафик (ingress)",
    "egress": "исходящий трафик (egress)",
    "reverse proxy": "обратный прокси (reverse proxy)",
    "load balancer": "балансировщик нагрузки",

    // AI & LLMs
    "prompt": "промпт (запрос к модели)",
    "prompts": "промпты (запросы к модели)",
    "prompt engineering": "промпт-инжиниринг",
    "hallucination": "галлюцинация модели",
    "context window": "контекстное окно",
    "fine-tuning": "дообучение модели (fine-tuning)",
    "inference": "инференс (вывод модели)",
    "embedding": "эмбеддинг (векторное представление)",
    "embeddings": "эмбеддинги (векторные представления)",
    "token": "токен",
    "tokens": "токены",
    "tokenizer": "токенизатор",

    // Git & Workflows
    "pull request": "Pull Request (PR — запрос на слияние)",
    "pr": "Pull Request (PR — запрос на слияние)",
    "merge request": "Merge Request (MR — запрос на слияние)",
    "mr": "Merge Request (MR — запрос на слияние)",
    "commit": "коммит (зафиксировать изменения)",
    "branch": "ветка (бранч)",
    "merge": "слияние (мердж веток)",
    "rebase": "перебазирование (ребейз)",
    "cherry-pick": "черри-пик (выборочный перенос коммита)",
    "stash": "стэш (временный тайник изменений)",
    "fork": "форк (ответвление репозитория)",
    "upstream": "апстрим (вышестоящий репозиторий)",
    "origin": "ориджин (удаленный основной репозиторий)",
    "head": "HEAD (указатель на текущий коммит/ветку)",
    "diff": "дифф (разница между версиями кода)",
    "squash": "сквош (объединение коммитов)",

    // Chat & Slang
    "lgtm": "LGTM (Looks Good To Me — одобряю, выглядит отлично)",
    "wip": "WIP (Work In Progress — в процессе разработки)",
    "afaik": "AFAIK (насколько мне известно)",
    "iirc": "IIRC (если правильно помню)",
    "tbd": "TBD (будет определено позже)",
    "imo": "IMO (по моему мнению)",
    "imho": "IMHO (по моему скромному мнению)",
    "rfc": "RFC (Request For Comments — запрос на обсуждение)",
    "poc": "PoC (Proof of Concept — доказательство концепции)",
    "mvp": "MVP (Minimum Viable Product — минимальный рабочий продукт)",
    "fyi": "FYI (к вашему сведению)",

    // Architecture & Backend
    "ci/cd": "CI/CD (непрерывная интеграция и доставка)",
    "pipeline": "пайплайн / конвейер сборки",
    "middleware": "мидлвар / промежуточный слой обработки",
    "endpoint": "эндпоинт (конечная точка API)",
    "payload": "полезная нагрузка (тело запроса/данные)",
    "handler": "обработчик",
    "event handler": "обработчик событий",
    "mock": "мок / тестовая заглушка (имитация)",
    "mocks": "моки / тестовые заглушки",
    "stub": "стаб / заглушка",
    "scope": "область видимости (скоуп)",
    "closure": "замыкание",
    "callback": "колбэк (функция обратного вызова)",
    "runtime": "время выполнения (рантайм)",
    "state machine": "конечный автомат (стейт-машина)",
    "tree shaking": "тришейкинг (удаление неиспользуемого кода)",
    "bundle": "бандл (собранный пакет кода)",
    "build": "сборка (билд)",
    "deploy": "развертывание (деплой)",
    "deployment": "развертывание (деплоймент)",
    "hotfix": "срочный патч / хотфикс",
    "patch": "патч (исправление/заплатка)",
    "daemon": "демон (фоновый сервис)",
    "sandbox": "песочница (изолированное окружение)",
    "linter": "линтер (статический анализатор кода)",
    "formatter": "форматтер кода",
    "staging": "стейджинг (предрелизный сервер)",
    "production": "прод / продакшен (боевой рабочий сервер)",
    "prod": "прод (боевое окружение)",
    "issue": "задача / проблема (ишью)",
    "issues": "задачи / проблемы (ишью)",
    "dependency": "зависимость",
    "dependencies": "зависимости",
    "dependency injection": "внедрение зависимостей (DI)",
    "inversion of control": "инверсия управления (IoC)",
    "refactoring": "рефакторинг (улучшение структуры кода)",
    "overhead": "накладные расходы (избыточная нагрузка)",
    "throughput": "пропускная способность",
    "latency": "задержка (латентность / пинг)",
    "rate limit": "ограничение частоты запросов",
    "throttling": "троттлинг (ограничение частоты)",
    "debouncing": "дебаунс (устранение дребезга / задержка вызова)",
    "lazy loading": "ленивая загрузка (по требованию)",
    "eager loading": "жадная загрузка (немедленная)",
    "immutable": "неизменяемый (иммутабельный)",
    "mutable": "изменяемый (мутабельный)",
    "idempotent": "идемпотентный (повторный вызов дает тот же результат)",
    "spaghetti code": "спагетти-код (запутанный код)",
    "technical debt": "технический долг (техдолг)",
    "tech debt": "техдолг",
    "hardcode": "хардкод (жестко прописанные данные)",
    "hardcoded": "захардкожено (прописано жестко в коде)",
    "sanity check": "базовая проверка здравого смысла",
    "smoke test": "дымовой тест (первичная экспресс-проверка)",
    "unit test": "юнит-тест (модульный тест)",
    "edge case": "граничный случай",
    "corner case": "краевой случай (редкая комбинация условий)"
};

// Reverse dictionary (Russian IT terms -> English equivalents)
var dictRuToEn = {
    "пул потоков": "thread pool",
    "потокобезопасный": "thread-safe",
    "состояние гонки": "race condition",
    "дедлок": "deadlock",
    "взаимная блокировка": "deadlock",
    "сборщик мусора": "garbage collector",
    "сборка мусора": "garbage collection",
    "утечка памяти": "memory leak",
    "стектрейс": "stack trace",
    "стек вызовов": "stack trace",
    "переполнение стека": "stack overflow",
    "переполнение буфера": "buffer overflow",
    "сегфолт": "segfault / segmentation fault",
    "ошибка сегментации": "segmentation fault",
    "шаблонный код": "boilerplate",
    "бойлерплейт": "boilerplate",
    "из коробки": "out of the box",
    "под капотом": "under the hood",
    "сайд-эффект": "side effect",
    "побочный эффект": "side effect",
    "мидлвар": "middleware",
    "эндпоинт": "endpoint",
    "обработчик": "handler",
    "заглушка": "stub / mock",
    "мок": "mock",
    "рантайм": "runtime",
    "время выполнения": "runtime",
    "скоуп": "scope",
    "область видимости": "scope",
    "замыкание": "closure",
    "колбэк": "callback",
    "ветка": "branch",
    "коммит": "commit",
    "слияние": "merge",
    "ребейз": "rebase",
    "деплой": "deploy",
    "развертывание": "deployment",
    "билд": "build",
    "сборка": "build",
    "хотфикс": "hotfix",
    "патч": "patch",
    "ишью": "issue",
    "техдолг": "tech debt / technical debt",
    "хардкод": "hardcode",
    "костыль": "crutch / hack / workaround",
    "экранирование": "escaping",
    "экранировать": "escape",
    "рендерить": "render",
    "отрисовка": "rendering",
    "хук": "hook",
    "хуки": "hooks",
    "фреймворк": "framework",
    "либа": "library",
    "рефакторинг": "refactoring",
    "накладные расходы": "overhead",
    "пайплайн": "pipeline",
    "устарело": "deprecated",
    "вывод из эксплуатации": "turn down / sunset",
    "промпт": "prompt",
    "токены": "tokens",
    "внедрение зависимостей": "dependency injection",

    // C# & Programming Concepts & Variable Naming
    "ссылочные и значимые типы": "reference and value types",
    "ссылочные и значимые": "reference and value",
    "ссылочный тип": "reference type",
    "ссылочные типы": "reference types",
    "значимый тип": "value type",
    "значимые типы": "value types",
    "типы значений": "value types",
    "куча": "heap",
    "стек": "stack",
    "куча и стек": "heap and stack",
    "стек и куча": "stack and heap",
    "перегрузка методов": "method overload",
    "перегрузка метода": "method overload",
    "перегрузка функций": "function overload",
    "перегрузка операторов": "operator overload",
    "пространство имен": "namespace",
    "инкапсуляция": "encapsulation",
    "наследование": "inheritance",
    "полиморфизм": "polymorphism",
    "абстракция": "abstraction",
    "интерфейс": "interface",
    "интерфейсы": "interfaces",
    "перечисление": "enum",
    "структура": "struct",
    "структуры": "structs",
    "класс": "class",
    "классы": "classes",
    "свойство": "property",
    "свойства": "properties",
    "поле": "field",
    "поля": "fields",
    "конструктор": "constructor",
    "деструктор": "destructor",
    "статический метод": "static method",
    "статические методы": "static methods",
    "модификатор доступа": "access modifier",
    "модификаторы доступа": "access modifiers",
    "двумерный массив": "two dimensional array",
    "двумерные массивы": "two dimensional arrays",
    "зубчатый массив": "jagged array",
    "зубчатые массивы": "jagged arrays",
    "ступенчатый массив": "jagged array",
    "индексы и диапазоны": "indices and ranges",
    "тернарный оператор": "ternary operator",
    "условный оператор": "conditional operator",
    "цикл": "loop",
    "циклы": "loops",
    "вложенный цикл": "nested loop",
    "вложенные циклы": "nested loops",
    "точка входа": "entry point",
    "делегат": "delegate",
    "делегаты": "delegates",
    "событие": "event",
    "события": "events",
    "исключение": "exception",
    "исключения": "exceptions",
    "обработка ошибок": "error handling"
};

// Universal non-word boundaries for Cyrillic and Latin
var bS = "(^|[^а-яёА-ЯЁa-zA-Z0-9_])";
var bE = "($|[^а-яёА-ЯЁa-zA-Z0-9_])";

// Helper to sanitize single line lookup key
function cleanKey(str) {
    if (!str) return "";
    return str.trim().toLowerCase().replace(/^[^\w\sа-яёА-ЯЁ]+|[^\w\sа-яёА-ЯЁ]+$/g, "");
}

// Smart unwrap: merges soft line-breaks from OCR / terminal wraps into coherent sentences
function smartUnwrap(text) {
    if (!text) return "";
    var rawLines = text.split(/\r?\n/);
    var out = [];

    var connectorWords = /^(be|to|and|or|the|a|an|in|on|at|for|with|is|are|was|were|will|would|can|could|should|that|this|these|those|we|you|they|he|she|it|my|our|your|their|his|her|of|by|from|as|into|about|after|before|between|under|over|through|и|или|в|на|с|со|к|ко|от|до|по|за|из|о|об|обо|при|для|что|чтобы|как|но|а|не|же|да)$/i;

    for (var i = 0; i < rawLines.length; i++) {
        var s = rawLines[i].trim();
        if (!s) {
            out.push("");
            continue;
        }

        if (out.length === 0) {
            out.push(s);
            continue;
        }

        var prev = out[out.length - 1];
        if (!prev) {
            out.push(s);
            continue;
        }

        var prevKey = cleanKey(prev);
        var currKey = cleanKey(s);

        // Keep distinct UI actions on separate lines
        if (uiActionsEnToRu.hasOwnProperty(prevKey) || uiActionsEnToRu.hasOwnProperty(currKey)) {
            out.push(s);
            continue;
        }

        // Check if prev line ends with terminal punctuation
        var prevEndsPunct = /[.!?:\u2014]\s*$/.test(prev);
        // Check if current line starts with lowercase
        var currStartsLower = /^[a-zа-яё]/.test(s);
        // Check if prev line ends with connector word
        var lastWordMatch = prev.match(/([a-zA-Zа-яёА-ЯЁ]+)\s*$/);
        var prevEndsConnector = lastWordMatch ? connectorWords.test(lastWordMatch[1]) : false;

        if ((!prevEndsPunct && currStartsLower) || prevEndsConnector) {
            out[out.length - 1] = prev + " " + s;
        } else {
            out.push(s);
        }
    }
    return out.join("\n");
}

// Sentence and context fixes
function applySentenceFixes(text) {
    var res = text;

    // 1. Turning down / will be turning down -> мы отключим / отключим
    res = res.replace(new RegExp(bS + "мы\\s+будем\\s+отключение" + bE, "gi"), "$1мы отключим$3");
    res = res.replace(new RegExp(bS + "будем\\s+отключение" + bE, "gi"), "$1отключим$2");
    res = res.replace(new RegExp(bS + "будем\\s+удаление" + bE, "gi"), "$1будем удалять$2");
    res = res.replace(new RegExp(bS + "будем\\s+закрытие" + bE, "gi"), "$1будем закрывать$2");
    res = res.replace(new RegExp(bS + "будем\\s+прекращение" + bE, "gi"), "$1прекратим$2");

    // 2. Multiline/isolated "Увольнять" -> "Закрыть"
    res = res.replace(/(^|\n)\s*(Увольнять|увольнять|Уволить|уволить)\s*($|\n)/g, "$1Закрыть$3");
    res = res.replace(new RegExp(bS + "(кнопка|нажмите|действие)\\s+увольнять" + bE, "gi"), "$1$2 закрыть$4");

    // 3. Model name reordering
    res = res.replace(new RegExp(bS + "Flash\\s+Gemini" + bE, "gi"), "$1Gemini Flash$2");
    res = res.replace(new RegExp(bS + "устаревани[ея]\\s+Flash\\s+Gemini" + bE, "gi"), "$1устаревание Gemini Flash$2");

    // 4. Deprecated fixes
    res = res.replace(new RegExp(bS + "осуждаем(ый|ая|ое|ые|ого|ому|ым|ых|ую|ом)" + bE, "gi"), "$1устаревш$2 (deprecated)$3");
    res = res.replace(new RegExp(bS + "осуждается" + bE, "gi"), "$1устарело / не рекомендуется (deprecated)$2");

    // 5. Thread pool
    res = res.replace(new RegExp(bS + "бассейн(а|у|ом|е)?\\s+(потоков|нитей)" + bE, "gi"), "$1пул$2 потоков$4");
    res = res.replace(new RegExp(bS + "пул(а|у|ом|е)?\\s+нитей" + bE, "gi"), "$1пул$2 потоков$3");
    res = res.replace(new RegExp(bS + "(нить|нити|нитей|нитями|нитях)\\s+выполнения" + bE, "gi"), "$1поток$2 выполнения$3");
    res = res.replace(new RegExp(bS + "(фонов(ая|ую|ой|ые|ых))\\s+нить" + bE, "gi"), "$1фоновый поток$3");

    // 6. Race condition & deadlock
    res = res.replace(new RegExp(bS + "состояни(е|я|ю|ем|и)\\s+расы" + bE, "gi"), "$1состояни$2 гонки (race condition)$3");
    res = res.replace(new RegExp(bS + "услови(е|я|ю|ем|и)\\s+гонки" + bE, "gi"), "$1состояни$2 гонки$3");

    // 7. Boilerplate
    res = res.replace(new RegExp(bS + "пластин(а|ы|е|у|ой)?\\s+котла" + bE, "gi"), "$1шаблонный код (boilerplate)$3");
    res = res.replace(new RegExp(bS + "код\\s+котла" + bE, "gi"), "$1шаблонный код (boilerplate)$2");

    // 8. Breakpoint
    res = res.replace(new RegExp(bS + "точк(а|и|е|у|ой|ами|ах)\\s+разрыва" + bE, "gi"), "$1точк$2 останова (breakpoint)$3");

    // 9. Handlers & Hooks
    res = res.replace(new RegExp(bS + "ручк(а|и|е|у|ой)\\s+(запрос(а|ов)|событи(й|я))" + bE, "gi"), "$1обработчик $3$4");
    res = res.replace(new RegExp(bS + "крюч(ок|ка|ку|ком|ке|ки|ков)\\s+React" + bE, "gi"), "$1хук$2 React$3");
    res = res.replace(new RegExp(bS + "Git\\s+крюч(ок|ка|ку|ком|ке|ки|ков)" + bE, "gi"), "$1Git-хук$2$3");

    // 10. Git PR / MR
    res = res.replace(new RegExp(bS + "запрос(а|у|ом|е)?\\s+на\\s+вытягивание" + bE, "gi"), "$1Pull Request (PR)$3");
    res = res.replace(new RegExp(bS + "запрос(а|у|ом|е)?\\s+на\\s+слияние" + bE, "gi"), "$1Merge Request (MR)$3");
    res = res.replace(new RegExp(bS + "вишнев(ый|ого|ому|ым)\\s+сбор(а|у|ом|е)?" + bE, "gi"), "$1выборочный перенос (cherry-pick)$4");
    res = res.replace(new RegExp(bS + "морщить\\s+коммит(ы|ов)?" + bE, "gi"), "$1объединить (squash) коммит$2$3");

    // 11. GC, Overhead, Payload
    res = res.replace(new RegExp(bS + "коллектор(а|у|ом|е)?\\s+мусора" + bE, "gi"), "$1сборщик$2 мусора (GC)$3");
    res = res.replace(new RegExp(bS + "накладные\\s+расходы" + bE, "gi"), "$1накладные расходы (overhead)$2");
    res = res.replace(new RegExp(bS + "полезн(ая|ой|ую|ости)\\s+нагрузк(а|и|у|ой)" + bE, "gi"), "$1полезная нагрузка (payload)$3");

    // 12. Exceptions
    res = res.replace(new RegExp(bS + "бросить\\s+исключение" + bE, "gi"), "$1выбросить исключение (throw exception)$2");
    res = res.replace(new RegExp(bS + "поймать\\s+исключение" + bE, "gi"), "$1перехватить исключение (catch exception)$2");

    // 13. Networking, Cookies & Middleware
    res = res.replace(new RegExp(bS + "гнезд(о|а|у|ом|е)\\s+(сети|сетевое|сокета)" + bE, "gi"), "$1сетевой сокет$4");
    res = res.replace(new RegExp(bS + "печеньк(и|ек|ами|ах)?\\s+браузера" + bE, "gi"), "$1cookies (куки)$3");
    res = res.replace(new RegExp(bS + "промежуточн(ое|ого|ому|ым)\\s+программн(ое|ого|ому|ым)\\s+обеспечени(е|я|ю|ем)" + bE, "gi"), "$1промежуточный слой (middleware)$4");

    // 14. Tree shaking & Mock
    res = res.replace(new RegExp(bS + "дерев(о|а|у|ом|е)\\s+встряхивания" + bE, "gi"), "$1tree shaking (удаление лишнего кода)$3");

    return res;
}

// Main enhance function
function enhance(sourceText, translatedText, sourceLang, targetLang) {
    if (!sourceText || !translatedText) return translatedText;

    var sTrim = sourceText.trim().toLowerCase();

    // 1. Direct Term Match (EN -> RU)
    if (targetLang === "ru") {
        if (dictEnToRu.hasOwnProperty(sTrim)) {
            return dictEnToRu[sTrim];
        }
        if (uiActionsEnToRu.hasOwnProperty(sTrim)) {
            return uiActionsEnToRu[sTrim];
        }

        // Line-by-line processing
        var srcLines = sourceText.split(/\r?\n/);
        var trnLines = translatedText.split(/\r?\n/);

        if (srcLines.length === trnLines.length && srcLines.length > 1) {
            for (var l = 0; l < srcLines.length; l++) {
                var lineKey = cleanKey(srcLines[l]);
                if (uiActionsEnToRu.hasOwnProperty(lineKey)) {
                    trnLines[l] = uiActionsEnToRu[lineKey];
                } else if (dictEnToRu.hasOwnProperty(lineKey)) {
                    trnLines[l] = dictEnToRu[lineKey];
                }
            }
            translatedText = trnLines.join("\n");
        } else {
            // Check individual lines in translatedText for lone button terms
            for (var k = 0; k < trnLines.length; k++) {
                var tLineTrim = trnLines[k].trim();
                if (/^(увольнять|уволить)$/i.test(tLineTrim)) {
                    trnLines[k] = "Закрыть";
                }
            }
            translatedText = trnLines.join("\n");
        }

        // Apply sentence-level contextual improvements
        return applySentenceFixes(translatedText);
    }

    // 2. Direct Term Match (RU -> EN)
    if (targetLang === "en") {
        if (dictRuToEn.hasOwnProperty(sTrim)) {
            return dictRuToEn[sTrim];
        }
    }

    return translatedText;
}

// Variable Name / Code Identifier Formatter
function cleanIdentifierWords(text) {
    if (!text) return [];
    var primary = text.split(/[\/\\]/)[0].trim();
    primary = primary.replace(/\([^)]*\)/g, "");
    primary = primary.replace(/['"’`]/g, "");
    primary = primary.replace(/[^a-zA-Z0-9]+/g, " ").trim();
    if (!primary) return [];
    return primary.split(/\s+/).filter(function(w) { return w.length > 0; });
}

function toPascalCase(text) {
    var words = cleanIdentifierWords(text);
    if (words.length === 0) return "";
    return words.map(function(w) {
        return w.charAt(0).toUpperCase() + w.slice(1).toLowerCase();
    }).join("");
}

function toCamelCase(text) {
    var words = cleanIdentifierWords(text);
    if (words.length === 0) return "";
    var first = words[0].toLowerCase();
    var rest = words.slice(1).map(function(w) {
        return w.charAt(0).toUpperCase() + w.slice(1).toLowerCase();
    }).join("");
    return first + rest;
}

function toSnakeCase(text) {
    var words = cleanIdentifierWords(text);
    if (words.length === 0) return "";
    return words.map(function(w) { return w.toLowerCase(); }).join("_");
}

function toScreamingSnakeCase(text) {
    var words = cleanIdentifierWords(text);
    if (words.length === 0) return "";
    return words.map(function(w) { return w.toUpperCase(); }).join("_");
}

function toKebabCase(text) {
    var words = cleanIdentifierWords(text);
    if (words.length === 0) return "";
    return words.map(function(w) { return w.toLowerCase(); }).join("-");
}

function getCodeIdentifiers(text) {
    if (!text || text.trim().length === 0) {
        return {
            pascal: "",
            camel: "",
            snake: "",
            screaming: "",
            kebab: ""
        };
    }
    return {
        pascal: toPascalCase(text),
        camel: toCamelCase(text),
        snake: toSnakeCase(text),
        screaming: toScreamingSnakeCase(text),
        kebab: toKebabCase(text)
    };
}

