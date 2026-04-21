# 📊 Record-to-Report (R2R) — Month-End / Year-End Financial Close

**Capstone Project | SAP ABAP Batch**
**Author:** Your Name
**Roll No:** Your Roll Number
**Program:** SAP ABAP

---

## 🎯 Project Overview

This project automates the **Record-to-Report (R2R)** financial close process — the complete workflow used by finance teams during month-end and year-end closing.

### Problem Statement

Manual financial close processes are time-consuming, error-prone, and lack real-time visibility. Finance teams spend significant time reconciling accounts, validating journal entries, and preparing reports manually. This project provides an automated solution.

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
│                         │  For presentation and evaluation       │
└─────────────────────────┴────────────────────────────────────────┘
```

> **Note:** The Python simulation layer is used only for demonstration. The actual implementation is done using SAP ABAP programs.

---

## 📁 Project Structure

```bash
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

| T-Code    | Program            | Description     | Tables Used           |
| --------- | ------------------ | --------------- | --------------------- |
| ZR2R_MAIN | ZFIR001            | R2R Dashboard   | BKPF, BSEG, FAGLFLEXT |
| ZR2R_TB   | ZFIR002            | Trial Balance   | FAGLFLEXT, SKA1, SKB1 |
| ZR2R_RC   | ZFIR004            | Reconciliation  | BSIS, BSAS            |
| ZR2R_CL   | ZFIR_CLOSE_TRACKER | Close Checklist | ZCLOSE_CHECKLIST      |

---

### SAP Tables Used

| Table            | Description                    |
| ---------------- | ------------------------------ |
| BKPF             | Accounting Document Header     |
| BSEG             | Accounting Document Line Items |
| FAGLFLEXT        | G/L Account Totals             |
| SKA1             | G/L Master (Chart of Accounts) |
| SKB1             | G/L Master (Company Code)      |
| BSIS             | Open Items                     |
| BSAS             | Cleared Items                  |
| T001             | Company Code                   |
| ZCLOSE_CHECKLIST | Custom Table                   |

---

### Deployment Steps (SAP)

1. Go to **SE38** and create programs
2. Paste code from `src/abap/`
3. Create table `ZCLOSE_CHECKLIST` in **SE11**
4. Create T-Codes in **SE93**
5. Activate and test

---

## 🐍 Python Simulation

### Install Dependencies

```bash
pip install streamlit pandas plotly
```

---

### Run Application

```bash
cd src/simulation
streamlit run app.py
```

---

## 📊 R2R Process Flow

```
Data Collection → Journal Validation → Reconciliation
      ↓
Trial Balance → Financial Statements → Close
```

---

## 🔍 Modules Covered

* Journal Entry Validation (Debit = Credit)
* Trial Balance Generation
* Account Reconciliation
* Financial Statements (P&L + Balance Sheet)
* Close Checklist Tracking

---

## 🌟 Key Features

* Real SAP FI Tables used
* Debit-Credit validation logic
* Aging analysis (30/60/90/180 days)
* Traffic-light indicators
* OO ALV reporting
* Custom Z-table implementation

---

## 🔮 Future Scope

* SAP Fiori integration
* Workflow automation
* Email alerts
* AI anomaly detection

---

## 📌 Conclusion

This project demonstrates automation of financial close processes using a hybrid approach combining SAP ABAP and Python simulation. It improves efficiency, accuracy, and visibility.

---

## 📄 License

Academic project — for educational purposes only.
