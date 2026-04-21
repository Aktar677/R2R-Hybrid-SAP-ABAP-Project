*&---------------------------------------------------------------------*
*& Include       : ZFIR001_FORMS
*& Description   : FORM Routines — Core R2R Business Logic
*& Key Tables    : BKPF, BSEG, FAGLFLEXT, SKA1, SKB1
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& FORM: VALIDATE_INPUT
*& Purpose: Validate selection parameters before data fetch
*&---------------------------------------------------------------------*
FORM validate_input.
  " Ensure fiscal year is valid (4 digit, not future)
  IF s_gjahr-low > sy-datum(4).
    MESSAGE w002(zfir_msg).
    " Warning: Future fiscal year selected
  ENDIF.

  " Ensure period is 01-12
  IF s_monat-low < '01' OR s_monat-low > '12'.
    MESSAGE e003(zfir_msg).
    " Error: Invalid posting period
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& FORM: FETCH_HEADER_DATA
*& Purpose: Get company name and period description
*&---------------------------------------------------------------------*
FORM fetch_header_data.
  SELECT SINGLE butxt INTO gv_company_name
    FROM t001 WHERE bukrs = s_bukrs-low.

  PERFORM get_period_desc
    USING    s_monat-low s_gjahr-low
    CHANGING gv_period_desc.
ENDFORM.

*&---------------------------------------------------------------------*
*& FORM: FETCH_GL_BALANCES
*& Purpose: Fetch G/L account balances from FAGLFLEXT for Trial Balance
*& Key Table: FAGLFLEXT (New G/L totals table)
*&            SKA1      (Account master – Chart of Accounts)
*&            SKB1      (Account master – Company Code)
*&---------------------------------------------------------------------*
FORM fetch_gl_balances.
  CLEAR: gt_trial_balance.

  DATA: lt_flext   TYPE TABLE OF faglflext,
        ls_flext   TYPE faglflext,
        ls_ska1    TYPE ska1.

  " Step 1: Read G/L balances from FAGLFLEXT
  SELECT rldnr rbukrs racct
         tslvt                    " Opening balance
         tslp01 tslp02 tslp03
         tslp04 tslp05 tslp06
         tslp07 tslp08 tslp09
         tslp10 tslp11 tslp12    " Period-wise amounts
    INTO TABLE lt_flext
    FROM faglflext
    WHERE rldnr  = p_rldnr
      AND rbukrs IN s_bukrs
      AND ryear  IN s_gjahr
      AND racct  <> ''.

  " Step 2: Build Trial Balance lines
  LOOP AT lt_flext INTO ls_flext.
    CLEAR gs_tb.

    gs_tb-hkont = ls_flext-racct.
    gs_tb-tslvt = ls_flext-tslvt.    " Opening balance

    " Sum period movements up to selected period
    PERFORM sum_period_amounts
      USING    ls_flext s_monat-low
      CHANGING gs_tb-debit
               gs_tb-credit.

    " Closing balance = Opening + Debits - Credits
    gs_tb-balance = gs_tb-tslvt + gs_tb-debit - gs_tb-credit.

    " Step 3: Get account description from SKA1
    SELECT SINGLE txt20 bilkt
      INTO (gs_tb-txt20, gs_tb-bilkt)
      FROM ska1
      WHERE ktopl = '1000'     " Chart of accounts — adjust as needed
        AND saknr = ls_flext-racct.

    APPEND gs_tb TO gt_trial_balance.
  ENDLOOP.

  " Step 4: Calculate totals for balance check
  gv_total_debit  = REDUCE dmbtr( INIT s = 0
                                  FOR  w IN gt_trial_balance
                                  NEXT s = s + w-debit ).
  gv_total_credit = REDUCE dmbtr( INIT s = 0
                                  FOR  w IN gt_trial_balance
                                  NEXT s = s + w-credit ).
  gv_diff = gv_total_debit - gv_total_credit.
ENDFORM.

*&---------------------------------------------------------------------*
*& FORM: FETCH_JOURNAL_ENTRIES
*& Purpose: Fetch posted JEs and validate debit = credit balance
*& Key Tables: BKPF (Document Header), BSEG (Line Items)
*&---------------------------------------------------------------------*
FORM fetch_journal_entries.
  CLEAR: gt_je_entries.

  DATA: lt_bkpf  TYPE TABLE OF bkpf,
        ls_bkpf  TYPE bkpf,
        lt_bseg  TYPE TABLE OF bseg,
        ls_bseg  TYPE bseg,
        lv_dr    TYPE dmbtr,
        lv_cr    TYPE dmbtr.

  " Fetch document headers
  SELECT belnr bukrs gjahr budat blart usnam
    INTO TABLE lt_bkpf
    FROM bkpf
    WHERE bukrs IN s_bukrs
      AND gjahr IN s_gjahr
      AND monat IN s_monat.

  " For each document, validate balance
  LOOP AT lt_bkpf INTO ls_bkpf.
    CLEAR: lv_dr, lv_cr.

    " Fetch line items for this document
    SELECT hkont dmbtr shkzg sgtxt
      INTO TABLE lt_bseg
      FROM bseg
      WHERE bukrs = ls_bkpf-bukrs
        AND belnr = ls_bkpf-belnr
        AND gjahr = ls_bkpf-gjahr.

    LOOP AT lt_bseg INTO ls_bseg.
      CLEAR gs_je.
      gs_je-belnr = ls_bkpf-belnr.
      gs_je-budat = ls_bkpf-budat.
      gs_je-hkont = ls_bseg-hkont.
      gs_je-sgtxt = ls_bseg-sgtxt.
      gs_je-dmbtr = ls_bseg-dmbtr.
      gs_je-shkzg = ls_bseg-shkzg.

      IF ls_bseg-shkzg = 'S'.    " Debit (Soll)
        lv_dr = lv_dr + ls_bseg-dmbtr.
      ELSE.                       " Credit (Haben)
        lv_cr = lv_cr + ls_bseg-dmbtr.
      ENDIF.

      APPEND gs_je TO gt_je_entries.
    ENDLOOP.

    " Validate: Dr must equal Cr per document
    DATA(lv_balance) = lv_dr - lv_cr.
    IF ABS( lv_balance ) > '0.01'.
      " Mark all lines of this document as invalid
      LOOP AT gt_je_entries ASSIGNING FIELD-SYMBOL(<fs_je>)
        WHERE belnr = ls_bkpf-belnr.
        <fs_je>-valid = 'E'.   " Error
        <fs_je>-msg   = |Dr/Cr imbalance: { lv_balance }|.
      ENDLOOP.
    ELSE.
      LOOP AT gt_je_entries ASSIGNING FIELD-SYMBOL(<fs_je_ok>)
        WHERE belnr = ls_bkpf-belnr.
        <fs_je_ok>-valid = 'S'.  " Success
        <fs_je_ok>-msg   = 'Balanced'.
      ENDLOOP.
    ENDIF.

  ENDLOOP.
ENDFORM.

*&---------------------------------------------------------------------*
*& FORM: CALCULATE_KPIS
*& Purpose: Compute KPI summary values for dashboard header
*&---------------------------------------------------------------------*
FORM calculate_kpis.
  CLEAR gt_kpis.

  DATA(lv_je_count)   = lines( gt_je_entries ).
  DATA(lv_err_count)  = REDUCE i( INIT n = 0
                                   FOR  w IN gt_je_entries
                                   WHERE ( valid = 'E' )
                                   NEXT n = n + 1 ).

  " KPI 1: Total Journal Entries
  CLEAR gs_kpi.
  gs_kpi-label  = 'Total Journal Entries'.
  gs_kpi-value  = lv_je_count.
  gs_kpi-status = 'G'.
  APPEND gs_kpi TO gt_kpis.

  " KPI 2: Invalid/Flagged Entries
  CLEAR gs_kpi.
  gs_kpi-label  = 'Invalid Entries'.
  gs_kpi-value  = lv_err_count.
  gs_kpi-status = COND #( WHEN lv_err_count = 0 THEN 'G'
                           WHEN lv_err_count < 5 THEN 'Y'
                           ELSE 'R' ).
  APPEND gs_kpi TO gt_kpis.

  " KPI 3: Trial Balance Status
  CLEAR gs_kpi.
  gs_kpi-label  = 'Trial Balance'.
  gs_kpi-value  = COND #( WHEN ABS( gv_diff ) < '0.01'
                           THEN 'BALANCED' ELSE 'NOT BALANCED' ).
  gs_kpi-status = COND #( WHEN ABS( gv_diff ) < '0.01' THEN 'G' ELSE 'R' ).
  APPEND gs_kpi TO gt_kpis.

  " KPI 4: Total Debits
  CLEAR gs_kpi.
  gs_kpi-label  = 'Total Debits'.
  gs_kpi-value  = gv_total_debit.
  gs_kpi-status = 'G'.
  APPEND gs_kpi TO gt_kpis.
ENDFORM.

*&---------------------------------------------------------------------*
*& FORM: SUM_PERIOD_AMOUNTS
*& Purpose: Sum debit/credit movements up to selected period from FAGLFLEXT
*&---------------------------------------------------------------------*
FORM sum_period_amounts
  USING    ps_flext TYPE faglflext
           pv_period TYPE monat
  CHANGING pv_debit   TYPE dmbtr
           pv_credit  TYPE dmbtr.

  DATA: lv_amount TYPE fagl_tsl,
        lv_idx    TYPE i.

  DO 12 TIMES.
    lv_idx = sy-index.
    IF lv_idx > pv_period. EXIT. ENDIF.

    " Access period field dynamically
    ASSIGN COMPONENT |TSLP{ lv_idx ALPHA = IN }| OF STRUCTURE ps_flext
           TO FIELD-SYMBOL(<lv_period_amt>).
    IF sy-subrc = 0.
      lv_amount = <lv_period_amt>.
      IF lv_amount > 0.
        pv_debit  = pv_debit + lv_amount.
      ELSE.
        pv_credit = pv_credit + ABS( lv_amount ).
      ENDIF.
    ENDIF.
  ENDDO.
ENDFORM.

*&---------------------------------------------------------------------*
*& FORM: GET_PERIOD_DESC
*& Purpose: Convert period number to readable text (e.g., "03" → "March 2026")
*&---------------------------------------------------------------------*
FORM get_period_desc
  USING    pv_period TYPE monat
           pv_year   TYPE gjahr
  CHANGING pv_desc   TYPE char20.

  DATA: lt_months TYPE TABLE OF string.
  lt_months = VALUE #(
    ( `January` )   ( `February` ) ( `March` )    ( `April` )
    ( `May` )        ( `June` )      ( `July` )     ( `August` )
    ( `September` )  ( `October` )   ( `November` ) ( `December` )
  ).

  DATA(lv_idx) = CONV i( pv_period ).
  READ TABLE lt_months INTO DATA(lv_month) INDEX lv_idx.
  pv_desc = |{ lv_month } { pv_year }|.
ENDFORM.
