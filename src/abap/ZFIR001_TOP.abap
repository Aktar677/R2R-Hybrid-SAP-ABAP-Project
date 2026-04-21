*&---------------------------------------------------------------------*
*& Include       : ZFIR001_TOP
*& Description   : Global Data Declarations for R2R Dashboard
*&---------------------------------------------------------------------*

TABLES: bkpf,       " Accounting Document Header
        bseg,       " Accounting Document Line Items
        ska1,       " G/L Account Master (Chart of Accounts)
        skb1,       " G/L Account Master (Company Code)
        t001,       " Company Codes
        faglflext.  " General Ledger Totals

*----------------------------------------------------------------------*
* Type definitions
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_tb_line,
         hkont    TYPE hkont,           " G/L Account
         txt20    TYPE txt20_skat,      " Account Short Text
         bilkt    TYPE bilkt,           " Account Type
         tslvt    TYPE fagl_tsl,        " Opening Balance
         debit    TYPE fagl_tsl,        " Period Debits
         credit   TYPE fagl_tsl,        " Period Credits
         balance  TYPE fagl_tsl,        " Closing Balance
         color    TYPE lvc_t_scol,      " ALV color
       END OF ty_tb_line.

TYPES: BEGIN OF ty_je_line,
         belnr    TYPE belnr_d,         " Document Number
         budat    TYPE budat,           " Posting Date
         hkont    TYPE hkont,           " G/L Account
         sgtxt    TYPE sgtxt,           " Item Text
         dmbtr    TYPE dmbtr,           " Amount in Local Currency
         shkzg    TYPE shkzg,           " Debit/Credit Indicator
         valid    TYPE char1,           " Validation Flag (X=valid)
         msg      TYPE char100,         " Validation Message
       END OF ty_je_line.

TYPES: BEGIN OF ty_kpi,
         label    TYPE char50,
         value    TYPE char30,
         status   TYPE char1,           " G=Green, Y=Yellow, R=Red
       END OF ty_kpi.

*----------------------------------------------------------------------*
* Internal tables
*----------------------------------------------------------------------*
DATA: gt_trial_balance  TYPE TABLE OF ty_tb_line,
      gt_je_entries     TYPE TABLE OF ty_je_line,
      gt_kpis           TYPE TABLE OF ty_kpi,
      gs_tb             TYPE ty_tb_line,
      gs_je             TYPE ty_je_line,
      gs_kpi            TYPE ty_kpi.

*----------------------------------------------------------------------*
* Work variables
*----------------------------------------------------------------------*
DATA: gv_total_debit    TYPE dmbtr,
      gv_total_credit   TYPE dmbtr,
      gv_diff           TYPE dmbtr,
      gv_company_name   TYPE butxt,
      gv_period_desc    TYPE char20,
      gv_title          TYPE lvc_title.

*----------------------------------------------------------------------*
* ALV references
*----------------------------------------------------------------------*
DATA: go_alv_tb    TYPE REF TO cl_salv_table,
      go_alv_je    TYPE REF TO cl_salv_table,
      go_container TYPE REF TO cl_gui_custom_container,
      go_splitter  TYPE REF TO cl_gui_splitter_container.

* Constants
CONSTANTS: gc_leading_ledger TYPE fagl_ledger VALUE '0L',
           gc_true            TYPE char1       VALUE 'X',
           gc_false           TYPE char1       VALUE ' '.
