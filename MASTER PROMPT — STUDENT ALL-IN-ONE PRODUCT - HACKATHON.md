# MASTER PROMPT — STUDENT ALL-IN-ONE PRODUCT / HACKATHON

You are an expert **product architect, UI/UX designer, Flutter developer, Supabase developer, and hackathon mentor**.

We are a group of **B.Tech 1st-year Computer Science students** building a hackathon prototype.

Our skill level is beginner/intermediate, so the architecture, code, explanations, and implementation plan must be **simple enough for first-year students to understand and maintain**, while still looking professional enough for a hackathon demonstration.

---

# 1. PRODUCT IDEA

## Problem

Students constantly have to switch between multiple applications and websites when studying or completing college work.

For example:

- Google/Search engine for finding information
- YouTube/websites for learning resources
- ChatGPT/AI tools for explanations
- Calculator for calculations
- To-do apps for tasks
- Discord/WhatsApp for discussions
- Word/Google Docs for documents
- PDF tools for converting files
- PowerPoint/Canva for presentations

This creates unnecessary app switching, distraction, and loss of time.

## Proposed Solution

Create an **all-in-one student productivity and study workspace** that brings commonly needed student tools into one application.

The main philosophy is:

> **"Everything a student needs, in one workspace."**

The application should not try to completely replace every existing application. Instead, it should provide convenient access to the most frequently used student functions from one clean interface.

---

# 2. TARGET USERS

Primary users:

- B.Tech students
- College students
- School/college learners
- Students working on assignments
- Students preparing presentations
- Students searching for study resources

Secondary users:

- Teachers
- General users who need productivity utilities

The initial MVP should focus heavily on **students**.

---

# 3. CORE FEATURES

The prototype should contain the following modules.

## A. Welcome / Landing Page

Create a professional welcome page containing:

- Application logo/name
- Short tagline
- Brief explanation of the application
- "Get Started" button
- Login button
- Sign Up button

Example positioning:

> One workspace. Less switching. More learning.

Do not overload the landing page.

---

# 4. AUTHENTICATION

Use **Supabase Authentication**.

Support:

- Email/password registration
- Login
- Logout
- Password reset
- User profile

Structure authentication separately from the rest of the application.

Do NOT place authentication logic directly inside UI widgets.

Create a dedicated authentication/service layer.

Possible structure:

lib/
  features/
    auth/
      data/
      models/
      services/
      presentation/

---

# 5. MAIN DASHBOARD

After login, users should reach the main dashboard.

The dashboard should contain feature cards or slides.

Main modules:

1. To-Do
2. AI Assistant
3. Smart Search
4. Discussion / Community
5. Scientific Calculator
6. PDF Tools
7. Profile / Settings

The dashboard should be modular so that new features can be added later without rewriting the entire application.

---

# 6. TO-DO LIST

Create a simple but useful student task manager.

Features:

- Create task
- Edit task
- Delete task
- Mark task as completed
- Due date
- Priority
- Categories
- Optional notes

Example categories:

- Assignment
- Exam
- Project
- Personal
- College

Store user tasks in Supabase.

Suggested database table:

tasks

Fields:

- id
- user_id
- title
- description
- category
- priority
- due_date
- completed
- created_at
- updated_at

Keep the MVP simple.

---

# 7. AI ASSISTANT

Create an AI chatbot specifically designed around student productivity.

Possible capabilities:

- Explain concepts
- Summarize text
- Generate study plans
- Help brainstorm presentation ideas
- Explain programming concepts
- Generate questions for revision
- Help organize notes
- Answer general academic questions

Important:

Do not expose API keys inside Flutter client code.

Use a secure backend/API layer.

The architecture should allow us to change AI providers later.

For example:

Flutter UI
     ↓
AI service
     ↓
Secure backend/API
     ↓
AI provider

The AI module should be isolated from the rest of the application.

---

# 8. SMART SEARCH

Create a search interface that helps students discover useful resources.

The concept:

User searches:

"Python loops"

The application can show:

- Web results
- Educational resources
- Free resources
- Articles
- Documentation
- Public reviews/ratings where legally and technically possible
- Useful websites
- Study resources

The search system should prioritize:

1. Free resources
2. Educational resources
3. Reliable sources
4. Beginner-friendly explanations

Do NOT scrape websites illegally.

Use legitimate APIs or publicly available search services where appropriate.

The architecture should keep the search provider replaceable.

Example:

Search UI
↓
Search service
↓
Search API
↓
Normalized SearchResult model
↓
Search result cards

Do not tightly couple the UI to a specific search provider.

---

# 9. COMMUNITY / DISCUSSION SERVER

Create a Discord-inspired discussion area inside the application.

Do not attempt to reproduce the entire Discord feature set.

For the MVP implement:

- Communities
- Channels
- Posts/messages
- Replies
- User profiles
- Basic reactions
- Basic moderation/report functionality

Possible categories:

- Programming
- Mathematics
- Physics
- Engineering
- College life
- Projects
- Hackathons
- General discussion

Use Supabase database and, where appropriate, Supabase Realtime for live messages.

Possible tables:

communities
channels
messages
message_reactions
reports

Make sure users can only perform actions they are authorized to perform.

---

# 10. SCIENTIFIC CALCULATOR

Create a scientific calculator.

It should support:

- Addition
- Subtraction
- Multiplication
- Division
- Percentage
- Brackets
- Powers
- Square root
- Trigonometric functions
- Logarithms
- Constants such as π
- Basic scientific operations

The calculator should work independently and should not require an internet connection.

Create the calculator as a completely independent Flutter feature.

---

# 11. PDF TOOLS

Create a PDF utility section.

For the prototype, include:

### PDF → Word

Allow users to select a PDF and convert/extract its content into a Word document where technically feasible.

Also design the architecture so future PDF features can be added:

- PDF merge
- PDF split
- PDF compression
- PDF → image
- Image → PDF
- PDF → text

Important:

Do not put PDF processing logic throughout the UI.

Create a dedicated PDF service.

Example:

features/
  pdf_tools/
    data/
    models/
    services/
    presentation/

If conversion requires server-side processing, clearly separate the client and backend responsibilities.

---

# 12. SUPABASE

Use **Supabase as the primary backend/database**.

Use:

- Supabase PostgreSQL database
- Supabase Authentication
- Supabase Realtime where useful
- Supabase Storage for appropriate user files

Design database tables with proper relationships.

Potential tables:

users/profiles
tasks
communities
channels
messages
message_reactions
reports
files
search_history
user_preferences

Use:

- Primary keys
- Foreign keys
- Timestamps
- Indexes where appropriate
- Row Level Security (RLS)

Security is important.

Users should not be able to read or modify another user's private tasks/files unless explicitly allowed.

---

# 13. FLUTTER ARCHITECTURE

Use **Flutter + Dart**.

The architecture must be:

- Clean
- Modular
- Beginner-friendly
- Future-editable
- Feature-based
- Easy to debug

Do NOT create one giant main.dart file.

Use a feature-based structure.

Recommended high-level structure:

lib/
│
├── main.dart
│
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── theme/
│
├── core/
│   ├── constants/
│   ├── errors/
│   ├── utils/
│   ├── services/
│   └── widgets/
│
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── todo/
│   ├── ai_assistant/
│   ├── search/
│   ├── community/
│   ├── calculator/
│   ├── pdf_tools/
│   ├── profile/
│   └── settings/
│
└── shared/
    ├── models/
    └── widgets/

Each feature should preferably contain:

data/
models/
services/
presentation/

For example:

features/todo/

    data/
        todo_repository.dart

    models/
        todo.dart

    services/
        todo_service.dart

    presentation/
        pages/
        widgets/

The exact structure can be simplified where appropriate for first-year students, but maintain clear separation of responsibilities.

---

# 14. IMPORTANT ARCHITECTURE RULE

Follow this principle:

> UI should not directly communicate with the database.

Instead:

UI
↓
Controller/ViewModel/State layer
↓
Repository/Service
↓
Supabase/API

This ensures changing the database or API later does not require rewriting the UI.

Similarly:

UI
↓
SearchService
↓
SearchProvider

rather than:

UI
↓
Google-specific implementation

This makes the project future-editable.

---

# 15. STATE MANAGEMENT

Choose ONE beginner-friendly Flutter state-management approach.

Do not introduce multiple state-management systems.

Explain why you selected it.

The chosen solution should be:

- Easy to learn
- Suitable for modular architecture
- Scalable
- Hackathon-friendly

---

# 16. NAVIGATION

Create a clean navigation system.

Desktop/tablet:

- Sidebar navigation

Mobile:

- Bottom navigation or adaptive navigation

Possible navigation:

Home
To-Do
AI
Search
Community
Tools
Profile

The UI should adapt to different screen sizes.

---

# 17. RESPONSIVE DESIGN

The same Flutter project should support:

- Android
- iOS
- Web/Desktop browser

The interface should not assume a fixed phone screen size.

Use responsive layouts.

For example:

Mobile:
Bottom navigation

Tablet:
Navigation rail

Desktop/Web:
Sidebar

---

# 18. IPHONE WEBSITE / PWA

We specifically want iPhone users to access the application as a website.

Therefore, design the project for:

**Flutter Web + PWA**

The same Flutter codebase should be able to produce the web version.

The web version should:

- Work in Safari
- Work on iPhone
- Be responsive
- Have an application icon
- Have a proper browser title
- Have PWA metadata
- Provide a manifest
- Support "Add to Home Screen" where supported
- Have an app-like interface

Do not create a completely separate iPhone website unless absolutely necessary.

Architecture:

Flutter application
       │
       ├── Android
       ├── iOS
       └── Web / PWA
              │
              └── Hosted website

Use a deployment platform such as Vercel, Firebase Hosting, Netlify, or another suitable service.

Explain which option is easiest for beginners and why.

---

# 19. UI/UX DESIGN

The interface should feel like a modern student productivity platform.

Design principles:

- Clean
- Modern
- Minimal
- Fast
- Not visually overwhelming
- Student-friendly
- Professional hackathon appearance

Use:

- Cards
- Clear icons
- Consistent spacing
- Good typography
- Responsive layouts
- Subtle animations

Avoid:

- Excessive animations
- Overly complicated navigation
- Too many colors
- Clutter
- Unnecessary screens

The application should feel like ONE ecosystem rather than seven unrelated applications.

---

# 20. DASHBOARD CONCEPT

The home dashboard should answer:

### "What do I need to do today?"

Possible dashboard sections:

Good morning, [Name]

Today's tasks
[Assignment] [Due today]

Quick tools

[AI]
[Search]
[Calculator]
[PDF]

Continue learning

Recent searches/resources

Community activity

This makes the product feel integrated rather than just a collection of utilities.

---

# 21. PRODUCT DIFFERENTIATOR

Do not market the application simply as:

"An app containing many tools."

Instead position it as:

> **A unified student workspace that reduces app switching.**

Potential unique feature:

### Student Workspace

A student can start a task and access everything required from the same workspace.

Example:

Student creates:

"Physics Presentation"

Inside the workspace they can:

- Search for resources
- Ask AI questions
- Save useful resources
- Calculate formulas
- Convert PDFs
- Create a task
- Discuss the topic with other students

This creates a stronger product story for judges.

---

# 22. MVP SCOPE

We are first-year students and have limited development time.

Do NOT attempt to fully build every feature.

Prioritize a convincing MVP.

### MUST HAVE

1. Authentication
2. Dashboard
3. To-do list
4. AI chatbot prototype
5. Search
6. Scientific calculator
7. Basic community/discussion system
8. PDF → Word prototype
9. Supabase integration
10. Responsive Flutter Web/PWA

### SHOULD HAVE

- User profile
- Search history
- Saved resources
- Notifications
- Reactions
- Basic moderation

### COULD HAVE

- Study planner
- AI study plans
- Notes
- File storage
- Collaborative workspaces
- Presentation helper
- AI-powered PDF summarization

### FUTURE

- Calendar integration
- Google Drive integration
- Microsoft Office integration
- LMS/college integration
- Advanced AI agents
- Voice assistant
- Collaborative documents
- Cross-device synchronization

---

# 23. DATABASE DESIGN

Create a complete Supabase database schema.

For every table provide:

- Table name
- Columns
- Data type
- Primary key
- Foreign keys
- Relationships
- Indexes
- RLS policies

Create an ER-style explanation showing relationships.

Example:

profiles
   │
   ├── tasks
   │
   ├── search_history
   │
   ├── files
   │
   └── messages

communities
   │
   └── channels
          │
          └── messages

Keep the database normalized and easy to extend.

---

# 24. SECURITY

Explain:

- Supabase RLS
- Authentication
- API key handling
- Environment variables
- Backend secrets
- File upload security
- User permissions
- Community moderation

Never put private API keys directly into Flutter source code.

Use environment configuration and secure server-side functionality where required.

---

# 25. ERROR HANDLING

Every feature should have:

- Loading state
- Empty state
- Error state
- Success state

Examples:

Search:
Loading → Results → No results → Error

To-do:
Loading → Tasks → No tasks → Error

AI:
Connecting → Response → Error

PDF:
Uploading → Processing → Download/Result → Error

Make error messages understandable to normal students.

---

# 26. OFFLINE-FIRST WHERE PRACTICAL

Identify features that can work offline.

For example:

- Calculator
- Existing to-do data
- Basic UI
- Cached resources

Clearly distinguish offline functionality from features requiring internet access.

Do not over-engineer offline synchronization for the MVP.

---

# 27. PROJECT DEVELOPMENT ROADMAP

Create a detailed roadmap divided into phases.

### Phase 1 — Planning

- Finalize product name
- Finalize features
- Create user flow
- Create wireframes
- Design database

### Phase 2 — Project Setup

- Install Flutter
- Create project
- Configure Git
- Configure Supabase
- Configure environment variables
- Establish folder structure

### Phase 3 — UI Foundation

- Theme
- Colors
- Typography
- Navigation
- Responsive layout
- Reusable components

### Phase 4 — Authentication

- Sign up
- Login
- Logout
- Password reset
- Profile

### Phase 5 — Dashboard

Build dashboard and feature navigation.

### Phase 6 — To-Do

Implement complete MVP.

### Phase 7 — Calculator

Implement offline scientific calculator.

### Phase 8 — Search

Implement search service and result UI.

### Phase 9 — AI

Implement chatbot through a secure backend/API.

### Phase 10 — Community

Implement basic communities, channels, messages, and realtime updates.

### Phase 11 — PDF Tools

Implement PDF upload and conversion prototype.

### Phase 12 — Supabase Security

Configure:

- RLS
- Storage policies
- Authentication policies

### Phase 13 — Web/PWA

Configure:

- Flutter Web
- Manifest
- Icons
- Responsive UI
- PWA behavior
- Web deployment

### Phase 14 — Testing

Test:

- Android
- iPhone Safari
- Desktop browser
- Different screen sizes
- Authentication
- Database
- Network failures
- Empty states

### Phase 15 — Hackathon Polish

Add:

- Animations
- Loading states
- Better UX
- Demo data
- Landing page
- Product screenshots
- Presentation

---

# 28. TEAM DIVISION

Assume a team of 4 first-year students.

Suggest a realistic division such as:

### Person 1 — Flutter/UI

Responsible for:

- Flutter setup
- Navigation
- Dashboard
- Responsive UI
- Shared widgets

### Person 2 — Supabase/Backend

Responsible for:

- Supabase
- Database
- Authentication
- RLS
- Storage

### Person 3 — Core Features

Responsible for:

- To-do
- Calculator
- PDF tools

### Person 4 — AI/Search/Community

Responsible for:

- AI integration
- Search
- Community

Everyone should understand the overall architecture so that nobody becomes a single point of failure.

---

# 29. GIT / COLLABORATION

Design the project for GitHub collaboration.

Use:

main
development
feature branches

Example:

feature/auth
feature/todo
feature/search
feature/calculator
feature/community

Explain:

- Commit conventions
- Pull requests
- Merge conflicts
- Code reviews
- Environment variables
- .gitignore

Never commit:

- API keys
- Supabase service-role keys
- passwords
- private credentials

---

# 30. HACKATHON DEMO FLOW

Design a 3–5 minute demo.

Suggested flow:

1. Open landing page
2. Login
3. Show dashboard
4. Create a task
5. Ask AI a question
6. Search for a study resource
7. Open calculator
8. Show PDF conversion
9. Enter community
10. Show realtime discussion
11. Open same application through web/PWA
12. Explain how everything is connected through one ecosystem

The demo should focus on solving the original problem:

> "Students waste time switching between applications."

---

# 31. PRD REQUIREMENT

Create a complete Product Requirements Document containing:

1. Product name
2. Product vision
3. Problem statement
4. Target users
5. User personas
6. Goals
7. Non-goals
8. Feature list
9. Functional requirements
10. Non-functional requirements
11. User journeys
12. User stories
13. Acceptance criteria
14. Technical architecture
15. Flutter architecture
16. Supabase architecture
17. Database schema
18. Security model
19. PWA/Web strategy
20. API strategy
21. UI/UX requirements
22. MVP definition
23. Future roadmap
24. Testing strategy
25. Deployment strategy
26. Team responsibilities
27. Hackathon demo plan
28. Risks and mitigation

---

# 32. IMPORTANT BEGINNER RULE

We are B.Tech 1st-year students.

Whenever you provide code or architecture:

- Explain what it does
- Explain where the file belongs
- Explain why it belongs there
- Avoid unnecessarily advanced patterns
- Do not introduce technologies without explaining them
- Prefer simple maintainable solutions
- Give commands step-by-step
- Tell us exactly which file to create/edit
- Do not modify unrelated files
- Clearly identify dependencies/packages we need to install

If changing one feature requires modifying many unrelated files, redesign the architecture.

---

# 33. DEVELOPMENT RULE

Build the project incrementally.

DO NOT generate the entire application in one giant response.

Instead:

1. Establish architecture
2. Create project structure
3. Configure Supabase
4. Build authentication
5. Build dashboard
6. Build each feature independently
7. Integrate features
8. Test
9. Deploy

After each major stage, verify that the existing application still works before moving to the next stage.

---

# 34. CODE QUALITY RULE

Follow:

- Separation of concerns
- Reusable widgets
- Feature-based organization
- Clear naming
- Small files
- Minimal duplication
- Proper error handling
- Environment variables
- Git-friendly changes

Avoid:

- Giant files
- Hardcoded credentials
- Hardcoded API responses
- Copy-pasted widgets
- Database calls directly inside UI
- Feature-specific logic inside main.dart

---

# 35. FINAL OUTPUT REQUIRED

Based on all requirements above, produce:

### A. Product Overview

Explain the final product in simple terms.

### B. Improved Product Concept

Improve our original idea where necessary without changing its core purpose.

### C. Complete PRD

Write the complete PRD.

### D. Feature Prioritization

Separate:

- MVP
- V1
- V2
- Future

### E. User Flow

Provide complete user flows.

### F. Architecture

Provide Flutter + Supabase + API + PWA architecture.

### G. Folder Structure

Provide the complete recommended Flutter folder structure.

### H. Database

Provide Supabase tables, relationships, and RLS requirements.

### I. Development Roadmap

Give a realistic step-by-step roadmap for first-year students.

### J. Team Division

Divide work between 4 students.

### K. Git Strategy

Explain repository structure and collaboration.

### L. Deployment

Explain:

Flutter Android
Flutter iOS
Flutter Web
PWA
Supabase
Backend/API
Hosting

### M. Hackathon Demo

Create a compelling 3–5 minute demonstration flow.

### N. Future Scalability

Explain how we can add features later without breaking existing modules.

---

# MOST IMPORTANT REQUIREMENT

The final architecture must follow this principle:

> **Each feature should behave like an independent module.**

If we remove the calculator, the rest of the application should continue working.

If we replace the search provider, the search UI should not need to be rewritten.

If we replace the AI provider, the rest of the application should not be affected.

If we change the database implementation, the UI should require minimal changes.

If we later add a notes system, calendar, Google Drive, or presentation creator, it should be possible to add them as new features without restructuring the entire application.

Build the architecture around **low coupling, high cohesion, modularity, and future editability**.

The goal is not merely to make a collection of tools.

The goal is to create a convincing prototype of a **unified student workspace**.