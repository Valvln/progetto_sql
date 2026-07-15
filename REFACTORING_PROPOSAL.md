# Proposta di Refactoring Minimo - Progetto SQL

## 📊 Stato Attuale
```
progetto_sql/
├── storico_progetto_sql.sql          # File principale (+ 700 righe)
├── obiettivo_1.sql                  # Query singole
├── obiettivo_2.sql
├── ... (7 file query)
├── obiettivo-1-d.csv                # Dati (9 file)
├── ... (8 file dati)
├── graf_ob_*.png                    # Output (5 grafici)
└── .git/
```

**Problemi:**
- ❌ Struttura flat e difficile da navigare
- ❌ Query negli obiettivo_*.sql non sincronizzate con storico_progetto_sql.sql
- ❌ Nessun README di documentazione
- ❌ Mix di setup, query, dati e output in una sola cartella
- ❌ Mancanza di commenti header nei file singoli

---

## ✨ Refactoring Minimo Proposto

### Fase 1: Reorganizzazione (NO duplicazione code)

**Nuova struttura:**
```
progetto_sql/
├── README.md                         # [NUOVO] Documentazione progetto
├── setup.sql                         # [NUOVO] Consolidato: tabelle + view
├── config.sql                        # [NUOVO] Costanti + liste escluse
│
├── sql/
│   ├── 01_obiettivo_1.sql           # Query rinominate + header
│   ├── 02_obiettivo_2.sql
│   ├── ... (8 file)
│   └── main.sql                     # [NUOVO] Master file con tutte le query
│
├── data/                             # [NUOVO] Cartella dedicata
│   ├── obiettivo-1-d.csv
│   └── ... (8 file CSV)
│
├── outputs/                          # [NUOVO] Cartella dedicata
│   ├── graf_ob_1.png
│   └── ... (5 file PNG)
│
├── storico_progetto_sql.sql         # [LEGACY] Mantenuto per compatibilità
├── obiettivo_*.sql                  # [LEGACY] Mantenuti per compatibilità
└── .git/
```

### Fase 2: File da Creare

#### 1️⃣ `README.md` - Documentazione Progetto
Contiene:
- Descrizione progetto
- Struttura dataset
- Elenco obiettivi analitici
- Modalità esecuzione query
- Metadati versione

#### 2️⃣ `setup.sql` - DDL Consolidato
```sql
-- Creazione tabelle
CREATE TABLE researchers_per_million (...)
CREATE TABLE global_data_sustainable_energy (...)
CREATE TABLE iso_country_codes (...)

-- Creazione view
CREATE VIEW matching_with_global AS (...)
CREATE OR REPLACE VIEW matching_with_global_copy AS (...)
```

#### 3️⃣ `config.sql` - Configurazioni Centrali
```sql
-- Costanti e liste escluse
-- Facilitano manutenzione e reutilizzo
WITH excluded_countries AS (
    SELECT * FROM (VALUES
        ('ECU'), ('GEO'), ('KWT'), ...
    ) AS t(geounit)
)

-- Versione
-- Metadata
```

#### 4️⃣ `sql/main.sql` - Master File
Aggregazione di tutte le query:
```sql
-- ============================================
-- OBIETTIVO 1: Distribuzione globale rpm (2018)
-- ============================================
SELECT ...

-- ============================================
-- OBIETTIVO 2: Distribuzione energia rinnovabile (2018)
-- ============================================
SELECT ...

-- ... (8 obiettivi)
```

#### 5️⃣ `sql/XX_obiettivo_N.sql` - Header Standardizzato
```sql
/*
╔════════════════════════════════════════════════════════════╗
║ OBIETTIVO 1: Distribuzione Globale Ricercatori (2018)     ║
╚════════════════════════════════════════════════════════════╝

Descrizione: Analizza la distribuzione dei ricercatori 
             per milione di abitanti nel 2018

Output: Grafico a barre ordinato per rpm
Periodo: 2018
Dataset: researchers_per_million + iso_country_codes

Ultima modifica: 2026-07-14
*/

SELECT ...
```

### Fase 3: File da Sincronizzare

**Aggiornare obiettivo_*.sql:**
- Applicare refactoring best practice del storico_progetto_sql.sql
- Aggiungere header standardizzato
- Uniformare alias (rpm, gdse, icc, mwg)
- Formattazione MAIUSCOLO
- Gestione NULL esplicita

---

## 🎯 Benefici del Refactoring Minimo

| Aspetto | Prima | Dopo |
|---------|-------|------|
| **Navigabilità** | 8 file SQL nella root | 8 file organizzati in `/sql/` + master file |
| **Documentazione** | 0 README | README completo + header nei file |
| **Setup** | Disperso nel storico (700 righe) | File dedicato `setup.sql` (40 righe) |
| **Manutenzione** | Duplicazione nelle costanti | `config.sql` centralizzato |
| **Dati** | Mescolati con SQL | Cartella `/data/` dedicata |
| **Output** | Mescolati con SQL | Cartella `/outputs/` dedicata |
| **Sincronizzazione** | storico ≠ obiettivo_*.sql | Un file master + singoli per esecuzione |

---

## 📋 Piano di Esecuzione (Minimo)

### ✅ Step 1: Creare Struttura Base
```bash
mkdir -p sql data outputs
```

### ✅ Step 2: Estrarre e Creare setup.sql
- Copiare CREATE TABLE da storico_progetto_sql.sql
- Copiare CREATE VIEW da storico_progetto_sql.sql
- Testare esecuzione

### ✅ Step 3: Creare config.sql
- Centralizzare liste paesi esclusi
- Aggiungere metadati di versione

### ✅ Step 4: Creare sql/main.sql
- Aggregare tutte le query da storico_progetto_sql.sql
- Mantener sezioni commentate per indagini

### ✅ Step 5: Aggiornare Singoli File
- Aggiungere header a ogni obiettivo_X.sql
- Applicare best practice (alias, formattazione, NULL)
- Rinominare in `sql/XX_obiettivo_X.sql` (opzionale)

### ✅ Step 6: Organizzare Dati e Output
```bash
mv obiettivo-*-d.csv data/
mv graf_ob_*.png outputs/
```

### ✅ Step 7: Creare README.md
- Documentazione completa del progetto
- Istruzioni di esecuzione

### ⏭️ Step 8: Git Cleanup
```bash
git add -A
git commit -m "refactor: reorganize project structure with minimal impact"
```

---

## ⚠️ Considerazioni

### Cosa NON Cambieremo (Minimalismo)
- ❌ Nomi colonne tabelle
- ❌ Logica query
- ❌ Struttura database
- ❌ Rimuovere storico_progetto_sql.sql (legacy support)

### Cosa SÌ Cambieremo (Essenziale)
- ✅ Organizzazione file
- ✅ Documentazione
- ✅ Sincronizzazione setup
- ✅ Centralizzazione costanti

---

## 💡 Raccomandazioni Implementazione

**MINIMO (30 min):**
- Creare cartelle `/sql`, `/data`, `/outputs`
- Creare `setup.sql` da storico_progetto_sql.sql
- Creare `README.md` base
- Spostare dati e output

**OTTIMALE (1 ora):**
- Aggiungere `config.sql`
- Creare `sql/main.sql`
- Aggiungere header a ogni file obiettivo_X.sql
- Sincronizzare con best practice

**EVOLUTIVO (futura):**
- Parametrizzare query con Python wrapper
- Aggiungere tests SQL
- Creare Makefile per esecuzione
- Aggiungere CI/CD

---

## 🚀 Prossimi Passi

Scegliere livello implementazione:

1. **MINIMO** - Solo reorganizzazione cartelle + README
2. **COMPLETO** - Reorganizzazione + setup.sql + config.sql + main.sql
3. **EVOLUTIVO** - Completo + parametrizzazione + wrapper

**Raccomandazione:** Approccio COMPLETO per massimo beneficio con sforzo minimo.

