# 🤖 StudySpace AI Integration & Setup Guide (`AI.md`)

This guide outlines the exact, production-tested architecture and configuration used in **StudySpace** to deliver reliable, high-speed, and truncation-free AI features using Google's Gemini models.

---

## 📑 Table of Contents
1. [Core Architecture & Why Previous Setups Fail](#1-core-architecture--why-previous-setups-fail)
2. [API Configuration & Endpoint Details](#2-api-configuration--endpoint-details)
3. [Model Cascade Strategy (Zero-Downtime Fallback)](#3-model-cascade-strategy-zero-downtime-fallback)
4. [Fixing Response Truncation (Long Answers Cutting Mid-Way)](#4-fixing-response-truncation-long-answers-cutting-mid-way)
5. [LaTeX & Mathematical Formula Sanitizer](#5-latex--mathematical-formula-sanitizer)
6. [Structured JSON AI Mode (For Search Engines & Cards)](#6-structured-json-ai-mode-for-search-engines--cards)
7. [Full Copy-Paste Implementation: JavaScript / TypeScript (Next.js, Vite, React)](#7-full-copy-paste-implementation-javascript--typescript-nextjs-vite-react)
8. [Full Copy-Paste Implementation: Dart / Flutter](#8-full-copy-paste-implementation-dart--flutter)
9. [Full Copy-Paste Implementation: Python (FastAPI / Flask)](#9-full-copy-paste-implementation-python-fastapi--flask)
10. [Environment Variables & Deployment Checklist](#10-environment-variables--deployment-checklist)

---

## 1. Core Architecture & Why Previous Setups Fail

Most web & mobile AI implementations suffer from 5 common pitfalls:
1. **Single Model Hardcoding**: When Google deprecates a model alias (e.g. `gemini-1.5-flash-latest`), single-model apps throw `404 Not Found` or `400 Bad Request`.
2. **Small Output Token Limit**: Default token limit (`maxOutputTokens: 2048`) abruptly cuts off long essays or code solutions mid-sentence.
3. **Multi-Part Fragmentation**: Gemini responses often return text across multiple items in the `parts` array. Reading only `parts[0].text` drops subsequent blocks of code and conclusions.
4. **LaTeX/Math Delimiter Clutter**: Raw `\frac{...}{...}` or `\text{...}` confuses markdown parsers unless sanitized into student-readable symbols.
5. **Missing CORS / Release Permissions**: Missing `android.permission.INTERNET` on mobile or incorrect header syntax on the web.

---

## 2. API Configuration & Endpoint Details

- **Base URL**: `https://generativelanguage.googleapis.com/v1beta/models/{MODEL_NAME}:generateContent?key={API_KEY}`
- **HTTP Method**: `POST`
- **Headers**:
  ```json
  {
    "Content-Type": "application/json",
    "x-goog-api-key": "YOUR_GEMINI_API_KEY"
  }
  ```

---

## 3. Model Cascade Strategy (Zero-Downtime Fallback)

To guarantee that your app never goes down if a specific model version is overloaded or deprecated, loop through a cascade array:

```dart
final modelsToTry = [
  'gemini-3.6-flash',
  'gemini-3.7-flash',
  'gemini-3.5-flash',
  'gemini-3.1-flash-lite',
  'gemini-flash-latest',
];
```

If the first model returns an error status (`404`, `429`, `500`), the engine immediately retries with the next model in milliseconds.

---

## 4. Fixing Response Truncation (Long Answers Cutting Mid-Way)

### Rule A: Increase `maxOutputTokens` to 16,384
```json
{
  "generationConfig": {
    "temperature": 0.7,
    "maxOutputTokens": 16384
  }
}
```

### Rule B: Concatenate all `parts`
Never read only `candidates[0].content.parts[0].text`. Always join all parts:
```typescript
const fullText = candidate.content.parts.map(p => p.text || '').join('');
```

---

## 5. LaTeX & Mathematical Formula Sanitizer

To prevent raw unrendered LaTeX tags from confusing students, sanitize before rendering:

```typescript
function cleanMathFormulas(input: string): string {
  if (!input) return input;
  let text = input;

  // 1. Remove \text{...}, \mathrm{...}, \mathbf{...}
  text = text.replace(/\\(?:text|mathrm|mathbf|mathit|textsf)\{([^}]+)\}/g, '$1');

  // 2. Replace \frac{a}{b} -> (a / b)
  text = text.replace(/\\frac\{([^}]+)\}\{([^}]+)\}/g, '($1 / $2)');

  // 3. Replace common math symbols with clean Unicode
  const mathSymbols: Record<string, string> = {
    '\\cdot': '·',
    '\\times': '×',
    '\\pm': '±',
    '\\approx': '≈',
    '\\neq': '≠',
    '\\le': '≤',
    '\\leq': '≤',
    '\\ge': '≥',
    '\\geq': '≥',
    '\\infty': '∞',
    '\\Delta': 'Δ',
    '\\theta': 'θ',
    '\\lambda': 'λ',
    '\\mu': 'μ',
    '\\sigma': 'σ',
    '\\pi': 'π',
    '\\alpha': 'α',
    '\\beta': 'β',
    '\\omega': 'ω'
  };

  for (const [tex, uni] of Object.entries(mathSymbols)) {
    text = text.split(tex).join(uni);
  }

  // 4. Replace \sqrt{x} -> √(x)
  text = text.replace(/\\sqrt\{([^}]+)\}/g, '√($1)');

  // 5. Clean up subscripts and exponents
  text = text.replace(/_\{([^}]+)\}/g, '_$1');
  text = text.replace(/\^\{([^}]+)\}/g, '^$1');

  // 6. Remove remaining raw $ or $$ delimiters
  text = text.replace(/\$\$/g, '').replace(/\$/g, '');

  return text;
}
```

---

## 6. Structured JSON AI Mode (For Search Engines & Cards)

To receive 100% valid JSON without markdown wrapping:
```json
{
  "generationConfig": {
    "temperature": 0.2,
    "responseMimeType": "application/json"
  }
}
```

---

## 7. Full Copy-Paste Implementation: JavaScript / TypeScript (Next.js, Vite, React)

Save this as `geminiService.ts`:

```typescript
export interface ChatMessage {
  role: 'user' | 'model';
  content: string;
}

const MODELS_CASCADE = [
  'gemini-3.6-flash',
  'gemini-3.7-flash',
  'gemini-3.5-flash',
  'gemini-3.1-flash-lite',
  'gemini-flash-latest'
];

export async function askGemini(
  history: ChatMessage[],
  userPrompt: string,
  apiKey: string,
  systemInstruction: string = 'You are a helpful, expert AI assistant.'
): Promise<string> {
  const contents = [
    ...history.map(msg => ({
      role: msg.role,
      parts: [{ text: msg.content }]
    })),
    {
      role: 'user',
      parts: [{ text: userPrompt }]
    }
  ];

  for (const model of MODELS_CASCADE) {
    try {
      const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;
      const res = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey
        },
        body: JSON.stringify({
          system_instruction: {
            parts: [{ text: systemInstruction }]
          },
          contents,
          generationConfig: {
            temperature: 0.7,
            maxOutputTokens: 16384
          }
        })
      });

      if (res.ok) {
        const data = await res.json();
        const candidate = data.candidates?.[0];
        const parts = candidate?.content?.parts;

        if (Array.isArray(parts) && parts.length > 0) {
          const fullText = parts.map(p => p.text || '').join('');
          if (fullText.trim().length > 0) {
            return fullText;
          }
        }
      }
    } catch (err) {
      console.warn(`[Gemini] Model ${model} failed, trying next...`, err);
    }
  }

  throw new Error('All Gemini model endpoints failed. Please check your API key.');
}
```

---

## 8. Full Copy-Paste Implementation: Dart / Flutter

Save this as `ai_service.dart`:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  final String apiKey;
  AiService({required this.apiKey});

  static const List<String> models = [
    'gemini-3.6-flash',
    'gemini-3.7-flash',
    'gemini-3.5-flash',
    'gemini-3.1-flash-lite',
    'gemini-flash-latest',
  ];

  Future<String> askGemini({
    required List<Map<String, String>> history,
    required String prompt,
    String systemPrompt = 'You are a helpful educational tutor.',
  }) async {
    final contents = <Map<String, dynamic>>[];

    for (final msg in history) {
      contents.add({
        'role': msg['role'] == 'user' ? 'user' : 'model',
        'parts': [{'text': msg['content'] ?? ''}],
      });
    }

    contents.add({
      'role': 'user',
      'parts': [{'text': prompt}],
    });

    for (final model in models) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
        );

        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          },
          body: jsonEncode({
            'system_instruction': {
              'parts': [{'text': systemPrompt}],
            },
            'contents': contents,
            'generationConfig': {
              'temperature': 0.7,
              'maxOutputTokens': 16384, // Prevents truncation
            },
          }),
        ).timeout(const Duration(seconds: 35));

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final candidate = json['candidates']?[0];
          final parts = candidate?['content']?['parts'] as List?;

          if (parts != null && parts.isNotEmpty) {
            final fullText = parts.map((p) => p['text']?.toString() ?? '').join('');
            if (fullText.trim().isNotEmpty) {
              return fullText;
            }
          }
        }
      } catch (e) {
        // Fallback to next model in cascade
      }
    }

    throw Exception('Failed to generate AI response from all available models.');
  }
}
```

---

## 9. Full Copy-Paste Implementation: Python (FastAPI / Flask)

```python
import requests
from typing import List, Dict

MODELS = [
    "gemini-3.6-flash",
    "gemini-3.7-flash",
    "gemini-3.5-flash",
    "gemini-3.1-flash-lite",
    "gemini-flash-latest",
]

def generate_ai_response(
    messages: List[Dict[str, str]], 
    api_key: str, 
    system_prompt: str = "You are an expert AI tutor."
) -> str:
    contents = [
        {"role": m["role"], "parts": [{"text": m["content"]}]}
        for m in messages
    ]

    for model in MODELS:
        try:
            url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
            headers = {
                "Content-Type": "application/json",
                "x-goog-api-key": api_key,
            }
            payload = {
                "system_instruction": {"parts": [{"text": system_prompt}]},
                "contents": contents,
                "generationConfig": {
                    "temperature": 0.7,
                    "maxOutputTokens": 16384,
                },
            }

            resp = requests.post(url, headers=headers, json=payload, timeout=30)
            if resp.status_code == 200:
                data = resp.json()
                parts = data.get("candidates", [{}])[0].get("content", {}).get("parts", [])
                full_text = "".join([p.get("text", "") for p in parts])
                if full_text.strip():
                    return full_text
        except Exception:
            continue

    raise RuntimeError("Failed to generate response from Gemini.")
```

---

## 10. Environment Variables & Deployment Checklist

When deploying to Vercel, Netlify, or Android:

1. **Set Environment Variables**:
   - `GEMINI_API_KEY`: Obtain a free key from [Google AI Studio](https://aistudio.google.com/app/apikey).
2. **Android Release Permission**:
   - Verify `android/app/src/main/AndroidManifest.xml` includes `<uses-permission android:name="android.permission.INTERNET"/>`.
3. **Avoid Client-Side Hardcoding**:
   - On web projects, route through an API route (e.g. `/api/chat`) to protect your API key from public browser inspection.
