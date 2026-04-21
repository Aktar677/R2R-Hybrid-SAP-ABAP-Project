*&---------------------------------------------------------------------*
*& Program      : ZFIR001
*& Title        : R2R Period Close Dashboard
*& Description  : Main dashboard for Record-to-Report Month-End Close
*& Author       : [Your Name] | Roll No: [Roll No] | Batch: SAP ABAP
*& T-Code       : ZR2R_MAIN
*& Created      : April 2026
*& Tables Used  : BKPF, BSEG, FAGLFLEXT, SKA1, T001
*&---------------------------------------------------------------------*
*& This is the PRODUCTION ABAP implementation.
*& The Python/Streamlit app (src/simulation/) is the visual simulation.
*&---------------------------------------------------------------------*

REPORT zfir001.

INCLUDE zfir001_top.     " Global declarations
INCLUDE zfir001_sel.     " Selection screen
INCLUDE zfir001_forms.   " FORM routines
INCLUDE zfir001_alv.     " ALV display routines

*&---------------------------------------------------------------------*
START-OF-SELECTION.
*&---------------------------------------------------------------------*

  PERFORM validate_input.
  PERFORM fetch_header_data.
  PERFORM fetch_gl_balances.
  PERFORM fetch_journal_entries.
  PERFORM calculate_kpis.
  PERFORM display_dashboard.
