# Progetto SQL — Ricercatori per milione ed Energia Rinnovabile

Analisi in SQL (PostgreSQL) della relazione tra la densità di ricercatori per milione di abitanti e l'adozione di energia rinnovabile a livello globale, combinando due dataset pubblici:

- **UNESCO** — "researchers per million" → tabella `researchers_per_million`
- **Kaggle** — "Global Data on Sustainable Energy" → tabella `global_data_sustainable_energy`
- Tabella di lookup ISO Alpha-3 curata manualmente → `iso_country_codes`

## Struttura del progetto

```
progetto_sql/
├── setup.sql                     # DDL consolidato: tabelle + view
├── storico_progetto_sql.sql      # Cronologia completa: setup, indagini, tutte le query
├── obiettivo_1.sql ... _8.sql    # Query di analisi, una per obiettivo
├── data/                         # Export CSV dei risultati per obiettivo
├── outputs/                      # Grafici generati a partire dai CSV
└── REFACTORING_PROPOSAL.md       # Proposta di riorganizzazione del progetto
```

## Esecuzione

1. Creare le tabelle e le view eseguendo `setup.sql` su un database PostgreSQL.
2. Importare i dati nelle tre tabelle (`researchers_per_million`, `global_data_sustainable_energy`, `iso_country_codes`), ad esempio con `\copy` da `psql`.
3. Eseguire le query di analisi desiderate da `obiettivo_1.sql` ... `obiettivo_8.sql`.

Per il dettaglio del processo di sviluppo (indagini sui dati, correzioni, query di validazione) fare riferimento a `storico_progetto_sql.sql`.

## Obiettivi analitici

1. Distribuzione globale dei ricercatori per milione, istantanea 2018 (grafico a barre).
2. Distribuzione globale della quota di energia rinnovabile, istantanea 2018 (grafico a barre).
3. Correlazione tra ricercatori per milione e quota di energia rinnovabile, dataset completo (scatter plot).
4. Correlazione media per paese tra le due metriche (tabella aggregata).
5. Evoluzione temporale 2000–2022 della media globale di ricercatori per milione (grafico a linee).
6. Evoluzione temporale 2000–2022 della media globale della quota di energia rinnovabile (grafico a linee).
7. Confronto per paesi selezionati (Germania, Italia, USA, Canada, Giappone, Nuova Zelanda, Sudafrica), 2000–2020 (grafico a linee).
8. Clustering dei paesi in base alla media di ricercatori per milione (terzili Low/Medium/High) e correlazione per cluster e per anno.

## FONTI 

1. Global Data on Sustainable Energy (2000-2020). - Kaggle
2. Researchers per million inhabitants (FTE) - UNESCO
3. Online Browsing Platform (ISO 3166 - Alpha 3)