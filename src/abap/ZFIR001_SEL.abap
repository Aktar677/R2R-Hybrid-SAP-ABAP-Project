*&---------------------------------------------------------------------*
*& Include       : ZFIR001_SEL
*& Description   : Selection Screen for R2R Dashboard
*&---------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.

  " Company Code
  SELECT-OPTIONS: s_bukrs FOR bkpf-bukrs
                  OBLIGATORY
                  DEFAULT '1000'.

  " Fiscal Year
  SELECT-OPTIONS: s_gjahr FOR bkpf-gjahr
                  OBLIGATORY
                  DEFAULT sy-datum(4).

  " Posting Period (Month)
  SELECT-OPTIONS: s_monat FOR bkpf-monat
                  DEFAULT '03'.

SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.

  " Ledger
  PARAMETERS: p_rldnr TYPE fagl_ledger DEFAULT '0L'.

  " Report Mode
  PARAMETERS: p_mode  TYPE char1 AS LISTBOX
                              VISIBLE LENGTH 30.

SELECTION-SCREEN END OF BLOCK b2.

*----------------------------------------------------------------------*
INITIALIZATION.
*----------------------------------------------------------------------*
  " Set default texts
  TEXT-001 = 'Selection Criteria'.
  TEXT-002 = 'Report Options'.

  " Populate report mode dropdown
  DATA: lt_modes TYPE vrm_values,
        ls_mode  TYPE vrm_value.

  ls_mode-key = '1'. ls_mode-text = 'Dashboard Overview'.
  APPEND ls_mode TO lt_modes.
  ls_mode-key = '2'. ls_mode-text = 'Trial Balance Only'.
  APPEND ls_mode TO lt_modes.
  ls_mode-key = '3'. ls_mode-text = 'JE Validation Only'.
  APPEND ls_mode TO lt_modes.
  ls_mode-key = '4'. ls_mode-text = 'Full Detailed Report'.
  APPEND ls_mode TO lt_modes.

  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING id     = 'P_MODE'
    TABLES    values = lt_modes.

  p_mode = '1'.

*----------------------------------------------------------------------*
AT SELECTION-SCREEN.
*----------------------------------------------------------------------*
  " Validate company code exists
  SELECT SINGLE butxt INTO gv_company_name
    FROM t001 WHERE bukrs = s_bukrs-low.
  IF sy-subrc <> 0.
    MESSAGE e001(zfir_msg) WITH s_bukrs-low.
    " Error: Company code & does not exist
  ENDIF.

*----------------------------------------------------------------------*
AT SELECTION-SCREEN OUTPUT.
*----------------------------------------------------------------------*
  " Display company name dynamically on screen
  IF gv_company_name IS NOT INITIAL.
    LOOP AT SCREEN.
      IF screen-name = 'S_BUKRS-LOW'.
        " Company name shown in title area
      ENDIF.
    ENDLOOP.
  ENDIF.
