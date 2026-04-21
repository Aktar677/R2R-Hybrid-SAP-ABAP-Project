*&---------------------------------------------------------------------*
*& Program      : ZFIR002
*& Title        : Trial Balance ALV Report
*& T-Code       : ZR2R_TB
*& Tables       : FAGLFLEXT, SKA1, SKB1, T001
*& Author       : [Your Name] | Roll No: [Roll No] | Batch: SAP ABAP
*&---------------------------------------------------------------------*

REPORT zfir002.

TABLES: faglflext, ska1, t001.

*----------------------------------------------------------------------*
* Types
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_output,
         hkont    TYPE saknr,
         txt50    TYPE txt50_skat,
         acct_typ TYPE char15,
         op_bal   TYPE fagl_tsl,
         debits   TYPE fagl_tsl,
         credits  TYPE fagl_tsl,
         cl_bal   TYPE fagl_tsl,
         currency TYPE waers,
       END OF ty_output.

DATA: gt_output TYPE TABLE OF ty_output,
      gs_output TYPE ty_output.

*----------------------------------------------------------------------*
* Selection Screen
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS: s_bukrs FOR faglflext-rbukrs OBLIGATORY DEFAULT '1000'.
  SELECT-OPTIONS: s_gjahr FOR faglflext-ryear  OBLIGATORY.
  PARAMETERS:     p_period TYPE faglflext-rpmax DEFAULT '003'.
  PARAMETERS:     p_rldnr  TYPE fagl_ledger     DEFAULT '0L'.
SELECTION-SCREEN END OF BLOCK b1.

INITIALIZATION.
  TEXT-001 = 'Trial Balance Parameters'.
  s_gjahr-low  = sy-datum(4).
  s_gjahr-sign = 'I'.
  s_gjahr-option = 'EQ'.
  APPEND s_gjahr.

*----------------------------------------------------------------------*
START-OF-SELECTION.
*----------------------------------------------------------------------*
  PERFORM fetch_and_build_tb.
  PERFORM display_tb_alv.

*----------------------------------------------------------------------*
*& FORM: FETCH_AND_BUILD_TB
*----------------------------------------------------------------------*
FORM fetch_and_build_tb.
  DATA: lt_flext TYPE TABLE OF faglflext,
        ls_flext TYPE faglflext.

  " Fetch from New G/L totals table
  SELECT rldnr rbukrs racct ryear
         tslvt
         tslp01 tslp02 tslp03 tslp04
         tslp05 tslp06 tslp07 tslp08
         tslp09 tslp10 tslp11 tslp12
    INTO TABLE lt_flext
    FROM faglflext
    WHERE rldnr  = p_rldnr
      AND rbukrs IN s_bukrs
      AND ryear  IN s_gjahr
      AND racct  <> space.

  IF sy-subrc <> 0.
    MESSAGE 'No data found for selection criteria' TYPE 'I'.
    RETURN.
  ENDIF.

  LOOP AT lt_flext INTO ls_flext.
    CLEAR gs_output.
    gs_output-hkont = ls_flext-racct.

    " Get account text and type from SKA1
    SELECT SINGLE txt50 xbilk bilkt
      INTO (@DATA(lv_txt50), @DATA(lv_xbilk), @DATA(lv_bilkt))
      FROM ska1
      WHERE saknr = ls_flext-racct.

    gs_output-txt50 = lv_txt50.
    gs_output-acct_typ = SWITCH #( lv_bilkt
                                    WHEN 'X' THEN 'Balance Sheet'
                                    WHEN ' ' THEN 'P&L'
                                    ELSE 'Other' ).

    gs_output-op_bal  = ls_flext-tslvt.

    " Sum period movements up to selected period
    DATA(lv_period_num) = CONV i( p_period ).
    DO lv_period_num TIMES.
      DATA(lv_i) = sy-index.
      ASSIGN COMPONENT |TSLP{ lv_i ALPHA = IN }|
             OF STRUCTURE ls_flext TO FIELD-SYMBOL(<amt>).
      IF sy-subrc = 0 AND <amt> IS ASSIGNED.
        IF <amt> > 0.
          gs_output-debits  = gs_output-debits  + <amt>.
        ELSE.
          gs_output-credits = gs_output-credits + ABS( <amt> ).
        ENDIF.
      ENDIF.
    ENDDO.

    gs_output-cl_bal = gs_output-op_bal + gs_output-debits - gs_output-credits.
    APPEND gs_output TO gt_output.
  ENDLOOP.

  " Sort by account number
  SORT gt_output BY hkont.
ENDFORM.

*----------------------------------------------------------------------*
*& FORM: DISPLAY_TB_ALV
*----------------------------------------------------------------------*
FORM display_tb_alv.
  DATA: lo_alv     TYPE REF TO cl_salv_table,
        lo_display TYPE REF TO cl_salv_display_settings,
        lo_funcs   TYPE REF TO cl_salv_functions_list,
        lo_columns TYPE REF TO cl_salv_columns_table,
        lo_column  TYPE REF TO cl_salv_column_table,
        lo_aggr    TYPE REF TO cl_salv_aggregations,
        lx_error   TYPE REF TO cx_salv_msg.

  TRY.
    cl_salv_table=>factory(
      IMPORTING r_salv_table = lo_alv
      CHANGING  t_table      = gt_output ).

    lo_display = lo_alv->get_display_settings( ).
    lo_display->set_list_header( |Trial Balance — Period { p_period } / { s_gjahr-low }| ).
    lo_display->set_striped_pattern( abap_true ).

    lo_funcs = lo_alv->get_functions( ).
    lo_funcs->set_all( abap_true ).

    lo_columns = lo_alv->get_columns( ).
    lo_columns->set_optimize( abap_true ).

    " Set Totals on numeric columns
    lo_aggr = lo_alv->get_aggregations( ).
    TRY.
      lo_aggr->add_aggregation( columnname   = 'DEBITS'
                                 aggregation = if_salv_c_aggregation=>total ).
      lo_aggr->add_aggregation( columnname   = 'CREDITS'
                                 aggregation = if_salv_c_aggregation=>total ).
      lo_aggr->add_aggregation( columnname   = 'CL_BAL'
                                 aggregation = if_salv_c_aggregation=>total ).
    CATCH cx_salv_data_error cx_salv_not_found cx_salv_existing.
    ENDTRY.

    lo_alv->display( ).

  CATCH cx_salv_msg INTO lx_error.
    MESSAGE lx_error TYPE 'E'.
  ENDTRY.
ENDFORM.
