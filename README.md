# Proyecto Diseño – Backend API 🚀

The **Proyecto Diseño** backend is a Ruby on Rails 7 JSON‑first API that handles authentication, professor & student records, work‑plan workflows, activity tracking, notifications and more—all persisted in **Google Cloud Firestore** and **Firebase Storage**.

---

## ✨ Key features
| Domain | Highlights |
|--------|------------|
| **Auth** | JWT‑based sign‑in (`/authenticate`) & password recovery |
| **Users** | CRUD + smart filters by campus / role / email |
| **Professors** | Photo upload, coordinator toggle, active / inactive scopes |
| **Students** | Bulk CSV/XLSX upload, fuzzy search, Excel export |
| **Work Plans** | Coordinator‑only create / update, active & inactive scopes |
| **Activities** | Evidence upload, auto‑reminders, cancel / done states |
| **Comments** | Nested replies on activities |
| **Notifications** | Per‑student inbox with read/unread & status filters |
| **Global Date** | Simulate semester timeline for testing (`increment`, `decrement`) |

*Full route list lives in [`config/routes.rb`](config/routes.rb).*

---

## 🛠 Tech stack
| Layer | Choice | Why |
|-------|--------|-----|
| Language | **Ruby 3.2** | Modern pattern‑matching & YJIT |
| Framework | **Rails 7.1 (API‑only)** | Hotwired import‑maps |
| Data | **Google Cloud Firestore** | Server‑less, real‑time NoSQL DB |
| File store | **Firebase Storage** | Easy signed URLs for images/evidence |
| Auth | **JWT + BCrypt** | Statel­ess sessions, secure password hash |
| Infra | **Puma** server, CORS wide‑open while in dev |
| Tests | Minitest + Capybara + Mocha (headless system tests) |
| Misc gems | rack‑cors, jbuilder, caxlsx_rails |

---

## ⚡ Quick start

> Prereqs: **Ruby 3.2**, **Bundler**, **gcloud SDK** with a Firebase service‑account key (JSON).

```bash
# 1. Clone
git clone https://github.com/hart-venus/proyecto-diseno-backend.git
cd proyecto-diseno-backend

# 2. Install dependencies
bundle install

# 3. Point Rails at your GCP project
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service‑account.json
export FIREBASE_PROJECT=my‑firebase‑id          # optional, used by front‑end

# 4. Boot the API
bin/rails db:setup          # only builds the local sqlite test DB
bin/rails s                 # http://localhost:3000
```

### Running the test‑suite
```bash
bin/rails test              # Minitest + system tests
```

---

## 🔑 Environment variables

| Variable | Purpose |
|----------|---------|
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to the Firebase/GCP service‑account JSON |
| `FIREBASE_PROJECT` (optional) | Explicit project‑id override |
| `RAILS_MASTER_KEY` | Decrypts `config/credentials.yml.enc` if you add secrets |
| `JWT_SECRET_KEY` | Overrides the auto‑generated secret for token signing |

---

## 📚 API reference (TL;DR)

<details>
<summary>Users & Auth</summary>

```
POST   /authenticate                       → login, returns JWT
POST   /users                              → create user
GET    /users                              → list all
GET    /users/:id                          → show one
PUT    /users/:id                          → update
DELETE /users/:id                          → destroy
```
</details>

<details>
<summary>Professors, Students, Work Plans…</summary>

See `config/routes.rb` for the full matrix—endpoints are grouped by controller and follow the same RESTful shape shown above.
</details>

---

## 🧪 Local Firestore emulator (optional)

If you’d rather not hit prod while developing:

```bash
gcloud beta emulators firestore start --host-port=localhost:8080
export FIRESTORE_EMULATOR_HOST=localhost:8080
```

The initializer will auto‑connect. File uploads still hit live Firebase Storage for now.

---

## 🚀 Deployment

1. **Provision**: A single `e2.micro` (or Heroku Hobby dyno) + `GOOGLE_APPLICATION_CREDENTIALS` secret  
2. **Build**: `bundle install && bin/rails db:prepare`  
3. **Serve**: `bundle exec puma -C config/puma.rb`

_No SQL migrations run in prod—Firestore is schemaless._

---

## 👥 Authors & maintainers
- **Ariel Leyva** (@hart‑venus)  
- **José Ricardo Cardona**  
- **José Eduardo Gutiérrez Conejo**

> Big thanks to every contributor who helps keep the 🔥 in Hotwire!
