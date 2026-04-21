*&---------------------------------------------------------------------*
*& Program      : ZFIR004
*& Title        : Bank Reconciliation Report
*& T-Code       : ZR2R_RC
*& Tables       : BSIS (Open Items), BSAS (Cleared Items), SKB1
*& Author       : [Your Name] | Roll No: [Roll No] | Batch: SAP ABAP
*& Description  : Compares open vs cleared G/L items to identify
*&                unreconciled entries at month-end close
*&---------------------------------------------------------------------*

REPORT zfir004.

TABLES: bsis, bsas, skb1.

*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_recon,
         hkont    TYPE saknr,      " G/L Account
         belnr    TYPE belnr_d,    " Document Number
         budat    TYPE budat,      " Posting Date
         dmbtr    TYPE dmbtr,      " Amount
         shkzg    TYPE shkzg,      " Dr/Cr indicator
         sgtxt    TYPE sgtxt,      " Text
         status   TYPE char10,     " Open / Cleared
         aging    TYPE i,          " Aging in days
         color    TYPE c LENGTH 4, " ALV row color
       END OF ty_recon.

DATA: gt_open    TYPE TABLE OF ty_recon,
      gt_cleared TYPE TABLE OF ty_recon,
      gt_all     TYPE TABLE OF ty_recon,
      gs_recon   TYPE ty_recon.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS: s_bukrs FOR bsis-bukrs OBLIGATORY DEFAULT '1000'.
  SELECT-OPTIONS: s_hkont FOR bsis-hkont.              " G/L Account range
  SELECT-OPTIONS: s_budat FOR bsis-budat.              " Posting date range
  PARAMETERS:     p_aging TYPE i DEFAULT 30.           " Flag if aged > N days
SELECTION-SCREEN END OF BLOCK b1.

INITIALIZATION.
  TEXT-001 = 'Bank / Account Reconciliation'.
  s_budat-low    = sy-datum - 90.
  s_budat-high   = sy-datum.
  s_budat-sign   = 'I'.
  s_budat-option = 'BT'.
  APPEND s_budat.

*----------------------------------------------------------------------*
START-OF-SELECTION.
*----------------------------------------------------------------------*
  PERFORM fetch_open_items.
  PERFORM fetch_cleared_items.
  PERFORM combine_and_color.
  PERFORM display_recon_alv.

*----------------------------------------------------------------------*
FORM fetch_open_items.
  DATA: lt_bsis TYPE TABLE OF bsis,
        ls_bsis TYPE bsis.

  SELECT hkont belnr budat dmbtr shkzg sgtxt
    INTO TABLE lt_bsis
    FROM bsis
    WHERE bukrs IN s_bukrs
      AND hkont IN s_hkont
      AND budat IN s_budat.

  LOOP AT lt_bsis INTO ls_bsis.
    CLEAR gs_recon.
    gs_recon-hkont  = ls_bsis-hkont.
    gs_recon-belnr  = ls_bsis-belnr.
    gs_recon-budat  = ls_bsis-budat.
    gs_recon-dmbtr  = ls_bsis-dmbtr.
    gs_recon-shkzg  = ls_bsis-shkzg.
    gs_recon-sgtxt  = ls_bsis-sgtxt.
    gs_recon-status = 'Open'.
    gs_recon-aging  = sy-datum - ls_bsis-budat.   " Days since posting
    APPEND gs_recon TO gt_open.
  ENDLOOP.
ENDFORM.

*----------------------------------------------------------------------*
FORM fetch_cleared_items.
  DATA: lt_bsas TYPE TABLE OF bsas,
        ls_bsas TYPE bsas.

  SELECT hkont belnr budat dmbtr shkzg sgtxt
    INTO TABLE lt_bsas
    FROM bsas
    WHERE bukrs IN s_bukrs
      AND hkont IN s_hkont
      AND budat IN s_budat.

  LOOP AT lt_bsas INTO ls_bsas.
    CLEAR gs_recon.
    gs_recon-hkont  = ls_bsas-hkont.
    gs_recon-belnr  = ls_bsas-belnr.
    gs_recon-budat  = ls_bsas-budat.
    gs_recon-dmbtr  = ls_bsas-dmbtr.
    gs_recon-shkzg  = ls_bsas-shkzg.
    gs_recon-sgtxt  = ls_bsas-sgtxt.
    gs_recon-status = 'Cleared'.
    gs_recon-aging  = 0.
    APPEND gs_recon TO gt_cleared.
  ENDLOOP.
ENDFORM.

*----------------------------------------------------------------------*
FORM combine_and_color.
  " Combine open + cleared, apply traffic-light coloring
  APPEND LINES OF gt_open    TO gt_all.
  APPEND LINES OF gt_cleared TO gt_all.

  LOOP AT gt_all ASSIGNING FIELD-SYMBOL(<fs>).
    IF <fs>-status = 'Open'.
      IF <fs>-aging > p_aging.
        <fs>-color = 'C610'.   " Red = overdue open item
      ELSE.
        <fs>-color = 'C510'.   " Yellow = open but within tolerance
      ENDIF.
    ELSE.
      <fs>-color = 'C310'.     " Green = cleared
    ENDIF.
  ENDLOOP.

  " Summary statistics
  DATA(lv_open_count)    = lines( gt_open ).
  DATA(lv_cleared_count) = lines( gt_cleared ).
  DATA(lv_open_amount)   = REDUCE dmbtr( INIT s = 0
                                          FOR  w IN gt_open
                                          NEXT s = s + w-dmbtr ).

  WRITE: / |Open items    : { lv_open_count }|.
  WRITE: / |Cleared items : { lv_cleared_count }|.
  WRITE: / |Open amount   : { lv_open_amount }|.
  SKIP.
ENDFORM.

*----------------------------------------------------------------------*
FORM display_recon_alv.
  DATA: lo_alv     TYPE REF TO cl_salv_table,
        lo_display TYPE REF TO cl_salv_display_settings,
        lo_funcs   TYPE REF TO cl_salv_functions_list,
        lx_error   TYPE REF TO cx_salv_msg.

  TRY.
    cl_salv_table=>factory(
      IMPORTING r_salv_table = lo_alv
      CHANGING  t_table      = gt_all ).

    lo_display = lo_alv->get_display_settings( ).
    lo_display->set_list_header( 'Reconciliation Report — Open vs Cleared Items' ).
    lo_display->set_striped_pattern( abap_true ).

    lo_funcs = lo_alv->get_functions( ).
    lo_funcs->set_all( abap_true ).

    lo_alv->display( ).

  CATCH cx_salv_msg INTO lx_error.
    MESSAGE lx_error TYPE 'E'.
  ENDTRY.
ENDFORM.
