*&---------------------------------------------------------------------*
*& Include       : ZFIR001_ALV
*& Description   : ALV Display routines using CL_SALV_TABLE
*& Note          : Uses modern OO ALV (CL_SALV_TABLE) for clean output
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& FORM: DISPLAY_DASHBOARD
*& Purpose: Main display controller — routes to correct ALV based on mode
*&---------------------------------------------------------------------*
FORM display_dashboard.
  CASE p_mode.
    WHEN '1'. PERFORM display_overview.
    WHEN '2'. PERFORM display_trial_balance.
    WHEN '3'. PERFORM display_je_validation.
    WHEN '4'.
      PERFORM display_trial_balance.
      PERFORM display_je_validation.
  ENDCASE.
ENDFORM.

*&---------------------------------------------------------------------*
*& FORM: DISPLAY_OVERVIEW
*& Purpose: Show KPI summary header then both ALV reports
*&---------------------------------------------------------------------*
FORM display_overview.
  " Print dashboard header
  WRITE: / '═══════════════════════════════════════════════════════'.
  WRITE: / '  R2R PERIOD CLOSE DASHBOARD'.
  WRITE: / |  Company : { gv_company_name }|.
  WRITE: / |  Period  : { gv_period_desc }|.
  WRITE: / |  Ledger  : { p_rldnr }|.
  WRITE: / '═══════════════════════════════════════════════════════'.
  SKIP.

  " Print KPIs
  LOOP AT gt_kpis INTO gs_kpi.
    DATA(lv_icon) = SWITCH #( gs_kpi-status
                               WHEN 'G' THEN '✅'
                               WHEN 'Y' THEN '⚠️ '
                               WHEN 'R' THEN '❌'
                               ELSE         '  ' ).
    WRITE: / lv_icon, gs_kpi-label, ':', gs_kpi-value.
  ENDLOOP.

  SKIP 2.
  PERFORM display_trial_balance.
  SKIP 2.
  PERFORM display_je_validation.
ENDFORM.

*&---------------------------------------------------------------------*
*& FORM: DISPLAY_TRIAL_BALANCE
*& Purpose: Render Trial Balance in ALV grid (CL_SALV_TABLE)
*&---------------------------------------------------------------------*
FORM display_trial_balance.
  DATA: lo_alv     TYPE REF TO cl_salv_table,
        lo_columns TYPE REF TO cl_salv_columns_table,
        lo_column  TYPE REF TO cl_salv_column_table,
        lo_display TYPE REF TO cl_salv_display_settings,
        lo_funcs   TYPE REF TO cl_salv_functions_list,
        lx_error   TYPE REF TO cx_salv_msg.

  TRY.
    cl_salv_table=>factory(
      IMPORTING r_salv_table = lo_alv
      CHANGING  t_table      = gt_trial_balance ).

    " Set title
    lo_display = lo_alv->get_display_settings( ).
    lo_display->set_list_header( '  Trial Balance Report  ' ).
    lo_display->set_striped_pattern( cl_salv_display_settings=>true ).

    " Enable toolbar functions
    lo_funcs = lo_alv->get_functions( ).
    lo_funcs->set_all( cl_salv_functions_list=>true ).

    " Configure columns
    lo_columns = lo_alv->get_columns( ).
    lo_columns->set_optimize( cl_salv_columns=>true ).

    " Set column headers
    TRY.
      lo_column ?= lo_columns->get_column( 'HKONT' ).
      lo_column->set_long_text(   'Account Code' ).
      lo_column->set_medium_text( 'Account' ).

      lo_column ?= lo_columns->get_column( 'TXT20' ).
      lo_column->set_long_text(   'Account Description' ).

      lo_column ?= lo_columns->get_column( 'TSLVT' ).
      lo_column->set_long_text(   'Opening Balance' ).

      lo_column ?= lo_columns->get_column( 'DEBIT' ).
      lo_column->set_long_text(   'Total Debits' ).

      lo_column ?= lo_columns->get_column( 'CREDIT' ).
      lo_column->set_long_text(   'Total Credits' ).

      lo_column ?= lo_columns->get_column( 'BALANCE' ).
      lo_column->set_long_text(   'Closing Balance' ).
    CATCH cx_salv_not_found.  " Column not found — skip
    ENDTRY.

    " Colour rows where balance is zero (fully cleared accounts)
    " via the COLOR field in structure

    lo_alv->display( ).

  CATCH cx_salv_msg INTO lx_error.
    MESSAGE lx_error TYPE 'E'.
  ENDTRY.

  " Print totals below ALV
  SKIP.
  WRITE: / 'Total Debits  :', gv_total_debit   CURRENCY 'INR'.
  WRITE: / 'Total Credits :', gv_total_credit  CURRENCY 'INR'.
  IF ABS( gv_diff ) < '0.01'.
    WRITE: / '✅ Trial Balance: BALANCED'.
  ELSE.
    WRITE: / '❌ Trial Balance: NOT BALANCED — Difference:', gv_diff CURRENCY 'INR'.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& FORM: DISPLAY_JE_VALIDATION
*& Purpose: Render Journal Entry validation results in ALV
*&---------------------------------------------------------------------*
FORM display_je_validation.
  DATA: lo_alv     TYPE REF TO cl_salv_table,
        lo_columns TYPE REF TO cl_salv_columns_table,
        lo_column  TYPE REF TO cl_salv_column_table,
        lo_display TYPE REF TO cl_salv_display_settings,
        lo_funcs   TYPE REF TO cl_salv_functions_list,
        lx_error   TYPE REF TO cx_salv_msg.

  TRY.
    cl_salv_table=>factory(
      IMPORTING r_salv_table = lo_alv
      CHANGING  t_table      = gt_je_entries ).

    lo_display = lo_alv->get_display_settings( ).
    lo_display->set_list_header( '  Journal Entry Validation Report  ' ).
    lo_display->set_striped_pattern( cl_salv_display_settings=>true ).

    lo_funcs = lo_alv->get_functions( ).
    lo_funcs->set_all( cl_salv_functions_list=>true ).

    lo_columns = lo_alv->get_columns( ).
    lo_columns->set_optimize( cl_salv_columns=>true ).

    TRY.
      lo_column ?= lo_columns->get_column( 'BELNR' ).
      lo_column->set_long_text( 'Document Number' ).

      lo_column ?= lo_columns->get_column( 'BUDAT' ).
      lo_column->set_long_text( 'Posting Date' ).

      lo_column ?= lo_columns->get_column( 'HKONT' ).
      lo_column->set_long_text( 'G/L Account' ).

      lo_column ?= lo_columns->get_column( 'VALID' ).
      lo_column->set_long_text( 'Status' ).

      lo_column ?= lo_columns->get_column( 'MSG' ).
      lo_column->set_long_text( 'Validation Message' ).
    CATCH cx_salv_not_found.
    ENDTRY.

    lo_alv->display( ).

  CATCH cx_salv_msg INTO lx_error.
    MESSAGE lx_error TYPE 'E'.
  ENDTRY.
ENDFORM.
