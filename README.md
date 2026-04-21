# 📊 Record-to-Report (R2R) — Month-End / Year-End Financial Close

**Capstone Project | SAP ABAP Batch**  
**Author:** [Your Name] | **Roll No:** [Your Roll No] | **Batch/Program:** SAP ABAP

---

## 🎯 Project Overview

This project automates the **Record-to-Report (R2R)** financial close process — the end-to-end workflow that finance teams execute at every month-end and year-end to close the books and generate financial statements.

### Problem Statement
Manual financial close processes are time-consuming, error-prone, and lack real-time visibility. Finance teams spend days reconciling accounts, validating journal entries, and generating reports — all manually. This project builds a complete automated R2R system.

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                    PROJECT STRUCTURE                              │
├─────────────────────────┬────────────────────────────────────────┤
│  LAYER 1 (PRODUCTION)   │  SAP ABAP Programs                     │
│  src/abap/              │  Runs in SAP FI system                 │
│                         │  Uses real SAP tables                  │
├─────────────────────────┼────────────────────────────────────────┤
│  LAYER 2 (SIMULATION)   │  Python / Streamlit                    │
│  src/simulation/        │  Visual demo with sample data          │
│                         │  For evaluation/presentation only      │
└─────────────────────────┴────────────────────────────────────────┘
```

> **Note:** The Python simulation (Layer 2) exists purely for visual demonstration. The actual production implementation is the ABAP code (Layer 1) that runs in the SAP FI module.

---

## 📁 Project Structure

```
R2R_PROJECT/
├── data/
│   └── r2r_data.json
├── docs/
│   └── screenshots/
│       ├── 01_dashboard.png
│       ├── 02_checklist.png
│       ├── 03_trial_balance.png
│       ├── 04_je_validation.png
│       ├── 05_financial_statement.png
│       ├── 05_reconciliation.png
├── src/
│   ├── abap/
│   │   ├── ZFIR001.abap
│   │   ├── ZFIR001_TOP.abap
│   │   ├── ZFIR001_SEL.abap
│   │   ├── ZFIR001_FORMS.abap
│   │   ├── ZFIR001_ALV.abap
│   │   ├── ZFIR002.abap
│   │   ├── ZFIR004.abap
│   │   └── ZFIR_CLOSE_TRACKER.abap
│   └── simulation/
│       └── app.py
├── README.md
└── requirements.txt

```

---

## 🔧 SAP ABAP Programs

### T-Codes & Programs

| T-Code | Program | Description | Key Tables |
|--------|---------|-------------|-----------|
| `ZR2R_MAIN` | ZFIR001 | R2R Dashboard | BKPF, BSEG, FAGLFLEXT |
| `ZR2R_TB` | ZFIR002 | Trial Balance | FAGLFLEXT, SKA1, SKB1 |
| `ZR2R_RC` | ZFIR004 | Reconciliation | BSIS, BSAS |
| `ZR2R_CL` | ZFIR_CLOSE_TRACKER | Close Checklist | ZCLOSE_CHECKLIST (Z-table) |

### SAP Tables Used

| Table | Description |
|-------|-------------|
| `BKPF` | Accounting Document Header |
| `BSEG` | Accounting Document Line Items |
| `FAGLFLEXT` | New G/L Account Totals |
| `SKA1` | G/L Account Master (Chart of Accounts) |
| `SKB1` | G/L Account Master (Company Code) |
| `BSIS` | Open G/L Line Items |
| `BSAS` | Cleared G/L Line Items |
| `T001` | Company Codes |
| `ZCLOSE_CHECKLIST` | Custom Z-table for close tasks |

### Deploying in SAP

1. Open **SE38** → Create each program (ZFIR001, ZFIR002 etc.)
2. Copy code from `src/abap/*.abap` files
3. Create **Z-table** `ZCLOSE_CHECKLIST` in **SE11** (schema in ZFIR_CLOSE_TRACKER.abap)
4. Register T-Codes in **SE93**
5. Create message class `ZFIR_MSG` in **SE91**
6. Activate and test with company code 1000, period 03, year 2026

---

## 🐍 Python Simulation (Demo Layer)

### Prerequisites
```bash
pip install streamlit plotly pandas
```

### Run
```bash
cd src/simulation
streamlit run app.py
```

The app reads from `data/r2r_data.json` — sample data modelled on real SAP FI structures.

---

## 📊 R2R Process Covered

```
Data Collection → Journal Entry Validation → Account Reconciliation
      ↓
Trial Balance Generation → Financial Statements → Close Sign-off
```

### Modules
1. **Journal Entry Validation** — Debit = Credit check on every document (BKPF+BSEG)
2. **Trial Balance** — Period-wise G/L balances from FAGLFLEXT with totals check
3. **Bank Reconciliation** — Open items (BSIS) vs Cleared items (BSAS) with aging
4. **Financial Statements** — P&L (Revenue - Expenses) and Balance Sheet
5. **Close Task Tracker** — Z-table based checklist with traffic-light status

---

## 🌟 Unique Features

- ✅ Real SAP FI tables (BKPF, BSEG, FAGLFLEXT, BSIS, BSAS) — not simulated
- ✅ Debit = Credit validation per accounting document
- ✅ Aging analysis for open items (30/60/90/180+ day buckets)
- ✅ Traffic-light ALV coloring (Green/Yellow/Red per task status)
- ✅ Custom Z-table `ZCLOSE_CHECKLIST` for period close management
- ✅ OO ALV using `CL_SALV_TABLE` (modern approach)
- ✅ Dynamic period summation using field symbols

---

## 🔮 Future Improvements

- Workflow integration (SAP Business Workplace) for task approvals
- Email notifications on overdue close tasks
- Integration with SAP Fiori for mobile close tracking
- AI-based anomaly detection on journal entries
- Automated period lock (OB52) trigger on 100% task completion

---

## 📄 License
Academic capstone project — not for commercial use.
